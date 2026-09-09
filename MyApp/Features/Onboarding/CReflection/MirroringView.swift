import SwiftUI

/// C1 — Aynalama (PRD-Ek Onboarding §4.1).
///
/// Akışın en yüksek güven üreten anı ve hiçbir şey satmayan tek ekranı: kullanıcının
/// cevapları kendi kelimeleriyle geri veriliyor. "Bu form doldurtmuyor, beni okuyor"
/// hissi buradan çıkıyor.
///
/// İlerleme izi bu ekranda **solar** — B6'da dolmuştu, C'de soru sorulmuyor.
struct MirroringView: View {
    let flow: OnboardingFlowViewModel

    var body: some View {
        OnboardingStatementLayout(
            headline: Copy.Onboarding.mirroringHeadline(name: flow.draft.displayName),
            action: { flow.finishMirroring() }
        ) {
            let paragraphs = MirroringComposer.paragraphs(for: flow.draft)
            let insertionIndex = MirroringComposer.illustrationInsertionIndex(for: flow.draft)

            ForEach(Array(paragraphs.prefix(insertionIndex).enumerated()), id: \.offset) { index, paragraph in
                StatementParagraph(paragraph)
                    .sequentialReveal(1 + index)
            }

            // Durum ve süre birlikte okunduktan sonra: görsel bu iki parçayı
            // tek bir kişisel yol hissinde birleştirir; kalan cümleler ardından gelir.
            OnboardingIllustration(
                name: "illustration-c1-mirror",
                height: 282,
                accessibilityHeight: 194
            )
            .sequentialReveal(1 + insertionIndex)

            ForEach(Array(paragraphs.dropFirst(insertionIndex).enumerated()), id: \.offset) { index, paragraph in
                StatementParagraph(paragraph)
                    .sequentialReveal(2 + insertionIndex + index)
            }
        }
    }
}

#Preview("Tam veri") {
    OnboardingPreviewHost(
        step: .c1Mirroring,
        draft: {
            var draft = OnboardingDraft()
            draft.categories = [.sleep]
            draft.duration = .months
            draft.timing = .bedtime
            draft.avoidanceText = "yatma saatimi sürekli erteliyorum"
            draft.currentMood = .heavy
            return draft
        }()
    ) { flow in
        MirroringView(flow: flow)
    }
}

/// B1–B4 atlandığında ekran uydurmaya başlamamalı: geriye yalnızca kategori
/// cümlesi ve kapanış kalır.
#Preview("Eksik veri") {
    OnboardingPreviewHost(
        step: .c1Mirroring,
        draft: {
            var draft = OnboardingDraft()
            draft.categories = [.unnamed]
            draft.duration = .unsure
            return draft
        }()
    ) { flow in
        MirroringView(flow: flow)
    }
}
