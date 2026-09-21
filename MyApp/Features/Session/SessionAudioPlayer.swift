import AVFoundation
import Foundation
import MediaPlayer
import Observation

/// Manifest zaman çizelgesini çalan oturum motoru.
///
/// ## Tek dosya değil, sıra
///
/// Sunucu bir MP3 değil bir **manifest** üretiyor: sabit blok sesleri, kişisel
/// konuşma parçaları, bağlantılı cümleler arasındaki kısa geçişler ve nefes
/// sessizlikleri. Sessizlik TTS'e hiç gitmiyor — istemcide zamanlanıyor.
/// Marjın tamamı buna bağlı (PRD §13.3).
///
/// ## Sıralı zamanlama, mutlak değil
///
/// Her dosya tek `AVAudioPlayerNode`'a **mutlak** zamanla verilirse, beklenenden
/// uzun bir dosya sonrasını sessizce iter ve saat kendi fikrinde kalır: metin
/// sesin önüne geçer, iki dosya çakışır. Burada akışın kendisi çizelgedir ve
/// hepsi `at: nil` ile arka arkaya sıralanır:
///
///     [giriş tamponu][orta segment][çıkış tamponu][sessizlik tamponları][giriş]...
///
/// Çakışma yapısal olarak imkânsız. Çizelge, dosyalar yüklenip **ölçüldükten**
/// sonra kurulur; manifestin `durationMs`i yalnızca bir planlama değeridir.
///
/// Fade'ler yalnızca **kenar** tamponlarında (600/250 ms) uygulanır: ortası
/// dosyadan doğrudan çalar. Tamamen fade'lenmiş PCM oturum başına 60-75 MB tutardı.
///
/// ## Kesinti oturumu bitirmez
///
/// Telefon görüşmesi, kulaklığın çıkması ya da uygulamanın kapanması oturumu
/// baştan başlatmaz: kaldığı yer saniyesiyle kaydediliyor ve dönüşte oradan
/// devam ediyor. Meditasyonun ortasında baştan başlamak, kullanıcıya kaybettiği
/// şeyi iki kez yaşatıyordu.
///
/// ## Ses enerjisi görsel bir katman, bir gösterge değil
///
/// Mikser çıkışındaki RMS yumuşatılıp `audioEnergy` olarak yayımlanıyor; arka
/// plan bunu **taban hareketine ek** olarak kullanıyor (en fazla 0.03 konum).
/// Sesle titreyen bir arka plan meditasyonu ekran koruyucusuna çevirirdi.
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
    /// Bağlı grafiğin biçimi. Biçim değişirse (farklı örnekleme hızlı ikinci oturum)
    /// grafik yeniden bağlanır; eski bağlantı formatı sessizce kullanılmaz.
    private var graphFormat: AVAudioFormat?
    private var files: [AVAudioFile] = []
    /// Sarma zaman çizelgesini yeniden kurar; yüklenen dosyalar ve biçim bu
    /// yüzden oynatma boyunca elde tutuluyor.
    private var timeline: SessionTimeline?
    private var loadedFiles: [UUID: AVAudioFile] = [:]
    private var format: AVAudioFormat?
    /// Ölçülmüş dosya sürelerinden kurulan çizelge. Ekran sahneleri **bundan**
    /// türetilir (`SessionRunner.audioDidStart`): ses ve ekran aynı sayıyı okur.
    private(set) var resolvedTimeline: SessionTimeline?
    /// Son kurulan çizelgenin başladığı an; `playerTime` bu ofsete göre okunur.
    private var scheduleOrigin: TimeInterval = 0
    private var completionTask: Task<Void, Never>?
    private var envelope = SessionEnvelope()
    private var onFinish: (@MainActor () -> Void)?
    private var nowPlayingTitle = ""
    private var observers: [NSObjectProtocol] = []

    /// Oynatmanın başladığı an ve o ana kadar birikmiş süre. Sayaç yerine
    /// monotonik saat: `elapsed += 0.05` döngüsü uyku ve kesinti sonrası
    /// kayıyordu, ekrandaki cümle sesin gerisinde kalıyordu.
    private let clock = ContinuousClock()
    private var clockOrigin: ContinuousClock.Instant?
    private var accumulated: TimeInterval = 0
    private var checkpointKey: String?
    var isPlaying: Bool { state == .playing }

    /// Kilit ekranındaki ve kulaklıktaki 15 saniye düğmeleri. Sahne saati de
    /// taşınsın diye sarma kararı oturum motorunda (`SessionRunner.skip`).
    var onSkip: (@MainActor (TimeInterval) -> Void)?

    /// Kilit ekranı ve oturum ekranı aynı aralığı kullanır.
    static let skipInterval: TimeInterval = 15

    // MARK: - Oynatma

    func play(
        playback: SessionPlayback,
        title: String,
        startingAt offset: TimeInterval = 0,
        onFinish: @escaping @MainActor () -> Void
    ) async {
        stop(resetState: false)
        self.onFinish = onFinish
        nowPlayingTitle = title
        checkpointKey = Self.checkpointKey(for: playback.manifest.stepID)
        state = .loading

        do {
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
            // Tek node tek biçim çalar. Farklı biçimli dosya karışırsa zamanlama
            // tanımsız olur; sessizce çalmak yerine oturum sessiz sürüme düşer.
            guard loaded.values.allSatisfy({ $0.processingFormat == format }) else {
                throw BackendError.unavailable(status: -1, code: "audio_format_mismatch")
            }

            // Önce ÖLÇ, sonra çizelgeyi kur. `durationMs` dosyanın baş/son
            // sessizliğini içermiyordu: eski sıralamada (çizelge dosyalardan önce)
            // uzun bir dosya sonrasını itiyordu.
            let measured = loaded.mapValues { TimeInterval($0.length) / $0.processingFormat.sampleRate }
            let timeline = SessionTimeline(manifest: playback.manifest, measured: measured)

            try configureSession()
            buildGraph(format: format)
            observeInterruptions()
            files = Array(loaded.values)
            self.timeline = timeline
            self.resolvedTimeline = timeline
            self.loadedFiles = loaded
            self.format = format
            duration = timeline.duration
            let start = min(max(offset, 0), max(0, timeline.duration - 1))
            accumulated = start
            elapsed = start

            schedule(timeline: timeline, files: loaded, format: format, from: start)

            if !engine.isRunning { try engine.start() }
            voice.volume = 0.86
            voice.play()
            clockOrigin = clock.now
            state = .playing
            startCompletionClock()
            updateNowPlaying(rate: 1)
            configureRemoteCommands()
        } catch {
            state = .unavailable(reason: (error as? LocalizedError)?.errorDescription ?? String(describing: error))
        }
    }

    // MARK: - Çizelge

    private func schedule(
        timeline: SessionTimeline,
        files: [UUID: AVAudioFile],
        format: AVAudioFormat,
        from start: TimeInterval
    ) {
        scheduleOrigin = start
        SessionScheduler(voice: voice).schedule(timeline: timeline, files: files, format: format, from: start)
    }

    func pause() {
        guard state == .playing else { return }
        voice.pause()
        engine.pause()
        commitClock()
        state = .paused
        saveCheckpoint()
        updateNowPlaying(rate: 0)
    }

    func resume() {
        guard state == .paused else { return }
        try? engine.start()
        voice.play()
        clockOrigin = clock.now
        state = .playing
        updateNowPlaying(rate: 1)
    }

    func stop() { stop(resetState: true) }

    /// Zaman çizelgesinde `time` anına atlar. Duraklamışken duraklamış kalır.
    ///
    /// Düğüm durdurulup çizelge o andan yeniden kuruluyor: `scheduleSegment`
    /// cümlenin ortasına düşen parçayı kaldığı yerden çaldığı için kesinti
    /// sonrası devamla aynı yol.
    func seek(to time: TimeInterval) {
        guard state == .playing || state == .paused,
              let timeline, let format
        else { return }
        let wasPlaying = state == .playing
        let target = min(max(time, 0), max(0, duration - 1))
        commitClock()
        voice.stop()
        accumulated = target
        elapsed = target
        schedule(timeline: timeline, files: loadedFiles, format: format, from: target)
        if wasPlaying {
            voice.play()
            clockOrigin = clock.now
        }
        saveCheckpoint()
        updateNowPlaying(rate: wasPlaying ? 1 : 0)
    }

    /// Kullanıcı adımı bitirdiğinde çağrılır: kaldığı yer kaydı silinir, yoksa
    /// tamamlanmış bir adım bir daha açıldığında ortasından başlıyordu.
    func clearCheckpoint() {
        guard let checkpointKey else { return }
        UserDefaults.standard.removeObject(forKey: checkpointKey)
    }

    /// Bu adım için kaydedilmiş kalınan an. Yoksa sıfır.
    static func resumeOffset(for stepID: UUID) -> TimeInterval {
        UserDefaults.standard.double(forKey: checkpointKey(for: stepID))
    }

    private static func checkpointKey(for stepID: UUID) -> String {
        "patika.session.checkpoint.\(stepID.uuidString.lowercased())"
    }

    private func saveCheckpoint() {
        guard let checkpointKey, elapsed > 0, elapsed < duration else { return }
        UserDefaults.standard.set(elapsed, forKey: checkpointKey)
    }

    private func stop(resetState: Bool) {
        completionTask?.cancel()
        commitClock()
        saveCheckpoint()
        voice.stop()
        if engine.isRunning { engine.stop() }
        files.removeAll()
        loadedFiles.removeAll()
        timeline = nil
        resolvedTimeline = nil
        format = nil
        elapsed = 0
        accumulated = 0
        clockOrigin = nil
        audioEnergy = 0
        removeObservers()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPRemoteCommandCenter.shared().playCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().pauseCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().skipForwardCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().skipBackwardCommand.removeTarget(nil)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if resetState, state != .finished { state = .idle }
    }

    private func seconds(since instant: ContinuousClock.Instant) -> TimeInterval {
        let components = instant.duration(to: clock.now).components
        return TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1e18
    }

    private func commitClock() {
        guard let clockOrigin else { return }
        accumulated += seconds(since: clockOrigin)
        self.clockOrigin = nil
    }

    // MARK: - Kesinti ve rota

    /// Telefon görüşmesi, Siri, kulaklığın çıkması.
    ///
    /// `.oldDeviceUnavailable` kulaklığın çıkması demek: ses hoparlöre atlarsa
    /// kullanıcının kendi cümlesi odadaki herkese duyulur. Bu yüzden duraklıyor.
    private func observeInterruptions() {
        removeObservers()
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated { self?.handleInterruption(notification) }
        })
        observers.append(center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated { self?.handleRouteChange(notification) }
        })
    }

    private func removeObservers() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
    }

    private func handleInterruption(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw)
        else { return }
        switch type {
        case .began:
            pause()
        case .ended:
            // Kendiliğinden devam etmiyor: kullanıcı "Devam" diyene kadar
            // duraklamış kalıyor. Görüşme biter bitmez sesin patlaması,
            // kesintinin kendisinden daha rahatsız ediciydi.
            try? AVAudioSession.sharedInstance().setActive(true)
        @unknown default:
            pause()
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: raw),
              reason == .oldDeviceUnavailable
        else { return }
        pause()
    }

    // MARK: - Graf

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [])
        try session.setActive(true)
    }

    private func buildGraph(format: AVAudioFormat) {
        // Aynı biçimde kurulu grafik yeniden kullanılır. Biçim farklıysa (başka
        // örnekleme hızlı ikinci oturum) eski bağlantı formatıyla çalmak tanımsızdı;
        // motor bu noktada durdurulmuş (`stop`) olduğundan yeniden bağlanabilir.
        if let graphFormat {
            guard graphFormat != format else { return }
            mixer.removeTap(onBus: 0)
            engine.disconnectNodeOutput(voice)
            engine.disconnectNodeOutput(mixer)
        } else {
            engine.attach(voice)
            engine.attach(mixer)
        }
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
        graphFormat = format
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
                self.tick()
            }
            guard let self, !Task.isCancelled else { return }
            self.state = .finished
            self.clearCheckpoint()
            self.updateNowPlaying(rate: 0)
            self.onFinish?()
        }
    }

    /// Oynatıcı düğümünün gerçekten çaldığı an (çizelge saniyesi). Yoksa nil.
    private func renderedElapsed() -> TimeInterval? {
        guard let nodeTime = voice.lastRenderTime, nodeTime.isSampleTimeValid,
              let playerTime = voice.playerTime(forNodeTime: nodeTime),
              playerTime.sampleTime >= 0, playerTime.sampleRate > 0
        else { return nil }
        return scheduleOrigin + TimeInterval(playerTime.sampleTime) / playerTime.sampleRate
    }

    /// Yeniden bağlanmayan tek sapma kaynağı: monotonik saat ile gerçek çalma
    /// aynı hızda akmıyor (uyku, çıkış aygıtı saati). Saniyede bir gerçeğe bakılır;
    /// 150 ms'den fazla ayrışırsa saat düzeltilir.
    private static let driftTolerance: TimeInterval = 0.15

    private func tick() {
        guard state == .playing, let clockOrigin else { return }
        var current = accumulated + seconds(since: clockOrigin)
        if let rendered = renderedElapsed(), abs(rendered - current) > Self.driftTolerance {
            accumulated += rendered - current
            current = rendered
        }
        elapsed = min(duration, max(0, current))
        // Uygulama kapanırsa son kayıt buradan kalır; her karede yazmıyor.
        if Int(elapsed * 10) % 50 == 0 { saveCheckpoint() }
    }

    // MARK: - Varlıklar

    private func downloadedFile(from URL: URL, assetID: UUID) async throws -> AVAudioFile {
        if URL.isFileURL { return try AVAudioFile(forReading: URL) }
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
        // Kişisel ses cihazda da yedeklenmiyor: iCloud'a çıkan bir oturum
        // kaydı, kullanıcının kendi cümlesini bizim taşımadığımız bir yere
        // taşırdı.
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutable = destination
        try? mutable.setResourceValues(values)
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
        center.skipForwardCommand.removeTarget(nil)
        center.skipBackwardCommand.removeTarget(nil)
        center.skipForwardCommand.preferredIntervals = [NSNumber(value: Self.skipInterval)]
        center.skipBackwardCommand.preferredIntervals = [NSNumber(value: Self.skipInterval)]
        center.skipForwardCommand.isEnabled = true
        center.skipBackwardCommand.isEnabled = true
        center.skipForwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.onSkip?(Self.skipInterval) }
            return .success
        }
        center.skipBackwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.onSkip?(-Self.skipInterval) }
            return .success
        }
    }
}
