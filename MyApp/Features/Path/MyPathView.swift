import SwiftUI

/// "Yolum" sekmesi — onboarding sonrası patikanın hâli (PRD §6).
///
/// ## İz dili
///
/// F2 ile aynı düğüm dilini korur; fakat günlük kullanımda yol baştan sona
/// kesintisiz, sakin bir mürekkep izi olarak akar. Faz eşikleri yolu kesmez.
///
/// Sıradaki adım daha büyük, nefes ritminde bir düğüm ve açılabilen kartla
/// belirginleşiyor. Gelecek adımların gerçek başlıkları görünür kalıyor; kilit
/// işareti henüz açılamadıklarını anlatırken iz kesintisiz devam ediyor.
///
/// ## Sayaç yok, streak yok
///
/// Kaçırılan gün hiçbir şeyi geri almıyor: ekranda ne seri, ne "bugün de kaçtı",
/// ne yüzde. Tek söylenen, sıradaki adımın hazır olduğu.
struct MyPathView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var viewModel: MyPathViewModel?
    @State private var runningStep: PathStepRecord?
    /// Teklif önce yüklenir, kaplama ancak sonra açılır: arada ekran yok.
    @State private var purchaseOffer: PathPaywallViewModel?
    @State private var isOpeningOffer = false
    @State private var isCreatingPath = false
    @State private var headerHeight: CGFloat = 150
    @State private var headerHidden = false

    var body: some View {
        ZStack {
            WoodlandStyle.background.ignoresSafeArea()
            content
        }
        .task {
            if viewModel == nil { viewModel = MyPathViewModel(services: services) }
            await viewModel?.load()
        }
        .fullScreenCover(isPresented: $isCreatingPath, onDismiss: {
            Task { await viewModel?.load() }
        }) {
            OnboardingContainerView(services: services) {
                isCreatingPath = false
            }
            .safeAreaInset(edge: .top, alignment: .leading, spacing: 0) {
                Button(Copy.Button.finish) { isCreatingPath = false }
                    .font(.caption.weight(Theme.Weight.action))
                    .foregroundStyle(Theme.textPrimary.color)
                    .padding(12)
                    .background(.black.opacity(0.8), in: Capsule())
                    .padding(.leading, 24)
            }
        }
        .fullScreenCover(item: $runningStep) { step in
            if let path = viewModel?.path {
                PathSessionView(services: services, path: path, step: step)
            }
        }
        // Tam ekran ve doğrudan RevenueCat paywall'ı (teklif önceden yüklendi).
        .fullScreenCover(item: $purchaseOffer, onDismiss: {
            Task { await viewModel?.load() }
        }) { offer in
            PathPurchaseOfferView(viewModel: offer) { purchaseOffer = nil }
        }
        .onChange(of: runningStep) { old, new in
            // Oturum kapandı: tamamlanma sunucuda, ekran yeniden okuyor.
            guard let old, new == nil else { return }
            Task {
                await viewModel?.load()
                if viewModel?.consumeReplayOffer(finishedDay: old.day) == true {
                    await openPurchaseOffer()
                }
            }
        }
        .onChange(of: viewModel?.recentlyCompletedStepID) { _, completedID in
            guard completedID != nil, !reduceMotion else { return }
            Theme.softHaptic(intensity: 0.55)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel?.state ?? .loading {
        case .loading:
            ProgressView()
                .tint(Theme.textPrimary.color)
                .accessibilityLabel(Text(Copy.Path.loading))
        case .empty:
            PathEmptyState(
                onCreate: { isCreatingPath = true },
                onRetry: { Task { await viewModel?.load() } }
            )
            #if DEBUG
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button("Design preview · sample path") {
                    viewModel?.showDesignPreview()
                }
                .font(.caption.weight(Theme.Weight.emphasis))
                .foregroundStyle(Theme.textSecondary.color)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.vertical, 4)
                .background(WoodlandStyle.background)
            }
            #endif
        case .failed:
            VStack(spacing: Theme.Spacing.stack) {
                BodyText(Copy.Path.loadError)
                Button(Copy.Path.retry) {
                    Task { await viewModel?.load() }
                }
                .buttonStyle(.calm)
                .foregroundStyle(Theme.textPrimary.color)
                .frame(minHeight: 44)
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
        case .ready(let path):
            ready(path)
        }
    }

    private func ready(_ path: ActivePath) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    #if DEBUG
                    if viewModel?.isDesignPreview == true {
                        Text("Design preview · sample data")
                            .font(.caption.weight(Theme.Weight.emphasis))
                            .foregroundStyle(Theme.textSecondary.color)
                    }
                    #endif
                    if dynamicTypeSize.isAccessibilitySize {
                        journeyHeader(path)
                    } else {
                        Color.clear.frame(height: headerHeight)
                    }

                    if let viewModel {
                        IllustratedPathMap(viewModel: viewModel) { step in
                            start(step, viewModel: viewModel)
                        }
                        if viewModel.nextStep == nil {
                            BodyText(Copy.Path.finishedBody)
                                .padding(.horizontal, Theme.Spacing.screenMargin)
                        }
                    }
                }
                .padding(.bottom, 100)
                .background { PathLandscapeScene() }
            }
            .scrollHidesHeader($headerHidden)
            .overlay(alignment: .top) {
                if !dynamicTypeSize.isAccessibilitySize {
                    journeyHeader(path)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
                        .offset(y: reduceMotion || !headerHidden ? 0 : -headerHeight)
                        .opacity(headerHidden ? 0 : 1)
                        .allowsHitTesting(!headerHidden)
                        .accessibilityHidden(headerHidden)
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .scrollEdgeEffectStyle(.soft, for: .all)
            .refreshable { await viewModel?.load() }
            .task(id: path.id) {
                #if DEBUG
                if PathPreviewFixture.isEnabled,
                   let day = PathPreviewFixture.scrollDay,
                   let target = path.steps.first(where: { $0.day == day }) {
                    await Task.yield()
                    proxy.scrollTo(target.id, anchor: .top)
                }
                #endif
            }
        }
    }

    private func journeyHeader(_ path: ActivePath) -> some View {
        PathHomeHeader(
            title: path.title,
            hasNextStep: path.nextStep != nil,
            phase: path.nextStep.flatMap { viewModel?.phase(for: $0) } ?? .closing
        )
        // Zemin başlığın kendi camı; ekran genişliğinde bir bant yok. Başlık
        // manzaranın üstünde yüzüyor, onu ikiye bölmüyor.
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private func start(_ step: PathStepRecord, viewModel: MyPathViewModel) {
        #if DEBUG
        if PathPreviewFixture.isEnabled || viewModel.isDesignPreview { return }
        #endif
        if viewModel.requiresPurchase(step) {
            Task { await openPurchaseOffer() }
        } else {
            runningStep = step
        }
    }
}

extension PathStepRecord: Identifiable {}

extension MyPathView {
    /// Teklifi yükler, sonra açar. Yükleme sürerken ekran değişmez.
    @MainActor
    private func openPurchaseOffer() async {
        guard purchaseOffer == nil, !isOpeningOffer, let path = viewModel?.path else { return }
        isOpeningOffer = true
        defer { isOpeningOffer = false }
        let offer = PathPaywallViewModel(
            services: services,
            pathID: path.id,
            days: path.steps.count,
            context: .return,
            reminderTime: nil
        )
        await offer.load()
        // Zaten açılmışsa (hak az önce yazıldı) teklif yok: ekran yenilenir, adım açılır.
        if case .unlocked = offer.state {
            await viewModel?.load()
            return
        }
        purchaseOffer = offer
    }
}
