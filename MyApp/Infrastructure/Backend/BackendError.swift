import Foundation

enum BackendError: LocalizedError {
    case invalidResponse
    /// Sunucu bir cevap verdi ama kullanılabilir değildi. HTTP durumu ve varsa
    /// sunucunun kendi hata kodu taşınır: "bir şeyler ters gitti" ekranı
    /// kullanıcıya yeterli, geliştiriciye değil — 400 (payload) ile 401 (oturum)
    /// ile 503 (sağlayıcı) aynı hata olarak görünürse hata ayıklanamıyor.
    case unavailable(status: Int, code: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "invalid_backend_response"
        case .unavailable(let status, let code):
            "backend_unavailable(\(status)\(code.map { ", \($0)" } ?? ""))"
        }
    }
}

/// Sunucunun hata gövdesi — her Edge Function `{ "code": "..." }` döndürüyor.
struct BackendErrorPayload: Decodable {
    let code: String?
}
