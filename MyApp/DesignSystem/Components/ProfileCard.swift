import SwiftUI

/// Mesh üstünde okunur içerik yüzeyi (`Theme.Surface`, profile-design §9.2).
///
/// Liquid Glass değil: cam gezinme ve kontrol katmanının dili. İçerik kartında
/// cam kullanmak, içerikle kontrolün ayrımını bulanıklaştırır. Gölge de yok —
/// koyu zeminde görünmez, yalnızca kirletir.
struct ProfileCard<Content: View>: View {
    var padding: CGFloat = Theme.Surface.padding
    @ViewBuilder let content: Content

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background {
                let shape = RoundedRectangle(cornerRadius: Theme.Surface.cornerRadius, style: .continuous)
                shape
                    .fill(Color.black.opacity(fillOpacity))
                    .overlay {
                        shape.strokeBorder(Theme.textPrimary.color.opacity(strokeOpacity), lineWidth: 1)
                    }
            }
    }

    private var fillOpacity: Double {
        if contrast == .increased { return Theme.Surface.fillOpacityHighContrast }
        return reduceTransparency ? Theme.Surface.fillOpacityOpaqueBackground : Theme.Surface.fillOpacity
    }

    private var strokeOpacity: Double {
        contrast == .increased ? Theme.Surface.strokeOpacityHighContrast : Theme.Surface.strokeOpacity
    }
}

/// Bölüm başlığı. Büyük harfli üst etiket yok (profile-design §9.3): Türkçe büyük
/// harf yerel ayar ister ve sakin bir ekranda bağırır.
struct ProfileSectionHeader: View {
    let title: LocalizedStringResource
    var actionTitle: LocalizedStringResource?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.title3.weight(Theme.Weight.title))
                .foregroundStyle(Theme.textPrimary.color)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(Theme.Weight.action))
                            .accessibilityHidden(true)
                    }
                    .font(.subheadline.weight(Theme.Weight.action))
                    .foregroundStyle(Theme.textSecondary.color)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.calm)
            }
        }
    }
}

/// Kart içi satır ayırıcı.
struct ProfileRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.textPrimary.color.opacity(0.08))
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

/// Dokunulabilir kart satırının sağındaki ok.
struct ProfileChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(Theme.Weight.action))
            .foregroundStyle(Theme.textSecondary.color)
            .accessibilityHidden(true)
    }
}
