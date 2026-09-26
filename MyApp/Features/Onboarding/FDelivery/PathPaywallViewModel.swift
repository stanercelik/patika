import Foundation
import Observation
import RevenueCat

/// Tek patika teklifinin durumu. Çağıran (onboarding akışı, Yolum, Ben) bunu
/// **paywall açılmadan önce** kurar ve `load()` eder: tam ekran kaplama ancak teklif
/// hazır olunca açılır ve içeriği doğrudan RevenueCat paywall'ıdır. Arada uygulamanın
/// kendi yükleniyor ekranı görünmez (ürün sahibi, 25 Eylül 2026).
@Observable
@MainActor
final class PathPaywallViewModel: Identifiable {
    enum State {
        case loading
        case ready(Offering)
        case checking
        case unlocked
        case unavailable
    }

    private(set) var state: State = .loading

    func clearError() { hasError = false }

    var isUnlocked: Bool {
        if case .unlocked = state { return true }
        return false
    }

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }
    private(set) var hasError = false
    private(set) var restoreUnavailable = false
    let days: Int
    let remainingSessions: Int
    let context: AnalyticsPaywallContext
    private let reminderTime: String?
    private let pathID: UUID
    private let services: AppServices

    init(
        services: AppServices,
        pathID: UUID,
        days: Int,
        context: AnalyticsPaywallContext,
        reminderTime: String?
    ) {
        self.services = services
        self.pathID = pathID
        self.days = days
        self.remainingSessions = max(0, days - 1)
        self.context = context
        self.reminderTime = reminderTime
    }

    /// RevenueCat editöründeki custom değişkenlerin değerleri (docs/paywall-stratejisi.md
    /// §5.1). Yalnız sayılar, saat ve mağaza fiyatından türeyen metin: sorun, patika adı
    /// ve ölçüm RevenueCat'e gitmez. `CustomVariableValue`'ya görünüm çevirir (RevenueCatUI
    /// SwiftUI getirir, ViewModel onu import etmez).
    enum PaywallVariable {
        case number(Double)
        case text(String)
    }

    func paywallVariables(for offering: Offering) -> [String: PaywallVariable] {
        [
            "path_days": .number(Double(days)),
            "remaining_sessions": .number(Double(remainingSessions)),
            "reminder_time": .text(reminderTime ?? ""),
            "price_per_session": .text(
                offering.availablePackages.first.map {
                    Self.pricePerSession($0.storeProduct, sessions: remainingSessions)
                } ?? ""
            ),
            "context": .text(context.rawValue),
        ]
    }

    /// Mağaza fiyatının kalan oturuma bölümü, ürünün kendi para birimi biçimiyle.
    /// Biçimlendirici yoksa boş döner; editördeki kural o zaman satırı değiştirir.
    nonisolated static func pricePerSession(_ product: StoreProduct, sessions: Int) -> String {
        guard sessions > 0, let formatter = product.priceFormatter else { return "" }
        let value = product.price / Decimal(sessions)
        return formatter.string(from: value as NSDecimalNumber) ?? ""
    }

    /// Paywall ekrana geldi mi: satın alma sonrası `unlocked` olan teklif, kapanış
    /// sırasında kaplamayı erkenden düşürmesin diye ayırt edilir.
    private(set) var wasShown = false

    func paywallShown() {
        wasShown = true
        services.observability.capture(.paywallShown(context))
    }

    func paywallClosed() {
        services.observability.capture(.paywallClosed(context))
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
                guard productID == expectedProduct else { return false }
                services.observability.capture(.purchaseStarted(context))
                return true
            }
        } catch {
            hasError = true
            return false
        }
    }

    /// Satın alma ya da geri yükleme sonrası: paywall açık kalırken sunucunun hakkı
    /// yazmasını bekler. Sunucu satın almayı RevenueCat'ten kendisi doğruladığı için
    /// genelde ilk yanıtta açılır; webhook'u beklemez. Doğrulama ekranı göstermez:
    /// çağıran sonuç ne olursa olsun kullanıcıyı satın aldığı yere döndürür, hak
    /// gecikirse bir sonraki durum sorgusu onu yine açar.
    func confirmPurchase() async -> Bool {
        for attempt in 0..<8 {
            if attempt > 0 { try? await Task.sleep(for: .seconds(1)) }
            do {
                let token = try await services.auth.validAccessToken()
                if try await services.purchaseBackend.isUnlocked(pathID: pathID, accessToken: token) {
                    state = .unlocked
                    services.observability.capture(.purchaseVerified(context))
                    return true
                }
            } catch {
                // Geçici ağ hatası: bir sonraki denemede yeniden sorulur.
            }
        }
        return false
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
                    services.observability.capture(.purchaseVerified(context))
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
