import Foundation
import Observation

@Observable
@MainActor
final class AuthSessionStore {
    private(set) var session: AuthSession?
    private(set) var isWorking = false
    private(set) var errorMessage: LocalizedStringResource?

    private let client: any AuthClient
    /// Keychain'deki oturumun geri yüklenmesi. **Her giriş noktası bunu bekler.**
    ///
    /// Önceden geri yükleme fire-and-forget'ti: açılışta ilk jeton isteyen
    /// `session == nil` görüyor, "henüz yüklenmedi"yi "oturum yok" sanıp yeni bir
    /// anonim kullanıcı açıyor ve Keychain'deki gerçek oturumu eziyordu. Sonuç:
    /// her açılışta yeni kimlik — boş patika, kaybolan defter ve fotoğraf.
    @ObservationIgnored private var restoration: Task<Void, Never>?
    /// Uçuştaki jeton isteği. Açılışta birkaç ekran aynı anda jeton ister; hepsi
    /// tek isteği paylaşır. Ayrıca yenileme çağıranın Task'ından **bağımsız**
    /// yürür: sunucu yenilemeyi tamamladıktan sonra çağıran iptal edilirse yeni
    /// jeton kaybolur ve eldeki eski jeton geçersiz kalırdı.
    @ObservationIgnored private var inflight: Task<AuthSession, Error>?

    init(client: any AuthClient) {
        self.client = client
        restoration = Task { [weak self] in
            let restored = await client.restoredSession()
            guard let self else { return }
            // Bu arada A1'de oturum açılmış olabilir; koşulsuz atama yeni
            // oturumu eski (ya da nil) olanla eziyordu.
            if session == nil { session = restored }
        }
    }

    /// Cihazda kayıtlı bir oturum var mı? Geri yükleme bitince cevap verir; yeni
    /// oturum **açmaz**. İlk kurulumda (Keychain boş) sunucuya hiç gidilmesin diye.
    func hasStoredSession() async -> Bool {
        await restoration?.value
        return session != nil
    }

    func ensureAnonymousSession() async -> Bool {
        do {
            _ = try await validAccessToken()
            return true
        } catch {
            errorMessage = Copy.Auth.failed
            return false
        }
    }

    func signIn(provider: AuthProvider) async -> Bool {
        await restoration?.value
        return await perform { try await client.signIn(provider: provider) }
    }

    func link(provider: AuthProvider) async -> Bool {
        await restoration?.value
        guard let session else {
            errorMessage = Copy.Auth.sessionMissing
            return false
        }
        return await perform { try await client.link(provider: provider, session: session) }
    }

    /// İstek anında geçerli olan erişim jetonu.
    ///
    /// Kimlik kaybı bu fonksiyonda olur, o yüzden kurallar dar:
    ///
    /// 1. Önce geri yükleme beklenir. Oturum **yalnızca** Keychain gerçekten
    ///    boşsa (ilk açılış, cihaz sıfırlanmış) yeni bir anonim kullanıcıyla
    ///    başlar.
    /// 2. Jeton dolmuşsa yenilenir. Geçici hata (ağ yok, zaman aşımı, sunucu
    ///    5xx) **kimliği yok etmez**: hata yukarı taşınır, oturum yerinde kalır,
    ///    bir sonraki istek yeniden dener. Anonim kullanıcı kimlik bilgisi
    ///    taşımadığı için yeni kullanıcı açmak, ona ait bütün veriyi (patika,
    ///    defter, fotoğraf) erişilemez bırakmak demek.
    /// 3. Yalnızca sunucu yenileme jetonunu **kesin olarak reddettiyse**
    ///    (`sessionRejected`: döndürülmüş, silinmiş, oturumu yok) anonim oturum
    ///    yeniden açılır — kurtarılacak kimlik kalmamıştır. Bağlantılı bir
    ///    hesapta sessizce yeni kullanıcı yaratmak verisini görünmez kılardı;
    ///    orada hata yukarı taşınır.
    func validAccessToken() async throws -> String {
        await restoration?.value
        if let session, session.expiresAt.timeIntervalSinceNow > 90 {
            return session.accessToken
        }
        if let inflight {
            return try await inflight.value.accessToken
        }
        let task = Task { try await self.obtainSession() }
        inflight = task
        defer { inflight = nil }
        return try await task.value.accessToken
    }

    private func obtainSession() async throws -> AuthSession {
        guard let current = session else {
            return try await establishAnonymousSession()
        }
        guard current.expiresAt.timeIntervalSinceNow <= 90 else { return current }
        do {
            let refreshed = try await client.refreshedSession(current)
            session = refreshed
            return refreshed
        } catch AuthClientError.sessionRejected where current.isAnonymous {
            return try await establishAnonymousSession()
        }
    }

    private func establishAnonymousSession() async throws -> AuthSession {
        let created = try await client.signInAnonymously()
        session = created
        return created
    }

    func clearError() { errorMessage = nil }

    /// Hesap silindikten sonra. Keychain'deki oturum da temizlenir; uygulama bir
    /// sonraki açılışta sıfırdan başlar.
    func signOut() async {
        await restoration?.value
        inflight?.cancel()
        inflight = nil
        await client.signOut(session: session)
        session = nil
    }

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
