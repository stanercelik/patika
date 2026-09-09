import Foundation
import Observation

/// A2 — "Seni buraya ne getirdi?" (PRD-Ek Onboarding §2.2)
///
/// İlk ekranın soru olması bilinçlidir: kullanıcı ilk 5 saniyede ürünün kendisiyle
/// ilgilendiğini görmeli. Çoklu seçim de öyle — insanlar uygulamaya birden fazla
/// sorunla gelir ve tek hedef seçtirmek onları daraltır (karar #6).
@Observable
@MainActor
final class CategorySelectionViewModel {
    private(set) var selection: [ProblemCategory] = []

    let categories = ProblemCategory.allCases
    let maximum = OnboardingDraft.maximumCategories

    private let flow: OnboardingFlowViewModel

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
        self.selection = flow.draft.categories
    }

    // MARK: - Durum

    func isSelected(_ category: ProblemCategory) -> Bool {
        selection.contains(category)
    }

    /// Seçim dolu ve bu kart seçili değilse kart pasif görünür.
    func isDimmed(_ category: ProblemCategory) -> Bool {
        selection.count >= maximum && !isSelected(category)
    }

    /// A2 atlanamaz — path tipi buradan belirlenir.
    var canContinue: Bool { !selection.isEmpty }

    // MARK: - Etkileşim

    func toggle(_ category: ProblemCategory) {
        if let index = selection.firstIndex(of: category) {
            selection.remove(at: index)
        } else if selection.count < maximum {
            selection.append(category)
        } else {
            // Sessizce yok say. "En fazla 2 seçebilirsin" uyarısı çıkarmıyoruz —
            // kullanıcıyı hata yapmış gibi hissettirmez, kartların soluklaşması
            // sınırı zaten anlatıyor.
            return
        }
        // Arka plan seçime anında tepki verir: akışın en gösterişli anı.
        flow.previewCategories(selection)
    }

    func continueTapped() {
        guard canContinue else { return }
        flow.commitCategories(selection)
    }
}
