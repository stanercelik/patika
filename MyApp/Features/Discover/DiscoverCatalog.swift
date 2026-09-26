import Foundation

/// Katalog metni. MVP yalnızca İngilizce (2026-09-21); `tr` isteğe bağlı ve
/// yoksa İngilizceye düşer, yani yeni bir dil eklemek katalogu yeniden yazmak
/// değil, eksik alanları doldurmak demek.
struct DiscoverText: Codable, Equatable, Sendable {
    let en: String
    var tr: String?
    /// Ekranda okunan metin `AppLocale`e uyar. **Konuşulan metin için kullanılmaz:**
    /// ekrandaki cümle duyulan cümleyle aynı olmalı (`DiscoverLibrary.playback`).
    var value: String { value(for: AppLocale.current) }

    func value(for locale: AppLocale) -> String {
        locale == .turkish ? (tr ?? en) : en
    }
}

/// Bir adımın konuşulan bir bölümü ve ardından gelen sessizlik.
///
/// Adım tek bir metin + tek bir sessizlik değil: öğretmen yönergeyi verir, susar,
/// bir sonrakini verir. `quietMs` bölümden **sonra** gelir ve yazılan süredir;
/// nefes döngüsüne yuvarlanmaz (10 sn'lik zemin 12 sn'lik bir sessizliği bozardı).
struct DiscoverSegment: Codable, Equatable, Sendable {
    let text: DiscoverText
    let quietMs: Int
}

struct DiscoverStep: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: DiscoverText
    let segments: [DiscoverSegment]
    /// Tüm adımlarda aynı: ses bir kez üretilir.
    let closing: DiscoverText

    /// Konuşulan parçaların adları, çalma sırasıyla. Ses kayıtlarının anahtarı
    /// `<adım>.<dil>.<ses>.<parça>` biçiminde bunları kullanır.
    var parts: [String] { segments.indices.map { "segment-\($0)" } + ["closing"] }
}

struct DiscoverPath: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: DiscoverText
    let summary: DiscoverText
    /// Patikanın ait olduğu problem kategorisi (A2'deki on kategoriden biri).
    /// Bölümü (`DiscoverSection`) ve detay ekranının paletini buradan gelir.
    let category: ProblemCategory
    let artwork: String
    let steps: [DiscoverStep]
}

struct DiscoverRecording: Codable, Sendable {
    let file: String
    /// Dosyadan **çözülerek** ölçülmüş süre (`render-discover-audio.py`). Planlama
    /// değeri; oynatıcı yüklediği dosyayı ayrıca ölçer.
    let durationMs: Int
    let voice: String
    let locale: String
    let sha256: String
    /// Kaydı baytlarına kadar belirleyen her şeyin özeti (metin, ses, model, ayarlar,
    /// son işlem). Değişen bir ayar yalnızca etkilenen dosyaları yeniler.
    let renditionKey: String
}

struct DiscoverCatalog: Decodable, Sendable {
    let version: Int
    let audioLocale: String
    let paths: [DiscoverPath]

    static func load(bundle: Bundle = .main) throws -> Self {
        guard let url = bundle.url(forResource: "discover-catalog", withExtension: "json") else {
            throw DiscoverError.missingCatalog
        }
        let result = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        guard result.version == 2, !result.paths.isEmpty,
              Set(result.paths.map(\.id)).count == result.paths.count,
              Set(result.paths.map(\.category)).count == result.paths.count,
              result.paths.allSatisfy({ $0.steps.count == 7 && $0.steps.allSatisfy { !$0.segments.isEmpty } })
        else { throw DiscoverError.missingCatalog }
        return result
    }
}

enum DiscoverError: Error { case missingCatalog, missingAudio, notEnrolled }
