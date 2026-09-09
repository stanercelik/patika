import SwiftUI

/// C4 — Dürüst beklenti (PRD-Ek Onboarding §4.4).
///
/// Aşırı vaat vermek yanlış beklenti kurar; baştan dürüst olmak hem güven inşa eder
/// hem iki somut iş yapar:
/// 1. 3. günde "işe yaramıyor" diye bırakacak kullanıcıya cevabı önceden verir.
/// 2. 7. gün paywall'ını sürpriz olmaktan çıkarıp beklenen bir kilometre taşına
///    çevirir.
///
/// CTA "Devam" değil "Anladım": bu ekranda ilerlemiyoruz, bir şeye onay veriyoruz.
struct HonestExpectationView: View {
    let flow: OnboardingFlowViewModel

    var body: some View {
        OnboardingStatementLayout(
            headline: Copy.Onboarding.honestExpectationHeadline(name: flow.draft.displayName),
            ctaTitle: Copy.Button.understood,
            action: { flow.finishHonestExpectation() }
        ) {
            StatementParagraph(Copy.Onboarding.honestExpectationEarlyDays)
                .sequentialReveal(1)
            StatementParagraph(Copy.Onboarding.honestExpectationTimeline)
                .sequentialReveal(2)

            // Raster görsel yerine sürecin kendisi çizilir: önce diğer
            // uygulamalar, ardından ilk günlerde sakin başlayıp 8. günden sonra
            // ivmelenen Patika. Grafik kendi görünürlük ve çizim sırasını yönetir.
            // Grafiğin üstünde ve altında cümlelerin arasından belirgin olarak
            // daha geniş bir boşluk var: grafik bir paragraf değil, ayrı bir
            // nesne — aynı ritimde dizilince metne yapışık okunuyordu.
            ExpectationCurveChart(startDelay: Theme.Motion.revealDelay(3))
                .padding(.vertical, 14)

            StatementParagraph(Copy.Onboarding.honestExpectationMeasurement)
                .sequentialReveal(6)
        }
    }
}

#Preview {
    OnboardingPreviewHost(step: .c4HonestExpectation) { flow in
        HonestExpectationView(flow: flow)
    }
}
