#if DEBUG
import Foundation

/// "Ben" sekmesinin durumlarını simülatörde görmek için örnek kayıtlar.
///
/// `-patika-debug-me pending|compared|worse|finished|crisis|empty|v2full|v2badges`
/// (Ben v2: `v2empty` = `empty`, `v2crisis` = `crisis`) kaydı diske
/// yazmayan bir depoyla kurar; `-patika-debug-tab ben` uygulamayı o sekmede açar.
/// 7. gün ölçümü henüz gerçek akışta yok — bu senaryolar olmadan değişim kartının
/// dolu hâli hiç görülemezdi.
///
/// Örnek ölçüm cevapları `MeasurementLibrary`den türetilir, elle yazılmaz.
enum MeDebugSeed {
    enum Scenario: String {
        case pending, compared, worse, finished, crisis, empty
        /// Ben v2: karşılaştırma + notlar + rozetler + bu haftanın adım günleri.
        case v2full
        /// Ben v2: neredeyse bütün rozetler kazanılmış.
        case v2badges
    }

    static var scenario: Scenario? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-patika-debug-me"),
              arguments.index(after: index) < arguments.endIndex
        else { return nil }
        let name = arguments[arguments.index(after: index)].lowercased()
        switch name {
        case "v2empty": return .empty
        case "v2crisis": return .crisis
        default: return Scenario(rawValue: name)
        }
    }

    /// `-patika-debug-me-anchor journal|paths|preferences|settings` — sayfa o
    /// bölüme kayar; alt bölümler dokunmadan görülebilsin.
    static var anchor: MeAnchor? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-patika-debug-me-anchor"),
              arguments.index(after: index) < arguments.endIndex
        else { return nil }
        return MeAnchor(rawValue: arguments[arguments.index(after: index)].lowercased())
    }

    /// `-patika-debug-me-route journal|badges` — sayfa doğrudan o alt ekranda açılır.
    static var route: MeRoute? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-patika-debug-me-route"),
              arguments.index(after: index) < arguments.endIndex
        else { return nil }
        switch arguments[arguments.index(after: index)].lowercased() {
        case "journal": return .journal
        case "badges": return .badges
        default: return nil
        }
    }

    /// `-patika-debug-me-sheet change|settings|support|note|badge`
    /// (`note` ve `badge` defter sayfasında açılır).
    static var sheet: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-patika-debug-me-sheet"),
              arguments.index(after: index) < arguments.endIndex
        else { return nil }
        return arguments[arguments.index(after: index)].lowercased()
    }

    static func makeStore() -> ProfileStore? {
        guard let scenario else { return nil }
        return .ephemeral(record(for: scenario))
    }

    /// Sunucuda aktif path yoksa senaryonun örnek yolu. "Bitti" senaryosunda
    /// aktif yol yok — tamamlananlar arşivde.
    static func activePath(replacing current: ActivePath?) -> ActivePath? {
        guard current == nil, let scenario, scenario != .finished, scenario != .empty else { return nil }
        let completed: Int = switch scenario {
        case .pending, .crisis: 3
        default: 8
        }
        let now = Date.now
        let steps = (1...21).map { day in
            PathStepRecord(
                id: UUID(),
                day: day,
                title: stepTitles[(day - 1) % stepTitles.count],
                blockIds: [],
                slotCopy: [:],
                audioStatus: .ready,
                question: nil,
                completedAt: day <= completed ? now.addingTimeInterval(Double(day - completed - 1) * day1) : nil
            )
        }
        return ActivePath(
            id: pathID,
            kind: .personalized,
            title: String(localized: ProblemCategory.sleep.provisionalPathTitle),
            steps: steps
        )
    }

    // MARK: - Kayıt

    private static let day1: TimeInterval = 24 * 60 * 60
    private static let pathID = UUID()
    private static let stepTitles = [
        "Nefesle yere inmek", "Zihnin sesini fark etmek", "Düşünceden ayrışma",
        "Bedeni taramak", "Akşamı yavaşlatmak", "Kaygıya yer açmak", "Küçük bir deneme",
    ]

    static func record(for scenario: Scenario) -> ProfileRecord? {
        guard scenario != .empty else { return nil }
        let now = Date.now
        let start = now.addingTimeInterval(-10 * day1)
        let draft = OnboardingDraft.debugSample()
        let category = draft.primaryCategory

        var record = ProfileRecord.empty(startedAt: start)
        record.mergeOnboarding(draft)
        record.reminder.isEnabled = scenario != .pending
        record.journal.append(contentsOf: [
            reflection(
                "Telefonu bıraktığımda ilk kez sessizlik rahatsız etmedi.",
                question: "Bugün zihnin en çok nereye kaçtı?",
                day: 8,
                title: "Düşünceden ayrışma",
                at: now.addingTimeInterval(-1 * day1)
            ),
            reflection(
                "Nefesi saymak işe yaradı ama yarısında yine yarını düşünmeye başladım.",
                question: "Nefese dönmek ne kadar kolaydı?",
                day: 4,
                title: "Bedeni taramak",
                at: now.addingTimeInterval(-5 * day1)
            ),
        ])

        let baseline = draft.measurementResponses
        switch scenario {
        case .pending, .crisis, .empty:
            break
        case .compared, .v2full, .v2badges:
            record.measurements.append(measurement(
                .day7, day: 7, at: now.addingTimeInterval(-2 * day1),
                responses: shifted(baseline, category: category, steps: [.behavior: 2, .selfEfficacy: 1])
            ))
        case .worse:
            record.measurements.append(measurement(
                .day7, day: 7, at: now.addingTimeInterval(-2 * day1),
                responses: shifted(baseline, category: category, steps: [.emotion: -1, .behavior: -1, .selfEfficacy: -1])
            ))
        case .finished:
            record.measurements.append(contentsOf: [
                measurement(
                    .day7, day: 7, at: now.addingTimeInterval(-8 * day1),
                    responses: shifted(baseline, category: category, steps: [.behavior: 1])
                ),
                measurement(
                    .day14, day: 14, at: now.addingTimeInterval(-3 * day1),
                    responses: shifted(baseline, category: category, steps: [.behavior: 2, .selfEfficacy: 1])
                ),
            ])
            record.pathArchive = [
                PathArchiveEntry(
                    id: pathID,
                    title: String(localized: ProblemCategory.sleep.provisionalPathTitle),
                    stepCount: 21,
                    walkedSteps: 21,
                    startedAt: start,
                    endedAt: now.addingTimeInterval(-1 * day1),
                    status: .completed,
                    bucket: .clearProgress,
                    headlineChange: "Uykuya dalma süren %41 kısaldı."
                ),
                PathArchiveEntry(
                    id: UUID(),
                    title: String(localized: ProblemCategory.anxiety.provisionalPathTitle),
                    stepCount: 14,
                    walkedSteps: 6,
                    startedAt: start.addingTimeInterval(-60 * day1),
                    endedAt: start.addingTimeInterval(-50 * day1),
                    status: .abandoned,
                    bucket: nil,
                    headlineChange: nil
                ),
            ]
        }

        if scenario == .crisis { record.crisisSignalAt = now }
        if scenario == .v2full || scenario == .v2badges { seedV2(&record, scenario: scenario, now: now) }
        return record
    }

    /// Ben v2 örnekleri: kullanıcının kendi notları, kazanılmış rozetler ve
    /// bu haftanın adım günleri. Metinler `Copy` dışındadır çünkü kullanıcının
    /// kendi sesi.
    private static func seedV2(_ record: inout ProfileRecord, scenario: Scenario, now: Date) {
        record.notes = [
            JournalNote(
                id: UUID(),
                body: "Bugün yürüyüşten sonra omuzlarım gevşedi. Sebebini bilmiyorum ama kalsın.",
                createdAt: now.addingTimeInterval(-2 * day1),
                updatedAt: now.addingTimeInterval(-2 * day1)
            ),
            JournalNote(
                id: UUID(),
                body: "Akşam telefonu erken bıraktım. Uyumadan önce kafamdaki gürültü biraz azaldı.",
                createdAt: now.addingTimeInterval(-6 * 60 * 60),
                updatedAt: now.addingTimeInterval(-6 * 60 * 60)
            ),
        ]
        record.completedStepDates = [0, 1, 2, 8, 9, 10].map { now.addingTimeInterval(-Double($0) * day1) }

        let earned: [BadgeID] = scenario == .v2badges
            ? BadgeID.allCases.filter { $0 != .week7 && $0 != .pathComplete && $0 != .note10 }
            : [.firstStep, .phaseRelief, .measureDay7, .week3, .noteFirst]
        record.earnedBadges = earned.enumerated().map { index, badge in
            EarnedBadge(badgeID: badge, earnedAt: now.addingTimeInterval(-Double(earned.count - index) * day1))
        }
    }

    private static func reflection(_ text: String, question: String, day: Int, title: String, at date: Date) -> JournalEntry {
        JournalEntry(
            id: UUID(),
            source: .reflection,
            text: text,
            question: question,
            stepDay: day,
            stepTitle: title,
            pathID: pathID,
            createdAt: date
        )
    }

    private static func measurement(
        _ point: MeasurementPoint,
        day: Int,
        at date: Date,
        responses: [String: Double]
    ) -> MeasurementRecord {
        MeasurementRecord(id: UUID(), point: point, stepDay: day, takenAt: date, responses: responses, pathID: pathID)
    }

    /// Katman başına kaç kova iyi (+) ya da kötü (−) yöne kaydırılacağı.
    private static func shifted(
        _ responses: [String: Double],
        category: ProblemCategory,
        steps: [MeasurementLayer: Int]
    ) -> [String: Double] {
        var result = responses
        for item in MeasurementLibrary.items(for: .baseline, category: category) {
            guard let raw = responses[item.id], let step = steps[item.layer], step != 0 else { continue }
            let towardBetter = item.higherMeansBetter ? 1 : -1
            switch item.style {
            case .intensity:
                result[item.id] = min(max(raw + Double(towardBetter * step * 2), 0), 10)
            case .choice(let options):
                let values = options.map(\.value).sorted()
                guard let index = values.firstIndex(of: raw) else { continue }
                let next = min(max(index + towardBetter * step, 0), values.count - 1)
                result[item.id] = values[next]
            }
        }
        return result
    }
}

extension DebugDirectEntry {
    /// `-patika-debug-tab ben` — kabuk o sekmede açılır.
    static var initialTab: RootTab? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-patika-debug-tab"),
              arguments.index(after: index) < arguments.endIndex
        else { return nil }
        switch arguments[arguments.index(after: index)].lowercased() {
        case "ben", "me": return .me
        case "kesfet", "discover": return .discover
        case "yolum", "path": return .path
        default: return nil
        }
    }
}
#endif
