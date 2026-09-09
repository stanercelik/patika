import Foundation

enum AnalyticsEvent: Sendable {
    case onboardingStarted
    case authenticationFinished(provider: AuthProvider, succeeded: Bool)
    case pathGenerationFinished(result: PathGenerationTelemetryResult)
    case accountLinkFinished(provider: AuthProvider, succeeded: Bool)

    var name: String {
        switch self {
        case .onboardingStarted: "onboarding_started"
        case .authenticationFinished: "authentication_finished"
        case .pathGenerationFinished: "path_generation_finished"
        case .accountLinkFinished: "account_link_finished"
        }
    }

    var safeProperties: [String: String] {
        switch self {
        case .onboardingStarted: [:]
        case .authenticationFinished(let provider, let succeeded),
             .accountLinkFinished(let provider, let succeeded):
            ["provider": provider.rawValue, "result": succeeded ? "succeeded" : "failed"]
        case .pathGenerationFinished(let result):
            ["result": result.rawValue]
        }
    }
}

enum PathGenerationTelemetryResult: String, Sendable {
    case ready, crisis, failed
}

protocol AnalyticsClient: Sendable {
    func capture(_ event: AnalyticsEvent, subjectID: UUID) async
}

struct NoOpAnalyticsClient: AnalyticsClient {
    func capture(_ event: AnalyticsEvent, subjectID: UUID) async {}
}

struct PostHogHTTPClient: AnalyticsClient {
    let projectToken: String
    let host: URL

    init(projectToken: String, host: URL = URL(string: "https://eu.i.posthog.com")!) {
        self.projectToken = projectToken
        self.host = host
    }

    func capture(_ event: AnalyticsEvent, subjectID: UUID) async {
        var request = URLRequest(url: host.appending(path: "/capture/"))
        request.httpMethod = "POST"
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = PostHogCapture(
            apiKey: projectToken,
            event: event.name,
            properties: event.safeProperties.merging([
                "distinct_id": subjectID.uuidString.lowercased(),
                "$lib": "patika-ios",
            ]) { _, new in new }
        )
        request.httpBody = try? JSONEncoder().encode(body)
        _ = try? await URLSession.shared.data(for: request)
    }
}

private struct PostHogCapture: Encodable {
    let apiKey: String
    let event: String
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case event, properties
    }
}
