import SwiftUI

/// Taahhüt anı: kullanıcının kendi sözünün üstünde, kaydırarak onaylanan bir jest.
///
/// `PrimaryButton` ile aynı malzeme ve yükseklik (kırık beyaz hap, koyu metin);
/// alt bölge ekrandan ekrana zıplamasın diye. `HoldToStartButton`ın kalıbını izler:
/// haptik tek kademe (`.soft`), yalnızca `intensity` ilerlemeyle artar; VoiceOver
/// ve Switch Control sürükleme üretemediği için düğme gibi etkinleşir ve beklemeden
/// tamamlar; Reduce Motion'da iğne yaylanmaz.
///
/// Yarıda bırakılırsa iğne geri döner ve **hiçbir şey olmaz**: bu bir sınav değil.
struct CommitmentSlide: View {
    let title: LocalizedStringResource
    let accessibilityTitle: LocalizedStringResource
    let onCommit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var trackHeight: CGFloat = 60
    @State private var progress: CGFloat = 0
    @State private var didCommit = false
    @State private var lastHapticStep = 0

    private let completionThreshold: CGFloat = 0.92

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            // Büyük yazıda iğne metnin yerini yer ve sürükleme yardımcı teknolojiler için
            // zaten bir cevap yolu değil: aynı söz, düz bir düğmeyle verilir.
            PrimaryButton(title: accessibilityTitle) { complete() }
        } else {
            slider
        }
    }

    private var slider: some View {
        GeometryReader { geo in
            let thumb = trackHeight - 12
            let travel = max(geo.size.width - thumb - 12, 1)

            ZStack(alignment: .leading) {
                Capsule().fill(Theme.textPrimary.color)

                // Geçilen yol koyu dolar: ilerleme okunur, sayı yok.
                if progress > 0.001 {
                    Capsule()
                        .fill(WoodlandStyle.ink.opacity(0.9))
                        .frame(width: 6 + thumb + travel * progress)
                        .frame(maxHeight: .infinity)
                }

                Text(title)
                    .font(.body.weight(Theme.Weight.action))
                    .foregroundStyle(Color.black.opacity(1 - Double(progress) * 1.4))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, thumb + 12)
                    .padding(.trailing, 12)

                Circle()
                    .fill(WoodlandStyle.ink)
                    .overlay {
                        Image(systemName: didCommit ? "checkmark" : "chevron.right")
                            .font(.body.weight(Theme.Weight.action))
                            .foregroundStyle(WoodlandStyle.paper)
                    }
                    .frame(width: thumb, height: thumb)
                    .offset(x: 6 + travel * progress)
            }
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !didCommit else { return }
                        let next = min(max((value.location.x - thumb / 2 - 6) / travel, 0), 1)
                        progress = next
                        rampHaptic(next)
                    }
                    .onEnded { _ in
                        guard !didCommit else { return }
                        if progress >= completionThreshold { complete() } else { reset() }
                    }
            )
        }
        .frame(height: trackHeight)
        .accessibilityElement()
        .accessibilityLabel(Text(accessibilityTitle))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { complete() }
    }

    private func rampHaptic(_ value: CGFloat) {
        let step = Int(value * 8)
        guard step != lastHapticStep else { return }
        lastHapticStep = step
        Theme.softHaptic(intensity: 0.35 + Double(value) * 0.55)
    }

    private func complete() {
        guard !didCommit else { return }
        didCommit = true
        withAnimation(reduceMotion ? nil : Theme.Motion.crossFade) { progress = 1 }
        Theme.softHaptic(intensity: 1.0)
        onCommit()
    }

    private func reset() {
        lastHapticStep = 0
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : Theme.Motion.press) { progress = 0 }
    }
}
