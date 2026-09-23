import Foundation
import Observation

@Observable
@MainActor
final class Observability {
    /// Created in memory for this process only. Never stored or linked to auth.
    let analyticsSessionID = UUID()

    private let analytics: any AnalyticsClient
    private let errors: any ErrorReporter

    init(
        analytics: any AnalyticsClient,
        errors: any ErrorReporter
    ) {
        self.analytics = analytics
        self.errors = errors
        // Delete identifiers left by the previous persistent analytics design.
        UserDefaults.standard.removeObject(forKey: "privacy.analytics-subject-id")
        UserDefaults.standard.removeObject(forKey: "privacy.analytics-consent")
    }

    static func live() -> Observability {
        let info = Bundle.main.infoDictionary ?? [:]
        let analytics: any AnalyticsClient
        #if DEBUG
        analytics = NoOpAnalyticsClient()
        #else
        if let token = info["POSTHOG_PROJECT_TOKEN"] as? String,
           AnalyticsDeployment.canSend(
               environment: info["POSTHOG_ENVIRONMENT"] as? String,
               token: token,
               releaseApproved: info["POSTHOG_RELEASE_APPROVED"] as? String
           ) {
            analytics = PostHogHTTPClient(projectToken: token)
        } else {
            analytics = NoOpAnalyticsClient()
        }
        #endif
        let errors: any ErrorReporter
        if let dsn = info["SENTRY_DSN"] as? String, let reporter = SentryHTTPReporter(dsn: dsn) {
            errors = reporter
        } else {
            errors = NoOpErrorReporter()
        }
        return Observability(analytics: analytics, errors: errors)
    }

    func capture(_ event: AnalyticsEvent) {
        let occurredAt = Date()
        Task { await analytics.capture(event, sessionID: analyticsSessionID, occurredAt: occurredAt) }
    }

    func capture(_ failure: AppFailure) {
        Task { await errors.capture(failure) }
    }
}
