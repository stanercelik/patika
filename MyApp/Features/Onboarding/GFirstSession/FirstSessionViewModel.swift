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
    typealias Phase = SessionRunner.Phase

    /// Motor paylaşılıyor: aynı oturum onboarding sonrası "Yolum" sekmesinde de
    /// çalışıyor (`PathSessionViewModel`). Bu sınıfta kalan tek şey akışa özgü
    /// olan kısım — adımı bulmak, sahneleri kurmak ve G2'ye devretmek.
    let runner = SessionRunner()

    private(set) var stepTitle: String = ""

    private let flow: OnboardingFlowViewModel
    private var audioTask: Task<Void, Never>?
    private var stepId: UUID?

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
    }

    // MARK: - Türetilen durum
    //
    // Görünüm `if`/hesap yapmıyor; hazır özellikleri okuyor.

    var phase: Phase { runner.phase }
    var currentSegment: SessionSegment? { runner.currentSegment }
    var progress: Double { runner.progress }
    var isPaused: Bool { runner.isPaused }
    var didReachEnd: Bool { runner.didReachEnd }
    var audio: SessionAudioPlayer { runner.audio }
    var audioNote: LocalizedStringResource? { runner.audioNote }

    // MARK: - Yaşam döngüsü

    func start() {
        guard runner.phase == .preparing, runner.segments.isEmpty else { return }
        Task { @MainActor in
            let step = await resolveStep()
            let segments = SessionScript.build(
                step: step,
                ownWords: flow.draft.hasOwnWords ? flow.draft.problemText : nil,
                targetMinutes: flow.draft.sessionLength.minutes
            )
            stepTitle = step?.title ?? String(localized: Copy.Session.fallbackStepTitle)
            runner.begin(segments: segments) { _ in }
            beginAudio()
        }
    }

    func togglePause() { runner.togglePause() }

    /// "Burada duralım" — oturum yarıda bırakılabilir ve bu bir kayıp değil.
    /// Akış yine G2'ye gider, yalnızca metni değişir.
    func leave() { runner.leave() }

    func teardown() {
        audioTask?.cancel()
        runner.teardown()
        flow.updateSessionVoiceEnergy(0)
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
                        // Uygulama oturumun ortasında kapandıysa oradan devam
                        // eder; baştan başlamak kesintiyi ikinci kez yaşatıyordu.
                        let offset = SessionAudioPlayer.resumeOffset(for: playback.manifest.stepID)
                        runner.replaceSegments(SessionScript.build(from: playback.manifest), startingAt: offset)
                        await audio.play(
                            playback: playback,
                            title: stepTitle,
                            startingAt: offset
                        ) {}
                        runner.audioDidStart()
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
}
