import SwiftUI

/// Ben'de ödenmemiş kişisel patikanın teklif kartı (docs/paywall-stratejisi.md §2).
///
/// Defter kartıyla aynı aileden: guaj görsel zemin, üstünde metin. Görsel
/// `me-continue-path` (`PaywallForestPath`'in ışık + yol + ilk taş kırpımı) — ilk
/// taştan sonra güneşe doğru devam eden orman yolu; kartın
/// söylediği şeyin kendisi. Alt yarısı zaten koyu, metin oraya oturuyor; ayrıca
/// düz bir perde var (gradyan yok).
///
/// İz paywall'daki izin aynısı: yürünen adımlar kayısı, kalanlar sönük. Kullanıcı
/// başladığı yolu görür. Kayısı kenar ve yumuşak gölge kartı sayfadaki diğer
/// kartlardan bir kademe öne çıkarır; hareket, nabız ya da sayaç yok.
struct ContinuePathCard: View {
    let walked: Int
    let total: Int
    let onOpen: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private static let cornerRadius: CGFloat = 28
    private static let artwork = "me-continue-path"

    private var remaining: Int { max(0, total - walked) }
    private var showsArtwork: Bool {
        PatikaArt.exists(Self.artwork) && !dynamicTypeSize.isAccessibilitySize && !reduceTransparency
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Copy.Me.continuePathProgress(walked: walked, total: total))
                    .font(Theme.TypeFace.eyebrow)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(WoodlandStyle.sage)

                trail

                VStack(alignment: .leading, spacing: 4) {
                    Text(Copy.Me.continuePathTitle)
                        .font(Theme.TypeFace.cardTitleProminent)
                        .foregroundStyle(WoodlandStyle.paper)
                    Text(Copy.Me.continuePathCaption(remaining: remaining))
                        .font(Theme.TypeFace.detailBody)
                        .foregroundStyle(WoodlandStyle.paper.opacity(0.82))
                }
                .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(Copy.Me.continuePathCTA)
                    Image(systemName: "chevron.right")
                        .font(Theme.TypeFace.lockMark)
                        .accessibilityHidden(true)
                }
                .font(Theme.TypeFace.action)
                .foregroundStyle(WoodlandStyle.ink)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .background(WoodlandStyle.paper, in: Capsule())
                .padding(.top, 4)
            }
            .multilineTextAlignment(.leading)
            .padding(22)
            .padding(.top, showsArtwork ? 96 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { background }
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                    .strokeBorder(WoodlandStyle.apricot.opacity(0.45), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 10)
            .shadow(color: WoodlandStyle.apricot.opacity(0.18), radius: 14, x: 0, y: 0)
            .contentShape(.rect)
        }
        .buttonStyle(.calm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Copy.Me.continuePathCardLabel(remaining: remaining)))
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var background: some View {
        if showsArtwork {
            // Görsel yalnız zemin: boyutu metin belirler, görsel kırpılır.
            Image(decorative: Self.artwork)
                .resizable()
                .scaledToFill()
                .overlay(WoodlandStyle.background.opacity(0.36))
        } else {
            WoodlandStyle.surface
        }
    }

    /// Patikanın her günü bir parça; yürünenler dolu. 28 günlükte de tek satır.
    private var trail: some View {
        HStack(spacing: total > 14 ? 2 : 3) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                Capsule()
                    .fill(index < walked ? WoodlandStyle.apricot : WoodlandStyle.paper.opacity(0.28))
                    .frame(height: 4)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        WoodlandStyle.background.ignoresSafeArea()
        ContinuePathCard(walked: 1, total: 14) {}
            .padding(24)
    }
}
