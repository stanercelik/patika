import Foundation

/// Bu haftanın yedi günü — kimlik kartındaki noktalar ve seri rozetleri.
///
/// "Seri" burada **"bu hafta"** demek: pazartesi–pazar arasında adım tamamlanan
/// günler (docs/profile-v2-plan.md). Kırılınca gösterilecek bir mesaj yok, çünkü
/// kırılacak bir şey yok: yeni haftada noktalar boş başlar, geçen haftadan
/// hiçbir şey geri alınmaz. Haftada 0 gün varsa noktalar boş kalır ve yanında
/// metin yazılmaz.
struct WeeklyRhythm: Equatable, Sendable {
    struct Day: Equatable, Sendable, Identifiable {
        let date: Date
        let isCompleted: Bool
        let isToday: Bool

        var id: Date { date }
    }

    /// Pazartesiden pazara.
    let days: [Day]

    var completedCount: Int { days.count(where: \.isCompleted) }

    static func make(
        completedStepDates: [Date],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> WeeklyRhythm {
        let calendar = mondayFirst(calendar)
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return WeeklyRhythm(days: [])
        }
        let completedDays = Set(completedStepDates.map { calendar.startOfDay(for: $0) })
        let today = calendar.startOfDay(for: now)

        let days = (0..<7).compactMap { offset -> Day? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: week.start) else { return nil }
            return Day(date: date, isCompleted: completedDays.contains(date), isToday: date == today)
        }
        return WeeklyRhythm(days: days)
    }

    /// Bir takvim haftasında adım tamamlanan en çok gün sayısı. Seri rozetleri
    /// (`week-3/5/7`) bunu okur; hangi hafta olduğu önemli değil — rozet bir kez
    /// kazanılır ve geri alınmaz.
    static func bestDaysInAWeek(
        completedStepDates: [Date],
        calendar: Calendar = .current
    ) -> Int {
        let calendar = mondayFirst(calendar)
        var daysByWeek: [Date: Set<Date>] = [:]
        for date in completedStepDates {
            guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else { continue }
            daysByWeek[week.start, default: []].insert(calendar.startOfDay(for: date))
        }
        return daysByWeek.values.map(\.count).max() ?? 0
    }

    /// Hafta pazartesi başlar. Cihazın bölgesi pazarı ya da cumartesiyi başlangıç
    /// sayıyorsa "bu hafta" iki farklı yerde iki farklı şey demek olurdu.
    static func mondayFirst(_ calendar: Calendar) -> Calendar {
        var calendar = calendar
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }
}
