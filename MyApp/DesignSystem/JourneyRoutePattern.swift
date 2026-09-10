import Foundation

/// Haritadaki bir adımın açılabilirlik sözleşmesi.
///
/// Başlığı görmek ile oturumu açabilmek ayrı şeylerdir: bütün başlıklar görünür,
/// yalnızca tamamlanan ve sıradaki adımlar etkileşimlidir.
enum JourneyStepAccess {
    static func isLocked(day: Int, isCompleted: Bool, nextDay: Int?) -> Bool {
        guard !isCompleted else { return false }
        guard let nextDay else { return true }
        return day != nextDay
    }
}
