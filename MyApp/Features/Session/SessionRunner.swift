import Foundation
import Observation

/// Bir oturumun ilerleyişi: sahneler, saat, duraklatma ve ses.
///
/// Onboarding'in ilk oturumu (G1) ile onboarding sonrası günlük adım aynı şeyi
/// yapıyor — sahneleri sırayla göstermek, sesi çalmak, yarıda bırakılabilmek.
/// İkisi ayrı yazıldığında ikinci ekran ilkinin küçük hatalarını miras almadan
/// yeni hatalar üretiyordu; motor burada tek yerde duruyor. Ekranların kendine
/// özgü kısmı (akış yönlendirmesi, kayıt, soru) dışarıda kalıyor.
@Observable
@MainActor
final class SessionRunner {
    enum Phase: Equatable {
        case preparing
        case running
        case completed
    }

    private(set) var phase: Phase = .preparing
    private(set) var segments: [SessionSegment] = []
    private(set) var index = 0
    private(set) var elapsedInSegment: TimeInterval = 0
    /// Ses yokken (yükleniyor ya da sessiz sürüm) duraklatma burada tutulur.
    /// Ses varken asıl kaynak sesin kendi durumu — bkz. `isPaused`.
    private var manualPause = false
    /// Oturum sonuna kadar gitti mi? "Burada duralım" ile çıkıldığında false.
    private(set) var didReachEnd = false

    let audio = SessionAudioPlayer()

    private var ticker: Task<Void, Never>?
    private var onComplete: (@MainActor (Bool) -> Void)?

    // MARK: - Türetilen durum

    var currentSegment: SessionSegment? {
        segments.indices.contains(index) ? segments[index] : nil
    }

    var totalDuration: TimeInterval {
        segments.reduce(0) { $0 + $1.duration }
    }

    /// Oturumun başından bu yana geçen süre. Ekranda **gösterilmez**; sarma ve
    /// iz bunu okur.
    var elapsed: TimeInterval {
        startTime(of: index) + elapsedInSegment
    }

    /// 0…1. Yüzde **gösterilmez** — bunu okuyan tek şey ince iz.
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return min(1, elapsed / totalDuration)
    }

    /// Duraklatma kilit ekranından, kulaklıktan ya da bir telefon görüşmesinden
    /// de gelebilir. Ses varken durum sesten okunuyor: önceden kilit ekranında
    /// duraklatılan ses susuyor ama ekrandaki sahne akmaya devam ediyordu.
    var isPaused: Bool {
        switch audio.state {
        case .playing: false
        case .paused: true
        default: manualPause
        }
    }

    /// Geri sarma oturumun başında anlamsız.
    var canSkipBackward: Bool { phase == .running && elapsed > 1 }

    /// İleri sarma kapanışın **içine** atlamaz: son sahne her zaman duyulur.
    /// Kapanışa kadar sarmak kullanıcının seçimi; kapanışı atlayıp adımı
    /// "sonuna kadar dinlendi" diye işaretlemek ise olmayan bir şeyi olmuş
    /// göstermek olurdu.
    var canSkipForward: Bool { phase == .running && index + 1 < segments.count }

    /// Sesin durumu kullanıcıya tek satırla söylenir; sessizlik gizlenmez.
    var audioNote: LocalizedStringResource? {
        switch audio.state {
        case .loading: Copy.Session.audioPreparing
        case .playing, .paused, .unavailable, .idle, .finished: nil
        }
    }

    // MARK: - Yaşam döngüsü

    func begin(segments: [SessionSegment], onComplete: @escaping @MainActor (Bool) -> Void) {
        guard phase == .preparing else { return }
        self.segments = segments
        self.onComplete = onComplete
        phase = .running
        startTicker()
    }

    /// Ses hazır olduğunda sahneler manifestin kendi zamanlamasıyla değişir.
    /// Metin ile ses ayrı saatlerde ilerlerse duyulan cümle ekrandakinden
    /// ayrışıyordu — en kötü yerde.
    ///
    /// `offset` sesin başlayacağı an: uygulama oturumun ortasında kapandıysa ses
    /// kaldığı yerden çalıyor, sahne de oradan başlamalı. Önceden sahne sıfıra
    /// dönüyor ve ekrandaki cümle duyulandan dakikalarca geride kalıyordu.
    func replaceSegments(_ replacement: [SessionSegment], startingAt offset: TimeInterval = 0) {
        guard !replacement.isEmpty else { return }
        segments = replacement
        position(at: offset)
    }

    /// Ses çalmaya başladığında çağrılır. Ses yüklenirken kullanıcı
    /// duraklattıysa ses de duraklamış başlar — dokunduğu düğme ne diyorsa o.
    func audioDidStart() {
        guard audio.state == .playing else { return }
        audio.onSkip = { [weak self] delta in self?.skip(by: delta) }
        if manualPause { audio.pause() }
        manualPause = false
        position(at: audio.elapsed)
    }

    func togglePause() {
        switch audio.state {
        case .playing: audio.pause()
        case .paused: audio.resume()
        default: manualPause.toggle()
        }
    }

    /// 15 saniye geri ya da ileri. Duraklamışken de çalışır ve duraklamış kalır:
    /// kaçırdığı cümleyi bulmak isteyen biri sesin kendiliğinden başlamasını
    /// beklemiyor.
    func skip(by delta: TimeInterval) {
        guard phase == .running, !segments.isEmpty else { return }
        let lastStart = startTime(of: segments.count - 1)
        let target = min(max(0, elapsed + delta), max(elapsed, lastStart))
        position(at: target)
        audio.seek(to: target)
    }

    /// "Burada duralım" — oturum yarıda bırakılabilir ve bu bir kayıp değil.
    func leave() {
        finish(reachedEnd: false)
    }

    func teardown() {
        ticker?.cancel()
        audio.stop()
    }

    // MARK: - Saat

    /// Ses çalarken sahne kendi saatini saymaz, sesin saatini okur. İki ayrı
    /// saat uyku ve kesinti sonrası birbirinden kayıyordu; sarma eklenince bu
    /// kayma her dokunuşta büyüyordu.
    private func startTicker() {
        ticker?.cancel()
        ticker = Task { @MainActor [weak self] in
            let step: TimeInterval = 0.1
            while let self, self.phase == .running {
                try? await Task.sleep(for: .seconds(step))
                guard !Task.isCancelled else { return }
                switch self.audio.state {
                case .playing:
                    self.position(at: self.audio.elapsed)
                case .paused:
                    continue
                case .finished:
                    self.finish(reachedEnd: true)
                default:
                    guard !self.manualPause else { continue }
                    self.elapsedInSegment += step * Self.timeScale
                    if self.elapsedInSegment >= (self.currentSegment?.duration ?? 0) {
                        self.advance()
                    }
                }
            }
        }
    }

    private func startTime(of segmentIndex: Int) -> TimeInterval {
        segments.prefix(max(0, segmentIndex)).reduce(0) { $0 + $1.duration }
    }

    /// Sahneyi oturumun `time` anına taşır.
    private func position(at time: TimeInterval) {
        var cursor: TimeInterval = 0
        for (candidate, segment) in segments.enumerated() {
            if time < cursor + segment.duration || candidate == segments.count - 1 {
                index = candidate
                elapsedInSegment = min(max(0, time - cursor), segment.duration)
                return
            }
            cursor += segment.duration
        }
        index = 0
        elapsedInSegment = 0
    }

    private func advance() {
        elapsedInSegment = 0
        guard index + 1 < segments.count else {
            finish(reachedEnd: true)
            return
        }
        index += 1
    }

    private func finish(reachedEnd: Bool) {
        guard phase == .running else { return }
        ticker?.cancel()
        audio.stop()
        didReachEnd = reachedEnd
        phase = .completed
        onComplete?(reachedEnd)
    }

    /// Oturumun hız çarpanı. Release'te her zaman 1.
    ///
    /// On dakikalık bir oturumu her denemede baştan dinlemek G1/G2 üzerinde
    /// çalışmayı durduruyordu. `-patika-debug-session-speed 30` ile oturum
    /// 30 kat hızlı akar; sahnelerin **sırası ve oranları** aynı kalır.
    static var timeScale: TimeInterval {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-patika-debug-session-speed"),
              arguments.index(after: index) < arguments.endIndex,
              let value = Double(arguments[arguments.index(after: index)]),
              value > 0
        else { return 1 }
        return value
        #else
        return 1
        #endif
    }
}
