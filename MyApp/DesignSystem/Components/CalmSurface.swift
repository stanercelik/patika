import SwiftUI

/// Shared inset surface for choices and writing, distinct from navigation glass.
struct CalmSurface: View {
    var isEmphasized = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Control.cornerRadius, style: .continuous)
        shape
            .fill(reduceTransparency ? RGB(hex: 0x14151E).color : Color.black.opacity(0.24))
            .overlay {
                if !reduceTransparency {
                    shape.fill(LinearGradient(
                        colors: [Theme.textPrimary.color.opacity(isEmphasized ? 0.13 : 0.055), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                }
            }
            .overlay {
                shape.strokeBorder(
                    Theme.textPrimary.color.opacity(isEmphasized ? 0.66 : (contrast == .increased ? 0.32 : 0.13)),
                    lineWidth: isEmphasized ? Theme.Line.border : Theme.Line.journeyConnector
                )
            }
            .accessibilityHidden(true)
    }
}

struct SelectionMark: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle().fill(Theme.textPrimary.color.opacity(isSelected ? 1 : 0.035))
            Circle().strokeBorder(Theme.textPrimary.color.opacity(isSelected ? 0 : 0.28), lineWidth: Theme.Line.journeyConnector)
            Image(systemName: "checkmark")
                .font(.caption2.weight(Theme.Weight.action))
                .foregroundStyle(.black)
                .opacity(isSelected ? 1 : 0)
        }
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)
    }
}
