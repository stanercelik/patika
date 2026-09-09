import Foundation

/// Nefes döngüsü — PRD-Ek Görsel Sistem §4.
///
/// Bu görsel süsleme değil, **fonksiyonel** bir öğedir: kullanıcı farkında olmadan
/// nefesini animasyona uydurur. Asimetri bilinçlidir (karar #10) — uzun nefes verme
/// parasempatik sistemi aktive eder.
enum BreathCycle {
    static let inhale: TimeInterval = 4.0
    static let hold: TimeInterval = 0.5
    static let exhale: TimeInterval = 5.5
    static var period: TimeInterval { inhale + hold + exhale }  // 10 sn

    /// 0…1 arası nefes değeri, `amplitude` ile ölçeklenmiş.
    /// Mesh merkez noktasını ve shader parlaklığını besleyen tek kaynak.
    static func value(at time: TimeInterval, amplitude: Double) -> Double {
        guard amplitude > 0 else { return 0 }
        let phase = time.truncatingRemainder(dividingBy: period)
        let raw: Double
        if phase < inhale {
            raw = easeInOutSine(phase / inhale)
        } else if phase < inhale + hold {
            raw = 1.0
        } else {
            raw = 1.0 - easeInOutSine((phase - inhale - hold) / exhale)
        }
        return raw * amplitude
    }

    private static func easeInOutSine(_ x: Double) -> Double {
        -(cos(.pi * x) - 1) / 2
    }
}

/// Ekran grubuna göre nefes genliği — PRD-Ek Görsel Sistem §4.
///
/// Genlik yukarı çıkarılmaz: ölçüm ekranında odaklanma, kriz ekranında ise
/// hareketsizlik gerekir (PRD §11.1).
enum BreathAmplitude {
    /// A1, A2, B, C — arka plan, dikkat çekmemeli.
    static let ambient: Double = 0.60
    /// D — ölçüm, odaklanma gerekiyor.
    static let measurement: Double = 0.35
    /// F1 — üretim beklemesi.
    static let generation: Double = 0.80
    /// G1 — oturum. Kullanıcı gerçekten nefesini buna uyduruyor.
    static let session: Double = 1.00
    /// Kriz ekranı. Hareket yok.
    static let crisis: Double = 0.00
}
