import SwiftUI

/// B3 — "Genelde ne zaman ortaya çıkıyor?" (PRD-Ek Onboarding §3.3)
///
/// Cevap E1'deki varsayılan hatırlatma saatini belirler ve ipucu bunu kullanıcıya
/// söyler: sorduğumuz her şeyin görünür bir karşılığı olmalı.
struct TimingView: View {
    @State private var viewModel: SingleChoiceStepViewModel<ProblemTiming>

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(
            initialValue: SingleChoiceStepViewModel(
                selection: flow.draft.timing,
                onChange: { flow.previewTiming($0) },
                commit: { flow.commitTiming($0) }
            )
        )
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.timingHeadline,
            hint: Copy.Onboarding.timingHint
        ) {
            VStack(spacing: 12) {
                AdaptiveChoiceGrid(
                    options: ProblemTiming.allCases.filter { $0 != .noPattern },
                    isSelected: { viewModel.isSelected($0) },
                    onSelect: { viewModel.select($0) }
                )
                ChoiceRow(
                    label: ProblemTiming.noPattern.label,
                    isSelected: viewModel.isSelected(.noPattern)
                ) {
                    viewModel.select(.noPattern)
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

#Preview {
    OnboardingPreviewHost(step: .b3Timing) { flow in
        TimingView(flow: flow)
    }
}
