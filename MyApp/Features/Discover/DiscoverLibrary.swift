import Foundation
import Observation
import CryptoKit

/// Prepared content is available offline. Progress belongs to this installation;
/// it never overwrites the server's personalized path or measurements.
@Observable @MainActor
final class DiscoverLibrary {
    struct Enrollment: Codable {
        var completed: Set<String> = []
        var voice: SessionVoice = .feminine
    }
    private struct Saved: Codable {
        var activeID: String?
        var enrollments: [String: Enrollment] = [:]
    }

    let paths: [DiscoverPath]
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
        if let catalog = try? DiscoverCatalog.load(bundle: bundle) { paths = catalog.paths }
        else { paths = []; loadFailed = true }
        if let url = bundle.url(forResource: "discover-audio", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let values = try? JSONDecoder().decode([String: DiscoverRecording].self, from: data) { recordings = values }
        else { recordings = [:] }
        if !paths.contains(where: { $0.id == saved.activeID }) { saved.activeID = nil }
    }

    var activePath: DiscoverPath? { paths.first { $0.id == saved.activeID } }
    func isEnrolled(_ path: DiscoverPath) -> Bool { saved.enrollments[path.id] != nil }
    func isComplete(_ step: DiscoverStep, in path: DiscoverPath) -> Bool { saved.enrollments[path.id]?.completed.contains(step.id) == true }
    func completedCount(_ path: DiscoverPath) -> Int { path.steps.filter { isComplete($0, in: path) }.count }
    func nextStep(_ path: DiscoverPath) -> DiscoverStep? { path.steps.first { !isComplete($0, in: path) } }
    func isAvailable(_ step: DiscoverStep, in path: DiscoverPath) -> Bool {
        isEnrolled(path) && (isComplete(step, in: path) || nextStep(path)?.id == step.id)
    }
    func voice(for path: DiscoverPath) -> SessionVoice { saved.enrollments[path.id]?.voice ?? .feminine }
    func selectVoice(_ voice: SessionVoice, for path: DiscoverPath) {
        guard saved.enrollments[path.id] != nil else { return }
        saved.enrollments[path.id]?.voice = voice
        persist()
    }
    func enroll(_ path: DiscoverPath, voice: SessionVoice) {
        guard paths.contains(where: { $0.id == path.id }) else { return }
        if saved.enrollments[path.id] == nil { saved.enrollments[path.id] = Enrollment(voice: voice) }
        saved.enrollments[path.id]?.voice = voice
        saved.activeID = path.id
        persist()
    }
    func openPersonalPath() { saved.activeID = nil; persist() }
    func complete(_ step: DiscoverStep, in path: DiscoverPath) {
        guard isAvailable(step, in: path) else { return }
        saved.enrollments[path.id]?.completed.insert(step.id)
        persist()
    }
    func audioIsReady(_ path: DiscoverPath) -> Bool {
        path.steps.allSatisfy { step in
            [SessionVoice.feminine, .masculine].allSatisfy { voice in
                ["guidance", "closing"].allSatisfy { part in
                    guard let recording = recordings["\(step.id).\(voice.rawValue).\(part)"] else { return false }
                    return recording.durationMs > 0 && resourceURL(recording) != nil
                }
            }
        }
    }
    func playback(for step: DiscoverStep, in path: DiscoverPath) throws -> SessionPlayback {
        guard isAvailable(step, in: path) else { throw DiscoverError.notEnrolled }
        let voice = voice(for: path)
        var urls: [UUID: URL] = [:]
        var events: [SessionEvent] = []
        for (index, part) in ["guidance", "closing"].enumerated() {
            guard let recording = recordings["\(step.id).\(voice.rawValue).\(part)"], let url = resourceURL(recording) else { throw DiscoverError.missingAudio }
            let id = stableUUID(recording.sha256)
            urls[id] = url
            events.append(.speech(SessionSpeech(source: .block, assetID: id, storagePath: recording.file, text: part == "guidance" ? step.guidance.value : step.closing.value, durationMilliseconds: recording.durationMs)))
            if index == 0 {
                events.append(.silence(SessionSilence(breaths: step.quietSeconds / 10, landOn: nil, displayText: DiscoverCopy.quiet)))
            }
        }
        let checkpointID = stableUUID("\(path.id).\(step.id).\(voice.rawValue)")
        return SessionPlayback(manifest: SessionManifest(version: 1, stepID: checkpointID, pathKind: .prepared, locale: "en", voice: voice, question: nil, events: events), assetURLs: urls)
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
