import SwiftUI

/// Basılı tutularak tetiklenen birincil buton — F2'nin "Yola çık"ı.
///
/// ## Neden basılı tutma
///
/// Bu dokunuş onboarding'in sonu ve ilk oturumun başı; tek bir yanlış dokunuşla
/// geçilecek bir eşik değil. Ürün bu kalıbı zaten tanıyor: SOS butonu da basılı
/// tutulunca büyür ve bırakılınca çalışır (Ton eki §2.2) — kaza koruması ve
/// fiziksel rahatlama aynı anda.
///
/// Bekleme bir engel değil, bir **an**: buton parmağın altında büyürken haptik
/// nabız hızlanıyor. Kullanıcı kararı tutarak veriyor, dokunarak değil.
///
/// ## Haptik tek kademe kalır
///
/// Ton eki §7: haptik tek seviyedir, `.soft`. Titreşim hissi stil değiştirerek
/// değil, **şiddet ve sıklık** artırılarak kuruluyor — aynı yumuşak vuruş, gitgide
/// sıklaşan ve kuvvetlenen bir nabız. `.rigid` / `.success` kullanılmıyor.
///
/// ## Erişilebilirlik
///
/// VoiceOver ve Switch Control kullanıcısı "basılı tutma" jestini üretemez.
/// Buton bu yüzden normal bir `Button` gibi de etkinleşir: yardımcı teknolojiden
/// gelen etkinleştirme beklemeden çalışır. Reduce Motion'da büyüme yok, yerine
/// dolgu ilerler — bekleme yine var, hareket yok.
struct HoldToStartButton: View {
    let title: LocalizedStringResource
    /// Butonun altında duran tek satırlık kullanım ipucu. Jest görünmez olduğu
    /// için yazıyla söylenmek zorunda.
    let hint: LocalizedStringResource
    let action: () -> Void

    /// Tetiklenme için gereken süre. 1.4 sn: kazayla tutulacak kadar kısa değil,
    /// beklerken sıkıcı olacak kadar uzun değil.
    private let holdDuration: TimeInterval = 1.4
    /// Büyüme oranı. Daha fazlası butonu ekran kenarlarına taşırıyor.
    private let maximumScale: CGFloat = 1.14

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var progress: Double = 0
    @State private var isHolding = false
    @State private var holdTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 10) {
            label
                .scaleEffect(reduceMotion ? 1 : 1 + (maximumScale - 1) * progress)
                .animation(.easeOut(duration: 0.28), value: progress == 0)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in beginHold() }
                        .onEnded { _ in cancelHold() }
                )
                // Yardımcı teknolojiler için düz bir buton gibi davranır.
                .accessibilityElement()
                .accessibilityLabel(Text(title))
                .accessibilityHint(Text(hint))
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { complete() }

            Text(hint)
                .font(.footnote.weight(Theme.Weight.emphasis))
                .foregroundStyle(Theme.textPrimary.color.opacity(0.55))
                .accessibilityHidden(true)
        }
        .onDisappear { holdTask?.cancel() }
    }

    private var label: some View {
        Text(title)
            .font(.body.weight(Theme.Weight.action))
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                ZStack {
                    Capsule().fill(Theme.textPrimary.color)
                    // Reduce Motion'da büyümenin yerini alan sinyal: mürekkep
                    // soldan sağa doluyor, buton yerinde duruyor.
                    if reduceMotion {
                        GeometryReader { geo in
                            Capsule()
                                .fill(Color.black.opacity(0.14))
                                .frame(width: geo.size.width * progress)
                        }
                    }
                }
            }
            .clipShape(Capsule())
            .contentShape(Capsule())
    }

    // MARK: - Jest

    private func beginHold() {
        guard !isHolding else { return }
        isHolding = true

        holdTask = Task { @MainActor in
            let step: TimeInterval = 1.0 / 60.0
            var elapsed: TimeInterval = 0
            var nextPulse: TimeInterval = 0

            while elapsed < holdDuration {
                try? await Task.sleep(for: .seconds(step))
                guard !Task.isCancelled else { return }
                elapsed += step
                progress = min(elapsed / holdDuration, 1)

                // Nabız hızlanır: başta ~180 ms'de bir, sonda ~70 ms'de bir; her
                // vuruş bir öncekinden biraz daha kuvvetli. Tek stil, artan şiddet.
                if elapsed >= nextPulse {
                    Theme.softHaptic(intensity: 0.35 + progress * 0.55)
                    nextPulse = elapsed + 0.18 - progress * 0.11
                }
            }

            complete()
        }
    }

    private func cancelHold() {
        holdTask?.cancel()
        holdTask = nil
        guard isHolding else { return }
        isHolding = false

        // Bırakınca aynı yoldan geri iner: büyüme ne kadar sürdüyse küçülme de
        // o ölçüde yumuşak. Sert bir "pat" geri dönüş, iptali hata gibi gösterir.
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            progress = 0
        }
    }

    private func complete() {
        holdTask?.cancel()
        holdTask = nil
        isHolding = false
        Theme.softHaptic(intensity: 1.0)
        withAnimation(.spring(response: 0.30, dampingFraction: 0.72)) {
            progress = 0
        }
        action()
    }
}

#Preview {
    ZStack {
        BreathingMeshBackground(palette: Palette.all["sleep"]!, safeY: 0.80)
        VStack {
            Spacer()
            HoldToStartButton(
                title: Copy.Button.start,
                hint: Copy.Onboarding.holdToStartHint
            ) {}
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.bottom, 24)
        }
    }
    .preferredColorScheme(.dark)
}
