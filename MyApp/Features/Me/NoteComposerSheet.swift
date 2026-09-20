import SwiftUI

/// Defter notu yazma ve düzenleme yaprağı (`docs/profile-v2-plan.md` Aşama 4).
///
/// - **Sınır `JournalNote.maxLength`** (sunucuyla aynı sayı). Sayaç baştan
///   görünmez — yazmayı ödeve çevirir; yalnızca son %10'da "N karakter kaldı"
///   çıkar ki metnin neden durduğu anlaşılsın.
/// - **Otomatik düzeltme kapalı**: not kullanıcının kendi cümlesi, düzeltilmiş
///   hâli onun cümlesi değil.
/// - **Taslak korunur** (`NoteDraftStore`): kayıt başarısız olursa ya da yaprak
///   kapanırsa yazılan kaybolmaz. Yalnızca yeni notta; düzenlemede taslak yok.
/// - Kayıtta önce cihazdaki, sonra sunucudaki kriz taraması çalışır
///   (`MeViewModel.saveNote`). Sinyalde not yazılmaz, taslak silinir ve destek
///   ekranını açmak çağırana bırakılır (`onFinished(.crisis)`).
struct NoteComposerSheet: View {
    let viewModel: MeViewModel
    /// nil ise yeni not.
    let editing: MeViewModel.JournalItem?
    let onFinished: (MeViewModel.NoteSaveResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var isSaving = false
    @State private var showsError = false
    @FocusState private var isFocused: Bool

    /// Sayaç, sınıra bu kadar karakter kalınca görünür.
    private static let counterThreshold = JournalNote.maxLength / 10

    init(
        viewModel: MeViewModel,
        editing: MeViewModel.JournalItem?,
        onFinished: @escaping (MeViewModel.NoteSaveResult) -> Void
    ) {
        self.viewModel = viewModel
        self.editing = editing
        self.onFinished = onFinished
        _text = State(initialValue: editing?.text ?? NoteDraftStore.load() ?? "")
    }

    private var remaining: Int { JournalNote.maxLength - text.utf16.count }

    private var canSave: Bool {
        !isSaving && remaining >= 0 && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WoodlandStyle.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $text)
                            .font(Theme.Voice.user())
                            .foregroundStyle(Theme.textPrimary.color)
                            .scrollContentBackground(.hidden)
                            .autocorrectionDisabled()
                            .focused($isFocused)
                            .disabled(isSaving)
                        if text.isEmpty {
                            Text(Copy.Me.notePlaceholder)
                                .font(Theme.Voice.user())
                                .foregroundStyle(Theme.textSecondary.color)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }

                    if remaining <= Self.counterThreshold {
                        Text(remaining > 0 ? Copy.Me.noteRemaining(remaining) : Copy.Me.noteLimitReached)
                            .font(Theme.TypeFace.rowCaption)
                            .foregroundStyle(Theme.textSecondary.color)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .accessibilityAddTraits(.updatesFrequently)
                    }

                    if showsError {
                        Text(Copy.Me.noteSaveFailed)
                            .font(Theme.TypeFace.rowCaption)
                            .foregroundStyle(Theme.textSecondary.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.top, 8)
            }
            .navigationTitle(Text(editing == nil ? Copy.Me.journalNewNote : Copy.Me.journalEditNote))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text(Copy.Button.cancel) }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) { Text(Copy.Button.save) }
                        .disabled(!canSave)
                }
            }
        }
        .onChange(of: text) { _, value in
            let clamped = JournalNote.clamped(value)
            if clamped != value { text = clamped }
            showsError = false
            if editing == nil { NoteDraftStore.save(text) }
        }
        .onAppear { isFocused = true }
        .interactiveDismissDisabled(isSaving)
    }

    private func save() {
        Task {
            isSaving = true
            let result = await viewModel.saveNote(id: editing?.noteID, body: text)
            isSaving = false
            switch result {
            case .failed:
                showsError = true
            case .crisis:
                // Kriz metni taslak olarak da cihazda kalmaz.
                NoteDraftStore.clear()
                onFinished(result)
                dismiss()
            case .saved:
                if editing == nil { NoteDraftStore.clear() }
                onFinished(result)
                dismiss()
            }
        }
    }
}
