import SwiftUI

/// Hazır patikanın detayı — Keşfet'ten yakınlaştırma geçişiyle açılır ("Ben"deki
/// defter geçişiyle aynı) ve katılınmış patikanın canlı hâlini de çizer.
///
/// - **Zemin düz `WoodlandStyle.background`**: gradyan ve palet kalktı (2026-09-22);
///   patikanın kimliğini zeminin rengi değil hero görseli taşır.
/// - **Hero** `MeBackdrop`un fade/parallax matematiğiyle: 220 pt'de söner, en çok
///   10 pt kayar; Reduce Motion, Reduce Transparency ve AX boyutlarında çizilmez.
///   Yazı hero'nun üstüne binmez, altındaki zeminde durur.
/// - **Adımlar** "Yolum"un tabela rotasıdır (`DiscoverTrailMap`).
/// - Katılım alt eylem satırında; ses yoksa düğme kapalı ve gerekçesi yazılı.
///   AX boyutlarında eylem sabitlenmez, içerikle kayar.
/// - **Katılım Keşfet'te kalır**: katılınca ekran değişmez, yalnızca önizleme
///   canlı duruma döner. Hazır patika Yolum'u devralmaz.
/// - Oturum `PathSessionView`la açılır (Yolum'la aynı sahne ve motor).
struct DiscoverPathView: View {
    let path: DiscoverPath

    @Environment(DiscoverLibrary.self) private var library
    @Environment(AppServices.self) private var services
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var confirmsJoin = false
    @State private var session: DiscoverStep?
    @State private var expandedStepID: String?
    @State private var scroll = ScrollOffsetBox()

    private static let heroHeight: CGFloat = 300
    /// Hero'nun altında başlığın başladığı yer; ilk ekranda yazı görselin üstüne
    /// binmesin diye şeridin neredeyse sönmüş kısmına denk gelir.
    private static let heroClearance: CGFloat = 176

    private var isAccessible: Bool { dynamicTypeSize.isAccessibilitySize }

    /// Katılmadan önce: durum yok, oturum başlatılamaz. Kütüphaneden okunur ki
    /// katılınca ekran kendiliğinden canlı duruma geçsin.
    private var isPreview: Bool { !library.isEnrolled(path) }

    private var showsHero: Bool {
        !isAccessible && !reduceTransparency && PatikaArt.exists(path.artwork)
    }

    var body: some View {
        ZStack(alignment: .top) {
            WoodlandStyle.background.ignoresSafeArea()
            DiscoverHero(box: scroll, assetName: path.artwork, height: Self.heroHeight)

            ScrollView {
                VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.sectionSpacing) {
                    Color.clear.frame(height: showsHero ? Self.heroClearance : 8)
                    titleBlock.woodlandReveal(0)
                    if !isPreview, library.nextStep(path) == nil {
                        allDone.woodlandReveal(1)
                    }
                    VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.labelSpacing) {
                        PatikaSectionLabel(verbatim: DiscoverCopy.steps)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                        DiscoverTrailMap(
                            path: path,
                            isPreview: isPreview,
                            expandedStepID: $expandedStepID,
                            onStart: { session = $0 }
                        )
                    }
                    .woodlandReveal(2)
                    if isPreview && isAccessible {
                        joinControls.padding(.horizontal, Theme.Spacing.screenMargin)
                    }
                    if library.saveFailed {
                        Text(verbatim: DiscoverCopy.saveError)
                            .font(Theme.TypeFace.rowValue)
                            .foregroundStyle(Theme.textPrimary.color)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                    }
                }
                .padding(.bottom, 36)
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, offset in
                scroll.offset = offset
            }
            .discoverDebugScroll()
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .scrollEdgeEffectStyle(.soft, for: .all)
        }
        // Çubuğun arkası gizlenmiyor: kaydırılan içerik durum çubuğunun ve geri
        // düğmesinin altına girerken sistemin kaydırma kenarı efekti onu soluyor.
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isPreview && !isAccessible {
                joinControls
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                    .padding(.top, 32)
                    .padding(.bottom, 8)
                    .background {
                        // Solma düğmenin üstünde biter; düğmenin ve notun arkası opak,
                        // altındaki durakların yazısı üst üste binmesin.
                        LinearGradient(
                            stops: [
                                .init(color: WoodlandStyle.background.opacity(0), location: 0),
                                .init(color: WoodlandStyle.background.opacity(0.97), location: 0.4),
                                .init(color: WoodlandStyle.background.opacity(0.97), location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .bottom)
                    }
            }
        }
        .sheet(isPresented: $confirmsJoin) {
            DiscoverJoinSheet {
                library.enroll(path)
                expandedStepID = library.nextStep(path)?.id
                confirmsJoin = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $session) { step in
            PathSessionView(services: services, preparedPath: path, step: step, library: library)
        }
        .onAppear {
            if expandedStepID == nil, !isPreview { expandedStepID = library.nextStep(path)?.id }
            #if DEBUG
            // `-patika-debug-discover-expanded <n>`: n. adımı (1 tabanlı) açık başlatır.
            let args = ProcessInfo.processInfo.arguments
            if let index = args.firstIndex(of: "-patika-debug-discover-expanded"),
               args.indices.contains(index + 1), let number = Int(args[index + 1]),
               path.steps.indices.contains(number - 1) {
                expandedStepID = path.steps[number - 1].id
            }
            // `-patika-debug-discover-session <n>`: n. adımın oturumunu doğrudan açar
            // (katılınmış patikada; katılım için `-patika-debug-discover-enrolled`).
            if let index = args.firstIndex(of: "-patika-debug-discover-session"),
               args.indices.contains(index + 1), let number = Int(args[index + 1]),
               path.steps.indices.contains(number - 1), !isPreview {
                session = path.steps[number - 1]
            }
            #endif
        }
    }

    // MARK: Bloklar

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isPreview {
                Label(DiscoverCopy.preview, systemImage: "eye")
                    .font(Theme.TypeFace.cardMeta)
                    .foregroundStyle(WoodlandStyle.apricot)
            }
            Text(verbatim: path.title.value)
                .font(Theme.TypeFace.coverTitle)
                .foregroundStyle(Theme.textPrimary.color)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: path.summary.value)
                .font(Theme.TypeFace.rowValue)
                .foregroundStyle(Theme.textSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Text(verbatim: DiscoverCopy.duration)
                .font(Theme.TypeFace.rowCaption)
                .foregroundStyle(WoodlandStyle.apricot)
            Text(verbatim: isPreview ? DiscoverCopy.previewNote : DiscoverCopy.offline)
                .font(Theme.TypeFace.rowCaption)
                .foregroundStyle(Theme.textSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    private var allDone: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: DiscoverCopy.allDone)
                .font(Theme.TypeFace.cardTitleProminent)
                .foregroundStyle(WoodlandStyle.ink)
            Text(verbatim: DiscoverCopy.allDoneBody)
                .font(Theme.TypeFace.rowCaption)
                .foregroundStyle(WoodlandStyle.secondaryInk)
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(PatikaSurfaceMetrics.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperSurface()
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .accessibilityElement(children: .combine)
    }

    /// Ses yokken düğme kartlardaki durumla aynı şeyi söyler: "Yakında".
    private var joinTitle: String {
        if library.isEnrolled(path) { return DiscoverCopy.continuePath }
        return library.audioIsReady(path) ? DiscoverCopy.join : DiscoverCopy.comingSoon
    }

    private var joinControls: some View {
        VStack(spacing: 10) {
            DiscoverAction(title: joinTitle, enabled: library.audioIsReady(path)) { confirmsJoin = true }
            if !library.audioIsReady(path) {
                Text(verbatim: DiscoverCopy.audioPreparing)
                    .font(Theme.TypeFace.rowCaption)
                    .foregroundStyle(Theme.textSecondary.color)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct DiscoverJoinSheet: View {
    let onJoin: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                .font(.title2.weight(Theme.Weight.emphasis))
                .foregroundStyle(WoodlandStyle.sage)
                .accessibilityHidden(true)

            Text(verbatim: DiscoverCopy.joinTitle)
                .font(Theme.TypeFace.sectionTitle)
                .foregroundStyle(Theme.textPrimary.color)

            Text(verbatim: DiscoverCopy.joinBody)
                .font(Theme.TypeFace.rowValue)
                .foregroundStyle(Theme.textSecondary.color)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            DiscoverAction(title: DiscoverCopy.join, action: onJoin)

            Button(DiscoverCopy.cancel) { dismiss() }
                .font(Theme.TypeFace.action)
                .foregroundStyle(Theme.textSecondary.color)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .padding(.top, 22)
        .padding(.bottom, 12)
        .background(WoodlandStyle.background)
    }
}

/// Hero şeridi. Kaydırma kutusunu yalnızca bu görünüm okur (`ScrollOffsetBox`).
private struct DiscoverHero: View {
    let box: ScrollOffsetBox
    let assetName: String
    let height: CGFloat

    var body: some View {
        MeBackdrop(scrollOffset: box.offset, assetName: assetName, height: height)
    }
}
