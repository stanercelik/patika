import Foundation
import Observation

@Observable
@MainActor
final class AppServices {
    let auth: AuthSessionStore
    let backend: any BackendClient
    let observability: Observability

    init(auth: AuthSessionStore, backend: any BackendClient, observability: Observability) {
        self.auth = auth
        self.backend = backend
        self.observability = observability
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
            observability: .live()
        )
    }
}
