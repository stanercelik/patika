import Foundation

/// Yolum'un doğa illüstrasyonlarını gerçek program fazına bağlar.
/// Görseller hassas problem metninden değil, deterministik faz bilgisinden gelir.
enum JourneyPhaseDecoration {
    static func artwork(for phase: PathPhase) -> PatikaArtwork {
        switch phase {
        case .relief:
            .shelter
        case .awareness, .skill, .behavior:
            .trail
        case .closing:
            .rest
        }
    }

    /// İlk satır bugünün eylemine ayrılır; dekorasyon yalnızca sonraki gerçek
    /// faz eşiklerinde görünür.
    static func shouldShow(startsPhase: Bool, rowIndex: Int) -> Bool {
        startsPhase && rowIndex > 0
    }
}
