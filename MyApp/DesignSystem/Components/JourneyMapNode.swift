import SwiftUI

/// Aktif düğüm ve aktif iz için tek 60 Hz nefes değerini üretir. Yalnızca
/// grafik overlay'ini sardığı için satır metni her karede yeniden hesaplanmaz.
struct JourneyMotionValueReader<Content: View>: View {
    var forcePaused = false
    @ViewBuilder let content: (Double) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State private var thermalState = ProcessInfo.processInfo.thermalState

    var body: some View {
        let policy = JourneyMotionPolicy(
            reduceMotion: reduceMotion || forcePaused,
            sceneIsActive: scenePhase == .active,
            lowPowerMode: lowPowerMode,
            thermalState: thermalState
        )

        TimelineView(.animation(
            minimumInterval: JourneyMotionPolicy.minimumInterval,
            paused: policy.pausesContinuousMotion
        )) { timeline in
            content(
                policy.pausesContinuousMotion
                    ? 0.5
                    : BreathCycle.value(
                        at: timeline.date.timeIntervalSinceReferenceDate,
                        amplitude: BreathAmplitude.ambient
                    )
            )
        }
        .onReceive(NotificationCenter.default.publisher(
            for: ProcessInfo.PowerStateDidChangeMessage.name
        )) { _ in
            let current = ProcessInfo.processInfo.isLowPowerModeEnabled
            if current != lowPowerMode { lowPowerMode = current }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: ProcessInfo.ThermalStateDidChangeMessage.name
        )) { _ in
            let current = ProcessInfo.processInfo.thermalState
            if current != thermalState { thermalState = current }
        }
    }
}

/// F2 ve Yolum'un dört durumlu, monokrom harita düğümü.
struct JourneyMapNode: View {
    let node: TrailNode
    let showsLock: Bool
    var breath: Double = 0.5

    @ScaledMetric(relativeTo: .body) private var pendingSize: CGFloat = 34
    @ScaledMetric(relativeTo: .body) private var activeSize: CGFloat = 50
    @ScaledMetric(relativeTo: .body) private var milestoneSize: CGFloat = 42
    @ScaledMetric(relativeTo: .body) private var doneSize: CGFloat = 36

    var body: some View {
        switch node {
        case .pending: pending
        case .active: active
        case .done: done
        case .milestone: milestone
        }
    }

    private var pending: some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.22))
            Circle().strokeBorder(
                Theme.textPrimary.color.opacity(0.30),
                lineWidth: Theme.Line.border
            )
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
        ZStack {
            Circle()
                .stroke(
                    Theme.textPrimary.color.opacity(0.16 + breath * 0.12),
                    lineWidth: 7 + breath
                )
                .scaleEffect(1 + breath * 0.04)
            Circle()
                .fill(Color.black.opacity(0.26))
                .overlay {
                    Circle().strokeBorder(
                        Theme.textPrimary.color.opacity(0.94),
                        lineWidth: Theme.Line.border
                    )
                }
            Circle()
                .fill(Theme.textPrimary.color)
                .frame(width: 12, height: 12)
        }
        .frame(width: resolvedActiveSize, height: resolvedActiveSize)
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
            Circle().fill(Color.black.opacity(0.22))
            Circle().strokeBorder(
                Theme.textPrimary.color.opacity(0.62),
                lineWidth: Theme.Line.border
            )
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

#Preview("Journey node states") {
    HStack(spacing: 24) {
        JourneyMapNode(node: .done, showsLock: false)
        JourneyMapNode(node: .active, showsLock: false, breath: 0.75)
        JourneyMapNode(node: .pending, showsLock: true)
        JourneyMapNode(node: .milestone, showsLock: true)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
