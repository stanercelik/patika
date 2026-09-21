import SwiftUI

/// F4 — fiyat şeffaflığı (PRD-Ek Onboarding §7; docs/onboarding-redesign.md, Bölüm 1).
///
/// PRD bu ekranı tasarladı, F2 doğrudan G1'i başlatınca onu yetim bıraktı; kendi
/// tercih ettiği yeni yer G2'den sonra, H1'den önce. Kullanıcı ilk meditasyonunu
/// dinledi ve neyin, ne zaman, kaça olduğunu **ödeme istenmeden** öğreniyor.
///
/// ## Sert paywall değil, ve bilerek
///
/// - Bugün hiçbir şey alınmıyor, ekranın ilk cümlesi bu. Ödeme kararı 7. günde, ölçüm
///   ekranından **sonra** gelir; paywall yok (RevenueCat ile sonradan gelecek), ve ilerleme yoksa devam ücretsiz
///   (Kova C taahhüdü, PRD 7.9) sözünü önden para alarak vermek anlamsız olurdu.
/// - Geri sayım, indirim, "kaçırma", sahte aciliyet **yok**; önceden seçili bir seçenek
///   de yok: varsayılan yanlılığı ödeme kararlarında kullanılmaz.
/// - Sosyal kanıt ve kullanıcı sayısı yok: veri yokken sayı yazılmaz.
/// - Seçenekler seçilemez; bir liste, bir buton değil.
///
/// > **Fiyatlar PRD §12.1'den, katalogda sabit metin.** Paywall RevenueCat ile yapılacak
/// > (ürün sahibi kararı, 2026-09-22): yayından önce RevenueCat offering'inden okunmalı (bölgeye göre para birimi) ve birincil pazar kararı
/// > (PRD §18, açık soru 2) verilmeli: €12.99 Türkiye için yüksek.
struct PriceView: View {
    let flow: OnboardingFlowViewModel

    var body: some View {
        OnboardingQuestionLayout(headline: .priceHeadline) {
            VStack(alignment: .leading, spacing: 16) {
                statement(.priceFree).statementReveal(1)
                statement(.priceDecision).statementReveal(2)

                PaperRowDivider().padding(.vertical, 2)

                Text(.priceOptionsHeader)
                    .font(.headline.weight(Theme.Weight.title))
                    .inkStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
                    .statementReveal(3)

                VStack(spacing: 0) {
                    optionRow(name: .priceOptionSingle, price: .priceOptionSinglePrice)
                    PaperRowDivider()
                    optionRow(name: .priceOptionMonthly, price: .priceOptionMonthlyPrice)
                    PaperRowDivider()
                    optionRow(name: .priceOptionYearly, price: .priceOptionYearlyPrice)
                }
                .statementReveal(4)

                statement(.pricePromise).statementReveal(5)
            }
        } footer: {
            OnboardingQuestionFooter(
                primaryTitle: Copy.Button.next,
                primaryAction: { flow.finishPrice() }
            )
        }
    }

    private func statement(_ text: LocalizedStringResource) -> some View {
        Text(text)
            .font(.body.weight(Theme.Weight.body))
            .inkStyle(.primary)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func optionRow(name: LocalizedStringResource, price: LocalizedStringResource) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(name).font(.body.weight(Theme.Weight.emphasis)).inkStyle(.primary)
                Spacer(minLength: 8)
                Text(price).font(.body.weight(Theme.Weight.action)).inkStyle(.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.body.weight(Theme.Weight.emphasis)).inkStyle(.primary)
                Text(price).font(.body.weight(Theme.Weight.action)).inkStyle(.primary)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingPreviewHost(step: .price) { flow in
        PriceView(flow: flow)
    }
}
