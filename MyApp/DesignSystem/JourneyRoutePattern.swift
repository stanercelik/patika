import Foundation

/// Yol haritasındaki düğümlerin yatay ritmi.
///
/// Desen bilerek tam simetrik değil: mekanik bir zikzak yerine, aynı patikanın
/// içinde sakin biçimde yön değiştiren bir iz hissi verir. Değerler normalize
/// olduğu için ekran genişliğinden bağımsızdır.
enum JourneyRoutePattern {
    private static let horizontalRhythm: [Double] = [0.18, 0.76, 0.26, 0.82, 0.22, 0.72]

    static func normalizedX(at index: Int, usesAccessibleLayout: Bool) -> Double {
        guard !usesAccessibleLayout else { return 0.10 }
        let safeIndex = abs(index) % horizontalRhythm.count
        return horizontalRhythm[safeIndex]
    }
}

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
