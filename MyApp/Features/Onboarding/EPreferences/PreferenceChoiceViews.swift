import SwiftUI

/// E2 — "Adımların ne kadar sürsün?" (PRD-Ek Onboarding §6).
///
/// Önerilen seçenek (10 dakika) **önceden seçili** gelir: bu bir tercih sorusu,
/// bir ödeme kararı değil. Varsayılan yanlılığı yalnızca ödeme ve abonelik
/// kararlarında yasak.
///
/// Cevap ürünün davranışını gerçekten değiştiriyor — seçilen süre blok seçimini
/// ve ses uzunluğunu belirliyor. "Kişiselleştirme tiyatrosu" değil.
struct SessionLengthView: View {
    @State private var viewModel: SingleChoiceStepViewModel<SessionLength>

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(
            initialValue: SingleChoiceStepViewModel(
                selection: flow.draft.sessionLength,
                commit: { flow.commitSessionLength($0) }
            )
        )
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.sessionLengthHeadline,
            hint: Copy.Onboarding.sessionLengthHint
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

#Preview("E2 — süre") {
    OnboardingPreviewHost(step: .e2SessionLength) { flow in
        SessionLengthView(flow: flow)
    }
}

#Preview("E3 — ton") {
    OnboardingPreviewHost(step: .e3Tone) { flow in
        TonePreferenceView(flow: flow)
    }
}
