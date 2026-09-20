import Foundation

/// Cihazdaki kişisel kayıt — "Ben" sekmesinin kaynağı (`docs/profile-design.md`).
///
/// ## Neden bir kayıt var
///
/// Onboarding'in topladığı her şey (`OnboardingDraft`) path üretimine gönderilip
/// bellekte kalıyordu: uygulama kapanınca kullanıcının adı, ilk cümlesi, baseline
/// cevapları ve tercihleri cihazda hiçbir yerde durmuyordu. Profil sayfası
/// "buraya geldiğinden beri ne oldu" sorusunu cevaplayacaksa başlangıcın bir yerde
/// yazılı olması gerekiyor.
///
/// ## Neden SwiftData değil
///
/// `PersistentModels` yerel-öncelikli bir tasarımdan kaldı: path ve adımlar artık
/// sunucunun, istemci onları okuyor. Bu kayıt yalnızca **sunucuda olmayan** ya da
/// şifreli durup geri okunamayan şeyleri tutuyor. Tek bir Codable dosya — dışa
/// aktarması ve silmesi tek satır, şeması okunur.
struct ProfileRecord: Codable, Equatable, Sendable {
    var displayName: String?
    var categories: [ProblemCategory]
    var mood: MoodLevel?
    var timing: ProblemTiming?
    var reminder: ReminderSetting
    /// Üçü de yolun kurulduğu tercih; bilinmiyorsa nil ve satırı çizilmez
    /// (hazır patikada kişiselleştirme bağlamı yok).
    var sessionLength: SessionLength?
    var tone: TonePreference?
    var voice: VoicePreference?
    var journal: [JournalEntry]
    /// Kullanıcının kendi yazdığı notlar (Ben v2). Adım cevaplarından ayrı durur:
    /// notlar düzenlenebilir, cevaplar yalnızca silinir; ikisi de sunucuda şifreli.
    var notes: [JournalNote] = []
    /// Sunucuda kazanılmış rozetler. Rozet geri alınmaz: bu liste yalnızca büyür,
    /// bir notu ya da adımı silmek rozeti götürmez.
    var earnedBadges: [EarnedBadge] = []
    /// Tamamlanan adımların anı (haftalık ritim ve seri rozetleri için). Gün
    /// sınırı cihazın takviminden hesaplanır.
    var completedStepDates: [Date] = []
    /// Sunucudaki profil fotoğrafının son bilinen imzalı adresi (1 saatlik).
    /// Ekranda gösterilen yerel önbellektir (`AvatarStore`); bu adres yalnızca
    /// önbellek boşken indirmek için var.
    var avatarURL: URL?
    var measurements: [MeasurementRecord]
    /// Biten ya da bırakılan yollar. Path sonu servisi yazılana kadar boş kalır.
    var pathArchive: [PathArchiveEntry]
    var privacy: PrivacySettings
    /// Son kriz sinyalinin zamanı. Bir sonraki adım olağan biçimde tamamlanınca
    /// temizlenir: akış o zaman yeniden yürümeye başlamış demektir.
    var crisisSignalAt: Date?
    /// Değişim kartındaki hareket yalnızca yeni bir ölçüm **ilk kez**
    /// görüldüğünde oynar (profile-design §10). Tekrar eden animasyon anlamını
    /// yitirir.
    var revealedMeasurementID: UUID?
    var anonymousCardHiddenUntil: Date?
    var startedAt: Date

    var primaryCategory: ProblemCategory { categories.first ?? .unnamed }

    /// Anahtarlar açıkça yazılı: `init(from:)` yeni alanları `decodeIfPresent` ile
    /// okur. Cihazda duran eski `record.json` bu alanlar olmadan yazıldı; sentezlenen
    /// çözücü eksik anahtarda hata verip kaydın **tamamını** düşürürdü.
    enum CodingKeys: String, CodingKey {
        case displayName, categories, mood, timing, reminder, sessionLength, tone, voice
        case journal, notes, earnedBadges, completedStepDates, avatarURL
        case measurements, pathArchive, privacy, crisisSignalAt, revealedMeasurementID
        case anonymousCardHiddenUntil, startedAt
    }
}

extension ProfileRecord {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        categories = try container.decode([ProblemCategory].self, forKey: .categories)
        mood = try container.decodeIfPresent(MoodLevel.self, forKey: .mood)
        timing = try container.decodeIfPresent(ProblemTiming.self, forKey: .timing)
        reminder = try container.decode(ReminderSetting.self, forKey: .reminder)
        sessionLength = try container.decodeIfPresent(SessionLength.self, forKey: .sessionLength)
        tone = try container.decodeIfPresent(TonePreference.self, forKey: .tone)
        voice = try container.decodeIfPresent(VoicePreference.self, forKey: .voice)
        journal = try container.decode([JournalEntry].self, forKey: .journal)
        notes = try container.decodeIfPresent([JournalNote].self, forKey: .notes) ?? []
        earnedBadges = try container.decodeIfPresent([EarnedBadge].self, forKey: .earnedBadges) ?? []
        completedStepDates = try container.decodeIfPresent([Date].self, forKey: .completedStepDates) ?? []
        avatarURL = try container.decodeIfPresent(URL.self, forKey: .avatarURL)
        measurements = try container.decode([MeasurementRecord].self, forKey: .measurements)
        pathArchive = try container.decode([PathArchiveEntry].self, forKey: .pathArchive)
        privacy = try container.decode(PrivacySettings.self, forKey: .privacy)
        crisisSignalAt = try container.decodeIfPresent(Date.self, forKey: .crisisSignalAt)
        revealedMeasurementID = try container.decodeIfPresent(UUID.self, forKey: .revealedMeasurementID)
        anonymousCardHiddenUntil = try container.decodeIfPresent(Date.self, forKey: .anonymousCardHiddenUntil)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
    }
}

struct ReminderSetting: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var hour: Int
    var minute: Int
    /// Saat hâlâ onboarding cevabından mı geliyor? Kullanıcı saati değiştirdiği
    /// anda false olur ve kaynak satırı kalkar: artık onun kendi seçimi ve öyle
    /// görünmeli.
    var isSuggested: Bool

    var timeText: String { String(format: "%02d:%02d", hour, minute) }
}

/// Defterdeki tek bir cümle. **Düzenlenmez, yalnızca silinir** (profile-design
/// İ6): cümle yazıldığı an path'i şekillendirdi.
struct JournalEntry: Codable, Equatable, Sendable, Identifiable {
    enum Source: String, Codable, Sendable {
        /// B1 — kullanıcının kendi kelimeleriyle ilk cümlesi.
        case origin
        /// B4 — kaçındığı şey.
        case avoidance
        /// Oturum sonu kişisel soruya cevap (yalnızca `personalized` patika).
        case reflection
    }

    let id: UUID
    let source: Source
    let text: String
    let question: String?
    let stepDay: Int?
    let stepTitle: String?
    let pathID: UUID?
    let createdAt: Date
}

/// Kullanıcının defterine kendi yazdığı not. Adım cevabının aksine **düzenlenir**:
/// notu yazan kullanıcı, path'in bir sonraki adımı onun üstüne kurulmadığı için
/// cümlesini sonradan düzeltebilir.
struct JournalNote: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    var body: String
    let createdAt: Date
    var updatedAt: Date

    /// Bir notun en fazla uzunluğu. Sunucudaki `maxNoteLength` ile **aynı sayı**
    /// (`supabase/functions/_shared/notes.ts`); ikisi birlikte değişir.
    ///
    /// UTF-16 birimiyle ölçülür çünkü sunucu `String.length` ile sayıyor: karakter
    /// sayısıyla ölçülseydi emojili bir not istemcide geçer, sunucuda reddedilir
    /// ve kullanıcı "kaydedilemedi" döngüsüne girerdi.
    static let maxLength = 1_000

    /// Sınırı aşan metni sondan keser; bir karakteri (emoji, aksanlı harf) ortasından
    /// bölmez.
    static func clamped(_ text: String) -> String {
        guard text.utf16.count > maxLength else { return text }
        var result = String(text.prefix(maxLength))
        while result.utf16.count > maxLength { result.removeLast() }
        return result
    }
}

/// Bir ölçüm noktasının **ham** cevapları. Skor saklanmaz; her gösterimde
/// `MeasurementScoring` ile yeniden hesaplanır — skorlama değişirse eski kayıt
/// yanlış bir sayıyla donmuş kalmasın.
struct MeasurementRecord: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let point: MeasurementPoint
    /// Ölçümün yapıldığı adım. Baseline onboarding'de alındığı için 0.
    let stepDay: Int
    let takenAt: Date
    let responses: [String: Double]
    let pathID: UUID?
}

struct PathArchiveEntry: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let title: String
    let stepCount: Int
    let walkedSteps: Int
    let startedAt: Date
    let endedAt: Date
    let status: PathStatus
    let bucket: OutcomeBucket?
    /// `BadgeArtifact.headlineChange` ile aynı kural: Kova C'de nil.
    let headlineChange: String?
}

/// Hangi adımdan sonra hangi ölçüm yapılır (PRD §8.6).
///
/// Baseline onboarding'de (gün 0). Sonrakiler yolun uzunluğuna bağlı: son adımdan
/// sonra son ölçüm; 7. ve 14. adımdan sonra ara ölçüm — o adım yolun sonu değilse.
/// Sunucudaki `measurement_day` gün numarasıdır (0, 7, 14, 21, 28).
enum MeasurementSchedule {
    static func point(afterStep day: Int, pathLength: Int) -> MeasurementPoint? {
        if day == pathLength { return .final }
        if day == 7 { return .day7 }
        if day == 14 { return .day14 }
        return nil
    }

    static func point(forServerDay day: Int, pathLength: Int?) -> MeasurementPoint? {
        if day == 0 { return .baseline }
        if let pathLength, day == pathLength { return .final }
        if day == 7 { return .day7 }
        if day == 14 { return .day14 }
        return nil
    }
}

struct PrivacySettings: Codable, Equatable, Sendable {
    var appLockEnabled = false
    /// Defter "Ben" sekmesinde örtülü durur, dokununca 30 saniye açılır.
    var hidesJournal = false
}
