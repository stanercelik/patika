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
        guard 200..<300 ~= http.statusCode else { throw BackendError.unavailable }
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
        try validate(response)
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
        let (_, response) = try await session.data(for: request)
        try validate(response)
    }

    private func authenticatedRequest(path: String, method: String, accessToken: String) -> URLRequest {
        var request = URLRequest(url: URL(string: path, relativeTo: configuration.supabaseURL)!.absoluteURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.supabasePublishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw BackendError.unavailable
        }
    }

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
