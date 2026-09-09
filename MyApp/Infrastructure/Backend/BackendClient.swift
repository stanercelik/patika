import Foundation

struct GeneratedPathStep: Decodable, Equatable, Sendable {
    let day: Int
    let title: String
    let blockIds: [String]
    let slotCopy: [String: String]
}

struct GeneratedPath: Equatable, Sendable {
    let id: UUID
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

    enum CodingKeys: String, CodingKey {
        case id, day, title
        case blockIds = "block_ids"
        case slotCopy = "slot_copy"
        case audioStatus = "audio_status"
    }
}

/// `path_steps.audio_status` sütunuyla birebir.
enum AudioStatus: String, Decodable, Sendable {
    case pending, processing, ready, failed
    /// Sunucu yeni bir değer eklerse istemci çökmez, sesi olmayan oturuma düşer.
    init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AudioStatus(rawValue: raw) ?? .failed
    }
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
    func markOnboardingCompleted(accessToken: String) async throws

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
    /// Adımı tamamlanmış işaretler (G2). Yalnızca `completed_at` yazılır —
    /// sütun bazlı yetki, istemcinin planın kendisine dokunmasını engelliyor.
    func markStepCompleted(pathStepId: UUID, at date: Date, accessToken: String) async throws
    /// Hazır sesin imzalı indirme adresi. Kova özel; imza kullanıcının kendi
    /// JWT'siyle alınır, servis anahtarı istemciye hiç girmez.
    func signedAudioURL(pathStepId: UUID, accessToken: String) async throws -> URL?
}

enum BackendError: LocalizedError {
    case invalidResponse
    /// Sunucu bir cevap verdi ama kullanılabilir değildi. HTTP durumu ve varsa
    /// sunucunun kendi hata kodu taşınır: "bir şeyler ters gitti" ekranı
    /// kullanıcıya yeterli, geliştiriciye değil — 400 (payload) ile 401 (oturum)
    /// ile 503 (sağlayıcı) aynı hata olarak görünürse hata ayıklanamıyor.
    case unavailable(status: Int, code: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "invalid_backend_response"
        case .unavailable(let status, let code):
            "backend_unavailable(\(status)\(code.map { ", \($0)" } ?? ""))"
        }
    }
}

/// Sunucunun hata gövdesi — her Edge Function `{ "code": "..." }` döndürüyor.
struct BackendErrorPayload: Decodable {
    let code: String?
}
