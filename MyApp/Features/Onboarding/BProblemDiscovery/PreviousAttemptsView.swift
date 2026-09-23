import SwiftUI

/// B5 — "Daha önce ne denedin?" (PRD-Ek Onboarding §3.5)
struct PreviousAttemptsView: View {
    @State private var viewModel: PreviousAttemptsViewModel

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(initialValue: PreviousAttemptsViewModel(
            selection: flow.draft.previousAttempts,
            otherText: flow.draft.previousAttemptOtherText ?? "",
            commit: { flow.commitPreviousAttempts($0, otherText: $1) },
            flagCrisis: { flow.flagCrisis() }
        ))
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.attemptsHeadline,
            hint: Copy.Onboarding.attemptsHint,
            autoScrollTarget: viewModel.isSelected(.other) ? "other-attempt" : nil
        ) {
            VStack(alignment: .leading, spacing: 10) {
                AdaptiveChoiceGrid(
                    options: viewModel.options,
                    isSelected: { viewModel.isSelected($0) },
                    onSelect: { viewModel.toggle($0) }
                )

                if viewModel.isSelected(.other) {
                    OnboardingTextInput(
                        text: $viewModel.otherText,
                        placeholder: Copy.Onboarding.attemptsOtherPlaceholder,
                        lineRange: 1...1
                    )
                    .id("other-attempt")
                    if viewModel.showsOtherRequired {
                        Text(Copy.Onboarding.attemptsOtherRequired)
                            .font(.footnote.weight(Theme.Weight.body))
                            .inkStyle(.secondary)
                    }
                }

                if viewModel.showsTherapyNote {
                    TherapyNote()
                }
            }
        } footer: {
            OnboardingQuestionFooter(
                primaryTitle: Copy.Button.next,
                isPrimaryEnabled: viewModel.canContinue,
                primaryAction: { viewModel.continueTapped() },
                skipTitle: Copy.Button.skipQuestion,
                skipAction: { viewModel.skipTapped() }
            )
        }
        .animation(Theme.Motion.crossFade, value: viewModel.showsTherapyNote)
    }
}

/// Terapi devam ediyorsa görünen sınır cümlesi.
///
/// Ürün **asla** terapinin yerine geçme imasında bulunmaz (PRD §4). Bu not bir
/// süsleme değil; kullanıcının en olası endişesine ("bunu bırakmam mı gerekiyor?")
/// sorulmadan verilen cevap.
private struct TherapyNote: View {
    @Environment(\.patikaInk) private var ink

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.footnote.weight(Theme.Weight.action))
                .foregroundStyle(ink.secondary)

            Text(Copy.Onboarding.attemptsTherapyNote)
                .font(.footnote.weight(Theme.Weight.body))
                .foregroundStyle(ink.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 2)
        .transition(.opacity)
    }
}

#Preview {
    OnboardingPreviewHost(step: .b5PreviousAttempts) { flow in
        PreviousAttemptsView(flow: flow)
    }
}
