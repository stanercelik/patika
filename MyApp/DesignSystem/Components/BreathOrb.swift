import SwiftUI

/// Meditasyon ekranının nefes küresi (docs/onboarding-redesign.md, Faz 7).
///
/// Gradyan kalktı (2026-09-22): oturum ekranının arka planı artık `MeshGradient`
/// değil, tam ekran bir guaj sahnesi (`OnboardingSceneLayer`, `bg-session`). Bunun
/// üstünde nefesi işaret eden tek şey bu küre — düz kırık beyaz dolgu (aynı malzeme:
/// oturumun oynat düğmesiyle akraba), gradyan yok.
///
/// 10 sn'lik gerçek döngüyle (4 al / 0,5 tut / 5,5 ver) 0,88 → 1,00 ölçeklenir. Ses
/// varsa `voiceEnergy` en fazla %4 ölçek ve opaklık ekler — konuşma başladığında küre
/// hafifçe canlanır, tıpkı eski mesh'in ses zarfına tepki vermesi gibi.
///
/// Reduce Motion'da durur (sabit daire); `BreathAmplitude.crisis` = 0 zaten hiçbir
/// hareket üretmez. Anlam hiçbir zaman yalnızca bu görselle taşınmadığı için
/// VoiceOver'dan gizli.
struct BreathOrb: View {
    var amplitude: Double = BreathAmplitude.session
    var voiceEnergy: Double = 0
    var diameter: CGFloat = 120

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion || amplitude == 0)) { timeline in
            let breath = reduceMotion ? 0 : BreathCycle.value(
                at: timeline.date.timeIntervalSinceReferenceDate,
                amplitude: amplitude
            )
            let voice = reduceMotion ? 0 : min(max(voiceEnergy, 0), 1)
            let scale = 0.88 + 0.12 * breath + 0.04 * voice

            ZStack {
                Circle()
                    .fill(WoodlandStyle.paper.opacity(0.16 + 0.05 * breath + 0.04 * voice))
                Circle()
                    .strokeBorder(WoodlandStyle.paper.opacity(0.42), lineWidth: 1.5)
            }
            .frame(width: diameter, height: diameter)
            .scaleEffect(scale)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        WoodlandStyle.background.ignoresSafeArea()
        BreathOrb()
    }
}
