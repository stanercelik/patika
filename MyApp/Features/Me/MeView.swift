import SwiftUI

/// "Ben" sekmesinin kökü. Alt ekranlar aynı yığına itilir; sekme çubuğu
/// derinde de görünür kalır (HIG 7.5).
struct MeTab: View {
    var body: some View {
        NavigationStack {
            MeView()
        }
    }
}

enum MeRoute: Hashable {
    case journal
    case path(String)
}

/// "Ben" — geriye bakan defter (`docs/profile-design.md`).
///
/// ## Yüzey: krem kapak + koyu adaçayı kartlar (`profile-design.md` §20)
///
/// Sayfanın üstünde **krem kâğıt bir kapak** durur: koyu yeşil metin ve guaj
/// defter çizimi. Altında **opak koyu adaçayı** kartlar gelir. Defter alıntıları
/// ve geçmiş yollar kendi yuvarlak yüzeylerini alır.
///
/// > Bu §20'nin kararıdır ve §9.2'nin "kart = koyu yüzey" tarifini de, bir ara
/// > denenen "her şey kâğıt" yönünü de geçersiz kılar. Her şeyi kâğıda çevirmek
/// > kapağı sıradanlaştırıyordu: kapak ancak altındaki yüzey ondan farklıysa
/// > kapak gibi okunuyor.
///
/// ## Kart sayısı azaltıldı (ürün sahibi geri bildirimi, 2026-09-17)
///
/// §20'nin malzemesi korunarak bölümler **gruplandı**: "Destek al" ve "Ayarlar"
/// ayrı iki kart değil, ayırıcıyla bölünmüş tek kart. Gerekçe: sekiz ayrı kutu
/// sayfayı eşit ağırlıkta sekize bölüyordu ve hangisinin önemli olduğu
/// okunmuyordu. Aynı kalıp Waking Up ve stoic.'in profil ekranlarında da var:
/// sakinlik, kutu sayısını azaltıp satırları tek yüzeyde toplamaktan geliyor.
///
/// ## Yalnızca gerçek veri
///
/// Verisi olmayan bölüm **çizilmez**: karşılaştırma yoksa "Ne değişti" yok,
/// cümle yoksa defter yok, yol yoksa mühür yok. **Birincil CTA yok.**
struct MeView: View {
    @Environment(AppServices.self) private var services
    @Environment(PaletteController.self) private var palette

    @State private var viewModel: MeViewModel?

    var body: some View {
        ZStack {
            WoodlandStyle.background.ignoresSafeArea()
            BreathingMeshBackground(
                palette: palette.current,
                safeY: 0.12,
                breathAmplitude: viewModel?.isInCrisisMode == true ? BreathAmplitude.crisis : BreathAmplitude.measurement
            )
            .opacity(0.16)
            .ignoresSafeArea()

            if let viewModel {
                MeContent(viewModel: viewModel)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: MeRoute.self) { route in
            if let viewModel {
                switch route {
                case .journal:
                    JournalView(viewModel: viewModel)
                case .path(let id):
                    PathDetailView(viewModel: viewModel, sealID: id)
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
    case change, journal, paths, preferences, settings
}

private enum MeSheet: String, Identifiable {
    case change
    case reminder
    case settings
    case account

    var id: String { rawValue }
}

private struct MeContent: View {
    let viewModel: MeViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sheet: MeSheet?
    @State private var isShowingSupport = false
    @State private var isChangeRevealed = true
    @State private var pendingDeletion: MeViewModel.JournalItem?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.sectionSpacing) {
                    MeHeader(
                        name: viewModel.displayName,
                        title: viewModel.pathTitle,
                        detail: viewModel.headerDetail,
                        showsArtwork: !viewModel.isInCrisisMode
                    )
                    .padding(.top, 8)
                    .woodlandReveal(0, enabled: !viewModel.isInCrisisMode)

                    if viewModel.supportPlacement == .top {
                        supportRow
                            .woodlandReveal(1, enabled: !viewModel.isInCrisisMode)
                    }

                    if !viewModel.isInCrisisMode {
                        if let change = viewModel.change {
                            ChangeSection(summary: change, isRevealed: isChangeRevealed) {
                                sheet = .change
                            }
                            .id(MeAnchor.change)
                            .woodlandReveal(2)
                        }

                        if viewModel.supportPlacement == .belowChange {
                            supportRow.woodlandReveal(2)
                        }

                        if viewModel.showsJournalSection {
                            JournalSection(viewModel: viewModel, pendingDeletion: $pendingDeletion)
                                .id(MeAnchor.journal)
                                .woodlandReveal(3)
                        }

                        if viewModel.showsSealsSection {
                            SealsSection(seals: viewModel.seals)
                                .id(MeAnchor.paths)
                                .woodlandReveal(4)
                        }

                        if !viewModel.preferenceItems.isEmpty {
                            PreferencesSection(items: viewModel.preferenceItems) { sheet = .reminder }
                                .id(MeAnchor.preferences)
                                .woodlandReveal(5)
                        }

                    }

                    // Destek al + Ayarlar tek kartta, ayırıcıyla (P6: destek
                    // hesap işlerinin üstünde kalır). İki ayrı kutu, aynı
                    // ağırlıkta iki karar varmış gibi okunuyordu.
                    ProfileCard(padding: 0) {
                        VStack(spacing: 0) {
                            if viewModel.supportPlacement == .standard, !viewModel.isInCrisisMode {
                                MeEntryRow(
                                    title: Copy.Me.supportTitle,
                                    caption: String(localized: Copy.Me.supportSubtitle),
                                    symbol: "hand.raised"
                                ) { isShowingSupport = true }
                                ProfileRowDivider().padding(.leading, Theme.Surface.padding)
                            }
                            MeEntryRow(title: Copy.Me.settingsRow) { sheet = .settings }
                        }
                    }
                    .id(MeAnchor.settings)
                    .woodlandReveal(6, enabled: !viewModel.isInCrisisMode)

                    // §20: kriz durumunda anonim hesap kartı gösterilmez.
                    if viewModel.showsAnonymousCard && !viewModel.isInCrisisMode {
                        AnonymousAccountCard(viewModel: viewModel) { sheet = .account }
                            .woodlandReveal(7)
                    }

                    Text(verbatim: viewModel.versionText)
                        .font(Theme.TypeFace.rowCaption)
                        .foregroundStyle(Theme.textSecondary.color)
                        .frame(maxWidth: .infinity)
                        .woodlandReveal(8)
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                // Son satır sekme çubuğunun altında kalmasın.
                .padding(.bottom, 120)
            }
            #if DEBUG
            .onChange(of: viewModel.pathLoad) {
                if let debugSheet = MeDebugSeed.sheet {
                    switch debugSheet {
                    case "change": sheet = .change
                    case "settings": sheet = .settings
                    case "reminder": sheet = .reminder
                    case "support": isShowingSupport = true
                    default: break
                    }
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
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .change: ChangeDetailSheet(viewModel: viewModel)
            case .reminder: ReminderSheet(viewModel: viewModel)
            case .settings: SettingsSheet(viewModel: viewModel)
            case .account: AccountLinkSheet(viewModel: viewModel)
            }
        }
        .fullScreenCover(isPresented: $isShowingSupport) {
            SupportView()
        }
        .alert(
            Text(Copy.Me.journalDeleteTitle),
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            presenting: pendingDeletion
        ) { item in
            Button(role: .destructive) {
                Task { await viewModel.delete(item) }
            } label: {
                Text(Copy.Me.journalDelete)
            }
            Button(role: .cancel) {} label: { Text(Copy.Button.cancel) }
        } message: { item in
            Text(viewModel.deletionMessage(for: item))
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

// MARK: - 1 · Başlık

/// Krem kâğıt kapak: koyu yeşil metin + guaj defter çizimi (`profile-design.md`
/// §20).
///
/// Bir ara bu kapak kaldırılıp yerine cam bir çubuk konmuştu; sayfa o hâlde
/// kimliğini tamamen kaybetti (ürün sahibi geri bildirimi, 2026-09-17). Kapak
/// geri geldi — sayfanın fikri **geriye bakan defter** ve o fikri taşıyan tek
/// görsel bu.
///
/// Parallax en fazla 10 pt (§20) ve yalnızca render katmanında: yerleşime
/// yazmadığı için kaydırma sırasında satırlar yeniden ölçülmüyor.
///
/// Kriz durumunda kapak, görsel ve hareket yoktur: `showsArtwork` false.
private struct MeHeader: View {
    let name: String?
    let title: String?
    let detail: String?
    let showsArtwork: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Copy.Me.screenTitle)
                .font(Theme.TypeFace.eyebrow)
                .tracking(1.2)
                .foregroundStyle(showsArtwork ? WoodlandStyle.secondaryInk : Theme.textSecondary.color)

            // Ad yoksa ad satırı hiç yoktur; path adı büyüyüp başlık rolünü alır.
            // "Sen" ya da "Misafir" yazılmaz (kimlik bloğu kuralı).
            if let name {
                Text(verbatim: name)
                    .font(Theme.TypeFace.coverTitle)
                    .foregroundStyle(showsArtwork ? WoodlandStyle.ink : Theme.textPrimary.color)
            }
            if let title {
                Text(verbatim: title)
                    .font(name == nil ? Theme.TypeFace.coverTitle : Theme.TypeFace.sectionTitle)
                    .foregroundStyle(showsArtwork ? WoodlandStyle.ink : Theme.textPrimary.color)
            }
            if let detail {
                Text(verbatim: detail)
                    .font(Theme.TypeFace.screenNote)
                    .foregroundStyle(showsArtwork ? WoodlandStyle.secondaryInk : Theme.textSecondary.color)
            }

            if showsArtwork && !dynamicTypeSize.isAccessibilitySize {
                PatikaIllustration(artwork: .journal)
                    .frame(height: 168)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)
                    .visualEffect { content, geometry in
                        let y = geometry.frame(in: .scrollView(axis: .vertical)).minY
                        return content.offset(y: min(10, max(-10, -y * 0.035)))
                    }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(showsArtwork ? 22 : 0)
        .background {
            if showsArtwork {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(WoodlandStyle.paper)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Koyu adaçayı kart içindeki dokunulabilir satır. Ayrı kartlar yerine tek
/// kartta ayırıcıyla dizilir.
private struct MeEntryRow: View {
    let title: LocalizedStringResource
    var caption: String?
    var symbol: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let symbol {
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

// MARK: - 2 · Ne değişti — sayfanın tek açık bloğu

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

            // PRD §8.1: her ölçüm yüzeyinde sabit. Zeminde durur, kâğıtta değil —
            // feragat içeriğin parçası değil, çerçevesi.
            Text(Copy.clinicalDisclaimer)
                .font(Theme.TypeFace.rowCaption)
                .foregroundStyle(Theme.textSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var card: some View {
        ProfileCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(verbatim: summary.headline)
                        .font(Theme.TypeFace.cardTitleProminent)
                        .foregroundStyle(Theme.textPrimary.color)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    ProfileChevron()
                }

                rows

                HStack(spacing: 8) {
                    BaselineLegendMark()
                    Text(verbatim: summary.legend)
                        .font(Theme.TypeFace.rowCaption)
                        .foregroundStyle(Theme.textSecondary.color)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }

    @ViewBuilder
    private var rows: some View {
        let indexed = Array(summary.rows.enumerated())
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(indexed, id: \.element.id) { index, row in
                    VStack(alignment: .leading, spacing: 6) {
                        label(row)
                        direction(row, index: index)
                        track(row, index: index)
                    }
                }
            }
        } else {
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 16) {
                ForEach(indexed, id: \.element.id) { index, row in
                    GridRow(alignment: .center) {
                        label(row)
                        track(row, index: index)
                        direction(row, index: index)
                            .gridColumnAlignment(.trailing)
                    }
                }
            }
        }
    }

    private func label(_ row: ChangeSummary.Row) -> some View {
        Text(Copy.Me.layerShort(row.layer))
            .font(Theme.TypeFace.rowTitle)
            .foregroundStyle(Theme.textPrimary.color)
            .fixedSize(horizontal: true, vertical: false)
    }

    private func track(_ row: ChangeSummary.Row, index: Int) -> some View {
        BaselineTrack(offset: row.offset, isRevealed: isRevealed)
            .frame(minWidth: 72, maxWidth: .infinity)
            .animation(rowAnimation(index), value: isRevealed)
    }

    @ViewBuilder
    private func direction(_ row: ChangeSummary.Row, index: Int) -> some View {
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

// MARK: - 3 · Defter

private struct JournalSection: View {
    let viewModel: MeViewModel
    @Binding var pendingDeletion: MeViewModel.JournalItem?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.labelSpacing) {
            header

            if viewModel.isJournalObscured {
                Button { viewModel.revealJournal() } label: {
                    ProfileCard {
                        HStack(spacing: 12) {
                            Image(systemName: "eye.slash").accessibilityHidden(true)
                            Text(Copy.Me.journalHidden)
                        }
                        .font(Theme.TypeFace.rowTitle)
                        .foregroundStyle(Theme.textSecondary.color)
                    }
                }
                .buttonStyle(.calm)
            } else {
                // §20: defter alıntıları kendi yuvarlak yüzeylerini alır.
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.journalPreview) { item in
                        UserQuote(text: item.text, caption: item.caption)
                            .padding(Theme.Surface.padding)
                            .background(
                                WoodlandStyle.surface,
                                in: RoundedRectangle(cornerRadius: Theme.Surface.cornerRadius, style: .continuous)
                            )
                            .contextMenu {
                                Button(role: .destructive) {
                                    pendingDeletion = item
                                } label: {
                                    Label {
                                        Text(Copy.Me.journalDelete)
                                    } icon: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                            .accessibilityAction(named: Text(Copy.Me.journalDelete)) {
                                pendingDeletion = item
                            }
                    }
                }
            }
        }
    }

    /// "Tümü" bir `NavigationLink` olduğu için `PatikaSectionLabel`ın closure
    /// tabanlı eylemi kullanılamıyor; başlık burada elle kuruluyor.
    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(Copy.Me.journalTitle)
                .font(Theme.TypeFace.sectionTitle)
                .foregroundStyle(Theme.textPrimary.color)
                .accessibilityAddTraits(.isHeader)
            // Gizlilik ayarının açık olduğu sayfada her an görünür (F13):
            // kullanıcı korumayı bir köşede unutmasın.
            if viewModel.hidesJournal {
                Image(systemName: "eye.slash")
                    .font(Theme.TypeFace.rowCaption)
                    .foregroundStyle(Theme.textSecondary.color)
                    .accessibilityHidden(true)
            }
            Spacer(minLength: 0)
            if viewModel.hasMoreJournal, !viewModel.isJournalObscured {
                NavigationLink(value: MeRoute.journal) {
                    HStack(spacing: 4) {
                        Text(Copy.Me.journalAll)
                        Image(systemName: "chevron.right")
                            .font(Theme.TypeFace.lockMark)
                            .accessibilityHidden(true)
                    }
                    .font(Theme.TypeFace.rowAction)
                    .foregroundStyle(Theme.textSecondary.color)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.calm)
            }
        }
    }
}

// MARK: - 4 · Yürüdüğün yollar

private struct SealsSection: View {
    let seals: [MeViewModel.SealItem]

    var body: some View {
        VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.labelSpacing) {
            PatikaSectionLabel(title: Copy.Me.pathsTitle)
            VStack(spacing: 10) {
                ForEach(seals) { seal in
                    NavigationLink(value: MeRoute.path(seal.id)) {
                        SealRow(seal: seal)
                    }
                    .buttonStyle(.calm)
                }
            }
        }
    }
}

private struct SealRow: View {
    let seal: MeViewModel.SealItem

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var sealSize: CGFloat = 52

    var body: some View {
        HStack(spacing: 14) {
            RouteSeal(
                stepCount: seal.stepCount,
                walkedFraction: seal.walkedFraction,
                style: seal.style,
                size: dynamicTypeSize.isAccessibilitySize ? 44 : min(sealSize, 68)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: seal.title)
                    .font(Theme.TypeFace.rowTitle)
                    .foregroundStyle(Theme.textPrimary.color)
                    .multilineTextAlignment(.leading)
                Text(verbatim: seal.detail)
                    .font(Theme.TypeFace.rowCaption)
                    .foregroundStyle(Theme.textSecondary.color)
                    .multilineTextAlignment(.leading)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
            ProfileChevron()
        }
        .padding(.horizontal, Theme.Surface.padding)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .contentShape(.rect)
        // §20: geçmiş yollar da kendi yuvarlak yüzeyini alır.
        .background(
            WoodlandStyle.surface,
            in: RoundedRectangle(cornerRadius: Theme.Surface.cornerRadius, style: .continuous)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Copy.Me.sealAccessibility(title: seal.title, detail: seal.detail)))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - 5 · Sana göre ayarlananlar

private struct PreferencesSection: View {
    let items: [MeViewModel.PreferenceItem]
    let onEditReminder: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.labelSpacing) {
            PatikaSectionLabel(title: Copy.Me.preferencesTitle)

            ProfileCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            ProfileRowDivider().padding(.leading, Theme.Surface.padding)
                        }
                        PreferenceRow(
                            label: Self.label(for: item.kind),
                            value: item.value,
                            caption: item.caption,
                            action: item.isEditable ? onEditReminder : nil
                        )
                    }
                }
            }
        }
    }

    private static func label(for kind: MeViewModel.PreferenceItem.Kind) -> LocalizedStringResource {
        switch kind {
        case .reminder: Copy.Me.reminderLabel
        case .sessionLength: Copy.Me.sessionLengthLabel
        case .tone: Copy.Me.toneLabel
        case .voice: Copy.Me.voiceLabel
        }
    }
}

private struct PreferenceRow: View {
    let label: LocalizedStringResource
    let value: String
    var caption: String?
    var action: (() -> Void)?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if let action {
            Button(action: action) { content(showsChevron: true) }
                .buttonStyle(.calm)
                .accessibilityAddTraits(.isButton)
        } else {
            content(showsChevron: false)
        }
    }

    private func content(showsChevron: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if dynamicTypeSize.isAccessibilitySize {
                Text(label)
                    .font(Theme.TypeFace.rowTitle)
                    .foregroundStyle(Theme.textPrimary.color)
                valueLabel(showsChevron: showsChevron)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(label)
                        .font(Theme.TypeFace.rowTitle)
                        .foregroundStyle(Theme.textPrimary.color)
                    Spacer(minLength: 8)
                    valueLabel(showsChevron: showsChevron)
                }
            }

            // "Sorduğumuz her şeyin karşılığı olmalı": değerin kaynağı yazılır.
            if let caption {
                Text(verbatim: caption)
                    .font(Theme.TypeFace.rowCaption)
                    .foregroundStyle(Theme.textSecondary.color)
                    .multilineTextAlignment(.leading)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Theme.Surface.padding)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    private func valueLabel(showsChevron: Bool) -> some View {
        HStack(spacing: 6) {
            Text(verbatim: value)
                .font(Theme.TypeFace.rowValue)
                .foregroundStyle(Theme.textSecondary.color)
            if showsChevron { ProfileChevron() }
        }
    }
}

// MARK: - Anonim hesap

private struct AnonymousAccountCard: View {
    let viewModel: MeViewModel
    let onLink: () -> Void

    var body: some View {
        ProfileCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(Copy.Me.anonymousTitle)
                    .font(Theme.TypeFace.rowTitle)
                    .foregroundStyle(Theme.textPrimary.color)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 20) {
                    Button(action: onLink) {
                        HStack(spacing: 4) {
                            Text(Copy.Me.linkAccount)
                            Image(systemName: "chevron.right")
                                .font(Theme.TypeFace.lockMark)
                                .accessibilityHidden(true)
                        }
                        .font(Theme.TypeFace.rowAction)
                        .foregroundStyle(Theme.textPrimary.color)
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.calm)

                    Button { viewModel.hideAnonymousCard() } label: {
                        Text(Copy.Auth.notNow)
                            .font(Theme.TypeFace.rowAction)
                            .foregroundStyle(Theme.textSecondary.color)
                            .frame(minHeight: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.calm)
                }
            }
        }
    }
}

/// Sağlayıcı seçimi. Sayfada iki iri buton durmasın diye ayrı yaprakta.
private struct AccountLinkSheet: View {
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
