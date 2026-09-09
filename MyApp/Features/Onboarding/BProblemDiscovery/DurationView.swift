import SwiftUI

/// B2 — "Bu ne kadar zamandır böyle?" (PRD-Ek Onboarding §3.2)
struct DurationView: View {
    @State private var viewModel: SingleChoiceStepViewModel<ProblemDuration>

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(
            initialValue: SingleChoiceStepViewModel(
                selection: flow.draft.duration,
                commit: { flow.commitDuration($0) }
            )
        )
    }

    var body: some View {
        OnboardingQuestionLayout(headline: Copy.Onboarding.durationHeadline) {
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

/// Tek seçimlik cevap listesi. Üç ekran (B2, B3 ve sonra E bölümü) aynı yerleşimi
/// paylaşıyor; ayrı ayrı yazmak üçünün zamanla birbirinden ayrışması demek.
struct ChoiceList<Option: OnboardingChoice>: View {
    let viewModel: SingleChoiceStepViewModel<Option>

    var body: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.options) { option in
                ChoiceRow(
                    label: option.label,
                    isSelected: viewModel.isSelected(option)
                ) {
                    viewModel.select(option)
                }
            }
        }
    }
}

#Preview {
    OnboardingPreviewHost(step: .b2Duration) { flow in
        DurationView(flow: flow)
    }
}
