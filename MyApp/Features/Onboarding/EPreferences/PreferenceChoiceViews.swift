import SwiftUI

/// E3 — "Sana nasıl bir ses iyi gelir?" (PRD-Ek Onboarding §6, Ton eki §5.1).
///
/// Bu cevap doğrudan TTS istemine giriyor: kullanıcı farkı ilk oturumda
/// (G1) duyuyor. Onboarding'in son tercih ekranı.
struct TonePreferenceView: View {
    @State private var viewModel: SingleChoiceStepViewModel<TonePreference>

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(
            initialValue: SingleChoiceStepViewModel(
                selection: flow.draft.tonePreference,
                commit: { flow.commitTonePreference($0) }
            )
        )
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.toneHeadline,
            hint: Copy.Onboarding.toneHint
        ) {
            ChoiceList(viewModel: viewModel)
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

#Preview("E3 — ton") {
    OnboardingPreviewHost(step: .e3Tone) { flow in
        TonePreferenceView(flow: flow)
    }
}
