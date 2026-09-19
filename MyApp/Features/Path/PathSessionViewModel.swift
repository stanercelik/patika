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
///
/// ## Ölçüm günü
///
/// "Yolum" ölçüm gününün kartında "bu adımdan sonra kısa bir ölçüm var" diyor.
/// Adım tamamlandığında o söz burada tutulur: aynı sekiz soru (14. günde altı),
/// o noktanın varyantıyla. Cevaplar sunucuya yazılır ve "Ben" sekmesindeki
/// karşılaştırmayı besler. Ölçüm yalnızca adım sonuna kadar dinlendiyse ve o gün
/// için kayıt yoksa sorulur.
@Observable
@MainActor
final class PathSessionViewModel {
    enum Phase: Equatable {
        case preparing
        case running
        /// Oturum bitti, kişisel soru bekliyor.
        case question
        /// Sorusu olmayan adım tamamlanıyor; ağ hatasında burada kalınır.
        case completing
        case measurementIntro
        case measurement(Int)
        case finished
        /// Kriz sinyali: akış durur, adım tamamlanmaz, hareket yok.
        case crisis
    }

    private(set) var phase: Phase = .preparing
    private(set) var isSubmitting = false
    private(set) var showsError = false
    private(set) var didReachEnd = false
    private(set) var pendingMeasurement: MeasurementPoint?

    let runner = SessionRunner()

    private let services: AppServices
    private let path: ActivePath
    private let step: PathStepRecord
    private var audioTask: Task<Void, Never>?
    private var measurementResponses: [String: Double] = [:]
    private var pendingCompletion: (answer: String?, skipped: Bool)?

    init(services: AppServices, path: ActivePath, step: PathStepRecord) {
        self.services = services
        self.path = path
        self.step = step
    }

    var stepTitle: String { step.title }

    /// Oturum ekranının üst satırı: "12. adım · Nefesi fark etmek".
    var stepEyebrow: String {
        String(localized: Copy.Session.stepEyebrow(day: step.day, title: step.title))
    }

    /// Adımın fazından seçilir — yol haritasındaki fazla aynı yer. Kullanıcının
    /// cevabı ya da sonucu görsele çevrilmez.
    var artwork: SessionArtwork {
        guard let length = PathLength(rawValue: path.steps.count),
              let phase = PathPlan.phase(on: step.day, length: length)
        else { return .practice }
        return SessionArtwork(phase: phase)
    }

    /// Soru **yalnızca** kişiselleştirilmiş patikada ve yalnızca oturum sonuna
    /// kadar gidildiyse. Yarıda bırakana soru sormak, bırakmayı bir eksiklik
    /// gibi okutuyordu.
    var question: String? {
        guard path.kind == .personalized, didReachEnd else { return nil }
        return step.question
    }

    /// Ölçüm ekranında odaklanma, kriz ekranında hareketsizlik (Görsel Sistem §4).
    var breathAmplitude: Double {
        switch phase {
        case .measurementIntro, .measurement, .completing: BreathAmplitude.measurement
        case .crisis: BreathAmplitude.crisis
        default: BreathAmplitude.session
        }
    }

    func start() {
        guard phase == .preparing else { return }
        phase = .running
        runner.begin(
            segments: SessionScript.build(
                step: step.generatedStep,
                ownWords: nil,
                // E2'nin cevabı; yol bu uzunlukla kuruldu.
                targetMinutes: services.profile.record?.sessionLength?.minutes
                    ?? SessionLength.standard.minutes
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

    /// Yarıda bırakılan oturum tamamlanmış sayılmaz. Sonuna kadar dinlenen adım
    /// soru yoksa kendiliğinden tamamlanır — önceden hazır patikada hiçbir adım
    /// `completed_at` almıyordu ve yol hiç ilerlemiyordu.
    private func sessionDidFinish(reachedEnd: Bool) {
        didReachEnd = reachedEnd
        guard reachedEnd else {
            phase = .finished
            return
        }
        if question != nil {
            phase = .question
        } else {
            phase = .completing
            complete(answer: nil, skipped: true)
        }
    }

    /// Cevap yazılmazsa (`skipped`) sonraki adım mevcut özetle hazır kalır.
    func submit(answer: String?, skipped: Bool) {
        // Her serbest metin cihazda da taranıyor: kural istisnası olduğu an
        // kural değildir.
        if let answer, CrisisClassifier.evaluate(answer).hasSignal {
            markCrisis()
            return
        }
        complete(answer: answer, skipped: skipped)
    }

    func retryCompletion() {
        guard let pendingCompletion else { return }
        complete(answer: pendingCompletion.answer, skipped: pendingCompletion.skipped)
    }

    private func complete(answer: String?, skipped: Bool) {
        guard !isSubmitting else { return }
        pendingCompletion = (answer, skipped)
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
                    services.profile.clearCrisisSignal()
                    pendingCompletion = nil
                    advanceAfterCompletion()
                case .crisis:
                    markCrisis()
                }
            } catch {
                services.observability.capture(.stepCompletion)
                showsError = true
            }
            isSubmitting = false
        }
    }

    private func advanceAfterCompletion() {
        guard let point = MeasurementSchedule.point(afterStep: step.day, pathLength: path.steps.count),
              !(services.profile.record?.measurements.contains { $0.point == point && $0.pathID == path.id } ?? false)
        else {
            phase = .finished
            return
        }
        pendingMeasurement = point
        measurementResponses = [:]
        phase = .measurementIntro
    }

    // MARK: - Ölçüm

    var measurementItems: [MeasurementItem] {
        guard let pendingMeasurement else { return [] }
        return MeasurementLibrary.items(
            for: pendingMeasurement,
            category: services.profile.record?.primaryCategory ?? .unnamed
        )
    }

    var measurementVariant: MeasurementVariant { pendingMeasurement?.variant ?? .a }

    func measurementItem(at index: Int) -> MeasurementItem? {
        let items = measurementItems
        return items.indices.contains(index) ? items[index] : nil
    }

    /// Cevap önceden doldurulmaz; yalnızca geri dönülen soruda verilmiş cevap.
    func measurementResponse(for item: MeasurementItem) -> Double? {
        measurementResponses[item.id]
    }

    func beginMeasurement() {
        phase = measurementItems.isEmpty ? .finished : .measurement(0)
    }

    func commitMeasurementAnswer(_ value: Double, at index: Int) {
        let items = measurementItems
        guard items.indices.contains(index) else { return }
        measurementResponses[items[index].id] = value
        if index + 1 < items.count {
            phase = .measurement(index + 1)
        } else {
            saveMeasurement()
        }
    }

    private func saveMeasurement() {
        guard let point = pendingMeasurement, !isSubmitting else { return }
        let items = measurementItems
        let responses = measurementResponses
        let day = point == .final ? path.steps.count : step.day
        isSubmitting = true
        showsError = false
        Task { @MainActor in
            do {
                let token = try await services.auth.validAccessToken()
                guard let userID = services.auth.session?.userID else { throw BackendError.invalidResponse }
                try await services.backend.recordMeasurement(
                    MeasurementUpload(
                        pathID: path.id,
                        day: day,
                        variant: point.variant,
                        responses: responses,
                        score: MeasurementScoring.score(responses: responses, items: items)
                    ),
                    userID: userID,
                    accessToken: token
                )
                services.profile.appendMeasurement(MeasurementRecord(
                    id: UUID(),
                    point: point,
                    stepDay: day,
                    takenAt: .now,
                    responses: responses,
                    pathID: path.id
                ))
                phase = .finished
            } catch {
                services.observability.capture(.profileSync)
                showsError = true
            }
            isSubmitting = false
        }
    }

    private func markCrisis() {
        services.profile.markCrisisSignal()
        phase = .crisis
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
                        let offset = SessionAudioPlayer.resumeOffset(for: playback.manifest.stepID)
                        runner.replaceSegments(SessionScript.build(from: playback.manifest), startingAt: offset)
                        await runner.audio.play(
                            playback: playback,
                            title: step.title,
                            startingAt: offset
                        ) {}
                        runner.audioDidStart()
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
