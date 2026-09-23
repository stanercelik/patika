import AuthenticationServices
import CryptoKit
import Foundation
import GoogleSignIn
import Security
import UIKit

@MainActor
final class SupabaseAuthClient: NSObject, AuthClient, @unchecked Sendable {
    private let configuration: AppConfiguration
    private let keychain: KeychainSessionStore
    private var appleContinuation: CheckedContinuation<ASAuthorization, Error>?

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
        let credential = try await idTokenCredential(for: provider)
        let session = try await exchangeIDToken(credential, linkingAccessToken: nil)
        keychain.save(session)
        return session
    }

    /// Anonim oturumu kalıcı bir kimliğe bağlar. Supabase'in id_token uç noktası,
    /// istek anonim oturumun `access_token`'ıyla imzalanmışsa yeni kullanıcı
    /// açmak yerine mevcut anonim kullanıcıya kimliği bağlar (bkz. Supabase
    /// "Link identity with native OAuth (ID token)" dokümantasyonu).
    func link(provider: AuthProvider, session: AuthSession) async throws -> AuthSession {
        let current = try await fresh(session)
        let credential = try await idTokenCredential(for: provider)
        let linked = try await exchangeIDToken(credential, linkingAccessToken: current.accessToken)
        keychain.save(linked)
        return linked
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
        GIDSignIn.sharedInstance.signOut()
        keychain.clear()
    }

    private func fresh(_ session: AuthSession) async throws -> AuthSession {
        session.expiresAt.timeIntervalSinceNow > 90 ? session : try await refreshedSession(session)
    }

    // MARK: - ID token acquisition

    private struct IDTokenCredential {
        let provider: AuthProvider
        let idToken: String
        /// Apple: hash'lenmemiş ham nonce (Apple isteğine hash'lenmiş hâli gider,
        /// id_token'ın nonce claim'i o hash'i taşır — Supabase'e ham hâli gönderilir,
        /// kendi hash'leyip karşılaştırır). Google: aynı ham değer hem isteğe hem
        /// id_token claim'ine hash'lenmeden gider — Supabase'e de aynı ham hâliyle
        /// gönderilir. GoogleSignIn 10.x id_token'a kendiliğinden bir nonce claim'i
        /// koyduğu için (Supabase "nonce ile id_token'daki nonce ya ikisi de olmalı
        /// ya da ikisi de olmamalı" diyerek reddediyordu) burayı da doldurmak zorunlu.
        let nonce: String?
        /// Google: OAuth access token (Supabase id_token grant'i için gerekli). Apple: kullanılmaz.
        let accessToken: String?
    }

    private func idTokenCredential(for provider: AuthProvider) async throws -> IDTokenCredential {
        switch provider {
        case .apple: return try await appleIDTokenCredential()
        case .google: return try await googleIDTokenCredential()
        }
    }

    private func appleIDTokenCredential() async throws -> IDTokenCredential {
        let rawNonce = Nonce.random()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Nonce.sha256Hex(rawNonce)

        let authorization = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
            appleContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else { throw AuthClientError.invalidResponse }
        return IDTokenCredential(provider: .apple, idToken: idToken, nonce: rawNonce, accessToken: nil)
    }

    private func googleIDTokenCredential() async throws -> IDTokenCredential {
        guard let presenter = currentWindow().rootViewController else {
            throw AuthClientError.providerUnavailable
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: configuration.googleClientID)
        // Google'ın iOS SDK'sı isteğe göndereceğimiz nonce'u id_token'a güvenilir
        // biçimde yansıtmıyor (Supabase'in kendi dokümante ettiği bilinen bir iOS
        // sınırlaması — "Nonce check failure on mobile (Google Sign In)"). Bu yüzden
        // nonce hiç göndermiyoruz; Supabase Dashboard'da Google sağlayıcısında
        // "Skip nonce check" (iOS için) açık olmalı, yoksa "Passed nonce and nonce
        // in id_token should either both exist or not" hatası alınır.
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { result, error in
                if let error {
                    if let signInError = error as? GIDSignInError, signInError.code == .canceled {
                        continuation.resume(throwing: AuthClientError.cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: AuthClientError.invalidResponse)
                }
            }
        }
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthClientError.invalidResponse
        }
        return IDTokenCredential(
            provider: .google,
            idToken: idToken,
            nonce: nil,
            accessToken: result.user.accessToken.tokenString
        )
    }

    private func currentWindow() -> UIWindow {
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) {
            return window
        }
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            preconditionFailure("An active window scene is required for authentication")
        }
        return UIWindow(windowScene: scene)
    }

    // MARK: - Supabase exchange

    private func exchangeIDToken(_ credential: IDTokenCredential, linkingAccessToken: String?) async throws -> AuthSession {
        var components = URLComponents(
            url: configuration.supabaseURL.appending(path: "/auth/v1/token"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [.init(name: "grant_type", value: "id_token")]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.supabasePublishableKey, forHTTPHeaderField: "apikey")
        if let linkingAccessToken {
            request.setValue("Bearer \(linkingAccessToken)", forHTTPHeaderField: "Authorization")
        }
        var body: [String: String] = [
            "provider": credential.provider.rawValue,
            "id_token": credential.idToken,
        ]
        if let nonce = credential.nonce { body["nonce"] = nonce }
        if let accessToken = credential.accessToken { body["access_token"] = accessToken }
        request.httpBody = try JSONEncoder().encode(body)
        return try await performSessionRequest(request)
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

    /// Sunucunun bir oturumu kesin olarak geçersiz saydığı hata kodları. Yalnızca
    /// bunlar kimliğin kurtarılamadığı anlamına gelir; 5xx, 429 ve ağ hataları
    /// geçicidir ve oturum korunur.
    private static let rejectedSessionCodes: Set<String> = [
        "refresh_token_not_found",
        "refresh_token_already_used",
        "session_not_found",
        "session_expired",
        "user_not_found",
    ]

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let code = (try? JSONDecoder().decode(AuthErrorPayload.self, from: data).errorCode) ?? "invalid_auth_response"
            if code == "manual_linking_disabled" { throw AuthClientError.manualLinkingDisabled }
            if code == "identity_already_exists" { throw AuthClientError.identityAlreadyLinked }
            if code == "anonymous_provider_disabled" { throw AuthClientError.providerUnavailable }
            if Self.rejectedSessionCodes.contains(code) { throw AuthClientError.sessionRejected }
            throw AuthClientError.invalidResponse
        }
    }
}

extension SupabaseAuthClient: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        appleContinuation?.resume(returning: authorization)
        appleContinuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            appleContinuation?.resume(throwing: AuthClientError.cancelled)
        } else {
            appleContinuation?.resume(throwing: error)
        }
        appleContinuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        currentWindow()
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

/// Apple'ın replay-koruması için gereken rastgele nonce. Apple'ın kendi
/// örnek koduyla aynı ret-örnekleme (rejection sampling) yöntemi: bit
/// önyargısı olmadan ASCII alt kümesinden karakter seçer.
private enum Nonce {
    static func random(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            precondition(status == errSecSuccess)
            for random in randoms {
                guard remaining > 0 else { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    static func sha256Hex(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
