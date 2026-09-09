import AVFoundation
import Foundation
import MediaPlayer
import Observation

/// Oturum sesinin çalar tarafı — PRD §13 hibrit ses mimarisi.
///
/// ## Neden `AVAudioPlayer` değil `AVAudioEngine`
///
/// Bugün çalınan tek bir dosya var (1. adımın taze TTS açılışı) ve o kadarı için
/// `AVAudioPlayer` yeterdi. Mimari yine de motor üzerine kuruluyor çünkü hedef
/// yapı **iki kaynağı aynı anda** çalmak: oturumun ~%70'i önceden render edilmiş
/// blok sesi, ~%30'u taze TTS (PRD §13.3). O yapıya sonradan geçmek, çalar
/// tarafını baştan yazmak demek olurdu.
///
/// İki `AVAudioPlayerNode` tek bir `AVAudioMixerNode`a bağlı: `voice` taze
/// seslendirme, `bed` önceden render edilmiş bloklar. `bed` şu an kullanılmıyor
/// ama graf yerinde duruyor — sessizlik de TTS ile değil, istemcide zamanlamayla
/// üretilecek (PRD §13.3), yani doğru yer burası.
///
/// ## Ses kimliği sabittir
///
/// Model ve voice ID sunucuda sabit (`providers.ts`). Değiştirmek tüm blok
/// kütüphanesini yeniden render ettirir; bu yüzden istemci tarafında hiçbir ses
/// parametresi yok.
@Observable
@MainActor
final class SessionAudioPlayer {
    enum State: Equatable {
        case idle
        case loading
        case playing
        case paused
        case finished
        /// Ses yok ve **bu bir hata durumu değil**: TTS sağlayıcısı henüz
        /// yapılandırılmamış olabilir. Oturum sessiz sürümde devam eder.
        case unavailable(reason: String)
    }

    private(set) var state: State = .idle
    private(set) var duration: TimeInterval = 0

    private let engine = AVAudioEngine()
    private let voice = AVAudioPlayerNode()
    private let bed = AVAudioPlayerNode()
    private let mixer = AVAudioMixerNode()

    private var isGraphBuilt = false
    private var onFinish: (@MainActor () -> Void)?
    private var nowPlayingTitle: String = ""

    var isPlaying: Bool { state == .playing }
    var hasAudio: Bool {
        switch state {
        case .playing, .paused, .finished: true
        default: false
        }
    }

    // MARK: - Yükleme

    /// Uzak sesi indirir, grafa bağlar ve çalar.
    ///
    /// Hata **fırlatılmaz**: sesin gelmemesi oturumu durduran bir şey değil.
    /// Çağıran taraf `state`e bakar; `.unavailable` sessiz sürüm demektir.
    func play(url: URL, title: String, onFinish: @escaping @MainActor () -> Void) async {
        self.onFinish = onFinish
        self.nowPlayingTitle = title
        state = .loading

        do {
            let file = try await downloadedFile(from: url)
            try configureSession()
            buildGraph(format: file.processingFormat)
            duration = Double(file.length) / file.processingFormat.sampleRate

            if !engine.isRunning { try engine.start() }
            voice.scheduleFile(file, at: nil) { [weak self] in
                Task { @MainActor in self?.finish() }
            }
            voice.play()
            state = .playing
            updateNowPlaying(rate: 1)
            configureRemoteCommands()
        } catch {
            state = .unavailable(reason: (error as? LocalizedError)?.errorDescription
                ?? String(describing: error))
        }
    }

    func pause() {
        guard state == .playing else { return }
        voice.pause()
        bed.pause()
        engine.pause()
        state = .paused
        updateNowPlaying(rate: 0)
    }

    func resume() {
        guard state == .paused else { return }
        try? engine.start()
        voice.play()
        bed.play()
        state = .playing
        updateNowPlaying(rate: 1)
    }

    /// Oturumdan çıkılırken. Ses oturumu da bırakılır — meditasyon bitince
    /// telefonun sesi uygulamanın elinde kalmamalı.
    func stop() {
        voice.stop()
        bed.stop()
        if engine.isRunning { engine.stop() }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPRemoteCommandCenter.shared().playCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().pauseCommand.removeTarget(nil)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if state != .finished { state = .idle }
    }

    // MARK: - Kurulum

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        // `.playback`: sessize alma anahtarı meditasyonu susturmamalı ve
        // uygulama arka plana gidince ses devam etmeli (PRD §13.3).
        try session.setCategory(.playback, mode: .spokenAudio, options: [])
        try session.setActive(true)
    }

    private func buildGraph(format: AVAudioFormat) {
        guard !isGraphBuilt else { return }
        engine.attach(voice)
        engine.attach(bed)
        engine.attach(mixer)
        engine.connect(voice, to: mixer, format: format)
        engine.connect(bed, to: mixer, format: format)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)
        engine.prepare()
        isGraphBuilt = true
    }

    private func downloadedFile(from url: URL) async throws -> AVAudioFile {
        let (temporaryURL, response) = try await URLSession.shared.download(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw BackendError.unavailable(
                status: (response as? HTTPURLResponse)?.statusCode ?? -1,
                code: "audio_download_failed"
            )
        }
        // İndirilen geçici dosya bu fonksiyon dönünce siliniyor; `AVAudioFile`
        // dosyayı açık tuttuğu için kalıcı bir yere taşınması gerekiyor.
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(url.pathExtension.isEmpty ? "mp3" : url.pathExtension)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
        return try AVAudioFile(forReading: destination)
    }

    private func finish() {
        guard state == .playing else { return }
        state = .finished
        updateNowPlaying(rate: 0)
        onFinish?()
    }

    // MARK: - Kilit ekranı

    private func updateNowPlaying(rate: Double) {
        // Başlık path adıdır, **sorun adı değil**: kilit ekranına bakan biri
        // kullanıcının neyle uğraştığını öğrenmemeli (PRD §13.5 gizlilik).
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: nowPlayingTitle,
            MPMediaItemPropertyArtist: "Patika",
            MPMediaItemPropertyPlaybackDuration: duration,
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
        // İleri/geri sarma yok: meditasyonun ortasından atlamak oturumun
        // yapısını bozuyor ve kilit ekranında kazayla basılıyor.
        center.skipForwardCommand.isEnabled = false
        center.skipBackwardCommand.isEnabled = false
    }
}
