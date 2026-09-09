import Foundation

/// Kriz sinyali ön filtresi — PRD §11.1.
///
/// ## Bu neyin yerine geçmez
///
/// **Bu sınıflandırıcı değil, ön filtredir.** Cihazda çalışan bir anahtar ifade
/// taramasıdır ve gerçek sınıflandırıcının yerine geçmez: ima, mecaz, ironi ve
/// yazım hatası yakalamaz. PRD §11.1'in gerektirdiği sunucu tarafı sınıflandırma
/// hâlâ **bloklayıcı bir eksik** — path üretimi eklendiğinde metin oraya gitmeden
/// önce sunucuda yeniden değerlendirilmelidir.
///
/// Ön filtrenin yine de burada olma sebebi: sunucu turu gecikmeli ve çevrimdışı
/// çalışmıyor. Bariz bir sinyalde kullanıcıyı bir sonraki soruya geçirip sonra
/// geri çekmek, hiç geçirmemekten kötü.
///
/// ## Neden yüksek duyarlılık, düşük kesinlik
///
/// Eşik bilerek gevşek: yanlış pozitifin bedeli kullanıcının yardım ekranını
/// görmesi, yanlış negatifin bedeli kriz sinyali vermiş birine meditasyon
/// programı satmaya çalışmak. İkisi kıyaslanamaz. Akışın durması da bilinçli
/// (§11.1): path üretilmez, ölçüm yapılmaz, kayıt istenmez.
///
/// Liste büyütülürken tek kural: ifade **tek başına** ciddi olmalı. "Dayanamıyorum"
/// gibi yaygın abartılar buraya girmez — girerse filtre gürültüye boğulur ve
/// güvenilirliğini kaybeder.
enum CrisisClassifier {

    struct Result: Equatable, Sendable {
        let hasSignal: Bool
        /// Hangi ifadenin tetiklediği — yalnızca hata ayıklama ve test içindir.
        /// **Analitiğe gönderilmez** (PRD §13.5: problem metni asla analitiğe gitmez).
        let matchedPhrases: [String]

        static let clear = Result(hasSignal: false, matchedPhrases: [])
    }

    /// Kendine zarar ve intihar ifadeleri. Aksansız yazımı da yakalamak için
    /// karşılaştırma öncesi hem liste hem girdi normalize edilir ("ölmek" → "olmek").
    private static let signalPhrases: [String] = [
        // İntihar niyeti
        "intihar",
        "kendimi oldur",
        "kendimi asa",
        "canima kiy",
        "hayatima son",
        "yasamak istemiyorum",
        "olmek istiyorum",
        "olsem daha iyi",
        "olsem keske",
        "keske olsem",
        "artik yasamak",
        "yok olmak istiyorum",
        "uyanmak istemiyorum",
        // Kendine zarar
        "kendime zarar",
        "kendimi kesiyorum",
        "kendimi kestim",
        "bileklerimi",
        "kendimi cezalandir",
        // Plan / araç
        "ilaclarin hepsini",
        "yuksek yerden atla",
    ]

    static func evaluate(_ text: String) -> Result {
        let normalized = normalize(text)
        guard !normalized.isEmpty else { return .clear }

        let matches = signalPhrases.filter { normalized.contains(normalize($0)) }
        return Result(hasSignal: !matches.isEmpty, matchedPhrases: matches)
    }

    /// Küçük harfe indirir ve Türkçe harfleri ASCII karşılığına eşler.
    ///
    /// Eşleme elle yazılmıştır, `folding(options: .diacriticInsensitive)` ile değil:
    /// "ı" bir aksanlı harf değil ayrı bir harftir ve folding'in onu "i"ye
    /// indirmesi garanti değil. Klavyesi Türkçe olmayan kullanıcı "ölmek" yerine
    /// "olmek" yazıyor — filtre ikisini de görmek zorunda.
    private static let turkishToASCII: [Character: Character] = [
        "ı": "i", "ş": "s", "ğ": "g", "ü": "u", "ö": "o", "ç": "c",
        "â": "a", "î": "i", "û": "u",
    ]

    private static func normalize(_ text: String) -> String {
        String(
            text
                .lowercased(with: Locale(identifier: "tr_TR"))
                .map { turkishToASCII[$0] ?? $0 }
        )
    }
}
