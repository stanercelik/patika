import Foundation
import RevenueCat

@MainActor
final class RevenueCatPurchaseService {
    private(set) var configuredUserID: UUID?

    func configure(for userID: UUID) async throws {
        let key = (Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_IOS_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard key.hasPrefix("appl_") else { throw RevenueCatConfigurationError.missingPublicKey }
        if configuredUserID == userID { return }
        if configuredUserID == nil {
            let configuration = Configuration.Builder(withAPIKey: key)
                .with(appUserID: userID.uuidString.lowercased())
                .build()
            Purchases.configure(with: configuration)
        } else {
            _ = try await Purchases.shared.logIn(userID.uuidString.lowercased())
        }
        configuredUserID = userID
    }

    func offering(for days: Int) async throws -> Offering {
        guard configuredUserID != nil else { throw RevenueCatConfigurationError.missingIdentity }
        let identifier = "path_\(days)d"
        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.all[identifier],
              offering.availablePackages.count == 1,
              offering.availablePackages[0].storeProduct.productIdentifier == "path.unlock.\(days)d" else {
            throw RevenueCatConfigurationError.offeringUnavailable
        }
        return offering
    }
}

enum RevenueCatConfigurationError: Error {
    case missingPublicKey
    case missingIdentity
    case offeringUnavailable
}
