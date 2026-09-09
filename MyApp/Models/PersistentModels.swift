import Foundation
import SwiftData

// Veri modeli — PRD §13.4. Gizlilik mimarisi §13.5.
//
// NOT: SwiftUI'ın `Path` tipiyle çakışmaması için path modeli `ProgramPath` adını alır.

// MARK: - Kullanıcı

@Model
final class UserProfile {
    var localeIdentifier: String
    /// Hitap adı. Nil ise ürün isimsiz konuşur — bu bir eksiklik değil, seçenek.
    var displayName: String?
    /// Cinsiyet ve yaş aralığı ürünün davranışını **değiştirmez** (bkz. `Gender`);
    /// yalnızca kimin kullandığını bilmek için tutulur.
    var gender: Gender?
    var ageRange: AgeRange?
    /// Yaş sınırı 18+ (PRD §11.4). Bağlayıcı kontrol burada — `ageRange` istatistik.
    var birthYear: Int?
    var subscriptionStatus: SubscriptionStatus
    /// Kova C ücretsiz devam hakkı — ömür boyu 2 (PRD §7.9 suistimal sınırı).
    var freeContinuationCount: Int

    // Rıza bayrakları ayrı tutulur (GDPR Madde 9 özel kategori veri, PRD §14.1).
    // Önceden işaretli kutu yok — hepsi varsayılan false.
    var consentAnalytics: Bool
    var consentPersonalization: Bool
    var consentMarketing: Bool

    // Tercihler (PRD-Ek Onboarding §6, Ton eki §5.1)
    var tonePreference: TonePreference
    var reminderFrequency: ReminderFrequency
    /// Günlük hatırlatma saati. Sunucuya gitmez — cihazda
    /// `UNCalendarNotificationTrigger` ile planlanır (Ton eki §5.1).
    var reminderHour: Int
    var reminderMinute: Int
    var preferredSessionMinutes: Int
    /// Ton eki §5.7: art arda 5 bildirim açılmadıysa nudge motoru kendini kapatır.
    var consecutiveIgnoredNotifications: Int

    var createdAt: Date

    init(
        localeIdentifier: String = Locale.current.identifier,
        displayName: String? = nil,
        gender: Gender? = nil,
        ageRange: AgeRange? = nil,
        birthYear: Int? = nil,
        subscriptionStatus: SubscriptionStatus = .free,
        freeContinuationCount: Int = 0,
        consentAnalytics: Bool = false,
        consentPersonalization: Bool = false,
        consentMarketing: Bool = false,
        tonePreference: TonePreference = .calmAndShort,
        reminderFrequency: ReminderFrequency = .daily,
        reminderHour: Int = 22,
        reminderMinute: Int = 30,
        preferredSessionMinutes: Int = 10,
        consecutiveIgnoredNotifications: Int = 0,
        createdAt: Date = .now
    ) {
        self.localeIdentifier = localeIdentifier
        self.displayName = displayName
        self.gender = gender
        self.ageRange = ageRange
        self.birthYear = birthYear
        self.subscriptionStatus = subscriptionStatus
        self.freeContinuationCount = freeContinuationCount
        self.consentAnalytics = consentAnalytics
        self.consentPersonalization = consentPersonalization
        self.consentMarketing = consentMarketing
        self.tonePreference = tonePreference
        self.reminderFrequency = reminderFrequency
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.preferredSessionMinutes = preferredSessionMinutes
        self.consecutiveIgnoredNotifications = consecutiveIgnoredNotifications
        self.createdAt = createdAt
    }

    /// Ömür boyu 2 ücretsiz devam (PRD §7.9).
    var canClaimFreeContinuation: Bool { freeContinuationCount < 2 }
}

// MARK: - Problem girdisi

/// Kullanıcının kendi kelimeleri. **Özel kategori veri** (GDPR Madde 9).
///
/// PRD §13.5: ham metin şifreli ve ayrı tabloda saklanır; LLM'e giden bağlam
/// özettir, ham metin değil; bu metin **asla** analitik araçlara gönderilmez.
/// Aşağıdaki `rawText` yalnızca cihaz üzerindedir — sunucuya gönderim katmanı
/// eklendiğinde şifreleme orada uygulanmalıdır.
@Model
final class ProblemStatement {
    var rawText: String
    var categories: [ProblemCategory]
    /// B2 — "Bu ne kadar zamandır böyle?"
    var duration: ProblemDuration?
    /// B3 — "Genelde ne zaman ortaya çıkıyor?" E1'deki varsayılan saati belirler.
    var timing: ProblemTiming?
    /// B4 — kaçınma. Ölçümün en sağlam metriği ve path'in ikinci yarısının omurgası.
    var avoidanceText: String?
    /// B5 — daha önce ne denedi. C3'ün koşulu ve segmentasyon sinyali.
    var previousAttempts: [PreviousAttempt]
    /// B6 — onboarding anındaki ruh hali. Baseline **değil** (o D bölümünden
    /// gelir), yalnızca ilk oturumun tonunu ayarlayan ısınma sinyali.
    var initialMood: MoodLevel?

    /// PRD §11.1: sinyal varsa akış durur — path üretilmez, ölçüm yapılmaz,
    /// kayıt istenmez. Bu bayrak true iken hiçbir üretim tetiklenmemelidir.
    var crisisFlag: Bool
    var createdAt: Date

    init(
        rawText: String = "",
        categories: [ProblemCategory] = [],
        duration: ProblemDuration? = nil,
        timing: ProblemTiming? = nil,
        avoidanceText: String? = nil,
        previousAttempts: [PreviousAttempt] = [],
        initialMood: MoodLevel? = nil,
        crisisFlag: Bool = false,
        createdAt: Date = .now
    ) {
        self.rawText = rawText
        self.categories = categories
        self.duration = duration
        self.timing = timing
        self.avoidanceText = avoidanceText
        self.previousAttempts = previousAttempts
        self.initialMood = initialMood
        self.crisisFlag = crisisFlag
        self.createdAt = createdAt
    }

    /// Onboarding taslağından kalıcı kayda geçiş.
    ///
    /// Yalnızca akış tamamlandığında çağrılır (PRD-Ek Onboarding §9, H1) — yarıda
    /// kalan onboarding veritabanında yarım kayıt bırakmaz.
    ///
    /// Kriz bayrağı taşınır ve `true` iken hiçbir üretim tetiklenmez (PRD §11.1).
    convenience init(draft: OnboardingDraft) {
        self.init(
            rawText: draft.problemText,
            categories: draft.categories,
            duration: draft.duration,
            timing: draft.timing,
            avoidanceText: draft.avoidanceText,
            previousAttempts: draft.previousAttempts,
            initialMood: draft.currentMood,
            crisisFlag: draft.crisisDetected
        )
    }
}

// MARK: - Path

@Model
final class ProgramPath {
    var templateID: String
    var title: String
    var lengthDays: Int
    var status: PathStatus
    /// PRD §13.5: **özet**, ham metin değil. LLM bağlamı buradan beslenir.
    var personalizationContext: String
    var outcomeBucket: OutcomeBucket?
    /// Kova C sonrası verilen ücretsiz devam patikası mı?
    var isFreeContinuation: Bool
    var startedAt: Date
    var completedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \PathStep.path)
    var steps: [PathStep] = []

    @Relationship(deleteRule: .cascade, inverse: \Measurement.path)
    var measurements: [Measurement] = []

    init(
        templateID: String,
        title: String,
        lengthDays: Int = PathLength.threeWeeks.days,
        status: PathStatus = .active,
        personalizationContext: String = "",
        outcomeBucket: OutcomeBucket? = nil,
        isFreeContinuation: Bool = false,
        startedAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.templateID = templateID
        self.title = title
        self.lengthDays = lengthDays
        self.status = status
        self.personalizationContext = personalizationContext
        self.outcomeBucket = outcomeBucket
        self.isFreeContinuation = isFreeContinuation
        self.startedAt = startedAt
        self.completedAt = completedAt
    }

    var completedStepCount: Int {
        steps.count { $0.completedAt != nil }
    }

    /// İlerleme asla geri gitmez (PRD karar #5). Kaçırılan gün hiçbir şeyi sıfırlamaz.
    var progress: Double {
        guard lengthDays > 0 else { return 0 }
        return Double(completedStepCount) / Double(lengthDays)
    }

    /// Üst üste 3 olumsuz geri bildirim → sonraki adım sessizce kısaltılır (PRD §9.4).
    var needsAdaptation: Bool {
        let recent = steps
            .filter { $0.completedAt != nil }
            .sorted { $0.dayIndex > $1.dayIndex }
            .prefix(3)
            .compactMap(\.feedback)
        return recent.count == 3 && recent.allSatisfy(\.isDifficulty)
    }
}

@Model
final class PathStep {
    var dayIndex: Int
    var title: String
    var phase: PathPhase
    /// Blok kütüphanesinden seçilen bloklar. AI içerik icat etmez, blok seçer (PRD §9.1).
    var blockIDs: [String]
    var durationSeconds: Int
    var audioURLString: String?
    var completedAt: Date?
    var feedback: SessionFeedback?
    /// Oturum yarıda kalırsa pozisyon buraya yazılır (PRD §13.2.1) —
    /// dönüşte "kaldığın yerden devam et".
    var resumePositionSeconds: Double
    /// Mikro-sprint ile tamamlandıysa da **tamamlanmış** sayılır, yarım sayılmaz
    /// (Ton eki §5.4). Yoksa amacını kaybeder.
    var completedAsMicroSession: Bool

    var path: ProgramPath?

    init(
        dayIndex: Int,
        title: String,
        phase: PathPhase = .relief,
        blockIDs: [String] = [],
        durationSeconds: Int = 600,
        audioURLString: String? = nil,
        completedAt: Date? = nil,
        feedback: SessionFeedback? = nil,
        resumePositionSeconds: Double = 0,
        completedAsMicroSession: Bool = false
    ) {
        self.dayIndex = dayIndex
        self.title = title
        self.phase = phase
        self.blockIDs = blockIDs
        self.durationSeconds = durationSeconds
        self.audioURLString = audioURLString
        self.completedAt = completedAt
        self.feedback = feedback
        self.resumePositionSeconds = resumePositionSeconds
        self.completedAsMicroSession = completedAsMicroSession
    }

    var isCompleted: Bool { completedAt != nil }
}

// MARK: - Ölçüm

@Model
final class Measurement {
    var point: MeasurementPoint
    var variant: MeasurementVariant
    var takenAt: Date
    /// Madde kimliği → ham cevap.
    var rawResponses: [String: Double]
    /// `MeasurementLayer.rawValue` → 0…100 normalize skor.
    var dimensionScores: [String: Double]
    var compositeScore: Double

    var path: ProgramPath?

    init(
        point: MeasurementPoint,
        variant: MeasurementVariant? = nil,
        takenAt: Date = .now,
        rawResponses: [String: Double] = [:],
        dimensionScores: [String: Double] = [:],
        compositeScore: Double = 0
    ) {
        self.point = point
        self.variant = variant ?? point.variant
        self.takenAt = takenAt
        self.rawResponses = rawResponses
        self.dimensionScores = dimensionScores
        self.compositeScore = compositeScore
    }
}

// MARK: - Rozet / artifact

/// Path sonu rozeti ve kalıcı ses kaydı.
///
/// Artifact abonelik bitse bile kullanıcıda kalır (PRD §10). Kova C'de rozet verilir
/// ama `headlineChange` nil'dir — emek tanınır, sonuç uydurulmaz (Ton eki §6).
@Model
final class BadgeArtifact {
    var pathTitle: String
    var outcomeBucket: OutcomeBucket
    /// Örn. "Uykuya dalma süren %41 kısaldı". Kova C'de **nil**.
    var headlineChange: String?
    var audioURLString: String?
    var earnedAt: Date

    init(
        pathTitle: String,
        outcomeBucket: OutcomeBucket,
        headlineChange: String? = nil,
        audioURLString: String? = nil,
        earnedAt: Date = .now
    ) {
        self.pathTitle = pathTitle
        self.outcomeBucket = outcomeBucket
        self.headlineChange = outcomeBucket.badgeShowsNumbers ? headlineChange : nil
        self.audioURLString = audioURLString
        self.earnedAt = earnedAt
    }
}
