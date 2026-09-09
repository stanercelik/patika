import Foundation
import Observation

/// B1 — akışın en değerli ekranı (PRD-Ek Onboarding §3.1).
///
/// Buradaki metin F2'de kullanıcıya geri yansıtılacak ve G1'de **kendi
/// kelimeleriyle seslendirilecek**; aha momentinin yakıtı bu. Bu yüzden "atla"
/// görünür ama ikincil tutuluyor.
///
/// Kriz taraması bu ekranın çıkışında, `OnboardingFlowViewModel.commitProblemText`
/// içinde yapılır — ekran VM'i güvenlik kararı vermez, akış verir.
@Observable
@MainActor
final class ProblemTextViewModel {
    var text: String

    private let flow: OnboardingFlowViewModel

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
        self.text = flow.draft.problemText
    }

    /// Placeholder A2'de seçilen kategoriye göre değişir — küçük ama doldurma
    /// oranını ciddi artıran detay (PRD-Ek Onboarding §3.1).
    var placeholder: LocalizedStringResource {
        flow.draft.primaryCategory.textPlaceholder
    }

    /// Tek kelime yazıp geçmek path üretimine hiçbir şey katmıyor; boş metinle
    /// aynı. Ama sınırı sayaçla göstermiyoruz — yazmayı ödeve çevirir. Buton
    /// pasif kalır ve altındaki "yazmak istemiyorum" zaten açık bir çıkış.
    var canContinue: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    func continueTapped() {
        guard canContinue else { return }
        flow.commitProblemText(text)
    }

    func skipTapped() {
        flow.skipProblemText()
    }
}
