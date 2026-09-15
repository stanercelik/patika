import CoreTransferable
import Foundation
import Observation
import UniformTypeIdentifiers

/// "Ben" sekmesi — geriye bakan defter (`docs/profile-design.md`).
///
/// ## Yalnızca gerçek veri
///
/// Sayfa sunucudaki kaydı (`me-profile`) okur ve cihazdaki kayda işler. Verisi
/// olmayan bölüm **çizilmez**: henüz karşılaştırma yoksa "Ne değişti" yok, cümle
/// yoksa defter yok, yol yoksa mühür yok. Boş durum metni ve açıklama notu yok.
///
/// "Yolum" ileriye bakan harita; bu ekran nereden geçildiğini, yolda ne
/// söylendiğini ve neyin değiştiğini tutar. **Birincil CTA yok.**
@Observable
@MainActor
final class MeViewModel {
    enum PathLoad: Equatable {
        case loading
        case none
        case active(ActivePath)
        case unavailable
    }

    enum SupportPlacement: Equatable {
        /// Kriz sinyali: sayfada destekten başka kişisel içerik yok.
        case top
        /// Üç katmanın üçü de kötü yönde.
        case belowChange
        case standard
    }

    struct JournalItem: Identifiable, Equatable {
        let id: UUID
        let text: String
        let caption: String
        let detail: String?
        let target: JournalDeletionTarget
    }

    struct JournalGroup: Identifiable, Equatable {
        let id: String
        let title: String
        var items: [JournalItem]
    }

    struct SealItem: Identifiable, Equatable {
        let id: String
        let pathID: UUID
        let title: String
        let detail: String
        let meta: String
        let headline: String?
        let style: RouteSeal.Style
        let stepCount: Int
        let walkedFraction: Double
    }

    struct PreferenceItem: Identifiable, Equatable {
        enum Kind: String {
            case reminder, sessionLength, tone, voice
        }

        let kind: Kind
        let value: String
        let caption: String?

        var id: Kind { kind }
        var isEditable: Bool { kind == .reminder }
    }

    private(set) var pathLoad: PathLoad = .loading
    private(set) var isLinking = false
    private(set) var isWorking = false
    private(set) var journalRevealedUntil: Date?
    /// Başarısız bir silme ya da kayıt. Görünüm uyarı olarak gösterir.
    var actionError: LocalizedStringResource?

    let services: AppServices
    @ObservationIgnored private var journalHideTask: Task<Void, Never>?

    init(services: AppServices) {
        self.services = services
    }

    var record: ProfileRecord? { services.profile.record }

    var activePath: ActivePath? {
        if case .active(let path) = pathLoad { return path }
        return nil
    }

    /// Aktif yol ve profil kaydı birlikte okunur. Kayıt okunamazsa cihazdaki son
    /// kayıt gösterilir — kullanıcı sayfayı hiçbir zaman boş görmemeli, ama
    /// uydurulmuş bir şey de görmemeli.
    func load() async {
        let backend = services.backend
        let token: String
        do {
            token = try await services.auth.validAccessToken()
        } catch {
            pathLoad = .unavailable
            return
        }

        async let pathRequest = backend.activePath(accessToken: token)
        async let snapshotRequest = backend.profileSnapshot(accessToken: token)

        do {
            if let path = try await pathRequest, !path.steps.isEmpty {
                pathLoad = .active(path)
            } else {
                pathLoad = .none
            }
        } catch {
            pathLoad = .unavailable
        }

        do {
            let snapshot = try await snapshotRequest
            if !Self.usesDebugRecord { services.profile.apply(snapshot) }
        } catch {
            services.observability.capture(.profileSync)
        }

        #if DEBUG
        if let fallback = MeDebugSeed.activePath(replacing: activePath) {
            pathLoad = .active(fallback)
        }
        #endif
    }

    // MARK: - Başlık

    var displayName: String? { record?.displayName }
    var pathTitle: String? { activePath?.title }

    var headerDetail: String? {
        guard let path = activePath else { return nil }
        guard let next = path.nextStep else { return String(localized: Copy.Me.pathFinishedHeader) }
        let position = String(localized: Copy.Me.stepPosition(day: next.day))
        guard let phase = Self.phase(day: next.day, stepCount: path.steps.count) else { return position }
        return "\(String(localized: phase.label)) · \(position)"
    }

    // MARK: - Durum

    var isInCrisisMode: Bool { record?.crisisSignalAt != nil }

    var supportPlacement: SupportPlacement {
        if isInCrisisMode { return .top }
        if change?.allWorsened == true { return .belowChange }
        return .standard
    }

    // MARK: - Ne değişti

    /// Yalnızca gerçek bir karşılaştırma varsa (baseline + en az bir yol içi
    /// ölçüm). Beklenti durumu çizilmez.
    var change: ChangeSummary? {
        guard let record,
              let summary = ChangeAnalysis.summary(
                  measurements: measurements(forPath: comparisonPathID),
                  category: record.primaryCategory,
                  pathStepCount: activePath?.steps.count,
                  isFinished: activePath.map { $0.nextStep == nil } ?? !record.pathArchive.isEmpty
              ),
              !summary.isPending
        else { return nil }
        return summary
    }

    func series(for layer: MeasurementLayer) -> [ChangeAnalysis.Point] {
        guard let record else { return [] }
        return ChangeAnalysis.series(
            for: layer,
            measurements: measurements(forPath: comparisonPathID),
            category: record.primaryCategory
        )
    }

    func itemChanges(for layer: MeasurementLayer) -> (most: ChangeAnalysis.ItemChange?, least: ChangeAnalysis.ItemChange?) {
        guard let record else { return (nil, nil) }
        return ChangeAnalysis.itemChanges(
            for: layer,
            measurements: measurements(forPath: comparisonPathID),
            category: record.primaryCategory
        )
    }

    /// Yeni bir ölçüm ilk kez görülüyorsa true döner ve onu görülmüş işaretler.
    func consumeChangeReveal() -> Bool {
        guard let id = change?.latestMeasurementID, record?.revealedMeasurementID != id else {
            return false
        }
        services.profile.markMeasurementRevealed(id)
        return true
    }

    // MARK: - Defter

    var showsJournalSection: Bool { !journalPreview.isEmpty }

    /// Başlangıç cümlesi her zaman ilk sırada, altında en yeni iki kayıt.
    var journalPreview: [JournalItem] {
        guard let journal = record?.journal, !journal.isEmpty else { return [] }
        let origin = journal.first { $0.source == .origin }
        let rest = journal
            .filter { $0.id != origin?.id }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(origin == nil ? 3 : 2)
        return ([origin].compactMap { $0 } + rest).map { item(for: $0, excerpted: true) }
    }

    var hasMoreJournal: Bool { (record?.journal.count ?? 0) > journalPreview.count }

    var journalGroups: [JournalGroup] {
        let calendar = Calendar.current
        let now = Date.now
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        var groups: [JournalGroup] = []

        for entry in (record?.journal ?? []).sorted(by: { $0.createdAt > $1.createdAt }) {
            let key: String
            let title: String
            if calendar.isDate(entry.createdAt, equalTo: now, toGranularity: .weekOfYear) {
                key = "this-week"
                title = String(localized: Copy.Me.thisWeek)
            } else if calendar.isDate(entry.createdAt, equalTo: lastWeek, toGranularity: .weekOfYear) {
                key = "last-week"
                title = String(localized: Copy.Me.lastWeek)
            } else {
                title = MeFormat.monthYear(entry.createdAt)
                key = title
            }
            let item = item(for: entry, excerpted: false, includesQuestion: true)
            if let index = groups.firstIndex(where: { $0.id == key }) {
                groups[index].items.append(item)
            } else {
                groups.append(JournalGroup(id: key, title: title, items: [item]))
            }
        }
        return groups
    }

    func journalItems(forPath id: UUID) -> [JournalItem] {
        (record?.journal ?? [])
            .filter { $0.pathID == id }
            .sorted { $0.createdAt < $1.createdAt }
            .map { item(for: $0, excerpted: false, includesQuestion: true) }
    }

    var hasJournal: Bool { !(record?.journal.isEmpty ?? true) }

    var isJournalObscured: Bool {
        guard record?.privacy.hidesJournal == true else { return false }
        return !(journalRevealedUntil.map { $0 > .now } ?? false)
    }

    func revealJournal() {
        journalRevealedUntil = .now.addingTimeInterval(30)
        journalHideTask?.cancel()
        journalHideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { return }
            self?.journalRevealedUntil = nil
        }
    }

    func deletionMessage(for item: JournalItem) -> LocalizedStringResource {
        if case .origin = item.target { return Copy.Me.journalDeleteOriginBody }
        return Copy.Me.journalDeleteBody
    }

    /// Sunucudan silinir, sonra cihazdan. Sunucu reddederse cihazdaki cümle de
    /// yerinde kalır — silinmiş gibi görünüp sunucuda duran bir cümle, silme
    /// hakkını yalanlamak olurdu.
    func delete(_ item: JournalItem) async {
        await performDeletion(item.target)
    }

    func deleteJournal() async {
        await performDeletion(.all)
    }

    private func performDeletion(_ target: JournalDeletionTarget) async {
        isWorking = true
        defer { isWorking = false }
        do {
            if !Self.usesDebugRecord {
                let token = try await services.auth.validAccessToken()
                try await services.backend.deleteJournal(target, accessToken: token)
            }
            services.profile.removeJournal(target)
        } catch {
            services.observability.capture(.profileSync)
            actionError = Copy.Me.journalDeleteFailed
        }
    }

    // MARK: - Yürüdüğün yollar

    var showsSealsSection: Bool { !seals.isEmpty }

    var seals: [SealItem] {
        var items: [SealItem] = []

        if let path = activePath {
            let walked = path.completedStepCount
            let isFinished = path.nextStep == nil
            let detail: String = isFinished
                ? completedOutcomeText(pathID: path.id, stepCount: path.steps.count)
                : String(localized: walked == 0 ? Copy.Me.pathJustStarted : Copy.Me.pathActive(walked: walked))
            items.append(SealItem(
                id: "active-\(path.id.uuidString)",
                pathID: path.id,
                title: path.title,
                detail: detail,
                meta: String(localized: Copy.Me.pathSteps(path.steps.count)),
                headline: nil,
                style: isFinished ? .completed : .active,
                stepCount: path.steps.count,
                walkedFraction: Double(walked) / Double(max(path.steps.count, 1))
            ))
        }

        for entry in (record?.pathArchive ?? []).sorted(by: { $0.endedAt > $1.endedAt })
        where entry.id != activePath?.id {
            let isCompleted = entry.status == .completed
            let range = String(localized: Copy.Me.pathDateRange(
                start: MeFormat.dayMonth(entry.startedAt),
                end: MeFormat.dayMonth(entry.endedAt)
            ))
            items.append(SealItem(
                id: "archive-\(entry.id.uuidString)",
                pathID: entry.id,
                title: entry.title,
                detail: "\(outcomeText(for: entry)) · \(MeFormat.dayMonth(entry.endedAt))",
                meta: "\(range) · \(String(localized: Copy.Me.pathSteps(entry.stepCount)))",
                headline: entry.bucket?.badgeShowsNumbers == true ? entry.headlineChange : nil,
                style: isCompleted ? .completed : .stopped,
                stepCount: entry.stepCount,
                walkedFraction: isCompleted
                    ? 1
                    : Double(entry.walkedSteps) / Double(max(entry.stepCount, 1))
            ))
        }
        return items
    }

    func seal(id: String) -> SealItem? {
        seals.first { $0.id == id }
    }

    private func outcomeText(for entry: PathArchiveEntry) -> String {
        guard entry.status == .completed else {
            return String(localized: Copy.Me.pathStopped(walked: entry.walkedSteps))
        }
        return completedOutcomeText(pathID: entry.id, stepCount: entry.stepCount, bucket: entry.bucket)
    }

    /// Ana sayfada **sayı yok**: kova kelimeyle söylenir. Kova C'de yalnızca süre
    /// yazar — emek tanınır, sonuç uydurulmaz. Son ölçüm yoksa kova da yok.
    private func completedOutcomeText(pathID: UUID, stepCount: Int, bucket: OutcomeBucket? = nil) -> String {
        switch bucket ?? outcomeBucket(forPath: pathID) {
        case .clearProgress: String(localized: Copy.Me.pathClearProgress)
        case .partialProgress: String(localized: Copy.Me.pathPartialProgress)
        case .noProgress: String(localized: Copy.Me.pathDays(stepCount))
        case nil: String(localized: Copy.Me.pathCompleted)
        }
    }

    private func outcomeBucket(forPath id: UUID) -> OutcomeBucket? {
        guard let record else { return nil }
        return ChangeAnalysis.bucket(measurements: measurements(forPath: id), category: record.primaryCategory)
    }

    /// Karşılaştırılan yol: aktif (ya da yeni bitmiş) yol; yoksa en son biten.
    private var comparisonPathID: UUID? {
        activePath?.id ?? record?.pathArchive.max { $0.endedAt < $1.endedAt }?.id
    }

    /// Kullanıcının baseline'ı ve yalnızca o yolun ölçümleri. İki yolun 7. gün
    /// ölçümleri birbirine karışmamalı.
    private func measurements(forPath id: UUID?) -> [MeasurementRecord] {
        (record?.measurements ?? []).filter { $0.point == .baseline || ($0.pathID != nil && $0.pathID == id) }
    }

    // MARK: - Sana göre ayarlananlar

    /// Yalnızca değeri bilinen satırlar. Hazır patikada uzunluk, ton ve ses yok.
    var preferenceItems: [PreferenceItem] {
        guard let record else { return [] }
        var items = [PreferenceItem(
            kind: .reminder,
            value: record.reminder.isEnabled
                ? record.reminder.timeText
                : String(localized: Copy.Me.reminderOffValue),
            caption: reminderSourceCaption
        )]
        if let length = record.sessionLength {
            items.append(PreferenceItem(kind: .sessionLength, value: String(localized: Copy.Me.minutes(length.minutes)), caption: nil))
        }
        if let tone = record.tone {
            items.append(PreferenceItem(kind: .tone, value: String(localized: tone.label), caption: nil))
        }
        if let voice = record.voice {
            items.append(PreferenceItem(kind: .voice, value: String(localized: voice.label), caption: nil))
        }
        return items
    }

    /// Saat kullanıcının B3 cevabından geliyorsa bunu söyler.
    var reminderSourceCaption: String? {
        guard let record, record.reminder.isEnabled, record.reminder.isSuggested,
              let timing = record.timing, timing != .noPattern
        else { return nil }
        return String(localized: Copy.Me.reminderSource(String(localized: timing.label)))
    }

    var reminderSummary: String {
        guard let reminder = record?.reminder else { return "" }
        return reminder.isEnabled ? reminder.timeText : String(localized: Copy.Me.reminderOffValue)
    }

    /// İzin yoksa hatırlatma kapalı kaydedilir — açık görünen ama hiç gelmeyen
    /// bir hatırlatma, kullanıcıya kendi ayarını yalanlatırdı.
    func saveReminder(isEnabled: Bool, hour: Int, minute: Int) async -> ReminderScheduler.Outcome {
        guard var reminder = record?.reminder else { return .cancelled }
        if reminder.hour != hour || reminder.minute != minute {
            reminder.isSuggested = false
        }
        reminder.hour = hour
        reminder.minute = minute
        reminder.isEnabled = isEnabled
        let outcome = await ReminderScheduler.apply(reminder)
        if outcome == .denied { reminder.isEnabled = false }
        services.profile.setReminder(reminder)
        return outcome
    }

    // MARK: - Hesap

    var showsAnonymousCard: Bool {
        guard record != nil, services.auth.session?.isAnonymous == true else { return false }
        return !(record?.anonymousCardHiddenUntil.map { $0 > .now } ?? false)
    }

    var isAccountLinked: Bool { services.auth.session.map { !$0.isAnonymous } ?? false }
    var authErrorMessage: LocalizedStringResource? { services.auth.errorMessage }

    func link(_ provider: AuthProvider) async {
        isLinking = true
        let succeeded = await services.auth.link(provider: provider)
        services.observability.capture(.accountLinkFinished(provider: provider, succeeded: succeeded))
        isLinking = false
    }

    func hideAnonymousCard() {
        services.profile.hideAnonymousCard(until: .now.addingTimeInterval(30 * 24 * 60 * 60))
    }

    /// Ad serbest metin: cihazda ve sunucuda kriz taramasından geçer. Sinyal
    /// varsa ad kaydedilmez ve sayfa destek öncelikli hâline döner.
    func saveName(_ raw: String) async -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if CrisisClassifier.evaluate(trimmed).hasSignal {
            services.profile.markCrisisSignal()
            return true
        }
        isWorking = true
        defer { isWorking = false }
        do {
            if !Self.usesDebugRecord {
                let token = try await services.auth.validAccessToken()
                if try await services.backend.updateDisplayName(
                    trimmed.isEmpty ? nil : trimmed,
                    accessToken: token
                ) == .crisis {
                    services.profile.markCrisisSignal()
                    return true
                }
            }
            services.profile.setDisplayName(trimmed.isEmpty ? nil : trimmed)
            return true
        } catch {
            services.observability.capture(.profileSync)
            actionError = Copy.Me.Settings.nameFailed
            return false
        }
    }

    /// Hesabı ve bütün verileri sunucudan siler, sonra cihazı temizler ve oturumu
    /// kapatır. Sunucu silmeyi tamamlamadıysa cihazda hiçbir şey silinmez.
    func deleteAccount() async -> Bool {
        isWorking = true
        defer { isWorking = false }
        do {
            if !Self.usesDebugRecord {
                let token = try await services.auth.validAccessToken()
                try await services.backend.deleteAccount(accessToken: token)
            }
            ReminderScheduler.cancel()
            await services.appLock.setEnabled(false)
            services.profile.erase()
            await services.auth.signOut()
            return true
        } catch {
            services.observability.capture(.profileSync)
            actionError = Copy.Me.Settings.deleteAccountFailed
            return false
        }
    }

    // MARK: - Gizlilik ve veri

    var appLockEnabled: Bool { record?.privacy.appLockEnabled ?? false }

    func setAppLock(_ enabled: Bool) async {
        await services.appLock.setEnabled(enabled)
    }

    var hidesJournal: Bool { record?.privacy.hidesJournal ?? false }

    func setHidesJournal(_ hides: Bool) {
        guard var privacy = record?.privacy else { return }
        privacy.hidesJournal = hides
        services.profile.setPrivacy(privacy)
    }

    var analyticsConsent: Bool { services.observability.analyticsConsent }

    func setAnalyticsConsent(_ consent: Bool) {
        services.observability.setAnalyticsConsent(consent)
    }

    var exportPayload: ProfileExport? {
        guard let record, let data = try? ProfileCoding.makeEncoder().encode(record) else { return nil }
        return ProfileExport(data: data)
    }

    var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return String(localized: Copy.Me.version(version, build: build))
    }

    // MARK: - Yardımcılar

    /// DEBUG senaryolarında sunucuya dokunulmaz: örnek kayıt gerçek hesabın
    /// verisini ezmesin, silme de gerçek hesabı silmesin.
    private static var usesDebugRecord: Bool {
        #if DEBUG
        MeDebugSeed.scenario != nil
        #else
        false
        #endif
    }

    private func item(for entry: JournalEntry, excerpted: Bool, includesQuestion: Bool = false) -> JournalItem {
        let date = MeFormat.relativeDay(entry.createdAt)
        let caption: LocalizedStringResource
        let target: JournalDeletionTarget
        switch entry.source {
        case .origin:
            caption = Copy.Me.journalOrigin(date: date)
            target = .origin
        case .avoidance:
            caption = Copy.Me.journalAvoidance(date: date)
            target = .origin
        case .reflection:
            caption = entry.stepDay.map { Copy.Me.journalAfterStep(day: $0, date: date) }
                ?? Copy.Me.journalOrigin(date: date)
            target = .answer(entry.id)
        }
        return JournalItem(
            id: entry.id,
            text: excerpted ? Self.excerpt(entry.text) : entry.text,
            caption: String(localized: caption),
            detail: includesQuestion
                ? entry.question.map { String(localized: Copy.Me.journalQuestion($0)) }
                : nil,
            target: target
        )
    }

    /// Uzun cümle **cümle sınırında** kısaltılır, kelime ortasından değil.
    static func excerpt(_ text: String, limit: Int = 180) -> String {
        guard text.count > limit else { return text }
        var result = ""
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { _, range, _, stop in
            let piece = String(text[range])
            if result.isEmpty || result.count + piece.count <= limit {
                result += piece
            } else {
                stop = true
            }
        }
        var trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > limit + 40 {
            let prefix = trimmed.prefix(limit)
            trimmed = prefix.lastIndex(of: " ").map { String(prefix[..<$0]) } ?? String(prefix)
        }
        return trimmed.count < text.trimmingCharacters(in: .whitespacesAndNewlines).count
            ? trimmed + " …"
            : trimmed
    }

    private static func phase(day: Int, stepCount: Int) -> PathPhase? {
        guard let length = PathLength(rawValue: stepCount) else { return nil }
        return PathPlan.phase(on: day, length: length)
    }
}

/// "Bu cihazdaki kaydını indir" dosyası — KVKK Madde 11 / GDPR Madde 15, 20.
nonisolated struct ProfileExport: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { export in
            let url = URL.temporaryDirectory.appending(path: "patika-kaydi.json")
            try export.data.write(to: url, options: [.atomic, .completeFileProtection])
            return SentTransferredFile(url)
        }
    }
}
