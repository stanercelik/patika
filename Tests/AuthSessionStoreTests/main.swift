import Foundation

// Oturum deposu — anonim kimliğin uygulama yeniden açılınca korunması.
// Test hedefi olmadığı için elle koşuluyor (bkz. CLAUDE.md, MeasurementScoring).
//
// Yakalanan hata: `AuthSessionStore.init` Keychain oturumunu fire-and-forget bir
// Task'la geri yüklüyordu ve kimse beklemiyordu. Açılışta ilk jeton isteyen
// "oturum yok" görüp yeni bir anonim kullanıcı açıyor, gerçek oturumu eziyordu:
// her açılışta yeni kimlik, yani boş patika/defter/fotoğraf.

var failures = 0
func check(_ condition: Bool, _ message: String, line: Int = #line) {
    if !condition {
        failures += 1
        print("FAIL (\(line)): \(message)")
    }
}

func session(_ name: String, expiresIn: TimeInterval = 3600, anonymous: Bool = true) -> AuthSession {
    AuthSession(
        accessToken: "access-\(name)",
        refreshToken: "refresh-\(name)",
        userID: UUID(),
        expiresAt: Date().addingTimeInterval(expiresIn),
        isAnonymous: anonymous
    )
}

/// Sahte istemci: geri yükleme yavaş olabilir, yenileme başarısız olabilir.
actor FakeClient: AuthClient {
    var stored: AuthSession?
    var restoreDelay: Duration = .zero
    var refreshDelay: Duration = .zero
    var refreshError: Error?
    private(set) var signUps = 0
    private(set) var refreshes = 0

    init(stored: AuthSession?) { self.stored = stored }

    func configure(restoreDelay: Duration = .zero, refreshDelay: Duration = .zero, refreshError: Error? = nil) {
        self.restoreDelay = restoreDelay
        self.refreshDelay = refreshDelay
        self.refreshError = refreshError
    }

    func restoredSession() async -> AuthSession? {
        try? await Task.sleep(for: restoreDelay)
        return stored
    }

    func signInAnonymously() async throws -> AuthSession {
        signUps += 1
        let created = session("new\(signUps)")
        stored = created
        return created
    }

    func signIn(provider: AuthProvider) async throws -> AuthSession { throw AuthClientError.providerUnavailable }
    func link(provider: AuthProvider, session: AuthSession) async throws -> AuthSession { throw AuthClientError.providerUnavailable }

    func refreshedSession(_ old: AuthSession) async throws -> AuthSession {
        refreshes += 1
        try? await Task.sleep(for: refreshDelay)
        if let refreshError { throw refreshError }
        let refreshed = AuthSession(
            accessToken: "refreshed-\(refreshes)",
            refreshToken: "refresh-r\(refreshes)",
            userID: old.userID,
            expiresAt: Date().addingTimeInterval(3600),
            isAnonymous: old.isAnonymous
        )
        stored = refreshed
        return refreshed
    }

    func signOut(session: AuthSession?) async { stored = nil }
}

@MainActor
func run() async {
    // 1. Açılış yarışı: geri yükleme bitmeden jeton istenirse yeni kimlik AÇILMAZ.
    do {
        let existing = session("existing")
        let client = FakeClient(stored: existing)
        await client.configure(restoreDelay: .milliseconds(150))
        let store = AuthSessionStore(client: client)

        let token = try? await store.validAccessToken()
        check(token == "access-existing", "geri yüklenen oturumun jetonu kullanılır (gelen: \(token ?? "nil"))")
        check(await client.signUps == 0, "geri yükleme beklenirken yeni anonim kullanıcı açılmaz (açılan: \(await client.signUps))")
        check(store.session?.userID == existing.userID, "kimlik korunur")
    }

    // 2. Aynı yarış onboarding'in A1 ekranında: oturum varken yeniden kayıt yok.
    do {
        let existing = session("existing")
        let client = FakeClient(stored: existing)
        await client.configure(restoreDelay: .milliseconds(150))
        let store = AuthSessionStore(client: client)

        let ok = await store.ensureAnonymousSession()
        check(ok, "oturum hazır")
        check(await client.signUps == 0, "ensureAnonymousSession de geri yüklemeyi bekler")
        check(store.session?.userID == existing.userID, "kimlik korunur (A1)")
    }

    // 3. Geçici yenileme hatası (ağ, zaman aşımı, iptal) kimliği YOK ETMEZ.
    do {
        let expired = session("expired", expiresIn: 10)
        let client = FakeClient(stored: expired)
        await client.configure(refreshError: URLError(.notConnectedToInternet))
        let store = AuthSessionStore(client: client)

        let token = try? await store.validAccessToken()
        check(token == nil, "geçici hata yukarı taşınır, sahte jeton dönmez")
        check(await client.signUps == 0, "geçici hata yeni kullanıcı açtırmaz (açılan: \(await client.signUps))")
        check(store.session?.userID == expired.userID, "eldeki oturum silinmez")
    }

    // 4. Eşzamanlı çağrılar tek yenileme yapar (açılışta birkaç ekran aynı anda ister).
    do {
        let expired = session("expired", expiresIn: 10)
        let client = FakeClient(stored: expired)
        await client.configure(refreshDelay: .milliseconds(80))
        let store = AuthSessionStore(client: client)

        async let a = store.validAccessToken()
        async let b = store.validAccessToken()
        async let c = store.validAccessToken()
        let tokens = try? await [a, b, c]
        check(tokens == ["refreshed-1", "refreshed-1", "refreshed-1"], "üç çağrı aynı jetonu alır (gelen: \(String(describing: tokens)))")
        check(await client.refreshes == 1, "tek yenileme isteği (yapılan: \(await client.refreshes))")
        check(await client.signUps == 0, "yeni kullanıcı açılmaz")
    }

    // 4b. Çağıran iptal edilse bile yenileme tamamlanır ve sonuç saklanır.
    do {
        let expired = session("expired", expiresIn: 10)
        let client = FakeClient(stored: expired)
        await client.configure(refreshDelay: .milliseconds(100))
        let store = AuthSessionStore(client: client)

        let caller = Task { try await store.validAccessToken() }
        try? await Task.sleep(for: .milliseconds(30))
        caller.cancel()
        try? await Task.sleep(for: .milliseconds(200))
        check(await client.signUps == 0, "iptal yeni kullanıcı açtırmaz")
        check(store.session?.accessToken == "refreshed-1", "yenilenen oturum iptale rağmen saklanır (eldeki: \(store.session?.accessToken ?? "nil"))")
    }

    // 4c. Sunucu yenileme jetonunu KESİN reddederse anonim oturum yeniden açılır.
    do {
        let expired = session("expired", expiresIn: 10)
        let client = FakeClient(stored: expired)
        await client.configure(refreshError: AuthClientError.sessionRejected)
        let store = AuthSessionStore(client: client)

        let token = try? await store.validAccessToken()
        check(token == "access-new1", "kurtarılamayan anonim oturum yenisiyle değişir (gelen: \(token ?? "nil"))")
        check(await client.signUps == 1, "tek yeni kullanıcı")
    }

    // 4d. Bağlantılı hesapta sessizce yeni kullanıcı AÇILMAZ; hata yukarı taşınır.
    do {
        let linked = session("linked", expiresIn: 10, anonymous: false)
        let client = FakeClient(stored: linked)
        await client.configure(refreshError: AuthClientError.sessionRejected)
        let store = AuthSessionStore(client: client)

        let token = try? await store.validAccessToken()
        check(token == nil, "bağlantılı hesapta hata yukarı taşınır")
        check(await client.signUps == 0, "bağlantılı hesap yeni anonim kullanıcıya dönüşmez")
        check(store.session?.userID == linked.userID, "bağlantılı oturum yerinde kalır")
    }

    // 4e. hasStoredSession geri yüklemeyi bekler ve ASLA yeni oturum açmaz.
    do {
        let client = FakeClient(stored: session("existing"))
        await client.configure(restoreDelay: .milliseconds(100))
        let store = AuthSessionStore(client: client)
        check(await store.hasStoredSession(), "kayıtlı oturum bulunur (geri yükleme beklenir)")

        let empty = FakeClient(stored: nil)
        let emptyStore = AuthSessionStore(client: empty)
        check(await emptyStore.hasStoredSession() == false, "ilk kurulumda oturum yok")
        check(await empty.signUps == 0, "sorgu yeni kullanıcı açmaz")
    }

    // 5. Oturum hiç yoksa (ilk açılış) tek bir anonim kullanıcı açılır.
    do {
        let client = FakeClient(stored: nil)
        let store = AuthSessionStore(client: client)

        async let a = store.validAccessToken()
        async let b = store.validAccessToken()
        _ = try? await [a, b]
        check(await client.signUps == 1, "ilk açılışta eşzamanlı isteklere rağmen tek kullanıcı (açılan: \(await client.signUps))")
    }
}

await run()

if failures == 0 {
    print("AuthSessionStore: hepsi geçti")
} else {
    print("AuthSessionStore: \(failures) hata")
    exit(1)
}
