import Foundation

enum AppFailure: String, Sendable {
    case anonymousAuthentication
    case returningAuthentication
    case accountLink
    case pathGeneration
    /// Ses üretimi ya da indirmesi. Oturumu durdurmaz — sessiz sürüme düşülür —
    /// ama sessizce yutulmaz: TTS sağlayıcısı yapılandırılmadığı sürece bu
    /// sayacın dolu olması beklenen durum.
    case audioGeneration
    /// Adım tamamlanma kaydı sunucuya yazılamadı. Oturumu etkilemez; profildeki
    /// ilerleme eksik kalır.
    case stepCompletion
    case profileSync
}

protocol ErrorReporter: Sendable {
    func capture(_ failure: AppFailure) async
}

struct NoOpErrorReporter: ErrorReporter {
    func capture(_ failure: AppFailure) async {}
}

struct SentryHTTPReporter: ErrorReporter {
    private let envelopeURL: URL
    private let publicKey: String

    init?(dsn: String) {
        guard let components = URLComponents(string: dsn),
              let host = components.host,
              let key = components.user,
              let projectID = components.path.split(separator: "/").last,
              let url = URL(string: "https://\(host)/api/\(projectID)/envelope/")
        else { return nil }
        envelopeURL = url
        publicKey = key
    }

    func capture(_ failure: AppFailure) async {
        let eventID = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let header = ["event_id": eventID, "sent_at": ISO8601DateFormatter().string(from: .now)]
        let item = ["type": "event", "content_type": "application/json"]
        let event: [String: Any] = [
            "event_id": eventID,
            "level": "error",
            "platform": "cocoa",
            "message": ["formatted": failure.rawValue],
            "tags": ["privacy_mode": "strict", "app": "patika"],
        ]
        guard let headerData = try? JSONSerialization.data(withJSONObject: header),
              let itemData = try? JSONSerialization.data(withJSONObject: item),
              let eventData = try? JSONSerialization.data(withJSONObject: event)
        else { return }
        var envelope = Data()
        [headerData, itemData, eventData].forEach {
            envelope.append($0)
            envelope.append(0x0A)
        }
        var request = URLRequest(url: envelopeURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 8
        request.setValue("application/x-sentry-envelope", forHTTPHeaderField: "Content-Type")
        request.setValue("Sentry sentry_version=7,sentry_key=\(publicKey),sentry_client=patika-ios/1.0", forHTTPHeaderField: "X-Sentry-Auth")
        request.httpBody = envelope
        _ = try? await URLSession.shared.data(for: request)
    }
}
