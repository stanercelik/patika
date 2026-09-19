import SwiftUI

/// Ayarlar için koyu orman + adaçayı bileşenleri (`docs/profile-v2-plan.md`
/// Aşama 6). Sistem `List`'i nötr gri ve uygulamanın geri kalanından kopuktu;
/// bunlar aynı `ProfileCard` yüzeyini ve aynı tipografi rollerini kullanır.
///
/// Satırlar en az 52 pt. Erişilebilir Dynamic Type boyutlarında etiket ve değer
/// alt alta.

/// Başlık + adaçayı kart + (isteğe bağlı) altbilgi. Satırlar arasına ayırıcı
/// kendiliğinden konur.
struct SettingsGroup<Content: View>: View {
    var title: LocalizedStringResource?
    var footer: LocalizedStringResource?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.labelSpacing) {
            if let title {
                Text(title)
                    .font(Theme.TypeFace.cardMeta)
                    .foregroundStyle(Theme.textSecondary.color)
                    .padding(.horizontal, 4)
                    .accessibilityAddTraits(.isHeader)
            }

            ProfileCard(padding: 0) {
                VStack(spacing: 0) {
                    Group(subviews: content) { subviews in
                        ForEach(Array(subviews.enumerated()), id: \.element.id) { index, subview in
                            if index > 0 {
                                ProfileRowDivider().padding(.leading, Theme.Surface.padding)
                            }
                            subview
                        }
                    }
                }
            }

            if let footer {
                Text(footer)
                    .font(Theme.TypeFace.rowCaption)
                    .foregroundStyle(Theme.textSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
    }
}

/// Etiket + isteğe bağlı değer, açıklama ve ok. Yalnızca içerik: dokunulabilir
/// olması gerekiyorsa çağıran `Button`/`NavigationLink`/`ShareLink` ile sarar ve
/// `.buttonStyle(.calm)` verir.
struct SettingsRow: View {
    let title: LocalizedStringResource
    var symbol: String?
    var value: String?
    /// Değerin kaynağı ("… dediğin için"): sorduğumuz her şeyin karşılığı görünür.
    var caption: String?
    var showsChevron = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 14) {
            if let symbol, !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: symbol)
                    .font(Theme.TypeFace.rowSymbol)
                    .foregroundStyle(Theme.textPrimary.color)
                    .frame(width: 26)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                if dynamicTypeSize.isAccessibilitySize {
                    titleText
                    if let value { valueText(value) }
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        titleText
                        Spacer(minLength: 8)
                        if let value { valueText(value) }
                    }
                }
                if let caption {
                    Text(verbatim: caption)
                        .font(Theme.TypeFace.rowCaption)
                        .foregroundStyle(Theme.textSecondary.color)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if showsChevron { ProfileChevron() }
        }
        .padding(.horizontal, Theme.Surface.padding)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: PatikaSurfaceMetrics.rowMinHeight, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    private var titleText: some View {
        Text(title)
            .font(Theme.TypeFace.rowTitle)
            .foregroundStyle(Theme.textPrimary.color)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func valueText(_ value: String) -> some View {
        Text(verbatim: value)
            .font(Theme.TypeFace.rowValue)
            .foregroundStyle(Theme.textSecondary.color)
            // AX'te değer etiketin altında ve sola hizalı; yan yana olduğunda sağda.
            .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
    }
}

/// Anahtarlı satır; anahtar adaçayı tonunda.
struct SettingsToggleRow: View {
    let title: LocalizedStringResource
    @Binding var isOn: Bool
    var isEnabled = true

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(Theme.TypeFace.rowTitle)
                .foregroundStyle(Theme.textPrimary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .tint(WoodlandStyle.sage)
        .disabled(!isEnabled)
        .padding(.horizontal, Theme.Surface.padding)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: PatikaSurfaceMetrics.rowMinHeight, alignment: .leading)
    }
}

/// Geri alınamaz eylem satırı. Renk tek başına anlam taşımıyor: eylem metni
/// açıkça söylüyor, üstünde onay uyarısı çıkıyor.
struct SettingsDestructiveRow: View {
    let title: LocalizedStringResource
    var isWorking = false

    /// Koyu adaçayı yüzeyde okunur, doygun olmayan kırmızı.
    private static let ink = Color(red: 0.96, green: 0.56, blue: 0.52)

    var body: some View {
        HStack {
            if isWorking {
                ProgressView().tint(Self.ink)
            } else {
                Text(title)
                    .font(Theme.TypeFace.rowTitle)
                    .foregroundStyle(Self.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Surface.padding)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: PatikaSurfaceMetrics.rowMinHeight, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
