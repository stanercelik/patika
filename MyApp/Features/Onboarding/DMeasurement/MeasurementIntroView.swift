import SwiftUI

/// D0 — Ölçüm giriş ekranı (PRD-Ek Onboarding §5).
///
/// Soruların **neden** sorulduğunu bilmeyen kullanıcı form dolduruyor gibi
/// hisseder ve terk eder. Bir cümlelik gerekçe tamamlanma oranını belirgin
/// şekilde artırıyor.
///
/// Ekranın işi aynı zamanda 7. günü baştan takvime yazmak: "aynılarını 7. günde
/// tekrar soracağız" cümlesi hem ölçümü anlamlı kılıyor hem C4'ün dürüst beklenti
/// sözünü somutlaştırıyor.
///
/// **Bu bölüm atlanamaz** (PRD-Ek Onboarding §10) — alt bölgede çıkış bağlantısı
/// yok. Baseline olmadan 7. günde karşılaştırılacak bir şey kalmıyor; ürünün
/// tamamı bu ölçüme dayanıyor.
struct MeasurementIntroView: View {
    let flow: OnboardingFlowViewModel

    var body: some View {
        OnboardingStatementLayout(
            headline: Copy.Onboarding.measurementIntroHeadline(flow.measurementItems.count),
            ctaTitle: Copy.Onboarding.measurementIntroCTA,
            action: { flow.startMeasurement() }
        ) {
            StatementParagraph(Copy.Onboarding.measurementIntroPurpose)
                .sequentialReveal(1)
            StatementParagraph(Copy.Onboarding.measurementIntroEffort)
                .sequentialReveal(2)

            Text(Copy.clinicalDisclaimer)
                .font(.caption.weight(Theme.Weight.body))
                .foregroundStyle(Theme.textPrimary.color.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
                .sequentialReveal(3)
                .padding(.top, 4)
        }
    }
}

#Preview {
    OnboardingPreviewHost(
        step: .d0MeasurementIntro,
        draft: {
            var draft = OnboardingDraft()
            draft.categories = [.sleep]
            draft.currentMood = .heavy
            return draft
        }()
    ) { flow in
        MeasurementIntroView(flow: flow)
    }
}
