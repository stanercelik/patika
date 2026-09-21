import SwiftUI

/// Taahhüt anı — C4'ten sonra, ölçümden önce (docs/onboarding-redesign.md, Bölüm 1).
///
/// Oyunlaştırmaya izin verildikten sonra akışın en güçlü, kullanılmamış dönüşüm
/// aracı ve sunucuda hiçbir değişiklik istemiyor. **Söz kullanıcının kendine, kendi
/// cümlesiyle**: hazır bir taahhüt listesi ya da kalabalık bir "yemin" yok. Kullanıcının
/// kendi sözü varsa (B4, yoksa B1) kartta serif yazılır; hiçbiri yoksa yalnızca cümle
/// ve kaydırıcı kalır, **uydurma bir cümle yansıtılmaz** (aynı kural G1'de de var).
///
/// Söz bir başarı vaadi değil: "düzeltmek zorunda değilsin, yalnızca ilk adımı at".
/// Yarıda bırakılan kaydırma hiçbir şey yapmaz. Cevap saklanmaz, çünkü karşılığı bir
/// ürün davranışı değil bir an; sunucuya yazmak "sorduğumuz her şeyin karşılığı olmalı"
/// kuralını yalan söyletirdi.
struct CommitmentView: View {
    let flow: OnboardingFlowViewModel

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
                OnboardingArtworkView(artwork: .commit, height: 160)
                    .statementReveal(1)

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

                BodyText(.commitmentBody)
                    .statementReveal(3)
            }
        } footer: {
            VStack(spacing: 0) {
                CommitmentSlide(
                    title: .commitmentSlide,
                    accessibilityTitle: .commitmentSlideAccessibility,
                    onCommit: { flow.finishCommitment() }
                )
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
