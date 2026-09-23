import SwiftUI

/// B6 — "Şu an, tam bu anda nasılsın?" (PRD-Ek Onboarding §3.6)
///
/// Ölçüm bölümüne yumuşak geçiş. Bu ölçek günlük ön kontrolün aynısı: kullanıcı
/// ürünün ritmini onboarding'de öğrenmiş oluyor.
///
/// Akışta arka planın kullanıcının cevabına doğrudan tepki verdiği ikinci yer
/// (ilki A2'deki kategori seçimi). Seçim anında paleti modüle ediyor: ağır
/// kademede ekran kısılıp yavaşlıyor, sakin kademede biraz açılıyor.
struct CurrentMoodView: View {
    @State private var viewModel: SingleChoiceStepViewModel<MoodLevel>

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(
            initialValue: SingleChoiceStepViewModel(
                selection: flow.draft.currentMood,
                onChange: { flow.previewCurrentMood($0) },
                commit: { flow.commitCurrentMood($0) }
            )
        )
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.moodHeadline,
            hint: Copy.Onboarding.moodHint,
            usesScenePlate: true,
            sceneContentTopSpacing: 210
        ) {
            MoodScale(selection: viewModel.selection) { level in
                viewModel.select(level)
            }
            .padding(.top, 12)
        } footer: {
            OnboardingQuestionFooter(
                primaryTitle: Copy.Button.next,
                primaryDisabledTitle: Copy.Onboarding.chooseOneCTA,
                isPrimaryEnabled: viewModel.canContinue,
                primaryAction: { viewModel.submit() }
            )
        }
    }
}

#Preview {
    OnboardingPreviewHost(step: .b6CurrentMood) { flow in
        CurrentMoodView(flow: flow)
    }
}
