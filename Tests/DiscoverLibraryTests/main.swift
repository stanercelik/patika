import Foundation

// Test harness boundary type; the app's BackendClient defines the same transport.
struct SessionPlayback: Sendable {
    let manifest: SessionManifest
    let assetURLs: [UUID: URL]
}

@MainActor
func run() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle")
    let resources = temp.appendingPathComponent("Contents/Resources")
    try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temp) }
    try Data("<?xml version=\"1.0\"?><plist version=\"1.0\"><dict><key>CFBundleIdentifier</key><string>test.discover</string></dict></plist>".utf8).write(to: temp.appendingPathComponent("Contents/Info.plist"))
    let catalogURL = root.appendingPathComponent("MyApp/Content/Discover/discover-catalog.json")
    try FileManager.default.copyItem(at: catalogURL, to: resources.appendingPathComponent("discover-catalog.json"))
    let bundle = Bundle(url: temp)!
    let suite = "DiscoverTests.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let library = DiscoverLibrary(defaults: defaults, bundle: bundle)
    precondition(library.paths.count == 3)
    let path = library.paths[0]
    precondition(!library.isEnrolled(path))
    precondition(!library.isAvailable(path.steps[0], in: path), "Preview must never authorize playback")
    precondition(!library.audioIsReady(path), "Missing voice files must not appear playable")
    do { _ = try library.playback(for: path.steps[0], in: path); preconditionFailure("Preview played") }
    catch DiscoverError.notEnrolled {}
    library.enroll(path, voice: .masculine)
    precondition(library.activePath?.id == path.id)
    precondition(library.voice(for: path) == .masculine)
    precondition(library.isAvailable(path.steps[0], in: path))
    precondition(!library.isAvailable(path.steps[1], in: path))
    library.complete(path.steps[1], in: path)
    precondition(library.completedCount(path) == 0, "Locked steps cannot be completed")
    library.complete(path.steps[0], in: path)
    precondition(library.isAvailable(path.steps[1], in: path))
    precondition(library.isAvailable(path.steps[0], in: path), "Replay must remain possible")
    let other = library.paths[1]
    library.enroll(other, voice: .feminine)
    precondition(library.completedCount(path) == 1, "Switching must preserve progress")
    library.openPersonalPath()
    precondition(library.activePath == nil)
    precondition(library.completedCount(path) == 1)
    let restored = DiscoverLibrary(defaults: defaults, bundle: bundle)
    precondition(restored.completedCount(path) == 1)
    precondition(restored.voice(for: path) == .masculine)
    precondition(restored.activePath == nil)
    for step in path.steps { restored.complete(step, in: path) }
    precondition(restored.nextStep(path) == nil)
    precondition(restored.completedCount(path) == 7)
    print("PASS: preview gating, missing audio, sequential steps, replay, switching, persistence, completion")
}
try MainActor.assumeIsolated { try run() }
