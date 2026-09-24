import Foundation

struct GeneratedPathStep: Decodable, Equatable, Sendable {
    let day: Int
    let title: String
    let blockIds: [String]
    let slotCopy: [String: String]
    let question: String?
}

struct GeneratedPath: Equatable, Sendable {
    let id: UUID
    let kind: ProgramPathKind
    let title: String
    let steps: [GeneratedPathStep]
}

enum PathGenerationResult: Equatable, Sendable {
    case ready(GeneratedPath)
    case crisis
}

/// Sunucuda duran bir path adımı.
///
/// `GeneratedPathStep`ten farkı kimliği taşıması: ses üretimi (`generate-audio`)
/// ve ses durumu sorgusu satır kimliğiyle çalışıyor. `generate-path` cevabında
/// kimlik yok, o yüzden adım REST üzerinden ayrıca okunuyor — Edge Function'ı
/// yeniden dağıtmadan çalışsın diye.
struct PathStepRecord: Decodable, Equatable, Sendable {
    let id: UUID
    let day: Int
    let title: String
    let blockIds: [String]
    let slotCopy: [String: String]
    let audioStatus: AudioStatus
    let question: String?
    let completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, day, title
        case blockIds = "block_ids"
        case slotCopy = "slot_copy"
        case audioStatus = "audio_status"
        case question = "step_question"
        case completedAt = "completed_at"
    }

    var generatedStep: GeneratedPathStep {
        GeneratedPathStep(day: day, title: title, blockIds: blockIds, slotCopy: slotCopy, question: question)
    }
}

/// Sunucudaki aktif path — kimliği, türü ve bütün adımları.
///
/// Onboarding bittikten sonra "Yolum" sekmesi ve F1'in uzlaştırması bunu okur:
/// istemcinin elinde bir şey kalmasa bile (uygulama yeniden kuruldu, üretim
/// başka bir cihazda bitti) path sunucuda duruyor.
struct ActivePath: Equatable, Sendable {
    let id: UUID
    let kind: ProgramPathKind
    let title: String
    let steps: [PathStepRecord]
    /// Sunucu yolu tamamladı (`program_paths.status = completed`). "Yolum" bitmiş
    /// yolu göstermeye devam eder; üretim uzlaştırması onu yeni yol saymaz.
    var isCompleted = false

    /// Sıradaki adım: tamamlanmamış ilk gün. Hepsi tamamlandıysa nil.
    var nextStep: PathStepRecord? {
        steps.sorted { $0.day < $1.day }.first { $0.completedAt == nil }
    }

    var completedStepCount: Int { steps.count { $0.completedAt != nil } }
}

struct SessionPlayback: Sendable {
    let manifest: SessionManifest
    let assetURLs: [UUID: URL]
}

enum StepCompletionOutcome: Equatable, Sendable {
    case completed(nextQueued: Bool)
    case crisis
}

/// `generate-audio` çağrısının sonucu.
enum AudioRequestOutcome: Equatable, Sendable {
    case ready
    case processing
    /// TTS sağlayıcısı sunucuda yapılandırılmamış (503) ya da seslendirilecek
    /// metin yok (422). İkisi de oturumu durdurmaz: ekran sessiz sürüme düşer.
    case unavailable(reason: String)
}

protocol BackendClient: Sendable {
    func generatePath(
        from draft: OnboardingDraft,
        measurementVariant: MeasurementVariant,
        accessToken: String,
        idempotencyKey: UUID
    ) async throws -> PathGenerationResult
    func hasCompletedOnboarding(accessToken: String) async throws -> Bool
    func markOnboardingCompleted(userID: UUID, accessToken: String) async throws

    /// Bir path'in tek bir gününü kimliğiyle birlikte okur.
    func pathStep(pathId: UUID, day: Int, accessToken: String) async throws -> PathStepRecord
    /// En son üretilmiş aktif path'in kimliği. Uygulama yeniden başlatıldığında
    /// ya da üretim başka bir oturumda yapıldığında path'i bulmanın yolu.
    func latestPathId(accessToken: String) async throws -> UUID?
    /// JIT ses üretimini başlatır (PRD-Ek Path Üretimi §6: F1'de yalnızca 1.
    /// adımın sesi üretilir).
    func requestAudio(
        pathStepId: UUID,
        accessToken: String,
        idempotencyKey: UUID
    ) async throws -> AudioRequestOutcome
    func audioStatus(pathStepId: UUID, accessToken: String) async throws -> AudioStatus
    /// Hazır sesin imzalı indirme adresi. Kova özel; imza kullanıcının kendi
    /// JWT'siyle alınır, servis anahtarı istemciye hiç girmez.
    func signedAudioURL(pathStepId: UUID, accessToken: String) async throws -> URL?
    func sessionPlayback(pathStepId: UUID, accessToken: String) async throws -> SessionPlayback?
    func completeStep(
        pathStepId: UUID,
        answer: String?,
        skipped: Bool,
        accessToken: String
    ) async throws -> StepCompletionOutcome
    /// Aktif path ve bütün adımları. Yoksa nil.
    func activePath(accessToken: String) async throws -> ActivePath?

    // MARK: "Ben" sekmesi

    /// Kullanıcının sunucudaki kendi verisi; şifreli alanlar sahibine çözülmüş.
    func profileSnapshot(accessToken: String) async throws -> ProfileSnapshot
    /// Hitap adı. Ad serbest metin: sunucu da kriz taramasından geçirir.
    func updateDisplayName(_ name: String?, accessToken: String) async throws -> ProfileUpdateOutcome
    func deleteJournal(_ target: JournalDeletionTarget, accessToken: String) async throws
    /// Defter notunu oluşturur (`id == nil`) ya da günceller. Sunucu metni kriz
    /// taramasından geçirir; sinyalde not **yazılmaz** ve `.crisis` döner.
    func saveNote(id: UUID?, body: String, accessToken: String) async throws -> NoteSaveOutcome
    func deleteNote(id: UUID, accessToken: String) async throws
    /// Profil fotoğrafı: özel kova, yol `<user_id>/avatar.jpg`. İstemci yalnızca
    /// kendi klasörüne yazabilir (RLS).
    func uploadAvatar(_ jpegData: Data, userID: UUID, accessToken: String) async throws
    func removeAvatar(userID: UUID, accessToken: String) async throws
    /// Kazanılan rozetleri yazar. Çakışma başarı sayılır: rozet zaten kayıtlı.
    func recordBadges(_ badges: [BadgeID], userID: UUID, accessToken: String) async throws
    /// Yol içi ölçüm (7. / 14. adım, son). Aynı gün ikinci kez yazılmaz; sunucu
    /// çakışması başarı sayılır — ölçüm zaten kayıtlı.
    func recordMeasurement(_ upload: MeasurementUpload, userID: UUID, accessToken: String) async throws
    /// Hesabı ve bütün verileri kalıcı olarak siler.
    func deleteAccount(accessToken: String) async throws
}

enum ProfileUpdateOutcome: Equatable, Sendable {
    case updated
    case crisis
}

enum NoteSaveOutcome: Equatable, Sendable {
    case saved(JournalNote)
    case crisis
}

enum JournalDeletionTarget: Equatable, Sendable {
    case answer(UUID)
    /// İlk cümle ve kaçınma cümlesi.
    case origin
    /// Kullanıcının kendi yazdığı tek bir not.
    case note(UUID)
    case allNotes
    /// Cevaplar, ilk cümleler ve notlar. Rozetler silinmez.
    case all
}

struct MeasurementUpload: Sendable {
    /// Yol içi ölçüm hangi yola ait. Tekillik yol başına (20260912120000).
    let pathID: UUID
    let day: Int
    let variant: MeasurementVariant
    let responses: [String: Double]
    let score: MeasurementScore?
}

extension BackendClient {
    /// Path üretimi — sınırlı yeniden deneme ve sunucuyla uzlaştırma.
    ///
    /// Mobilde -1005 sıradan bir olay ve üretim sunucuda **çoktan bitmiş**
    /// olabilir. Doğrudan hata göstermek kullanıcıyı akışın en pahalı adımını
    /// tekrar ettirmeye iterdi; bu da ikinci bir LLM + TTS faturası demek.
    /// Bu yüzden önce aynı idempotency anahtarıyla tekrar denenir, o da
    /// tükenirse sunucudaki aktif path okunur.
    func generatePathWithReconciliation(
        from draft: OnboardingDraft,
        measurementVariant: MeasurementVariant,
        accessToken: String,
        idempotencyKey: UUID
    ) async throws -> PathGenerationResult {
        do {
            return try await RetryPolicy.standard.run(idempotencyKey: idempotencyKey) { key in
                try await generatePath(
                    from: draft,
                    measurementVariant: measurementVariant,
                    accessToken: accessToken,
                    idempotencyKey: key
                )
            }
        } catch {
            // Bitmiş eski bir yol, üretimi yarıda kalmış yeni yolun yerine geçmemeli.
            guard let active = try? await activePath(accessToken: accessToken),
                  !active.steps.isEmpty,
                  !active.isCompleted
            else { throw error }
            return .ready(GeneratedPath(
                id: active.id,
                kind: active.kind,
                title: active.title,
                steps: active.steps.sorted { $0.day < $1.day }.map(\.generatedStep)
            ))
        }
    }

    /// Ses üretimi isteği — aynı anahtarla yeniden denenir.
    ///
    /// Yeni anahtar üretmek ikinci bir TTS faturası demek; sunucu aynı anahtarı
    /// gördüğünde ilk işi döndürüyor.
    func requestAudioWithRetry(
        pathStepId: UUID,
        accessToken: String,
        idempotencyKey: UUID
    ) async throws -> AudioRequestOutcome {
        try await RetryPolicy.standard.run(idempotencyKey: idempotencyKey) { key in
            try await requestAudio(pathStepId: pathStepId, accessToken: accessToken, idempotencyKey: key)
        }
    }
}
