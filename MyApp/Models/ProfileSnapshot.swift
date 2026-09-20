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

    /// Kullanıcının kendi yazdığı defter notu.
    struct Note: Decodable, Equatable, Sendable {
        let id: UUID
        let body: String
        let createdAt: Date
        let updatedAt: Date
    }

    /// Rozet kimliği metin olarak çözülür: sunucu yeni bir rozet eklediğinde eski
    /// bir istemcinin bütün sayfası düşmez, tanımadığı rozet atlanır.
    struct Badge: Decodable, Equatable, Sendable {
        let id: String
        let earnedAt: Date
    }

    let profile: Profile?
    let origin: Origin?
    let measurements: [Measurement]
    /// En yeni önce.
    let paths: [Path]
    let answers: [Answer]
    let notes: [Note]
    let earnedBadges: [Badge]
    let completedStepDates: [Date]
    /// 1 saatlik imzalı adres; fotoğraf yoksa nil.
    let avatarURL: URL?
    /// Fotoğrafın sunucudaki son değişim zamanı. Eski sunucuda nil.
    let avatarUpdatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case profile, origin, measurements, paths, answers
        case notes, earnedBadges, completedStepDates, avatarURL, avatarUpdatedAt
    }

    /// Ben v2 alanları eksik olabilir: istemci, sunucudaki `me-profile` yeniden
    /// dağıtılmadan önce de çalışmalı. Eksik alan boş liste demektir.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profile = try container.decodeIfPresent(Profile.self, forKey: .profile)
        origin = try container.decodeIfPresent(Origin.self, forKey: .origin)
        measurements = try container.decode([Measurement].self, forKey: .measurements)
        paths = try container.decode([Path].self, forKey: .paths)
        answers = try container.decode([Answer].self, forKey: .answers)
        notes = try container.decodeIfPresent([Note].self, forKey: .notes) ?? []
        earnedBadges = try container.decodeIfPresent([Badge].self, forKey: .earnedBadges) ?? []
        completedStepDates = try container.decodeIfPresent([Date].self, forKey: .completedStepDates) ?? []
        avatarURL = try container.decodeIfPresent(URL.self, forKey: .avatarURL)
        avatarUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .avatarUpdatedAt)
    }
}
