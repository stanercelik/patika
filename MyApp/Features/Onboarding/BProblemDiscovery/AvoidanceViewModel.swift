import Foundation
import Observation

/// B4 — kaçınma davranışı (PRD-Ek Onboarding §3.4).
///
/// Bu cevap ölçüm sisteminin en sağlam metriğini besliyor (davranış katmanı, ağırlık
/// %40 — PRD §8.2) ve path'in ikinci yarısının omurgası. "Yok / emin değilim" gerçek
/// bir cevap: kaçınma davranışı olmayan kullanıcı var ve onu zorlamak veriyi bozar.
@Observable
@MainActor
final class AvoidanceViewModel {
    var text: String

    private let flow: OnboardingFlowViewModel

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
        self.text = flow.draft.avoidanceText ?? ""
    }

    var canContinue: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    func continueTapped() {
        guard canContinue else { return }
        flow.commitAvoidance(text)
    }

    func skipTapped() {
        flow.skipAvoidance()
    }
}
