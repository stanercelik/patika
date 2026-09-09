import AVFoundation
import Foundation
import MediaPlayer
import Observation

@Observable
@MainActor
final class SessionAudioPlayer {
    enum State: Equatable {
        case idle, loading, playing, paused, finished
        case unavailable(reason: String)
    }

    private(set) var state: State = .idle
    private(set) var duration: TimeInterval = 0
    private(set) var elapsed: TimeInterval = 0
    private(set) var audioEnergy: Double = 0

    private let engine = AVAudioEngine()
    private let voice = AVAudioPlayerNode()
    private let mixer = AVAudioMixerNode()
    private var isGraphBuilt = false
    private var files: [AVAudioFile] = []
    private var completionTask: Task<Void, Never>?
    private var envelope = SessionEnvelope()
    private var onFinish: (@MainActor () -> Void)?
    private var nowPlayingTitle = ""

    var isPlaying: Bool { state == .playing }

    func play(
        playback: SessionPlayback,
        title: String,
        onFinish: @escaping @MainActor () -> Void
    ) async {
        stop(resetState: false)
        self.onFinish = onFinish
        nowPlayingTitle = title
        state = .loading

        do {
            let timeline = SessionTimeline(manifest: playback.manifest)
            var loaded: [UUID: AVAudioFile] = [:]
            for event in playback.manifest.events {
                guard case .speech(let speech) = event,
                      loaded[speech.assetID] == nil,
                      let URL = playback.assetURLs[speech.assetID]
                else { continue }
                loaded[speech.assetID] = try await downloadedFile(from: URL, assetID: speech.assetID)
            }
            guard let format = loaded.values.first?.processingFormat else {
                throw BackendError.unavailable(status: -1, code: "audio_assets_missing")
            }

            try configureSession()
            buildGraph(format: format)
            files = Array(loaded.values)
            duration = timeline.duration
            elapsed = 0

            for entry in timeline.entries {
                guard case .speech(let speech) = entry.event,
                      let file = loaded[speech.assetID]
                else { continue }
                let start = AVAudioFramePosition((entry.start * format.sampleRate).rounded())
                voice.scheduleFile(
                    file,
                    at: AVAudioTime(sampleTime: start, atRate: format.sampleRate),
                    completionCallbackType: .dataConsumed
                ) { _ in }
            }

            if !engine.isRunning { try engine.start() }
            voice.volume = 0.86
            voice.play()
            state = .playing
            startCompletionClock()
            updateNowPlaying(rate: 1)
            configureRemoteCommands()
        } catch {
            state = .unavailable(reason: (error as? LocalizedError)?.errorDescription ?? String(describing: error))
        }
    }

    func pause() {
        guard state == .playing else { return }
        voice.pause()
        engine.pause()
        state = .paused
        updateNowPlaying(rate: 0)
    }

    func resume() {
        guard state == .paused else { return }
        try? engine.start()
        voice.play()
        state = .playing
        updateNowPlaying(rate: 1)
    }

    func stop() { stop(resetState: true) }

    private func stop(resetState: Bool) {
        completionTask?.cancel()
        voice.stop()
        if engine.isRunning { engine.stop() }
        files.removeAll()
        elapsed = 0
        audioEnergy = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPRemoteCommandCenter.shared().playCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().pauseCommand.removeTarget(nil)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if resetState, state != .finished { state = .idle }
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [])
        try session.setActive(true)
    }

    private func buildGraph(format: AVAudioFormat) {
        guard !isGraphBuilt else { return }
        engine.attach(voice)
        engine.attach(mixer)
        engine.connect(voice, to: mixer, format: format)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)
        mixer.outputVolume = 0.85
        mixer.installTap(onBus: 0, bufferSize: 2_205, format: format) { [weak self] buffer, _ in
            guard let samples = buffer.floatChannelData?.pointee else { return }
            let count = Int(buffer.frameLength)
            guard count > 0 else { return }
            var sum: Float = 0
            for index in 0..<count { sum += samples[index] * samples[index] }
            let rms = sqrt(Double(sum) / Double(count))
            let normalized = min(max(rms * 8, 0), 1)
            Task { @MainActor [weak self] in self?.receiveEnergy(normalized) }
        }
        engine.prepare()
        isGraphBuilt = true
    }

    private func receiveEnergy(_ target: Double) {
        audioEnergy = envelope.advance(toward: target, delta: 0.05)
    }

    private func startCompletionClock() {
        completionTask?.cancel()
        completionTask = Task { @MainActor [weak self] in
            while let self, self.elapsed < self.duration {
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled else { return }
                if self.state == .playing { self.elapsed += 0.05 }
            }
            guard let self, !Task.isCancelled else { return }
            self.state = .finished
            self.updateNowPlaying(rate: 0)
            self.onFinish?()
        }
    }

    private func downloadedFile(from URL: URL, assetID: UUID) async throws -> AVAudioFile {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PatikaAudio", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent(assetID.uuidString.lowercased()).appendingPathExtension("mp3")
        if FileManager.default.fileExists(atPath: destination.path) { return try AVAudioFile(forReading: destination) }

        let (temporaryURL, response) = try await URLSession.shared.download(from: URL)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw BackendError.unavailable(status: (response as? HTTPURLResponse)?.statusCode ?? -1, code: "audio_download_failed")
        }
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
        return try AVAudioFile(forReading: destination)
    }

    private func updateNowPlaying(rate: Double) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: nowPlayingTitle,
            MPMediaItemPropertyArtist: "Patika",
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: rate,
        ]
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        center.skipForwardCommand.isEnabled = false
        center.skipBackwardCommand.isEnabled = false
    }
}
