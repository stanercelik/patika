import AuthenticationServices
import CryptoKit
import Foundation
import Security
import UIKit

@MainActor
final class SupabaseAuthClient: NSObject, AuthClient, @unchecked Sendable {
    private let configuration: AppConfiguration
    private let keychain: KeychainSessionStore
    private var webSession: ASWebAuthenticationSession?

    init(configuration: AppConfiguration, keychain: KeychainSessionStore) {
        self.configuration = configuration
        self.keychain = keychain
    }

    func restoredSession() async -> AuthSession? { keychain.load() }

    func signInAnonymously() async throws -> AuthSession {
        var request = request(path: "/auth/v1/signup", method: "POST")
        request.httpBody = Data("{}".utf8)
        let session = try await performSessionRequest(request)
        keychain.save(session)
        return session
    }

    func signIn(provider: AuthProvider) async throws -> AuthSession {
        let verifier = PKCE.verifier()
        let callback = try await openOAuth(
            url: authorizeURL(path: "/auth/v1/authorize", provider: provider, verifier: verifier)
        )
        let session = try await exchange(callback: callback, verifier: verifier)
        keychain.save(session)
        return session
    }

    func link(provider: AuthProvider, session: AuthSession) async throws -> AuthSession {
        let current = try await fresh(session)
        let verifier = PKCE.verifier()
        let endpoint = authorizeURL(
            path: "/auth/v1/user/identities/authorize",
            provider: provider,
            verifier: verifier
        )
        var request = URLRequest(url: endpoint)
        request.setValue(configuration.supabasePublishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(current.accessToken)", forHTTPHeaderField: "Authorization")
        let redirect = try await redirectLocation(for: request)
        _ = try await openOAuth(url: redirect)
        let confirmed = try await fetchCurrentSession(current)
        keychain.save(confirmed)
        return confirmed
    }

    func refreshedSession(_ session: AuthSession) async throws -> AuthSession {
        var components = URLComponents(
            url: configuration.supabaseURL.appending(path: "/auth/v1/token"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [.init(name: "grant_type", value: "refresh_token")]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.supabasePublishableKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(["refresh_token": session.refreshToken])
        let refreshed = try await performSessionRequest(request)
        keychain.save(refreshed)
        return refreshed
    }

    func signOut(session: AuthSession?) async {
        if let session {
            var request = request(path: "/auth/v1/logout", method: "POST")
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: request)
        }
        keychain.clear()
    }

    private func fresh(_ session: AuthSession) async throws -> AuthSession {
        session.expiresAt.timeIntervalSinceNow > 90 ? session : try await refreshedSession(session)
    }

    private func authorizeURL(path: String, provider: AuthProvider, verifier: String) -> URL {
        var components = URLComponents(
            url: configuration.supabaseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            .init(name: "provider", value: provider.rawValue),
            .init(name: "redirect_to", value: "patika://auth-callback"),
            .init(name: "code_challenge", value: PKCE.challenge(verifier)),
            .init(name: "code_challenge_method", value: "s256"),
        ]
        return components.url!
    }

    private func exchange(callback: URL, verifier: String) async throws -> AuthSession {
        guard let code = URLComponents(url: callback, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value
        else { throw AuthClientError.invalidResponse }
        var components = URLComponents(
            url: configuration.supabaseURL.appending(path: "/auth/v1/token"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [.init(name: "grant_type", value: "pkce")]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.supabasePublishableKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(["auth_code": code, "code_verifier": verifier])
        return try await performSessionRequest(request)
    }

    private func fetchCurrentSession(_ session: AuthSession) async throws -> AuthSession {
        var request = self.request(path: "/auth/v1/user", method: "GET")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        let user = try JSONDecoder().decode(AuthUserPayload.self, from: data)
        return AuthSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            userID: user.id,
            expiresAt: session.expiresAt,
            isAnonymous: user.isAnonymous ?? false
        )
    }

    private func openOAuth(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "patika") { callback, error in
                if let callback { continuation.resume(returning: callback) }
                else if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                    continuation.resume(throwing: AuthClientError.cancelled)
                } else {
                    continuation.resume(throwing: error ?? AuthClientError.providerUnavailable)
                }
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = self
            webSession = session
            guard session.start() else {
                continuation.resume(throwing: AuthClientError.providerUnavailable)
                return
            }
        }
    }

    private func redirectLocation(for request: URLRequest) async throws -> URL {
        let delegate = RedirectBlocker()
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthClientError.invalidResponse }
        if let location = http.value(forHTTPHeaderField: "Location"), let url = URL(string: location) {
            return url
        }
        try validate(response: response, data: data)
        throw AuthClientError.invalidResponse
    }

    private func performSessionRequest(_ request: URLRequest) async throws -> AuthSession {
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        let payload = try JSONDecoder().decode(AuthSessionPayload.self, from: data)
        return AuthSession(
            accessToken: payload.accessToken,
            refreshToken: payload.refreshToken,
            userID: payload.user.id,
            expiresAt: Date().addingTimeInterval(TimeInterval(payload.expiresIn)),
            isAnonymous: payload.user.isAnonymous ?? false
        )
    }

    private func request(path: String, method: String) -> URLRequest {
        var request = URLRequest(url: configuration.supabaseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.supabasePublishableKey, forHTTPHeaderField: "apikey")
        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let code = (try? JSONDecoder().decode(AuthErrorPayload.self, from: data).errorCode) ?? "invalid_auth_response"
            if code == "manual_linking_disabled" { throw AuthClientError.manualLinkingDisabled }
            if code == "identity_already_exists" { throw AuthClientError.identityAlreadyLinked }
            if code == "anonymous_provider_disabled" { throw AuthClientError.providerUnavailable }
            throw AuthClientError.invalidResponse
        }
    }
}

extension SupabaseAuthClient: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let window = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)) {
            return window
        }
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            preconditionFailure("An active window scene is required for authentication")
        }
        return ASPresentationAnchor(windowScene: scene)
    }
}

private final class RedirectBlocker: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

private struct AuthSessionPayload: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: AuthUserPayload

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

private struct AuthUserPayload: Decodable {
    let id: UUID
    let isAnonymous: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case isAnonymous = "is_anonymous"
    }
}

private struct AuthErrorPayload: Decodable {
    let errorCode: String?
    enum CodingKeys: String, CodingKey { case errorCode = "error_code" }
}

private enum PKCE {
    static func verifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    static func challenge(_ verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncodedString()
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
