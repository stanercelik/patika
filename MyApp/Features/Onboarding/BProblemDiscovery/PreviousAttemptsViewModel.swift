import Foundation
import Observation

/// B5 — "Daha önce ne denedin?" (PRD-Ek Onboarding §3.5)
///
/// Bu ekran akışı bitirmeyen kullanıcıdan bile bedava pazar araştırması getiriyor.
/// Bizde iki ek işlevi var: C3 koşullu ekranının anahtarı ve terapi tonunun
/// tetikleyicisi. İkisi de `PreviousAttempt` üzerindeki bayraklardan okunur,
/// burada `if` ile hesaplanmaz.
@Observable
@MainActor
final class PreviousAttemptsViewModel {
    private(set) var selection: [PreviousAttempt] = []

    let options = PreviousAttempt.allCases

    private let flow: OnboardingFlowViewModel

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
        self.selection = flow.draft.previousAttempts
    }

    func isSelected(_ option: PreviousAttempt) -> Bool {
        selection.contains(option)
    }

    var canContinue: Bool { !selection.isEmpty }

    /// Terapi devam ediyorsa sınır cümlesi görünür.
    var showsTherapyNote: Bool {
        selection.contains(where: \.requiresTherapyAwareTone)
    }

    /// "Hiçbir şey" ile başka bir şey aynı anda seçilemez — mantıksal çelişki.
    /// Uyarı göstermek yerine sessizce diğerlerini bırakıyoruz: kullanıcı hata
    /// yapmış gibi hissetmez, seçimin sonucu ekranda görünür zaten.
    func toggle(_ option: PreviousAttempt) {
        if let index = selection.firstIndex(of: option) {
            selection.remove(at: index)
            return
        }

        if option.isExclusive {
            selection = [option]
        } else {
            selection.removeAll(where: \.isExclusive)
            selection.append(option)
        }
    }

    func continueTapped() {
        guard canContinue else { return }
        flow.commitPreviousAttempts(selection)
    }

    /// Atlarsa boş liste gider: C3 gösterilmez, terapi tonu tetiklenmez.
    func skipTapped() {
        flow.commitPreviousAttempts([])
    }
}
