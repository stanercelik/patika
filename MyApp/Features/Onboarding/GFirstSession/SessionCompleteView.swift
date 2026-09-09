import SwiftUI

/// G2 — Oturum sonu (PRD-Ek Onboarding §8).
///
/// ## Kutlama şiddeti 1/5
///
/// PRD bu ekran için en düşük kutlama kademesini veriyor ve gerekçesi ürünün
/// tamamıyla aynı: kullanıcı az önce üç dakika boyunca kendi hâlinde durdu.
/// Konfeti, rozet, "harika iş çıkardın" — üçü de o üç dakikanın tonunu bir
/// anda bozar ve ürünü ödül dağıtan bir şeye çevirir. Ekranda tek bir cümle,
/// tek bir bilgi ve tek bir buton var.
///
/// ## İki hâli var ve ikisi aynı şeyi söylemiyor
///
/// Oturum sonuna kadar dinlendiyse "İlk adım tamam." Yarıda bırakıldıysa
/// **"tamam" denmiyor** — ölçtüğünü iddia eden bir üründe olmayan bir şeyi
/// olmuş göstermek ilk yalan olurdu. Ama suçlama da yok, kalan adım sayısı da
/// yazılmıyor: bitirmemiş birine "20 adım daha var" demek kalan yolu borç gibi
/// okutuyor.
///
/// ## Yarının saati burada yazıyor
///
/// E1'de seçilen saat ilk kez burada görünür hâle geliyor. "Sorduğumuz her
/// şeyin karşılığı olmalı" kuralının son halkası: kullanıcı saati seçti, path
/// üretildi, oturum dinlendi ve şimdi o saatin ne işe yaradığını görüyor.
struct SessionCompleteView: View {
    let flow: OnboardingFlowViewModel
    @State private var answer = ""
    @State private var isSubmitting = false
    @State private var showsError = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.stack) {
            Spacer()

            DisplayText(
                flow.didCompleteFirstSession
                    ? Copy.Session.completedHeadline
                    : Copy.Session.leftEarlyHeadline,
                size: 32
            )

            BodyText(
                flow.didCompleteFirstSession
                    ? Copy.Session.completedBody(
                        remaining: flow.remainingSteps,
                        time: flow.reminderTimeText
                    )
                    : Copy.Session.leftEarlyBody(time: flow.reminderTimeText)
            )

            if let question = flow.firstStepQuestion {
                VStack(alignment: .leading, spacing: 12) {
                    Text(verbatim: question)
                        .font(.title3.weight(Theme.Weight.title))
                        .foregroundStyle(Theme.textPrimary.color)
                    Text(Copy.Session.reflectionHint)
                        .font(.footnote.weight(Theme.Weight.body))
                        .foregroundStyle(Theme.textSecondary.color)
                    OnboardingTextInput(
                        text: $answer,
                        placeholder: Copy.Session.reflectionPlaceholder,
                        lineRange: 3...6
                    )
                    if showsError {
                        Text(Copy.Session.reflectionError)
                            .font(.footnote.weight(Theme.Weight.body))
                            .foregroundStyle(Theme.textSecondary.color)
                    }
                }
            }

            Spacer()

            if flow.firstStepQuestion != nil {
                VStack(spacing: 10) {
                    PrimaryButton(title: Copy.Session.reflectionSave, isEnabled: canSave && !isSubmitting) {
                        submit(answer: answer, skipped: false)
                    }
                    Button(Copy.Session.reflectionSkip) {
                        submit(answer: nil, skipped: true)
                    }
                    .buttonStyle(.calm)
                    .foregroundStyle(Theme.textSecondary.color)
                    .frame(minHeight: 44)
                    .disabled(isSubmitting)
                }
                .padding(.bottom, 12)
            } else {
                PrimaryButton(title: Copy.Session.completedCTA, isEnabled: !isSubmitting) {
                    submit(answer: nil, skipped: true)
                }
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    private var canSave: Bool {
        answer.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    private func submit(answer: String?, skipped: Bool) {
        guard !isSubmitting else { return }
        isSubmitting = true
        showsError = false
        Task { @MainActor in
            let completed = await flow.completeFirstStep(answer: answer, skipped: skipped)
            isSubmitting = false
            guard completed else {
                if flow.step == .g2SessionComplete { showsError = true }
                return
            }
            flow.finishSessionSummary()
        }
    }
}

#Preview {
    OnboardingPreviewHost(
        step: .g2SessionComplete,
        draft: {
            var draft = OnboardingDraft()
            draft.name = "Taner"
            draft.categories = [.sleep]
            draft.currentMood = .heavy
            draft.reminderHour = 22
            draft.reminderMinute = 30
            return draft
        }()
    ) { flow in
        SessionCompleteView(flow: flow)
    }
}
