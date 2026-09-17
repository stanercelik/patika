import SwiftUI

/// Kesintisiz bir yürüyüş rotası. Her durak bir **tabela**: yoldaki yuvarlak ile
/// adımın adı tek bir gövde.
///
/// ## Neden tabela
///
/// Önce düğüm ile etiket arasında 12 pt boşluk vardı ve rota o boşluktan
/// geçiyordu; etiket, düğüme ait bir isim değil yola düşmüş ayrı bir kutu gibi
/// okunuyordu (ürün sahibi geri bildirimi, 2026-09-17). Şimdi etiket düğümün
/// altına giriyor, ikisi tek siluet oluşturuyor.
///
/// Duraklar merkezin iki yanında sırayla duruyor; aradaki olukta yol görünmeye
/// devam ediyor. Ortada duran bir durak yolu boydan boya örterdi.
struct IllustratedPathMap: View {
    let viewModel: MyPathViewModel
    let onStart: (PathStepRecord) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.steps.enumerated()), id: \.element.id) { index, step in
                IllustratedPathStop(
                    step: step,
                    viewModel: viewModel,
                    isLeading: dynamicTypeSize.isAccessibilitySize || index.isMultiple(of: 2),
                    onStart: { onStart(step) }
                )
                .id(step.id)
            }
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .backgroundPreferenceValue(PathStopAnchors.self) { anchors in
            GeometryReader { geometry in
                let points = viewModel.steps.compactMap { step -> CGPoint? in
                    guard let anchor = anchors[step.id] else { return nil }
                    let rect = geometry[anchor]
                    return CGPoint(x: rect.midX, y: rect.midY)
                }
                let route = continuousRoute(points)
                route.stroke(WoodlandStyle.ink.opacity(0.22), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                route.stroke(WoodlandStyle.paper.opacity(0.78), style: StrokeStyle(lineWidth: 11, lineCap: .round))
                route.stroke(WoodlandStyle.paper.opacity(0.35), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

private struct IllustratedPathStop: View {
    let step: PathStepRecord
    let viewModel: MyPathViewModel
    /// Durak merkezin solunda mı: oluk karşı tarafta açılır.
    let isLeading: Bool
    let onStart: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var current: Bool { viewModel.isCurrent(step) }
    private var completed: Bool { viewModel.isCompleted(step) }
    private var expanded: Bool { viewModel.isExpanded(step) }
    private var locked: Bool { viewModel.isLocked(step) }
    private var accessible: Bool { dynamicTypeSize.isAccessibilitySize }
    private var nodeSize: CGFloat { current ? 72 : 54 }

    /// Etiketin düğümün altına girdiği pay. Siluetin tek parça okunması buna
    /// bağlı: boşluk kaldığı an iki ayrı nesne görünüyor.
    private let tuck: CGFloat = 20
    /// Yolun göründüğü oluk. AX boyutlarında metne yer açmak için kapanır.
    private var gutter: CGFloat { accessible ? 0 : 88 }

    private var expandAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.18) : Theme.Motion.bouncy
    }

    var body: some View {
        HStack(spacing: 0) {
            if !isLeading, gutter > 0 { Color.clear.frame(width: gutter) }
            signpost
            if isLeading, gutter > 0 { Color.clear.frame(width: gutter) }
        }
        .padding(.top, 20)
        .padding(.bottom, 44)
        .animation(expandAnimation, value: expanded)
    }

    /// Düğüm + etiket tek gövde. Negatif aralık etiketi düğümün altına sokuyor;
    /// `zIndex` düğümü üstte tutuyor ki daire etiketin kenarında kesilmesin.
    private var signpost: some View {
        VStack(spacing: -tuck) {
            nodeMark
                .zIndex(1)
            label
        }
        .frame(maxWidth: .infinity)
    }

    private var nodeMark: some View {
        ZStack {
            if current {
                Circle()
                    .stroke(WoodlandStyle.apricot.opacity(0.24), lineWidth: Theme.Line.border)
                    .frame(width: nodeSize + 18, height: nodeSize + 18)
            }
            Circle()
                .fill(current ? WoodlandStyle.paper : WoodlandStyle.ink)
                .overlay {
                    Circle().strokeBorder(
                        current ? WoodlandStyle.apricot : WoodlandStyle.sage.opacity(0.45),
                        lineWidth: Theme.Line.border
                    )
                }
                .frame(width: nodeSize, height: nodeSize)
                .shadow(color: WoodlandStyle.ink.opacity(0.18), radius: 8, y: 4)

            if current || completed {
                Image(systemName: completed ? "checkmark" : "leaf.fill")
                    .font(Theme.TypeFace.nodeMark)
                    .foregroundStyle(current ? WoodlandStyle.ink : WoodlandStyle.sage)
            } else {
                Text(step.day.formatted())
                    .font(Theme.TypeFace.nodeMark)
                    .foregroundStyle(Theme.textPrimary.color)
            }
        }
        .frame(width: nodeSize + 18, height: nodeSize + 18)
        .anchorPreference(key: PathStopAnchors.self, value: .bounds) { [step.id: $0] }
        .accessibilityHidden(true)
    }

    /// Özet ile ayrıntı **aynı** kâğıdın üstünde: açılınca yeni bir kart
    /// belirmiyor, tabela uzuyor.
    private var label: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                Theme.softHaptic(intensity: 0.25)
                withAnimation(expandAnimation) { viewModel.toggle(step) }
            } label: {
                summary
            }
            .buttonStyle(PathStopButtonStyle())
            .disabled(locked)
            .accessibilityElement(children: .combine)
            .accessibilityValue(Text(verbatim: accessibilityState))
            .accessibilityHint(
                locked
                    ? Text(Copy.Path.lockedHint)
                    : Text(expanded ? Copy.Path.collapseDetails : Copy.Path.expandDetails)
            )

            if expanded {
                detail
                    .transition(.opacity.combined(with: .offset(y: reduceMotion ? 0 : -6)))
            }
        }
        .background(
            WoodlandStyle.paper,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: WoodlandStyle.ink.opacity(0.14), radius: 12, y: 5)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                if locked {
                    Image(systemName: "lock.fill").accessibilityHidden(true)
                }
                Text(current ? Copy.Path.currentLocation : Copy.Path.stepLabel(day: step.day))
                Spacer(minLength: 4)
                if !locked {
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
            }
            .font(Theme.TypeFace.cardMeta)
            .foregroundStyle(WoodlandStyle.secondaryInk)

            Text(verbatim: step.title)
                .font(current ? Theme.TypeFace.cardTitleProminent : Theme.TypeFace.cardTitle)
                .foregroundStyle(WoodlandStyle.ink)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.isMeasurementDay(step) {
                Text(Copy.Path.measurementNote)
                    .font(Theme.TypeFace.cardMeta)
                    .foregroundStyle(WoodlandStyle.secondaryInk)
            }
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Düğümün altından başla: metin dairenin altında kalmasın.
        .padding(.top, tuck + 14)
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
        .contentShape(Rectangle())
    }

    private var accessibilityState: String {
        if locked { return String(localized: Copy.Path.lockedAccessibility) }
        let disclosure = String(localized: expanded ? Copy.Path.detailsExpanded : Copy.Path.detailsCollapsed)
        return completed ? String(localized: Copy.Path.completedNote) + ". " + disclosure : disclosure
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(WoodlandStyle.secondaryInk.opacity(0.16))
                .frame(height: Theme.Line.journeyConnector)
                .accessibilityHidden(true)

            if let phase = viewModel.phase(for: step) {
                Text(phase.label)
                    .font(Theme.TypeFace.cardMeta)
                    .foregroundStyle(WoodlandStyle.secondaryInk)
            }
            if let techniques = viewModel.techniques(for: step), techniques != step.title {
                Text(verbatim: techniques)
                    .font(Theme.TypeFace.detailBody)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if viewModel.isMeasurementDay(step) {
                Text(Copy.Path.measurementNotice)
                    .font(Theme.TypeFace.detailBody)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: onStart) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(Theme.TypeFace.cardMeta)
                        .accessibilityHidden(true)
                    Text(completed ? Copy.Path.replayCTA : Copy.Path.continueCTA)
                        .font(Theme.TypeFace.action)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: 24)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .foregroundStyle(WoodlandStyle.paper)
                .background(WoodlandStyle.ink, in: Capsule())
            }
            .buttonStyle(.calm)
            .disabled(locked)
        }
        .foregroundStyle(WoodlandStyle.ink)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Kapalı duraklar başlığını okunur tutar; açılmadığını kilit ve metin anlatır.
private struct PathStopButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.smooth(duration: 0.24), value: configuration.isPressed)
    }
}

private struct PathStopAnchors: PreferenceKey {
    static var defaultValue: [UUID: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [UUID: Anchor<CGRect>], nextValue: () -> [UUID: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

/// Gerçek düğüm merkezleri arasında karo başına tek bir kübik; satır sınırında
/// köşe oluşmuyor.
private func continuousRoute(_ points: [CGPoint]) -> Path {
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
