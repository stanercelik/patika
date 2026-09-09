import SwiftUI

/// C3 — Neden kütüphane değil, yol (PRD-Ek Onboarding §4.3).
///
/// **Koşullu ekran:** yalnızca B5'te "başka meditasyon uygulamaları" seçen
/// kullanıcı görür. Denememiş kullanıcı için karşılaştırma anlamsız ve akışı boşuna
/// uzatır; denemiş kullanıcı için ise en ikna edici ekran, çünkü tarif edilen
/// başarısızlık onun kendi hikâyesi.
///
/// Koşulun kendisi burada değil `OnboardingDraft.showsLibraryComparison`da —
/// bir görünümün akışın şeklini bilmesi gerekmiyor.
struct PathNotLibraryView: View {
    let flow: OnboardingFlowViewModel

    var body: some View {
        OnboardingStatementLayout(
            headline: Copy.Onboarding.libraryComparisonHeadline,
            action: { flow.finishLibraryComparison() }
        ) {
            // Grafik yok (ürün sahibi kararı, 2026-09-08). Karşılaştırma iki
            // sütuna alındı: eğri, iki yaklaşımın farkını anlatırken istemeden
            // bir sonuç eğrisi gibi okunuyordu ve altındaki "bu bir vaat değil"
            // notu ekranın en uzun cümlesiydi. Sütunlar aynı farkı tek bakışta,
            // hiçbir sayı ima etmeden gösteriyor.
            ComparisonColumns(
                theirsTitle: Copy.Onboarding.libraryComparisonTheirsTitle,
                oursTitle: Copy.Onboarding.libraryComparisonOursTitle,
                theirs: Copy.Onboarding.libraryComparisonTheirs,
                ours: Copy.Onboarding.libraryComparisonOurs,
                revealStartIndex: 1
            )
            .padding(.top, 4)

            StatementParagraph(Copy.Onboarding.libraryComparisonClosing)
                .sequentialReveal(1 + Copy.Onboarding.libraryComparisonTheirs.count + 1)
                .padding(.top, 6)
        }
    }
}

#Preview {
    OnboardingPreviewHost(
        step: .c3PathNotLibrary,
        draft: {
            var draft = OnboardingDraft()
            draft.categories = [.anxiety]
            draft.previousAttempts = [.otherApps]
            return draft
        }()
    ) { flow in
        PathNotLibraryView(flow: flow)
    }
}
