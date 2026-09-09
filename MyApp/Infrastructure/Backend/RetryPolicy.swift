import Foundation

/// Ağ çağrılarının sınırlı, üstel ve dağıtılmış yeniden denemesi.
///
/// ## Neden ayrı bir tip
///
/// -1005 (`networkConnectionLost`) mobilde sıradan bir olay: hücresel el
/// değiştirme, kilit ekranı, Wi-Fi geçişi. Tek denemede pes eden bir istemci
/// bunu ürün hatası gibi gösteriyordu. Yeniden deneme çağrının kendisinde
/// yazılırsa her çağrı biraz farklı davranır; burada tek yerde duruyor ve
/// saf olduğu için testten geçebiliyor.
///
/// ## Idempotency anahtarı denemeler boyunca **aynı** kalır
///
/// Yeni anahtar üretmek ikinci bir path ya da ikinci bir TTS faturası demek.
/// Sunucu aynı anahtarı gördüğünde ilk sonucu döndürüyor; yeniden deneme bu
/// yüzden güvenli.
///
/// ## Kalıcı hata denenmez
///
/// 4xx (401 dâhil) kullanıcı ya da istemci tarafında bir sorun; tekrar sormak
/// aynı cevabı getirir. 429 ve 5xx sunucunun "şimdi değil"i, o yüzden denenir.
struct RetryPolicy: Sendable {
    let maximumAttempts: Int
    let baseDelay: TimeInterval
    let maximumDelay: TimeInterval

    static let standard = RetryPolicy(maximumAttempts: 3, baseDelay: 0.6, maximumDelay: 4)

    func isRetryable(_ error: any Error) -> Bool {
        if let backend = error as? BackendError {
            switch backend {
            case .invalidResponse:
                return false
            case .unavailable(let status, _):
                return status == 429 || status >= 500 || status <= 0
            }
        }
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .networkConnectionLost, .timedOut, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed,
             .secureConnectionFailed, .badServerResponse, .resourceUnavailable:
            return true
        default:
            return false
        }
    }

    /// `jitter` 0…1 arası bir katsayı; testte sabitlenebilsin diye dışarıdan
    /// veriliyor.
    func delay(forAttempt attempt: Int, jitter: Double) -> TimeInterval {
        guard attempt > 0, baseDelay > 0 else { return 0 }
        let exponential = baseDelay * pow(2, Double(attempt - 1))
        let spread = exponential * 0.25 * min(max(jitter, 0), 1)
        return min(exponential + spread, maximumDelay)
    }

    /// Operasyonu en fazla `maximumAttempts` kez, **aynı** anahtarla çalıştırır.
    func run<Value: Sendable>(
        idempotencyKey: UUID,
        operation: @Sendable (UUID) async throws -> Value
    ) async throws -> Value {
        var lastError: (any Error)?
        for attempt in 1...max(1, maximumAttempts) {
            do {
                return try await operation(idempotencyKey)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                guard isRetryable(error), attempt < maximumAttempts else { throw error }
                lastError = error
                let pause = delay(forAttempt: attempt, jitter: Double.random(in: 0...1))
                if pause > 0 { try await Task.sleep(for: .seconds(pause)) }
            }
        }
        throw lastError ?? BackendError.invalidResponse
    }
}
