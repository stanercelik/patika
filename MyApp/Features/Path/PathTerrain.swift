import SwiftUI

/// A small topographic landscape, drawn in the app's own ink. Geometry is
/// decorative: it never represents a score, distance, or promised outcome.
struct PathTerrain: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        JourneyMotionValueReader(forcePaused: reduceTransparency) { breath in
            Canvas { context, size in
                let ink = Theme.textPrimary.color
                for contour in 0..<18 {
                    let level = CGFloat(contour)
                    let inset = level * 6
                    var ridge = Path()
                    ridge.move(to: CGPoint(x: -40 + inset, y: size.height * 0.92))
                    ridge.addCurve(
                        to: CGPoint(x: size.width * 0.72, y: 24 + inset * 0.72),
                        control1: CGPoint(x: size.width * 0.08 + inset, y: -40 + inset),
                        control2: CGPoint(x: size.width * 0.48, y: size.height * 0.86 - inset)
                    )
                    ridge.addCurve(
                        to: CGPoint(x: size.width + 50, y: size.height * 0.64 + inset),
                        control1: CGPoint(x: size.width * 0.96, y: -20 + inset),
                        control2: CGPoint(x: size.width * 0.86, y: size.height * 0.58 + inset)
                    )
                    context.stroke(ridge, with: .color(ink.opacity(contrast == .increased ? 0.22 : 0.10)), lineWidth: Theme.Line.journeyConnector)
                }

                let route = Path { path in
                    path.move(to: CGPoint(x: size.width * 0.16, y: size.height + 8))
                    path.addCurve(
                        to: CGPoint(x: size.width * 0.67, y: size.height * 0.28),
                        control1: CGPoint(x: size.width * 0.16, y: size.height * 0.18),
                        control2: CGPoint(x: size.width * 0.80, y: size.height * 0.98)
                    )
                }
                context.stroke(route, with: .color(ink.opacity(0.055 + breath * 0.025)), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                context.stroke(route, with: .color(ink.opacity(0.85)), style: StrokeStyle(lineWidth: Theme.Line.trail, lineCap: .round))
                let center = CGPoint(x: size.width * 0.67, y: size.height * 0.28)
                let halo = 16 + breath * 3
                context.fill(Path(ellipseIn: CGRect(x: center.x - halo, y: center.y - halo, width: halo * 2, height: halo * 2)), with: .color(ink.opacity(0.08)))
                context.stroke(Path(ellipseIn: CGRect(x: center.x - 9, y: center.y - 9, width: 18, height: 18)), with: .color(ink.opacity(0.8)), lineWidth: Theme.Line.journeyConnector)
                context.fill(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)), with: .color(ink))
            }
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
