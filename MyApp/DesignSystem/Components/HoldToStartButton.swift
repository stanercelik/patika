import SwiftUI
import UIKit

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
/// ## Buton ekranı kaplar (ürün sahibi kararı, 2026-09-09)
///
/// Basılı tutuldukça buton bir kapsülden başlayıp **tüm ekranı dolduran** bir
/// alana büyür ve dolgusu paletin kendi rengiyle gradyanlıdır. İki iş birden
/// yapıyor:
///
/// - **Geri sayım görünür oluyor.** Önceki hâlde buton yalnızca %14 büyüyordu;
///   bekleme süresinin nerede olduğunu yalnızca haptik söylüyordu ve parmağını
///   erken çeken kullanıcı bir şey olmadığını sanıyordu.
/// - **Geçişin örtüsü oluyor.** Dolgu tamamlandığında ekran zaten kaplı; F2'den
///   G1'e geçiş bu ışığın altında oluyor, iki ekran arasında boşluk görünmüyor.
///
/// Gradyan arka planın **akrabası ama aynısı değil**: paletin en parlak noktası
/// kırık beyazla karıştırılıyor, yani ton kategoriden geliyor ama luminans yukarı
/// çıkıyor. Koyu arka planın üstünde açık bir alan olarak ayrılıyor ve siyah
/// buton metni büyüme boyunca okunur kalıyor — kontrast kilidinin (Görsel Sistem
/// eki §3.4) buradaki karşılığı bu.
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
/// dolgu soldan sağa ilerler — bekleme yine var, ekranı yutan hareket yok.
struct HoldToStartButton: View {
    let title: LocalizedStringResource
    /// Butonun altında duran tek satırlık kullanım ipucu. Jest görünmez olduğu
    /// için yazıyla söylenmek zorunda.
    let hint: LocalizedStringResource
    let action: () -> Void

    /// Tetiklenme için gereken süre. 1.4 sn: kazayla tutulacak kadar kısa değil,
    /// beklerken sıkıcı olacak kadar uzun değil.
    private let holdDuration: TimeInterval = 1.4

    @Environment(PaletteController.self) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var progress: Double = 0
    @State private var isHolding = false
    @State private var isCompleted = false
    @State private var holdTask: Task<Void, Never>?
    /// Butonun ekrandaki yeri — büyüyen dolgunun ekran merkezine doğru
    /// kaymasını hesaplamak için gerekiyor. Buton altta duruyor; olduğu yerde
    /// büyüseydi üst köşeleri boş kalırdı.
    @State private var buttonFrame: CGRect = .zero

    var body: some View {
        VStack(spacing: 10) {
            label
                .background {
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { buttonFrame = geo.frame(in: .global) }
                            .onChange(of: geo.frame(in: .global)) { _, new in
                                buttonFrame = new
                            }
                    }
                }
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
                .foregroundStyle(Theme.textPrimary.color.opacity(hintOpacity))
                .accessibilityHidden(true)
        }
        .onDisappear { holdTask?.cancel() }
    }

    private var label: some View {
        Text(title)
            .font(.body.weight(Theme.Weight.action))
            .foregroundStyle(Color.black)
            // Metin dolgu büyürken sahnede kalır ama sonda çekilir: ekranı
            // kaplamış bir ışığın ortasındaki "Yola çık" yazısı, geçilmiş bir
            // eşiği hâlâ bir buton gibi gösteriyordu.
            .opacity(labelOpacity)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(alignment: .center) { fill }
            .contentShape(Capsule())
    }

    /// Kapsülden ekranı kaplayan alana büyüyen dolgu.
    ///
    /// Parent kırpmıyor, bu yüzden şekil butonun çerçevesinin dışına taşabiliyor
    /// ve ayrı bir tam ekran katmanına (overlay / fullScreenCover) gerek kalmıyor —
    /// öyle olsaydı dolgu ile buton iki ayrı animasyon olurdu ve senkronu kayardı.
    @ViewBuilder
    private var fill: some View {
        if reduceMotion {
            ZStack {
                Capsule().fill(gradient)
                // Reduce Motion'da büyümenin yerini alan sinyal: mürekkep
                // soldan sağa doluyor, buton yerinde duruyor.
                GeometryReader { geo in
                    Capsule()
                        .fill(Color.black.opacity(0.14))
                        .frame(width: geo.size.width * progress)
                }
            }
            .clipShape(Capsule())
        } else {
            GeometryReader { geo in
                let rest = geo.size
                let expanded = expandedDiameter
                let width = rest.width + (expanded - rest.width) * eased
                let height = rest.height + (expanded - rest.height) * eased

                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(gradient)
                    .frame(width: width, height: height)
                    .offset(y: centerOffset * eased)
                    .position(x: rest.width / 2, y: rest.height / 2)
            }
        }
    }

    /// Paletin en parlak noktası kırık beyaza karıştırılıyor: ton kategoriden,
    /// luminans metin renginden. Arka planla akraba, arka plandan ayrık.
    private var gradient: LinearGradient {
        let base = Theme.textPrimary
        let accent = palette.current.spots.max(by: { $0.relativeLuminance < $1.relativeLuminance })
            ?? Theme.textPrimary
        return LinearGradient(
            colors: [
                base.mixed(with: accent, amount: 0.14).color,
                base.mixed(with: accent, amount: 0.58).color,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Geometri

    /// Ekranı her yönden kapatan çap. Buton ekranın altında olduğu için
    /// köşegen yetmiyor: dolgu ekran merkezine kayarken bile en uzak köşeye
    /// ulaşmak zorunda.
    private var expandedDiameter: CGFloat {
        let screen = HoldToStartButton.screenSize
        return hypot(screen.width, screen.height) * 1.25
    }

    /// Butonun merkezinden ekranın merkezine olan dikey mesafe.
    private var centerOffset: CGFloat {
        guard buttonFrame != .zero else { return 0 }
        return HoldToStartButton.screenSize.height / 2 - buttonFrame.midY
    }

    /// Büyüme baştan yavaş, sonda hızlı: doğrusal büyüme ilk yarısında ekranı
    /// çoktan kaplıyor ve kalan bekleme boşa geçiyordu.
    private var eased: CGFloat {
        let p = CGFloat(progress)
        return p * p
    }

    private var labelOpacity: Double {
        guard !reduceMotion else { return 1 }
        return progress < 0.72 ? 1 : max(0, 1 - (progress - 0.72) / 0.28)
    }

    private var hintOpacity: Double {
        0.55 * max(0, 1 - progress * 2.2)
    }

    @MainActor
    private static var screenSize: CGSize {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.size
            ?? CGSize(width: 430, height: 932)
    }

    // MARK: - Jest

    private func beginHold() {
        guard !isHolding, !isCompleted else { return }
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
        guard isHolding, !isCompleted else { return }
        isHolding = false

        // Bırakınca aynı yoldan geri iner: büyüme ne kadar sürdüyse küçülme de
        // o ölçüde yumuşak. Sert bir "pat" geri dönüş, iptali hata gibi gösterir.
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            progress = 0
        }
    }

    private func complete() {
        guard !isCompleted else { return }
        isCompleted = true
        holdTask?.cancel()
        holdTask = nil
        isHolding = false
        Theme.softHaptic(intensity: 1.0)
        // Dolgu **geri inmiyor**: ekran kaplı hâlde kalıyor ve F2→G1 geçişi bu
        // ışığın altında oluyor. Geri indirmek, kaplanan ekranı bir anda geri
        // verip iki ekran arasında boşluk gösterirdi.
        withAnimation(.easeOut(duration: 0.18)) {
            progress = 1
        }
        action()
    }
}

#Preview {
    @Previewable @State var palette = PaletteController()

    return ZStack {
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
    .environment(palette)
    .preferredColorScheme(.dark)
    .task { palette.select([.sleep]) }
}
