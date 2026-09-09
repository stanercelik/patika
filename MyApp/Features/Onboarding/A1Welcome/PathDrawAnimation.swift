import SwiftUI

/// A1 yol animasyonu — R1 brief'i (Görsel Sistem eki §8.4).
///
/// Rive yerine SwiftUI `Canvas` ile yazıldı: görsel ek §2.2'nin açıkça sunduğu
/// alternatif ("tasarımcınız yoksa bu yol daha hızlı", karar #12). Bağımlılık ve
/// varlık boyutu sıfır.
///
/// 4 sn döngü:
/// - 0.0–1.2  yol çizgisi alttan yukarı çizilir
/// - 1.2–2.4  yol üzerinde 5 nokta sırayla dolar (stagger 200 ms)
/// - 2.4–3.2  sağda iki dikey bar belirir
/// - 3.2–4.0  ikinci bar kısalır, ilki sabit — "fark" metaforu
///
/// Tek renk (#F2EFE9), derinlik opaklık varyasyonuyla verilir.
struct PathDrawAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Döngü, görünüm belirdiği anda baştan başlar. Duvar saatine bağlansaydı
    /// kullanıcı animasyonun ortasına düşerdi — "yol çiziliyor" anlatısı kaybolur.
    @State private var startedAt = Date()

    private let loop: TimeInterval = 4.0

    /// Yol üzerindeki düğüm noktaları (normalize).
    private let nodes: [CGPoint] = [
        CGPoint(x: 0.20, y: 0.90),
        CGPoint(x: 0.38, y: 0.71),
        CGPoint(x: 0.27, y: 0.50),
        CGPoint(x: 0.47, y: 0.29),
        CGPoint(x: 0.38, y: 0.09),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isStatic)) { timeline in
            // Reduce Motion / düşük güç: animasyon oynamaz, bitmiş kare gösterilir.
            let t = isStatic
                ? loop * 0.98
                : timeline.date.timeIntervalSince(startedAt).truncatingRemainder(dividingBy: loop)

            Canvas { context, size in
                draw(in: &context, size: size, t: t)
            }
        }
        .accessibilityHidden(true)  // dekoratif (Ton eki §7)
        .onAppear { startedAt = Date() }
    }

    private var isStatic: Bool {
        reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    // MARK: - Çizim

    private func draw(in context: inout GraphicsContext, size: CGSize, t: TimeInterval) {
        let ink = Theme.textPrimary.color
        // Döngü sonunda yumuşak kapanış.
        let fade = t > 3.8 ? 1.0 - (t - 3.8) / 0.2 : 1.0

        // 1) Yol çizgisi — 0.0 → 1.2 sn
        let drawProgress = eased(min(t / 1.2, 1.0))
        let trail = smoothPath(in: size)
        context.stroke(
            trail.trimmedPath(from: 0, to: drawProgress),
            with: .color(ink.opacity(0.55 * fade)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )

        // 2) Düğüm noktaları — 1.2 sn'den itibaren 200 ms arayla
        for (index, node) in nodes.enumerated() {
            let start = 1.2 + Double(index) * 0.2
            guard t >= start else { continue }
            let appear = eased(min((t - start) / 0.35, 1.0))
            let center = CGPoint(x: node.x * size.width, y: node.y * size.height)
            let radius = 5.0 * appear
            let rect = CGRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(ink.opacity((0.35 + 0.55 * appear) * fade))
            )
        }

        // 3–4) İki bar — 2.4 sn'de belirir, 3.2'den sonra ikincisi kısalır
        guard t >= 2.4 else { return }
        let barAppear = eased(min((t - 2.4) / 0.6, 1.0))
        let shrink = t >= 3.2 ? eased(min((t - 3.2) / 0.8, 1.0)) : 0.0

        let baseline = size.height * 0.90
        let fullHeight = size.height * 0.42 * barAppear
        let barWidth = size.width * 0.075

        drawBar(&context, x: size.width * 0.68, baseline: baseline,
                height: fullHeight, width: barWidth,
                color: ink.opacity(0.30 * fade))

        // İkinci bar kısalır — ölçülen fark.
        drawBar(&context, x: size.width * 0.82, baseline: baseline,
                height: fullHeight * (1.0 - 0.45 * shrink), width: barWidth,
                color: ink.opacity(0.75 * fade))
    }

    private func drawBar(
        _ context: inout GraphicsContext,
        x: CGFloat, baseline: CGFloat, height: CGFloat, width: CGFloat,
        color: Color
    ) {
        // Köşe yarıçapı sabit tutulur: `width / 2` kullanılsaydı bar kısayken
        // daireye dönüşüp "ölçüm barı" okumasını kaybederdi.
        let drawnHeight = max(height, 3)
        let rect = CGRect(x: x, y: baseline - drawnHeight, width: width, height: drawnHeight)
        context.fill(
            Path(roundedRect: rect, cornerRadius: 5),
            with: .color(color)
        )
    }

    /// Düğüm noktalarından yumuşak bir eğri kurar (orta noktalardan quad curve).
    private func smoothPath(in size: CGSize) -> Path {
        let points = nodes.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        guard points.count > 1 else { return path }

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(
                x: (previous.x + current.x) / 2,
                y: (previous.y + current.y) / 2
            )
            path.addQuadCurve(to: midpoint, control: previous)
        }
        path.addQuadCurve(to: points[points.count - 1], control: points[points.count - 1])
        return path
    }

    private func eased(_ x: Double) -> Double {
        -(cos(.pi * x) - 1) / 2
    }
}

#Preview {
    ZStack {
        BreathingMeshBackground(palette: .neutral)
        PathDrawAnimation()
            .frame(width: 220, height: 260)
    }
}
