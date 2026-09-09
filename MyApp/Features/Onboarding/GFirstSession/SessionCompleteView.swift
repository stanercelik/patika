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

            Spacer()

            PrimaryButton(title: Copy.Session.completedCTA) {
                flow.finishSessionSummary()
            }
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.screenMargin)
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
