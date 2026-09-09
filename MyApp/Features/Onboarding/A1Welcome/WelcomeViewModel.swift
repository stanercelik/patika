import Foundation
import Observation

/// A1 — Ürünü hareket halinde göster (PRD-Ek Onboarding §2.1).
///
/// Ekran özellik listelemez, **sonucu** satar. Mağaza ekran görüntülerinin hiçbirini
/// tekrarlamaz; mağazada statik görseller varsa burada hareket vardır.
@Observable
@MainActor
final class WelcomeViewModel {
    let headline: LocalizedStringResource = Copy.Onboarding.welcomeHeadline
    let body: LocalizedStringResource = Copy.Onboarding.welcomeBody
    let ctaTitle: LocalizedStringResource = Copy.Onboarding.welcomeCTA

    private let flow: OnboardingFlowViewModel

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
    }

    func startTapped() {
        flow.finishWelcome()
    }
}
