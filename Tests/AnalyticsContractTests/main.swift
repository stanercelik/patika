import Foundation

// Standalone test target shim; the app supplies this enum from AuthClient.swift.
enum AuthProvider: String, Sendable { case apple, google }

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

let client = PostHogHTTPClient(projectToken: "phc_test")
let sessionID = UUID()
let occurredAt = Date(timeIntervalSince1970: 1_700_000_000.123)
let events: [AnalyticsEvent] = [
    .onboardingStepViewed(step: .b1),
    .onboardingStepCompleted(step: .d8),
    .problemTextSubmitted(wasWritten: true),
    .pathGenerationStarted,
    .pathGenerationFinished(succeeded: false),
    .sessionStarted(source: .first),
    .sessionCompleted(source: .prepared),
    .accountChoice(.later),
    .appScreenViewed(.me),
    .preparedPathSelected,
    .reminderPreferenceChanged(enabled: true),
    .authenticationFinished(provider: .apple, succeeded: true),
    .accountLinkFinished(provider: .google, succeeded: false),
    .paywallShown(.first),
    .paywallClosed(.return),
    .purchaseStarted(.first),
    .purchaseVerified(.return),
]

let allowedKeys: Set<String> = [
    "step", "written", "result", "source", "choice", "screen", "enabled", "context",
    "$process_person_profile",
]

var tracker = AnalyticsStepTracker()
check(tracker.firstView(of: .a1), "first view")
check(!tracker.firstView(of: .a1), "repeat view")
check(tracker.firstCompletion(of: .a1), "first completion")
check(!tracker.firstCompletion(of: .a1), "repeat completion")
check(tracker.firstView(of: .b1), "different step is independent")

for event in events {
    let request = client.makeRequest(event, sessionID: sessionID, occurredAt: occurredAt)
    check(request.url?.absoluteString == "https://us.i.posthog.com/i/v0/e/", "US endpoint")
    check(request.httpMethod == "POST", "HTTP method")
    let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
    check(body["event"] as? String == event.name, "event name")
    check(body["timestamp"] as? String == "2023-11-14T22:13:20.123Z", "event occurrence time")
    check(body["distinct_id"] as? String == sessionID.uuidString.lowercased(), "ephemeral session ID")
    check(body["api_key"] as? String == "phc_test", "project token")
    let properties = body["properties"] as! [String: Any]
    check(Set(properties.keys).isSubset(of: allowedKeys), "unexpected property")
    check(properties["$process_person_profile"] as? Bool == false, "person profile disabled")
    check(properties["distinct_id"] == nil, "identity must only be top-level")
}

let flowSource = try String(contentsOfFile: "MyApp/Features/Onboarding/OnboardingFlowViewModel.swift", encoding: .utf8)
check(flowSource.contains("analyticsSteps.firstView(of: id)"), "flow uses view deduplication")
check(flowSource.contains("analyticsSteps.firstCompletion(of: id)"), "flow uses completion deduplication")
check(flowSource.contains("case .crisis: nil"), "crisis screen excluded")
check(!flowSource.contains("result: .crisis"), "crisis outcome excluded")

let observationSource = try String(contentsOfFile: "MyApp/Infrastructure/Observability/Observability.swift", encoding: .utf8)
check(observationSource.contains("#if DEBUG"), "debug gate")
check(AnalyticsDeployment.canSend(environment: "staging", token: "phc_test", releaseApproved: nil), "staging release enabled")
check(!AnalyticsDeployment.canSend(environment: "production", token: "phc_test", releaseApproved: nil), "production default off")
check(AnalyticsDeployment.canSend(environment: "production", token: "phc_test", releaseApproved: "YES"), "production requires approval")
check(!AnalyticsDeployment.canSend(environment: "staging", token: "wrong", releaseApproved: "YES"), "invalid token off")
check(!AnalyticsDeployment.canSend(environment: "unknown", token: "phc_test", releaseApproved: "YES"), "unknown environment off")
check(!observationSource.contains("analyticsSubjectID"), "persistent subject removed")

print("Analytics privacy contract passed")

// Token çözümü: Debug varsayılan kapalı, Release varsayılan Staging, Production kapılı.
let staging = "phc_staging"
check(AnalyticsDeployment.resolveToken(info: [:], stagingToken: staging, isDebug: true, arguments: []) == nil,
      "debug sends nothing by default")
check(AnalyticsDeployment.resolveToken(info: [:], stagingToken: staging, isDebug: true,
                                       arguments: ["-patika-analytics-staging"]) == staging,
      "debug can opt into staging for verification")
check(AnalyticsDeployment.resolveToken(info: ["POSTHOG_PROJECT_TOKEN": "$(POSTHOG_PROJECT_TOKEN)"],
                                       stagingToken: staging, isDebug: false, arguments: []) == staging,
      "release without build settings falls back to staging")
check(AnalyticsDeployment.resolveToken(info: ["POSTHOG_PROJECT_TOKEN": "phc_prod", "POSTHOG_ENVIRONMENT": "production"],
                                       stagingToken: staging, isDebug: false, arguments: []) == nil,
      "production without approval sends nothing")
check(AnalyticsDeployment.resolveToken(info: ["POSTHOG_PROJECT_TOKEN": "phc_prod", "POSTHOG_ENVIRONMENT": "production",
                                              "POSTHOG_RELEASE_APPROVED": "YES"],
                                       stagingToken: staging, isDebug: false, arguments: []) == "phc_prod",
      "approved production uses its own token")
check(AnalyticsDeployment.resolveToken(info: [:], stagingToken: "sk_not_a_project_token", isDebug: false, arguments: []) == nil,
      "only project tokens are accepted")
print("Analytics deployment resolution passed")

