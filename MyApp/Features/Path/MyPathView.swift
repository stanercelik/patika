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
    @Environment(PaletteController.self) private var palette
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var viewModel: MyPathViewModel?
    @State private var runningStep: PathStepRecord?
    @State private var isCreatingPath = false
    @State private var headerHeight: CGFloat = 280
    @State private var headerHidden = false
    @State private var scrollTracking = PathHeaderScrollTracking()
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            WoodlandStyle.background.ignoresSafeArea()
            BreathingMeshBackground(
                palette: palette.current,
                safeY: 0.12,
                breathAmplitude: BreathAmplitude.measurement
            )
            .opacity(0.20)
            .ignoresSafeArea()
            .accessibilityHidden(true)
            content
        }
        .task {
            if viewModel == nil { viewModel = MyPathViewModel(services: services) }
            await viewModel?.load()
        }
        .fullScreenCover(isPresented: $isCreatingPath, onDismiss: {
            Task { await viewModel?.load() }
        }) {
            OnboardingContainerView(palette: palette, services: services) {
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
                    .environment(palette)
            }
        }
        .onChange(of: runningStep) { old, new in
            // Oturum kapandı: tamamlanma sunucuda, ekran yeniden okuyor.
            guard old != nil, new == nil else { return }
            Task { await viewModel?.load() }
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
                Button("Tasarım önizlemesi · örnek patika") {
                    viewModel?.showDesignPreview()
                }
                .font(.caption.weight(Theme.Weight.emphasis))
                .foregroundStyle(Theme.textSecondary.color)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.vertical, 4)
                .background(Palette.neutral.background.color)
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
                        Text("Tasarım önizlemesi · örnek veriler")
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
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                let offset = geometry.contentOffset.y + geometry.contentInsets.top
                let maximum = max(0, geometry.contentSize.height - geometry.containerSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom)
                return min(maximum, max(0, offset))
            } action: { old, new in
                let delta = new - old
                if new < 12 {
                    scrollTracking.travel = 0
                    setHeaderHidden(false)
                } else {
                    if (delta > 0 && scrollTracking.travel < 0) || (delta < 0 && scrollTracking.travel > 0) {
                        scrollTracking.travel = 0
                    }
                    scrollTracking.travel += delta
                    if scrollTracking.travel > 28 { setHeaderHidden(true) }
                    if scrollTracking.travel < -18 { setHeaderHidden(false) }
                }
            }
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

    private func setHeaderHidden(_ hidden: Bool) {
        guard headerHidden != hidden else { return }
        withAnimation(reduceMotion ? .easeOut(duration: 0.18) : .smooth(duration: 0.34)) {
            headerHidden = hidden
        }
    }

    private func journeyHeader(_ path: ActivePath) -> some View {
        PathHomeHeader(
            title: path.title,
            hasNextStep: path.nextStep != nil,
            phase: path.nextStep.flatMap { viewModel?.phase(for: $0) } ?? .closing
        )
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background {
            if reduceTransparency {
                WoodlandStyle.background
            } else {
                Rectangle()
                    .fill(.regularMaterial)
                    .environment(\.colorScheme, .light)
                    .mask {
                        VStack(spacing: 0) {
                            Rectangle()
                            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                                .frame(height: 32)
                        }
                    }
                    .ignoresSafeArea(edges: .top)
            }
        }
    }

    private func start(_ step: PathStepRecord, viewModel: MyPathViewModel) {
        #if DEBUG
        if PathPreviewFixture.isEnabled || viewModel.isDesignPreview { return }
        #endif
        runningStep = step
    }
}

extension PathStepRecord: Identifiable {}

/// Gesture bookkeeping is intentionally not observable: only visibility changes
/// invalidate the screen, rather than rebuilding all stops on every scroll pixel.
private final class PathHeaderScrollTracking {
    var travel: CGFloat = 0
}
