import SwiftUI

/// Tek ya da çoklu seçim satırı (B2, B3, B5, E bölümü).
///
/// Seçili durum **üç sinyalle birden** anlatılır — dolgu, kenarlık ve metin
/// ağırlığı. Renk tek başına anlam taşımaz (Ton eki §7); renk körü bir kullanıcı
/// da, gri tonlamalı ekran görüntüsü de seçimi okur.
struct ChoiceRow: View {
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
                    .font(
                        .body.weight(isSelected ? Theme.Weight.action : Theme.Weight.emphasis)
                    )
                    .foregroundStyle(Theme.textPrimary.color)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                SelectionMark(isSelected: isSelected)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background { CalmSurface(isEmphasized: isSelected) }
        }
        .buttonStyle(.calm)
        .animation(Theme.Motion.crossFade, value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    ZStack {
        BreathingMeshBackground(palette: .neutral, safeY: 0.30)
        VStack(spacing: 10) {
            ChoiceRow(label: "Birkaç gündür", isSelected: false) {}
            ChoiceRow(label: "Aylardır", isSelected: true) {}
            ChoiceRow(label: "Emin değilim", isSelected: false) {}
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
    .preferredColorScheme(.dark)
}
