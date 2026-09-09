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
    private(set) var isPaused = false
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

    /// 0…1. Yüzde **gösterilmez** — bunu okuyan tek şey ince iz.
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        let done = segments.prefix(index).reduce(0) { $0 + $1.duration }
        return min(1, (done + elapsedInSegment) / totalDuration)
    }

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
    func replaceSegments(_ replacement: [SessionSegment]) {
        guard !replacement.isEmpty else { return }
        segments = replacement
        index = 0
        elapsedInSegment = 0
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused { audio.pause() } else { audio.resume() }
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

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { @MainActor [weak self] in
            let step: TimeInterval = 0.1
            while let self, self.phase == .running {
                try? await Task.sleep(for: .seconds(step))
                guard !Task.isCancelled else { return }
                guard !self.isPaused else { continue }
                self.elapsedInSegment += step * Self.timeScale
                if self.elapsedInSegment >= (self.currentSegment?.duration ?? 0) {
                    self.advance()
                }
            }
        }
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
