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
        /// Kullanıcının kendi yazdığı not ise kimliği; düzenlenebilir olan yalnızca
        /// bunlar. Adım cevapları yalnızca silinir.
        var noteID: UUID?

        var isOwnNote: Bool { noteID != nil }
    }

    enum NoteSaveResult: Equatable {
        /// Kaydedildi; bu kayıtla yeni kazanılan rozetler (kutlama yaprağı için).
        case saved(newBadges: [BadgeID])
        /// Kriz sinyali: not yazılmadı, sayfa destek öncelikli hâle geçti.
        case crisis
        case failed
    }

    struct JournalGroup: Identifiable, Equatable {
        let id: String
        let title: String
        var items: [JournalItem]
    }

    struct PreferenceItem: Identifiable, Equatable {
        enum Kind: String {
            case reminder
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
        // Yenileme sırasında geçici boş/hatalı yanıt, doğrulanmış yol başlığını
        // karttan kaldırmamalı.
        let previouslyLoadedPath = activePath
        let token: String
        do {
            token = try await services.auth.validAccessToken()
        } catch {
            if previouslyLoadedPath == nil { pathLoad = .unavailable }
            return
        }

        async let pathRequest = backend.activePath(accessToken: token)
        async let snapshotRequest = backend.profileSnapshot(accessToken: token)

        do {
            if let path = try await pathRequest, !path.steps.isEmpty {
                pathLoad = .active(path)
            } else if previouslyLoadedPath == nil {
                pathLoad = .none
            }
        } catch {
            if previouslyLoadedPath == nil { pathLoad = .unavailable }
        }

        do {
            let snapshot = try await snapshotRequest
            if !Self.usesDebugRecord {
                services.profile.apply(snapshot)
                await services.avatar.reconcile(withServerURL: snapshot.avatarURL, updatedAt: snapshot.avatarUpdatedAt)
                // Rozetler sessizce uzlaşır: kutlama yaprağı yalnızca oturum sonu
                // ve defterde açılır (BadgeEarnedSheet), sayfayı açmak değil.
                let awarder = BadgeAwarder(services: services)
                awarder.award(activePath: activePath)
                awarder.syncUnsynced(serverBadges: snapshot.earnedBadges)
            }
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

    // MARK: - Kimlik kartı

    /// Yoldaki ilerleme, 0…1. Yol yoksa ve kriz modunda nil: iz çizilmez.
    var stepProgress: Double? {
        guard !isInCrisisMode, let path = activePath, !path.steps.isEmpty else { return nil }
        return Double(path.completedStepCount) / Double(path.steps.count)
    }

    /// Bu haftanın yedi günü. Kriz modunda nil: seri o anda yanlış bir dil olurdu.
    var weeklyRhythm: WeeklyRhythm? {
        guard !isInCrisisMode, let record else { return nil }
        return WeeklyRhythm.make(completedStepDates: record.completedStepDates)
    }

    /// Kimlik kartının VoiceOver özeti: "Taner, Uykuya dönüş yolu, 12. adım,
    /// Farkındalık fazı, bu hafta 3 gün". Yalnızca gerçekten var olan parçalar.
    var identityAccessibility: String {
        var parts: [String] = []
        if let displayName { parts.append(displayName) }
        if let pathTitle { parts.append(pathTitle) }
        if let path = activePath, let next = path.nextStep {
            parts.append(String(localized: Copy.Me.stepPosition(day: next.day)))
            if let phase = Self.phase(day: next.day, stepCount: path.steps.count) {
                parts.append(String(localized: phase.label))
            }
        } else if headerDetail != nil {
            parts.append(headerDetail ?? "")
        }
        if let rhythm = weeklyRhythm, rhythm.completedCount > 0 {
            parts.append(String(localized: Copy.Me.weekDays(rhythm.completedCount)))
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Defter kartı

    /// Kartın bulanık önizlemesi: kullanıcının en son yazdığı şey — not ya da
    /// adım cevabı. nil ise kart davet metnini çizer.
    ///
    /// `hidesJournal` açıkken **nil**: gizlenen cümlenin bulanık şekli bile
    /// sızdırmamalı. Uygulama kilidi ve perde (`PrivacyShieldView`) zaten sayfanın
    /// tamamını örter.
    var journalCardPreview: String? {
        guard let record, !record.privacy.hidesJournal else { return nil }
        let latestNote = record.notes.max { $0.updatedAt < $1.updatedAt }
        let latestAnswer = record.journal.filter { $0.source == .reflection }.max { $0.createdAt < $1.createdAt }
        let text: String? = switch (latestNote, latestAnswer) {
        case (let note?, let answer?): note.updatedAt >= answer.createdAt ? note.body : answer.text
        case (let note?, nil): note.body
        case (nil, let answer?): answer.text
        case (nil, nil): record.journal.first { $0.source == .origin }?.text
        }
        return text.map { Self.excerpt($0, limit: 120) }
    }

    // MARK: - Rozetler

    var earnedBadges: [EarnedBadge] { record?.earnedBadges ?? [] }
    var nextBadge: BadgeID? { BadgeCatalog.next(after: earnedBadges) }

    /// Kriz modunda rozet rafı hiç çizilmez.
    var showsBadges: Bool { !isInCrisisMode }

    // MARK: - Fotoğraf

    /// Seçilen fotoğrafı hazırlar (kare, 512 px, EXIF'siz), sunucuya yazar ve
    /// önbelleğe koyar. Sunucu yazamazsa önbellek de değişmez: ekranda görünen
    /// fotoğraf, başka bir cihazda görünecek olanla aynı kalır.
    func setPhoto(_ data: Data) async {
        guard let jpeg = await Task.detached(priority: .userInitiated, operation: { AvatarStore.prepare(data) }).value else {
            actionError = Copy.Me.photoFailed
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            if !Self.usesDebugRecord {
                let token = try await services.auth.validAccessToken()
                guard let userID = services.auth.session?.userID else { throw BackendError.invalidResponse }
                try await services.backend.uploadAvatar(jpeg, userID: userID, accessToken: token)
            }
            services.avatar.cache(jpeg)
        } catch {
            services.observability.capture(.profileSync)
            actionError = Copy.Me.photoFailed
        }
    }

    func removePhoto() async {
        isWorking = true
        defer { isWorking = false }
        do {
            if !Self.usesDebugRecord {
                let token = try await services.auth.validAccessToken()
                guard let userID = services.auth.session?.userID else { throw BackendError.invalidResponse }
                try await services.backend.removeAvatar(userID: userID, accessToken: token)
            }
            services.avatar.clear()
        } catch {
            services.observability.capture(.profileSync)
            actionError = Copy.Me.photoFailed
        }
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

    /// Adım cevapları, ilk cümleler ve kullanıcının kendi notları tek akışta,
    /// en yeni üstte.
    var journalGroups: [JournalGroup] {
        let calendar = Calendar.current
        let now = Date.now
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now

        var dated: [(date: Date, item: JournalItem)] = (record?.journal ?? []).map {
            ($0.createdAt, item(for: $0, excerpted: false, includesQuestion: true))
        }
        dated += (record?.notes ?? []).map { ($0.createdAt, item(for: $0)) }
        dated.sort { $0.date > $1.date }

        var groups: [JournalGroup] = []
        for (date, item) in dated {
            let key: String
            let title: String
            if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
                key = "this-week"
                title = String(localized: Copy.Me.thisWeek)
            } else if calendar.isDate(date, equalTo: lastWeek, toGranularity: .weekOfYear) {
                key = "last-week"
                title = String(localized: Copy.Me.lastWeek)
            } else {
                title = MeFormat.monthYear(date)
                key = title
            }
            if let index = groups.firstIndex(where: { $0.id == key }) {
                groups[index].items.append(item)
            } else {
                groups.append(JournalGroup(id: key, title: title, items: [item]))
            }
        }
        return groups
    }

    /// Defterde hiçbir şey yok mu (ne cevap, ne ilk cümle, ne not).
    var hasJournal: Bool {
        guard let record else { return false }
        return !record.journal.isEmpty || !record.notes.isEmpty
    }

    // MARK: - Notlar

    /// Kullanıcının kendi notu. Sıra bilinçli:
    ///
    /// 1. Cihazdaki ön filtre (`CrisisClassifier`) — ağ olmadan da çalışır.
    /// 2. Sunucu taraması (`save-note`) — istemci filtresi sinyal vermediyse de
    ///    kendi taramasını yapar; sunucu reddederse not hiç var olmaz.
    ///
    /// Sinyal iki katmanda da tek yönlüdür: not yazılmaz, `crisisSignalAt`
    /// işaretlenir. Sonucu görüntüleyen çağırıdır (destek ekranı).
    func saveNote(id: UUID?, body raw: String) async -> NoteSaveResult {
        let body = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, body.utf16.count <= JournalNote.maxLength else { return .failed }

        if CrisisClassifier.evaluate(body).hasSignal {
            services.profile.markCrisisSignal()
            return .crisis
        }

        isWorking = true
        defer { isWorking = false }
        do {
            if Self.usesDebugRecord {
                let existing = record?.notes.first { $0.id == id }
                let now = Date.now
                services.profile.upsertNote(JournalNote(
                    id: id ?? UUID(), body: body,
                    createdAt: existing?.createdAt ?? now, updatedAt: now
                ))
            } else {
                let token = try await services.auth.validAccessToken()
                switch try await services.backend.saveNote(id: id, body: body, accessToken: token) {
                case .crisis:
                    services.profile.markCrisisSignal()
                    return .crisis
                case .saved(let note):
                    services.profile.upsertNote(note)
                }
            }
            let fresh = BadgeAwarder(services: services).award(activePath: activePath)
            return .saved(newBadges: fresh)
        } catch {
            services.observability.capture(.profileSync)
            return .failed
        }
    }

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

    // MARK: - Karşılaştırma yolu

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
        let items = [PreferenceItem(
            kind: .reminder,
            value: record.reminder.isEnabled
                ? record.reminder.timeText
                : String(localized: Copy.Me.reminderOffValue),
            caption: reminderSourceCaption
        )]
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
        services.observability.capture(.reminderPreferenceChanged(enabled: reminder.isEnabled))
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
            services.promiseSignature.clear()
            services.avatar.clear()
            await services.auth.signOut()
            return true
        } catch {
            services.observability.capture(.profileSync)
            actionError = Copy.Me.Settings.deleteAccountFailed
            return false
        }
    }

    /// Hesaptan çıkar; sunucudaki kayıt **silinmez**, yalnızca cihazdaki oturum ve
    /// yerel veri sıfırlanır (aynı Apple/Google hesabıyla tekrar giriş yapılabilir).
    /// Yalnızca bağlı (anonim olmayan) bir hesapta anlamlı — anonim kimliğin geri
    /// dönüşü olmadığı için `AccountLinkSheet` `isAccountLinked` false iken bu
    /// satırı hiç göstermez.
    func signOut() async {
        isWorking = true
        defer { isWorking = false }
        ReminderScheduler.cancel()
        await services.appLock.setEnabled(false)
        services.profile.erase()
        services.promiseSignature.clear()
        services.avatar.clear()
        await services.auth.signOut()
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

    private func item(for note: JournalNote) -> JournalItem {
        JournalItem(
            id: note.id,
            text: note.body,
            caption: String(localized: Copy.Me.journalNoteCaption(date: MeFormat.relativeDay(note.createdAt))),
            detail: nil,
            target: .note(note.id),
            noteID: note.id
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
