import Foundation

struct AppConfiguration: Sendable {
    let supabaseURL: URL
    let supabasePublishableKey: String
    /// Google Cloud Console'daki **iOS** OAuth client ID'si (Web client ID değil).
    /// GoogleSignIn SDK'nın id_token'ının `aud` claim'i bu değeri taşır; Supabase
    /// Dashboard > Auth > Providers > Google'daki "Client IDs" listesine de
    /// eklenmesi gerekir, yoksa id_token doğrulaması sunucu tarafında reddedilir.
    let googleClientID: String
    /// RevenueCat **public** Apple SDK key (`appl_…`). İstemci için tasarlanmış açık
    /// anahtardır: yalnızca bu uygulamanın satın alma ve teklif okumasına izin verir.
    /// Gizli `sk_…` anahtarı asla burada durmaz; yalnız Supabase Edge Function
    /// secret'ı `REVENUECAT_SECRET_API_KEY` olarak sunucuda kalır.
    let revenueCatAPIKey: String
    /// PostHog **Patika** projesi (ABD bulutu, proje 624242) proje token'ı. Yalnız
    /// olay göndermeye yarayan, istemcide görünmek üzere tasarlanmış açık anahtar;
    /// okuma yetkisi yok (docs/posthog-integration.md).
    let postHogProjectToken: String

    static let live = AppConfiguration(
        supabaseURL: URL(string: "https://aapxqeqduphafisyaadk.supabase.co")!,
        // Publishable keys are intentionally safe to ship in mobile clients.
        // RLS and authenticated Edge Functions are the security boundary.
        supabasePublishableKey: "sb_publishable_JjMT_0utI6qsAUAWMjW3Sw_RlKvNIZc",
        // iOS OAuth client ID'leri gizli değildir (client secret'ı yoktur, PKCE
        // benzeri public-client akışı kullanır) — GoogleService-Info.plist'te de
        // aynı şekilde açık dağıtılır.
        googleClientID: "497996763293-lmjj5qco7qbrtvpmbkbo3udae8me8d4c.apps.googleusercontent.com",
        revenueCatAPIKey: "appl_wTmOzyIWRKDPSvMJSHQRhKDtYpP",
        postHogProjectToken: "phc_Bq7CWoigoQLzLRTRQSCRHtpRKhkfig7itjLyNo8qCzC7"
    )
}
