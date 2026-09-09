import Foundation
import Observation

@Observable
@MainActor
final class Observability {
    private(set) var analyticsConsent: Bool
    let analyticsSubjectID: UUID

    private let analytics: any AnalyticsClient
    private let errors: any ErrorReporter
    private let defaults: UserDefaults

    init(
        analytics: any AnalyticsClient,
        errors: any ErrorReporter,
        defaults: UserDefaults = .standard
    ) {
        self.analytics = analytics
        self.errors = errors
        self.defaults = defaults
        analyticsConsent = defaults.bool(forKey: "privacy.analytics-consent")
        if let stored = defaults.string(forKey: "privacy.analytics-subject-id"),
           let id = UUID(uuidString: stored) {
            analyticsSubjectID = id
        } else {
            let id = UUID()
            analyticsSubjectID = id
            defaults.set(id.uuidString.lowercased(), forKey: "privacy.analytics-subject-id")
        }
    }

    static func live() -> Observability {
        let info = Bundle.main.infoDictionary ?? [:]
        let analytics: any AnalyticsClient = PostHogHTTPClient(
            projectToken: AppConfiguration.live.postHogProjectToken
        )
        let errors: any ErrorReporter
        if let dsn = info["SENTRY_DSN"] as? String, let reporter = SentryHTTPReporter(dsn: dsn) {
            errors = reporter
        } else {
            errors = NoOpErrorReporter()
        }
        return Observability(analytics: analytics, errors: errors)
    }

    func setAnalyticsConsent(_ consent: Bool) {
        analyticsConsent = consent
        defaults.set(consent, forKey: "privacy.analytics-consent")
    }

    func capture(_ event: AnalyticsEvent) {
        guard analyticsConsent else { return }
        Task { await analytics.capture(event, subjectID: analyticsSubjectID) }
    }

    func capture(_ failure: AppFailure) {
        Task { await errors.capture(failure) }
    }
}
