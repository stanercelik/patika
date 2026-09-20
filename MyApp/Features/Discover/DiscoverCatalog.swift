import Foundation

struct DiscoverText: Codable, Equatable, Sendable {
    let en: String
    let tr: String
    /// Ekranda okunan metin `AppLocale`e uyar. **Konuşulan metin için kullanılmaz:**
    /// ses ilk sürümde yalnızca İngilizce, ekrandaki cümle duyulan cümleyle aynı
    /// olmalı (`DiscoverLibrary.playback`, `value(for:)`).
    var value: String { value(for: AppLocale.current) }

    func value(for locale: AppLocale) -> String {
        locale == .turkish ? tr : en
    }
}

struct DiscoverStep: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: DiscoverText
    let guidance: DiscoverText
    let closing: DiscoverText
    let quietSeconds: Int
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
    let durationMs: Int
    let voice: String
    let locale: String
    let sha256: String
    let sourceURL: String
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
        guard result.version == 1, !result.paths.isEmpty,
              Set(result.paths.map(\.id)).count == result.paths.count,
              Set(result.paths.map(\.category)).count == result.paths.count,
              result.paths.allSatisfy({ $0.steps.count == 7 }) else { throw DiscoverError.missingCatalog }
        return result
    }
}

enum DiscoverError: Error { case missingCatalog, missingAudio, notEnrolled }
