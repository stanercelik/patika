import Foundation
import Observation

/// Uygulama düzeyi kalıcı durum.
///
/// Onboarding tamamlanması `UserProfile` kaydına değil buraya yazılır: kullanıcı
/// "Şimdilik geç" diyerek hesap açmadan da devam edebilir (PRD-Ek Onboarding §9, H1).
@Observable
@MainActor
final class AppState {
    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let hasCompletedOnboarding = "onboarding.completed"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
    }
}
