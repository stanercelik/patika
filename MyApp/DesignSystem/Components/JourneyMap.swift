import SwiftUI

/// F2 ve "Yolum" ekranlarının ortak, kıvrımlı yol satırı.
///
/// Yol her satırın kendi sınırları içinde çizilir. Komşu satırlar sınırda aynı
/// orta noktada buluştuğu için farklı metin yüksekliklerinde ve Dynamic Type'ta
/// tek parça kalır; bütün listenin geometrisini her scroll karesinde ölçmek
/// gerekmez.
struct JourneyMapRow<Content: View>: View {
    let index: Int
    let totalCount: Int
    let node: TrailNode
    var showsLock = false
    var isProminent = false
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .body) private var nodeCenterY: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var normalRowHeight: CGFloat = 132
    @ScaledMetric(relativeTo: .body) private var prominentRowHeight: CGFloat = 208
    @ScaledMetric(relativeTo: .body) private var prominentRouteClearance: CGFloat = 104
    @ScaledMetric(relativeTo: .body) private var accessibleProminentTopInset: CGFloat = 58
    private let accessibleRailCenter: CGFloat = 34
    private let accessibleContentInset: CGFloat = 78
    @State private var isRevealed = false

    private var usesAccessibleLayout: Bool { dynamicTypeSize.isAccessibilitySize }
    private var currentX: CGFloat {
        JourneyRoutePattern.normalizedX(at: index, usesAccessibleLayout: usesAccessibleLayout)
    }
    private var previousX: CGFloat {
        JourneyRoutePattern.normalizedX(at: index - 1, usesAccessibleLayout: usesAccessibleLayout)
    }
    private var nextX: CGFloat {
        JourneyRoutePattern.normalizedX(at: index + 1, usesAccessibleLayout: usesAccessibleLayout)
    }
    private var nodeIsLeading: Bool { currentX < 0.5 }

    var body: some View {
        contentLayout
            .padding(.vertical, 16)
            .frame(minHeight: rowHeight, alignment: .topLeading)
            .background { route }
            .overlay { marker }
            .opacity(isRevealed ? 1 : 0)
            .offset(y: isRevealed || reduceMotion ? 0 : 8)
            .task { reveal() }
            .onChange(of: reduceMotion) {
                if reduceMotion { isRevealed = true }
            }
            .animation(.easeOut(duration: Theme.Motion.stepFill), value: node)
    }

    private var rowHeight: CGFloat {
        if usesAccessibleLayout { return normalRowHeight }
        return isProminent ? prominentRowHeight : normalRowHeight
    }

    @ViewBuilder
    private var contentLayout: some View {
        if usesAccessibleLayout, isProminent {
            // AX boyutunda aktif kart rayın yanındaki dar kolona sıkışmaz.
            // Düğüm üstte kalır, kart bütün genişliği kullanır.
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 48)
                .padding(.top, min(accessibleProminentTopInset, 140))
        } else if usesAccessibleLayout {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, accessibleContentInset)
        } else if isProminent {
            HStack(alignment: .top, spacing: 24) {
                if nodeIsLeading { prominentClearance }
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !nodeIsLeading { prominentClearance }
            }
        } else {
            HStack(alignment: .top, spacing: 36) {
                if nodeIsLeading { routeClearance }
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !nodeIsLeading { routeClearance }
            }
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

    private var route: some View {
        GeometryReader { geometry in
            let y = resolvedNodeY(in: geometry.size.height)
            ZStack {
                JourneyRouteSegment(
                    previousX: resolvedNodeX(previousX, in: geometry.size.width),
                    currentX: resolvedNodeX(currentX, in: geometry.size.width),
                    nextX: resolvedNodeX(nextX, in: geometry.size.width),
                    nodeY: y,
                    showsAbove: index > 0,
                    showsBelow: index < totalCount - 1,
                    part: .whole
                )
                .trim(from: 0, to: isRevealed ? 1 : 0)
                .stroke(
                    Theme.textPrimary.color.opacity(showsLock ? 0.10 : 0.18),
                    style: StrokeStyle(
                        lineWidth: Theme.Line.trail,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: showsLock ? [5, 8] : []
                    )
                )

                if node == .done || node == .active {
                    JourneyRouteSegment(
                        previousX: resolvedNodeX(previousX, in: geometry.size.width),
                        currentX: resolvedNodeX(currentX, in: geometry.size.width),
                        nextX: resolvedNodeX(nextX, in: geometry.size.width),
                        nodeY: y,
                        showsAbove: index > 0,
                        showsBelow: index < totalCount - 1,
                        part: node == .active ? .above : .whole
                    )
                    .trim(from: 0, to: isRevealed ? 1 : 0)
                    .stroke(
                        Theme.textPrimary.color.opacity(node == .active ? 0.74 : 0.48),
                        style: StrokeStyle(
                            lineWidth: Theme.Line.trail + 1,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .transition(.opacity)
                }
            }
            .animation(routeAnimation, value: isRevealed)
        }
        .accessibilityHidden(true)
    }

    private var marker: some View {
        GeometryReader { geometry in
            JourneyMapNode(node: node, showsLock: showsLock)
                .position(
                    x: resolvedNodeX(currentX, in: geometry.size.width),
                    y: resolvedNodeY(in: geometry.size.height)
                )
                .scaleEffect(isRevealed ? 1 : 0.84)
                .opacity(isRevealed ? 1 : 0)
                .animation(routeAnimation, value: isRevealed)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var routeAnimation: Animation? {
        reduceMotion
            ? nil
            : .easeOut(duration: Theme.Motion.journeyRouteDraw)
                .delay(min(Double(index) * Theme.Motion.journeyNodeStagger, 0.30))
    }

    private func resolvedNodeY(in height: CGFloat) -> CGFloat {
        min(nodeCenterY, max(24, height - 24))
    }

    private func resolvedNodeX(_ normalizedX: CGFloat, in width: CGFloat) -> CGFloat {
        usesAccessibleLayout
            ? min(accessibleRailCenter, width / 2)
            : width * normalizedX
    }

    @MainActor
    private func reveal() {
        guard !isRevealed else { return }
        if reduceMotion {
            isRevealed = true
        } else {
            withAnimation(routeAnimation) { isRevealed = true }
        }
    }
}

private nonisolated enum JourneyRoutePart {
    case whole
    case above
}

/// Tek satırın üst sınırından düğüme, oradan alt sınıra uzanan eğri.
private struct JourneyRouteSegment: Shape {
    let previousX: CGFloat
    let currentX: CGFloat
    let nextX: CGFloat
    let nodeY: CGFloat
    let showsAbove: Bool
    let showsBelow: Bool
    let part: JourneyRoutePart

    func path(in rect: CGRect) -> Path {
        let current = CGPoint(x: currentX, y: nodeY)
        let topX = (previousX + currentX) / 2
        let bottomX = (currentX + nextX) / 2
        let top = CGPoint(x: topX, y: 0)
        let bottom = CGPoint(x: bottomX, y: rect.height)

        var path = Path()
        if showsAbove {
            path.move(to: top)
            path.addCurve(
                to: current,
                control1: CGPoint(x: top.x, y: nodeY * 0.38),
                control2: CGPoint(x: current.x, y: nodeY * 0.62)
            )
        } else {
            path.move(to: current)
        }

        if part == .whole, showsBelow {
            let remaining = max(rect.height - nodeY, 1)
            path.addCurve(
                to: bottom,
                control1: CGPoint(x: current.x, y: nodeY + remaining * 0.38),
                control2: CGPoint(x: bottom.x, y: nodeY + remaining * 0.72)
            )
        }
        return path
    }
}

/// Harita ölçeğindeki durum düğümü. `TrailNodeDot` F1'in küçük üretim izinde
/// kalır; harita düğümü başparmakla taranabilen daha belirgin bir işarettir.
private struct JourneyMapNode: View {
    let node: TrailNode
    let showsLock: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State private var thermalState = ProcessInfo.processInfo.thermalState
    @ScaledMetric(relativeTo: .body) private var pendingSize: CGFloat = 34
    @ScaledMetric(relativeTo: .body) private var activeSize: CGFloat = 50
    @ScaledMetric(relativeTo: .body) private var milestoneSize: CGFloat = 42
    @ScaledMetric(relativeTo: .body) private var doneSize: CGFloat = 36

    var body: some View {
        switch node {
        case .pending:
            pending
        case .active:
            active
        case .done:
            done
        case .milestone:
            milestone
        }
    }

    private var pending: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.18))
            Circle()
                .strokeBorder(Theme.textPrimary.color.opacity(0.32), lineWidth: Theme.Line.border)
            if showsLock {
                Image(systemName: "lock.fill")
                    .font(.caption2.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color.opacity(0.48))
            } else {
                Circle()
                    .fill(Theme.textPrimary.color.opacity(0.48))
                    .frame(width: 6, height: 6)
            }
        }
        .frame(width: resolvedPendingSize, height: resolvedPendingSize)
    }

    private var active: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: pausesContinuousMotion)) { timeline in
            let breath = pausesContinuousMotion
                ? 0.5
                : BreathCycle.value(
                    at: timeline.date.timeIntervalSinceReferenceDate,
                    amplitude: BreathAmplitude.ambient
                )

            ZStack {
                Circle()
                    .stroke(Theme.textPrimary.color.opacity(0.18 + breath * 0.12), lineWidth: 8)
                    .scaleEffect(0.90 + breath * 0.10)
                Circle()
                    .fill(Color.black.opacity(0.24))
                    .overlay {
                        Circle()
                            .strokeBorder(Theme.textPrimary.color.opacity(0.92), lineWidth: Theme.Line.border)
                    }
                Circle()
                    .fill(Theme.textPrimary.color)
                    .frame(width: 12, height: 12)
            }
        }
        .frame(width: resolvedActiveSize, height: resolvedActiveSize)
        .onReceive(NotificationCenter.default.publisher(for: ProcessInfo.PowerStateDidChangeMessage.name)) { _ in
            lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        .onReceive(NotificationCenter.default.publisher(for: ProcessInfo.ThermalStateDidChangeMessage.name)) { _ in
            thermalState = ProcessInfo.processInfo.thermalState
        }
    }

    private var pausesContinuousMotion: Bool {
        reduceMotion
            || scenePhase != .active
            || lowPowerMode
            || thermalState == .serious
            || thermalState == .critical
    }

    private var done: some View {
        Circle()
            .fill(Theme.textPrimary.color.opacity(0.94))
            .overlay {
                Image(systemName: "checkmark")
                    .font(.caption.weight(Theme.Weight.action))
                    .foregroundStyle(Color.black.opacity(0.82))
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: resolvedDoneSize, height: resolvedDoneSize)
    }

    private var milestone: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.18))
            Circle()
                .strokeBorder(Theme.textPrimary.color.opacity(0.62), lineWidth: Theme.Line.border)
            Circle()
                .strokeBorder(Theme.textPrimary.color.opacity(0.34), lineWidth: 1)
                .padding(7)
            if showsLock {
                Image(systemName: "lock.fill")
                    .font(.caption2.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color.opacity(0.52))
            } else {
                Circle()
                    .fill(Theme.textPrimary.color.opacity(0.92))
                    .frame(width: 7, height: 7)
            }
        }
        .frame(width: resolvedMilestoneSize, height: resolvedMilestoneSize)
    }

    private var resolvedPendingSize: CGFloat { min(pendingSize, 44) }
    private var resolvedActiveSize: CGFloat { min(activeSize, 64) }
    private var resolvedMilestoneSize: CGFloat { min(milestoneSize, 52) }
    private var resolvedDoneSize: CGFloat { min(doneSize, 44) }
}
