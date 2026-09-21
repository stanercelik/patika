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
            // Her tonun gerçek bir örnek cümlesi: "sıcak" ya da "kısa" gibi sıfatların
            // nasıl duyulduğunu kullanıcı bilmiyor; cümleyi görüp seçiyor. Sıra ima
            // eden bir kaydırıcı değil, çünkü üç ton sıralı değil, üç ayrı tercih.
            VStack(alignment: .leading, spacing: 10) {
                Text(.tonePreferenceSampleLabel)
                    .font(.footnote.weight(Theme.Weight.emphasis))
                    .foregroundStyle(WoodlandStyle.secondaryInk)
                ForEach(viewModel.options) { tone in
                    ChoiceRow(
                        label: tone.label,
                        isSelected: viewModel.isSelected(tone),
                        detail: tone.sample
                    ) {
                        viewModel.select(tone)
                    }
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

extension TonePreference {
    /// Ekrandaki örnek; gerçek anlatımın kendisi değil, tonun nasıl duyulacağının göstergesi.
    var sample: LocalizedStringResource {
        switch self {
        case .calmAndShort: .tonePreferenceSampleCalmAndShort
        case .moreGuiding: .tonePreferenceSampleMoreGuiding
        case .infoOnly: .tonePreferenceSampleInfoOnly
        }
    }
}

#Preview("E3 — ton") {
    OnboardingPreviewHost(step: .e3Tone) { flow in
        TonePreferenceView(flow: flow)
    }
}
