import Foundation

struct AppConfiguration: Sendable {
    let supabaseURL: URL
    let supabasePublishableKey: String
    /// Google Cloud Console'daki **iOS** OAuth client ID'si (Web client ID değil).
    /// GoogleSignIn SDK'nın id_token'ının `aud` claim'i bu değeri taşır; Supabase
    /// Dashboard > Auth > Providers > Google'daki "Client IDs" listesine de
    /// eklenmesi gerekir, yoksa id_token doğrulaması sunucu tarafında reddedilir.
    let googleClientID: String

    static let live = AppConfiguration(
        supabaseURL: URL(string: "https://aapxqeqduphafisyaadk.supabase.co")!,
        // Publishable keys are intentionally safe to ship in mobile clients.
        // RLS and authenticated Edge Functions are the security boundary.
        supabasePublishableKey: "sb_publishable_JjMT_0utI6qsAUAWMjW3Sw_RlKvNIZc",
        // iOS OAuth client ID'leri gizli değildir (client secret'ı yoktur, PKCE
        // benzeri public-client akışı kullanır) — GoogleService-Info.plist'te de
        // aynı şekilde açık dağıtılır.
        googleClientID: "497996763293-lmjj5qco7qbrtvpmbkbo3udae8me8d4c.apps.googleusercontent.com"
    )
}
