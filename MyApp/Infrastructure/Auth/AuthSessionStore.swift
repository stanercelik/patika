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
        Task {
            let restored = await client.restoredSession()
            // Geri yükleme asenkron: bu arada A1'de anonim oturum açılmış
            // olabilir. Koşulsuz atama, yeni açılmış oturumu eski (ya da nil)
            // olanla eziyordu.
            if session == nil { session = restored }
        }
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

    /// İstek anında geçerli olan erişim jetonu.
    ///
    /// Üç kurtarma katmanı var ve üçü de **anonim oturuma özgü**: anonim kullanıcı
    /// kimlik bilgisi taşımadığı için oturumu kaybetmek onboarding'in ortasında
    /// akışı kilitliyordu — F1'de "bir şeyler ters gitti" ekranının en olası
    /// sebebi buydu.
    ///
    /// 1. Oturum hiç yoksa (uygulama silinip yeniden kurulmuş, keychain boş,
    ///    A1 sırasında ağ yokmuş) yeni bir anonim oturum açılır.
    /// 2. Jeton dolmuşsa yenilenir.
    /// 3. Yenileme reddedilirse (refresh token döndürülmüş ya da kullanıcı
    ///    sunucudan silinmiş) anonim oturum **yeniden** açılır. Bu yalnızca
    ///    anonim oturumda güvenli: bağlantılı bir hesapta sessizce yeni kullanıcı
    ///    yaratmak kullanıcının verisini görünmez kılardı, o yüzden orada hata
    ///    yukarı taşınır.
    func validAccessToken() async throws -> String {
        if session == nil {
            _ = await perform { try await client.signInAnonymously() }
        }
        guard var session else { throw AuthClientError.invalidResponse }
        guard session.expiresAt.timeIntervalSinceNow <= 90 else { return session.accessToken }

        do {
            session = try await client.refreshedSession(session)
        } catch {
            guard session.isAnonymous else { throw error }
            session = try await client.signInAnonymously()
        }
        self.session = session
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
