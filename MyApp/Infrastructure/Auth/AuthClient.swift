import Foundation

enum AuthProvider: String, Sendable {
    case apple
    case google
}

struct AuthSession: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let userID: UUID
    let expiresAt: Date
    let isAnonymous: Bool
}

protocol AuthClient: Sendable {
    func restoredSession() async -> AuthSession?
    func signInAnonymously() async throws -> AuthSession
    func signIn(provider: AuthProvider) async throws -> AuthSession
    func link(provider: AuthProvider, session: AuthSession) async throws -> AuthSession
    func refreshedSession(_ session: AuthSession) async throws -> AuthSession
    func signOut(session: AuthSession?) async
}

enum AuthClientError: LocalizedError {
    case invalidResponse
    case providerUnavailable
    case cancelled
    case manualLinkingDisabled
    case identityAlreadyLinked

    var errorDescription: String? {
        switch self {
        case .cancelled: "cancelled"
        case .providerUnavailable: "provider_unavailable"
        case .manualLinkingDisabled: "manual_linking_disabled"
        case .identityAlreadyLinked: "identity_already_exists"
        case .invalidResponse: "invalid_auth_response"
        }
    }
}
