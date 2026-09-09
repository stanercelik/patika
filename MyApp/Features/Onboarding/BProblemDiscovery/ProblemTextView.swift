import SwiftUI

/// B1 — "Kendi cümlelerinle anlatır mısın?" (PRD-Ek Onboarding §3.1)
struct ProblemTextView: View {
    @State private var viewModel: ProblemTextViewModel

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(initialValue: ProblemTextViewModel(flow: flow))
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.problemTextHeadline,
            hint: Copy.Onboarding.problemTextHint
        ) {
            OnboardingTextInput(
                text: $viewModel.text,
                placeholder: viewModel.placeholder
            )
        } footer: {
            OnboardingQuestionFooter(
                primaryTitle: Copy.Button.next,
                isPrimaryEnabled: viewModel.canContinue,
                primaryAction: { viewModel.continueTapped() },
                skipTitle: Copy.Onboarding.problemTextSkip,
                skipAction: { viewModel.skipTapped() }
            )
        }
    }
}

#Preview {
    OnboardingPreviewHost(step: .b1ProblemText) { flow in
        ProblemTextView(flow: flow)
    }
}
