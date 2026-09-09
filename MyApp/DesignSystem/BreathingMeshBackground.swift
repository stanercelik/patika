import SwiftUI

/// Uygulamanın tek arka plan katmanı — PRD-Ek Görsel Sistem §2.1, §6.2.
///
/// Katman yapısı: `MeshGradient` (renk + hareket, sistem) → `.colorEffect` (grain +
/// metin scrim'i, Metal) → içerik. Toplam görsel varlık < 60 KB; video yok, üçüncü
/// parti render kütüphanesi yok.
struct BreathingMeshBackground: View {
    let palette: Palette
    /// Metin bloğunun dikey merkezi (0…1). Ekran bazlı değerler §7 tablosunda.
    var safeY: Float = 0.5
    /// Ekran grubuna göre nefes genliği — `BreathAmplitude`.
    var breathAmplitude: Double = BreathAmplitude.ambient
    /// Karartma gücü, 0.35–0.55. Dynamic Type büyüdükçe artırılmalı (§5).
    var scrimStrength: Float = 0.45
    /// Palet/ruh hâli geçişi sürerken kare hızı geçici olarak yükselir.
    var boostsFrameRate: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        if reduceTransparency {
            // Reduce Transparency: gradyan yerine düz koyu renk (Ton eki §7).
            palette.background.color.ignoresSafeArea()
        } else {
            GeometryReader { geo in
                TimelineView(.animation(minimumInterval: frameInterval, paused: isStatic)) { timeline in
                    let t = isStatic ? 0 : timeline.date.timeIntervalSinceReferenceDate * palette.speed
                    let breath = BreathCycle.value(at: t, amplitude: breathAmplitude)

                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: meshPoints(t: t, breath: breath),
                        colors: meshColors(),
                        background: palette.background.color,
                        // İkisi de açıkça yazılır (karar #7): iOS 18'de opt-in,
                        // iOS 26'da varsayılan — sürüme güvenilmez.
                        smoothsColors: true,
                        colorSpace: .perceptual
                    )
                    .colorEffect(
                        ShaderLibrary.grainAndScrim(
                            .float2(geo.size),
                            .float(Float(t)),
                            .float(palette.grain),
                            .float(safeY),
                            .float(scrimStrength)
                        )
                    )
                }
                .drawingGroup()  // tek Metal geçişinde birleştir
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)  // dekoratif (Ton eki §7)
        }
    }

    // MARK: - Hareket bütçesi (§6.6)

    /// Reduce Motion, düşük güç modu ve arka plan durumunda render durur.
    private var isStatic: Bool {
        reduceMotion
            || ProcessInfo.processInfo.isLowPowerModeEnabled
            || scenePhase != .active
    }

    /// Sabit durumda 30 fps, palet geçişinde 60. Termal baskıda ikisi de düşer —
    /// telefon ısınmışken pürüzsüz gradyan öncelik değil.
    private var frameInterval: Double {
        switch ProcessInfo.processInfo.thermalState {
        case .serious: return 1.0 / 15.0
        case .critical: return 1.0 / 8.0
        default: return 1.0 / (boostsFrameRate ? Theme.Motion.backgroundBoostFPS : Theme.Motion.backgroundFPS)
        }
    }

    // MARK: - Mesh

    /// KRİTİK (§6.5 tuzak #1): dış sınır noktaları birim karenin **kenarında**
    /// kalmalı. Bir kenar noktasını içeri çekerseniz gradyanın bittiği yerde
    /// görünür bir kesim oluşur. Kenar ortası noktaları kendi kenarları boyunca
    /// kayabilir — sabit koordinatları (0 ve 1) burada hiç değişmiyor.
    ///
    /// ## Hareket: kapanmayan bir gezinme
    ///
    /// Her nokta **iki ayrı sinüsün toplamıyla** sürülür (ürün sahibi kararı,
    /// 2026-09-09). Tek sinüs, noktayı bir elips üzerinde gezdiriyor: birkaç
    /// saniye bakan göz yörüngeyi öğreniyor ve hareket "döngüye girmiş animasyon"
    /// gibi okunuyordu. İki sinüsün oranı tam sayı olmadığı için toplamları
    /// pratikte hiç tekrar etmiyor — nokta her turda başka bir yerden geçiyor,
    /// hareket rastgele gibi hissediliyor ama tamamen deterministik ve sınırlı.
    ///
    /// Beş nokta birden akar (merkez + dört kenar ortası) ve her birinin kendi
    /// frekans çifti vardır; hiçbiri bir diğeriyle senkron değildir. Hız yine
    /// palete bağlı (`Palette.speed`, 0.18–0.40): uyku paleti en yavaş, odak en
    /// hızlı akar.
    ///
    /// Genlikler buradan yükseltilecekse dikkat: nokta ne kadar uzağa giderse
    /// mesh o kadar bükülür ve gradyanın yumuşaklığı bozulur. 0.13 civarı pratik
    /// tavan.
    private func meshPoints(t: TimeInterval, breath: Double) -> [SIMD2<Float>] {
        let b = Float(breath)

        // Ağırlıklar 0.62/0.38: baskın bir salınım ve onu sürekli kaydıran daha
        // hızlı ikinci bir salınım. İkisi eşit olsaydı hareket "iki ayrı şey"
        // gibi görünürdü.
        func wander(_ slow: Double, _ fast: Double, _ phase: Double) -> Float {
            Float(sin(t * slow + phase) * 0.62 + sin(t * fast + phase * 1.7) * 0.38)
        }

        let w1 = wander(1.00, 2.37, 0.0)
        let w2 = wander(0.79, 1.93, 1.1)
        let w3 = wander(1.31, 2.71, 2.3)
        let w4 = wander(0.91, 2.11, 3.4)
        let w5 = wander(1.13, 2.53, 4.6)

        return [
            SIMD2(0.0, 0.0),
            SIMD2(0.5 + w3 * 0.10, 0.0),
            SIMD2(1.0, 0.0),

            SIMD2(0.0, 0.5 + w4 * 0.09),
            // Merkez: iki eksende gezinir, üstüne nefes döngüsü biner.
            SIMD2(0.5 + w1 * 0.115, 0.46 + w2 * 0.10 + b * 0.05),
            SIMD2(1.0, 0.5 + w5 * 0.085),

            SIMD2(0.0, 1.0),
            SIMD2(0.5 - w4 * 0.10, 1.0),
            SIMD2(1.0, 1.0),
        ]
    }

    private func meshColors() -> [Color] {
        let s = palette.spots.map(\.color)
        let bg = palette.background.color
        return [
            bg,   s[0], bg,
            s[1], s[2], s[3],
            bg,   s[1], bg,
        ]
    }
}

#Preview("Kaygı") {
    BreathingMeshBackground(palette: Palette.all["anxiety"]!, safeY: 0.22)
        .overlay(alignment: .top) {
            Text("Şu an seni en çok ne zorluyor?")
                .font(.title2)
                .foregroundStyle(Theme.textPrimary.color)
                .padding(.top, 120)
                .padding(.horizontal, Theme.Spacing.screenMargin)
        }
}

#Preview("Uykusuzluk + Kaygı harmanı") {
    BreathingMeshBackground(
        palette: Palette.blend(Palette.all["sleep"]!, Palette.all["anxiety"]!),
        breathAmplitude: BreathAmplitude.session
    )
}
