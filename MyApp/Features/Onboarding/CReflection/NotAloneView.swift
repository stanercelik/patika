import SwiftUI

/// C2 — Yalnız değilsin (PRD-Ek Onboarding §4.2).
///
/// **Bu ekranda sayı yok ve lansmanda da olmayacak.** Sıfır kullanıcıyla
/// "10.000 kişi bunu kullanıyor" yazmak hem etik dışı hem bu kategoride yakalanınca
/// ölümcül. Yerine kategori düzeyinde niteliksel, doğrulanabilir bir cümle var
/// (`ProblemCategory.commonalityLine`).
///
/// Gerçek kullanıcı verisi oluştuğunda ekran değişir — metin şimdiden yazılmaz.
struct NotAloneView: View {
    let flow: OnboardingFlowViewModel

    var body: some View {
        OnboardingStatementLayout(
            headline: Copy.Onboarding.notAloneHeadline,
            action: { flow.finishNotAlone() }
        ) {
            StatementParagraph(flow.draft.primaryCategory.commonalityLine)
                .statementReveal(1)

            // Birbirine karışan yapraklar ve ortak akış; sayı veya insan
            // figürü üzerinden sosyal kanıt ima etmez.
            OnboardingIllustration(
                name: PatikaArtwork.belonging.rawValue,
                height: 292,
                accessibilityHeight: 194
            )
            .statementReveal(2)

            StatementParagraph(Copy.Onboarding.notAloneResearchLine)
                .statementReveal(3)
        }
    }
}

#Preview {
    OnboardingPreviewHost(
        step: .c2NotAlone,
        draft: {
            var draft = OnboardingDraft()
            draft.categories = [.sleep]
            return draft
        }()
    ) { flow in
        NotAloneView(flow: flow)
    }
}
