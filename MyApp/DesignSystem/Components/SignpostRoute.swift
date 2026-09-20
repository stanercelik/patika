import SwiftUI

/// Tabela rotasının ortak çizimi — "Yolum" (`IllustratedPathMap`) ve Keşfet
/// (`DiscoverTrailMap`) aynı yolu çizer.
///
/// Rota **gerçek düğüm merkezleri** arasında çizilir: her durak kendi düğümünün
/// ölçüsünü `signpostNode(id:)` ile yayımlar, kapsayıcı `signpostRoute(ids:)` ile
/// bunları sırayla birleştirir. Böylece satır yüksekliği (açık ya da kompakt
/// tabela) ne olursa olsun yol düğümlerden geçer.
///
/// Neden ortak: iki ayrı rota çizimi zamanla ayrışırdı — aynı yol iki sekmede
/// farklı kalınlık ve eğriyle görünürdü.
struct SignpostAnchors: PreferenceKey {
    static var defaultValue: [AnyHashable: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [AnyHashable: Anchor<CGRect>], nextValue: () -> [AnyHashable: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    /// Bu görünümün sınırlarını rotanın düğüm noktası olarak yayımlar.
    func signpostNode(id: some Hashable) -> some View {
        anchorPreference(key: SignpostAnchors.self, value: .bounds) { [AnyHashable(id): $0] }
    }

    /// Yayımlanan düğümleri `ids` sırasıyla birleştiren rotayı arkaya çizer.
    /// Dekor: dokunulmaz, VoiceOver'dan gizli.
    func signpostRoute<ID: Hashable>(ids: [ID]) -> some View {
        backgroundPreferenceValue(SignpostAnchors.self) { anchors in
            GeometryReader { geometry in
                let points = ids.compactMap { id -> CGPoint? in
                    guard let anchor = anchors[AnyHashable(id)] else { return nil }
                    let rect = geometry[anchor]
                    return CGPoint(x: rect.midX, y: rect.midY)
                }
                SignpostRouteStroke(points: points)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Üç katman: 20 pt koyu gölge, 11 pt krem yol, 2 pt vurgu.
struct SignpostRouteStroke: View {
    let points: [CGPoint]

    var body: some View {
        let route = signpostContinuousRoute(points)
        ZStack {
            route.stroke(WoodlandStyle.ink.opacity(0.22), style: StrokeStyle(lineWidth: 20, lineCap: .round))
            route.stroke(WoodlandStyle.paper.opacity(0.78), style: StrokeStyle(lineWidth: 11, lineCap: .round))
            route.stroke(WoodlandStyle.paper.opacity(0.35), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}

/// Düğüm merkezleri arasında aralık başına tek bir kübik; satır sınırında köşe
/// oluşmuyor.
func signpostContinuousRoute(_ points: [CGPoint]) -> Path {
    Path { path in
        guard let first = points.first else { return }
        path.move(to: first)
        for (start, end) in zip(points, points.dropFirst()) {
            let middleY = (start.y + end.y) / 2
            path.addCurve(to: end,
                          control1: CGPoint(x: start.x, y: middleY),
                          control2: CGPoint(x: end.x, y: middleY))
        }
    }
}

/// Tabela düğümü ve etiketi için basma tepkisi. Kapalı duraklar başlığını okunur
/// tutar; açılmadığını kilit ve metin anlatır.
struct SignpostStopButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.smooth(duration: 0.24), value: configuration.isPressed)
    }
}
