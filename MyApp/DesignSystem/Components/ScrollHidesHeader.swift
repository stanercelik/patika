import SwiftUI

/// Yön duyarlı yüzen başlığın kaydırma algılayıcısı: aşağı kaydırınca saklanır,
/// yukarı kaydırınca geri gelir. "Yolum" ve Keşfet aynı davranışı kullanır.
///
/// Eşikler asimetrik: gizlemek için 28 pt aşağı, göstermek için 18 pt yukarı; en
/// üstteki 12 pt'de her zaman görünür. Yön değişince biriken yol sıfırlanır.
///
/// Reduce Motion'da başlık kayarak değil yalnızca solarak değişir (çağıran
/// `isHidden`e göre ofseti sıfırlar); animasyon 0,18 sn'lik yumuşak geçiştir.
extension View {
    func scrollHidesHeader(_ isHidden: Binding<Bool>) -> some View {
        modifier(ScrollHidesHeader(isHidden: isHidden))
    }
}

private struct ScrollHidesHeader: ViewModifier {
    @Binding var isHidden: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tracking = ScrollTravel()

    func body(content: Content) -> some View {
        content.onScrollGeometryChange(for: CGFloat.self) { geometry in
            let offset = geometry.contentOffset.y + geometry.contentInsets.top
            let maximum = max(0, geometry.contentSize.height - geometry.containerSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom)
            return min(maximum, max(0, offset))
        } action: { old, new in
            let delta = new - old
            if new < 12 {
                tracking.travel = 0
                setHidden(false)
            } else {
                if (delta > 0 && tracking.travel < 0) || (delta < 0 && tracking.travel > 0) {
                    tracking.travel = 0
                }
                tracking.travel += delta
                if tracking.travel > 28 { setHidden(true) }
                if tracking.travel < -18 { setHidden(false) }
            }
        }
    }

    private func setHidden(_ hidden: Bool) {
        guard isHidden != hidden else { return }
        withAnimation(reduceMotion ? .easeOut(duration: 0.18) : Theme.Motion.headerReveal) {
            isHidden = hidden
        }
    }
}

/// Hareket birikimi bilerek gözlemlenebilir değil: yalnızca görünürlük değişince
/// ekran yeniden çizilsin, her kaydırma pikselinde değil.
private final class ScrollTravel {
    var travel: CGFloat = 0
}
