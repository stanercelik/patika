import SwiftUI

/// B2 — "Bu ne kadar zamandır böyle?" (PRD-Ek Onboarding §3.2)
///
/// Süre sıralı bir cevap: dört durağı olan bir cetvel. `DualStatementSlider` sayı
/// değil kova üretir (`ProblemDuration`), sunucu sözleşmesi aynı kalır.
///
/// "Emin değilim" bir süre değil, dürüst bir cevap: cetvelin durağı olamaz, altında
/// ayrı bir satır olarak durur ve seçilince cetvelin iğnesi kalkar.
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
                DualStatementSlider(
                    options: ordered,
                    selection: viewModel.selection.flatMap { ordered.contains($0) ? $0 : nil },
                    onSelect: { viewModel.select($0) },
                    lowStatement: .problemDurationSliderLow,
                    highStatement: .problemDurationSliderHigh,
                    accessibilityLabel: .problemDurationSliderAccessibility
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
