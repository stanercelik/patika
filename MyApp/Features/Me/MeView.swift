import PhotosUI
import SwiftUI

/// "Ben" sekmesinin kökü. Alt ekranlar aynı yığına itilir; sekme çubuğu
/// derinde de görünür kalır (HIG 7.5).
struct MeTab: View {
    @State private var path: [MeRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            MeView(path: $path)
        }
        #if DEBUG
        .task {
            if let route = MeDebugSeed.route { path = [route] }
        }
        #endif
    }
}

enum MeRoute: Hashable {
    case journal
    case badges
}

/// "Ben" — geriye bakan defter (`docs/profile-design.md` §21).
///
/// Kompakt bir profil: kimlik kartı, illüstrasyonlu defter kartı, rozetler,
/// "Ne değişti" ve "Destek al". Defterin kendisi ayrı sayfada; ayarlar sağ üstteki
/// dişli ile açılan yaprakta. **Birincil CTA yok.**
///
/// ## Yalnızca gerçek veri
///
/// Verisi olmayan bölüm **çizilmez**: karşılaştırma yoksa "Ne değişti" yok. Kriz
/// modunda yalnızca kimlik kartı (görselsiz, hareketsiz) ve en üstte "Destek al"
/// durur; rozet, seri ve illüstrasyon görünmez.
///
/// Zemin: koyu orman + üstte kısa bir guaj çayır şeridi (`MeBackdrop`), aşağı
/// doğru koyuya karışır ve kaydırmayla solar.
struct MeView: View {
    @Binding var path: [MeRoute]

    @Environment(AppServices.self) private var services
    @Namespace private var zoomNamespace

    @State private var viewModel: MeViewModel?

    var body: some View {
        ZStack {
            WoodlandStyle.background.ignoresSafeArea()
            if let viewModel {
                MeContent(viewModel: viewModel, path: $path, zoomNamespace: zoomNamespace)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: MeRoute.self) { route in
            if let viewModel {
                switch route {
                case .journal:
                    JournalView(viewModel: viewModel)
                        .navigationTransition(.zoom(sourceID: MeContent.journalSourceID, in: zoomNamespace))
                case .badges:
                    BadgesView(earned: viewModel.earnedBadges)
                }
            }
        }
        .task {
            if viewModel == nil { viewModel = MeViewModel(services: services) }
            await viewModel?.load()
        }
    }
}

enum MeAnchor: String {
    case identity, journal, badges, change, support
}

private enum MeSheet: String, Identifiable {
    case change
    case settings
    case account

    var id: String { rawValue }
}

private struct MeContent: View {
    static let journalSourceID = "me-journal-card"

    let viewModel: MeViewModel
    @Binding var path: [MeRoute]
    let zoomNamespace: Namespace.ID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sheet: MeSheet?
    @State private var isShowingSupport = false
    /// Teklif önce yüklenir, kaplama ancak sonra açılır: arada ekran yok.
    @State private var purchaseOffer: PathPaywallViewModel?
    @State private var isOpeningOffer = false
    @State private var isChangeRevealed = true
    @State private var scrollOffset: CGFloat = 0
    @State private var isShowingPhotoViewer = false
    @State private var isShowingPhotoPicker = false
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var editablePhoto: EditableProfilePhoto?

    var body: some View {
        ZStack(alignment: .top) {
            MeBackdrop(scrollOffset: scrollOffset, showsArtwork: !viewModel.isInCrisisMode)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.sectionSpacing) {
                        ProfileIdentityCard(
                            name: viewModel.displayName,
                            avatar: viewModel.services.avatar.image,
                            pathTitle: viewModel.pathTitle,
                            detail: viewModel.headerDetail,
                            progress: viewModel.stepProgress,
                            rhythm: viewModel.weeklyRhythm,
                            summaryAccessibility: viewModel.identityAccessibility,
                            canEditPhoto: !viewModel.isInCrisisMode,
                            onPhoto: {
                                if viewModel.services.avatar.hasImage {
                                    isShowingPhotoViewer = true
                                } else {
                                    isShowingPhotoPicker = true
                                }
                            },
                            onSettings: { sheet = .settings }
                        )
                        .id(MeAnchor.identity)
                        .padding(.top, 8)
                        .woodlandReveal(0, enabled: !viewModel.isInCrisisMode)

                        if viewModel.supportPlacement == .top {
                            supportRow
                                .woodlandReveal(1, enabled: !viewModel.isInCrisisMode)
                        }

                        if viewModel.showsContinuePathRow {
                            ContinuePathCard(
                                walked: viewModel.walkedStepCount,
                                total: viewModel.totalStepCount
                            ) { Task { await openPurchaseOffer() } }
                            .woodlandReveal(1)
                        }

                        // Kriz modunda anonim hesap çağrısı da gösterilmez.
                        if viewModel.showsAnonymousCard && !viewModel.isInCrisisMode {
                            AnonymousLinkRow(
                                onLink: { sheet = .account },
                                onDismiss: { viewModel.hideAnonymousCard() }
                            )
                            .woodlandReveal(1)
                        }

                        if !viewModel.isInCrisisMode {
                            JournalCoverCard(
                                preview: viewModel.journalCardPreview,
                                onOpen: { path.append(.journal) }
                            )
                            .matchedTransitionSource(id: Self.journalSourceID, in: zoomNamespace)
                            .id(MeAnchor.journal)
                            .woodlandReveal(2)

                            if viewModel.showsBadges {
                                BadgeShelf(earned: viewModel.earnedBadges, next: viewModel.nextBadge)
                                    .id(MeAnchor.badges)
                                    .woodlandReveal(3)
                            }

                            if let change = viewModel.change {
                                ChangeSection(summary: change, isRevealed: isChangeRevealed) {
                                    sheet = .change
                                }
                                .id(MeAnchor.change)
                                .woodlandReveal(4)
                            }

                            if viewModel.supportPlacement == .belowChange {
                                supportRow.woodlandReveal(5)
                            }
                        }

                        if viewModel.supportPlacement == .standard, !viewModel.isInCrisisMode {
                            supportRow
                                .id(MeAnchor.support)
                                .woodlandReveal(6)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                    // Son satır sekme çubuğunun altında kalmasın.
                    .padding(.bottom, 120)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                } action: { _, offset in
                    scrollOffset = offset
                }
                #if DEBUG
                .onChange(of: viewModel.pathLoad) {
                    if let debugSheet = MeDebugSeed.sheet {
                        switch debugSheet {
                        case "change": sheet = .change
                        case "settings": sheet = .settings
                        case "support": isShowingSupport = true
                        case "account": sheet = .account
                        default: break
                        }
                    }
                    if MeDebugSeed.tapsJournalCard {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { path.append(.journal) }
                    }
                    guard let anchor = MeDebugSeed.anchor else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        proxy.scrollTo(anchor, anchor: .top)
                    }
                }
                #endif
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .refreshable { await viewModel.load() }
        }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .change: ChangeDetailSheet(viewModel: viewModel)
            case .settings: SettingsSheet(viewModel: viewModel)
            case .account: AccountLinkSheet(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $isShowingPhotoViewer) {
            if let image = viewModel.services.avatar.image {
                ProfilePhotoViewer(
                    image: image,
                    onChoose: {
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(350))
                            isShowingPhotoPicker = true
                        }
                    },
                    onRemove: { Task { await viewModel.removePhoto() } }
                )
            }
        }
        .fullScreenCover(isPresented: $isShowingSupport) {
            SupportView()
        }
        .fullScreenCover(item: $purchaseOffer, onDismiss: {
            Task { await viewModel.load() }
        }) { offer in
            PathPurchaseOfferView(viewModel: offer) { purchaseOffer = nil }
        }
        .fullScreenCover(item: $editablePhoto) { photo in
            ProfilePhotoEditor(photo: photo) { data in
                Task { await viewModel.setPhoto(data) }
            }
        }
        .photosPicker(isPresented: $isShowingPhotoPicker, selection: $pickedPhoto, matching: .images)
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            Task {
                defer { pickedPhoto = nil }
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    viewModel.actionError = Copy.Me.photoFailed
                    return
                }
                editablePhoto = EditableProfilePhoto(image: image)
            }
        }
        .alert(
            Text(viewModel.actionError ?? ""),
            isPresented: Binding(
                get: { viewModel.actionError != nil && sheet == nil },
                set: { if !$0 { viewModel.actionError = nil } }
            )
        ) {
            Button(role: .cancel) {} label: { Text(Copy.Button.understood) }
        }
        .task(id: viewModel.change?.latestMeasurementID) {
            await playChangeRevealIfNeeded()
        }
    }

    /// Kriz sinyalinde ya da üç katman birden kötüleştiğinde destek yukarı çıkar;
    /// orada tek başına durduğu için kendi kartını alır.
    /// Teklifi yükler, sonra açar. Yükleme sürerken ekran değişmez.
    private func openPurchaseOffer() async {
        guard purchaseOffer == nil, !isOpeningOffer, let path = viewModel.activePath else { return }
        isOpeningOffer = true
        defer { isOpeningOffer = false }
        let offer = PathPaywallViewModel(
            services: viewModel.services,
            pathID: path.id,
            days: path.steps.count,
            context: .return,
            reminderTime: nil
        )
        await offer.load()
        purchaseOffer = offer
    }

    private var supportRow: some View {
        ProfileCard(padding: 0) {
            MeEntryRow(
                title: Copy.Me.supportTitle,
                caption: String(localized: Copy.Me.supportSubtitle),
                symbol: "hand.raised"
            ) { isShowingSupport = true }
        }
    }

    private func playChangeRevealIfNeeded() async {
        guard viewModel.consumeChangeReveal(), !reduceMotion else { return }
        isChangeRevealed = false
        try? await Task.sleep(for: .seconds(0.7))
        guard !Task.isCancelled else {
            isChangeRevealed = true
            return
        }
        isChangeRevealed = true
        try? await Task.sleep(for: .seconds(
            Theme.Motion.measurementBar + Theme.Motion.changeRowStagger * 2
        ))
        guard !Task.isCancelled else { return }
        Theme.softHaptic(intensity: 0.55)
    }
}

/// Koyu adaçayı kart içindeki dokunulabilir satır. Ayrı kartlar yerine tek
/// kartta ayırıcıyla dizilir.
private struct MeEntryRow: View {
    let title: LocalizedStringResource
    var caption: String?
    var symbol: String?
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Simge süs: AX'te 26 pt'lik çerçevesine sığmıyor ve metni sıkıştırıyor.
                if let symbol, !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: symbol)
                        .font(Theme.TypeFace.rowSymbol)
                        .foregroundStyle(Theme.textPrimary.color)
                        .frame(width: 26)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.TypeFace.rowTitle)
                        .foregroundStyle(Theme.textPrimary.color)
                        .multilineTextAlignment(.leading)
                    if let caption {
                        Text(verbatim: caption)
                            .font(Theme.TypeFace.rowCaption)
                            .foregroundStyle(Theme.textSecondary.color)
                            .multilineTextAlignment(.leading)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                ProfileChevron()
            }
            .padding(.horizontal, Theme.Surface.padding)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.calm)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Ne değişti — kompakt

/// Kompakt "Ne değişti": küçük guaj ikonu, başlık cümlesi ve üç katman için
/// "kelime + ok". Çubuklar (`BaselineTrack`) ve başlangıç göstergesi yalnızca
/// ayrıntı yaprağında; ana sayfada yüzde ya da sayı yok.
private struct ChangeSection: View {
    let summary: ChangeSummary
    let isRevealed: Bool
    let onOpen: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.labelSpacing) {
            PatikaSectionLabel(title: Copy.Me.changeTitle)

            Button(action: onOpen) { card }
                .buttonStyle(.calm)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: accessibilityText))
                .accessibilityHint(Text(Copy.Me.changeOpenHint))
                .accessibilityAddTraits(.isButton)

            // PRD §8.1: her ölçüm yüzeyinde sabit. Zeminde durur, kartta değil —
            // feragat içeriğin parçası değil, çerçevesi.
            Text(Copy.clinicalDisclaimer)
                .font(Theme.TypeFace.rowCaption)
                .foregroundStyle(Theme.textSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var card: some View {
        ProfileCard {
            HStack(alignment: .top, spacing: 14) {
                if !dynamicTypeSize.isAccessibilitySize, PatikaArt.exists("me-change") {
                    Image(decorative: "me-change")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(verbatim: summary.headline)
                            .font(Theme.TypeFace.cardTitle)
                            .foregroundStyle(Theme.textPrimary.color)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        ProfileChevron()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(summary.rows.enumerated()), id: \.element.id) { index, row in
                            rowView(row, index: index)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rowView(_ row: ChangeSummary.Row, index: Int) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        layout {
            Text(Copy.Me.layerShort(row.layer))
                .font(Theme.TypeFace.rowCaption)
                .foregroundStyle(Theme.textSecondary.color)
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
            if let direction = row.direction {
                HStack(spacing: 4) {
                    Text(Copy.Me.directionWord(row.layer, direction))
                    Image(systemName: ChangeDirectionSymbol.name(for: direction))
                        .accessibilityHidden(true)
                }
                .font(Theme.TypeFace.rowTitle)
                .foregroundStyle(Theme.textPrimary.color.opacity(0.92))
                .fixedSize()
                .opacity(isRevealed ? 1 : 0)
                .animation(rowAnimation(index), value: isRevealed)
            }
        }
    }

    private func rowAnimation(_ index: Int) -> Animation? {
        reduceMotion
            ? nil
            : .easeOut(duration: Theme.Motion.measurementBar)
                .delay(Double(index) * Theme.Motion.changeRowStagger)
    }

    private var accessibilityText: String {
        var parts = [String(localized: Copy.Me.changeTitle), summary.headline]
        for row in summary.rows {
            guard let direction = row.direction else { continue }
            parts.append(String(localized: Copy.Me.layerAccessibility(
                layer: String(localized: Copy.Me.layerShort(row.layer)),
                word: String(localized: Copy.Me.directionWord(row.layer, direction))
            )))
        }
        return parts.joined(separator: ". ")
    }
}

enum ChangeDirectionSymbol {
    static func name(for direction: MeasurementComparison.Direction) -> String {
        switch direction {
        case .improved: "arrow.up.right"
        case .unchanged: "arrow.right"
        case .worsened: "arrow.down.right"
        }
    }
}

// MARK: - Anonim hesap

/// Kimlik kartının hemen altında tek satır: hesaba bağla ya da şimdilik değil.
/// Kriz modunda gösterilmez.
private struct AnonymousLinkRow: View {
    let onLink: () -> Void
    let onDismiss: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ProfileCard(padding: 0) {
            if dynamicTypeSize.isAccessibilitySize {
                // AX: simge ve kapat düğmesi yan sütun olunca metin tek kelimelik
                // şeride sıkışıyordu; "Şimdilik değil" altta ayrı bir satır.
                VStack(alignment: .leading, spacing: 0) {
                    linkButton
                    Button(action: onDismiss) {
                        Text(Copy.Auth.notNow)
                            .font(Theme.TypeFace.rowAction)
                            .foregroundStyle(Theme.textSecondary.color)
                            .padding(.horizontal, Theme.Surface.padding)
                            .frame(minHeight: 44, alignment: .leading)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.calm)
                }
            } else {
                HStack(spacing: 0) {
                    linkButton
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(Theme.TypeFace.lockMark)
                            .foregroundStyle(Theme.textSecondary.color)
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.calm)
                    .accessibilityLabel(Text(Copy.Auth.notNow))
                    .padding(.trailing, 4)
                }
            }
        }
    }

    private var linkButton: some View {
        Button(action: onLink) {
            HStack(spacing: 12) {
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(Theme.TypeFace.rowSymbol)
                        .foregroundStyle(Theme.textPrimary.color)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(Copy.Me.anonymousTitle)
                        .font(Theme.TypeFace.rowCaption)
                        .foregroundStyle(Theme.textSecondary.color)
                    Text(Copy.Me.linkAccount)
                        .font(Theme.TypeFace.rowTitle)
                        .foregroundStyle(Theme.textPrimary.color)
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if !dynamicTypeSize.isAccessibilitySize { ProfileChevron() }
            }
            .padding(.horizontal, Theme.Surface.padding)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.calm)
    }
}

/// Sağlayıcı seçimi. Sayfada iki iri buton durmasın diye ayrı yaprakta.
struct AccountLinkSheet: View {
    let viewModel: MeViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(Copy.Auth.linkBody)
                    .font(Theme.TypeFace.product(.body, Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)

                AuthProviderButtons(isWorking: viewModel.isLinking) { provider in
                    Task {
                        await viewModel.link(provider)
                        if viewModel.isAccountLinked { dismiss() }
                    }
                }

                if let message = viewModel.authErrorMessage {
                    Text(message)
                        .font(Theme.TypeFace.rowCaption)
                        .foregroundStyle(Theme.textSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.screenMargin)
            .navigationTitle(Text(Copy.Auth.linkTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
