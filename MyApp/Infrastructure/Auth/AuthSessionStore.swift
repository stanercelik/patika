import Foundation
import Observation

@Observable
@MainActor
final class AuthSessionStore {
    private(set) var session: AuthSession?
    private(set) var isWorking = false
    private(set) var errorMessage: LocalizedStringResource?

    private let client: any AuthClient

    init(client: any AuthClient) {
        self.client = client
        Task { session = await client.restoredSession() }
    }

    func ensureAnonymousSession() async -> Bool {
        if session != nil { return true }
        return await perform { try await client.signInAnonymously() }
    }

    func signIn(provider: AuthProvider) async -> Bool {
        await perform { try await client.signIn(provider: provider) }
    }

    func link(provider: AuthProvider) async -> Bool {
        guard let session else {
            errorMessage = Copy.Auth.sessionMissing
            return false
        }
        return await perform { try await client.link(provider: provider, session: session) }
    }

    func validAccessToken() async throws -> String {
        guard var session else { throw AuthClientError.invalidResponse }
        if session.expiresAt.timeIntervalSinceNow <= 90 {
            session = try await client.refreshedSession(session)
            self.session = session
        }
        return session.accessToken
    }

    func clearError() { errorMessage = nil }

    private func perform(_ operation: () async throws -> AuthSession) async -> Bool {
        guard !isWorking else { return false }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            session = try await operation()
            return true
        } catch AuthClientError.cancelled {
            return false
        } catch AuthClientError.identityAlreadyLinked {
            errorMessage = Copy.Auth.identityAlreadyLinked
            return false
        } catch {
            errorMessage = Copy.Auth.failed
            return false
        }
    }
}
