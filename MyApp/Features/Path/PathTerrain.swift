import SwiftUI

/// A phase-specific cutout from the shared gouache family. Its alpha keeps the
/// path's existing background visible; the scene carries no progress or score.
struct PathTerrain: View {
    var phase: PathPhase = .relief

    var body: some View {
        PatikaIllustration(artwork: JourneyPhaseDecoration.artwork(for: phase))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
