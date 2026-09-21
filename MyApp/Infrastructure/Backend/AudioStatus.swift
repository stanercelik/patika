import Foundation

/// `path_steps.audio_status` sütunuyla birebir.
enum AudioStatus: String, Decodable, Sendable {
    case pending, processing, ready, failed
    /// Sunucu yeni bir değer eklerse istemci çökmez, sesi olmayan oturuma düşer.
    init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AudioStatus(rawValue: raw) ?? .failed
    }
}
