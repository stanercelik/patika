import SwiftUI

/// C4'ün süreç grafiği: diğer uygulamaların kısa süreli dalgalanması ile
/// Patika'nın küçük adımları biriktiren yapısını karşılaştırır.
///
/// Dikey eksen ve sayısal sonuç yoktur. Çizgiler gerçek kullanıcı verisi değil,
/// ürün yaklaşımının ritmidir.
///
/// **Kompakt** (ürün sahibi kararı, 2026-09-08). Grafik önce ekranın yarısını
/// kaplıyor ve çevresinde dört ayrı metin katmanı taşıyordu — gösterge satırı, iki
/// uçtaki zaman etiketi, ortadaki dönüm etiketi ve altındaki not. Ekranın kendisi
/// zaten üç cümlelik bir metin; grafik onlarla yarışıyordu. Kalanlar: gösterge
/// satırı ve iki uç etiketi. Dönüm noktası yalnızca kesik dikey çizgiyle
/// gösteriliyor, sözü zaten üstteki cümle söylüyor.
struct ExpectationCurveChart: View {
    var startDelay: Double = 0
    var startsImmediately = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.patikaInk) private var ink
    @ScaledMetric(relativeTo: .caption) private var chartHeight: CGFloat = 132

    @State private var delayElapsed = false
    @State private var isOnScreen = false
    @State private var hasStarted = false
    @State private var chartOpacity: Double = 0
    @State private var otherAppsProgress: CGFloat = 0
    @State private var patikaProgress: CGFloat = 0
    @State private var showsOtherAppsEndpoint = false
    @State private var showsPatikaEndpoint = false

    private let horizontalInset: CGFloat = 5
    private let verticalInset: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            legend

            GeometryReader { geometry in
                let plot = plotRect(in: geometry.size)

                ZStack(alignment: .topLeading) {
                    baseline(in: plot)
                    turningGuide(in: plot)

                    ExpectationLineShape(points: ExpectationCurveModel.otherApps)
                        .trim(from: 0, to: otherAppsProgress)
                        .stroke(
                            ink.primary.opacity(0.38),
                            style: StrokeStyle(
                                lineWidth: 2,
                                lineCap: .round,
                                lineJoin: .round,
                                dash: [6, 6]
                            )
                        )
                        .frame(width: plot.width, height: plot.height)
                        .offset(x: plot.minX, y: plot.minY)

                    ExpectationLineShape(points: ExpectationCurveModel.patika)
                        .trim(from: 0, to: patikaProgress)
                        .stroke(
                            ink.primary.opacity(0.96),
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: ink.primary.opacity(0.22), radius: 7)
                        .frame(width: plot.width, height: plot.height)
                        .offset(x: plot.minX, y: plot.minY)

                    endpoint(
                        for: ExpectationCurveModel.otherApps.last,
                        in: plot,
                        isPrimary: false
                    )
                    .opacity(showsOtherAppsEndpoint ? 1 : 0)

                    endpoint(
                        for: ExpectationCurveModel.patika.last,
                        in: plot,
                        isPrimary: true
                    )
                    .opacity(showsPatikaEndpoint ? 1 : 0)
                }
            }
            .frame(height: chartHeight)

            timelineCaptions
        }
        .opacity(chartOpacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Copy.Onboarding.expectationChartAccessibilityLabel))
        .onScrollVisibilityChange(threshold: 0.3) { isVisible in
            isOnScreen = isVisible
            startIfReady()
        }
        .task {
            if startsImmediately {
                delayElapsed = true
                isOnScreen = true
                startIfReady()
                return
            }

            try? await Task.sleep(for: .seconds(startDelay))
            guard !Task.isCancelled else { return }
            delayElapsed = true
            startIfReady()
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(
                Copy.Onboarding.expectationOtherAppsLabel,
                isPrimary: false
            )
            legendItem(
                Copy.Onboarding.expectationPatikaLabel,
                isPrimary: true
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legendItem(
        _ label: LocalizedStringResource,
        isPrimary: Bool
    ) -> some View {
        HStack(spacing: 6) {
            LegendLine(isPrimary: isPrimary)
                .frame(width: 22, height: 8)

            Text(label)
                .font(.caption2.weight(isPrimary ? Theme.Weight.action : Theme.Weight.emphasis))
                .foregroundStyle(ink.primary.opacity(isPrimary ? 0.96 : 0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    /// Yalnızca iki uç. Ortadaki dönüm etiketi kaldırıldı: `position` ile
    /// yerleştirilen o metin, kesik dikey çizginin ve alttaki uç etiketlerin
    /// arasına sıkışıp grafiği okunmaz kılıyordu.
    private var timelineCaptions: some View {
        HStack {
            Text(Copy.Onboarding.expectationStartCaption)
            Spacer(minLength: 8)
            Text(Copy.Onboarding.expectationEndCaption)
        }
        .font(.caption2.weight(Theme.Weight.emphasis))
        .foregroundStyle(ink.primary.opacity(0.48))
    }

    private func baseline(in plot: CGRect) -> some View {
        Path { path in
            path.move(to: CGPoint(x: plot.minX, y: plot.maxY))
            path.addLine(to: CGPoint(x: plot.maxX, y: plot.maxY))
        }
        .stroke(ink.primary.opacity(0.14), lineWidth: 1)
    }

    private func turningGuide(in plot: CGRect) -> some View {
        let x = plot.minX
            + plot.width * CGFloat(ExpectationCurveModel.turningDay)
            / CGFloat(ExpectationCurveModel.totalDays)

        return Path { path in
            path.move(to: CGPoint(x: x, y: plot.minY))
            path.addLine(to: CGPoint(x: x, y: plot.maxY))
        }
        .stroke(
            ink.primary.opacity(0.16),
            style: StrokeStyle(lineWidth: 1, dash: [3, 6])
        )
    }

    private func endpoint(
        for point: ExpectationCurveModel.Point?,
        in plot: CGRect,
        isPrimary: Bool
    ) -> some View {
        let point = point ?? .init(day: 0, level: 0)
        let x = plot.minX
            + plot.width * CGFloat(point.day) / CGFloat(ExpectationCurveModel.totalDays)
        let y = plot.minY + plot.height * (1 - CGFloat(point.level))
        let size: CGFloat = isPrimary ? 10 : 8

        return Circle()
            .fill(ink.primary.opacity(isPrimary ? 1 : 0.42))
            .frame(width: size, height: size)
            .shadow(
                color: ink.primary.opacity(isPrimary ? 0.45 : 0),
                radius: isPrimary ? 8 : 0
            )
            .position(x: x, y: y)
    }

    private func plotRect(in size: CGSize) -> CGRect {
        CGRect(
            x: horizontalInset,
            y: verticalInset,
            width: max(0, size.width - horizontalInset * 2),
            height: max(0, size.height - verticalInset * 2)
        )
    }

    private func startIfReady() {
        guard delayElapsed, isOnScreen, !hasStarted else { return }
        hasStarted = true

        guard !reduceMotion else {
            chartOpacity = 1
            otherAppsProgress = 1
            patikaProgress = 1
            showsOtherAppsEndpoint = true
            showsPatikaEndpoint = true
            return
        }

        withAnimation(.easeInOut(duration: Theme.Motion.revealFade)) {
            chartOpacity = 1
        }
        withAnimation(.easeInOut(duration: Theme.Motion.expectationOtherAppsDraw)) {
            otherAppsProgress = 1
        }
        withAnimation(
            .easeOut(duration: 0.35)
                .delay(Theme.Motion.expectationOtherAppsDraw * 0.76)
        ) {
            showsOtherAppsEndpoint = true
        }

        let patikaDelay = Theme.Motion.expectationOtherAppsDraw
            + Theme.Motion.expectationBetweenLines
        withAnimation(
            .easeInOut(duration: Theme.Motion.expectationPatikaDraw)
                .delay(patikaDelay)
        ) {
            patikaProgress = 1
        }
        withAnimation(
            .easeOut(duration: 0.40)
                .delay(patikaDelay + Theme.Motion.expectationPatikaDraw * 0.82)
        ) {
            showsPatikaEndpoint = true
        }
    }
}

private struct LegendLine: View {
    @Environment(\.patikaInk) private var ink
    let isPrimary: Bool

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
            }
            .stroke(
                ink.primary.opacity(isPrimary ? 0.96 : 0.42),
                style: StrokeStyle(
                    lineWidth: isPrimary ? 3.5 : 2,
                    lineCap: .round,
                    dash: isPrimary ? [] : [5, 5]
                )
            )
        }
        .accessibilityHidden(true)
    }
}

/// Normalize gün/seviye noktalarını kendi çizim alanına taşıyan yumuşak çizgi.
private struct ExpectationLineShape: Shape {
    let points: [ExpectationCurveModel.Point]

    func path(in rect: CGRect) -> Path {
        let scaled = points.map { point in
            CGPoint(
                x: rect.minX
                    + rect.width * CGFloat(point.day) / CGFloat(ExpectationCurveModel.totalDays),
                y: rect.minY + rect.height * (1 - CGFloat(point.level))
            )
        }

        return Path { path in
            guard scaled.count > 1 else { return }
            path.move(to: scaled[0])

            for index in 0..<(scaled.count - 1) {
                let previous = scaled[max(index - 1, 0)]
                let current = scaled[index]
                let next = scaled[index + 1]
                let following = scaled[min(index + 2, scaled.count - 1)]

                let control1 = CGPoint(
                    x: current.x + (next.x - previous.x) / 6,
                    y: current.y + (next.y - previous.y) / 6
                )
                let control2 = CGPoint(
                    x: next.x - (following.x - current.x) / 6,
                    y: next.y - (following.y - current.y) / 6
                )
                path.addCurve(to: next, control1: control1, control2: control2)
            }
        }
    }
}

#Preview {
    ZStack {
        BreathingMeshBackground(palette: Palette.all["sleep"]!, safeY: 0.30)
        ExpectationCurveChart(startsImmediately: true)
            .padding(.horizontal, Theme.Spacing.screenMargin)
    }
    .preferredColorScheme(.dark)
}
