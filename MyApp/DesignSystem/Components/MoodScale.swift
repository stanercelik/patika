import SwiftUI

/// B6 ve günlük ön kontrolün ölçeği — beş kademe, tek dokunuş.
///
/// Beş ayrı hava kartı, sahnedeki değişimin küçük bir haritası gibi çalışır.
/// Altında yalnızca seçili kademenin etiketi yazar; ekran kalabalıklaşmadan
/// seçimin anlamı metinle de açık kalır.
///
/// ## Sürükleyerek de seçilir
///
/// B6'da cevap arka planı **doğrudan** değiştiriyor (`previewCurrentMood`): parmağı
/// beş kademe boyunca sürüklemek, ekranın rengini parmağın altında canlı değiştiriyor;
/// karşılığı hemen görünüyor. Dokunuş aynen çalışıyor (sürükleme eşiği 6 pt, altı
/// düğmeye gider), düğmeler VoiceOver ve Switch Control için yerinde: sürükleme onlara
/// ek, onların yerine değil.
struct MoodScale: View {
    let selection: MoodLevel?
    let onSelect: (MoodLevel) -> Void

    @State private var rowWidth: CGFloat = 0

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
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { rowWidth = $0 }
            .simultaneousGesture(
                DragGesture(minimumDistance: 6, coordinateSpace: .local)
                    .onChanged { value in dragged(to: value.location.x) }
            )

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
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.textPrimary.color.opacity(isSelected ? 0.94 : 0.16))

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        Theme.textPrimary.color.opacity(isSelected ? 1 : 0.38),
                        lineWidth: isSelected ? 2 : Theme.Line.border
                    )

                Image(systemName: level.sceneSymbol)
                    .font(.title3.weight(Theme.Weight.emphasis))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(isSelected ? WoodlandStyle.ink : Theme.textPrimary.color)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2.weight(Theme.Weight.action))
                        .foregroundStyle(WoodlandStyle.ink)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
        }
        .buttonStyle(.calm)
        .animation(Theme.Motion.crossFade, value: isSelected)
        .accessibilityLabel(Text(level.label))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

extension MoodScale {
    /// Parmağın altındaki kademe. Kademe değişince haptik ve seçim; aynı kademede sessiz.
    fileprivate func dragged(to x: CGFloat) {
        guard rowWidth > 0 else { return }
        let levels = MoodLevel.allCases
        let ratio = min(max(x / rowWidth, 0), 0.999)
        let level = levels[Int(ratio * CGFloat(levels.count))]
        guard level != selection else { return }
        Theme.softHaptic()
        onSelect(level)
    }
}

#Preview {
    ZStack {
        WoodlandStyle.background.ignoresSafeArea()
        VStack(spacing: 40) {
            MoodScale(selection: nil) { _ in }
            MoodScale(selection: .middling) { _ in }
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
    .preferredColorScheme(.dark)
}
