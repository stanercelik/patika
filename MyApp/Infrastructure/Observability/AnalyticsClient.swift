import Foundation

/// Only fixed, low-detail values may enter the analytics contract.
enum AnalyticsEvent: Sendable {
    case onboardingStepViewed(step: AnalyticsOnboardingStep)
    case onboardingStepCompleted(step: AnalyticsOnboardingStep)
    case problemTextSubmitted(wasWritten: Bool)
    case pathGenerationStarted
    case pathGenerationFinished(succeeded: Bool)
    case sessionStarted(source: AnalyticsSessionSource)
    case sessionCompleted(source: AnalyticsSessionSource)
    case accountChoice(AnalyticsAccountChoice)
    case appScreenViewed(AnalyticsScreen)
    case preparedPathSelected
    case reminderPreferenceChanged(enabled: Bool)
    case authenticationFinished(provider: AuthProvider, succeeded: Bool)
    case accountLinkFinished(provider: AuthProvider, succeeded: Bool)
    /// Paywall hunisi. Yalnız bağlam (`first`/`return`); fiyat, patika ve sorun gitmez.
    case paywallShown(AnalyticsPaywallContext)
    case paywallClosed(AnalyticsPaywallContext)
    case purchaseStarted(AnalyticsPaywallContext)
    case purchaseVerified(AnalyticsPaywallContext)

    var name: String {
        switch self {
        case .onboardingStepViewed: "onboarding_step_viewed"
        case .onboardingStepCompleted: "onboarding_step_completed"
        case .problemTextSubmitted: "problem_text_submitted"
        case .pathGenerationStarted: "path_generation_started"
        case .pathGenerationFinished: "path_generation_finished"
        case .sessionStarted: "session_started"
        case .sessionCompleted: "session_completed"
        case .accountChoice: "account_choice"
        case .appScreenViewed: "app_screen_viewed"
        case .preparedPathSelected: "prepared_path_selected"
        case .reminderPreferenceChanged: "reminder_preference_changed"
        case .authenticationFinished: "authentication_finished"
        case .accountLinkFinished: "account_link_finished"
        case .paywallShown: "paywall_shown"
        case .paywallClosed: "paywall_closed"
        case .purchaseStarted: "purchase_started"
        case .purchaseVerified: "purchase_verified"
        }
    }

    var safeProperties: [String: String] {
        switch self {
        case .onboardingStepViewed(let step), .onboardingStepCompleted(let step):
            ["step": step.rawValue]
        case .problemTextSubmitted(let wasWritten):
            ["written": wasWritten ? "yes" : "no"]
        case .pathGenerationFinished(let succeeded),
             .authenticationFinished(_, let succeeded),
             .accountLinkFinished(_, let succeeded):
            ["result": succeeded ? "succeeded" : "failed"]
        case .sessionStarted(let source), .sessionCompleted(let source):
            ["source": source.rawValue]
        case .accountChoice(let choice):
            ["choice": choice.rawValue]
        case .appScreenViewed(let screen):
            ["screen": screen.rawValue]
        case .reminderPreferenceChanged(let enabled):
            ["enabled": enabled ? "yes" : "no"]
        case .paywallShown(let context), .paywallClosed(let context),
             .purchaseStarted(let context), .purchaseVerified(let context):
            ["context": context.rawValue]
        case .pathGenerationStarted, .preparedPathSelected:
            [:]
        }
    }
}

enum AnalyticsOnboardingStep: String, Sendable, Hashable {
    case a1, identityName, identityGender, identityAge, a2
    case b1, b2, b3, b4, b5, b6
    case c1, c2, c3, c4
    case d0, d1, d2, d3, d4, d5, d6, d7, d8
    case e1, h2, f1, f2, commitment, g1, g2, price, h1
}

enum AnalyticsSessionSource: String, Sendable {
    case first, personal, prepared
}

enum AnalyticsAccountChoice: String, Sendable {
    case apple, google, later
}

/// Paywall'ın açıldığı yer: onboarding'deki ilk teklif ya da sonraki dönüşler.
enum AnalyticsPaywallContext: String, Sendable {
    case first
    case `return`
}

enum AnalyticsScreen: String, Sendable {
    case path, discover, me
}

struct AnalyticsStepTracker {
    private var viewed: Set<AnalyticsOnboardingStep> = []
    private var completed: Set<AnalyticsOnboardingStep> = []

    mutating func firstView(of step: AnalyticsOnboardingStep) -> Bool {
        viewed.insert(step).inserted
    }

    mutating func firstCompletion(of step: AnalyticsOnboardingStep) -> Bool {
        completed.insert(step).inserted
    }
}

protocol AnalyticsClient: Sendable {
    func capture(_ event: AnalyticsEvent, sessionID: UUID, occurredAt: Date) async
}

enum AnalyticsDeployment {
    static func canSend(environment: String?, token: String?, releaseApproved: String?) -> Bool {
        guard token?.hasPrefix("phc_") == true else { return false }
        return environment == "staging"
            || (environment == "production" && releaseApproved == "YES")
    }

    /// Hangi projeye gönderileceğine karar verir (docs/posthog-integration.md).
    ///
    /// - Derleme ayarları (`Info.plist`) gerçekten doluysa onlar kazanır: Production
    ///   yalnız böyle ve `POSTHOG_RELEASE_APPROVED=YES` ile açılır.
    /// - Doldurulmamışsa (`$(POSTHOG_…)` hiç genişlemediyse ya da boşsa) Release
    ///   derlemesi **Staging**'e gönderir; TestFlight da böylece veri üretir.
    /// - Debug hiçbir şey göndermez; yalnız `-patika-analytics-staging` başlatma
    ///   argümanıyla Staging doğrulaması yapılabilir.
    ///
    /// Döndürülen token nil ise olay gönderilmez.
    static func resolveToken(
        info: [String: Any],
        stagingToken: String,
        isDebug: Bool,
        arguments: [String]
    ) -> String? {
        if isDebug && !arguments.contains("-patika-analytics-staging") { return nil }
        let plistToken = info["POSTHOG_PROJECT_TOKEN"] as? String
        if plistToken?.hasPrefix("phc_") == true {
            return canSend(
                environment: info["POSTHOG_ENVIRONMENT"] as? String,
                token: plistToken,
                releaseApproved: info["POSTHOG_RELEASE_APPROVED"] as? String
            ) ? plistToken : nil
        }
        return canSend(environment: "staging", token: stagingToken, releaseApproved: nil) ? stagingToken : nil
    }
}

struct NoOpAnalyticsClient: AnalyticsClient {
    func capture(_ event: AnalyticsEvent, sessionID: UUID, occurredAt: Date) async {}
}

struct PostHogHTTPClient: AnalyticsClient {
    let projectToken: String
    let host: URL
    let session: URLSession

    /// ABD bulutu (proje 624242; 25 Eylül 2026 ürün sahibi kararı, önceki AB projesinin yerine).
    init(projectToken: String, host: URL = URL(string: "https://us.i.posthog.com")!, session: URLSession = .shared) {
        self.projectToken = projectToken
        self.host = host
        self.session = session
    }

    func capture(_ event: AnalyticsEvent, sessionID: UUID, occurredAt: Date) async {
        let request = makeRequest(event, sessionID: sessionID, occurredAt: occurredAt)
        // Failed deliveries never block the product or persist on disk.
        _ = try? await session.data(for: request)
    }

    func makeRequest(_ event: AnalyticsEvent, sessionID: UUID, occurredAt: Date = .now) -> URLRequest {
        var request = URLRequest(url: host.appending(path: "/i/v0/e/"))
        request.httpMethod = "POST"
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = PostHogCapture(
            apiKey: projectToken,
            distinctID: sessionID.uuidString.lowercased(),
            event: event.name,
            timestamp: ISO8601DateFormatter.string(
                from: occurredAt,
                timeZone: TimeZone(secondsFromGMT: 0)!,
                formatOptions: [.withInternetDateTime, .withFractionalSeconds]
            ),
            properties: event.safeProperties
        )
        request.httpBody = try? JSONEncoder().encode(body)
        return request
    }
}

private struct PostHogCapture: Encodable {
    let apiKey: String
    let distinctID: String
    let event: String
    let timestamp: String
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case distinctID = "distinct_id"
        case event, timestamp, properties
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(distinctID, forKey: .distinctID)
        try container.encode(event, forKey: .event)
        try container.encode(timestamp, forKey: .timestamp)
        var props = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .properties)
        try props.encode(false, forKey: DynamicCodingKey("$process_person_profile"))
        for (key, value) in properties {
            try props.encode(value, forKey: DynamicCodingKey(key))
        }
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init(_ value: String) { stringValue = value }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}
