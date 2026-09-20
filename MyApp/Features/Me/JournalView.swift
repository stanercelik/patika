import SwiftUI

/// Defter — adım cevapları, ilk cümleler ve kullanıcının kendi notları
/// (`docs/profile-design.md` §21.3).
///
/// Koyu orman zemininde krem bir kâğıt yaprak. Kronolojik, en yeni üstte; ay
/// başlıklı gruplar. Gün gün başlık yok ve boş günler arada boşluk olarak da
/// görünmez: takvim ızgarası kaçırılan günü görünür yapar, defter yapmaz.
///
/// - Kullanıcının notu serif ve köşesinde küçük kalem işareti; kaydırarak silinir,
///   bağlam menüsünden ya da soldan kaydırarak düzenlenir.
/// - Adım cevabı: soru üstte, cevap serif. **Yalnızca silinir**, düzenlenmez
///   (cümle yazıldığı an path'i şekillendirdi).
/// - `hidesJournal` ve uygulama kilidi davranışı değişmedi (`isJournalObscured`).
struct JournalView: View {
    let viewModel: MeViewModel

    private enum Composer: Identifiable {
        case new
        case edit(MeViewModel.JournalItem)

        var id: String {
            switch self {
            case .new: "new"
            case .edit(let item): item.id.uuidString
            }
        }

        var item: MeViewModel.JournalItem? {
            if case .edit(let item) = self { return item }
            return nil
        }
    }

    @State private var pendingDeletion: MeViewModel.JournalItem?
    @State private var composer: Composer?
    /// Yaprak kapandıktan **sonra** işlenir: iki yaprak aynı anda açılmaz.
    @State private var finishedResult: MeViewModel.NoteSaveResult?
    @State private var celebration: BadgeCelebrationItem?
    @State private var isShowingSupport = false

    var body: some View {
        ZStack {
            WoodlandStyle.background.ignoresSafeArea()

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
                .padding(Theme.Spacing.screenMargin)
            } else if viewModel.hasJournal {
                paperList
            } else {
                emptyState
            }
        }
        .navigationTitle(Text(Copy.Me.journalTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.isJournalObscured {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { composer = .new } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel(Text(Copy.Me.journalNewNote))
                }
            }
        }
        #if DEBUG
        .task {
            switch MeDebugSeed.sheet {
            case "note": composer = .new
            case "badge": celebration = BadgeCelebrationItem(badges: [.phaseRelief])
            default: break
            }
        }
        #endif
        .sheet(item: $composer, onDismiss: handleFinishedResult) { composer in
            NoteComposerSheet(viewModel: viewModel, editing: composer.item) { result in
                finishedResult = result
            }
        }
        .sheet(item: $celebration) { item in
            BadgeEarnedSheet(badges: item.badges)
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
    }

    // MARK: Sonuç

    /// Kriz sinyalinde destek ekranı açılır: **numara**, harita değil. Yeni rozet
    /// varsa ve durum uygunsa sade kutlama yaprağı.
    private func handleFinishedResult() {
        defer { finishedResult = nil }
        switch finishedResult {
        case .crisis:
            isShowingSupport = true
        case .saved(let badges):
            guard BadgeCelebration.shouldPresent(
                badges: badges,
                isInCrisisMode: viewModel.isInCrisisMode,
                bucket: nil
            ) else { return }
            celebration = BadgeCelebrationItem(badges: badges)
        case .failed, nil:
            break
        }
    }

    // MARK: Boş defter

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(Copy.Me.journalEmpty)
                .font(Theme.TypeFace.rowValue)
                .foregroundStyle(Theme.textSecondary.color)
                .fixedSize(horizontal: false, vertical: true)

            Button { composer = .new } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.pencil").accessibilityHidden(true)
                    Text(Copy.Me.journalCardWrite)
                }
                .font(Theme.TypeFace.rowAction)
                .foregroundStyle(WoodlandStyle.apricot)
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.calm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(Theme.Spacing.screenMargin)
    }

    // MARK: Kâğıt yaprak

    private var paperList: some View {
        List {
            ForEach(viewModel.journalGroups) { group in
                Section {
                    // Başlık ilk satır: `List` bölüm başlıkları yapışkan ve
                    // kendi zeminini çiziyor, kâğıdın üstünde koyu bir bant olurdu.
                    Text(verbatim: group.title)
                        .font(Theme.TypeFace.cardMeta)
                        .foregroundStyle(WoodlandStyle.secondaryInk)
                        .accessibilityAddTraits(.isHeader)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(rowInsets(top: 16, bottom: 0))

                    ForEach(group.items) { item in
                        row(for: item)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background { paper }
        // Kapak kâğıdın üstünde başlar ve sayfa açılırken (yakınlaşma geçişiyle
        // aynı anda) sol kenarından açılır.
        .overlay { JournalCoverOverlay(preview: viewModel.journalCardPreview) }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private var paper: some View {
        PatikaPaperTexture()
    }

    private func rowInsets(top: CGFloat, bottom: CGFloat) -> EdgeInsets {
        EdgeInsets(top: top, leading: 20, bottom: bottom, trailing: 20)
    }

    private func row(for item: MeViewModel.JournalItem) -> some View {
        JournalEntryRow(item: item)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(rowInsets(top: 10, bottom: 10))
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    pendingDeletion = item
                } label: {
                    Label { Text(Copy.Me.journalDelete) } icon: { Image(systemName: "trash") }
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if item.isOwnNote {
                    Button { composer = .edit(item) } label: {
                        Label { Text(Copy.Me.journalEdit) } icon: { Image(systemName: "pencil") }
                    }
                    .tint(WoodlandStyle.sage)
                }
            }
            .contextMenu {
                if item.isOwnNote {
                    Button { composer = .edit(item) } label: {
                        Label { Text(Copy.Me.journalEdit) } icon: { Image(systemName: "pencil") }
                    }
                }
                Button(role: .destructive) {
                    pendingDeletion = item
                } label: {
                    Label { Text(Copy.Me.journalDelete) } icon: { Image(systemName: "trash") }
                }
            }
            .accessibilityAction(named: Text(Copy.Me.journalDelete)) {
                pendingDeletion = item
            }
            .accessibilityAction(named: Text(Copy.Me.journalEdit)) {
                if item.isOwnNote { composer = .edit(item) }
            }
    }
}

/// Defterdeki tek kayıt, kâğıt üstünde koyu mürekkeple. Kullanıcının kendi sesi
/// serif; kendi notunun köşesinde küçük kalem işareti. Adım cevabında soru
/// cevabın üstünde durur.
private struct JournalEntryRow: View {
    let item: MeViewModel.JournalItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: item.caption)
                    .font(Theme.TypeFace.rowCaption)
                    .foregroundStyle(WoodlandStyle.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if item.isOwnNote {
                    Image(systemName: "pencil.line")
                        .font(Theme.TypeFace.lockMark)
                        .foregroundStyle(WoodlandStyle.secondaryInk)
                        .accessibilityLabel(Text(Copy.Me.journalOwnNote))
                }
            }

            if let detail = item.detail {
                Text(verbatim: detail)
                    .font(Theme.TypeFace.rowCaption)
                    .foregroundStyle(WoodlandStyle.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(verbatim: item.text)
                .font(Theme.Voice.user())
                .foregroundStyle(WoodlandStyle.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .leading) {
            Capsule()
                .fill(WoodlandStyle.ink.opacity(0.35))
                .frame(width: Theme.Line.border)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}
