import SwiftUI

/// Defter — bütün cümleler (profile-design §8.2).
///
/// Kronolojik, en yeni üstte. Gün gün başlık yok ve boş günler arada boşluk olarak
/// da görünmez: takvim ızgarası kaçırılan günü görünür yapar, defter yapmaz.
struct JournalView: View {
    let viewModel: MeViewModel

    @Environment(PaletteController.self) private var palette
    @State private var pendingDeletion: MeViewModel.JournalItem?

    var body: some View {
        ZStack {
            BreathingMeshBackground(
                palette: palette.current,
                safeY: 0.3,
                breathAmplitude: BreathAmplitude.measurement
            )
            .ignoresSafeArea()

            if viewModel.isJournalObscured {
                Button { viewModel.revealJournal() } label: {
                    ProfileCard {
                        HStack(spacing: 12) {
                            Image(systemName: "eye.slash").accessibilityHidden(true)
                            Text(Copy.Me.journalHidden)
                        }
                        .font(.body.weight(Theme.Weight.emphasis))
                        .foregroundStyle(Theme.textSecondary.color)
                    }
                }
                .buttonStyle(.calm)
                .padding(Theme.Spacing.screenMargin)
            } else {
                List {
                    ForEach(viewModel.journalGroups) { group in
                        Section {
                            ForEach(group.items) { item in
                                UserQuote(text: item.text, caption: item.caption, detail: item.detail)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(
                                        top: 12,
                                        leading: Theme.Spacing.screenMargin,
                                        bottom: 12,
                                        trailing: Theme.Spacing.screenMargin
                                    ))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
                        } header: {
                            Text(verbatim: group.title)
                                .font(.footnote.weight(Theme.Weight.emphasis))
                                .foregroundStyle(Theme.textSecondary.color)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(Text(Copy.Me.journalTitle))
        .navigationBarTitleDisplayMode(.inline)
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
}
