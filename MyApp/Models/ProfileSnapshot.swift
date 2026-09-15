import Foundation

/// `me-profile` Edge Function'ının cevabı — kullanıcının sunucudaki kendi verisi.
///
/// Şifreli alanlar (ad, ilk cümle, cevaplar) sunucuda sahibine çözülmüş gelir.
/// Metin alanları `String` olarak çözülür ve enum'a istemcide çevrilir: sunucu
/// yeni bir kategori ya da ton eklediğinde bütün sayfanın çözümü düşmesin.
struct ProfileSnapshot: Decodable, Equatable, Sendable {
    struct Profile: Decodable, Equatable, Sendable {
        let displayName: String?
        let locale: String?
        let voicePreference: String?
        let createdAt: Date
    }

    struct Origin: Decodable, Equatable, Sendable {
        let problemText: String?
        let avoidanceText: String?
        let createdAt: Date
    }

    struct Measurement: Decodable, Equatable, Sendable {
        let id: UUID
        let day: Int
        let variant: String
        let responses: [String: Double]
        /// Baseline'da nil; yol içi ölçümde ait olduğu yol.
        let pathId: UUID?
        let createdAt: Date
    }

    struct Path: Decodable, Equatable, Sendable {
        let id: UUID
        let kind: String
        let title: String
        let status: String
        let lengthDays: Int
        let completedSteps: Int
        let categories: [String]
        let timing: String?
        let tone: String?
        let sessionMinutes: Int?
        let createdAt: Date
        let completedAt: Date?
    }

    struct Answer: Decodable, Equatable, Sendable {
        let id: UUID
        let pathId: UUID
        let stepDay: Int
        let stepTitle: String
        let question: String
        let answer: String
        let createdAt: Date
    }

    let profile: Profile?
    let origin: Origin?
    let measurements: [Measurement]
    /// En yeni önce.
    let paths: [Path]
    let answers: [Answer]
}
