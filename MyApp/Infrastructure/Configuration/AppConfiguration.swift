import Foundation

struct AppConfiguration: Sendable {
    let supabaseURL: URL
    let supabasePublishableKey: String
    let postHogProjectToken: String

    static let live = AppConfiguration(
        supabaseURL: URL(string: "https://aapxqeqduphafisyaadk.supabase.co")!,
        // Publishable keys are intentionally safe to ship in mobile clients.
        // RLS and authenticated Edge Functions are the security boundary.
        supabasePublishableKey: "sb_publishable_JjMT_0utI6qsAUAWMjW3Sw_RlKvNIZc",
        // PostHog project tokens identify the ingestion project; they are public
        // client configuration, not personal API keys.
        postHogProjectToken: "phc_Q82NXCbjEZXjGdzT2CYsIjQIZEG0Bu4Ba2RBFQSwHxL"
    )
}
