import Foundation

/// Komşu satın aynı sınır x değerinde buluşmasını sağlayan normalize rota
/// koordinatları. Değerler ekran genişliğine çevrilmeden önce saf ve test
/// edilebilir kalır.
struct JourneyRoutePosition: Equatable, Sendable {
    let previousX: Double
    let currentX: Double
    let nextX: Double
}

/// Kişisel İz'in faza göre değişen fakat her zaman deterministik yatay ritmi.
///
/// Bu değerler sonuç veya ruh hâli grafiği değildir. Yalnızca programın gerçek
/// fazlarını mekânsal olarak ayırır; aynı path her açılışta aynı izi üretir.
enum JourneyRouteLayout {
    private static let accessibleX = 0.10

    private static let rhythms: [PathPhase: [Double]] = [
        .relief: [0.40, 0.58, 0.36],
        .awareness: [0.30, 0.70, 0.38, 0.76],
        .skill: [0.20, 0.80, 0.28, 0.74],
        .behavior: [0.30, 0.68, 0.38, 0.62],
        .closing: [0.46, 0.54],
    ]

    static func positions(
        for phases: [PathPhase?],
        usesAccessibleLayout: Bool
    ) -> [JourneyRoutePosition] {
        guard !phases.isEmpty else { return [] }

        let xValues = phases.indices.map { index in
            normalizedX(
                at: index,
                phase: phases[index],
                usesAccessibleLayout: usesAccessibleLayout
            )
        }

        return xValues.indices.map { index in
            JourneyRoutePosition(
                previousX: xValues[max(index - 1, 0)],
                currentX: xValues[index],
                nextX: xValues[min(index + 1, xValues.count - 1)]
            )
        }
    }

    private static func normalizedX(
        at index: Int,
        phase: PathPhase?,
        usesAccessibleLayout: Bool
    ) -> Double {
        guard !usesAccessibleLayout else { return accessibleX }
        let rhythm = rhythms[phase ?? .awareness] ?? [0.30, 0.70, 0.38, 0.76]
        return rhythm[index % rhythm.count]
    }
}
