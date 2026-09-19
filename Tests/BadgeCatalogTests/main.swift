import Foundation

// Rozet kataloğu ve haftalık ritim — docs/profile-v2-plan.md.
// Test hedefi olmadığı için elle koşuluyor (bkz. CLAUDE.md, MeasurementScoring).

var failures = 0
func check(_ condition: Bool, _ message: String, line: Int = #line) {
    if !condition {
        failures += 1
        print("FAIL (\(line)): \(message)")
    }
}

var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
calendar.firstWeekday = 1  // Bilerek pazar: hafta yine pazartesi başlamalı.

func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
    calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
}

// 2026-09-16 çarşamba. Hafta: 14 Eylül pazartesi – 20 Eylül pazar.
let wednesday = date(2026, 9, 16)

// MARK: WeeklyRhythm

do {
    let rhythm = WeeklyRhythm.make(
        completedStepDates: [date(2026, 9, 14, hour: 8), date(2026, 9, 16, hour: 23), date(2026, 9, 13)],
        now: wednesday,
        calendar: calendar
    )
    check(rhythm.days.count == 7, "yedi gün")
    check(calendar.component(.weekday, from: rhythm.days[0].date) == 2, "hafta pazartesi başlar")
    check(rhythm.days.map(\.isCompleted) == [true, false, true, false, false, false, false],
          "yalnızca bu haftanın tamamlanan günleri işaretli (geçen pazar sayılmaz)")
    check(rhythm.days.filter(\.isToday).count == 1 && rhythm.days[2].isToday, "bugün çarşamba")
    check(rhythm.completedCount == 2, "iki gün")

    let empty = WeeklyRhythm.make(completedStepDates: [], now: wednesday, calendar: calendar)
    check(empty.completedCount == 0 && empty.days.count == 7, "boş hafta: noktalar var, hepsi boş")
}

do {
    // Aynı gün iki adım tek gün sayılır; pazar–pazartesi farklı haftalardır.
    let dates = [
        date(2026, 9, 14, hour: 9), date(2026, 9, 14, hour: 21),
        date(2026, 9, 15), date(2026, 9, 16),
        date(2026, 9, 20), // aynı hafta pazarı
        date(2026, 9, 21), // sonraki hafta pazartesisi
    ]
    check(WeeklyRhythm.bestDaysInAWeek(completedStepDates: dates, calendar: calendar) == 4,
          "en iyi hafta 4 gün (14,15,16,20); 21'i sonraki haftaya sayılır")
    check(WeeklyRhythm.bestDaysInAWeek(completedStepDates: [], calendar: calendar) == 0, "boş")
}

// MARK: BadgeCatalog

func step(_ day: Int, done: Bool) -> PathStepRecord {
    PathStepRecord(
        id: UUID(), day: day, title: "Adım \(day)", blockIds: [], slotCopy: [:],
        audioStatus: .ready, question: nil, completedAt: done ? wednesday : nil
    )
}

func path(length: Int, completedThrough: Int, isCompleted: Bool = false) -> ActivePath {
    ActivePath(
        id: UUID(), kind: .personalized, title: "Yol",
        steps: (1...length).map { step($0, done: $0 <= completedThrough) },
        isCompleted: isCompleted
    )
}

/// `ProfileRecord.empty` ProfileStore.swift'te; burada aynı alanlar elle kurulur.
func emptyRecord(startedAt: Date) -> ProfileRecord {
    ProfileRecord(
        displayName: nil, categories: [], mood: nil, timing: nil,
        reminder: ReminderSetting(isEnabled: false, hour: 22, minute: 30, isSuggested: false),
        sessionLength: .standard, tone: .calmAndShort, voice: .feminine,
        journal: [], measurements: [], pathArchive: [], privacy: PrivacySettings(),
        crisisSignalAt: nil, revealedMeasurementID: nil, anonymousCardHiddenUntil: nil,
        startedAt: startedAt
    )
}

let base = emptyRecord(startedAt: wednesday)

do {
    check(BadgeCatalog.earned(from: base, path: nil, calendar: calendar).isEmpty, "boş kayıt: rozet yok")

    let started = BadgeCatalog.earned(from: base, path: path(length: 21, completedThrough: 1), calendar: calendar)
    check(started.contains(.firstStep), "ilk adım")
    check(!started.contains(.phaseRelief), "rahatlama fazı 3 gün: 1 adım yetmez")

    // 21 günde faz sınırları: rahatlama 1–3, farkındalık 4–7, beceri 8–14, davranış 15–20, kapanış 21.
    let relief = BadgeCatalog.earned(from: base, path: path(length: 21, completedThrough: 3), calendar: calendar)
    check(relief.contains(.phaseRelief) && !relief.contains(.phaseAwareness), "rahatlama biter, farkındalık başlamadı")

    let almost = BadgeCatalog.earned(from: base, path: path(length: 21, completedThrough: 20), calendar: calendar)
    check(almost.contains(.phaseBehavior) && !almost.contains(.phaseClosing) && !almost.contains(.pathComplete),
          "20. adımda davranış fazı tamam, kapanış ve yol değil")

    let done = BadgeCatalog.earned(from: base, path: path(length: 21, completedThrough: 21, isCompleted: true), calendar: calendar)
    check(done.contains(.phaseClosing) && done.contains(.pathComplete), "yol biter")

    // 7 günlük yolda her faz en az bir gün alır.
    let week = BadgeCatalog.earned(from: base, path: path(length: 7, completedThrough: 7, isCompleted: true), calendar: calendar)
    check(Set([BadgeID.phaseRelief, .phaseAwareness, .phaseSkill, .phaseBehavior, .phaseClosing, .pathComplete]).isSubset(of: week),
          "7 günlük yolda beş faz rozeti de kazanılır")
}

do {
    // Arşivde tamamlanmış yol da yol rozetini verir (aktif yol artık yok).
    var record = base
    record.pathArchive = [PathArchiveEntry(
        id: UUID(), title: "Eski", stepCount: 21, walkedSteps: 21,
        startedAt: wednesday, endedAt: wednesday, status: .completed, bucket: .noProgress, headlineChange: nil
    )]
    check(BadgeCatalog.earned(from: record, path: nil, calendar: calendar).contains(.pathComplete),
          "Kova C dahil tamamlanan yol rozet verir — kutlama ayrı bir karar")
}

do {
    // Ölçüm: katılımdan; 14 günlük yolda 14. gün "son" olsa da measure-day14 sayılır.
    var record = base
    record.measurements = [
        MeasurementRecord(id: UUID(), point: .day7, stepDay: 7, takenAt: wednesday, responses: [:], pathID: nil),
        MeasurementRecord(id: UUID(), point: .final, stepDay: 14, takenAt: wednesday, responses: [:], pathID: nil),
    ]
    let earned = BadgeCatalog.earned(from: record, path: nil, calendar: calendar)
    check(earned.contains(.measureDay7) && earned.contains(.measureDay14), "iki ölçüm rozeti")
    check(!BadgeCatalog.earned(from: base, path: nil, calendar: calendar).contains(.measureDay7), "ölçüm yoksa rozet yok")
}

do {
    // Seri: bir takvim haftasında 3 / 5 / 7 farklı gün.
    var record = base
    record.completedStepDates = (14...18).map { date(2026, 9, $0) }
    var earned = BadgeCatalog.earned(from: record, path: nil, calendar: calendar)
    check(earned.contains(.week3) && earned.contains(.week5) && !earned.contains(.week7), "5 gün: week-3 ve week-5")
    record.completedStepDates += [date(2026, 9, 19), date(2026, 9, 20)]
    earned = BadgeCatalog.earned(from: record, path: nil, calendar: calendar)
    check(earned.contains(.week7), "7 gün: week-7")

    // Ardışık ama iki haftaya bölünen 5 gün seri sayılmaz (3 + 2).
    record.completedStepDates = [date(2026, 9, 18), date(2026, 9, 19), date(2026, 9, 20), date(2026, 9, 21), date(2026, 9, 22)]
    earned = BadgeCatalog.earned(from: record, path: nil, calendar: calendar)
    check(earned.contains(.week3) && !earned.contains(.week5), "hafta sınırında bölünen gün dizisi tek seri değil")
}

do {
    var record = base
    let note = JournalNote(id: UUID(), body: "Bugün iyiydi.", createdAt: wednesday, updatedAt: wednesday)
    record.notes = [note]
    var earned = BadgeCatalog.earned(from: record, path: nil, calendar: calendar)
    check(earned.contains(.noteFirst) && !earned.contains(.note10), "ilk not")
    record.notes = (0..<10).map { _ in JournalNote(id: UUID(), body: "x", createdAt: wednesday, updatedAt: wednesday) }
    earned = BadgeCatalog.earned(from: record, path: nil, calendar: calendar)
    check(earned.contains(.note10), "10 not")

    // Rozet geri alınmaz: notlar silinince hesaplanan küme küçülür ama birleşim küçülmez.
    record.notes = []
    let computed = BadgeCatalog.earned(from: record, path: nil, calendar: calendar)
    check(!computed.contains(.noteFirst), "not silinince koşul artık sağlanmıyor")
    let known = [EarnedBadge(badgeID: .noteFirst, earnedAt: wednesday)]
    let merged = BadgeCatalog.merged(known: known, computed: computed, at: wednesday)
    check(merged.contains { $0.badgeID == .noteFirst }, "kazanılmış rozet birleşimde kalır")
    check(BadgeCatalog.newlyEarned(computed: [.noteFirst], known: known).isEmpty, "bilinen rozet yeni sayılmaz")
    check(BadgeCatalog.newlyEarned(computed: [.week3, .firstStep], known: []) == [.firstStep, .week3],
          "yeni rozetler katalog sırasıyla")
    check(BadgeCatalog.next(after: known) == .firstStep, "sıradaki kilitli rozet katalogdaki ilk kazanılmamış")
}

do {
    // Kimlik ve görsel adları sunucu tablosu / varlık klasörüyle bire bir.
    let ids = BadgeID.allCases.map(\.rawValue)
    check(ids.count == 14 && Set(ids).count == 14, "14 benzersiz rozet")
    check(ids.allSatisfy { $0.range(of: #"^[a-z][a-z0-9-]{2,40}$"#, options: .regularExpression) != nil },
          "kimlikler sunucudaki check kısıtına uyar")
    check(BadgeID.week5.assetName == "badge-week-5", "varlık adı")
}

do {
    // Eski cihaz kaydı (Ben v2 alanları yok) okunabilir olmalı.
    // `ProfileCoding` ProfileStore.swift'te; oradaki ayarın aynısı (iso8601).
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let data = try encoder.encode(emptyRecord(startedAt: wednesday))
    var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    for key in ["notes", "earnedBadges", "completedStepDates", "avatarURL"] { json.removeValue(forKey: key) }
    let legacy = try JSONSerialization.data(withJSONObject: json)
    let decoded = try decoder.decode(ProfileRecord.self, from: legacy)
    check(decoded.notes.isEmpty && decoded.earnedBadges.isEmpty && decoded.completedStepDates.isEmpty && decoded.avatarURL == nil,
          "eski kayıt yeni alanlar olmadan çözülür")
    let roundTrip = try decoder.decode(ProfileRecord.self, from: data)
    check(roundTrip == emptyRecord(startedAt: wednesday), "gidiş-dönüş eşit")
}

print(failures == 0 ? "OK — all badge catalog checks passed" : "\(failures) failure(s)")
exit(failures == 0 ? 0 : 1)
