import Foundation

/// Kilometre taşı rozetleri — docs/profile-v2-plan.md.
///
/// Rozetin kimliği sunucudaki `earned_badges.badge_id` ile birebir aynıdır ve
/// **asla değiştirilmez**: değişirse kullanıcının kazandığı rozetle bağ kopar.
enum BadgeID: String, CaseIterable, Codable, Sendable, Identifiable {
    // Yol
    case firstStep = "first-step"
    case phaseRelief = "phase-relief"
    case phaseAwareness = "phase-awareness"
    case phaseSkill = "phase-skill"
    case phaseBehavior = "phase-behavior"
    case phaseClosing = "phase-closing"
    case pathComplete = "path-complete"
    // Ölçüm — katılımdan verilir, sonuçtan değil.
    case measureDay7 = "measure-day7"
    case measureDay14 = "measure-day14"
    // Seri — "bu hafta" (WeeklyRhythm).
    case week3 = "week-3"
    case week5 = "week-5"
    case week7 = "week-7"
    // Defter
    case noteFirst = "note-first"
    case note10 = "note-10"

    var id: String { rawValue }

    enum Family: CaseIterable, Sendable {
        case path, measurement, streak, journal
    }

    var family: Family {
        switch self {
        case .firstStep, .phaseRelief, .phaseAwareness, .phaseSkill, .phaseBehavior,
             .phaseClosing, .pathComplete: .path
        case .measureDay7, .measureDay14: .measurement
        case .week3, .week5, .week7: .streak
        case .noteFirst, .note10: .journal
        }
    }

    /// `Assets.xcassets/Me/` altındaki görsel. Klasörler ad alanı taşımıyor.
    var assetName: String { "badge-\(rawValue)" }

    /// Faz rozeti ise hangi faza ait.
    var phase: PathPhase? {
        switch self {
        case .phaseRelief: .relief
        case .phaseAwareness: .awareness
        case .phaseSkill: .skill
        case .phaseBehavior: .behavior
        case .phaseClosing: .closing
        default: nil
        }
    }

    static func phaseBadge(for phase: PathPhase) -> BadgeID {
        switch phase {
        case .relief: .phaseRelief
        case .awareness: .phaseAwareness
        case .skill: .phaseSkill
        case .behavior: .phaseBehavior
        case .closing: .phaseClosing
        }
    }
}

struct EarnedBadge: Codable, Equatable, Sendable, Identifiable {
    let badgeID: BadgeID
    let earnedAt: Date

    var id: BadgeID { badgeID }
}

/// Hangi rozetlerin hak edildiğini **saf ve deterministik** hesaplar; model yok,
/// ağ yok. Bu bir sözleşme: "Kova C'de kutlama yok" gibi kurallar, kazanımı bir
/// modelin belirlediği üründe anlamsız olurdu.
///
/// - **Rozet geri alınmaz.** Buradaki küme yalnızca *şu an* koşulu sağlayanları
///   verir; çağıran onu sunucudakiyle birleştirir (`merged`). Bir notu silmek
///   "İlk not" rozetini götürmez.
/// - **Ölçüm rozetleri katılımdan verilir**, sonuçtan değil: kova farkı burada
///   hiçbir rol oynamaz, Kova C'deki kullanıcı da 7. gün ölçümünü alır.
enum BadgeCatalog {
    static func earned(
        from record: ProfileRecord,
        path: ActivePath?,
        calendar: Calendar = .current
    ) -> Set<BadgeID> {
        var earned: Set<BadgeID> = []

        // Yol
        let stepsDone = path?.completedStepCount ?? 0
        if stepsDone > 0 || !record.completedStepDates.isEmpty { earned.insert(.firstStep) }

        if let path, let length = PathLength(rawValue: path.steps.count) {
            let stepsByPhase = Dictionary(grouping: path.steps) {
                PathPlan.phase(on: $0.day, length: length)
            }
            for (phase, steps) in stepsByPhase {
                guard let phase, steps.allSatisfy({ $0.completedAt != nil }) else { continue }
                earned.insert(BadgeID.phaseBadge(for: phase))
            }
        }
        if path?.isCompleted == true || record.pathArchive.contains(where: { $0.status == .completed }) {
            earned.insert(.pathComplete)
        }

        // Ölçüm: adım günü, yolun uzunluğundan bağımsız (14 günlük yolda 14. gün
        // "son" ölçümdür ama yine 14. gün ölçümüne katılmıştır).
        let measuredDays = Set(record.measurements.map(\.stepDay))
        if measuredDays.contains(7) { earned.insert(.measureDay7) }
        if measuredDays.contains(14) { earned.insert(.measureDay14) }

        // Seri
        let bestWeek = WeeklyRhythm.bestDaysInAWeek(
            completedStepDates: record.completedStepDates,
            calendar: calendar
        )
        if bestWeek >= 3 { earned.insert(.week3) }
        if bestWeek >= 5 { earned.insert(.week5) }
        if bestWeek >= 7 { earned.insert(.week7) }

        // Defter — yalnızca kullanıcının kendi notları.
        if record.notes.count >= 1 { earned.insert(.noteFirst) }
        if record.notes.count >= 10 { earned.insert(.note10) }

        return earned
    }

    /// Hesaplanan kümeden, henüz kaydedilmemiş olanlar — katalog sırasıyla.
    static func newlyEarned(computed: Set<BadgeID>, known: [EarnedBadge]) -> [BadgeID] {
        let knownIDs = Set(known.map(\.badgeID))
        return BadgeID.allCases.filter { computed.contains($0) && !knownIDs.contains($0) }
    }

    /// Kazanılmış her rozet: sunucudakiler + yeni hesaplananlar. Hiçbiri düşmez.
    static func merged(known: [EarnedBadge], computed: Set<BadgeID>, at date: Date) -> [EarnedBadge] {
        known + newlyEarned(computed: computed, known: known).map { EarnedBadge(badgeID: $0, earnedAt: date) }
    }

    /// Rafta sıradaki tek kilitli rozet: katalog sırasında ilk kazanılmamış.
    static func next(after known: [EarnedBadge]) -> BadgeID? {
        let knownIDs = Set(known.map(\.badgeID))
        return BadgeID.allCases.first { !knownIDs.contains($0) }
    }
}
