import Foundation
import Observation

/// `ProfileRecord`un tek sahibi.
///
/// Dosya `completeUnlessOpen` korumasıyla yazılır: telefon kilitliyken okunamaz,
/// ama kilit anında açık olan bir yazma (oturum sonu cevabı) yarıda kalmaz.
/// Kaydın içinde kişinin kendi cümleleri var — varsayılan koruma sınıfı
/// ("ilk kilit açılışına kadar") bunun için gevşek.
@Observable
@MainActor
final class ProfileStore {
    private(set) var record: ProfileRecord?
    @ObservationIgnored private let fileURL: URL?

    init(fileURL: URL?) {
        self.fileURL = fileURL
        record = fileURL.flatMap(Self.read)
    }

    static func live() -> ProfileStore {
        let directory = URL.applicationSupportDirectory
            .appending(path: "Profile", directoryHint: .isDirectory)
        return ProfileStore(fileURL: directory.appending(path: "record.json"))
    }

    /// Diske hiç yazmayan kayıt — önizleme ve DEBUG senaryoları.
    static func ephemeral(_ record: ProfileRecord?) -> ProfileStore {
        let store = ProfileStore(fileURL: nil)
        store.record = record
        return store
    }

    // MARK: - Onboarding

    /// Onboarding cevaplarını kayda işler. İki kez çağrılabilir (G2 cevabı ve
    /// akışın sonu): başlangıç cümlesi ve baseline yalnızca bir kez eklenir.
    ///
    /// Kriz sinyali verilmiş bir akış **kaydedilmez** — PRD §11.1: sinyal varsa
    /// kayıt istenmez.
    func recordOnboarding(_ draft: OnboardingDraft, at date: Date = .now) {
        guard !draft.crisisDetected else { return }
        var next = record ?? .empty(startedAt: date)
        next.mergeOnboarding(draft)
        commit(next)
    }

    // MARK: - Sunucu

    /// Sunucunun gerçeği kayda işlenir: ad, ilk cümleler, cevaplar, ölçümler,
    /// yollar ve yolun kurulduğu tercihler **sunucudan** gelir. Yalnızca cihaza ait
    /// olanlar (hatırlatma, gizlilik, uygulama kilidi, görülmüş ölçüm) korunur.
    ///
    /// Uygulama yeniden kurulduğunda ya da başka bir cihazda açıldığında sayfa
    /// böylece aynı kaydı gösterir.
    func apply(_ snapshot: ProfileSnapshot) {
        let isNew = record == nil
        let serverStart: Date = snapshot.profile?.createdAt ?? snapshot.origin?.createdAt ?? Date.now
        var next: ProfileRecord = record ?? ProfileRecord.empty(startedAt: serverStart)
        next.mergeServer(snapshot)
        if isNew, let timing = next.timing, timing != .noPattern {
            next.reminder = ReminderSetting(
                isEnabled: false,
                hour: timing.suggestedReminderHour,
                minute: 30,
                isSuggested: true
            )
        }
        commit(next)
    }

    /// Yol içi ölçüm — sunucuya yazıldıktan sonra kayda da işlenir, sayfa bir
    /// sonraki yenilemeyi beklemeden görsün.
    func appendMeasurement(_ measurement: MeasurementRecord) {
        var next = record ?? .empty(startedAt: .now)
        next.measurements.removeAll { $0.point == measurement.point && $0.pathID == measurement.pathID }
        next.measurements.append(measurement)
        commit(next)
    }

    func removeJournal(_ target: JournalDeletionTarget) {
        update { record in
            switch target {
            case .answer(let id):
                record.journal.removeAll { $0.id == id }
            case .origin:
                record.journal.removeAll { $0.source == .origin || $0.source == .avoidance }
            case .note(let id):
                record.notes.removeAll { $0.id == id }
            case .allNotes:
                record.notes.removeAll()
            case .all:
                record.journal.removeAll()
                record.notes.removeAll()
            }
        }
    }

    // MARK: - Notlar ve rozetler

    /// Sunucunun döndürdüğü notu kayda işler (yeni ya da düzenlenmiş).
    func upsertNote(_ note: JournalNote) {
        update { record in
            if let index = record.notes.firstIndex(where: { $0.id == note.id }) {
                record.notes[index] = note
            } else {
                record.notes.append(note)
            }
        }
    }

    /// Adım tamamlanınca, sunucunun bir sonraki okumasını beklemeden: haftalık
    /// ritim ve seri rozetleri hemen doğru olsun.
    func appendCompletedStepDate(_ date: Date = .now) {
        update { $0.completedStepDates.append(date) }
    }

    /// Yeni rozetleri kayda ekler; var olanlar yerinde kalır. Rozet geri alınmaz.
    func recordEarnedBadges(_ badges: [EarnedBadge]) {
        update { record in
            let known = Set(record.earnedBadges.map(\.badgeID))
            record.earnedBadges += badges.filter { !known.contains($0.badgeID) }
        }
    }

    // MARK: - Defter

    func appendReflection(
        text: String,
        question: String?,
        stepDay: Int,
        stepTitle: String?,
        pathID: UUID?,
        at date: Date = .now
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        update {
            $0.journal.append(JournalEntry(
                id: UUID(),
                source: .reflection,
                text: trimmed,
                question: question,
                stepDay: stepDay,
                stepTitle: stepTitle,
                pathID: pathID,
                createdAt: date
            ))
        }
    }

    func deleteJournalEntry(id: UUID) {
        update { $0.journal.removeAll { $0.id == id } }
    }

    func deleteJournal() {
        update { $0.journal.removeAll() }
    }

    // MARK: - Tercihler ve gizlilik

    func setReminder(_ reminder: ReminderSetting) {
        update { $0.reminder = reminder }
    }

    func setDisplayName(_ name: String?) {
        update { $0.displayName = name }
    }

    func setPrivacy(_ privacy: PrivacySettings) {
        update { $0.privacy = privacy }
    }

    // MARK: - Durum

    func markCrisisSignal(at date: Date = .now) {
        update { $0.crisisSignalAt = date }
    }

    func clearCrisisSignal() {
        update { $0.crisisSignalAt = nil }
    }

    func markMeasurementRevealed(_ id: UUID) {
        update { $0.revealedMeasurementID = id }
    }

    func hideAnonymousCard(until date: Date) {
        update { $0.anonymousCardHiddenUntil = date }
    }

    /// Bu cihazdaki kaydı siler. Sunucudaki path etkilenmez.
    func erase() {
        record = nil
        NoteDraftStore.clear()
        guard let fileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Yazma

    private func update(_ change: (inout ProfileRecord) -> Void) {
        guard var next = record else { return }
        change(&next)
        commit(next)
    }

    private func commit(_ next: ProfileRecord) {
        guard next != record else { return }
        record = next
        write(next)
    }

    private func write(_ record: ProfileRecord) {
        guard let fileURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try ProfileCoding.makeEncoder().encode(record)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            // Yazılamayan kayıt bellekte kalır; bir sonraki değişiklik yeniden
            // dener. Kullanıcıya gösterilecek bir şey yok — elindeki kaybolmadı.
        }
    }

    private static func read(from url: URL) -> ProfileRecord? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? ProfileCoding.makeDecoder().decode(ProfileRecord.self, from: data)
    }
}

enum ProfileCoding {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension ProfileRecord {
    static func empty(startedAt date: Date) -> ProfileRecord {
        ProfileRecord(
            displayName: nil,
            categories: [],
            mood: nil,
            timing: nil,
            reminder: ReminderSetting(isEnabled: false, hour: 22, minute: 30, isSuggested: false),
            sessionLength: .standard,
            tone: .calmAndShort,
            voice: .feminine,
            journal: [],
            measurements: [],
            pathArchive: [],
            privacy: PrivacySettings(),
            crisisSignalAt: nil,
            revealedMeasurementID: nil,
            anonymousCardHiddenUntil: nil,
            startedAt: date
        )
    }

    mutating func mergeServer(_ snapshot: ProfileSnapshot) {
        if let profile = snapshot.profile {
            displayName = profile.displayName
            voice = profile.voicePreference.flatMap(VoicePreference.init(rawValue:))
            startedAt = min(startedAt, profile.createdAt)
        }

        let latestPath = snapshot.paths.first
        if let latestPath {
            let pathCategories = latestPath.categories.compactMap(ProblemCategory.init(rawValue:))
            if !pathCategories.isEmpty { categories = pathCategories }
            timing = latestPath.timing.flatMap(ProblemTiming.init(rawValue:)) ?? timing
            tone = latestPath.tone.flatMap(TonePreference.init(rawValue:))
            sessionLength = latestPath.sessionMinutes.flatMap(SessionLength.init(rawValue:))
        }

        let existingOrigin = journal.first { $0.source == .origin }
        let existingAvoidance = journal.first { $0.source == .avoidance }
        notes = snapshot.notes.map {
            JournalNote(id: $0.id, body: $0.body, createdAt: $0.createdAt, updatedAt: $0.updatedAt)
        }
        // Rozet geri alınmaz: sunucudakiler ile cihazda henüz yazılamamış olanlar
        // birleşir, hiçbiri düşmez.
        let serverBadges = snapshot.earnedBadges.compactMap { badge in
            BadgeID(rawValue: badge.id).map { EarnedBadge(badgeID: $0, earnedAt: badge.earnedAt) }
        }
        let serverIDs = Set(serverBadges.map(\.badgeID))
        earnedBadges = serverBadges + earnedBadges.filter { !serverIDs.contains($0.badgeID) }
        completedStepDates = snapshot.completedStepDates
        avatarURL = snapshot.avatarURL

        var entries: [JournalEntry] = []
        if let origin = snapshot.origin {
            if let text = origin.problemText {
                entries.append(JournalEntry(
                    id: existingOrigin?.id ?? UUID(), source: .origin, text: text,
                    question: nil, stepDay: nil, stepTitle: nil, pathID: nil,
                    createdAt: origin.createdAt
                ))
            }
            if let text = origin.avoidanceText {
                entries.append(JournalEntry(
                    id: existingAvoidance?.id ?? UUID(), source: .avoidance, text: text,
                    question: nil, stepDay: nil, stepTitle: nil, pathID: nil,
                    createdAt: origin.createdAt
                ))
            }
        }
        entries += snapshot.answers.map { answer in
            JournalEntry(
                id: answer.id, source: .reflection, text: answer.answer,
                question: answer.question, stepDay: answer.stepDay, stepTitle: answer.stepTitle,
                pathID: answer.pathId, createdAt: answer.createdAt
            )
        }
        journal = entries

        // Ölçüm noktası ait olduğu yolun uzunluğundan çıkar: 14 günlük yolda
        // 14. gün "son", 21 günlük yolda "ara" ölçümdür.
        let lengthByPath = Dictionary(
            snapshot.paths.map { ($0.id, $0.lengthDays) },
            uniquingKeysWith: { first, _ in first }
        )
        measurements = snapshot.measurements.compactMap { row in
            let pathID = row.pathId ?? (row.day == 0 ? nil : latestPath?.id)
            let length = pathID.flatMap { lengthByPath[$0] }
            guard let point = MeasurementSchedule.point(forServerDay: row.day, pathLength: length) else {
                return nil
            }
            return MeasurementRecord(
                id: row.id,
                point: point,
                stepDay: row.day,
                takenAt: row.createdAt,
                responses: row.responses,
                pathID: point == .baseline ? nil : pathID
            )
        }

        pathArchive = snapshot.paths
            .filter { $0.status == "completed" || $0.status == "cancelled" }
            .map { path in
                PathArchiveEntry(
                    id: path.id,
                    title: path.title,
                    stepCount: path.lengthDays,
                    walkedSteps: path.completedSteps,
                    startedAt: path.createdAt,
                    endedAt: path.completedAt ?? path.createdAt,
                    status: path.status == "completed" ? .completed : .abandoned,
                    bucket: nil,
                    headlineChange: nil
                )
            }
    }

    /// Taslağı kayda işler. Tercihler her seferinde güncellenir; başlangıç
    /// cümlesi, kaçınma cümlesi ve baseline **bir kez** eklenir.
    mutating func mergeOnboarding(_ draft: OnboardingDraft) {
        displayName = draft.displayName
        categories = draft.categories
        mood = draft.currentMood
        timing = draft.timing
        let isSuggested = draft.timing.map {
            $0 != .noPattern && $0.suggestedReminderHour == draft.reminderHour
        } ?? false
        reminder = ReminderSetting(
            isEnabled: reminder.isEnabled,
            hour: draft.reminderHour,
            minute: draft.reminderMinute,
            isSuggested: isSuggested
        )
        sessionLength = draft.sessionLength
        tone = draft.resolvedTonePreference
        voice = draft.resolvedVoicePreference

        if draft.hasOwnWords, !journal.contains(where: { $0.source == .origin }) {
            journal.append(JournalEntry(
                id: UUID(),
                source: .origin,
                text: draft.problemText.trimmingCharacters(in: .whitespacesAndNewlines),
                question: nil,
                stepDay: nil,
                stepTitle: nil,
                pathID: nil,
                createdAt: startedAt
            ))
        }

        if let avoidance = draft.avoidanceText?.trimmingCharacters(in: .whitespacesAndNewlines),
           !avoidance.isEmpty,
           !journal.contains(where: { $0.source == .avoidance }) {
            journal.append(JournalEntry(
                id: UUID(),
                source: .avoidance,
                text: avoidance,
                question: nil,
                stepDay: nil,
                stepTitle: nil,
                pathID: nil,
                createdAt: startedAt
            ))
        }

        if !draft.measurementResponses.isEmpty,
           !measurements.contains(where: { $0.point == .baseline }) {
            measurements.append(MeasurementRecord(
                id: UUID(),
                point: .baseline,
                stepDay: 0,
                takenAt: startedAt,
                responses: draft.measurementResponses,
                pathID: nil
            ))
        }
    }
}
