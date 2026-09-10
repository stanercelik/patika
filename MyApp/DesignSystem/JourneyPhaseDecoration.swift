import Foundation

/// Yolum'daki heykelsi boşluk görsellerini gerçek program fazına bağlar.
/// Görseller hassas problem metninden değil, deterministik faz bilgisinden gelir.
enum JourneyPhaseDecoration {
    static func assetName(for phase: PathPhase) -> String {
        switch phase {
        case .relief:
            "journey-relief"
        case .awareness, .skill, .behavior:
            "journey-practice"
        case .closing:
            "journey-closing"
        }
    }

    /// İlk satır bugünün eylemine ayrılır; dekorasyon yalnızca sonraki gerçek
    /// faz eşiklerinde görünür.
    static func shouldShow(startsPhase: Bool, rowIndex: Int) -> Bool {
        startsPhase && rowIndex > 0
    }
}
