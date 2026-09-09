import Foundation
import Observation

/// Oturumdaki tek bir sahne.
///
/// Metin `String`, `LocalizedStringResource` değil: içeriğin bir kısmı sunucudan
/// (kişiselleştirilmiş yuvalar) ve bir kısmı kullanıcının kendi cümlesinden
/// geliyor. Sabit metinler `Copy`den okunup burada çözülüyor.
struct SessionSegment: Identifiable, Equatable {
    enum Kind: Equatable {
        /// Kişiselleştirilmiş açılış — seslendirilen kısım.
        case opening
        /// Kullanıcının kendi cümlesi. Aha momenti (PRD-Ek Onboarding §8).
        case ownWords
        /// Blok kütüphanesinden gelen sabit teknik.
        case technique
        /// Sunucudan gelen geçiş cümlesi.
        case bridge
        case closing
    }

    let id: String
    let text: String
    let kind: Kind
    var duration: TimeInterval
}

/// G1 — ilk oturum (PRD-Ek Onboarding §8).
///
/// ## Bu ekran akışın amacı
///
/// Onboarding'in üç yapısal kararından biri: ilk oturum akışın **içinde** ve
/// kullanıcının kendi cümlesini geri veriyor. Kayıt bundan sonra isteniyor —
/// kullanıcı ilk meditasyonunu dinledikten sonra.
///
/// ## Zamanlama nefes döngüsüne bağlı
///
/// Sahne süreleri saniye değil nefes döngüsü katı (`BreathCycle.period`).
/// Arka plan zaten o döngüyle soluyor; metnin döngü ortasında değişmesi nefesi
/// bölüyordu.
///
/// ## Ses varsa açılışta çalar, yoksa oturum yine tamdır
///
/// Taze TTS yalnızca **açılışı** seslendiriyor (hibrit mimari, PRD §13.3):
/// teknik kısmı sabit ve nefes temposuyla ilerliyor. Ses hazır değilse ya da TTS
/// sağlayıcısı sunucuda yapılandırılmamışsa oturum sessiz çalışır ve bu bir hata
/// olarak gösterilmez — sessiz bir meditasyon eksik bir meditasyon değil.
@Observable
@MainActor
final class FirstSessionViewModel {
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
    private(set) var stepTitle: String = ""
    /// Oturum sonuna kadar gitti mi? "Burada duralım" ile çıkıldığında false.
    /// G2'nin metnini bu belirliyor — yarım bırakılan bir adıma "tamam"
    /// dememek için.
    private(set) var didReachEnd = false

    let audio = SessionAudioPlayer()

    private let flow: OnboardingFlowViewModel
    private var ticker: Task<Void, Never>?
    private var audioTask: Task<Void, Never>?
    private var stepId: UUID?

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
    }

    // MARK: - Türetilen durum
    //
    // Görünüm `if`/hesap yapmıyor; hazır özellikleri okuyor.

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

    var remaining: TimeInterval {
        max(0, totalDuration - progress * totalDuration)
    }

    /// Sesin durumu kullanıcıya tek satırla söylenir; sessizlik gizlenmez.
    var audioNote: LocalizedStringResource? {
        switch audio.state {
        case .loading: Copy.Session.audioPreparing
        case .playing, .paused: nil
        case .unavailable, .idle, .finished: nil
        }
    }

    // MARK: - Yaşam döngüsü

    func start() {
        guard phase == .preparing, segments.isEmpty else { return }
        Task { @MainActor in
            let step = await resolveStep()
            segments = Self.buildSegments(
                step: step,
                draft: flow.draft,
                targetMinutes: flow.draft.sessionLength.minutes
            )
            stepTitle = step?.title ?? String(localized: Copy.Session.fallbackStepTitle)
            phase = .running
            beginAudio()
            beginTicker()
        }
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused { audio.pause() } else { audio.resume() }
    }

    /// "Burada duralım" — oturum yarıda bırakılabilir ve bu bir kayıp değil.
    /// Akış yine G2'ye gider, yalnızca metni değişir.
    func leave() {
        finish(reachedEnd: false)
    }

    func teardown() {
        ticker?.cancel()
        audioTask?.cancel()
        audio.stop()
        flow.updateSessionVoiceEnergy(0)
    }

    // MARK: - Zamanlayıcı

    private func beginTicker() {
        ticker?.cancel()
        ticker = Task { @MainActor in
            let step: TimeInterval = 0.1
            while phase == .running {
                try? await Task.sleep(for: .seconds(step))
                guard !Task.isCancelled else { return }
                guard !isPaused else { continue }
                elapsedInSegment += step * Self.timeScale
                if elapsedInSegment >= currentSegmentDuration {
                    advance()
                }
            }
        }
    }

    private var currentSegmentDuration: TimeInterval {
        currentSegment?.duration ?? 0
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
        ticker?.cancel()
        audio.stop()
        didReachEnd = reachedEnd
        phase = .completed
    }

    // MARK: - Ses

    /// Sesi bekler ama oturumu bekletmez: hazır olduğunda çalar, olmazsa oturum
    /// sessiz sürer. Yoklama aralığı bilerek seyrek — F1'de üretim çoktan
    /// başlatıldı (JIT), buradaki bekleyiş genelde birkaç saniye.
    private func beginAudio() {
        audioTask = Task { @MainActor in
            guard let stepId else { return }
            let services = flow.services
            let deadline = Date.now.addingTimeInterval(45)
            do {
                var token = try await services.auth.validAccessToken()
                while Date.now < deadline, !Task.isCancelled {
                    let status = try await services.backend.audioStatus(
                        pathStepId: stepId,
                        accessToken: token
                    )
                    if status == .ready {
                        guard let playback = try await services.backend.sessionPlayback(
                            pathStepId: stepId,
                            accessToken: token
                        ) else { return }
                        let manifestSegments = Self.buildSegments(from: playback.manifest)
                        if !manifestSegments.isEmpty {
                            segments = manifestSegments
                            index = 0
                            elapsedInSegment = 0
                        }
                        // Uygulama oturumun ortasında kapandıysa oradan devam
                        // eder; baştan başlamak kesintiyi ikinci kez yaşatıyordu.
                        await audio.play(
                            playback: playback,
                            title: stepTitle,
                            startingAt: SessionAudioPlayer.resumeOffset(for: playback.manifest.stepID)
                        ) {}
                        return
                    }
                    if status == .failed || status == .pending { return }
                    try await Task.sleep(for: .seconds(2))
                    token = try await services.auth.validAccessToken()
                }
            } catch {
                services.observability.capture(.audioGeneration)
            }
        }
    }

    /// Oturumun hız çarpanı. Release'te her zaman 1.
    ///
    /// On dakikalık bir oturumu her denemede baştan dinlemek G1/G2 üzerinde
    /// çalışmayı durduruyordu. `-patika-debug-session-speed 30` ile oturum
    /// 30 kat hızlı akar; sahnelerin **sırası ve oranları** aynı kalır, yalnızca
    /// saat hızlanır.
    private static var timeScale: TimeInterval {
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

    // MARK: - Adımı bulmak

    /// Path elde yoksa (uygulama yeniden başlatıldı, ya da geliştirici akışı
    /// ileri sardı) sunucudan en son aktif path okunur. O da yoksa oturum
    /// jenerik bloklarla çalışır — kullanıcı boş ekran görmez.
    private func resolveStep() async -> GeneratedPathStep? {
        if let step = flow.firstStep {
            stepId = flow.firstStepId
            if stepId == nil { await lookupStepId() }
            return step
        }
        do {
            let services = flow.services
            let token = try await services.auth.validAccessToken()
            guard let pathId = try await services.backend.latestPathId(accessToken: token) else {
                return nil
            }
            let record = try await services.backend.pathStep(
                pathId: pathId,
                day: 1,
                accessToken: token
            )
            stepId = record.id
            return GeneratedPathStep(
                day: record.day,
                title: record.title,
                blockIds: record.blockIds,
                slotCopy: record.slotCopy,
                question: record.question
            )
        } catch {
            flow.services.observability.capture(.pathGeneration)
            return nil
        }
    }

    private func lookupStepId() async {
        guard let pathId = flow.generatedPath?.id else { return }
        let services = flow.services
        stepId = try? await services.backend.pathStep(
            pathId: pathId,
            day: 1,
            accessToken: services.auth.validAccessToken()
        ).id
    }

    // MARK: - Sahneleri kurmak

    /// Sunucudan gelen yuvalar + istemcideki sabit bloklar.
    ///
    /// Kişiselleştirme **çerçevede**: açılış, geçişler ve kapanış sunucudan
    /// geliyor; teknik sabit (PRD-Ek Path Üretimi §4). Yuva boşsa yerine
    /// jenerik metin konuyor — eksik yuva oturumu kısaltmaz.
    static func buildSegments(
        step: GeneratedPathStep?,
        draft: OnboardingDraft,
        targetMinutes: Int
    ) -> [SessionSegment] {
        let slots = step?.slotCopy ?? [:]
        var opening: [SessionSegment] = []
        var technique: [SessionSegment] = []
        var closing: [SessionSegment] = []

        opening.append(SessionSegment(
            id: "opening",
            text: slots[BlockLibrary.Slot.opening.rawValue]
                ?? String(localized: Copy.Session.fallbackOpening),
            kind: .opening,
            duration: 2 * BreathCycle.period
        ))

        // Kullanıcının kendi cümlesi — akışın aha momenti. B1 atlandıysa bu
        // sahne hiç kurulmuyor; uydurma bir cümle geri yansıtmak, kişiselleştirme
        // iddiasını en görünür yerde çürütürdü.
        if draft.hasOwnWords {
            opening.append(SessionSegment(
                id: "ownWords",
                text: "“\(draft.problemText)”",
                kind: .ownWords,
                duration: 2 * BreathCycle.period
            ))
        }

        if let bridge = slots[BlockLibrary.Slot.techniqueBridge.rawValue] {
            technique.append(SessionSegment(
                id: "bridge.technique",
                text: bridge,
                kind: .bridge,
                duration: BreathCycle.period
            ))
        }

        let blocks = (step?.blockIds ?? [BlockLibrary.breathAwareness.id])
            .compactMap(BlockLibrary.block(id:))
        let resolvedBlocks = blocks.isEmpty ? [BlockLibrary.breathAwareness] : blocks

        for block in resolvedBlocks {
            for cue in block.cues {
                technique.append(SessionSegment(
                    id: "\(block.id).\(cue.id)",
                    text: String(localized: cue.text),
                    kind: .technique,
                    duration: cue.duration
                ))
            }
        }

        if let mid = slots[BlockLibrary.Slot.midBridge.rawValue], technique.count > 2 {
            technique.insert(
                SessionSegment(
                    id: "bridge.mid",
                    text: mid,
                    kind: .bridge,
                    duration: BreathCycle.period
                ),
                at: technique.count / 2
            )
        }

        closing.append(SessionSegment(
            id: "closing",
            text: slots[BlockLibrary.Slot.closing.rawValue]
                ?? String(localized: Copy.Session.fallbackClosing),
            kind: .closing,
            duration: 2 * BreathCycle.period
        ))

        // E2'nin cevabı burada karşılığını buluyor: teknik kısmın uzunluğu
        // kullanıcının seçtiği süreye ölçekleniyor. Açılış ve kapanış
        // ölçeklenmiyor — bir kez okunan cümleyi uzatmak sessizlik üretiyor.
        let target = TimeInterval(targetMinutes * 60)
        let fixed = (opening + closing).reduce(0) { $0 + $1.duration }
        let natural = technique.reduce(0) { $0 + $1.duration }
        if natural > 0 {
            let factor = min(max((target - fixed) / natural, 0.7), 2.2)
            technique = technique.map { segment in
                var scaled = segment
                // Tam nefes döngüsüne yuvarlanıyor: yarım döngüde değişen metin
                // nefesi ortasından kesiyordu.
                let cycles = max(1, (segment.duration * factor / BreathCycle.period).rounded())
                scaled.duration = cycles * BreathCycle.period
                return scaled
            }
        }

        return opening + technique + closing
    }

    static func buildSegments(from manifest: SessionManifest) -> [SessionSegment] {
        var lastText = ""
        return manifest.events.enumerated().map { index, event in
            switch event {
            case .speech(let speech):
                lastText = speech.text
                let kind: SessionSegment.Kind = speech.source == .personal ? .bridge : .technique
                return SessionSegment(
                    id: "speech.\(speech.assetID.uuidString)",
                    text: speech.text,
                    kind: kind,
                    duration: TimeInterval(speech.durationMilliseconds) / 1_000
                )
            case .gap(let milliseconds):
                return SessionSegment(
                    id: "gap.\(index)",
                    text: lastText,
                    kind: .bridge,
                    duration: TimeInterval(milliseconds) / 1_000
                )
            case .silence(let silence):
                if let displayText = silence.displayText { lastText = displayText }
                return SessionSegment(
                    id: "silence.\(index)",
                    text: lastText,
                    kind: .technique,
                    duration: TimeInterval(silence.breaths) * BreathCycle.period
                )
            }
        }
    }
}
