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
/// ## Tamamlanan oturumda yarını vaat etmez
///
/// Tam dinlenen oturumdan sonra taahhüt ve paywall gelir; ikinci adım henüz
/// ödenmemiş olabilir, bu yüzden "yarın buradayız" demez (2026-09-24,
/// docs/paywall-stratejisi.md). E1 saati paywall başlığında görünür.
struct SessionCompleteView: View {
    let flow: OnboardingFlowViewModel
    @State private var isSubmitting = false
    @State private var showsError = false
    @State private var answer = ""
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            let heightClass = OnboardingHeightClass.resolve(
                availableHeight: geometry.size.height,
                accessibility: dynamicTypeSize.isAccessibilitySize
            )
            ScrollView {
                VStack(alignment: .leading, spacing: heightClass == .comfortable ? 16 : 10) {
                    if heightClass != .scrollRequired {
                        PatikaIllustration(artwork: .rest)
                            .frame(height: heightClass == .comfortable ? 142 : 94)
                            .frame(maxWidth: .infinity)
                    }

                    SceneContentPlate {
                        VStack(alignment: .leading, spacing: 14) {
                            DisplayText(
                                flow.didCompleteFirstSession
                                    ? Copy.Session.completedHeadline
                                    : Copy.Session.leftEarlyHeadline,
                                size: 32
                            )

                            BodyText(
                                flow.didCompleteFirstSession
                                    ? Copy.Session.completedBody(remaining: flow.remainingSteps)
                                    : Copy.Session.leftEarlyBody(time: flow.reminderTimeText)
                            )

                            if let question = flow.firstStepQuestion {
                                AdaptiveQuestionView(
                                    answer: $answer,
                                    question: question,
                                    isSubmitting: isSubmitting,
                                    showsError: showsError,
                                    onSave: { submit(answer: $0, skipped: false) },
                                    onSkip: { submit(answer: nil, skipped: true) }
                                )
                            } else {
                                PrimaryButton(title: Copy.Session.completedCTA, isEnabled: !isSubmitting) {
                                    submit(answer: nil, skipped: true)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: heightClass == .scrollRequired ? nil : geometry.size.height, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
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
