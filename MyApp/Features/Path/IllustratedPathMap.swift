import SwiftUI

/// A continuous walking route. Lessons live on the route; gouache scenes fill
/// the clearings beside it. Each row measures its own text before drawing ink.
struct IllustratedPathMap: View {
    let viewModel: MyPathViewModel
    let onStart: (PathStepRecord) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private func location(_ index: Int) -> CGFloat {
        if dynamicTypeSize.isAccessibilitySize { return 0.5 }
        let positions: [CGFloat] = [0.5, 0.25, 0.5, 0.75, 0.5, 0.25, 0.5, 0.75]
        return positions[index % positions.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.steps.enumerated()), id: \.element.id) { index, step in
                IllustratedPathStop(
                    step: step,
                    viewModel: viewModel,
                    currentX: location(index),
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
    let currentX: CGFloat
    let onStart: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var current: Bool { viewModel.isCurrent(step) }
    private var completed: Bool { viewModel.isCompleted(step) }
    private var expanded: Bool { viewModel.isExpanded(step) }
    private var locked: Bool { viewModel.isLocked(step) }
    private var accessible: Bool { dynamicTypeSize.isAccessibilitySize }
    private var nodeSize: CGFloat { current ? 76 : 58 }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 0) {
                if currentX > 0.5 { clearing }
                stopButton
                    .frame(maxWidth: .infinity)
                if currentX < 0.5 { clearing }
            }
            .padding(.top, 18)

            if expanded {
                detail
                    .padding(.horizontal, accessible ? 0 : 20)
                    .transition(.opacity.combined(with: .offset(y: reduceMotion ? 0 : -5)))
            }
        }
        .padding(.bottom, 46)
        .frame(maxWidth: .infinity)
        .animation(reduceMotion ? .easeOut(duration: 0.18) : Theme.Motion.pathExpand, value: expanded)
    }

    private var clearing: some View {
        Color.clear.frame(maxWidth: .infinity).frame(height: 1)
    }

    private var stopButton: some View {
        Button {
            Theme.softHaptic(intensity: 0.25)
            withAnimation(reduceMotion ? .easeOut(duration: 0.18) : Theme.Motion.pathExpand) {
                viewModel.toggle(step)
            }
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    if current {
                        Circle().stroke(WoodlandStyle.apricot.opacity(0.24), lineWidth: Theme.Line.border)
                            .frame(width: 94, height: 94)
                    }
                    Circle()
                        .fill(current ? WoodlandStyle.paper : WoodlandStyle.ink)
                        .overlay {
                            Circle().strokeBorder(current ? WoodlandStyle.apricot : WoodlandStyle.sage.opacity(0.45), lineWidth: Theme.Line.border)
                        }
                        .frame(width: nodeSize, height: nodeSize)
                        .shadow(color: WoodlandStyle.ink.opacity(0.18), radius: 8, y: 4)
                    if current || completed {
                        Image(systemName: completed ? "checkmark" : "leaf.fill")
                            .font(.title3.weight(Theme.Weight.action))
                            .foregroundStyle(current ? WoodlandStyle.ink : WoodlandStyle.sage)
                            .rotationEffect(.degrees(current && expanded && !reduceMotion ? -8 : 0))
                    } else {
                        Text(step.day.formatted())
                            .font(.title3.weight(Theme.Weight.action))
                            .foregroundStyle(Theme.textPrimary.color)
                    }
                }
                .frame(height: 80)
                .anchorPreference(key: PathStopAnchors.self, value: .bounds) { [step.id: $0] }
                .accessibilityHidden(true)

                VStack(spacing: 6) {
                    HStack(spacing: 5) {
                        if locked { Image(systemName: "lock.fill").accessibilityHidden(true) }
                        Text(current ? Copy.Path.currentLocation : Copy.Path.stepLabel(day: step.day))
                        if !locked {
                            Image(systemName: "chevron.down")
                                .rotationEffect(.degrees(expanded ? 180 : 0))
                                .accessibilityHidden(true)
                        }
                    }
                    .font(.caption.weight(Theme.Weight.emphasis))
                    .foregroundStyle(WoodlandStyle.secondaryInk)
                    Text(verbatim: step.title)
                        .font(current ? .headline.weight(Theme.Weight.title) : .subheadline.weight(Theme.Weight.emphasis))
                        .foregroundStyle(WoodlandStyle.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if viewModel.isMeasurementDay(step) {
                        Text(Copy.Path.measurementNote)
                            .font(.caption.weight(Theme.Weight.emphasis))
                            .foregroundStyle(WoodlandStyle.secondaryInk)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(WoodlandStyle.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: WoodlandStyle.ink.opacity(0.12), radius: 10, y: 4)
                .frame(maxWidth: accessible ? .infinity : currentX == 0.5 ? 240 : .infinity)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PathStopButtonStyle())
        .disabled(locked)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(verbatim: accessibilityState))
        .accessibilityHint(locked ? Text(Copy.Path.lockedHint) : Text(expanded ? Copy.Path.collapseDetails : Copy.Path.expandDetails))
    }

    private var accessibilityState: String {
        if locked { return String(localized: Copy.Path.lockedAccessibility) }
        let disclosure = String(localized: expanded ? Copy.Path.detailsExpanded : Copy.Path.detailsCollapsed)
        return completed ? String(localized: Copy.Path.completedNote) + ". " + disclosure : disclosure
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let phase = viewModel.phase(for: step) {
                Text(phase.label).font(.caption.weight(Theme.Weight.emphasis))
            }
            if let techniques = viewModel.techniques(for: step), techniques != step.title {
                Text(verbatim: techniques)
                    .font(.subheadline.weight(Theme.Weight.body))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if viewModel.isMeasurementDay(step) {
                Text(Copy.Path.measurementNotice)
                    .font(.footnote.weight(Theme.Weight.body))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: onStart) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill").font(.caption.weight(Theme.Weight.action)).accessibilityHidden(true)
                    Text(completed ? Copy.Path.replayCTA : Copy.Path.continueCTA)
                        .font(.body.weight(Theme.Weight.action))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: 24)
                .padding(.horizontal, 16).padding(.vertical, 16)
                .foregroundStyle(WoodlandStyle.paper)
                .background(WoodlandStyle.ink, in: Capsule())
            }
            .buttonStyle(.calm)
            .disabled(locked)
        }
        .foregroundStyle(WoodlandStyle.ink)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WoodlandStyle.paper, in: RoundedRectangle(cornerRadius: 24))
    }
}

/// Locked stops retain readable titles; availability is conveyed by lock and text.
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

/// One cubic per pair of actual node centers; no row-boundary corners.
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
