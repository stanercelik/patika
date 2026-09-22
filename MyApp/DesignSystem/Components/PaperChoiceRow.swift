import SwiftUI

/// `ChoiceRow`un kâğıt ikizi.
///
/// `ChoiceRow` koyu yüzeyde açık mürekkeple çizilir ve `PathSessionView` de onu
/// kullanır; yerinde yeniden biçimlendirmek çalışan bir meditasyonun ortasına krem
/// kart koyardı. Bu yüzden ayrı bir bileşen: `ChoiceRow` mürekkebi ortamdan
/// (`patikaInk`) okur ve kâğıtta buna devreder.
///
/// Seçili durum yine **üç sinyalle**: dolgu, kalın kenarlık, metin ağırlığı.
struct PaperChoiceRow: View {
    let label: LocalizedStringResource
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Theme.softHaptic()
            action()
        } label: {
            HStack(spacing: 12) {
                Text(label)
                    .font(.body.weight(isSelected ? Theme.Weight.action : Theme.Weight.emphasis))
                    .foregroundStyle(WoodlandStyle.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                PaperSelectionMark(isSelected: isSelected)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background { PaperInsetSurface(isEmphasized: isSelected) }
        }
        .buttonStyle(.calm)
        .animation(Theme.Motion.crossFade, value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Kâğıdın içine gömülü yüzey: seçenek satırı ve yazı alanı için. `CalmSurface`in
/// kâğıttaki karşılığı — koyu zeminde açık çizgi neyse, kâğıtta koyu çizgi o.
struct PaperInsetSurface: View {
    var isEmphasized = false
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Control.cornerRadius, style: .continuous)
        shape
            .fill(WoodlandStyle.ink.opacity(isEmphasized ? 0.10 : 0.04))
            .overlay {
                shape.strokeBorder(
                    WoodlandStyle.ink.opacity(isEmphasized ? 0.85 : (contrast == .increased ? 0.55 : 0.22)),
                    lineWidth: isEmphasized ? Theme.Line.border : Theme.Line.journeyConnector
                )
            }
            .accessibilityHidden(true)
    }
}

/// `SelectionMark`ın kâğıttaki karşılığı. Mevcut olan beyaz-siyah, koyu zeminde
/// ve `CategoryCard`da kullanılıyor.
struct PaperSelectionMark: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle().fill(isSelected ? WoodlandStyle.ink : Color.clear)
            Circle().strokeBorder(
                WoodlandStyle.secondaryInk.opacity(isSelected ? 0 : 0.7),
                lineWidth: Theme.Line.journeyConnector
            )
            Image(systemName: "checkmark")
                .font(.caption2.weight(Theme.Weight.action))
                .foregroundStyle(WoodlandStyle.paper)
                .opacity(isSelected ? 1 : 0)
        }
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)
    }
}

#Preview("Kâğıt seçim satırları") {
    ZStack {
        WoodlandStyle.background.ignoresSafeArea()
        VStack(alignment: .leading, spacing: 10) {
            PaperChoiceRow(label: "Birkaç gündür", isSelected: false) {}
            PaperChoiceRow(label: "Aylardır", isSelected: true) {}
            PaperChoiceRow(label: "Emin değilim", isSelected: false) {}
        }
        .padding(PatikaSurfaceMetrics.padding)
        .paperSurface()
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
    .preferredColorScheme(.dark)
}
