import Foundation

/// Payment state is read from the server. A StoreKit callback never grants access.
struct PathPurchaseBackend: Sendable {
    private let configuration: AppConfiguration
    private let session: URLSession

    init(configuration: AppConfiguration = .live, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    enum Intent: Equatable {
        case ready(productID: String)
        case alreadyUnlocked
    }

    func intent(pathID: UUID, accessToken: String) async throws -> Intent {
        let response: IntentResponse = try await post("path-purchase-intent", pathID: pathID, accessToken: accessToken)
        if response.status == "already_unlocked" { return .alreadyUnlocked }
        guard response.status == "ready", let productID = response.productId else {
            throw PurchaseBackendError.invalidResponse
        }
        return .ready(productID: productID)
    }

    func isUnlocked(pathID: UUID, accessToken: String) async throws -> Bool {
        let response: StatusResponse = try await post("path-purchase-status", pathID: pathID, accessToken: accessToken)
        guard response.status == "locked" || response.status == "unlocked" else {
            throw PurchaseBackendError.invalidResponse
        }
        return response.status == "unlocked"
    }

    private func post<T: Decodable>(_ endpoint: String, pathID: UUID, accessToken: String) async throws -> T {
        var request = URLRequest(url: configuration.supabaseURL.appending(path: "/functions/v1/\(endpoint)"))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.supabasePublishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(["pathId": pathID.uuidString.lowercased()])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw PurchaseBackendError.serverUnavailable
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private struct IntentResponse: Decodable {
        let status: String
        let productId: String?
    }
    private struct StatusResponse: Decodable { let status: String }
}

enum PurchaseBackendError: Error {
    case invalidResponse
    case serverUnavailable
}
