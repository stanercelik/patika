import SwiftUI

/// Taahhüt anı — ilk adım tam dinlendikten sonra, G2 ile paywall arasında
/// (2026-09-24, docs/paywall-stratejisi.md). Söz "başlıyorum" değil "devam ediyorum":
/// hemen ardından gelen teklif, kullanıcının az önce verdiği kararın devamı gibi okunur.
/// İşaret isteğe bağlı; basılı tutma tek başına yeter, sürtünme paywall'ın önünde durmasın.
///
/// Oyunlaştırmaya izin verildikten sonra akışın en güçlü, kullanılmamış dönüşüm
/// aracı ve sunucuda hiçbir değişiklik istemiyor. **Söz kullanıcının kendine, kendi
/// cümlesiyle**: hazır bir taahhüt listesi ya da kalabalık bir "yemin" yok. Kullanıcının
/// kendi sözü varsa (B4, yoksa B1) kartta serif yazılır; hiçbiri yoksa yalnızca cümle
/// ve imza alanı kalır, **uydurma bir cümle yansıtılmaz** (aynı kural G1'de de var).
///
/// Söz bir başarı vaadi değil: "kalan adımlar senin, kendi hızında".
/// İmza ham koordinatları sunucuya veya analitiğe gitmez; yalnızca cihazdaki korumalı
/// dosyaya yazılır. Basılı tutma tamamlanınca paywall'dan önce kısa ve okunur
/// bir eşik cümlesi gösterilir.
struct CommitmentView: View {
    let flow: OnboardingFlowViewModel
    @State private var signature = NormalizedSignature(strokes: [])
    @State private var showsSaveError = false

    private var quote: (lead: LocalizedStringResource, text: String)? {
        if let avoidance = flow.draft.avoidanceText, !avoidance.isEmpty {
            return (.commitmentLeadAvoidance, avoidance)
        }
        if flow.draft.hasOwnWords {
            return (.commitmentLeadProblem, flow.draft.problemText)
        }
        return nil
    }

    var body: some View {
        OnboardingQuestionLayout(headline: .commitmentHeadline) {
            VStack(alignment: .leading, spacing: 18) {
                if let quote {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(quote.lead)
                            .font(.footnote.weight(Theme.Weight.emphasis))
                            .inkStyle(.secondary)
                        Text(verbatim: "\u{201C}\(quote.text)\u{201D}")
                            .font(Theme.Voice.user(.title3))
                            .inkStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .statementReveal(2)
                }

                BodyText(Copy.Onboarding.commitmentBody(remaining: flow.remainingSteps))
                    .statementReveal(3)

                Text(Copy.Onboarding.signatureDrawHint)
                    .font(.footnote.weight(Theme.Weight.body))
                    .inkStyle(.secondary)

                SignatureCanvas(signature: $signature)

                if showsSaveError {
                    Text(Copy.Onboarding.signatureSaveError)
                        .font(.footnote.weight(Theme.Weight.body))
                        .inkStyle(.secondary)
                }

            }
        } footer: {
            VStack(spacing: 0) {
                HoldToStartButton(title: Copy.Onboarding.commitmentHoldToContinue) {
                    if !signature.isEmpty, !flow.services.promiseSignature.save(signature) {
                        showsSaveError = true
                        return
                    }
                    flow.beginContinueTransition()
                }
                // Alt bölgenin yeri diğer soru ekranlarıyla aynı: birincil satır zıplamasın.
                Color.clear.frame(height: 44)
            }
        }

    }
}

#Preview {
    OnboardingPreviewHost(
        step: .commitment,
        draft: {
            var draft = OnboardingDraft()
            draft.categories = [.sleep]
            draft.avoidanceText = "I keep putting off meeting friends in the evening"
            return draft
        }()
    ) { flow in
        CommitmentView(flow: flow)
    }
}
