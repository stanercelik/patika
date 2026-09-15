import Foundation
import LocalAuthentication
import Observation

/// Uygulama kilidi (profile-design §8.4).
///
/// Ruh sağlığı ürününde ekranda kişinin derdi yazıyor; telefon masada açık
/// kalabiliyor. Kilit isteğe bağlı ve varsayılan kapalı.
///
/// **SOS kilidin arkasında değil.** Kilit ekranında da SOS görünür ve kimlik
/// doğrulama istemeden açılır — destek hiçbir duvarın arkasına konmaz, kilit de
/// bir duvar.
@Observable
@MainActor
final class AppLockController {
    private(set) var isLocked: Bool
    private(set) var isAuthenticating = false

    /// Arka planda bu kadar kalmadan dönen kullanıcıya kilit gösterilmez: bir
    /// bildirime bakıp geri gelmek her seferinde Face ID istememeli.
    static let gracePeriod: TimeInterval = 30

    @ObservationIgnored private var backgroundedAt: Date?
    @ObservationIgnored private let store: ProfileStore

    init(store: ProfileStore) {
        self.store = store
        isLocked = store.record?.privacy.appLockEnabled ?? false
    }

    var isEnabled: Bool { store.record?.privacy.appLockEnabled ?? false }

    func sceneMovedToBackground() {
        backgroundedAt = .now
    }

    func sceneBecameActive() {
        guard isEnabled, let backgroundedAt else { return }
        self.backgroundedAt = nil
        if Date.now.timeIntervalSince(backgroundedAt) >= Self.gracePeriod {
            isLocked = true
        }
    }

    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        if await Self.authenticate() {
            isLocked = false
        }
    }

    /// Kilidi açarken önce kimlik doğrulanır: çalışmayan bir kilidi açık
    /// kaydetmek kullanıcıyı kendi uygulamasının dışında bırakabilirdi.
    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            guard Self.isAvailable, await Self.authenticate() else { return false }
        }
        var privacy = store.record?.privacy ?? PrivacySettings()
        privacy.appLockEnabled = enabled
        store.setPrivacy(privacy)
        if !enabled { isLocked = false }
        return true
    }

    static var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    static var symbolName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock"
        }
    }

    private static func authenticate() async -> Bool {
        let context = LAContext()
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: Copy.AppLock.reason)
            )
        } catch {
            return false
        }
    }
}
