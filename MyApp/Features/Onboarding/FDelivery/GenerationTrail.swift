import SwiftUI

/// A moving highlight shows activity without inventing a completion percentage.
struct GenerationTrail: View {
    var isPaused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: isPaused || reduceMotion || scenePhase != .active)) { context in
            let phase = reduceMotion || isPaused ? 0.45
                : context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 4) / 4
            ZStack {
                TrailCurve()
                    .stroke(Theme.textPrimary.color.opacity(0.22), style: StrokeStyle(lineWidth: Theme.Line.border, lineCap: .round, dash: [3, 7]))
                TrailCurve()
                    .trim(from: max(0, phase - 0.22), to: phase)
                    .stroke(Theme.textPrimary.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                Image(systemName: "leaf")
                    .font(.title2.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color)
                    .offset(x: 0, y: -25)
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

private struct TrailCurve: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + 12, y: rect.maxY - 12))
            path.addCurve(
                to: CGPoint(x: rect.maxX - 12, y: rect.minY + 12),
                control1: CGPoint(x: rect.width * 0.8, y: rect.maxY + 8),
                control2: CGPoint(x: rect.width * 0.2, y: rect.minY - 8)
            )
        }
    }
}
