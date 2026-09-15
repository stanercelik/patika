import SwiftUI

enum JourneyMapPresentation {
    case roadmap
    case personalTrace
}

/// F2 ve Yolum'un ortak, faz duyarlı Kişisel İz satırı.
///
/// Satırlar sınırda aynı ara x değerini kullandığı için farklı metin
/// yüksekliklerinde iz kopmaz; scroll sırasında liste geometrisi state'e
/// yazılmaz.
struct JourneyMapRow<Content: View>: View {
    let index: Int
    let totalCount: Int
    let position: JourneyRoutePosition
    let phase: PathPhase?
    let startsPhase: Bool
    let node: TrailNode
    var showsLock = false
    var isProminent = false
    var disablesMotion = false
    var presentation: JourneyMapPresentation = .roadmap
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .body) private var nodeCenterY: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var normalRowHeight: CGFloat = 132
    @ScaledMetric(relativeTo: .body) private var prominentRowHeight: CGFloat = 208
    @ScaledMetric(relativeTo: .body) private var prominentRouteClearance: CGFloat = 104
    @ScaledMetric(relativeTo: .body) private var accessibleProminentTopInset: CGFloat = 58
    @ScaledMetric(relativeTo: .caption) private var phaseInset: CGFloat = 26
    @State private var isRevealed = false

    private let accessibleRailCenter: CGFloat = 34
    private let accessibleContentInset: CGFloat = 78

    private var usesAccessibleLayout: Bool { dynamicTypeSize.isAccessibilitySize }
    private var showsPhaseThreshold: Bool { startsPhase && index > 0 && phase != nil }
    private var nodeIsLeading: Bool { position.currentX < 0.5 }

    var body: some View {
        contentLayout
            .padding(.vertical, 16)
            .frame(minHeight: rowHeight, alignment: .topLeading)
            .background { staticRoute }
            .background { phaseArtwork }
            .overlay { markersAndActiveInk }
            .overlay { phaseThreshold }
            .opacity(isRevealed ? 1 : 0)
            .offset(y: isRevealed || motionIsReduced ? 0 : 8)
            .task { reveal() }
            .onChange(of: motionIsReduced) {
                if motionIsReduced { isRevealed = true }
            }
            .animation(.easeOut(duration: Theme.Motion.stepFill), value: node)
    }

    private var rowHeight: CGFloat {
        let base: CGFloat
        if usesAccessibleLayout {
            base = normalRowHeight
        } else {
            base = isProminent ? prominentRowHeight : normalRowHeight
        }
        return base + contentTopInset
    }

    private var contentTopInset: CGFloat { showsPhaseThreshold ? phaseInset : 0 }
    private var resolvedNodeCenterY: CGFloat { nodeCenterY + contentTopInset }

    @ViewBuilder
    private var contentLayout: some View {
        if presentation == .personalTrace, isProminent {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 72 + contentTopInset)
        } else if usesAccessibleLayout, isProminent {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 48)
                .padding(.top, min(accessibleProminentTopInset, 140) + contentTopInset)
        } else if usesAccessibleLayout {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, accessibleContentInset)
                .padding(.top, contentTopInset)
        } else if isProminent {
            HStack(alignment: .top, spacing: 24) {
                if nodeIsLeading { prominentClearance }
                content.frame(maxWidth: .infinity, alignment: .leading)
                if !nodeIsLeading { prominentClearance }
            }
            .padding(.top, contentTopInset)
        } else {
            HStack(alignment: .top, spacing: 36) {
                if nodeIsLeading { routeClearance }
                content.frame(maxWidth: .infinity, alignment: .leading)
                if !nodeIsLeading { routeClearance }
            }
            .padding(.top, contentTopInset)
        }
    }

    private var routeClearance: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }

    private var prominentClearance: some View {
        Color.clear
            .frame(width: prominentRouteClearance)
            .accessibilityHidden(true)
    }

    private var staticRoute: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let nodeY = resolvedNodeY(in: size.height)
            let previousX = resolvedNodeX(position.previousX, in: size.width)
            let currentX = resolvedNodeX(position.currentX, in: size.width)
            let nextX = resolvedNodeX(position.nextX, in: size.width)

            ZStack {
                JourneyRouteSegment(
                    previousX: previousX,
                    currentX: currentX,
                    nextX: nextX,
                    nodeY: nodeY,
                    showsAbove: index > 0,
                    showsBelow: index < totalCount - 1,
                    breaksAbove: presentation == .roadmap && showsPhaseThreshold,
                    part: .whole
                )
                .trim(from: 0, to: routeReveal)
                .stroke(
                    Theme.textPrimary.color.opacity(baseRouteOpacity),
                    style: StrokeStyle(
                        lineWidth: Theme.Line.trail,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: presentation == .roadmap && showsLock ? [5, 8] : []
                    )
                )

                if node == .done {
                    JourneyRouteSegment(
                        previousX: previousX,
                        currentX: currentX,
                        nextX: nextX,
                        nodeY: nodeY,
                        showsAbove: index > 0,
                        showsBelow: index < totalCount - 1,
                        breaksAbove: presentation == .roadmap && showsPhaseThreshold,
                        part: .whole
                    )
                    .trim(from: 0, to: routeReveal)
                    .stroke(
                        Theme.textPrimary.color.opacity(0.50),
                        style: StrokeStyle(
                            lineWidth: Theme.Line.trail + 1,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }

                if presentation == .roadmap {
                    JourneyContentConnector(
                        nodeX: currentX,
                        nodeY: nodeY,
                        targetX: connectorTargetX(in: size.width)
                    )
                    .trim(from: 0, to: isRevealed ? 1 : 0)
                    .stroke(
                        Theme.textPrimary.color.opacity(showsLock ? 0.12 : 0.24),
                        style: StrokeStyle(
                            lineWidth: Theme.Line.journeyConnector,
                            lineCap: .round
                        )
                    )
                }
            }
            .animation(routeAnimation, value: isRevealed)
        }
        .accessibilityHidden(true)
    }

    private var markersAndActiveInk: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let x = resolvedNodeX(position.currentX, in: size.width)
            let y = resolvedNodeY(in: size.height)

            if node == .active {
                JourneyMotionValueReader(forcePaused: disablesMotion) { breath in
                    ZStack {
                        JourneyRouteSegment(
                            previousX: resolvedNodeX(position.previousX, in: size.width),
                            currentX: x,
                            nextX: resolvedNodeX(position.nextX, in: size.width),
                            nodeY: y,
                            showsAbove: index > 0,
                            showsBelow: false,
                            breaksAbove: presentation == .roadmap && showsPhaseThreshold,
                            part: .above
                        )
                        .trim(from: 0, to: routeReveal)
                        .stroke(
                            Theme.textPrimary.color.opacity(0.66 + breath * 0.10),
                            style: StrokeStyle(
                                lineWidth: Theme.Line.trail + 1,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )

                        JourneyMapNode(node: node, showsLock: showsLock, breath: breath)
                            .position(x: x, y: y)
                    }
                }
            } else {
                JourneyMapNode(node: node, showsLock: showsLock)
                    .position(x: x, y: y)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .scaleEffect(isRevealed ? 1 : 0.84)
        .opacity(isRevealed ? 1 : 0)
        .animation(routeAnimation, value: isRevealed)
        .animation(.easeOut(duration: Theme.Motion.journeyNodeReplace), value: node)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var phaseThreshold: some View {
        if let phase, showsPhaseThreshold {
            GeometryReader { geometry in
                let topX = (
                    resolvedNodeX(position.previousX, in: geometry.size.width)
                        + resolvedNodeX(position.currentX, in: geometry.size.width)
                ) / 2
                JourneyPhaseThreshold(
                    phase: phase,
                    isVisible: isRevealed,
                    style: presentation == .roadmap ? .capsule : .margin
                )
                    .fixedSize()
                    .position(
                        x: phaseLabelX(topX: topX, width: geometry.size.width),
                        y: 12
                    )
                    .animation(
                        motionIsReduced
                            ? nil
                            : .easeOut(duration: Theme.Motion.journeyPhaseReveal),
                        value: isRevealed
                    )
            }
        }
    }

    private var routeAnimation: Animation? {
        motionIsReduced
            ? nil
            : .easeOut(duration: Theme.Motion.journeyRouteDraw)
                .delay(min(Double(index) * Theme.Motion.journeyNodeStagger, 0.30))
    }

    @ViewBuilder
    private var phaseArtwork: some View {
        if presentation == .personalTrace,
           let phase,
           JourneyPhaseDecoration.shouldShow(startsPhase: startsPhase, rowIndex: index),
           !usesAccessibleLayout {
            GeometryReader { geometry in
                Image(decorative: JourneyPhaseDecoration.assetName(for: phase))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104, height: 88)
                    .opacity(isRevealed ? 0.18 : 0)
                    .scaleEffect(isRevealed ? 1 : 0.96)
                    .position(
                        x: nodeIsLeading ? 34 : geometry.size.width - 34,
                        y: min(96 + contentTopInset, geometry.size.height - 42)
                    )
                    .animation(
                        motionIsReduced
                            ? nil
                            : .easeOut(duration: Theme.Motion.journeyTextReveal),
                        value: isRevealed
                    )
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func resolvedNodeY(in height: CGFloat) -> CGFloat {
        min(resolvedNodeCenterY, max(24, height - 24))
    }

    private func resolvedNodeX(_ normalizedX: Double, in width: CGFloat) -> CGFloat {
        usesAccessibleLayout
            ? min(accessibleRailCenter, width / 2)
            : width * CGFloat(normalizedX)
    }

    private func connectorTargetX(in width: CGFloat) -> CGFloat {
        if usesAccessibleLayout { return min(accessibleContentInset - 12, width - 12) }
        return nodeIsLeading ? width / 2 - 18 : width / 2 + 18
    }

    private var routeReveal: CGFloat {
        presentation == .personalTrace ? 1 : (isRevealed ? 1 : 0)
    }

    private var baseRouteOpacity: Double {
        if presentation == .personalTrace { return showsLock ? 0.16 : 0.21 }
        return showsLock ? 0.10 : 0.18
    }

    private func phaseLabelX(topX: CGFloat, width: CGFloat) -> CGFloat {
        guard presentation == .personalTrace else {
            return min(max(topX, 64), max(64, width - 64))
        }
        return topX < width / 2 ? max(62, width - 62) : 62
    }

    @MainActor
    private func reveal() {
        guard !isRevealed else { return }
        if motionIsReduced {
            isRevealed = true
        } else {
            withAnimation(routeAnimation) { isRevealed = true }
        }
    }

    private var motionIsReduced: Bool { reduceMotion || disablesMotion }
}

private nonisolated enum JourneyRoutePart {
    case whole
    case above
}

/// Üst sınırdan düğüme ve düğümden alt sınıra uzanan eğri. Faz başlangıcında
/// gerçek çizgi aralığı kullanır; hareketli mesh renginde maske yoktur.
private struct JourneyRouteSegment: Shape {
    let previousX: CGFloat
    let currentX: CGFloat
    let nextX: CGFloat
    let nodeY: CGFloat
    let showsAbove: Bool
    let showsBelow: Bool
    let breaksAbove: Bool
    let part: JourneyRoutePart

    nonisolated func path(in rect: CGRect) -> Path {
        let current = CGPoint(x: currentX, y: nodeY)
        var result = Path()

        if showsAbove {
            let top = CGPoint(x: (previousX + currentX) / 2, y: 0)
            var above = Path()
            above.move(to: top)
            above.addCurve(
                to: current,
                control1: CGPoint(x: top.x, y: nodeY * 0.38),
                control2: CGPoint(x: current.x, y: nodeY * 0.62)
            )
            if breaksAbove {
                result.addPath(above.trimmedPath(from: 0, to: 0.40))
                result.addPath(above.trimmedPath(from: 0.58, to: 1))
            } else {
                result.addPath(above)
            }
        }

        if part == .whole, showsBelow {
            let bottom = CGPoint(x: (currentX + nextX) / 2, y: rect.height)
            let remaining = max(rect.height - nodeY, 1)
            var below = Path()
            below.move(to: current)
            below.addCurve(
                to: bottom,
                control1: CGPoint(x: current.x, y: nodeY + remaining * 0.38),
                control2: CGPoint(x: bottom.x, y: nodeY + remaining * 0.72)
            )
            result.addPath(below)
        }

        return result
    }
}

/// Düğüm ile karşı kolondaki metni tek okuma birimi gibi bağlayan yönsüz çizgi.
private struct JourneyContentConnector: Shape {
    let nodeX: CGFloat
    let nodeY: CGFloat
    let targetX: CGFloat

    nonisolated func path(in rect: CGRect) -> Path {
        let direction: CGFloat = targetX >= nodeX ? 1 : -1
        return Path { path in
            path.move(to: CGPoint(x: nodeX + direction * 18, y: nodeY))
            path.addLine(to: CGPoint(x: targetX, y: nodeY))
        }
    }
}

#Preview("Kişisel İz — normal") {
    ScrollView {
        VStack(spacing: 0) {
            JourneyMapPreviewRow(index: 0, node: .done, x: (0.40, 0.40, 0.58))
            JourneyMapPreviewRow(index: 1, node: .active, x: (0.40, 0.58, 0.36))
            JourneyMapPreviewRow(
                index: 2,
                node: .pending,
                x: (0.58, 0.36, 0.70),
                phase: .awareness,
                startsPhase: true
            )
            JourneyMapPreviewRow(index: 3, node: .milestone, x: (0.36, 0.70, 0.38))
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
    .background(Color(red: 0.06, green: 0.10, blue: 0.14))
    .preferredColorScheme(.dark)
}

#Preview("Kişisel İz — AX5, statik") {
    ScrollView {
        VStack(spacing: 0) {
            JourneyMapPreviewRow(
                index: 0,
                node: .active,
                x: (0.10, 0.10, 0.10),
                disablesMotion: true
            )
            JourneyMapPreviewRow(
                index: 1,
                node: .pending,
                x: (0.10, 0.10, 0.10),
                phase: .skill,
                startsPhase: true,
                disablesMotion: true
            )
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
    .background(Color(red: 0.06, green: 0.10, blue: 0.14))
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}

private struct JourneyMapPreviewRow: View {
    let index: Int
    let node: TrailNode
    let x: (Double, Double, Double)
    var phase: PathPhase?
    var startsPhase = false
    var disablesMotion = false

    var body: some View {
        JourneyMapRow(
            index: index,
            totalCount: 4,
            position: JourneyRoutePosition(previousX: x.0, currentX: x.1, nextX: x.2),
            phase: phase,
            startsPhase: startsPhase,
            node: node,
            showsLock: node == .pending || node == .milestone,
            isProminent: node == .active,
            disablesMotion: disablesMotion
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gün \(index + 1)")
                    .font(.caption.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                Text(index == 1 ? "Düşünceyle arana küçük bir mesafe koy" : "Bugünün kişisel adımı")
                    .font(.body.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
