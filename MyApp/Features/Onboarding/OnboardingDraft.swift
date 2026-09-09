import Foundation

/// Onboarding boyunca biriken cevaplar.
///
/// Bilerek bir `struct`: onboarding yarıda kalırsa kalıcı katmanda yarım kayıt
/// bırakmaz. `ProblemStatement` / `UserProfile` kayıtları ancak akış tamamlandığında
/// (PRD-Ek Onboarding §9, H1) bu taslaktan üretilir.
struct OnboardingDraft: Equatable, Sendable {

    // MARK: - Kimlik · Akışın girişi
    /// Kullanıcının hitap edilmek istediği ad. Boş bırakılabilir — "İsim vermek
    /// istemiyorum" gerçek bir seçenek ve akışın hiçbir yerini kapatmaz.
    var name: String?
    /// Cinsiyet ve yaş **ürünün davranışını değiştirmez** (bkz. `Gender`).
    var gender: Gender?
    var ageRange: AgeRange?

    // MARK: - A2 · Seni buraya ne getirdi?
    /// En fazla 2 kategori (PRD-Ek Onboarding §2.2). Headspace'te çoklu seçim
    /// trial dönüşümünü %10 artırmış — karar #6.
    var categories: [ProblemCategory] = []

    // MARK: - B · Problem keşfi
    /// B1 — kullanıcının kendi kelimeleri. Akışın en değerli verisi: F2'de geri
    /// yansıtılır, G1'de seslendirilir. Boş kalabilir (atlanabilir ekran) ama o
    /// zaman kişiselleştirme zayıflar ve jenerik şablon kullanılır (§10).
    var problemText: String = ""
    var duration: ProblemDuration?
    var timing: ProblemTiming?
    var avoidanceText: String?
    var previousAttempts: [PreviousAttempt] = []
    var currentMood: MoodLevel?

    // MARK: - D · Baseline ölçüm
    /// Madde kimliği → ham cevap. Anahtarlar `Measurement.rawResponses` ile
    /// aynıdır; akış tamamlandığında taslak olduğu gibi oraya taşınır.
    ///
    /// Normalize skor **burada tutulmaz**: onboarding boyunca hiçbir yerde skor
    /// gösterilmiyor (PRD §7.3) ve skoru üretmenin yeri ölçüm servisi.
    var measurementResponses: [String: Double] = [:]

    // MARK: - E · Tercihler
    /// E3'te **önceden seçili gelmez** (nil): PRD E2'de "10 dakika (önerilen)"
    /// diyor ama ton için bir öneri yok, ve olmayan bir öneriyi varsayılan
    /// seçimle ima etmek kullanıcıyı kendi tercihi olmayan bir sese iter.
    /// Kullanıcı cevaplamadan akış ilerlemiyor; profil kurulurken `resolvedTone`
    /// devreye giriyor.
    var tonePreference: TonePreference?
    /// E4 — rehber sesin kimliği. Önceden seçili **gelmez**: iki sesten birini
    /// varsayılan yapmak, kullanıcının dinlemeden geçmesine ve on dakika
    /// seçmediği bir sesle baş başa kalmasına yol açardı.
    var voicePreference: VoicePreference?
    var reminderHour: Int = 22
    var reminderMinute: Int = 30
    var sessionLength: SessionLength = .standard

    // MARK: - Güvenlik
    /// PRD §11.1: sinyal varsa akış durur — path üretilmez, ölçüm yapılmaz,
    /// kayıt istenmez.
    var crisisDetected: Bool = false

    /// E3 cevaplanmadan profil kurulmaz; yine de model non-optional bir ton
    /// bekliyor — sessizce en sakin kademeye düşüyoruz.
    var resolvedTonePreference: TonePreference { tonePreference ?? .calmAndShort }

    /// Seçim yapılmadıysa kadın sesi. Sıra tesadüf değil: önizlemede önce o
    /// çalıyor ve "hiçbirini seçmeden geçtim" durumu duyduğu ilk sesle eşleşiyor.
    var resolvedVoicePreference: VoicePreference { voicePreference ?? .feminine }

    /// Hitapta kullanılacak ad; yoksa nil ve metinler isimsiz sürümüne düşer.
    ///
    /// Ad **her ekranda değil, sayılı yerde** kullanılır (ürün sahibi kararı,
    /// 2026-09-08): her cümlede adı geçen bir arayüz samimi değil, ısrarcı olur —
    /// ve satış yazılımı gibi okunur. Kullanıldığı yerler `Copy.Onboarding`
    /// içinde ada göre iki sürümü olan metinlerdir.
    var displayName: String? {
        guard let name else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Birincil kategori, palet ve placeholder seçimini sürer.
    var primaryCategory: ProblemCategory { categories.first ?? .unnamed }

    static let maximumCategories = 2

    // MARK: - B bölümünden türeyen kararlar
    //
    // Bu kararlar burada hesaplanır, ekranlarda değil: C3'ün gösterilip
    // gösterilmeyeceğini bir görünümün bilmesi gerekmiyor.

    /// C3 ("Neden kütüphane değil, yol") koşullu ekranı gösterilecek mi?
    /// (PRD-Ek Onboarding §4.3)
    var showsLibraryComparison: Bool {
        previousAttempts.contains(where: \.showsLibraryComparison)
    }

    /// Terapi devam ediyorsa ton değişir ve ürün terapinin yerine geçme imasında
    /// bulunmaz (PRD §4).
    var requiresTherapyAwareTone: Bool {
        previousAttempts.contains(where: \.requiresTherapyAwareTone)
    }

    /// E1'de önerilecek hatırlatma saati B3'ten gelir; cevap yoksa varsayılan kalır.
    var suggestedReminderHour: Int {
        timing?.suggestedReminderHour ?? reminderHour
    }

    /// Hatırlatma saatinin okunabilir hâli — "22:30".
    ///
    /// `DateFormatter` kullanılmıyor: burada biçimlendirilecek bir tarih yok,
    /// iki tam sayı var. Saat 12'li/24'lü ayrımı için sistem biçimine geçmek
    /// gerekirse tek yer burası.
    var reminderTimeText: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    /// B1 atlandıysa path üretimi jenerik şablona düşer (§10 kaçış tablosu).
    var hasOwnWords: Bool {
        !problemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
