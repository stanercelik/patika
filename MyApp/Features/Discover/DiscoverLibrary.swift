import Foundation
import Observation
import CryptoKit

/// Prepared content is available offline. Progress belongs to this installation;
/// it never overwrites the server's personalized path or measurements.
///
/// Katılım Keşfet'te kalır: hazır patikalar Yolum'u devralmaz ve aynı anda birden
/// fazlasına katılınabilir. Her patikanın ilerlemesi kendi kaydında durur.
@Observable @MainActor
final class DiscoverLibrary {
    struct Enrollment: Codable {
        var completed: Set<String> = []
        /// Son ilerleme sırası (büyük olan yeni). "Kaldığın yerden" bölümünün
        /// sırasını verir. Opsiyonel: bu alandan önce yazılmış kayıtlar okunabilmeli.
        var recency: Int?
    }
    /// Eski kayıtlardaki `activeID` (hazır patikanın Yolum'u devralması) artık yok;
    /// alan burada tanımlı olmadığı için okunurken yok sayılır, ilerleme korunur.
    private struct Saved: Codable {
        var enrollments: [String: Enrollment] = [:]
    }

    /// Bir patikanın kartta ve detayda görünen durumu. Renk dışında da okunur:
    /// her durumun kendi metni var.
    enum Status: Equatable {
        /// Sesi pakette yok: listede görünür, katılım kapalı. Sahte ses yok.
        case comingSoon
        case available
        case inProgress(done: Int, total: Int)
        case completed
    }

    let paths: [DiscoverPath]
    /// Kayıtların konuşulduğu dil (`catalog.audioLocale`). Oturumda ekrana yazılan
    /// cümle bu dildedir; arayüz dili değil.
    let audioLocale: AppLocale
    /// MVP tek ses: kadın sesi (ürün sahibi kararı, 2026-09-21). Ses seçimi arayüzden
    /// kalktı; kayıt anahtarları ses adını taşımaya devam ediyor, ikinci ses
    /// eklenirse katalog ve dosyalar yeniden üretilmeden genişler.
    static let voice: SessionVoice = .feminine
    private let recordings: [String: DiscoverRecording]
    private let defaults: UserDefaults
    private let bundle: Bundle
    private var saved: Saved
    private(set) var loadFailed = false
    private(set) var saveFailed = false
    private static let storageKey = "discover.library.v1"

    init(defaults: UserDefaults = .standard, bundle: Bundle = .main) {
        self.defaults = defaults
        self.bundle = bundle
        if let data = defaults.data(forKey: Self.storageKey), let value = try? JSONDecoder().decode(Saved.self, from: data) {
            saved = value
        } else { saved = Saved() }
        if let catalog = try? DiscoverCatalog.load(bundle: bundle) {
            paths = catalog.paths
            audioLocale = AppLocale(rawValue: catalog.audioLocale) ?? .english
        } else {
            paths = []
            audioLocale = .english
            loadFailed = true
        }
        if let url = bundle.url(forResource: "discover-audio", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let values = try? JSONDecoder().decode([String: DiscoverRecording].self, from: data) { recordings = values }
        else { recordings = [:] }
    }

    /// Boş olmayan bölümler, ekrandaki sırayla.
    var sections: [DiscoverShelf] {
        DiscoverSection.allCases.compactMap { section in
            let members = paths.filter { $0.section == section }
            return members.isEmpty ? nil : DiscoverShelf(section: section, paths: members)
        }
    }

    /// Katılıp bitirmediği patikalar; en son ilerleyen başta, eşitlikte katalog sırası.
    var inProgressPaths: [DiscoverPath] {
        paths.enumerated()
            .filter { isEnrolled($0.element) && nextStep($0.element) != nil }
            .sorted { lhs, rhs in
                let left = saved.enrollments[lhs.element.id]?.recency ?? 0
                let right = saved.enrollments[rhs.element.id]?.recency ?? 0
                return left != right ? left > right : lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    func status(_ path: DiscoverPath) -> Status {
        if isEnrolled(path) {
            return nextStep(path) == nil ? .completed : .inProgress(done: completedCount(path), total: path.steps.count)
        }
        return audioIsReady(path) ? .available : .comingSoon
    }
    func isEnrolled(_ path: DiscoverPath) -> Bool { saved.enrollments[path.id] != nil }
    func isComplete(_ step: DiscoverStep, in path: DiscoverPath) -> Bool { saved.enrollments[path.id]?.completed.contains(step.id) == true }
    func completedCount(_ path: DiscoverPath) -> Int { path.steps.filter { isComplete($0, in: path) }.count }
    func nextStep(_ path: DiscoverPath) -> DiscoverStep? { path.steps.first { !isComplete($0, in: path) } }
    func isAvailable(_ step: DiscoverStep, in path: DiscoverPath) -> Bool {
        isEnrolled(path) && (isComplete(step, in: path) || nextStep(path)?.id == step.id)
    }
    func enroll(_ path: DiscoverPath) {
        guard paths.contains(where: { $0.id == path.id }) else { return }
        if saved.enrollments[path.id] == nil { saved.enrollments[path.id] = Enrollment() }
        touch(path)
        persist()
    }
    func complete(_ step: DiscoverStep, in path: DiscoverPath) {
        guard isAvailable(step, in: path) else { return }
        // Yeniden dinleme ilerleme değil: sırayı yalnızca yeni bir adım değiştirir.
        if saved.enrollments[path.id]?.completed.insert(step.id).inserted == true { touch(path) }
        persist()
    }
    private func touch(_ path: DiscoverPath) {
        let latest = saved.enrollments.values.compactMap(\.recency).max() ?? 0
        saved.enrollments[path.id]?.recency = latest + 1
    }
    /// Kayıt anahtarı: `<adım>.<dil>.<ses>.<parça>`. Dil ve ses anahtarda: sonradan
    /// eklenen bir dil ya da ses mevcut kayıtlarla karışmaz.
    private func recordingKey(_ step: DiscoverStep, part: String) -> String {
        "\(step.id).\(audioLocale.rawValue).\(Self.voice.rawValue).\(part)"
    }

    func audioIsReady(_ path: DiscoverPath) -> Bool {
        path.steps.allSatisfy { step in
            step.parts.allSatisfy { part in
                guard let recording = recordings[recordingKey(step, part: part)] else { return false }
                return recording.durationMs > 0 && resourceURL(recording) != nil
            }
        }
    }

    /// Adımı bir manifeste çevirir: bölüm, yazılan sessizlik, bölüm, ... kapanış.
    ///
    /// Sessizlik `ms` ile yazılır (nefes sayısıyla değil) ve `displayText` taşımaz:
    /// son yönerge duraklama boyunca ekranda kalır, kullanıcı ne yaptığını görür.
    func playback(for step: DiscoverStep, in path: DiscoverPath) throws -> SessionPlayback {
        guard isAvailable(step, in: path) else { throw DiscoverError.notEnrolled }
        var urls: [UUID: URL] = [:]
        var events: [SessionEvent] = []
        func speech(part: String, text: String) throws {
            guard let recording = recordings[recordingKey(step, part: part)], let url = resourceURL(recording) else { throw DiscoverError.missingAudio }
            let id = stableUUID(recording.sha256)
            urls[id] = url
            events.append(.speech(SessionSpeech(source: .block, assetID: id, storagePath: recording.file, text: text, durationMilliseconds: recording.durationMs)))
        }
        for (index, segment) in step.segments.enumerated() {
            try speech(part: "segment-\(index)", text: segment.text.value(for: audioLocale))
            events.append(.silence(SessionSilence(
                milliseconds: segment.quietMs,
                breaths: max(1, Int((Double(segment.quietMs) / Double(SessionPacing.defaultBreathMilliseconds)).rounded())),
                landOn: nil,
                displayText: nil
            )))
        }
        try speech(part: "closing", text: step.closing.value(for: audioLocale))
        // Dil ve ses kayıt noktasında: dil değiştiren kullanıcı başka zamanlı bir
        // kayıtta yanlış konumdan devam etmesin.
        let checkpointID = stableUUID("\(path.id).\(step.id).\(audioLocale.rawValue).\(Self.voice.rawValue)")
        return SessionPlayback(
            manifest: SessionManifest(version: 1, stepID: checkpointID, pathKind: .prepared, locale: audioLocale.rawValue, voice: Self.voice, question: nil, breathMilliseconds: SessionPacing.defaultBreathMilliseconds, events: events),
            assetURLs: urls
        )
    }
    private func resourceURL(_ recording: DiscoverRecording) -> URL? {
        bundle.url(forResource: (recording.file as NSString).deletingPathExtension, withExtension: "mp3")
    }
    private func stableUUID(_ value: String) -> UUID {
        let hex = SHA256.hash(data: Data(value.utf8)).prefix(16).map { String(format: "%02x", $0) }.joined()
        let parts = [8,4,4,4,12]
        var offset = hex.startIndex
        let formatted = parts.map { count -> String in
            let end = hex.index(offset, offsetBy: count)
            defer { offset = end }
            return String(hex[offset..<end])
        }.joined(separator: "-")
        return UUID(uuidString: formatted) ?? UUID()
    }
    private func persist() {
        guard let data = try? JSONEncoder().encode(saved) else { saveFailed = true; return }
        defaults.set(data, forKey: Self.storageKey)
        saveFailed = false
    }
}
