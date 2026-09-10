import SwiftUI

/// Gerçek faz başlangıcını rota üzerinde sessizce işaretler.
struct JourneyPhaseThreshold: View {
    let phase: PathPhase
    let isVisible: Bool

    var body: some View {
        Text(phase.label)
            .font(.caption.weight(Theme.Weight.emphasis))
            .foregroundStyle(Theme.textPrimary.color.opacity(0.58))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background {
                Capsule().fill(Color.black.opacity(0.28))
            }
            .opacity(isVisible ? 1 : 0)
            .accessibilityHidden(true)
    }
}
