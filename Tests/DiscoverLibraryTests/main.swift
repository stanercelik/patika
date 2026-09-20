import Foundation

// Test harness boundary type; the app's BackendClient defines the same transport.
struct SessionPlayback: Sendable {
    let manifest: SessionManifest
    let assetURLs: [UUID: URL]
}

/// Verilen katalogla geçici bir paket kurar; çağıran işi bitince siler.
func makeBundle(catalog: Data) throws -> Bundle {
    let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle")
    let resources = temp.appendingPathComponent("Contents/Resources")
    try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
    try Data("<?xml version=\"1.0\"?><plist version=\"1.0\"><dict><key>CFBundleIdentifier</key><string>test.discover</string></dict></plist>".utf8).write(to: temp.appendingPathComponent("Contents/Info.plist"))
    try catalog.write(to: resources.appendingPathComponent("discover-catalog.json"))
    return Bundle(url: temp)!
}

/// Katalog metinlerinin kuralları: yasaklı ifade yok, adım kimlikleri kararlı, kapanış ortak.
/// Kapanışın ortak olması ses kayıtlarının tekrar üretilmemesini sağlar; sessizlik nefes
/// döngüsüne (10 sn) bölünebilir olmalı (`SessionSilence.breaths`).
@MainActor
func checkContent(_ paths: [DiscoverPath]) throws {
    let closing = paths[0].steps[0].closing
    var seen = Set<String>()
    for path in paths {
        for (index, step) in path.steps.enumerated() {
            precondition(step.id == "\(path.id)-\(index + 1)", "Step ids are `<path>-<n>` and never change: \(step.id)")
            precondition(seen.insert(step.id).inserted, "Duplicate step id \(step.id)")
            precondition(step.closing == closing, "Closing is shared so audio is rendered once: \(step.id)")
            precondition(step.quietSeconds > 0 && step.quietSeconds % 10 == 0, "Quiet time is whole breath cycles: \(step.id)")
            for text in [step.guidance, step.closing, step.title] {
                precondition(!text.en.isEmpty && !text.tr.isEmpty, "Both languages are required: \(step.id)")
                for value in [text.en, text.tr] {
                    precondition(BannedPhrases.check(value).isEmpty, "Banned phrase in \(step.id): \(BannedPhrases.check(value))")
                    precondition(!value.contains("\u{2014}") && value.rangeOfCharacter(from: .decimalDigits) == nil,
                                 "Spoken text avoids dashes and digits (TTS): \(step.id)")
                }
            }
            precondition((200...340).contains(step.guidance.en.count), "English guidance length: \(step.id) \(step.guidance.en.count)")
        }
    }
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
    library.enroll(path, voice: .masculine)
    precondition(library.status(path) == .inProgress(done: 0, total: 7))
    precondition(library.inProgressPaths.map(\.id) == [path.id])
    precondition(library.voice(for: path) == .masculine)
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
    library.enroll(other, voice: .feminine)
    precondition(library.isEnrolled(path) && library.isEnrolled(other), "Enrolling a second path must not drop the first")
    precondition(library.completedCount(path) == 1, "Joining another path must preserve progress")
    precondition(library.completedCount(other) == 0, "A new enrollment starts empty")
    precondition(library.voice(for: path) == .masculine && library.voice(for: other) == .feminine, "Voices are per path")
    precondition(library.inProgressPaths.map(\.id) == [other.id, path.id], "Most recently joined comes first")
    library.complete(other.steps[0], in: other)
    library.complete(path.steps[1], in: path)
    precondition(library.isComplete(other.steps[0], in: other) && !library.isComplete(other.steps[0], in: path), "Step ids never leak between paths")
    precondition(library.completedCount(path) == 2 && library.completedCount(other) == 1, "Progress stays separate")
    library.complete(other.steps[0], in: other)
    precondition(library.completedCount(other) == 1, "Replay is not progress")
    precondition(library.inProgressPaths.map(\.id) == [path.id, other.id], "Most recent progress comes first")
    precondition(library.status(other) == .inProgress(done: 1, total: 7))
    library.enroll(other, voice: .masculine)
    precondition(library.completedCount(other) == 1, "Enrolling again keeps progress")
    precondition(library.voice(for: other) == .masculine)
    let restored = DiscoverLibrary(defaults: defaults, bundle: bundle)
    precondition(restored.completedCount(path) == 2)
    precondition(restored.completedCount(other) == 1)
    precondition(restored.voice(for: path) == .masculine)
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
    precondition(migrated.voice(for: path) == .masculine)
    precondition(migrated.inProgressPaths.map(\.id) == [path.id])
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
