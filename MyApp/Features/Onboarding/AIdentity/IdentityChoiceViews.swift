import SwiftUI

/// Kimlik — cinsiyet. İkinci ekran (2026-09-22'de `IdentityView`den ayrıldı, bkz. `NameView`).
///
/// **İpucu cümlesi dürüstlük içindir:** ürünün kuralı "sorduğumuz her şeyin
/// görünür bir karşılığı olmalı". Bu sorunun yok — ve bunu saklamıyoruz.
/// Karşılığı olmayan bir soruyu varmış gibi sunmak, akışın geri kalanındaki
/// dürüstlük iddiasını zayıflatırdı (bkz. `Gender`).
struct GenderView: View {
    @State private var viewModel: SingleChoiceStepViewModel<Gender>

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(
            initialValue: SingleChoiceStepViewModel(
                selection: flow.draft.gender,
                commit: { flow.commitGender($0) }
            )
        )
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.genderHeadline,
            hint: Copy.Onboarding.identityStatsNote
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

/// Kimlik — yaş. Üçüncü ve son ekran.
///
/// Doğum tarihi sorulmuyor: onboarding'de kesin tarihe ihtiyaç yok ve kesin
/// tarih kimliklendirici bir veri. Bağlayıcı 18+ kontrolü kayıt ekranında
/// (H1) yapılır (PRD §11.4). Wheel tek yaşı gösterir; kalıcı katmana yalnızca
/// mevcut gizlilik kovası yazılır. "Söylemek istemiyorum" ayrı bir cevap yoludur.
struct AgeRangeView: View {
    private let flow: OnboardingFlowViewModel
    @State private var exactAge: Int
    @State private var prefersNotToSay: Bool

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
        self._exactAge = State(initialValue: flow.selectedExactAge ?? 24)
        self._prefersNotToSay = State(initialValue: flow.draft.ageRange == .undisclosed)
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.ageHeadline,
            hint: Copy.Onboarding.identityStatsNote
        ) {
            VStack(spacing: 22) {
                AgeWheelPicker(selection: $exactAge) { age in
                    prefersNotToSay = false
                    flow.previewAge(age)
                }
                .opacity(prefersNotToSay ? 0.46 : 1)

                ChoiceRow(
                    label: AgeRange.undisclosed.label,
                    isSelected: prefersNotToSay
                ) {
                    prefersNotToSay.toggle()
                    if !prefersNotToSay { flow.previewAge(exactAge) }
                }
            }
        } footer: {
            OnboardingQuestionFooter(
                primaryTitle: Copy.Button.next,
                primaryAction: {
                    if prefersNotToSay {
                        flow.commitAgeUndisclosed()
                    } else {
                        flow.commitAge(exactAge)
                    }
                }
            )
        }
    }
}

#Preview("Cinsiyet") {
    OnboardingPreviewHost(step: .identityGender) { flow in
        GenderView(flow: flow)
    }
}

#Preview("Yaş") {
    OnboardingPreviewHost(step: .identityAge) { flow in
        AgeRangeView(flow: flow)
    }
}
