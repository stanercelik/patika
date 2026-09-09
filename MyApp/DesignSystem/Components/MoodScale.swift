import SwiftUI

/// B6 ve günlük ön kontrolün ölçeği — beş kademe, tek dokunuş.
///
/// Emoji yerine monokrom SF Symbols (bkz. `MoodLevel`). İkonun altında **yalnızca
/// seçili kademenin etiketi** yazar: beş etiketi birden göstermek satırı okunmaz
/// hâle getiriyor, hiç göstermemek ise anlamı renk/ikona bırakıyordu — ikisi de
/// erişilebilirlik açısından kötü.
struct MoodScale: View {
    let selection: MoodLevel?
    let onSelect: (MoodLevel) -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(MoodLevel.allCases) { level in
                    MoodButton(
                        level: level,
                        isSelected: selection == level,
                        action: { onSelect(level) }
                    )
                }
            }

            // Yer her zaman ayrılır: seçim yapıldığında satır zıplamaz.
            Text(selection?.label ?? " ")
                .font(.subheadline.weight(Theme.Weight.action))
                .foregroundStyle(Theme.textPrimary.color)
                .opacity(selection == nil ? 0 : 1)
                .animation(Theme.Motion.crossFade, value: selection)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MoodButton: View {
    let level: MoodLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Theme.softHaptic()
            action()
        } label: {
            Image(systemName: level.icon)
                .font(.system(size: 24, weight: Theme.Weight.emphasis))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Theme.textPrimary.color.opacity(isSelected ? 1.0 : 0.72))
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(isSelected ? 0.16 : 0.07))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            Theme.textPrimary.color.opacity(isSelected ? 0.55 : 0.0),
                            lineWidth: Theme.Line.border
                        )
                }
        }
        .buttonStyle(.calm)
        .animation(Theme.Motion.crossFade, value: isSelected)
        .accessibilityLabel(Text(level.label))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    ZStack {
        BreathingMeshBackground(palette: .neutral, safeY: 0.40)
        VStack(spacing: 40) {
            MoodScale(selection: nil) { _ in }
            MoodScale(selection: .middling) { _ in }
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
    .preferredColorScheme(.dark)
}
