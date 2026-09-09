import SwiftUI

/// Aktif paleti tutar ve kategori seçimine göre canlı geçiş yaptırır.
///
/// PRD-Ek Görsel Sistem §6.4: 55 kombinasyonun tamamı, renk dizisini `withAnimation`
/// içinde değiştirmekten ibarettir — interpolasyonu sistem yapar. A2 ekranındaki
/// "seçime göre renk değiştiren gradyan", akışın en gösterişli anı ve kritik yolun
/// (1 → 2 → 5) son adımı.
@Observable
@MainActor
final class PaletteController {
    private(set) var palette: Palette = .neutral
    /// B6'da seçilen kademe. Kategori paletini modüle eder, değiştirmez.
    private(set) var mood: MoodLevel?

    /// Palet geçişi sürüyor mu — arka plan bu sürede 60 fps'e çıkar.
    ///
    /// Nefes döngüsü 10 saniye olduğu için sabit durumda 30 fps ile 60 fps
    /// arasında görünür fark yok ve tam ekran Metal geçişi uygulamanın en büyük
    /// pil kalemi. Ama palet geçişi 1.2 saniyede dokuz rengi birden taşıyor;
    /// orada 30 fps büyük düz alanlarda zamansal basamak olarak görünüyor.
    /// Yüksek kare hızını yalnızca o pencereye harcıyoruz (ürün sahibi kararı,
    /// 2026-09-08).
    private(set) var isTransitioning = false

    /// Ruh hâli ve gece modu uygulanmış hâli — görünümler bunu kullanır.
    var current: Palette { palette.moodAdjusted(mood).nightAdjusted() }

    private var transitionTask: Task<Void, Never>?

    /// A2'de en fazla 2 kategori seçilebilir (PRD-Ek Onboarding §2).
    func select(_ categories: [ProblemCategory]) {
        let next: Palette
        switch categories.count {
        case 0:
            next = .neutral
        case 1:
            next = .forCategory(categories[0])
        default:
            next = .blend(.forCategory(categories[0]), .forCategory(categories[1]))
        }
        guard next != palette else { return }
        withAnimation(Theme.Motion.palette) {
            palette = next
        }
        beginTransition()
    }

    /// B6. Kademe değiştikçe arka plan canlı tepki verir.
    func setMood(_ mood: MoodLevel?) {
        guard mood != self.mood else { return }
        withAnimation(Theme.Motion.palette) {
            self.mood = mood
        }
        beginTransition()
    }

    private func beginTransition() {
        transitionTask?.cancel()
        isTransitioning = true
        transitionTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Theme.Motion.paletteTransition))
            guard !Task.isCancelled else { return }
            self?.isTransitioning = false
        }
    }
}
