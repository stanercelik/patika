import SwiftUI

/// Mühür — rozetin Patika'daki hâli (profile-design §6.5).
///
/// ## Rozet, yolun kendi çizimidir
///
/// Madalyon, kupa, parıltı yok. Her path'in "Yolum"da gerçek bir rota ritmi var
/// (`JourneyRouteLayout`: faza göre kıvrım). Mühür o ritmin küçük, tek çizgili
/// hâli: deterministik ve kişiye özgü. Koleksiyon büyüdükçe kullanıcı bir harita
/// arşivi biriktirir.
///
/// ## Kova farkı çizimde görünmez
///
/// A, B ve C mührü aynıdır — emek tanınır, sonuç çizime işlenmez. Durumlar yalnızca
/// dokuyla ayrılır (tek mürekkep kuralı): tamamlanan düz çerçeve, aktif kesikli
/// çerçeve, yarım kalan açık uçlu çerçeve.
struct RouteSeal: View {
    enum Style: Equatable, Sendable {
        case completed
        case active
        case stopped
    }

    let stepCount: Int
    let walkedFraction: Double
    let style: Style
    let size: CGFloat
    let animatesDrawing: Bool
    /// Yüzeyin mürekkebi. Kâğıtta `.ink`; koyu zeminde varsayılan `.light`.
    let ink: PatikaInk

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawProgress: Double

    init(
        stepCount: Int,
        walkedFraction: Double,
        style: Style,
        size: CGFloat = 56,
        animatesDrawing: Bool = false,
        ink: PatikaInk = .light
    ) {
        self.stepCount = stepCount
        self.walkedFraction = walkedFraction
        self.style = style
        self.size = size
        self.animatesDrawing = animatesDrawing
        self.ink = ink
        _drawProgress = State(initialValue: animatesDrawing ? 0 : 1)
    }

    var body: some View {
        let points = RouteSealGeometry.normalizedPoints(stepCount: stepCount)
        let walked = min(max(walkedFraction, 0), 1) * drawProgress
        let lineWidth = max(1.5, size / 28)

        ZStack {
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .trim(from: style == .stopped ? 0.07 : 0, to: 1)
                .stroke(
                    ink.primary.opacity(style == .active ? 0.34 : 0.48),
                    style: StrokeStyle(
                        lineWidth: max(1, size / 56),
                        lineCap: .round,
                        dash: style == .active ? [3, 3.5] : []
                    )
                )

            ZStack {
                // Yürünmemiş kısmın soluk önizlemesi yalnızca aktif yolda var:
                // orada rota gerçekten devam ediyor. Yarım kalan yolda geri
                // kalanı göstermek "kaçırdığın şey" diye okunurdu — mühür
                // yalnızca yürüneni çizer, çerçeve açık uçlu kalır (F7).
                if style == .active {
                    RouteSealShape(points: points)
                        .stroke(
                            ink.primary.opacity(0.22),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                        )
                }
                RouteSealShape(points: points)
                    .trim(from: 0, to: walked)
                    .stroke(
                        ink.primary.opacity(0.94),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
                if walked > 0 {
                    RouteSealNode(points: points, fraction: walked, radius: lineWidth * 1.6)
                        .fill(ink.primary)
                }
            }
            .padding(size * 0.23)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .task {
            guard animatesDrawing, drawProgress < 1 else { return }
            if reduceMotion {
                drawProgress = 1
                return
            }
            withAnimation(.easeOut(duration: Theme.Motion.sealDraw)) {
                drawProgress = 1
            }
            // Tek yumuşak nabız, çizim bittiğinde (F6). Whimsy bütçesinin
            // içinde: bu zaten sayfadaki tek fark edilir an.
            try? await Task.sleep(for: .seconds(Theme.Motion.sealDraw))
            guard !Task.isCancelled else { return }
            Theme.softHaptic(intensity: 0.4)
        }
    }
}

/// Mühür rotasının noktaları — "Yolum"daki faz ritminden örneklenir.
enum RouteSealGeometry {
    static func normalizedPoints(stepCount: Int) -> [CGPoint] {
        let count = max(stepCount, 2)
        // 21 adımı 56 pt'ye sığdırmak okunmaz bir zikzak üretirdi; rota birkaç
        // adımda bir örneklenir ve ritim korunur.
        let samples = min(max(count / 3 + 1, 4), 8)
        let length = PathLength(rawValue: count)
        let phases: [PathPhase?] = (0..<samples).map { index in
            let day = 1 + Int((Double(index) / Double(samples - 1) * Double(count - 1)).rounded())
            guard let length else { return nil }
            return PathPlan.phase(on: day, length: length)
        }
        let positions = JourneyRouteLayout.positions(for: phases, usesAccessibleLayout: false)
        return positions.enumerated().map { index, position in
            CGPoint(x: position.currentX, y: Double(index) / Double(samples - 1))
        }
    }
}

/// Noktalardan geçen yumuşak rota.
struct RouteSealShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        let resolved = points.map {
            CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height)
        }
        var path = Path()
        guard let first = resolved.first else { return path }
        path.move(to: first)
        guard resolved.count > 2 else {
            resolved.dropFirst().forEach { path.addLine(to: $0) }
            return path
        }
        path.addLine(to: midpoint(resolved[0], resolved[1]))
        for index in 1..<(resolved.count - 1) {
            path.addQuadCurve(
                to: midpoint(resolved[index], resolved[index + 1]),
                control: resolved[index]
            )
        }
        path.addLine(to: resolved[resolved.count - 1])
        return path
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }
}

/// Rotanın yürünen ucundaki düğüm. Çizim animasyonuyla birlikte ilerler.
struct RouteSealNode: Shape {
    let points: [CGPoint]
    var fraction: Double
    let radius: CGFloat

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let route = RouteSealShape(points: points).path(in: rect)
        let end = route.trimmedPath(from: 0, to: min(max(fraction, 0.0001), 1)).currentPoint
            ?? rect.origin
        return Path(ellipseIn: CGRect(
            x: end.x - radius,
            y: end.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
    }
}
