import Foundation
import Observation

/// Onboarding sonrası bir adımın oturumu.
///
/// G1 ile aynı motoru (`SessionRunner`) ve aynı sahneyi kullanır; farkı adımın
/// nereden geldiği ve sonunda ne olduğu: burada akış yönlendirmesi yok, adım
/// tamamlanıp ekran kapanıyor.
///
/// **Kişisel soru yalnızca kişiselleştirilmiş patikada** sorulur. Hazır
/// patikada cevabın değiştirebileceği bir sonraki adım yok; sormak, cevabın bir
/// işe yaradığını ima etmek olurdu.
@Observable
@MainActor
final class PathSessionViewModel {
    enum Phase: Equatable {
        case preparing
        case running
        /// Oturum bitti, kişisel soru bekliyor.
        case question
        case finished
        /// Kriz sinyali: akış durur, adım tamamlanmaz, hareket yok.
        case crisis
    }

    private(set) var phase: Phase = .preparing
    private(set) var isSubmitting = false
    private(set) var showsError = false
    private(set) var didReachEnd = false

    let runner = SessionRunner()

    private let services: AppServices
    private let path: ActivePath
    private let step: PathStepRecord
    private var audioTask: Task<Void, Never>?

    init(services: AppServices, path: ActivePath, step: PathStepRecord) {
        self.services = services
        self.path = path
        self.step = step
    }

    var stepTitle: String { step.title }

    /// Soru **yalnızca** kişiselleştirilmiş patikada ve yalnızca oturum sonuna
    /// kadar gidildiyse. Yarıda bırakana soru sormak, bırakmayı bir eksiklik
    /// gibi okutuyordu.
    var question: String? {
        guard path.kind == .personalized, didReachEnd else { return nil }
        return step.question
    }

    func start() {
        guard phase == .preparing else { return }
        phase = .running
        runner.begin(
            segments: SessionScript.build(
                step: step.generatedStep,
                ownWords: nil,
                targetMinutes: 10
            )
        ) { [weak self] reachedEnd in
            self?.sessionDidFinish(reachedEnd: reachedEnd)
        }
        beginAudio()
    }

    func teardown() {
        audioTask?.cancel()
        runner.teardown()
    }

    private func sessionDidFinish(reachedEnd: Bool) {
        didReachEnd = reachedEnd
        phase = question == nil ? .finished : .question
    }

    /// Cevap yazılmazsa (`skipped`) sonraki adım mevcut özetle hazır kalır.
    func submit(answer: String?, skipped: Bool) {
        guard !isSubmitting else { return }
        // Her serbest metin cihazda da taranıyor: kural istisnası olduğu an
        // kural değildir.
        if let answer, CrisisClassifier.evaluate(answer).hasSignal {
            phase = .crisis
            return
        }
        isSubmitting = true
        showsError = false
        Task { @MainActor in
            do {
                let token = try await services.auth.validAccessToken()
                switch try await services.backend.completeStep(
                    pathStepId: step.id,
                    answer: answer,
                    skipped: skipped,
                    accessToken: token
                ) {
                case .completed:
                    runner.audio.clearCheckpoint()
                    phase = .finished
                case .crisis:
                    phase = .crisis
                }
            } catch {
                services.observability.capture(.stepCompletion)
                showsError = true
            }
            isSubmitting = false
        }
    }

    /// Ses hazır değilse üretimi başlatır, sonra bekler. Oturum beklemez:
    /// sessiz sürüm de tam bir oturumdur.
    private func beginAudio() {
        audioTask = Task { @MainActor in
            let deadline = Date.now.addingTimeInterval(60)
            do {
                var token = try await services.auth.validAccessToken()
                if step.audioStatus == .pending {
                    _ = try await services.backend.requestAudioWithRetry(
                        pathStepId: step.id,
                        accessToken: token,
                        idempotencyKey: UUID()
                    )
                }
                while Date.now < deadline, !Task.isCancelled {
                    let status = try await services.backend.audioStatus(
                        pathStepId: step.id,
                        accessToken: token
                    )
                    if status == .ready {
                        guard let playback = try await services.backend.sessionPlayback(
                            pathStepId: step.id,
                            accessToken: token
                        ) else { return }
                        runner.replaceSegments(SessionScript.build(from: playback.manifest))
                        await runner.audio.play(
                            playback: playback,
                            title: step.title,
                            startingAt: SessionAudioPlayer.resumeOffset(for: playback.manifest.stepID)
                        ) {}
                        return
                    }
                    if status == .failed { return }
                    try await Task.sleep(for: .seconds(2))
                    token = try await services.auth.validAccessToken()
                }
            } catch {
                services.observability.capture(.audioGeneration)
            }
        }
    }
}
