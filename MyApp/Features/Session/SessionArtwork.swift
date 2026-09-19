import SwiftUI

/// Oturum ekranının tek görseli — ortak guaj ailesinden, oturuma özel kesit.
///
/// Görsel adımın **fazından** seçilir (yol haritasındaki fazla aynı yer), asla
/// kullanıcının cevabından ya da sonucundan değil. Bütün oturum boyunca aynı
/// görsel kalır: sahne değiştikçe resmin de değişmesi gözü metinden çekiyordu.
///
/// Varlıklar `Assets.xcassets/Session/` altında; prompt'lar
/// `assets/illustrations/session/prompts.md`. Varlık eklenmemişse görsel hiç
/// yer kaplamaz ve ekran yalnızca metinle çalışır.
enum SessionArtwork: String, CaseIterable {
    /// G1 — ilk oturum, yolun başı.
    case trailhead = "session-trailhead"
    /// Rahatlama fazı.
    case relief = "session-relief"
    /// Farkındalık, beceri ve davranış fazları.
    case practice = "session-practice"
    /// Kapanış fazı.
    case closing = "session-closing"

    init(phase: PathPhase) {
        switch phase {
        case .relief: self = .relief
        case .awareness, .skill, .behavior: self = .practice
        case .closing: self = .closing
        }
    }

    var isAvailable: Bool { UIImage(named: rawValue) != nil }
}

/// Görsel arka planla aynı nefesi alır: nefes alırken %3 büyür, verirken
/// küçülür. Kendi ritmi yok — ekranda iki ayrı ritim kullanıcıyı ikisinin
/// arasında bırakırdı. Reduce Motion'da ve duraklatıldığında durur.
struct SessionArtworkView: View {
    let artwork: SessionArtwork
    let isPaused: Bool

    @Environment(PaletteController.self) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if artwork.isAvailable {
            TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion || isPaused)) { timeline in
                Image(decorative: artwork.rawValue)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(1 + 0.03 * breath(at: timeline.date))
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func breath(at date: Date) -> Double {
        guard !reduceMotion else { return 0 }
        let t = date.timeIntervalSinceReferenceDate * palette.current.speed
        return BreathCycle.value(at: t, amplitude: BreathAmplitude.session)
    }
}
