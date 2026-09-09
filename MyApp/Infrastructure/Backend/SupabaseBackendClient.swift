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
        return .ready(GeneratedPath(id: id, kind: payload.kind ?? .personalized, title: title, steps: steps))
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
            + "?select=\(Self.stepColumns)"
            + "&path_id=eq.\(pathId.uuidString.lowercased())&day=eq.\(day)&limit=1"
        var request = authenticatedRequest(path: query, method: "GET", accessToken: accessToken)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        try validate(response, data)
        guard let step = try Self.decoder.decode([PathStepRecord].self, from: data).first else {
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

    func sessionPlayback(pathStepId: UUID, accessToken: String) async throws -> SessionPlayback? {
        let query = "/rest/v1/session_manifests"
            + "?select=manifest&path_step_id=eq.\(pathStepId.uuidString.lowercased())"
            + "&order=version.desc&limit=1"
        var request = authenticatedRequest(path: query, method: "GET", accessToken: accessToken)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        try validate(response, data)
        guard let manifest = try JSONDecoder().decode([ManifestRow].self, from: data).first?.manifest else {
            return nil
        }

        var URLs: [UUID: URL] = [:]
        for event in manifest.events {
            guard case .speech(let speech) = event, URLs[speech.assetID] == nil else { continue }
            switch speech.source {
            case .block:
                URLs[speech.assetID] = configuration.supabaseURL
                    .appending(path: "/storage/v1/object/public/block_audio")
                    .appending(path: speech.storagePath)
            case .personal:
                URLs[speech.assetID] = try await signedStorageURL(
                    bucket: "private_audio",
                    path: speech.storagePath,
                    accessToken: accessToken
                )
            }
        }
        return SessionPlayback(manifest: manifest, assetURLs: URLs)
    }

    func completeStep(
        pathStepId: UUID,
        answer: String?,
        skipped: Bool,
        accessToken: String
    ) async throws -> StepCompletionOutcome {
        var request = authenticatedRequest(path: "/functions/v1/complete-step", method: "POST", accessToken: accessToken)
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(CompleteStepPayload(
            pathStepId: pathStepId.uuidString.lowercased(),
            answer: answer,
            skipped: skipped
        ))
        let (data, response) = try await session.data(for: request)
        try validate(response, data)
        let payload = try JSONDecoder().decode(CompleteStepResponse.self, from: data)
        if payload.crisis == true || payload.status == "crisis" { return .crisis }
        guard payload.status == "completed" else { throw BackendError.invalidResponse }
        return .completed(nextQueued: payload.nextStepStatus == "queued")
    }

    /// Aktif path ve adımları tek okumada.
    ///
    /// İki istek: path satırı ve adımlar. PostgREST gömme (`path_steps(...)`)
    /// yapabiliyordu ama iki tabloyu tek satırda birleştirmek adımların
    /// sıralamasını sunucu tarafına bırakıyordu; burada sıra istemcide,
    /// `day` üzerinden kesin.
    func activePath(accessToken: String) async throws -> ActivePath? {
        let pathQuery = "/rest/v1/program_paths"
            + "?select=id,kind,title&status=eq.active&order=created_at.desc&limit=1"
        var pathRequest = authenticatedRequest(path: pathQuery, method: "GET", accessToken: accessToken)
        pathRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        let (pathData, pathResponse) = try await session.data(for: pathRequest)
        try validate(pathResponse, pathData)
        guard let row = try Self.decoder.decode([ProgramPathRow].self, from: pathData).first else {
            return nil
        }

        let stepQuery = "/rest/v1/path_steps"
            + "?select=\(Self.stepColumns)"
            + "&path_id=eq.\(row.id.uuidString.lowercased())&order=day.asc"
        var stepRequest = authenticatedRequest(path: stepQuery, method: "GET", accessToken: accessToken)
        stepRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        let (stepData, stepResponse) = try await session.data(for: stepRequest)
        try validate(stepResponse, stepData)
        let steps = try Self.decoder.decode([PathStepRecord].self, from: stepData)
        return ActivePath(
            id: row.id,
            kind: row.kind ?? .personalized,
            title: row.title,
            steps: steps
        )
    }

    private static let stepColumns =
        "id,day,title,block_ids,slot_copy,audio_status,step_question,completed_at"

    /// Postgres `timestamptz` bazen kesirli saniye taşıyor, bazen taşımıyor.
    /// Tek biçime bağlı bir çözücü `completed_at`i sessizce düşürüyordu.
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            let withFraction = ISO8601DateFormatter()
            withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFraction.date(from: raw) { return date }
            if let date = ISO8601DateFormatter().date(from: raw) { return date }
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "unsupported_timestamp"
            ))
        }
        return decoder
    }()

    private func signedStorageURL(bucket: String, path: String, accessToken: String) async throws -> URL {
        var signRequest = authenticatedRequest(
            path: "/storage/v1/object/sign/\(bucket)/\(path)",
            method: "POST",
            accessToken: accessToken
        )
        signRequest.httpBody = try JSONEncoder().encode(["expiresIn": 3600])
        let (signData, signResponse) = try await session.data(for: signRequest)
        try validate(signResponse, signData)
        let signed = try JSONDecoder().decode(SignedURLResponse.self, from: signData)
        guard let URL = URL(string: "/storage/v1" + signed.signedURL, relativeTo: configuration.supabaseURL)?.absoluteURL else {
            throw BackendError.invalidResponse
        }
        return URL
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

private struct ProgramPathRow: Decodable {
    let id: UUID
    let kind: ProgramPathKind?
    let title: String
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
    let voicePreference: String

    init(draft: OnboardingDraft, variant: MeasurementVariant) {
        clientCrisisSignal = draft.crisisDetected
        // Ürünün taşıdığı iki dilden biri; ham cihaz tanımlayıcısı değil.
        // Sunucu bu değeri TTS dil koduna çeviriyor ve tanımadığı bir kod
        // telaffuzu sessizce bozuyordu.
        locale = AppLocale.current.identifier
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
        voicePreference = draft.resolvedVoicePreference.rawValue
    }
}

private struct GeneratePathResponse: Decodable {
    let status: String
    let pathId: UUID?
    let kind: ProgramPathKind?
    let title: String?
    let steps: [GeneratedPathStep]?
}

private struct ManifestRow: Decodable {
    let manifest: SessionManifest
}

private struct CompleteStepPayload: Encodable {
    let pathStepId: String
    let answer: String?
    let skipped: Bool
}

private struct CompleteStepResponse: Decodable {
    let status: String
    let nextStepStatus: String?
    let crisis: Bool?
}
