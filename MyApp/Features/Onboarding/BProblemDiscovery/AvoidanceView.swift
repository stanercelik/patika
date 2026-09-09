import SwiftUI

/// B4 — "Bu yüzden yapmaktan kaçındığın bir şey var mı?" (PRD-Ek Onboarding §3.4)
struct AvoidanceView: View {
    @State private var viewModel: AvoidanceViewModel

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(initialValue: AvoidanceViewModel(flow: flow))
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.avoidanceHeadline,
            hint: Copy.Onboarding.avoidanceHint
        ) {
            OnboardingTextInput(
                text: $viewModel.text,
                placeholder: Copy.Onboarding.avoidancePlaceholder,
                // B4 tek cümle bekler; B1 kadar büyük bir kutu "az yazdım"
                // hissi veriyor.
                lineRange: 2...5
            )
        } footer: {
            OnboardingQuestionFooter(
                primaryTitle: Copy.Button.next,
                isPrimaryEnabled: viewModel.canContinue,
                primaryAction: { viewModel.continueTapped() },
                skipTitle: Copy.Onboarding.avoidanceSkip,
                skipAction: { viewModel.skipTapped() }
            )
        }
    }
}

#Preview {
    OnboardingPreviewHost(step: .b4Avoidance) { flow in
        AvoidanceView(flow: flow)
    }
}
