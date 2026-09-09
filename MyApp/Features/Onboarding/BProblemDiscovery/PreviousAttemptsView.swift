import SwiftUI

/// B5 — "Daha önce ne denedin?" (PRD-Ek Onboarding §3.5)
struct PreviousAttemptsView: View {
    @State private var viewModel: PreviousAttemptsViewModel

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(initialValue: PreviousAttemptsViewModel(flow: flow))
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.attemptsHeadline,
            hint: Copy.Onboarding.attemptsHint
        ) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.options) { option in
                    ChoiceRow(
                        label: option.label,
                        isSelected: viewModel.isSelected(option)
                    ) {
                        viewModel.toggle(option)
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
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.footnote.weight(Theme.Weight.action))
                .foregroundStyle(Theme.textSecondary.color)

            Text(Copy.Onboarding.attemptsTherapyNote)
                .font(.footnote.weight(Theme.Weight.body))
                .foregroundStyle(Theme.textSecondary.color)
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
