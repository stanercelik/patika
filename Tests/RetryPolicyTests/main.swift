import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

// Geçici ağ hataları yeniden denenir; kalıcı istemci hataları denenmez.
expect(RetryPolicy.standard.isRetryable(URLError(.networkConnectionLost)), "-1005 must retry")
expect(RetryPolicy.standard.isRetryable(URLError(.timedOut)), "timeout must retry")
expect(!RetryPolicy.standard.isRetryable(URLError(.cancelled)), "cancellation must not retry")
expect(
    RetryPolicy.standard.isRetryable(BackendError.unavailable(status: 503, code: nil)),
    "5xx must retry"
)
expect(
    RetryPolicy.standard.isRetryable(BackendError.unavailable(status: 429, code: nil)),
    "429 must retry"
)
expect(
    !RetryPolicy.standard.isRetryable(BackendError.unavailable(status: 400, code: "bad_request")),
    "4xx must not retry"
)
expect(
    !RetryPolicy.standard.isRetryable(BackendError.unavailable(status: 401, code: nil)),
    "auth failure must not retry"
)

// Gecikme üstel ve sınırlı; jitter tam gecikmeyi aşmaz.
let first = RetryPolicy.standard.delay(forAttempt: 1, jitter: 0)
let second = RetryPolicy.standard.delay(forAttempt: 2, jitter: 0)
let far = RetryPolicy.standard.delay(forAttempt: 9, jitter: 1)
expect(second > first, "delay must grow")
expect(far <= RetryPolicy.standard.maximumDelay, "delay is capped")
expect(RetryPolicy.standard.delay(forAttempt: 1, jitter: 1) > first, "jitter adds spread")

// Aynı idempotency anahtarı her denemede korunur ve deneme sayısı sınırlıdır.
let policy = RetryPolicy(maximumAttempts: 3, baseDelay: 0, maximumDelay: 0)
let key = UUID()
actor Recorder {
    private(set) var keys: [UUID] = []
    func record(_ key: UUID) -> Int { keys.append(key); return keys.count }
}
let recorder = Recorder()

let value = try await policy.run(idempotencyKey: key) { attemptKey in
    let count = await recorder.record(attemptKey)
    if count < 3 { throw URLError(.networkConnectionLost) }
    return count
}
expect(value == 3, "must succeed on third attempt")
let keys = await recorder.keys
expect(keys.count == 3 && keys.allSatisfy { $0 == key }, "idempotency key must be stable")

// Kalıcı hata tek denemede biter.
let permanentRecorder = Recorder()
do {
    _ = try await policy.run(idempotencyKey: key) { attemptKey in
        _ = await permanentRecorder.record(attemptKey)
        throw BackendError.unavailable(status: 400, code: "bad_request")
    }
    fatalError("permanent error must propagate")
} catch {}
let permanentKeys = await permanentRecorder.keys
expect(permanentKeys.count == 1, "permanent error must not retry")

// Denemeler tükenirse son hata yükselir.
let exhaustedRecorder = Recorder()
do {
    _ = try await policy.run(idempotencyKey: key) { attemptKey in
        _ = await exhaustedRecorder.record(attemptKey)
        throw URLError(.timedOut)
    }
    fatalError("exhausted retries must throw")
} catch {}
let exhaustedKeys = await exhaustedRecorder.keys
expect(exhaustedKeys.count == 3, "attempts are bounded")

print("RetryPolicyTests passed")
