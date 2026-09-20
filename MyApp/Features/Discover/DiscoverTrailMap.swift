import SwiftUI

/// Patikanın adımları — "Yolum"un tabela rotasıyla aynı dil: duraklar merkezin iki
/// yanında sırayla, aradaki olukta kesintisiz yol (`SignpostRoute`).
///
/// Yolum'dan farkı yalnızca veri: hazır patikada gün, faz, ölçüm ve kişisel
/// teknik yok; durak bir adımın adı ve durumundan ibaret. Durak görünümü
/// `IllustratedPathStop`un ikizi; ortak olan rota çizimi ve basma stili
/// paylaşılıyor.
///
/// **Açmak okumaktır, başlatmak değil:** önizlemede ve kilitli adımda ayrıntı
/// açılır ama oturum başlatılamaz.
struct DiscoverTrailMap: View {
    let path: DiscoverPath
    let isPreview: Bool
    @Binding var expandedStepID: String?
    let onStart: (DiscoverStep) -> Void

    @Environment(DiscoverLibrary.self) private var library
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(path.steps.enumerated()), id: \.element.id) { index, step in
                DiscoverTrailStop(
                    step: step,
                    number: index + 1,
                    state: state(of: step),
                    isExpanded: expandedStepID == step.id,
                    isLeading: dynamicTypeSize.isAccessibilitySize || index.isMultiple(of: 2),
                    audioIsReady: library.audioIsReady(path),
                    onToggle: { expandedStepID = expandedStepID == step.id ? nil : step.id },
                    onStart: { onStart(step) }
                )
                .id(step.id)
            }
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .signpostRoute(ids: path.steps.map(\.id))
    }

    private func state(of step: DiscoverStep) -> DiscoverTrailStop.State {
        if isPreview { return .preview }
        if library.isComplete(step, in: path) { return .done }
        return library.nextStep(path)?.id == step.id ? .current : .locked
    }
}

struct DiscoverTrailStop: View {
    enum State: Equatable {
        /// Katılmadan önce: durum yok, yalnızca numara.
        case preview
        case current
        case done
        case locked
    }

    let step: DiscoverStep
    let number: Int
    let state: State
    let isExpanded: Bool
    let isLeading: Bool
    let audioIsReady: Bool
    let onToggle: () -> Void
    let onStart: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var current: Bool { state == .current }
    private var completed: Bool { state == .done }
    private var locked: Bool { state == .locked }
    private var accessible: Bool { dynamicTypeSize.isAccessibilitySize }
    /// Sıradaki durak ya da açılmış bir durak geniş çizilir; kalanı kompakt.
    private var isOpen: Bool { current || isExpanded }

    private var nodeSize: CGFloat { current ? 72 : 46 }
    /// Etiketin düğümün altına girdiği pay: siluetin tek parça okunması buna bağlı.
    private var tuck: CGFloat { current ? 20 : 14 }
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
        .padding(.top, current ? 20 : 12)
        .padding(.bottom, isOpen ? 44 : 26)
        .animation(expandAnimation, value: isExpanded)
    }

    private var signpost: some View {
        VStack(spacing: -tuck) {
            Button(action: toggle) { nodeMark }
                .buttonStyle(SignpostStopButtonStyle())
                // Aynı işi yapan iki öğe VoiceOver listesini ikiye katlardı.
                .accessibilityHidden(true)
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

            if current {
                Image(systemName: "leaf.fill")
                    .font(Theme.TypeFace.nodeMark)
                    .foregroundStyle(WoodlandStyle.ink)
            } else if completed {
                Image(systemName: "checkmark")
                    .font(Theme.TypeFace.nodeMarkCompact)
                    .foregroundStyle(WoodlandStyle.sage)
            } else {
                Text(number.formatted())
                    .font(Theme.TypeFace.nodeMarkCompact)
                    .foregroundStyle(Theme.textPrimary.color)
            }
        }
        .frame(width: nodeSize + 18, height: nodeSize + 18)
        .signpostNode(id: step.id)
    }

    /// Özet ile ayrıntı **aynı** kâğıdın üstünde: açılınca yeni bir kart belirmiyor,
    /// tabela uzuyor.
    private var label: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggle) { summary }
                .buttonStyle(SignpostStopButtonStyle())
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(verbatim: "\(DiscoverCopy.stepNumber(number)), \(step.title.value)"))
                .accessibilityValue(Text(verbatim: accessibilityState))
                .accessibilityHint(Text(verbatim: isExpanded ? DiscoverCopy.collapseHint : DiscoverCopy.expandHint))

            if isExpanded {
                detail
                    .transition(.opacity.combined(with: .offset(y: reduceMotion ? 0 : -6)))
            }
        }
        .background(
            WoodlandStyle.paper,
            in: RoundedRectangle(cornerRadius: isOpen ? 24 : 18, style: .continuous)
        )
        .shadow(color: WoodlandStyle.ink.opacity(isOpen ? 0.14 : 0.10), radius: isOpen ? 12 : 7, y: isOpen ? 5 : 3)
        // Kompakt tabela adının genişliği kadar; açılınca kolonu dolduruyor.
        .frame(maxWidth: isOpen || accessible ? .infinity : 232)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 5) {
            if current {
                HStack(spacing: 5) {
                    Text(verbatim: DiscoverCopy.now)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .font(Theme.TypeFace.cardMeta)
                .foregroundStyle(WoodlandStyle.secondaryInk)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if locked {
                    Image(systemName: "lock.fill")
                        .font(Theme.TypeFace.lockMark)
                        .foregroundStyle(WoodlandStyle.secondaryInk)
                        .accessibilityHidden(true)
                }
                Text(verbatim: step.title.value)
                    .font(current ? Theme.TypeFace.cardTitleProminent : Theme.TypeFace.cardTitle)
                    .foregroundStyle(locked ? WoodlandStyle.ink.opacity(0.72) : WoodlandStyle.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Düğümün altından başla: metin dairenin altında kalmasın.
        .padding(.top, tuck + (current ? 14 : 10))
        .padding(.horizontal, current ? 16 : 14)
        .padding(.bottom, current ? 14 : 12)
        .contentShape(Rectangle())
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 12) {
            PaperRowDivider()
            switch state {
            case .preview:
                Text(verbatim: DiscoverCopy.previewNote)
                    .font(Theme.TypeFace.cardMeta)
                    .foregroundStyle(WoodlandStyle.secondaryInk)
            case .locked:
                // Kilitli adımda buton yok: basılamayan bir buton denemeye davet eder.
                Text(verbatim: DiscoverCopy.nextLocked)
                    .font(Theme.TypeFace.cardMeta)
                    .foregroundStyle(WoodlandStyle.secondaryInk)
            case .current, .done:
                DiscoverAction(
                    title: completed ? DiscoverCopy.replay : DiscoverCopy.start,
                    enabled: audioIsReady,
                    surface: .paper,
                    action: onStart
                )
                if !audioIsReady {
                    Text(verbatim: DiscoverCopy.audioPreparing)
                        .font(Theme.TypeFace.cardMeta)
                        .foregroundStyle(WoodlandStyle.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .foregroundStyle(WoodlandStyle.ink)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accessibilityState: String {
        switch state {
        case .preview: ""
        case .current: DiscoverCopy.now
        case .done: DiscoverCopy.done
        case .locked: DiscoverCopy.nextLocked
        }
    }

    private func toggle() {
        Theme.softHaptic(intensity: 0.25)
        withAnimation(expandAnimation) { onToggle() }
    }
}
