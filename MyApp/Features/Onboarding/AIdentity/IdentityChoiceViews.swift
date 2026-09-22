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
/// (H1) yapılır (PRD §11.4). Süre sıralı bir cevap: `DualStatementSlider` bir
/// kova üretir, "söylemek istemiyorum" durağı olamayan ayrı bir satır.
struct AgeRangeView: View {
    @State private var viewModel: SingleChoiceStepViewModel<AgeRange>

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(
            initialValue: SingleChoiceStepViewModel(
                selection: flow.draft.ageRange,
                commit: { flow.commitAgeRange($0) }
            )
        )
    }

    private var ordered: [AgeRange] { AgeRange.allCases.filter { $0 != .undisclosed } }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.ageHeadline,
            hint: Copy.Onboarding.identityStatsNote
        ) {
            VStack(spacing: 22) {
                DualStatementSlider(
                    options: ordered,
                    selection: viewModel.selection.flatMap { ordered.contains($0) ? $0 : nil },
                    onSelect: { viewModel.select($0) },
                    lowStatement: AgeRange.eighteenToTwentyFour.label,
                    highStatement: AgeRange.fiftyFivePlus.label,
                    accessibilityLabel: Copy.Onboarding.ageHeadline,
                    fillsTrack: false
                )
                ChoiceRow(
                    label: AgeRange.undisclosed.label,
                    isSelected: viewModel.isSelected(.undisclosed)
                ) {
                    viewModel.select(.undisclosed)
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
