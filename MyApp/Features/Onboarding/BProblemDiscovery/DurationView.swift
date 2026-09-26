import SwiftUI

/// B2 — "Bu ne kadar zamandır böyle?" (PRD-Ek Onboarding §3.2)
///
/// Four direct duration choices avoid hiding the answer behind a ruler gesture.
/// "Emin değilim" remains a full-width honest escape below them.
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

    private var ordered: [ProblemDuration] { ProblemDuration.allCases.filter { $0 != .unsure } }

    var body: some View {
        OnboardingQuestionLayout(headline: Copy.Onboarding.durationHeadline) {
            VStack(spacing: 22) {
                AdaptiveChoiceGrid(
                    options: ordered,
                    isSelected: { viewModel.isSelected($0) },
                    onSelect: { viewModel.select($0) }
                )
                ChoiceRow(
                    label: ProblemDuration.unsure.label,
                    isSelected: viewModel.isSelected(.unsure)
                ) {
                    viewModel.select(.unsure)
                }
            }
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

/// Tek seçimlik cevap listesi. Üç ekran (B3 ve E bölümü) aynı yerleşimi
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
