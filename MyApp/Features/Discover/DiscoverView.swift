import SwiftUI

/// Keşfet'in yığın yolu: bir patikanın detayı.
///
/// `source` yakınlaştırma geçişinin kaynağını adlandırır: aynı patika hem "Kaldığın
/// yerden" kartında hem bölüm şeridinde görünebilir ve iki kaynak aynı kimliği
/// paylaşamaz.
enum DiscoverRoute: Hashable {
    case path(id: String, source: String)
}

/// Keşfet — hazır patika kütüphanesi.
///
/// Katman düzeni "Yolum"la aynı (`PatikaSurface.swift`): zemin (mesh + kayan guaj
/// manzara), kâğıt (kartlar), yalnızca gezinmede cam (yüzen başlık). Başlık aşağı
/// kaydırınca saklanır, yukarı kaydırınca geri gelir.
///
/// "Explore/Keşfet" üst etiketi yok ve yazı yalnızca `Theme.TypeFace`ten geliyor:
/// eski ekran ham sistem fontlarıyla SF Pro çiziyordu, uygulamanın kalanı Rounded.
struct DiscoverView: View {
    @Environment(DiscoverLibrary.self) private var library
    @Environment(PaletteController.self) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var route: [DiscoverRoute] = []
    @State private var confirmsPersonal = false
    @State private var headerHeight: CGFloat = 96
    @State private var headerHidden = false
    @Namespace private var zoomNamespace

    let onOpenPath: () -> Void

    var body: some View {
        NavigationStack(path: $route) {
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
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: DiscoverRoute.self) { route in
                switch route {
                case .path(let id, let source):
                    if let path = library.paths.first(where: { $0.id == id }) {
                        DiscoverPathView(path: path, isPreview: !library.isEnrolled(path)) {
                            self.route.removeAll()
                            onOpenPath()
                        }
                        .navigationTransition(.zoom(sourceID: source, in: zoomNamespace))
                    }
                }
            }
        }
        .confirmationDialog(DiscoverCopy.personalConfirm, isPresented: $confirmsPersonal, titleVisibility: .visible) {
            Button(DiscoverCopy.personalAction) { library.openPersonalPath(); onOpenPath() }
            Button(DiscoverCopy.cancel, role: .cancel) {}
        } message: { Text(DiscoverCopy.personalConfirmBody) }
        #if DEBUG
        .task { applyDebugArguments() }
        #endif
    }

    // MARK: İçerik

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.sectionSpacing) {
                if dynamicTypeSize.isAccessibilitySize {
                    header
                } else {
                    Color.clear.frame(height: headerHeight)
                }

                if library.loadFailed {
                    Text(verbatim: DiscoverCopy.catalogError)
                        .font(Theme.TypeFace.rowValue)
                        .foregroundStyle(Theme.textPrimary.color)
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                }

                continuing
                DiscoverPersonalCard(action: openPersonalPath)
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                    .woodlandReveal(1)

                ForEach(Array(library.sections.enumerated()), id: \.element.id) { index, shelf in
                    shelfView(shelf)
                        .woodlandReveal(index + 2)
                }
            }
            // Son satır sekme çubuğunun altında kalmasın.
            .padding(.bottom, 120)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { PathLandscapeScene(assetName: "discover-world") }
        }
        .scrollHidesHeader($headerHidden)
        .discoverDebugScroll()
        .overlay(alignment: .top) {
            if !dynamicTypeSize.isAccessibilitySize {
                header
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
    }

    private var header: some View {
        DiscoverHeader()
            // Zemin başlığın kendi camı; ekran genişliğinde bir bant yok.
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.top, 4)
            .padding(.bottom, 10)
    }

    @ViewBuilder
    private var continuing: some View {
        let paths = library.inProgressPaths
        if !paths.isEmpty {
            VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.labelSpacing) {
                PatikaSectionLabel(verbatim: DiscoverCopy.continuing)
                ForEach(paths) { path in
                    let source = "continuing-\(path.id)"
                    Button { open(path, source: source) } label: {
                        DiscoverContinueCard(path: path, done: library.completedCount(path), total: path.steps.count)
                    }
                    .buttonStyle(.calm)
                    .matchedTransitionSource(id: source, in: zoomNamespace)
                }
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .woodlandReveal(0)
        }
    }

    private func shelfView(_ shelf: DiscoverShelf) -> some View {
        VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.labelSpacing) {
            PatikaSectionLabel(verbatim: shelf.section.title)
                .padding(.horizontal, Theme.Spacing.screenMargin)
            if dynamicTypeSize.isAccessibilitySize {
                // AX'te yatay şerit yerine dikey liste: kart genişliği ekranı geçmez.
                VStack(spacing: 14) { ForEach(shelf.paths) { card($0) } }
                    .padding(.horizontal, Theme.Spacing.screenMargin)
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(shelf.paths) { card($0).frame(width: 268) }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, Theme.Spacing.screenMargin, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                // Kartın gölgesi şeridin sınırında kesilmesin.
                .scrollClipDisabled()
            }
        }
    }

    private func card(_ path: DiscoverPath) -> some View {
        Button { open(path, source: path.id) } label: {
            DiscoverPathCard(path: path, status: library.status(path))
        }
        .buttonStyle(.calm)
        .matchedTransitionSource(id: path.id, in: zoomNamespace)
    }

    // MARK: Eylemler

    private func open(_ path: DiscoverPath, source: String) {
        route.append(.path(id: path.id, source: source))
    }

    private func openPersonalPath() {
        if library.activePath == nil { onOpenPath() } else { confirmsPersonal = true }
    }

    #if DEBUG
    /// `-patika-debug-discover-preview <id>` detayı açar; `-patika-debug-discover-enrolled a,b`
    /// katılım kaydı yazar (bu cihazın UserDefaults'una — yalnızca simülatörde kullan);
    /// `-patika-debug-discover-progress N` o patikaların ilk N adımını bitirir.
    private func applyDebugArguments() {
        let args = ProcessInfo.processInfo.arguments
        func value(after flag: String) -> String? {
            guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else { return nil }
            return args[index + 1]
        }
        if let ids = value(after: "-patika-debug-discover-enrolled") {
            let steps = value(after: "-patika-debug-discover-progress").flatMap(Int.init) ?? 0
            for id in ids.split(separator: ",") {
                guard let path = library.paths.first(where: { $0.id == id }) else { continue }
                library.enroll(path, voice: .feminine)
                for step in path.steps.prefix(steps) { library.complete(step, in: path) }
            }
        }
        if let id = value(after: "-patika-debug-discover-preview"),
           library.paths.contains(where: { $0.id == id }) {
            route = [.path(id: id, source: id)]
        }
    }
    #endif
}

/// Yüzen cam başlık — `PathHomeHeader`la aynı malzeme ve ölçü.
struct DiscoverHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: DiscoverCopy.headerTitle)
                .font(Theme.TypeFace.screenTitle)
                .foregroundStyle(Theme.textPrimary.color)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: DiscoverCopy.collectionNote)
                .font(Theme.TypeFace.screenNote)
                .foregroundStyle(Theme.textSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .modifier(WoodlandGlassSurface(cornerRadius: 26))
    }
}
