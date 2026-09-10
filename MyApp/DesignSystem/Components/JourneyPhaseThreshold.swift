import SwiftUI

enum JourneyPhaseThresholdStyle {
    case capsule
    case margin
}

/// Gerçek faz başlangıcını rota üzerinde sessizce işaretler.
struct JourneyPhaseThreshold: View {
    let phase: PathPhase
    let isVisible: Bool
    var style: JourneyPhaseThresholdStyle = .capsule

    var body: some View {
        HStack(spacing: 6) {
            if style == .margin {
                Circle()
                    .fill(Theme.textPrimary.color.opacity(0.38))
                    .frame(width: 4, height: 4)
            }
            Text(phase.label)
                .font(.caption.weight(Theme.Weight.emphasis))
        }
        .foregroundStyle(Theme.textPrimary.color.opacity(style == .margin ? 0.48 : 0.58))
        .padding(.horizontal, style == .capsule ? 8 : 0)
        .padding(.vertical, style == .capsule ? 3 : 0)
        .background {
            if style == .capsule {
                Capsule().fill(Color.black.opacity(0.28))
            }
        }
            .opacity(isVisible ? 1 : 0)
            .accessibilityHidden(true)
    }
}
