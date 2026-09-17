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
/// Bölüm sırası sabit; verisi olmayan bölüm çizilmez.
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
                VStack(alignment: .leading, spacing: 32) {
                    MeHeader(
                        name: viewModel.displayName,
                        title: viewModel.pathTitle,
                        detail: viewModel.headerDetail,
                        showsArtwork: !viewModel.isInCrisisMode
                    )
                    .padding(.top, 16)
                    .woodlandReveal(0, enabled: !viewModel.isInCrisisMode)

                    if viewModel.supportPlacement == .top {
                        SupportCard { isShowingSupport = true }
                            .woodlandReveal(1, enabled: !viewModel.isInCrisisMode)
                    }

                    if !viewModel.isInCrisisMode {
                        if let change = viewModel.change {
                            ChangeSection(summary: change, isRevealed: isChangeRevealed) {
                                sheet = .change
                            }
                            .id(MeAnchor.change)
                            .woodlandReveal(2, enabled: !viewModel.isInCrisisMode)
                        }

                        if viewModel.supportPlacement == .belowChange {
                            SupportCard { isShowingSupport = true }
                                .woodlandReveal(2, enabled: !viewModel.isInCrisisMode)
                        }

                        if viewModel.showsJournalSection {
                            JournalSection(viewModel: viewModel, pendingDeletion: $pendingDeletion)
                                .id(MeAnchor.journal)
                                .woodlandReveal(3, enabled: !viewModel.isInCrisisMode)
                        }

                        if viewModel.showsSealsSection {
                            SealsSection(seals: viewModel.seals)
                                .id(MeAnchor.paths)
                                .woodlandReveal(4, enabled: !viewModel.isInCrisisMode)
                        }

                        if !viewModel.preferenceItems.isEmpty {
                            PreferencesSection(items: viewModel.preferenceItems) { sheet = .reminder }
                                .id(MeAnchor.preferences)
                                .woodlandReveal(5, enabled: !viewModel.isInCrisisMode)
                        }

                        // Destek al, hesap işlerinin **üstünde** (P6).
                        if viewModel.supportPlacement == .standard {
                            SupportCard { isShowingSupport = true }
                                .woodlandReveal(6, enabled: !viewModel.isInCrisisMode)
                        }
                    }

                    if viewModel.showsAnonymousCard && !viewModel.isInCrisisMode {
                        AnonymousAccountCard(viewModel: viewModel) { sheet = .account }
                            .woodlandReveal(7, enabled: !viewModel.isInCrisisMode)
                    }

                    SettingsEntryCard { sheet = .settings }
                        .id(MeAnchor.settings)
                        .woodlandReveal(7, enabled: !viewModel.isInCrisisMode)

                    Text(verbatim: viewModel.versionText)
                        .font(.caption.weight(Theme.Weight.body))
                        .foregroundStyle(Theme.textSecondary.color)
                        .frame(maxWidth: .infinity)
                        .woodlandReveal(8, enabled: !viewModel.isInCrisisMode)
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

    /// Yeni ölçüm ilk kez görüldüğünde noktalar başlangıç işaretinden yeni
    /// yerlerine kayar, ardından tek bir yumuşak haptik. Sonraki açılışlarda
    /// statik. Reduce Motion'da noktalar doğrudan yerinde.
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

private struct MeHeader: View {
    let name: String?
    let title: String?
    let detail: String?
    let showsArtwork: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Copy.Me.screenTitle)
                .font(.caption.weight(Theme.Weight.emphasis))
                .foregroundStyle((showsArtwork ? WoodlandStyle.secondaryInk : Theme.textSecondary.color))
                .tracking(2)

            if let name {
                Text(verbatim: name)
                    .font(.largeTitle.weight(Theme.Weight.display))
                    .foregroundStyle((showsArtwork ? WoodlandStyle.ink : Theme.textPrimary.color))
            }
            if let title {
                Text(verbatim: title)
                    .font(name == nil ? .largeTitle.weight(Theme.Weight.display) : .title3.weight(Theme.Weight.title))
                    .foregroundStyle((showsArtwork ? WoodlandStyle.ink : Theme.textPrimary.color))
            }
            if let detail {
                Text(verbatim: detail)
                    .font(.subheadline.weight(Theme.Weight.body))
                    .foregroundStyle((showsArtwork ? WoodlandStyle.secondaryInk : Theme.textSecondary.color))
            }
            if showsArtwork && !dynamicTypeSize.isAccessibilitySize {
                PatikaIllustration(artwork: .journal)
                    .frame(height: 176)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 8)
                    .visualEffect { content, geometry in
                        let y = geometry.frame(in: .scrollView(axis: .vertical)).minY
                        return content.offset(y: reduceMotion ? 0 : min(10, max(-10, -y * 0.035)))
                    }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(showsArtwork ? 24 : 0)
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

// MARK: - 2 · Ne değişti

private struct ChangeSection: View {
    let summary: ChangeSummary
    let isRevealed: Bool
    let onOpen: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProfileSectionHeader(title: Copy.Me.changeTitle)

            Button(action: onOpen) { card }
                .buttonStyle(.calm)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: accessibilityText))
                .accessibilityHint(Text(Copy.Me.changeOpenHint))
                .accessibilityAddTraits(.isButton)

            // PRD §8.1: her ölçüm yüzeyinde sabit.
            Text(Copy.clinicalDisclaimer)
                .font(.footnote.weight(Theme.Weight.body))
                .foregroundStyle(Theme.textSecondary.color)
        }
    }

    private var card: some View {
        ProfileCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(verbatim: summary.headline)
                        .font(.title3.weight(Theme.Weight.title))
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
                        .font(.footnote.weight(Theme.Weight.body))
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
            .font(.subheadline.weight(Theme.Weight.emphasis))
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
            .font(.subheadline.weight(Theme.Weight.emphasis))
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                ProfileSectionHeader(title: Copy.Me.journalTitle)
                Spacer(minLength: 0)
                if viewModel.hasMoreJournal, !viewModel.isJournalObscured {
                    NavigationLink(value: MeRoute.journal) {
                        HStack(spacing: 4) {
                            Text(Copy.Me.journalAll)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(Theme.Weight.action))
                                .accessibilityHidden(true)
                        }
                        .font(.subheadline.weight(Theme.Weight.action))
                        .foregroundStyle(Theme.textSecondary.color)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.calm)
                }
            }

            if viewModel.isJournalObscured {
                Button { viewModel.revealJournal() } label: {
                    ProfileCard {
                        HStack(spacing: 12) {
                            Image(systemName: "eye.slash")
                                .accessibilityHidden(true)
                            Text(Copy.Me.journalHidden)
                        }
                        .font(.body.weight(Theme.Weight.emphasis))
                        .foregroundStyle(Theme.textSecondary.color)
                    }
                }
                .buttonStyle(.calm)
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(viewModel.journalPreview) { item in
                        UserQuote(text: item.text, caption: item.caption)
                            .padding(20)
                            .background(WoodlandStyle.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
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
}

// MARK: - 4 · Yürüdüğün yollar

private struct SealsSection: View {
    let seals: [MeViewModel.SealItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProfileSectionHeader(title: Copy.Me.pathsTitle)
            VStack(spacing: 12) {
                ForEach(seals) { seal in
                    NavigationLink(value: MeRoute.path(seal.id)) {
                        SealRow(seal: seal)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(WoodlandStyle.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
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
    @ScaledMetric(relativeTo: .body) private var sealSize: CGFloat = 56

    var body: some View {
        HStack(spacing: 16) {
            RouteSeal(
                stepCount: seal.stepCount,
                walkedFraction: seal.walkedFraction,
                style: seal.style,
                size: dynamicTypeSize.isAccessibilitySize ? 44 : min(sealSize, 72)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: seal.title)
                    .font(.body.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color)
                    .multilineTextAlignment(.leading)
                Text(verbatim: seal.detail)
                    .font(.footnote.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                    .multilineTextAlignment(.leading)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
            ProfileChevron()
        }
        .padding(.vertical, 8)
        .frame(minHeight: 52)
        .contentShape(.rect)
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
        VStack(alignment: .leading, spacing: 12) {
            ProfileSectionHeader(title: Copy.Me.preferencesTitle)

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
                    .font(.body.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color)
                valueLabel(showsChevron: showsChevron)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(label)
                        .font(.body.weight(Theme.Weight.emphasis))
                        .foregroundStyle(Theme.textPrimary.color)
                    Spacer(minLength: 8)
                    valueLabel(showsChevron: showsChevron)
                }
            }

            if let caption {
                Text(verbatim: caption)
                    .font(.footnote.weight(Theme.Weight.body))
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
                .font(.body.weight(Theme.Weight.body))
                .foregroundStyle(Theme.textSecondary.color)
            if showsChevron { ProfileChevron() }
        }
    }
}

// MARK: - 6 · Destek al, 8 · Uygulama

private struct SupportCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ProfileCard {
                HStack(spacing: 14) {
                    Image(systemName: "hand.raised")
                        .font(.title3.weight(Theme.Weight.title))
                        .foregroundStyle(Theme.textPrimary.color)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Copy.Me.supportTitle)
                            .font(.body.weight(Theme.Weight.emphasis))
                            .foregroundStyle(Theme.textPrimary.color)
                        Text(Copy.Me.supportSubtitle)
                            .font(.footnote.weight(Theme.Weight.body))
                            .foregroundStyle(Theme.textSecondary.color)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    ProfileChevron()
                }
            }
        }
        .buttonStyle(.calm)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

private struct SettingsEntryCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ProfileCard(padding: 0) {
                HStack {
                    Text(Copy.Me.settingsRow)
                        .font(.body.weight(Theme.Weight.emphasis))
                        .foregroundStyle(Theme.textPrimary.color)
                    Spacer(minLength: 8)
                    ProfileChevron()
                }
                .padding(.horizontal, Theme.Surface.padding)
                .padding(.vertical, 16)
                .frame(minHeight: 52)
            }
        }
        .buttonStyle(.calm)
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
                    .font(.body.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 20) {
                    Button(action: onLink) {
                        HStack(spacing: 4) {
                            Text(Copy.Me.linkAccount)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(Theme.Weight.action))
                                .accessibilityHidden(true)
                        }
                        .font(.subheadline.weight(Theme.Weight.action))
                        .foregroundStyle(Theme.textPrimary.color)
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.calm)

                    Button { viewModel.hideAnonymousCard() } label: {
                        Text(Copy.Auth.notNow)
                            .font(.subheadline.weight(Theme.Weight.emphasis))
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
                    .font(.body.weight(Theme.Weight.body))
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
                        .font(.footnote.weight(Theme.Weight.body))
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
