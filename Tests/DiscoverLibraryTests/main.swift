import Foundation

// Test harness boundary type; the app's BackendClient defines the same transport.
struct SessionPlayback: Sendable {
    let manifest: SessionManifest
    let assetURLs: [UUID: URL]
}

/// Verilen katalogla geçici bir paket kurar; çağıran işi bitince siler.
func makeBundle(catalog: Data, recordings: [String: DiscoverRecording] = [:]) throws -> Bundle {
    let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle")
    let resources = temp.appendingPathComponent("Contents/Resources")
    try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
    try Data("<?xml version=\"1.0\"?><plist version=\"1.0\"><dict><key>CFBundleIdentifier</key><string>test.discover</string></dict></plist>".utf8).write(to: temp.appendingPathComponent("Contents/Info.plist"))
    try catalog.write(to: resources.appendingPathComponent("discover-catalog.json"))
    if !recordings.isEmpty {
        try JSONEncoder().encode(recordings).write(to: resources.appendingPathComponent("discover-audio.json"))
        for recording in Set(recordings.values.map(\.file)) {
            try Data(repeating: 1, count: 2_000).write(to: resources.appendingPathComponent(recording))
        }
    }
    return Bundle(url: temp)!
}

/// Katalog metinlerinin kuralları: yasaklı ifade yok, adım kimlikleri kararlı, kapanış ortak.
/// Kapanışın ortak olması ses kayıtlarının tekrar üretilmemesini sağlar. Sessizlik
/// yazılan süredir (`quietMs`): nefes döngüsüne bölünmek zorunda değil, ama makul.
@MainActor
func checkContent(_ paths: [DiscoverPath]) throws {
    let closing = paths[0].steps[0].closing
    var seen = Set<String>()
    for path in paths {
        for (index, step) in path.steps.enumerated() {
            precondition(step.id == "\(path.id)-\(index + 1)", "Step ids are `<path>-<n>` and never change: \(step.id)")
            precondition(seen.insert(step.id).inserted, "Duplicate step id \(step.id)")
            precondition(step.closing == closing, "Closing is shared so audio is rendered once: \(step.id)")
            precondition((3...6).contains(step.segments.count), "Three to six segments per step: \(step.id) has \(step.segments.count)")
            let quiet = step.segments.reduce(0) { $0 + $1.quietMs }
            precondition((120_000...240_000).contains(quiet), "A step is mostly silence, 2 to 4 minutes of it: \(step.id) \(quiet) ms")
            for segment in step.segments {
                precondition((5_000...120_000).contains(segment.quietMs), "Quiet after a segment stays between 5 and 120 s: \(step.id)")
            }
            let spoken = step.segments.map(\.text) + [step.closing]
            for text in spoken + [step.title] {
                precondition(!text.en.isEmpty, "English text is required: \(step.id)")
                precondition(BannedPhrases.check(text.en).isEmpty, "Banned phrase in \(step.id): \(BannedPhrases.check(text.en))")
                precondition(!text.en.contains("\u{2014}") && text.en.rangeOfCharacter(from: .decimalDigits) == nil,
                             "Spoken text avoids dashes and digits (TTS): \(step.id)")
            }
            let guidance = step.segments.map(\.text.en).joined(separator: " ")
            precondition((200...340).contains(guidance.count), "English guidance length: \(step.id) \(guidance.count)")
        }
    }
}

/// Sahte kayıtlarla: bölüm, yazılan sessizlik, bölüm, ... kapanış.
@MainActor
func checkPlayback(catalogURL: URL) throws {
    let catalog = try DiscoverCatalog.load(bundle: makeBundle(catalog: Data(contentsOf: catalogURL)))
    let path = catalog.paths[0]
    var recordings: [String: DiscoverRecording] = [:]
    var counter = 0
    func record(_ step: DiscoverStep, _ part: String, locale: String = "en", voice: String = "feminine") {
        counter += 1
        recordings["\(step.id).\(locale).\(voice).\(part)"] = DiscoverRecording(
            file: "discover-\(counter).mp3", durationMs: 4_000 + counter, voice: voice, locale: locale,
            sha256: String(format: "%064d", counter), renditionKey: "key\(counter)"
        )
    }
    for step in path.steps { for part in step.parts { record(step, part) } }
    // İngilizce olmayan ya da başka sesli kayıt hazır sayılmaz: yalnızca konuşulan dil + tek ses.
    let other = catalog.paths[1]
    for part in other.steps[0].parts { record(other.steps[0], part, locale: "tr") }
    let bundle = try makeBundle(catalog: Data(contentsOf: catalogURL), recordings: recordings)
    defer { try? FileManager.default.removeItem(at: bundle.bundleURL) }
    let suite = "DiscoverTests.playback.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let library = DiscoverLibrary(defaults: defaults, bundle: bundle)
    precondition(library.status(library.paths[0]) == .available, "A path with every recording is joinable")
    precondition(library.status(library.paths[1]) == .comingSoon, "Recordings in another language do not make a path playable")
    precondition(library.paths.dropFirst(2).allSatisfy { library.status($0) == .comingSoon })

    library.enroll(library.paths[0])
    let step = library.paths[0].steps[0]
    let playback = try library.playback(for: step, in: library.paths[0])
    let events = playback.manifest.events
    precondition(events.count == step.segments.count * 2 + 1, "speech+silence per segment, then the closing: \(events.count)")
    for (index, segment) in step.segments.enumerated() {
        guard case .speech(let spoken) = events[index * 2] else { preconditionFailure("segment \(index) is speech") }
        precondition(spoken.text == segment.text.en, "On-screen text is the spoken text")
        precondition(spoken.leadInMilliseconds == 0)
        guard case .silence(let quiet) = events[index * 2 + 1] else { preconditionFailure("segment \(index) is followed by silence") }
        precondition(quiet.milliseconds == segment.quietMs, "Quiet is the written time, not a rounded breath count")
        precondition(quiet.displayText == nil, "The last instruction stays on screen through the pause")
    }
    guard case .speech(let closing) = events.last! else { preconditionFailure("closing is spoken last") }
    precondition(closing.text == step.closing.en)
    precondition(playback.manifest.voice == .feminine && playback.manifest.locale == "en")
    precondition(playback.manifest.breathMilliseconds == SessionPacing.defaultBreathMilliseconds)
    precondition(playback.assetURLs.count == Set(events.compactMap { event -> UUID? in if case .speech(let s) = event { s.assetID } else { nil } }).count)

    // Sahne saati çizelgeyle aynı: toplam süre = konuşmalar + yazılan sessizlikler.
    let timeline = SessionTimeline(manifest: playback.manifest)
    let expected = Double(step.parts.indices.reduce(0) { $0 + 4_000 + ($1 + 1) }) / 1_000 + Double(step.segments.reduce(0) { $0 + $1.quietMs }) / 1_000
    precondition(abs(timeline.duration - expected) < 1.0, "Timeline follows the recordings and the written silences")
    let scenes = SessionManifestScript.segments(from: timeline)
    precondition(scenes.count == step.segments.count + 1, "One scene per spoken part; silences do not flicker the sentence")

    // Eski kayıtlardaki `voice` alanı okunurken yok sayılır.
    defaults.set(Data(#"{"enrollments":{"breath":{"completed":["breath-1"],"voice":"masculine"}}}"#.utf8), forKey: "discover.library.v1")
    let migrated = DiscoverLibrary(defaults: defaults, bundle: bundle)
    precondition(migrated.completedCount(migrated.paths[0]) == 1, "Progress survives the removal of voice choice")
}

@MainActor
func run() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let catalogURL = root.appendingPathComponent("MyApp/Content/Discover/discover-catalog.json")
    let bundle = try makeBundle(catalog: Data(contentsOf: catalogURL))
    defer { try? FileManager.default.removeItem(at: bundle.bundleURL) }
    let suite = "DiscoverTests.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let library = DiscoverLibrary(defaults: defaults, bundle: bundle)
    precondition(library.paths.count == 10, "One path per problem category")
    precondition(Set(library.paths.map(\.category)) == Set(ProblemCategory.allCases), "Every category has a path")
    precondition(library.audioLocale == .english, "Recordings are English; on-screen spoken text must follow them")
    precondition(library.paths.allSatisfy { library.status($0) == .comingSoon }, "No audio ships, so nothing may look joinable")
    precondition(library.sections.map { $0.section } == [.relief, .rest, .attention, .toSelf], "All four sections are drawn, in screen order")
    precondition(library.sections.map { $0.paths.map(\.id) } == [["breath", "beat", "pressure"], ["evening", "refill"], ["focus", "rooms"], ["kinder", "carry", "unnamed"]], "Shelf order")
    try checkContent(library.paths)
    precondition(Set(ProblemCategory.allCases.map { DiscoverSection(category: $0) }) == Set(DiscoverSection.allCases), "Every section must be reachable")
    precondition(library.inProgressPaths.isEmpty)
    let path = library.paths[0]
    precondition(!library.isEnrolled(path))
    precondition(!library.isAvailable(path.steps[0], in: path), "Preview must never authorize playback")
    precondition(!library.audioIsReady(path), "Missing voice files must not appear playable")
    do { _ = try library.playback(for: path.steps[0], in: path); preconditionFailure("Preview played") }
    catch DiscoverError.notEnrolled {}
    library.enroll(path)
    precondition(library.status(path) == .inProgress(done: 0, total: 7))
    precondition(library.inProgressPaths.map(\.id) == [path.id])
    precondition(library.isAvailable(path.steps[0], in: path))
    precondition(!library.isAvailable(path.steps[1], in: path))
    library.complete(path.steps[1], in: path)
    precondition(library.completedCount(path) == 0, "Locked steps cannot be completed")
    library.complete(path.steps[0], in: path)
    precondition(library.isAvailable(path.steps[1], in: path))
    precondition(library.isAvailable(path.steps[0], in: path), "Replay must remain possible")
    // Katılım Keşfet'te kalır: ikinci patikaya katılmak birincisini bırakmaz ve
    // ilerlemeler karışmaz.
    let other = library.paths[1]
    library.enroll(other)
    precondition(library.isEnrolled(path) && library.isEnrolled(other), "Enrolling a second path must not drop the first")
    precondition(library.completedCount(path) == 1, "Joining another path must preserve progress")
    precondition(library.completedCount(other) == 0, "A new enrollment starts empty")
    precondition(library.inProgressPaths.map(\.id) == [other.id, path.id], "Most recently joined comes first")
    library.complete(other.steps[0], in: other)
    library.complete(path.steps[1], in: path)
    precondition(library.isComplete(other.steps[0], in: other) && !library.isComplete(other.steps[0], in: path), "Step ids never leak between paths")
    precondition(library.completedCount(path) == 2 && library.completedCount(other) == 1, "Progress stays separate")
    library.complete(other.steps[0], in: other)
    precondition(library.completedCount(other) == 1, "Replay is not progress")
    precondition(library.inProgressPaths.map(\.id) == [path.id, other.id], "Most recent progress comes first")
    precondition(library.status(other) == .inProgress(done: 1, total: 7))
    library.enroll(other)
    precondition(library.completedCount(other) == 1, "Enrolling again keeps progress")
    let restored = DiscoverLibrary(defaults: defaults, bundle: bundle)
    precondition(restored.completedCount(path) == 2)
    precondition(restored.completedCount(other) == 1)
    precondition(restored.inProgressPaths.map(\.id) == [other.id, path.id], "Order survives a relaunch")
    for step in path.steps { restored.complete(step, in: path) }
    precondition(restored.nextStep(path) == nil)
    precondition(restored.completedCount(path) == 7)
    precondition(restored.status(path) == .completed)
    precondition(restored.inProgressPaths.map(\.id) == [other.id], "A finished path leaves the continue list")
    // Bu değişiklikten önce yazılmış bir kayıt: hazır patikanın Yolum'u devralmasından
    // kalan `activeID` okunurken yok sayılır, ilerleme kaybolmaz.
    let legacy = "DiscoverTests.legacy.\(UUID())"
    let legacyDefaults = UserDefaults(suiteName: legacy)!
    defer { legacyDefaults.removePersistentDomain(forName: legacy) }
    let step = path.steps[0].id
    legacyDefaults.set(Data("""
    {"activeID":"\(path.id)","enrollments":{"\(path.id)":{"completed":["\(step)"],"voice":"masculine"}}}
    """.utf8), forKey: "discover.library.v1")
    let migrated = DiscoverLibrary(defaults: legacyDefaults, bundle: bundle)
    precondition(migrated.isEnrolled(path) && migrated.completedCount(path) == 1, "Legacy progress must survive")
    precondition(migrated.inProgressPaths.map(\.id) == [path.id])
    try checkPlayback(catalogURL: catalogURL)
    var raw = try JSONSerialization.jsonObject(with: Data(contentsOf: catalogURL)) as! [String: Any]
    var rawPaths = raw["paths"] as! [[String: Any]]
    rawPaths[1]["category"] = rawPaths[0]["category"]
    raw["paths"] = rawPaths
    let duplicate = try makeBundle(catalog: JSONSerialization.data(withJSONObject: raw))
    defer { try? FileManager.default.removeItem(at: duplicate.bundleURL) }
    precondition((try? DiscoverCatalog.load(bundle: duplicate)) == nil, "One path per category")
    print("PASS: preview gating, missing audio, sections, content rules, status, unique categories, sequential steps, replay, multi-enrollment isolation, ordering, legacy record, persistence, completion")
}
try MainActor.assumeIsolated { try run() }
