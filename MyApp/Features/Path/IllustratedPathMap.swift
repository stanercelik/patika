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
/// ## Bir durak açık, kalanı kompakt
///
/// Yalnızca bugünün durağı geniş; önceki ve sonraki duraklar adlarından ibaret
/// küçük tabelalar (ürün sahibi kararı, 2026-09-17). Hepsini aynı boyda çizmek
/// ekranı eşit ağırlıkta yirmi bir kutuya bölüyordu ve bugünün hangisi olduğu
/// okunmuyordu. Küçük tabelaya dokunmak onu açıyor, tekrar dokunmak kapatıyor —
/// **açmak okumaktır**, başlatmak değil: kilitli bir adımın ayrıntısı görünür,
/// "Kaldığın yerden" butonu yine basılamaz.
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
        .signpostRoute(ids: viewModel.steps.map(\.id))
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

    /// Bugünün durağı ya da açılmış bir durak geniş çizilir; kalanı kompakt.
    private var isOpen: Bool { current || expanded }

    private var nodeSize: CGFloat { current ? 72 : 46 }
    /// Etiketin düğümün altına girdiği pay. Siluetin tek parça okunması buna
    /// bağlı: boşluk kaldığı an iki ayrı nesne görünüyor.
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
        .animation(expandAnimation, value: expanded)
    }

    /// Düğüm + etiket tek gövde. Negatif aralık etiketi düğümün altına sokuyor;
    /// `zIndex` düğümü üstte tutuyor ki daire etiketin kenarında kesilmesin.
    private var signpost: some View {
        VStack(spacing: -tuck) {
            nodeButton
                .zIndex(1)
            label
        }
        .frame(maxWidth: .infinity)
    }

    /// Yuvarlak da açıp kapatıyor (ürün sahibi kararı, 2026-09-17). Etiket ile
    /// düğüm tek nesne olduğuna göre dokunma alanı da tek olmalı; yalnızca
    /// yazıya basılabilmesi, dairenin süs olduğunu ima ediyordu.
    ///
    /// Yardımcı teknolojiden gizli: aynı işi yapan iki öğe VoiceOver'da listeyi
    /// ikiye katlardı. Etiket butonu tam etiketi ve ipucunu zaten taşıyor.
    private var nodeButton: some View {
        Button(action: toggle) {
            nodeMark
        }
        .buttonStyle(SignpostStopButtonStyle())
        .accessibilityHidden(true)
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
                // Gün sayısı yalnızca burada yazıyor; etiket onu tekrar etmiyor.
                Text(step.day.formatted())
                    .font(Theme.TypeFace.nodeMarkCompact)
                    .foregroundStyle(Theme.textPrimary.color)
            }
        }
        .frame(width: nodeSize + 18, height: nodeSize + 18)
        .signpostNode(id: step.id)
    }

    /// Özet ile ayrıntı **aynı** kâğıdın üstünde: açılınca yeni bir kart
    /// belirmiyor, tabela uzuyor.
    private var label: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggle) {
                summary
            }
            .buttonStyle(SignpostStopButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityValue(Text(verbatim: accessibilityState))
            .accessibilityHint(Text(expanded ? Copy.Path.collapseDetails : Copy.Path.expandDetails))

            if expanded {
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
                    Text(Copy.Path.currentLocation)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .font(Theme.TypeFace.cardMeta)
                .foregroundStyle(WoodlandStyle.secondaryInk)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if locked && !current {
                    Image(systemName: "lock.fill")
                        .font(Theme.TypeFace.lockMark)
                        .foregroundStyle(WoodlandStyle.secondaryInk)
                        .accessibilityHidden(true)
                }
                Text(verbatim: step.title)
                    .font(current ? Theme.TypeFace.cardTitleProminent : Theme.TypeFace.cardTitle)
                    .foregroundStyle(locked && !current ? WoodlandStyle.ink.opacity(0.72) : WoodlandStyle.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if viewModel.isMeasurementDay(step), isOpen {
                Text(Copy.Path.measurementNote)
                    .font(Theme.TypeFace.cardMeta)
                    .foregroundStyle(WoodlandStyle.secondaryInk)
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

    private var accessibilityState: String {
        let disclosure = String(localized: expanded ? Copy.Path.detailsExpanded : Copy.Path.detailsCollapsed)
        if locked {
            return String(localized: Copy.Path.lockedAccessibility) + ". " + disclosure
        }
        return completed
            ? String(localized: Copy.Path.completedNote) + ". " + disclosure
            : disclosure
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

            if locked {
                // Kilitli adımda buton yok: basılamayan bir buton, kapalı olanın
                // ne olduğunu anlatmak yerine kullanıcıyı denemeye davet ediyordu.
                Text(Copy.Path.lockedHint)
                    .font(Theme.TypeFace.cardMeta)
                    .foregroundStyle(WoodlandStyle.secondaryInk)
            } else {
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
            }
        }
        .foregroundStyle(WoodlandStyle.ink)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggle() {
        Theme.softHaptic(intensity: 0.25)
        withAnimation(expandAnimation) { viewModel.toggle(step) }
    }
}
