import SwiftUI

/// Tek rozet. Kazanılan tam renk; kilitli aynı görsel gri tona çevrilip %30
/// opaklıkla çizilir (yeni varlık gerekmiyor). Kilitli hâl renkle **değil**
/// solukluk ve gri tonla anlatılır; altındaki metin ayrıca söyler.
struct BadgeMedallion: View {
    let id: BadgeID
    let isEarned: Bool
    var size: CGFloat = 72

    var body: some View {
        Group {
            if PatikaArt.exists(id.assetName) {
                Image(decorative: id.assetName)
                    .resizable()
                    .scaledToFit()
            } else {
                // Görsel yoksa krem disk ve tek simge: raf boş boşluk göstermesin.
                ZStack {
                    Circle().fill(WoodlandStyle.paper)
                    Circle().strokeBorder(WoodlandStyle.ink, lineWidth: 3)
                    Image(systemName: "leaf")
                        .font(.system(size: size * 0.36, weight: .semibold))
                        .foregroundStyle(WoodlandStyle.secondaryInk)
                }
            }
        }
        .frame(width: size, height: size)
        .saturation(isEarned ? 1 : 0)
        .opacity(isEarned ? 1 : 0.3)
        .accessibilityHidden(true)
    }
}

/// Profildeki rozet rafı: kazanılanlar yeniden eskiye, en sonda sıradaki tek
/// kilitli rozet. Sayı, toplam ya da ilerleme çubuğu yok (docs/profile-v2-plan.md).
///
/// Hiç rozet yoksa yalnızca ilk kilitli rozet ve "İlk adımı attığında burada".
struct BadgeShelf: View {
    let earned: [EarnedBadge]
    let next: BadgeID?
    var showsAll = true

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var medallionSize: CGFloat = 72

    var body: some View {
        VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.labelSpacing) {
            header

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(earned.sorted { $0.earnedAt > $1.earnedAt }) { badge in
                        cell(id: badge.badgeID, isEarned: true)
                    }
                    if let next {
                        cell(id: next, isEarned: false)
                    }
                    if earned.isEmpty {
                        Text(Copy.Me.badgesFirstHint)
                            .font(Theme.TypeFace.rowCaption)
                            .foregroundStyle(Theme.textSecondary.color)
                            .frame(width: 140, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }

    private var header: some View {
        // AX'te başlık ve "Tümü" alt alta: yan yana olunca başlık kelime ortasından
        // bölünüyordu.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
        return layout {
            Text(Copy.Me.badgesTitle)
                .font(Theme.TypeFace.sectionTitle)
                .foregroundStyle(Theme.textPrimary.color)
                .accessibilityAddTraits(.isHeader)
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
            if showsAll {
                NavigationLink(value: MeRoute.badges) {
                    HStack(spacing: 4) {
                        Text(Copy.Me.badgesAll)
                        Image(systemName: "chevron.right")
                            .font(Theme.TypeFace.lockMark)
                            .accessibilityHidden(true)
                    }
                    .font(Theme.TypeFace.rowAction)
                    .foregroundStyle(Theme.textSecondary.color)
                    .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                    .contentShape(.rect)
                }
                .buttonStyle(.calm)
            }
        }
    }

    private func cell(id: BadgeID, isEarned: Bool) -> some View {
        BadgeMedallion(id: id, isEarned: isEarned, size: min(medallionSize, 96))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(Copy.Me.badgeAccessibility(
                title: String(localized: Copy.Me.Badge.title(id)),
                detail: String(localized: isEarned ? Copy.Me.Badge.earned(id) : Copy.Me.Badge.howToEarn(id)),
                earned: isEarned
            )))
            .accessibilityAddTraits(.isImage)
    }
}

/// Bütün rozetler: kazanılan tam renk, kilitli soluk. Kilitli rozetin altında
/// nasıl kazanılacağı **tek cümleyle** yazar; sayı ya da ilerleme çubuğu yok.
struct BadgesView: View {
    let earned: [EarnedBadge]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            WoodlandStyle.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(BadgeID.Family.allCases, id: \.self) { family in
                        section(for: family)
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(Text(Copy.Me.badgesTitle))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(for family: BadgeID.Family) -> some View {
        let badges = BadgeID.allCases.filter { $0.family == family }
        return VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.labelSpacing) {
            Text(Copy.Me.Badge.family(family))
                .font(Theme.TypeFace.sectionTitle)
                .foregroundStyle(Theme.textPrimary.color)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 240 : 150), spacing: 12)],
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(badges) { badge in
                    cell(for: badge)
                }
            }
        }
    }

    private func cell(for badge: BadgeID) -> some View {
        let isEarned = earned.contains { $0.badgeID == badge }
        let detail = isEarned ? Copy.Me.Badge.earned(badge) : Copy.Me.Badge.howToEarn(badge)
        return ProfileCard {
            VStack(spacing: 10) {
                BadgeMedallion(id: badge, isEarned: isEarned, size: 88)
                Text(Copy.Me.Badge.title(badge))
                    .font(Theme.TypeFace.rowTitle)
                    .foregroundStyle(Theme.textPrimary.color)
                Text(detail)
                    .font(Theme.TypeFace.rowCaption)
                    .foregroundStyle(Theme.textSecondary.color)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
        .opacity(isEarned ? 1 : 0.85)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Copy.Me.badgeAccessibility(
            title: String(localized: Copy.Me.Badge.title(badge)),
            detail: String(localized: detail),
            earned: isEarned
        )))
    }
}
