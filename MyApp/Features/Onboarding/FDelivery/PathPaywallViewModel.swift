import Foundation
import Observation
import RevenueCat

@Observable
@MainActor
final class PathPaywallViewModel {
    enum State {
        case loading
        case ready(Offering)
        case checking
        case unlocked
        case unavailable
    }

    private(set) var state: State = .loading
    private(set) var hasError = false
    private(set) var restoreUnavailable = false
    let days: Int
    let remainingSessions: Int
    private let pathID: UUID
    private let services: AppServices

    init(services: AppServices, pathID: UUID, days: Int) {
        self.services = services
        self.pathID = pathID
        self.days = days
        self.remainingSessions = max(0, days - 1)
    }

    func load() async {
        hasError = false
        restoreUnavailable = false
        state = .loading
        do {
            let token = try await services.auth.validAccessToken()
            guard let userID = services.auth.session?.userID else { throw RevenueCatConfigurationError.missingIdentity }
            try await services.purchases.configure(for: userID)
            if try await services.purchaseBackend.isUnlocked(pathID: pathID, accessToken: token) {
                state = .unlocked
            } else {
                state = .ready(try await services.purchases.offering(for: days))
            }
        } catch {
            state = .unavailable
        }
    }

    func restore() async {
        restoreUnavailable = false
        do {
            _ = try await Purchases.shared.restorePurchases()
            let token = try await services.auth.validAccessToken()
            if try await services.purchaseBackend.isUnlocked(pathID: pathID, accessToken: token) {
                state = .unlocked
            } else {
                restoreUnavailable = true
            }
        } catch {
            restoreUnavailable = true
        }
    }

    /// Called from RevenueCatUI's purchase interceptor before StoreKit opens.
    func preparePurchase(productID: String) async -> Bool {
        guard productID == "path.unlock.\(days)d" else { hasError = true; return false }
        do {
            let token = try await services.auth.validAccessToken()
            switch try await services.purchaseBackend.intent(pathID: pathID, accessToken: token) {
            case .alreadyUnlocked:
                state = .unlocked
                return false
            case .ready(let expectedProduct):
                return productID == expectedProduct
            }
        } catch {
            hasError = true
            return false
        }
    }

    func checkPurchase() async {
        state = .checking
        hasError = false
        // The callback only starts server polling; it never opens paid content.
        for _ in 0..<12 {
            do {
                let token = try await services.auth.validAccessToken()
                if try await services.purchaseBackend.isUnlocked(pathID: pathID, accessToken: token) {
                    state = .unlocked
                    return
                }
            } catch {
                // A temporary network failure must not erase the pending state.
            }
            try? await Task.sleep(for: .seconds(2))
        }
        hasError = true
    }
}
