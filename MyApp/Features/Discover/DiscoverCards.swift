import SwiftUI

/// Durum etiketi. Renk dışında da okunur: her durumun kendi simgesi ve metni var.
struct DiscoverStatusLabel: View {
    let status: DiscoverLibrary.Status

    var body: some View {
        Label {
            Text(verbatim: text)
        } icon: {
            Image(systemName: symbol).accessibilityHidden(true)
        }
        .font(Theme.TypeFace.product(.footnote, Theme.Weight.emphasis))
        .foregroundStyle(WoodlandStyle.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        // Durum metnin kendisiyle ve simgesiyle okunur; kapsül yalnızca satırı
        // kâğıttan ayırır, anlamı renge taşımaz.
        .background(WoodlandStyle.ink.opacity(0.09), in: Capsule())
    }

    private var text: String {
        switch status {
        case .comingSoon: DiscoverCopy.comingSoon
        case .available: DiscoverCopy.duration
        case .inProgress(let done, let total): DiscoverCopy.progress(done: done, total: total)
        case .completed: DiscoverCopy.done
        }
    }

    private var symbol: String {
        switch status {
        case .comingSoon: "clock"
        case .available: "leaf"
        case .inProgress: "leaf.fill"
        case .completed: "checkmark.circle"
        }
    }
}

/// Bölüm şeridindeki patika kartı: üstte guaj görsel, altında krem kâğıtta metin.
/// Yazı görselin üstüne binmez (`docs/discover-design.md`, Keşfet v2).
///
/// Görsel yoksa ya da AX boyutundaysa kart yalnızca metinle durur.
struct DiscoverPathCard: View {
    let path: DiscoverPath
    let status: DiscoverLibrary.Status

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isAccessible: Bool { dynamicTypeSize.isAccessibilitySize }
    /// Görsel bandı kısa: uzun bir boyalı sahne kartın yazısıyla ve arkadaki manzarayla
    /// yarışıyordu (ürün sahibi geri bildirimi, 2026-09-20). 150 pt'ten indi.
    private static let artworkHeight: CGFloat = 112
    /// Erişilebilir boyutta satır sınırı fiilen kalkar; normalde üç satır ayrılır
    /// (en uzun Türkçe özet üç satıra sığar, kısaltılmaz) ve kartlar aynı boyda durur.
    private var lineCap: Int { isAccessible ? 12 : 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !isAccessible {
                DiscoverArtwork(name: path.artwork, height: Self.artworkHeight)
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: PatikaSurfaceMetrics.radius,
                        topTrailingRadius: PatikaSurfaceMetrics.radius,
                        style: .continuous
                    ))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: path.title.value)
                    .font(Theme.TypeFace.cardTitleProminent)
                    .foregroundStyle(WoodlandStyle.ink)
                    .lineLimit(lineCap)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: path.summary.value)
                    .font(Theme.TypeFace.product(.subheadline, Theme.Weight.body))
                    .foregroundStyle(WoodlandStyle.ink)
                    .lineLimit(lineCap, reservesSpace: !isAccessible)
                    .fixedSize(horizontal: false, vertical: true)
                DiscoverStatusLabel(status: status)
                    .padding(.top, 4)
            }
            .multilineTextAlignment(.leading)
            .padding(PatikaSurfaceMetrics.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentShape(RoundedRectangle(cornerRadius: PatikaSurfaceMetrics.radius, style: .continuous))
        .paperSurface()
        .accessibilityElement(children: .combine)
    }
}

/// "Kaldığın yerden": katılıp bitirmediğin patika. Sayfada tek açık yüzey; iz
/// yedi noktadan oluşur ve renk yerine doluluğuyla okunur, sayıyı metin verir.
struct DiscoverContinueCard: View {
    let path: DiscoverPath
    let done: Int
    let total: Int

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isAccessible: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !isAccessible {
                DiscoverArtwork(name: path.artwork, height: 132)
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: PatikaSurfaceMetrics.radius,
                        topTrailingRadius: PatikaSurfaceMetrics.radius,
                        style: .continuous
                    ))
            }
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(verbatim: path.title.value)
                        .font(Theme.TypeFace.cardTitleProminent)
                        .foregroundStyle(WoodlandStyle.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(Theme.TypeFace.lockMark)
                        .foregroundStyle(WoodlandStyle.secondaryInk)
                        .accessibilityHidden(true)
                }
                if !isAccessible {
                    HStack(spacing: 6) {
                        ForEach(0..<total, id: \.self) { index in
                            Circle()
                                .fill(index < done ? WoodlandStyle.ink : WoodlandStyle.secondaryInk.opacity(0.2))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .accessibilityHidden(true)
                }
                DiscoverStatusLabel(status: .inProgress(done: done, total: total))
            }
            .multilineTextAlignment(.leading)
            .padding(PatikaSurfaceMetrics.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentShape(RoundedRectangle(cornerRadius: PatikaSurfaceMetrics.radius, style: .continuous))
        .paperSurface()
        .accessibilityElement(children: .combine)
    }
}

/// Kişisel patikaya dönüş satırı. Kompakt: sayfada açık duran yüzey "Kaldığın
/// yerden" kartı, bu satır değil.
struct DiscoverPersonalCard: View {
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if !dynamicTypeSize.isAccessibilitySize, PatikaArt.exists("discover-personal") {
                    Image(decorative: "discover-personal")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: DiscoverCopy.personalAction)
                        .font(Theme.TypeFace.rowTitle)
                        .foregroundStyle(WoodlandStyle.ink)
                    Text(verbatim: DiscoverCopy.personalBody)
                        .font(Theme.TypeFace.rowCaption)
                        .foregroundStyle(WoodlandStyle.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(Theme.TypeFace.lockMark)
                    .foregroundStyle(WoodlandStyle.secondaryInk)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, PatikaSurfaceMetrics.compactPadding + 2)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: PatikaSurfaceMetrics.rowMinHeight, alignment: .leading)
            .contentShape(.rect)
            .paperSurface(radius: PatikaSurfaceMetrics.compactRadius, isProminent: false)
        }
        .buttonStyle(.calm)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}
