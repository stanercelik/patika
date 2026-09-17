import Foundation
import Observation

@Observable @MainActor
final class DiscoverSessionViewModel {
    let audio = SessionAudioPlayer()
    let path: DiscoverPath
    let step: DiscoverStep
    private let library: DiscoverLibrary
    private(set) var finished = false
    private(set) var failed = false
    private(set) var isPreparing = true
    private var playback: SessionPlayback?
    private var generation = 0

    init(path: DiscoverPath, step: DiscoverStep, library: DiscoverLibrary) {
        self.path = path; self.step = step; self.library = library
    }
    var progress: Double { audio.duration > 0 ? audio.elapsed / audio.duration : 0 }
    var sceneText: String {
        guard let playback else { return DiscoverCopy.loading }
        var time: TimeInterval = 0
        for event in playback.manifest.events {
            switch event {
            case .speech(let speech):
                time += Double(speech.durationMilliseconds) / 1000
                if audio.elapsed < time { return speech.text }
            case .silence(let silence):
                time += Double(silence.breaths) * 10
                if audio.elapsed < time { return silence.displayText ?? DiscoverCopy.quiet }
            case .gap(let milliseconds): time += Double(milliseconds) / 1000
            }
        }
        return step.closing.value
    }
    func start() async {
        generation += 1
        let current = generation
        isPreparing = true; failed = false
        do {
            let value = try library.playback(for: step, in: path)
            playback = value
            await audio.play(playback: value, title: step.title.value, startingAt: SessionAudioPlayer.resumeOffset(for: value.manifest.stepID)) { [weak self] in
                guard let self, self.generation == current else { return }
                self.library.complete(self.step, in: self.path)
                self.finished = true
            }
            guard generation == current, !Task.isCancelled else { audio.stop(); return }
            if case .unavailable = audio.state { failed = true }
        } catch { failed = true }
        isPreparing = false
    }
    func togglePause() {
        if audio.isPlaying { audio.pause() } else { audio.resume() }
    }
    func stop() { generation += 1; audio.stop() }
}

