import Foundation
import Observation

@Observable
@MainActor
final class AppServices {
    let auth: AuthSessionStore
    let backend: any BackendClient
    let observability: Observability
    /// Cihazdaki kişisel kayıt — "Ben" sekmesinin kaynağı.
    let profile: ProfileStore
    let appLock: AppLockController

    init(
        auth: AuthSessionStore,
        backend: any BackendClient,
        observability: Observability,
        profile: ProfileStore
    ) {
        self.auth = auth
        self.backend = backend
        self.observability = observability
        self.profile = profile
        self.appLock = AppLockController(store: profile)
    }

    static func live() -> AppServices {
        AppServices(
            auth: AuthSessionStore(
                client: SupabaseAuthClient(
                    configuration: .live,
                    keychain: KeychainSessionStore()
                )
            ),
            backend: SupabaseBackendClient(),
            observability: .live(),
            profile: makeProfileStore()
        )
    }

    private static func makeProfileStore() -> ProfileStore {
        #if DEBUG
        if let seeded = MeDebugSeed.makeStore() { return seeded }
        #endif
        return .live()
    }
}
