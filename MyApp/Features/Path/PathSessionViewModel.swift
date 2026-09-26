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
///
/// ## Hazır patika (Keşfet)
///
/// Keşfet'in hazır patikaları aynı motoru kullanır (`Source.prepared`); ikinci
/// bir oturum ekranı ilkinin düzeltilmiş hatalarını miras almazdı. Ama hazır
/// patikada **ölçüm, rozet, kova, kişisel soru ve sunucuya cevap yazımı yoktur**:
/// kayıtlar pakette, ilerleme cihazda (`DiscoverLibrary`), tamamlanma sonuna
/// kadar dinlenen sesle yazılır. Bu dallar tek yerde, `Source` üzerinden ayrılır.
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
        /// Hazır patikanın kaydı çalınamadı. Sessiz sürüm yok: hazır patikada ses
        /// içeriğin kendisi, sessizce "tamamlanmış" saymak olmayan bir şeyi
        /// olmuş göstermek olurdu.
        case audioUnavailable
    }

    /// Adımın nereden geldiği.
    enum Source {
        /// Sunucudaki kişiselleştirilmiş patika.
        case personal(path: ActivePath, step: PathStepRecord)
        /// Paketteki hazır patika; ilerleme `library`de tutulur.
        case prepared(path: DiscoverPath, step: DiscoverStep, library: DiscoverLibrary)
    }

    private(set) var phase: Phase = .preparing
    private(set) var isSubmitting = false
    private(set) var showsError = false
    private(set) var didReachEnd = false
    private(set) var pendingMeasurement: MeasurementPoint?
    /// Bu oturumda kazanılan rozetler. Yaprak yalnızca `finished` ekranında açılır
    /// (`badgesToCelebrate`), adım tamamlanırken ya da ölçüm sorulurken değil.
    private(set) var earnedBadges: [BadgeID] = []

    /// Yeniden denemede yenilenir: bitmiş ya da durdurulmuş bir motor yeniden
    /// başlatılamaz (`SessionRunner.begin` yalnızca hazırlanırken çalışır).
    private(set) var runner = SessionRunner()

    private let services: AppServices
    private let source: Source
    private var audioTask: Task<Void, Never>?
    private var measurementResponses: [String: Double] = [:]
    private var pendingCompletion: (answer: String?, skipped: Bool)?
    /// Hazır patika: ses gerçekten çalmaya başladı mı. Tamamlanma yalnızca
    /// duyulmuş bir kayıttan yazılır.
    private var preparedAudioStarted = false
    private var didTrackSessionStart = false
    private var didTrackSessionCompletion = false

    private var analyticsSource: AnalyticsSessionSource {
        if case .prepared = source { return .prepared }
        return .personal
    }

    private func trackSessionStarted() {
        guard !didTrackSessionStart else { return }
        didTrackSessionStart = true
        services.observability.capture(.sessionStarted(source: analyticsSource))
    }

    private func trackSessionCompleted() {
        guard !didTrackSessionCompletion else { return }
        didTrackSessionCompletion = true
        services.observability.capture(.sessionCompleted(source: analyticsSource))
    }

    init(services: AppServices, path: ActivePath, step: PathStepRecord) {
        self.services = services
        self.source = .personal(path: path, step: step)
    }

    init(services: AppServices, preparedPath: DiscoverPath, step: DiscoverStep, library: DiscoverLibrary) {
        self.services = services
        self.source = .prepared(path: preparedPath, step: step, library: library)
    }

    /// Kişisel patika ve adımı; hazır patikada nil. Ölçüm, rozet, soru ve sunucu
    /// tamamlaması yalnızca buradan geçer.
    private var personal: (path: ActivePath, step: PathStepRecord)? {
        if case .personal(let path, let step) = source { (path, step) } else { nil }
    }

    var stepTitle: String {
        switch source {
        case .personal(_, let step): step.title
        case .prepared(_, let step, _): step.title.value
        }
    }

    /// Oturum ekranının üst satırı: "12. adım · Nefesi fark etmek".
    var stepEyebrow: String {
        switch source {
        case .personal(_, let step):
            String(localized: Copy.Session.stepEyebrow(day: step.day, title: step.title))
        case .prepared(let path, let step, _):
            String(localized: Copy.Session.stepEyebrow(
                day: (path.steps.firstIndex(of: step) ?? 0) + 1,
                title: step.title.value
            ))
        }
    }

    /// Adımın fazından seçilir — yol haritasındaki fazla aynı yer. Kullanıcının
    /// cevabı ya da sonucu görsele çevrilmez.
    ///
    /// Hazır patikada faz eşlemesi **yalnızca görsel içindir**: yedi adımlık
    /// hazır patika kısa yolun faz ritmini ödünç alır, ölçüm ya da başka bir
    /// davranış bu eşlemeden türemez.
    var artwork: SessionArtwork {
        switch source {
        case .personal(let path, let step):
            guard let length = PathLength(rawValue: path.steps.count),
                  let phase = PathPlan.phase(on: step.day, length: length)
            else { return .practice }
            return SessionArtwork(phase: phase)
        case .prepared(let path, let step, _):
            let day = (path.steps.firstIndex(of: step) ?? 0) + 1
            guard let phase = PathPlan.phase(on: day, length: .week) else { return .practice }
            return SessionArtwork(phase: phase)
        }
    }

    /// Hazır patikada oturum bitince tamamlanma ekranı; kişiselde yok.
    var isPrepared: Bool {
        if case .prepared = source { true } else { false }
    }

    /// Hazır patikada bu, patikanın son adımıydı. "Sıradaki adımın seni bekler"
    /// diyecek sıradaki adım yok.
    var finishedPreparedPath: Bool {
        guard case .prepared(let path, _, let library) = source else { return false }
        return library.nextStep(path) == nil
    }

    /// Soru **yalnızca** kişiselleştirilmiş patikada ve yalnızca oturum sonuna
    /// kadar gidildiyse. Yarıda bırakana soru sormak, bırakmayı bir eksiklik
    /// gibi okutuyordu.
    var question: String? {
        guard let personal, personal.path.kind == .personalized, didReachEnd else { return nil }
        return personal.step.question
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
        guard let (_, step) = personal else {
            startPrepared()
            return
        }
        phase = .running
        trackSessionStarted()
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

    /// Hazır patikanın kaydı çalınamadıysa yeniden dener.
    func retryPrepared() {
        guard phase == .audioUnavailable else { return }
        audioTask?.cancel()
        runner.teardown()
        runner = SessionRunner()
        preparedAudioStarted = false
        phase = .preparing
        start()
    }

    // MARK: - Hazır patika

    /// Kayıtlar pakette: ağ yok, ses beklemesi yok. Sahneler manifestin kendi
    /// zamanlamasıyla kurulur — duyulan cümle ekrandaki cümledir.
    private func startPrepared() {
        guard case .prepared(let path, let step, let library) = source else { return }
        let playback: SessionPlayback
        do {
            playback = try library.playback(for: step, in: path)
        } catch {
            phase = .audioUnavailable
            return
        }
        phase = .running
        trackSessionStarted()
        let segments = SessionScript.build(from: playback.manifest)
        let offset = SessionAudioPlayer.resumeOffset(for: playback.manifest.stepID)
        runner.begin(segments: segments) { [weak self] reachedEnd in
            self?.sessionDidFinish(reachedEnd: reachedEnd)
        }
        runner.replaceSegments(segments, startingAt: offset)
        audioTask = Task { @MainActor in
            await runner.audio.play(playback: playback, title: step.title.value, startingAt: offset) {}
            guard !Task.isCancelled else { return }
            if case .unavailable = runner.audio.state {
                runner.teardown()
                phase = .audioUnavailable
                return
            }
            preparedAudioStarted = true
            runner.audioDidStart()
        }
    }

    /// Yarıda bırakılan oturum tamamlanmış sayılmaz. Sonuna kadar dinlenen adım
    /// soru yoksa kendiliğinden tamamlanır — önceden hazır patikada hiçbir adım
    /// `completed_at` almıyordu ve yol hiç ilerlemiyordu.
    private func sessionDidFinish(reachedEnd: Bool) {
        didReachEnd = reachedEnd
        if case .prepared(let path, let step, let library) = source {
            // Yalnızca duyulmuş bir kayıt adımı tamamlar. Sunucu, soru, ölçüm ve
            // rozet yok; ilerleme cihazda kalır.
            if reachedEnd, preparedAudioStarted {
                runner.audio.clearCheckpoint()
                library.complete(step, in: path)
                trackSessionCompleted()
            }
            phase = .finished
            return
        }
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
        guard let (_, step) = personal, !isSubmitting else { return }
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
                    trackSessionCompleted()
                    services.profile.clearCrisisSignal()
                    services.profile.appendCompletedStepDate()
                    pendingCompletion = nil
                    awardBadges()
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
        guard let (path, step) = personal, let point = MeasurementSchedule.point(afterStep: step.day, pathLength: path.steps.count),
              !(services.profile.record?.measurements.contains { $0.point == point && $0.pathID == path.id } ?? false)
        else {
            phase = .finished
            return
        }
        pendingMeasurement = point
        measurementResponses = [:]
        phase = .measurementIntro
    }

    // MARK: - Rozetler

    /// Bu adım tamamlanmış hâliyle yol. `path` oturum açılırken okunmuştu; adım
    /// sunucuda yeni tamamlandı ve rozet hesabı onu görmeli.
    private var pathWithCurrentStepCompleted: ActivePath? {
        guard let (path, step) = personal else { return nil }
        let now = Date.now
        let steps = path.steps.map { record -> PathStepRecord in
            guard record.id == step.id, record.completedAt == nil else { return record }
            return PathStepRecord(
                id: record.id, day: record.day, title: record.title, blockIds: record.blockIds,
                slotCopy: record.slotCopy, audioStatus: record.audioStatus,
                question: record.question, completedAt: now
            )
        }
        var updated = ActivePath(id: path.id, kind: path.kind, title: path.title, steps: steps)
        updated.isCompleted = steps.allSatisfy { $0.completedAt != nil }
        return updated
    }

    private func awardBadges() {
        guard let completed = pathWithCurrentStepCompleted else { return }
        earnedBadges += BadgeAwarder(services: services).award(activePath: completed)
    }

    /// Finished ekranında yaprakta gösterilecek rozetler.
    ///
    /// Kova C'deki yol sonunda ve kriz modunda **boş**: rozet verilmiştir ve rafta
    /// durur ama kutlama yapılmaz (`BadgeCelebration`).
    var badgesToCelebrate: [BadgeID] {
        guard let (path, _) = personal,
              let completed = pathWithCurrentStepCompleted,
              let record = services.profile.record
        else { return [] }
        let bucket: OutcomeBucket? = completed.isCompleted
            ? ChangeAnalysis.bucket(
                measurements: record.measurements.filter { $0.point == .baseline || $0.pathID == path.id },
                category: record.primaryCategory
            )
            : nil
        return BadgeCelebration.shouldPresent(
            badges: earnedBadges,
            isInCrisisMode: record.crisisSignalAt != nil,
            bucket: bucket
        ) ? earnedBadges : []
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
        guard let (path, step) = personal, let point = pendingMeasurement, !isSubmitting else { return }
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
                awardBadges()
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
        guard let (_, step) = personal else { return }
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
