import Foundation

/// Kişilik spektrumu — Ton eki §1.
///
/// Ürünün kişiliği tek değil, dört sıcaklık kademesinde çalışır.
/// **Bir ekranın kademesi yukarı çıkmaz.** Kova C ekranına "en azından denedin!"
/// eklenmez. Şüphe varsa bir kademe aşağı in.
enum ToneTier: Int, Comparable, Sendable, CaseIterable {
    /// Nötr — Kriz ekranı, Kova C raporu, Destek al, tıbbi feragat.
    /// Sade, yavaş, sıfır süsleme. Whimsy izni: **yok, hiçbiri.**
    case neutral = 0
    /// Sakin — Oturum içi, ölçüm ekranları, path haritası. Sıcak ama sessiz.
    case calm = 1
    /// Sıcak — Path sonu (Kova A/B), rozet, oturum sonu. İçten, kutlayan ama abartısız.
    case warm = 2
    /// Oyuncu — Keşfet, nefes egzersizleri, boş durumlar, ayarlar. Hafif esprili.
    case playful = 3

    static func < (lhs: ToneTier, rhs: ToneTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Whimsy bütçesi (Ton eki §4): delight sık olduğunda gürültüye dönüşür ve
    /// dikkat çeker — meditasyon ürününde dikkat çekmek başarısızlıktır.
    var allowsWhimsy: Bool { self > .neutral }

    /// Metin/mikro-animasyon whimsy'sine izin var mı (sadece hareket/geçiş değil).
    var allowsCopyWhimsy: Bool { self >= .warm }

    var maxCelebrationIntensity: Int {
        switch self {
        case .neutral: 0
        case .calm: 1
        case .warm: 5
        case .playful: 3
        }
    }
}

/// Asla kullanılmayacak ifadeler — Ton eki §3.6.
///
/// Kullanıcıya görünen metin ekleyen her PR'da bu listeye karşı kontrol edilmeli.
/// Test hedefi eklendiğinde `String Catalog` içeriğini tarayan bir lint testi bunu
/// otomatikleştirmeli.
enum BannedPhrases {
    /// MVP yalnızca İngilizce (2026-09-21): İngilizce liste asıl liste, Türkçe liste
    /// dil yeniden açılınca hazır dursun diye korunuyor.
    static let all: [String] = english + turkish

    static let english: [String] = [
        "great job",           // abartılı övgü → sahte hissettirir
        "well done!",
        "congratulations",
        "we miss you",         // suçluluk üretir
        "lose your streak",    // kayıp kaçınması — PRD karar #5
        "losing your streak",
        "streak",
        "days left",           // aciliyet baskısı
        "hurry up",
        "hurry!",
        "limited time",
        "other users",         // sosyal kıyaslama — bu kitlede toksik
        "don't worry",         // kaygılı kişiye söylenecek en işe yaramaz cümle
        "do not worry",
        "calm down",
        "you'll get through this", // garanti verilemez
        "you will get through this",
        "you failed",          // PRD karar #2
        "you've failed",
        "failure",
        // Tıbbi iddia — mağaza reddi ve düzenleyici risk (PRD §4, §14.3)
        "clinically proven",
        "cure",
        "heals you",
        "replaces therapy",
        "instead of therapy",
    ]

    static let turkish: [String] = [
        "harika iş",           // abartılı övgü → sahte hissettirir
        "tebrikler",
        "seni özledik",        // suçluluk üretir
        "serini kaybet",       // kayıp kaçınması — PRD karar #5
        "streak",
        "gün kaldı",           // aciliyet baskısı
        "diğer kullanıcılar",  // sosyal kıyaslama — bu kitlede toksik
        "endişelenme",         // kaygılı kişiye söylenecek en işe yaramaz cümle
        "sakin ol",
        "bunu aşacaksın",      // garanti verilemez
        "başarısız",           // PRD karar #2
        "başaramadın",
        // Tıbbi iddia — mağaza reddi ve düzenleyici risk (PRD §4, §14.3)
        "tedavi",
        "iyileştirir",
        "klinik olarak kanıtlanmış",
        "terapinin yerine",
    ]

    /// Ses testi (Ton eki §1.1): "Yazdığın cümleyi, gece 2'de uyuyamayan ve kendini
    /// kötü hisseden birine yüksek sesle söyleyebiliyor musun?"
    static func check(_ text: String) -> [String] {
        // Akıllı kesme işareti düz yazılır ("don’t" ve "don't" aynı ifade).
        let lowered = text.lowercased().replacingOccurrences(of: "\u{2019}", with: "'")
        return all.filter { lowered.contains($0) }
    }
}

/// Kutlama kalibrasyonu — Ton eki §6.
enum CelebrationIntensity {
    static let dailyStep = 1
    static let day7Measurement = 3
    static let day14Measurement = 2
    static let returningUser = 2
    // Path tamamlama için `OutcomeBucket.celebrationIntensity` kullanılır.
}
