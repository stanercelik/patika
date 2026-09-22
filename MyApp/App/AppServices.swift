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
    /// Profil fotoğrafının cihazdaki kopyası.
    let avatar: AvatarStore
    let promiseSignature: PromiseSignatureStore
    let appLock: AppLockController

    init(
        auth: AuthSessionStore,
        backend: any BackendClient,
        observability: Observability,
        profile: ProfileStore,
        avatar: AvatarStore,
        promiseSignature: PromiseSignatureStore
    ) {
        self.auth = auth
        self.backend = backend
        self.observability = observability
        self.profile = profile
        self.avatar = avatar
        self.promiseSignature = promiseSignature
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
            profile: makeProfileStore(),
            avatar: makeAvatarStore(),
            promiseSignature: .live()
        )
    }

    private static func makeAvatarStore() -> AvatarStore {
        #if DEBUG
        // Örnek senaryo gerçek hesabın fotoğraf önbelleğine dokunmaz.
        if MeDebugSeed.scenario != nil { return .ephemeral() }
        #endif
        return .live()
    }

    private static func makeProfileStore() -> ProfileStore {
        #if DEBUG
        if let seeded = MeDebugSeed.makeStore() { return seeded }
        #endif
        return .live()
    }
}
