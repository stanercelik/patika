import Foundation

/// G1'in ses beklemesi — saf ve ağdan bağımsız, ki yarış test edilebilsin.
///
/// ## Neden ayrı
///
/// F1 sesi "ateşle ve unut" başlatır; kullanıcı G1'e istek sunucuya ulaşmadan
/// gelirse adım hâlâ `pending` görünür. Önceki döngü `pending`i bitiş sayıyor ve
/// kalıcı olarak vazgeçiyordu: oturum sonsuza dek sessiz kalıyor, kullanıcı "ses
/// bozuk" diye okuyordu. Canlı duman testi (`live-smoke-audio.py`) sesi yoklamadan
/// **önce** istediği için bu yarışa hiç girmiyordu.
///
/// `pending` "henüz istenmedi" demek — bu yolda geçici bir durum. Bekleriz ve
/// hâlâ `pending` ise isteği kendimiz atarız. `failed` bitiştir: gerçek bir
/// hata da tam bir sessiz oturum verir.
enum AudioReadiness {
    enum Outcome: Equatable, Sendable {
        case ready
        /// Süre doldu, adım `failed`, sağlayıcı yok ya da görev iptal edildi.
        /// Hiçbiri hata değil: oturum sessiz sürüm olarak tamdır.
        case gaveUp
    }

    static let defaultTimeout: TimeInterval = 45
    static let defaultInterval: Duration = .seconds(2)

    /// - Parameters:
    ///   - status: adımın güncel `audio_status`u.
    ///   - requestIfNeeded: adım hâlâ `pending` iken **en fazla bir kez** çağrılır.
    ///     Çağıran, F1'in isteği uçuştayken ikinci bir iş açmamaktan sorumludur.
    ///   - isUnavailable: sağlayıcı sunucuda yok (503/422); beklemenin anlamı yok.
    static func wait(
        timeout: TimeInterval = defaultTimeout,
        interval: Duration = defaultInterval,
        now: () -> Date = { .now },
        sleep: (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
        status: () async throws -> AudioStatus,
        requestIfNeeded: () async -> Void,
        isUnavailable: () -> Bool
    ) async throws -> Outcome {
        let deadline = now().addingTimeInterval(timeout)
        var didRequest = false
        while now() < deadline, !Task.isCancelled {
            switch try await status() {
            case .ready:
                return .ready
            case .failed:
                return .gaveUp
            case .pending:
                if !didRequest {
                    didRequest = true
                    await requestIfNeeded()
                }
                if isUnavailable() { return .gaveUp }
            case .processing:
                break
            }
            try await sleep(interval)
        }
        return .gaveUp
    }
}
