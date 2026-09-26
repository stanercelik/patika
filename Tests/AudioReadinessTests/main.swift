import Foundation

// G1'in ses beklemesi. Asıl vaka: F1'in isteği sunucuya ulaşmadan G1'e gelen
// kullanıcı. Adım `pending` görünür ve eski döngü burada kalıcı olarak vazgeçiyordu.
//   bash scripts/run-swift-tests.sh AudioReadiness

setbuf(stdout, nil)
func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

/// Sahte saat: uyumak zamanı ilerletir, gerçek bekleme yok.
final class FakeClock: @unchecked Sendable {
    var current = Date(timeIntervalSince1970: 0)
    func now() -> Date { current }
    func sleep(_ duration: Duration) async throws {
        current = current.addingTimeInterval(Double(duration.components.seconds))
    }
}

/// Sıralı durumlar döndürür; dizi biterse sonuncuyu tekrarlar.
final class ScriptedStatus: @unchecked Sendable {
    private var script: [AudioStatus]
    private(set) var calls = 0
    init(_ script: [AudioStatus]) { self.script = script }
    func next() -> AudioStatus {
        calls += 1
        return script.count > 1 ? script.removeFirst() : script[0]
    }
}

func run(
    _ statuses: [AudioStatus],
    timeout: TimeInterval = 45,
    unavailableAfterRequest: Bool = false
) async throws -> (outcome: AudioReadiness.Outcome, requests: Int, polls: Int) {
    let clock = FakeClock()
    let script = ScriptedStatus(statuses)
    var requests = 0
    let outcome = try await AudioReadiness.wait(
        timeout: timeout,
        now: clock.now,
        sleep: clock.sleep,
        status: { script.next() },
        requestIfNeeded: { requests += 1 },
        isUnavailable: { unavailableAfterRequest && requests > 0 }
    )
    return (outcome, requests, script.calls)
}

// 1. Yarış: G1 adımı hâlâ pending görüyor, sonra istek ulaşıyor. Eski davranış
//    burada ilk yoklamada vazgeçip oturumu sonsuza dek sessiz bırakıyordu.
var r = try await run([.pending, .processing, .processing, .ready])
expect(r.outcome == .ready, "pending must be waited out, not treated as terminal")
expect(r.polls == 4, "must keep polling past pending (got \(r.polls))")
expect(r.requests == 1, "a pending step is requested exactly once")

// 2. İstek hiç ulaşmazsa G1 kendisi ister; iş açıldıktan sonra ses gelir.
r = try await run([.pending, .pending, .processing, .ready])
expect(r.outcome == .ready && r.requests == 1, "still pending after the first look is requested once, not on every poll")

// 3. F1 zaten istediyse adım processing görünür: G1 ikinci bir iş açmaz.
r = try await run([.processing, .processing, .ready])
expect(r.outcome == .ready && r.requests == 0, "a processing step must never be re-requested")

// 4. Zaten hazırsa hiç beklemez.
r = try await run([.ready])
expect(r.outcome == .ready && r.polls == 1 && r.requests == 0, "ready returns immediately")

// 5. failed bitiştir ve yeniden istenmez: gerçek hata da tam bir sessiz oturum verir.
r = try await run([.failed])
expect(r.outcome == .gaveUp && r.requests == 0, "failed is terminal and is not re-requested")
r = try await run([.processing, .failed])
expect(r.outcome == .gaveUp, "failed after processing is terminal")

// 6. Sağlayıcı sunucuda yok (503/422): beklemenin anlamı yok, hemen bırakılır.
r = try await run([.pending], unavailableAfterRequest: true)
expect(r.outcome == .gaveUp && r.requests == 1 && r.polls == 1, "unavailable provider ends the wait at once")

// 7. Hiç gelmezse süre dolar ve oturum sessiz sürer; sonsuza dek beklemez.
r = try await run([.pending], timeout: 45)
expect(r.outcome == .gaveUp, "deadline ends the wait")
expect(r.requests == 1, "a stuck pending step is requested once, not every 2 s")
expect(r.polls <= 24, "poll count is bounded by the deadline (got \(r.polls))")

// 8. İptal edilen görev sessizce bırakır.
let task = Task { () -> AudioReadiness.Outcome in
    let clock = FakeClock()
    return try await AudioReadiness.wait(
        now: clock.now, sleep: clock.sleep,
        status: { .processing }, requestIfNeeded: {}, isUnavailable: { false }
    )
}
task.cancel()
let cancelled = try await task.value
expect(cancelled == .gaveUp, "cancellation gives up quietly")

print("AudioReadinessTests passed")
