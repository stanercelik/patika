import SwiftUI

/// D1'in 0–10 şiddet ölçeği (PRD-Ek Onboarding §5).
///
/// ## Neden kaydırıcı değil, basamak
///
/// `Slider` sürekli bir değer üretir ve kullanıcıyı "doğru yeri bulmaya"
/// zorlar — kaygılı kullanıcıda tam istemediğimiz tereddüt. Onbir ayrı basamak
/// hem dokunmayla hem sürüklemeyle seçilebiliyor; her ikisinde de cevap kesin.
///
/// ## Yükselen çubuklar
///
/// Çubuk yükseklikleri soldan sağa artar: ölçeğin yönünü sayı okumadan
/// gösteriyor. Yön iki uçtaki etiketle de yazılı — biçim tek başına anlam
/// taşımıyor (Ton eki §7).
///
/// **Seçili değer sayıyla da yazılır.** Bu bir skor değil, kullanıcının kendi
/// cevabı; skor gösterme yasağı (PRD §7.3) ölçüm sonucuna dair, girdiye değil.
struct IntensityScale: View {
    /// 0…10. Nil = henüz dokunulmadı; varsayılan bir değer **yok**, çünkü
    /// önceden doldurulmuş bir cevap ölçümü kirletir.
    let selection: Double?
    let onSelect: (Double) -> Void

    var lowLabel: LocalizedStringResource = .intensityScaleLow
    var highLabel: LocalizedStringResource = .intensityScaleHigh

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var maximumBarHeight: CGFloat = 56
    @ScaledMetric(relativeTo: .body) private var minimumBarHeight: CGFloat = 18

    private var steps: [Int] { Array(MeasurementLibrary.intensityRange) }
    private var selectedStep: Int? { selection.map { Int($0.rounded()) } }

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: barSpacing) {
                    ForEach(steps, id: \.self) { step in
                        bar(step)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .contentShape(Rectangle())
                .gesture(
                    // `minimumDistance: 0` sayesinde tek dokunuş da sürükleme de
                    // aynı yoldan geçiyor; iki ayrı jest yazmak ikisinin zamanla
                    // ayrışması demekti.
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in select(at: value.location.x, width: geo.size.width) }
                )
            }
            .frame(height: maximumBarHeight)

            HStack {
                Text(lowLabel)
                Spacer(minLength: 8)
                Text(highLabel)
            }
            .font(.caption.weight(Theme.Weight.emphasis))
            .foregroundStyle(Theme.textPrimary.color.opacity(0.52))

            // Yer her zaman ayrılır: cevap verildiğinde satır zıplamasın.
            Text(selectedStep.map { "\($0)" } ?? " ")
                .font(.title3.weight(Theme.Weight.title))
                .foregroundStyle(Theme.textPrimary.color)
                .opacity(selectedStep == nil ? 0 : 1)
                .animation(reduceMotion ? nil : Theme.Motion.crossFade, value: selectedStep)
        }
        .accessibilityElement()
        .accessibilityLabel(.intensityScaleAccessibility)
        .accessibilityValue(selectedStep.map { Text(verbatim: "\($0)") } ?? Text(.intensityScaleNotSelected))
        .accessibilityAdjustableAction { direction in
            let current = selectedStep ?? 0
            switch direction {
            case .increment: onSelect(Double(min(current + 1, steps.count - 1)))
            case .decrement: onSelect(Double(max(current - 1, 0)))
            @unknown default: break
            }
        }
    }

    private var barSpacing: CGFloat { 6 }

    private func bar(_ step: Int) -> some View {
        let isFilled = selectedStep.map { step <= $0 } ?? false
        let isSelected = selectedStep == step
        let ratio = Double(step) / Double(steps.count - 1)
        let height = minimumBarHeight + (maximumBarHeight - minimumBarHeight) * ratio

        return RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(Theme.textPrimary.color.opacity(isFilled ? 0.85 : 0.14))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(
                        Theme.textPrimary.color.opacity(isSelected ? 1 : 0),
                        lineWidth: Theme.Line.border
                    )
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .animation(reduceMotion ? nil : Theme.Motion.crossFade, value: isFilled)
    }

    private func select(at x: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        let ratio = min(max(x / width, 0), 1)
        let step = Int((ratio * CGFloat(steps.count - 1)).rounded())
        guard Double(step) != selection else { return }
        Theme.softHaptic()
        onSelect(Double(step))
    }
}

#Preview {
    ZStack {
        WoodlandStyle.background.ignoresSafeArea()
        VStack(spacing: 48) {
            IntensityScale(selection: nil) { _ in }
            IntensityScale(selection: 7) { _ in }
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
    .preferredColorScheme(.dark)
}
