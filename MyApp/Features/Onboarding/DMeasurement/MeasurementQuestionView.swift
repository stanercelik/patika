import SwiftUI

/// D1–D8 — baseline ölçüm soruları (PRD-Ek Onboarding §5, PRD §8).
///
/// **Sekiz soru, sekiz ekran.** Tek ekrana yığmak "iş" gibi görünüyor; teker
/// teker göstermek hızlı hissettiriyor. Sorunun kendisi kategoriye ve ölçüm
/// noktasına göre `MeasurementLibrary`den geliyor; bu görünüm hangi sorunun
/// sorulduğunu bilmiyor, yalnızca cevabın biçimini çiziyor.
///
/// **Hiçbir skor gösterilmez** (PRD §7.3). Bu ekranlarda ne bir toplam, ne bir
/// yorum, ne de "iyi/kötü" işareti var — cevaplar 7. güne kadar sessizce
/// bekliyor. Skorlar ilk kez orada, kullanıcının kendi başlangıcıyla
/// karşılaştırmalı olarak görünür.
///
/// Her ekranın altında klinik feragat sabittir (PRD §8.1).
struct MeasurementQuestionView: View {
    @State private var viewModel: MeasurementQuestionViewModel

    init(flow: OnboardingFlowViewModel, index: Int) {
        let item = flow.measurementItem(at: index)
        self._viewModel = State(
            initialValue: MeasurementQuestionViewModel(
                item: item,
                variant: flow.measurementVariant,
                value: flow.draft.measurementResponses[item.id],
                commit: { flow.commitMeasurementAnswer($0, at: index) }
            )
        )
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: viewModel.prompt,
            hint: viewModel.hint
        ) {
            VStack(alignment: .leading, spacing: 20) {
                answerArea

                Text(Copy.clinicalDisclaimer)
                    .font(.caption.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } footer: {
            // Bu bölüm atlanamaz: ikincil satır boş kalıyor ama yeri yine de
            // ayrılıyor, yoksa birincil buton D0'dan D1'e geçerken kayıyordu.
            OnboardingQuestionFooter(
                primaryTitle: Copy.Button.next,
                primaryDisabledTitle: viewModel.usesIntensityScale
                    ? Copy.Onboarding.pickPointCTA
                    : Copy.Onboarding.chooseOneCTA,
                isPrimaryEnabled: viewModel.canContinue,
                primaryAction: { viewModel.submit() }
            )
        }
    }

    @ViewBuilder
    private var answerArea: some View {
        if viewModel.usesIntensityScale {
            IntensityScale(selection: viewModel.value) { viewModel.select($0) }
                .padding(.top, 4)
        } else {
            VStack(spacing: 10) {
                ForEach(viewModel.options) { option in
                    ChoiceRow(
                        label: option.label,
                        isSelected: viewModel.isSelected(option)
                    ) {
                        viewModel.select(option.value)
                    }
                }
            }
        }
    }
}

#Preview("D1 — şiddet") {
    OnboardingPreviewHost(
        step: .dMeasurement(1),
        draft: {
            var draft = OnboardingDraft()
            draft.categories = [.sleep]
            return draft
        }()
    ) { flow in
        MeasurementQuestionView(flow: flow, index: 1)
    }
}

#Preview("D5 — path'e özel davranış") {
    OnboardingPreviewHost(
        step: .dMeasurement(5),
        draft: {
            var draft = OnboardingDraft()
            draft.categories = [.social]
            return draft
        }()
    ) { flow in
        MeasurementQuestionView(flow: flow, index: 5)
    }
}
