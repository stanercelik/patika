import SwiftUI

/// Taahhüt anı — hazır path kullanıcıya gösterildikten sonra, G1'den önce.
///
/// Oyunlaştırmaya izin verildikten sonra akışın en güçlü, kullanılmamış dönüşüm
/// aracı ve sunucuda hiçbir değişiklik istemiyor. **Söz kullanıcının kendine, kendi
/// cümlesiyle**: hazır bir taahhüt listesi ya da kalabalık bir "yemin" yok. Kullanıcının
/// kendi sözü varsa (B4, yoksa B1) kartta serif yazılır; hiçbiri yoksa yalnızca cümle
/// ve imza alanı kalır, **uydurma bir cümle yansıtılmaz** (aynı kural G1'de de var).
///
/// Söz bir başarı vaadi değil: "düzeltmek zorunda değilsin, yalnızca ilk adımı at".
/// İmza ham koordinatları sunucuya veya analitiğe gitmez; yalnızca cihazdaki korumalı
/// dosyaya yazılır. Basılı tutma tamamlanınca G1'e geçmeden önce kısa ve okunur
/// bir eşik cümlesi gösterilir.
struct CommitmentView: View {
    let flow: OnboardingFlowViewModel
    @State private var signature = NormalizedSignature(strokes: [])
    @State private var showsSaveError = false
    @State private var showsTransitionMessage = false

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

                BodyText(.commitmentBody)
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
                if !signature.isEmpty {
                    HoldToStartButton(title: Copy.Onboarding.commitmentHoldToStart) {
                        guard flow.services.promiseSignature.save(signature) else {
                            showsSaveError = true
                            return
                        }
                        withAnimation(Theme.Motion.crossFade) {
                            showsTransitionMessage = true
                        }
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(1.2))
                            flow.startFirstSession()
                        }
                    }
                    .transition(.opacity)
                }
                // Alt bölgenin yeri diğer soru ekranlarıyla aynı: birincil satır zıplamasın.
                Color.clear.frame(height: 44)
            }
        }
        .animation(Theme.Motion.crossFade, value: signature.isEmpty)
        .animation(Theme.Motion.crossFade, value: showsTransitionMessage)
        .overlay {
            if showsTransitionMessage {
                ZStack {
                    WoodlandStyle.scenePlate.color.ignoresSafeArea()
                    Text(Copy.Onboarding.commitmentDayOneTransition)
                        .font(Theme.TypeFace.sectionTitle)
                        .foregroundStyle(Theme.textPrimary.color)
                        .multilineTextAlignment(.center)
                        .padding(Theme.Spacing.screenMargin)
                }
                .transition(.opacity)
                .accessibilityElement(children: .combine)
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
