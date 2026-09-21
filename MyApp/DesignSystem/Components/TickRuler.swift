import SwiftUI

/// Ayrık duraklı cetvel: sıralı bir cevap kümesini bir çizgi üstünde seçtirir.
///
/// `IntensityScale` gibi dokunma ile sürükleme **aynı yoldan** geçer
/// (`DragGesture(minimumDistance: 0)`), cevap her zaman bir duraktır; sürekli bir
/// değer yok, çünkü `Slider` "doğru yeri bulmaya" zorlar ve kaygılı kullanıcıda
/// tereddüt üretir.
///
/// Sözleşme diğer girdilerle aynı (`docs/onboarding-redesign.md`, Bölüm 4):
/// `@Binding` yok (`selection` + `onSelect`), **varsayılan seçim yok** (kullanıcı
/// dokunana kadar iğne çizilmez), haptik bileşenin içinde, ölçüler `@ScaledMetric`,
/// VoiceOver için ayarlanabilir eylem.
///
/// Mürekkep ortamdan (`patikaInk`) okunur: kâğıtta koyu, zeminde açık.
struct TickRuler: View {
    /// Durak sayısı, en az 2.
    let count: Int
    /// 0 tabanlı. Nil = henüz dokunulmadı.
    let selection: Int?
    let onSelect: (Int) -> Void
    var accessibilityLabel: LocalizedStringResource
    /// VoiceOver'ın okuyacağı değer (durağın adı).
    var accessibilityValue: (Int) -> String
    /// Seçili durağa kadar olan çizgiyi doldurur. Sıralı "ne kadar" cevaplarında
    /// (süre) anlamlı; "hangi aralık" cevaplarında (yaş) çizgi bir karşılaştırma
    /// ima eder, kapalı tutulur.
    var fillsTrack = true

    @Environment(\.patikaInk) private var ink
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 44
    @ScaledMetric(relativeTo: .body) private var thumbDiameter: CGFloat = 26

    var body: some View {
        GeometryReader { geo in
            let inset = thumbDiameter / 2
            let usable = max(geo.size.width - inset * 2, 1)
            let midY = geo.size.height / 2

            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(ink.primary.opacity(0.18))
                    .frame(width: usable, height: 4)
                    .position(x: geo.size.width / 2, y: midY)

                if fillsTrack, let selection {
                    Capsule()
                        .fill(ink.primary.opacity(0.75))
                        .frame(width: usable * fraction(selection), height: 4)
                        .position(x: inset + usable * fraction(selection) / 2, y: midY)
                }

                ForEach(0..<count, id: \.self) { index in
                    Circle()
                        .fill(ink.primary.opacity(isReached(index) ? 0.9 : 0.32))
                        .frame(width: 8, height: 8)
                        .position(x: inset + usable * fraction(index), y: midY)
                }

                if let selection {
                    Circle()
                        .fill(ink.primary)
                        .overlay { Circle().strokeBorder(ink.secondary.opacity(0.35), lineWidth: Theme.Line.border) }
                        .frame(width: thumbDiameter, height: thumbDiameter)
                        .position(x: inset + usable * fraction(selection), y: midY)
                        .animation(reduceMotion ? nil : Theme.Motion.crossFade, value: selection)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in select(at: value.location.x, inset: inset, usable: usable) }
            )
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityValue(selection.map { Text(verbatim: accessibilityValue($0)) } ?? Text(.intensityScaleNotSelected))
        .accessibilityAdjustableAction { direction in
            let current = selection ?? -1
            switch direction {
            case .increment: commit(min(current + 1, count - 1))
            case .decrement: commit(max(current - 1, 0))
            @unknown default: break
            }
        }
    }

    private func fraction(_ index: Int) -> CGFloat {
        count > 1 ? CGFloat(index) / CGFloat(count - 1) : 0
    }

    private func isReached(_ index: Int) -> Bool {
        guard fillsTrack, let selection else { return false }
        return index <= selection
    }

    private func select(at x: CGFloat, inset: CGFloat, usable: CGFloat) {
        let ratio = min(max((x - inset) / usable, 0), 1)
        commit(Int((ratio * CGFloat(count - 1)).rounded()))
    }

    private func commit(_ index: Int) {
        guard index != selection, (0..<count).contains(index) else { return }
        Theme.softHaptic()
        onSelect(index)
    }
}

#Preview("Cetvel") {
    ZStack {
        BreathingMeshBackground(palette: .neutral, safeY: 0.30)
        VStack(alignment: .leading, spacing: 32) {
            TickRuler(count: 4, selection: nil, onSelect: { _ in }, accessibilityLabel: .problemDurationSliderAccessibility, accessibilityValue: { "\($0)" })
            TickRuler(count: 5, selection: 2, onSelect: { _ in }, accessibilityLabel: .problemDurationSliderAccessibility, accessibilityValue: { "\($0)" }, fillsTrack: false)
        }
        .padding(PatikaSurfaceMetrics.padding)
        .paperSurface()
        .environment(\.patikaInk, .ink)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
    .preferredColorScheme(.dark)
}
