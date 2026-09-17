import SwiftUI

/// A short entrance for the personal notebook. No invisible waiting controls,
/// recurring timers, or displacement in Reduce Motion / crisis mode.
private struct WoodlandReveal: ViewModifier {
    let index: Int
    let enabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(!enabled || appeared ? 1 : 0.65)
            .offset(y: !enabled || appeared || reduceMotion ? 0 : 6)
            .task {
                guard enabled, !appeared else { return }
                withAnimation(.smooth(duration: 0.36).delay(Double(min(index, 5)) * 0.045)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func woodlandReveal(_ index: Int, enabled: Bool = true) -> some View {
        modifier(WoodlandReveal(index: index, enabled: enabled))
    }
}
