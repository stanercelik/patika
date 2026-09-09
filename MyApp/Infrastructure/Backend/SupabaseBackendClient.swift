import Foundation

struct SupabaseBackendClient: BackendClient {
    private let configuration: AppConfiguration
    private let session: URLSession

    init(configuration: AppConfiguration = .live, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func generatePath(
        from draft: OnboardingDraft,
        measurementVariant: MeasurementVariant,
        accessToken: String,
        idempotencyKey: UUID
    ) async throws -> PathGenerationResult {
        var request = URLRequest(
            url: configuration.supabaseURL.appending(path: "/functions/v1/generate-path")
        )
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.supabasePublishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(idempotencyKey.uuidString.lowercased(), forHTTPHeaderField: "Idempotency-Key")
        request.httpBody = try JSONEncoder().encode(GeneratePathPayload(draft: draft, variant: measurementVariant))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BackendError.invalidResponse }
        guard 200..<300 ~= http.statusCode else { throw error(status: http.statusCode, body: data) }
        let payload = try JSONDecoder().decode(GeneratePathResponse.self, from: data)
        if payload.status == "crisis" { return .crisis }
        guard payload.status == "ready", let id = payload.pathId, let title = payload.title,
              let steps = payload.steps, !steps.isEmpty
        else { throw BackendError.invalidResponse }
        return .ready(GeneratedPath(id: id, title: title, steps: steps))
    }

    func hasCompletedOnboarding(accessToken: String) async throws -> Bool {
        var request = authenticatedRequest(
            path: "/rest/v1/profiles?select=onboarding_completed_at&limit=1",
            method: "GET",
            accessToken: accessToken
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        try validate(response, data)
        let profiles = try JSONDecoder().decode([ProfileCompletion].self, from: data)
        return profiles.first?.onboardingCompletedAt != nil
    }

    func markOnboardingCompleted(accessToken: String) async throws {
        var request = authenticatedRequest(
            path: "/rest/v1/profiles",
            method: "PATCH",
            accessToken: accessToken
        )
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode([
            "onboarding_completed_at": ISO8601DateFormatter().string(from: .now),
        ])
        let (data, response) = try await session.data(for: request)
        try validate(response, data)
    }

    // MARK: - Path adımları ve ses
    //
    // Adım kimliği ve ses durumu REST üzerinden okunuyor, ayrı bir Edge Function
    // yazılmadan: `path_steps` ve `audio_assets` üzerinde RLS zaten "yalnızca
    // kendi satırın" diyor, yani sunucuya ikinci bir yetki kontrolü eklemek
    // aynı kuralı iki yerde tutmak olurdu.

    func pathStep(pathId: UUID, day: Int, accessToken: String) async throws -> PathStepRecord {
        let query = "/rest/v1/path_steps"
            + "?select=id,day,title,block_ids,slot_copy,audio_status"
            + "&path_id=eq.\(pathId.uuidString.lowercased())&day=eq.\(day)&limit=1"
        var request = authenticatedRequest(path: query, method: "GET", accessToken: accessToken)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        try validate(response, data)
        guard let step = try JSONDecoder().decode([PathStepRecord].self, from: data).first else {
            throw BackendError.invalidResponse
        }
        return step
    }

    func latestPathId(accessToken: String) async throws -> UUID? {
        let query = "/rest/v1/program_paths"
            + "?select=id&status=eq.active&order=created_at.desc&limit=1"
        var request = authenticatedRequest(path: query, method: "GET", accessToken: accessToken)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        try validate(response, data)
        return try JSONDecoder().decode([PathIdentifier].self, from: data).first?.id
    }

    func requestAudio(
        pathStepId: UUID,
        accessToken: String,
        idempotencyKey: UUID
    ) async throws -> AudioRequestOutcome {
        var request = URLRequest(
            url: configuration.supabaseURL.appending(path: "/functions/v1/generate-audio")
        )
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.supabasePublishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(idempotencyKey.uuidString.lowercased(), forHTTPHeaderField: "Idempotency-Key")
        request.httpBody = try JSONEncoder().encode(["pathStepId": pathStepId.uuidString.lowercased()])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BackendError.invalidResponse }
        // 503 = TTS sağlayıcısı sunucuda yapılandırılmamış, 422 = seslendirilecek
        // metin yok. İkisi de oturumu durdurmaz; ses **ek**, oturumun kendisi değil.
        if http.statusCode == 503 || http.statusCode == 422 {
            let code = try? JSONDecoder().decode(BackendErrorPayload.self, from: data).code
            return .unavailable(reason: code ?? "audio_unavailable")
        }
        guard 200..<300 ~= http.statusCode else { throw error(status: http.statusCode, body: data) }
        let payload = try JSONDecoder().decode(AudioRequestResponse.self, from: data)
        return payload.status == "ready" ? .ready : .processing
    }

    func audioStatus(pathStepId: UUID, accessToken: String) async throws -> AudioStatus {
        let query = "/rest/v1/path_steps?select=audio_status&id=eq.\(pathStepId.uuidString.lowercased())&limit=1"
        var request = authenticatedRequest(path: query, method: "GET", accessToken: accessToken)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        try validate(response, data)
        guard let row = try JSONDecoder().decode([AudioStatusRow].self, from: data).first else {
            throw BackendError.invalidResponse
        }
        return row.audioStatus
    }

    func markStepCompleted(pathStepId: UUID, at date: Date, accessToken: String) async throws {
        var request = authenticatedRequest(
            path: "/rest/v1/path_steps?id=eq.\(pathStepId.uuidString.lowercased())",
            method: "PATCH",
            accessToken: accessToken
        )
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode([
            "completed_at": ISO8601DateFormatter().string(from: date),
        ])
        let (data, response) = try await session.data(for: request)
        try validate(response, data)
    }

    func signedAudioURL(pathStepId: UUID, accessToken: String) async throws -> URL? {
        let query = "/rest/v1/audio_assets"
            + "?select=storage_path&path_step_id=eq.\(pathStepId.uuidString.lowercased())"
            + "&order=created_at.desc&limit=1"
        var listRequest = authenticatedRequest(path: query, method: "GET", accessToken: accessToken)
        listRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        let (listData, listResponse) = try await session.data(for: listRequest)
        try validate(listResponse, listData)
        guard let asset = try JSONDecoder().decode([AudioAssetRow].self, from: listData).first else {
            return nil
        }

        var signRequest = authenticatedRequest(
            path: "/storage/v1/object/sign/private_audio/\(asset.storagePath)",
            method: "POST",
            accessToken: accessToken
        )
        signRequest.httpBody = try JSONEncoder().encode(["expiresIn": 3600])
        let (signData, signResponse) = try await session.data(for: signRequest)
        try validate(signResponse, signData)
        let signed = try JSONDecoder().decode(SignedURLResponse.self, from: signData)
        // Supabase göreli bir yol döndürüyor: "/object/sign/...".
        return URL(string: "/storage/v1" + signed.signedURL, relativeTo: configuration.supabaseURL)?.absoluteURL
    }

    private func authenticatedRequest(path: String, method: String, accessToken: String) -> URLRequest {
        var request = URLRequest(url: URL(string: path, relativeTo: configuration.supabaseURL)!.absoluteURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.supabasePublishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func validate(_ response: URLResponse, _ data: Data = Data()) throws {
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw error(status: status, body: data)
        }
    }

    private func error(status: Int, body: Data) -> BackendError {
        let code = try? JSONDecoder().decode(BackendErrorPayload.self, from: body).code
        return .unavailable(status: status, code: code ?? nil)
    }

}

private struct PathIdentifier: Decodable {
    let id: UUID
}

private struct AudioStatusRow: Decodable {
    let audioStatus: AudioStatus
    enum CodingKeys: String, CodingKey { case audioStatus = "audio_status" }
}

private struct AudioAssetRow: Decodable {
    let storagePath: String
    enum CodingKeys: String, CodingKey { case storagePath = "storage_path" }
}

private struct AudioRequestResponse: Decodable {
    let status: String
}

private struct SignedURLResponse: Decodable {
    let signedURL: String
}

private struct ProfileCompletion: Decodable {
    let onboardingCompletedAt: String?
    enum CodingKeys: String, CodingKey { case onboardingCompletedAt = "onboarding_completed_at" }
}

private struct GeneratePathPayload: Encodable {
    let clientCrisisSignal: Bool
    let locale: String
    let name: String?
    let gender: String?
    let ageRange: String?
    let categories: [String]
    let problemText: String
    let duration: String?
    let timing: String?
    let avoidanceText: String?
    let previousAttempts: [String]
    let currentMood: String?
    let measurementVariant: String
    let measurementResponses: [String: Double]
    let sessionMinutes: Int
    let tone: String

    init(draft: OnboardingDraft, variant: MeasurementVariant) {
        clientCrisisSignal = draft.crisisDetected
        locale = Locale.current.identifier
        name = draft.displayName
        gender = draft.gender?.rawValue
        ageRange = draft.ageRange?.rawValue
        categories = draft.categories.map(\.rawValue)
        problemText = draft.problemText
        duration = draft.duration?.rawValue
        timing = draft.timing?.rawValue
        avoidanceText = draft.avoidanceText
        previousAttempts = draft.previousAttempts.map(\.rawValue)
        currentMood = draft.currentMood.map { String($0.rawValue) }
        measurementVariant = variant.rawValue
        measurementResponses = draft.measurementResponses
        sessionMinutes = draft.sessionLength.minutes
        tone = draft.resolvedTonePreference.rawValue
    }
}

private struct GeneratePathResponse: Decodable {
    let status: String
    let pathId: UUID?
    let title: String?
    let steps: [GeneratedPathStep]?
}
