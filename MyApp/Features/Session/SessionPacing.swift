import Foundation

/// Oturumun tempo kuralları — PRD-Ek Oturum Motoru §2 (K1-K6).
///
/// Üç kademe ve üçü de ayrı bir şey:
///
/// | Kademe   | Süre         | Yazılır mı    | Nefese hizalı |
/// |----------|--------------|---------------|---------------|
/// | join     | ~350 ms      | Hayır, makine | asla          |
/// | beat     | 0,8 - 3 sn   | Evet (`ms`)   | asla          |
/// | practice | >= 1 nefes   | Evet          | evet          |
///
/// **Join bir olay değildir**, bir sonraki konuşmanın özelliğidir (`leadIn`).
/// Bağlantılı iki cümle arasındaki 350 ms'nin kendi sahnesi olsaydı aynı cümle
/// boşluk için solup geri gelirdi.
///
/// Değerler türetilebilir olduğu için manifest alanı değil, burada sabit.
enum SessionPacing {
    /// K1: bağlantılı cümleler arası hedef boşluk. Sunucu komşu dolguları düşüp
    /// `leadInMs` olarak yazar; bu sabit yalnızca ekran/sunucu tutarlılığı için.
    static let joinGap: TimeInterval = 0.35
    /// Kısa sessizlikten sonra giriş (§3.1).
    static let fadeInShort: TimeInterval = 0.25
    /// K4: bir nefesten uzun sessizlikten sonra yumuşak giriş. Uzun sessizliğin
    /// ardından gelen ani ses, meditasyonun ortasında irkiltiyordu.
    static let fadeInLong: TimeInterval = 0.60
    /// Bir sessizlikten önce konuşmanın kuyruğu.
    static let fadeOut: TimeInterval = 0.25
    /// Tıklama önleyici: iki konuşma bitişikken ya da yalnızca uç kenar.
    static let declick: TimeInterval = 0.015
    /// Sarma/kesinti sonrası cümlenin **ortasına** iniş. 600 ms şişme burada arıza
    /// gibi duyulurdu; kullanıcı orada olmak istedi, yalnızca tıklama önlenir.
    static let declickOnSeek: TimeInterval = 0.12

    /// K4: sessizlik bir nefesten uzunsa uzun, değilse kısa giriş.
    static func fadeIn(afterGap gap: TimeInterval, breath: TimeInterval) -> TimeInterval {
        gap > breath ? fadeInLong : fadeInShort
    }

    /// Manifestin nefes periyodu yoksa arka planın varsayılan döngüsü.
    static let defaultBreathMilliseconds = 10_000
}
