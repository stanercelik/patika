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

protocol BackendClient: Sendable {
    func generatePath(
        from draft: OnboardingDraft,
        measurementVariant: MeasurementVariant,
        accessToken: String,
        idempotencyKey: UUID
    ) async throws -> PathGenerationResult
    func hasCompletedOnboarding(accessToken: String) async throws -> Bool
    func markOnboardingCompleted(accessToken: String) async throws
}

enum BackendError: LocalizedError {
    case invalidResponse
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "invalid_backend_response"
        case .unavailable: "backend_unavailable"
        }
    }
}
