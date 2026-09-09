import Foundation

/// Kategori paleti. Değerler PRD-Ek Görsel Sistem §3.2 ve §8.1'den birebir gelir.
///
/// İlke (§3.1): ton sorun tipine göre değişir, doygunluk ve parlaklık sabit bir
/// sakin bantta kalır (S 25–45%, L 12–38%). Hiçbir palette saf kırmızı yoktur.
struct Palette: Equatable, Hashable, Sendable, Identifiable {
    let key: String
    /// 4 renk noktası, koyudan açığa.
    let spots: [RGB]
    let background: RGB
    /// Sürüklenme hızı çarpanı, 0.18 – 0.40.
    let speed: Double
    /// Grain yoğunluğu, 0.040 – 0.061.
    ///
    /// Bant %35 yukarı taşındı (ürün sahibi kararı, 2026-09-09): dokunun görünür
    /// olması gradyanın "dijital degrade" değil basılı bir yüzey gibi okunmasını
    /// sağlıyor ve mesh'in yumuşak geçişlerindeki bantlaşmayı da örtüyor.
    let grain: Float

    var id: String { key }

    // MARK: - Harmanlama

    /// A2'de iki kategori seçildiğinde (PRD-Ek Görsel Sistem §3.3):
    /// birincil → renk noktaları 1 ve 3, ikincil → 2 ve 4, arka plan → daha koyu olan.
    ///
    /// 55 olası kombinasyonun tamamı bu kuralla üretilir.
    static func blend(_ primary: Palette, _ secondary: Palette?) -> Palette {
        guard let secondary, secondary.key != primary.key else { return primary }
        return Palette(
            key: "\(primary.key)+\(secondary.key)",
            spots: [primary.spots[0], secondary.spots[1], primary.spots[2], secondary.spots[3]],
            background: primary.background.relativeLuminance <= secondary.background.relativeLuminance
                ? primary.background
                : secondary.background,
            speed: (primary.speed + secondary.speed) / 2,
            grain: (primary.grain + secondary.grain) / 2
        )
    }

    // MARK: - Ruh hâli

    /// B6'da seçilen kademe paleti **değiştirmez, modüle eder** (ürün sahibi
    /// kararı, 2026-09-08). Kategori paleti kullanıcının derdinin kimliği;
    /// ruh hâli o kimliğin o anki hâli.
    ///
    /// İki eksende çalışır:
    ///
    /// **Ton.** Ağır uçta palet **laciverte**, sakin uçta **sıcak sarıya** çekilir
    /// (ürün sahibi kararı, 2026-09-08). Eksen keyfi değil: mavi–sarı, ruh hâli
    /// için kültürler arası en okunaklı görsel karşıtlık ve ikisi de kırmızıdan
    /// uzak — öfke paletindeki gerekçenin aynısı (karar #8).
    ///
    /// **Işık ve hız.** Ağır kademede ekran kısılır ve yavaşlar. Kötü hissedene
    /// ekranı parlatıp hızlandırmak "neşelen" demenin görsel karşılığı olurdu ve
    /// Ton eki §3'te yasak; kısık ve yavaş ekran ise sakinleştirici.
    ///
    /// **Değişmez kural:** ton serbest, luminans değil. Her nokta karıştırıldıktan
    /// sonra hedef luminansa geri taşınıyor (`RGB.withLuminance`) ve hedef, paletin
    /// mevcut en parlak noktasını aşamıyor. Kontrast yalnızca luminansa bağlı
    /// olduğu için renk istediği kadar değişse de metnin okunabilirliği bugünkü
    /// en kötü hâlinden aşağı inemiyor. Karartma serbest — açık metin koyu zeminde
    /// her zaman daha okunur.
    func moodAdjusted(_ mood: MoodLevel?) -> Palette {
        guard let mood else { return self }
        let m = mood.paletteModulation
        guard m.tintAmount != 0 || m.brightness != 1 || m.speedFactor != 1 || m.grainDelta != 0
        else { return self }

        let target = mood.anchorPalette
        let tintedSpots = zip(spots, target.spots).map { spot, goldOrNavy in
            spot.mixed(with: goldOrNavy, amount: m.tintAmount)
                .scaled(brightness: m.brightness)
        }
        let tintedBackground = background
            .mixed(with: target.background, amount: m.tintAmount)
            .scaled(brightness: min(m.brightness, 1))

        return Palette(
            key: "\(key)~\(mood.rawValue)",
            spots: tintedSpots,
            background: tintedBackground,
            speed: (speed * m.speedFactor).clamped(to: Palette.speedRange),
            grain: (grain + m.grainDelta).clamped(to: Palette.grainRange)
        )
    }

    /// §3.1'deki sakin bant. Modülasyon bu bandın dışına çıkamaz.
    static let speedRange: ClosedRange<Double> = 0.18...0.40
    static let grainRange: ClosedRange<Float> = 0.040...0.061

    // MARK: - Gece modu

    /// PRD-Ek Görsel Sistem §3.4 / Ton eki §2.1: 21:00 sonrası parlaklık %15 düşer,
    /// mavi kanal %8 kısılır. Uyku patikalarında işlevseldir, süsleme değildir.
    static let nightModeStartHour = 21

    func nightAdjusted(at date: Date = .now, calendar: Calendar = .current) -> Palette {
        let hour = calendar.component(.hour, from: date)
        guard hour >= Palette.nightModeStartHour else { return self }
        return Palette(
            key: key,
            spots: spots.map { $0.scaled(brightness: 0.85, blue: 0.92) },
            background: background.scaled(brightness: 0.85, blue: 0.92),
            speed: speed,
            grain: grain
        )
    }

    // MARK: - Kütüphane

    static func forCategory(_ category: ProblemCategory) -> Palette {
        all[category.rawValue] ?? neutral
    }

    static var neutral: Palette { all["unnamed"]! }

    static let all: [String: Palette] = [
        "anxiety": Palette(
            key: "anxiety",
            spots: [RGB(hex: 0x1F4A47), RGB(hex: 0x2D6A5E), RGB(hex: 0x3E8C79), RGB(hex: 0x7FB8A4)],
            background: RGB(hex: 0x0B1A19), speed: 0.35, grain: 0.047
        ),
        "sleep": Palette(
            key: "sleep",
            spots: [RGB(hex: 0x1B1F4B), RGB(hex: 0x2E2A6B), RGB(hex: 0x4A3F8C), RGB(hex: 0x7B6BB5)],
            background: RGB(hex: 0x07081A), speed: 0.22, grain: 0.041
        ),
        "burnout": Palette(
            key: "burnout",
            spots: [RGB(hex: 0x4A3520), RGB(hex: 0x7A5836), RGB(hex: 0xA8794A), RGB(hex: 0xD4A97A)],
            background: RGB(hex: 0x141009), speed: 0.30, grain: 0.061
        ),
        "focus": Palette(
            key: "focus",
            spots: [RGB(hex: 0x153A4A), RGB(hex: 0x1F5A6B), RGB(hex: 0x2E7D8C), RGB(hex: 0x6BAFBD)],
            background: RGB(hex: 0x08161C), speed: 0.40, grain: 0.043
        ),
        // Öfke paleti bilinçli olarak yeşil-teal (PRD-Ek Görsel Sistem karar #8):
        // öfkeli kullanıcıya kırmızı göstermek durumu pekiştirir.
        "anger": Palette(
            key: "anger",
            spots: [RGB(hex: 0x14403A), RGB(hex: 0x1E5C4E), RGB(hex: 0x2C7A64), RGB(hex: 0x6BAE96)],
            background: RGB(hex: 0x071815), speed: 0.25, grain: 0.051
        ),
        "selfcrit": Palette(
            key: "selfcrit",
            spots: [RGB(hex: 0x432A3D), RGB(hex: 0x6B4159), RGB(hex: 0x95637D), RGB(hex: 0xC296AC)],
            background: RGB(hex: 0x160E14), speed: 0.28, grain: 0.054
        ),
        "social": Palette(
            key: "social",
            spots: [RGB(hex: 0x2A3352), RGB(hex: 0x414D75), RGB(hex: 0x5F6E9B), RGB(hex: 0x9BA6C7)],
            background: RGB(hex: 0x0D1020), speed: 0.30, grain: 0.046
        ),
        "exam": Palette(
            key: "exam",
            spots: [RGB(hex: 0x1E3A4F), RGB(hex: 0x2C5570), RGB(hex: 0x3E7A96), RGB(hex: 0x7CAEC4)],
            background: RGB(hex: 0x0A1621), speed: 0.36, grain: 0.049
        ),
        "grief": Palette(
            key: "grief",
            spots: [RGB(hex: 0x3B2A38), RGB(hex: 0x5E4152), RGB(hex: 0x8A6274), RGB(hex: 0xB894A0)],
            background: RGB(hex: 0x130D12), speed: 0.18, grain: 0.057
        ),
        "unnamed": Palette(
            key: "unnamed",
            spots: [RGB(hex: 0x28302E), RGB(hex: 0x3E4A46), RGB(hex: 0x5A6B64), RGB(hex: 0x8FA098)],
            background: RGB(hex: 0x0E1211), speed: 0.26, grain: 0.051
        ),
        // B6 uç paletleri. Kategori paletine karıştırılır, tek başına kullanılmaz.
        // Luminansları önceden ayarlı: sarıyı sonradan karartmak kahve üretir,
        // laciverti sonradan açmak gri üretir. Bu yüzden uçlar hazır duruyor.
        "mood-navy": Palette(
            key: "mood-navy",
            spots: [RGB(hex: 0x0A1228), RGB(hex: 0x121C48), RGB(hex: 0x1C2A68), RGB(hex: 0x4A5A9A)],
            background: RGB(hex: 0x050814), speed: 0.18, grain: 0.057
        ),
        "mood-gold": Palette(
            key: "mood-gold",
            spots: [RGB(hex: 0x2A2208), RGB(hex: 0x5C4A10), RGB(hex: 0x9A7A18), RGB(hex: 0xD4B040)],
            background: RGB(hex: 0x120E06), speed: 0.32, grain: 0.041
        ),
    ]
}

/// Bir ruh hâli kademesinin palete etkisi.
struct MoodModulation: Equatable, Sendable {
    /// 0…1. Uçlarda kategori paleti neredeyse kaybolur — rengin ruh hâlini
    /// söylemesi isteniyor (karar #18).
    let tintAmount: Double
    /// 1.0 = değişiklik yok. 1'in altı karartır, üstü noktaları açar.
    let brightness: Double
    /// Sürüklenme hızı çarpanı.
    let speedFactor: Double
    /// Grain yoğunluğuna eklenen fark.
    let grainDelta: Float
}

extension MoodLevel {
    /// Uç palet. Ara kademeler kategori paletiyle bunun karışımı.
    var anchorPalette: Palette {
        switch self {
        case .veryHeavy, .heavy: Palette.all["mood-navy"]!
        case .middling: Palette.neutral
        case .okay, .calm: Palette.all["mood-gold"]!
        }
    }

    var paletteModulation: MoodModulation {
        switch self {
        case .veryHeavy:
            MoodModulation(tintAmount: 0.92, brightness: 0.88, speedFactor: 0.68, grainDelta: 0.006)
        case .heavy:
            MoodModulation(tintAmount: 0.55, brightness: 0.94, speedFactor: 0.82, grainDelta: 0.003)
        case .middling:
            MoodModulation(tintAmount: 0, brightness: 1.00, speedFactor: 1.00, grainDelta: 0)
        case .okay:
            MoodModulation(tintAmount: 0.55, brightness: 1.00, speedFactor: 1.10, grainDelta: -0.002)
        case .calm:
            MoodModulation(tintAmount: 0.92, brightness: 1.00, speedFactor: 1.18, grainDelta: -0.004)
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
