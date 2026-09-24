import Foundation
import Observation

/// Onboarding akışının adımları — PRD-Ek Onboarding §10 diyagramı.
///
/// Toplam 34 ekran (PRD'nin 31'i + sonradan eklenen 3 ekranlık kimlik bloğu).
/// Şu an **kimlik bloğu ve A, B, C, D, E bölümleri** uygulandı.
///
/// `CaseIterable` **yok**: D bölümü sekiz özdeş yapıda soru ekranı ve bunları
/// sekiz ayrı case olarak yazmak, aynı `switch`i her yerde sekiz kez uzatırdı.
/// İlişkili değerli tek bir case hem akışı hem ekranı tek satırda anlatıyor.
enum OnboardingStep: Equatable {
    // A — Kanca (2 ekran)
    case a1Welcome
    // Kimlik — PRD'de yok, sonradan eklendi (ürün sahibi kararı, 2026-09-08).
    // A1'in **sonrasında**: kanca ekranı markanın ilk izlenimi, önüne form
    // koyulmaz. A2'nin **öncesinde**: hitap adı akışın geri kalanında kullanılıyor.
    // 2026-09-22: her soru kendi sayfasında — üç ayrı ekran (bkz. karar günlüğü).
    case identityName
    case identityGender
    case identityAge
    case a2Categories
    // B — Problem keşfi (6 ekran)
    case b1ProblemText
    case b2Duration
    case b3Timing
    case b4Avoidance
    case b5PreviousAttempts
    case b6CurrentMood
    // C — Yansıtma ve ikna (4 ekran; C3 koşullu)
    case c1Mirroring
    case c2NotAlone
    case c3PathNotLibrary
    case c4HonestExpectation
    /// Taahhüt anı (2026-09-22): F2 sonrasında imza/işaret ve basılı tutma.
    case commitment
    // D — Baseline ölçüm (9 ekran: giriş + 8 soru). Atlanamayan tek bölüm.
    case d0MeasurementIntro
    /// D1–D8. `index` 1 tabanlı ve `OnboardingDraft.measurementItems`
    /// dizisindeki sırayı gösterir.
    case dMeasurement(Int)
    // E — Tercihler (2 ekran). İkisinin de ürün davranışında görünür karşılığı var.
    // E2 (adım uzunluğu) ve E4 (rehber sesi) 2026-09-21'de kaldırıldı: uzunluğu ürün
    // sahibi ayarlıyor (varsayılan 10 dk), MVP tek ses (kadın). E3 (ton) 2026-09-22'de
    // kaldırıldı — E bölümü artık yalnızca E1.
    case e1Reminder
    // F — Üretim ve teslim. PRD'de 4 ekran; F2 ile F3 **birleştirildi**
    // (ürün sahibi kararı, 2026-09-09), yani 3 ekran.
    case f1Generation
    case f2Roadmap
    // G — İlk değer / aha momenti (2 ekran, PRD-Ek Onboarding §8)
    case g1FirstSession
    case g2SessionComplete
    /// F4 — fiyat şeffaflığı, G2'den sonra (2026-09-21). Ödeme istemez, yalnızca söyler.
    case price
    // H — bildirim ön hazırlığı ve hesap bağlama.
    case h2Priming
    case h1Account
    // Kriz sinyali: akış buraya düşer ve devam etmez.
    case crisis

    /// 0…1 ilerleme. Nil ise iz solar.
    ///
    /// İlerleme **bölüm içi**dir, akışın tamamı üzerinden değil: 34 ekranlık bir
    /// akışta baştan tam ölçek göstermek caydırıcıdır. Soru bölümü = kimlik (3) +
    /// A2 + B1–B6, yani 10 ekran. B6'da iz dolar; C bölümünde soru sorulmadığı
    /// için iz solar, D ve E bölümleri kendi ölçekleriyle yeniden başlar.
    var progress: Double? {
        switch self {
        // Soru bölümü kimlik ekranlarıyla birlikte 10 ekran: iz onların da
        // sorulduğunu gösteriyor, yoksa üç ekran boyunca hiç ilerlemiyor gibi
        // görünüyordu.
        // Soru bölümü 10 ekran: kimlik (3, ayrı sayfa) + A2 + B1–B6.
        case .identityName: 1.0 / 10.0
        case .identityGender: 2.0 / 10.0
        case .identityAge: 3.0 / 10.0
        case .a2Categories: 4.0 / 10.0
        case .b1ProblemText: 5.0 / 10.0
        case .b2Duration: 6.0 / 10.0
        case .b3Timing: 7.0 / 10.0
        case .b4Avoidance: 8.0 / 10.0
        case .b5PreviousAttempts: 9.0 / 10.0
        case .b6CurrentMood: 1.0
        // D kendi ölçeğiyle yeniden başlar: soru bölümünün izi B6'da dolmuştu,
        // ölçüm ayrı bir bölüm ve kendi uzunluğu var. Giriş ekranında (D0) soru
        // sorulmadığı için iz solar — tıpkı C bölümünde olduğu gibi.
        case .dMeasurement(let index):
            Double(index) / Double(MeasurementPoint.baseline.questionCount)
        // E artık tek ekran (E3 kaldırıldı); dolu iz onaylandığını gösterir.
        case .e1Reminder: 1.0
        case .a1Welcome, .c1Mirroring, .c2NotAlone, .c3PathNotLibrary,
             .c4HonestExpectation, .commitment, .d0MeasurementIntro, .f1Generation, .f2Roadmap,
             .g1FirstSession, .g2SessionComplete, .price, .h2Priming, .h1Account, .crisis: nil
        }
    }

    /// Kriz ekranından geri dönülemez (PRD §11.1) ve A1'in öncesi yok.
    ///
    /// F bölümünde de geri yok: F1'de üretim çalışıyor, F2'de path üretilmiş
    /// durumda. Geri dönüp E3'ün tonunu değiştirmek, elde duran path'i sessizce
    /// yanlış hâle getirirdi — ya yeniden üretmek ya da cevabı yok saymak
    /// gerekirdi, ikisi de kullanıcıya açıklanamaz.
    var canGoBack: Bool {
        switch self {
        // Fiyat ekranında geri yok: G2'ye dönmek, bitmiş oturumun özetini yeniden açardı.
        case .a1Welcome, .f1Generation, .f2Roadmap, .g1FirstSession, .g2SessionComplete,
             .price, .h1Account, .crisis: false
        default: true
        }
    }

    /// Adımın malzemesi (docs/onboarding-redesign.md, Bölüm 2.2/Faz 2). Kabuk yalnızca okur.
    var surfaceStyle: OnboardingSurfaceStyle {
        switch self {
        // A2 ve B6 kartsız kalır: cevabın karşılığı sahnenin kendisi (kategori sahnesi,
        // ruh hâline göre perde) ve önüne kart koymak neden-sonucu koparırdı.
        case .identityName, .identityGender, .identityAge, .b1ProblemText, .b2Duration, .b3Timing,
             .b4Avoidance, .b5PreviousAttempts, .c1Mirroring, .c2NotAlone, .c3PathNotLibrary,
             .c4HonestExpectation, .commitment, .d0MeasurementIntro, .price,
             .h2Priming, .h1Account: .paper
        default: .plain
        }
    }

    /// Ekran grubuna göre nefes genliği (Görsel Sistem eki §4).
    ///
    /// Ölçüm bölümünde genlik kısılır: bu ekranlarda kullanıcıdan kendi hâlini
    /// tartması isteniyor ve arka planda hareket eden bir şey dikkati bölüyor.
    /// Kriz ekranında hareket tamamen durur (PRD §11.1).
    var breathAmplitude: Double {
        switch self {
        case .crisis: BreathAmplitude.crisis
        case .d0MeasurementIntro, .dMeasurement: BreathAmplitude.measurement
        // F1 bir bekleme ekranı: nefes genliği yükselir, ekran "çalışıyor" gibi
        // değil "soluk alıyor" gibi dursun (Görsel Sistem eki §4).
        case .f1Generation: BreathAmplitude.generation
        // Oturum: kullanıcı gerçekten nefesini buna uyduruyor (Görsel Sistem §4).
        case .g1FirstSession: BreathAmplitude.session
        default: BreathAmplitude.ambient
        }
    }
}

extension OnboardingStep {
    /// Crisis is deliberately absent from analytics.
    var analyticsStep: AnalyticsOnboardingStep? {
        switch self {
        case .a1Welcome: .a1
        case .identityName: .identityName
        case .identityGender: .identityGender
        case .identityAge: .identityAge
        case .a2Categories: .a2
        case .b1ProblemText: .b1
        case .b2Duration: .b2
        case .b3Timing: .b3
        case .b4Avoidance: .b4
        case .b5PreviousAttempts: .b5
        case .b6CurrentMood: .b6
        case .c1Mirroring: .c1
        case .c2NotAlone: .c2
        case .c3PathNotLibrary: .c3
        case .c4HonestExpectation: .c4
        case .d0MeasurementIntro: .d0
        case .dMeasurement(let index):
            [AnalyticsOnboardingStep.d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8]
                .indices.contains(index - 1)
                ? [AnalyticsOnboardingStep.d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8][index - 1]
                : nil
        case .e1Reminder: .e1
        case .h2Priming: .h2
        case .f1Generation: .f1
        case .f2Roadmap: .f2
        case .commitment: .commitment
        case .g1FirstSession: .g1
        case .g2SessionComplete: .g2
        case .price: .price
        case .h1Account: .h1
        case .crisis: nil
        }
    }
}

/// Onboarding akışının sahibi. Adım yönlendirmesi, taslak veri ve palet
/// senkronizasyonu buradadır; görünümler karar vermez.
@Observable
@MainActor
final class OnboardingFlowViewModel {
    private(set) var step: OnboardingStep = .a1Welcome
    private(set) var draft = OnboardingDraft()

    /// Oturum ekranı da aynı istemcileri kullanıyor (ses üretimi, imzalı adres);
    /// ikinci bir servis kabı kurmak yerine akışınki paylaşılıyor.
    let services: AppServices
    /// Onboarding bittiğinde çağrılır.
    private let onFinished: () -> Void

    private var history: [OnboardingStep] = []
    private var analyticsSteps = AnalyticsStepTracker()
    private var didTrackPathGenerationStart = false
    private var didTrackProblemSubmission = false
    private var didTrackAccountChoice = false
    /// F1'de başlatılan ses üretimi. Görev tutuluyor ki ekran değişince iptal
    /// edilebilsin ve iki kez başlatılmasın.
    private var audioPreparation: Task<Void, Never>?
    /// F1 ve G1 aynı ses isteği için **aynı** anahtarı kullanır: sunucu idempotency'yi
    /// (kullanıcı, anahtar) çiftine göre tutuyor, yeni bir anahtar ikinci bir iş ve
    /// ikinci bir TTS faturası demek.
    private let firstStepAudioKey = UUID()
    /// Bir ses isteği sunucuya gerçekten gönderildi mi (yanıt ne olursa olsun)?
    private var didRequestFirstStepAudio = false
    /// Sağlayıcı sunucuda yok ya da seslendirilecek metin yok (503/422): tekrar
    /// denemek anlamsız, G1 sessiz sürüme düşer.
    private(set) var isFirstStepAudioUnavailable = false
    /// 1. adımın sunucudaki satır kimliği — G1 sesi bununla arıyor, G2 de
    /// tamamlanmayı bununla yazıyor.
    private(set) var firstStepId: UUID?
    /// G1 sonuna kadar dinlendi mi? G2'nin metnini bu belirliyor.
    private(set) var didCompleteFirstSession = false
    /// Oturumdaki ses zarfı. Yalnızca dekoratif nefes küresi bunu okur; analitiğe ve
    /// kalıcı depoya gitmez.
    private(set) var sessionVoiceEnergy: Double = 0
    /// A2'de henüz commit edilmemiş canlı seçim — `currentScene` bunu taslaktan önce okur.
    private var previewedCategories: [ProblemCategory]?
    /// B6'da henüz commit edilmemiş canlı seçim — `currentSceneDimming` bunu okur.
    private var previewedMood: MoodLevel?
    private var previewedReminderHour: Int?
    private(set) var showsDayOneTransition = false
    /// The wheel value survives Back only in memory; it is never persisted or uploaded.
    private(set) var selectedExactAge: Int?

    init(
        services: AppServices,
        onFinished: @escaping () -> Void = {}
    ) {
        self.services = services
        self.onFinished = onFinished
        markStepViewed(.a1Welcome)
    }

    // MARK: - Navigasyon

    func advance(to next: OnboardingStep) {
        markStepCompleted(step)
        history.append(step)
        step = next
        markStepViewed(next)
    }

    private func markStepViewed(_ step: OnboardingStep) {
        guard let id = step.analyticsStep, analyticsSteps.firstView(of: id) else { return }
        services.observability.capture(.onboardingStepViewed(step: id))
    }

    private func markStepCompleted(_ step: OnboardingStep) {
        guard let id = step.analyticsStep, analyticsSteps.firstCompletion(of: id) else { return }
        services.observability.capture(.onboardingStepCompleted(step: id))
    }

    private func markProblemSubmission(wasWritten: Bool) {
        guard !didTrackProblemSubmission else { return }
        didTrackProblemSubmission = true
        services.observability.capture(.problemTextSubmitted(wasWritten: wasWritten))
    }

    func goBack() {
        guard let previous = history.popLast() else { return }
        previewedCategories = nil
        previewedMood = nil
        previewedReminderHour = nil
        step = previous
    }

    // MARK: - Sahne (docs/onboarding-redesign.md, Faz 2)
    //
    // Gradyan kalktı (2026-09-22): arka plan artık bölüm başına tam ekran bir guaj
    // sahnesi. A2'den B6'ya kadar sahne **kategoriye göre** değişir — eskiden bu işi
    // canlı palet yapıyordu; kategori bilinmeden önce ve C'den sonra bölüm sahnesi
    // kullanılır. Sahne enum'da değil burada hesaplanıyor çünkü taslağa (ve A2/B6'nın
    // henüz commit edilmemiş canlı seçimine) bakması gerekiyor.

    /// Adımın sahnesi. Kriz ekranında hiç sahne yok (`nil`); kalanında görsel eksikse
    /// `OnboardingSceneLayer` düz zemine düşer, hiçbir ekran kırılmaz.
    var currentScene: OnboardingArtwork? {
        switch step {
        case .a1Welcome: .threshold
        case .identityName, .identityGender, .identityAge: .gathering
        case .b6CurrentMood:
            OnboardingArtwork.mood(previewedMood ?? draft.currentMood)
        case .a2Categories, .b1ProblemText, .b2Duration, .b3Timing, .b4Avoidance, .b5PreviousAttempts:
            (previewedCategories ?? draft.categories).last.map(OnboardingArtwork.category)
                ?? .categoryUnnamed
        case .c1Mirroring, .c2NotAlone, .c3PathNotLibrary, .c4HonestExpectation:
            .reflection
        case .d0MeasurementIntro, .dMeasurement:
            .measure
        case .e1Reminder:
            OnboardingArtwork.time(hour: previewedReminderHour ?? suggestedReminderHour)
        case .h2Priming, .f1Generation, .f2Roadmap, .commitment:
            .prepare
        case .g1FirstSession:
            .session
        case .g2SessionComplete, .price, .h1Account:
            .settle
        case .crisis:
            nil
        }
    }

    /// Sahne perdesi. Yalnızca B6'da ruh hâline göre değişir — ağır kademede daha koyu,
    /// sakin kademede daha açık; ekranı ayrıca kısıp yavaşlatmak "neşelen" demenin görsel
    /// karşılığı olurdu, o yüzden yalnızca perde değişir (Görsel Sistem eki §3.4'ün
    /// gradyansız karşılığı). Kalan her yerde sabit.
    var currentSceneDimming: Double {
        let base = 0.34
        return base
    }

    // MARK: - A1

    /// A1'de "Başlayalım" da "atla" da aynı yere gider — A2 atlanamaz, çünkü
    /// path tipi oradan belirlenir (PRD-Ek Onboarding §10 kaçış tablosu).
    func finishWelcome() async -> Bool {
        guard await services.auth.ensureAnonymousSession() else {
            services.observability.capture(.anonymousAuthentication)
            return false
        }
        advance(to: .identityName)
        return true
    }

    // MARK: - Kimlik
    //
    // Üç ayrı ekran (2026-09-22, docs/onboarding-redesign.md, Faz 4): her soru kendi
    // sayfasında. Cinsiyet ve yaş ürünün hiçbir davranışını değiştirmiyor, ama her ikisi
    // de tek başına bir sayfa — "her soru kendi sayfasında" kuralının istisnası yok.

    /// Ad da serbest metin — "kullanıcının yazdığı **her** serbest metin
    /// sınıflandırıcıdan geçer" kuralının istisnası yok. Ad alanına kriz sinyali
    /// yazılması beklenmiyor ama kuralın istisnası olduğu an kural değildir.
    ///
    /// Ad boşsa isimsiz devam eder: isimsiz sürüm eksik bir sürüm değil.
    func commitName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if CrisisClassifier.evaluate(trimmed).hasSignal {
            flagCrisis()
            return
        }

        draft.name = trimmed.isEmpty ? nil : trimmed
        advance(to: .identityGender)
    }

    /// "İsim vermek istemiyorum". Akışın hiçbir yeri kapanmaz.
    func skipName() {
        draft.name = nil
        advance(to: .identityGender)
    }

    /// Cinsiyet cevapsız kalabilir ve `undisclosed` yazılır — karşılığı olmayan bir
    /// soruyu (`identityStatsNote`) varmış gibi sunmuyoruz.
    func commitGender(_ gender: Gender) {
        draft.gender = gender
        advance(to: .identityAge)
    }

    func previewAge(_ age: Int?) {
        selectedExactAge = age
    }

    func commitAge(_ age: Int) {
        selectedExactAge = age
        draft.ageRange = AgeSelection.range(for: age)
        advance(to: .a2Categories)
    }

    func commitAgeUndisclosed() {
        selectedExactAge = nil
        draft.ageRange = .undisclosed
        advance(to: .a2Categories)
    }

    // MARK: - A2

    func commitCategories(_ categories: [ProblemCategory]) {
        draft.categories = categories
        previewedCategories = nil
        advance(to: .b1ProblemText)
    }

    /// Kategori seçimi değiştikçe arka plan anında tepki verir — henüz commit
    /// edilmemiş seçim `currentScene`i besliyor.
    func previewCategories(_ categories: [ProblemCategory]) {
        previewedCategories = categories
    }

    // MARK: - B1 · Kendi cümlelerinle

    /// **Kriz kontrolü burada** (PRD §11.1). Metin gönderildiği anda taranır;
    /// sinyal varsa akış durur ve bir daha ilerlemez.
    ///
    /// Sıralama kritik: önce tarama, sonra taslağa yazma. Sinyalli metin taslakta
    /// birikip sonraki adımlara taşınmamalı.
    func commitProblemText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if CrisisClassifier.evaluate(trimmed).hasSignal {
            flagCrisis()
            return
        }

        draft.problemText = trimmed
        markProblemSubmission(wasWritten: !trimmed.isEmpty)
        advance(to: .b2Duration)
    }

    /// "Yazmak istemiyorum". Kişiselleştirme zayıflar, akış durmaz (§10).
    func skipProblemText() {
        draft.problemText = ""
        markProblemSubmission(wasWritten: false)
        advance(to: .b2Duration)
    }

    // MARK: - B2 · Süre

    func commitDuration(_ duration: ProblemDuration) {
        draft.duration = duration
        advance(to: .b3Timing)
    }

    // MARK: - B3 · Zamanlama

    func previewReminder(hour: Int) {
        previewedReminderHour = hour
    }

    func beginDayOneTransition() {
        showsDayOneTransition = true
    }

    func finishDayOneTransition() {
        showsDayOneTransition = false
        startFirstSession()
    }

    /// Cevap E1'deki varsayılan hatırlatma saatini belirler — sorduğumuz her
    /// şeyin görünür bir karşılığı olmalı (PRD-Ek Onboarding §3.3).
    func commitTiming(_ timing: ProblemTiming) {
        draft.timing = timing
        draft.reminderHour = timing.suggestedReminderHour
        advance(to: .b4Avoidance)
    }

    // MARK: - B4 · Kaçınma

    /// Kaçınma metni de serbest girdi — o yüzden aynı taramadan geçer.
    /// "Kullanıcının yazdığı **her** serbest metin" kuralı istisnasızdır.
    func commitAvoidance(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if CrisisClassifier.evaluate(trimmed).hasSignal {
            flagCrisis()
            return
        }

        draft.avoidanceText = trimmed.isEmpty ? nil : trimmed
        advance(to: .b5PreviousAttempts)
    }

    func skipAvoidance() {
        draft.avoidanceText = nil
        advance(to: .b5PreviousAttempts)
    }

    // MARK: - B5 · Daha önce ne denedin?

    func commitPreviousAttempts(_ attempts: [PreviousAttempt], otherText: String? = nil) {
        draft.previousAttempts = attempts
        draft.previousAttemptOtherText = otherText
        advance(to: .b6CurrentMood)
    }

    // MARK: - B6 · Şu an nasılsın?

    /// Kademe seçildiği anda arka plan tepki verir — A2'deki kategori
    /// önizlemesiyle aynı mantık, cevabın karşılığı hemen görünür (sahne perdesi
    /// koyulaşır/açılır, bkz. `currentSceneDimming`).
    func previewCurrentMood(_ mood: MoodLevel) {
        previewedMood = mood
    }

    func commitCurrentMood(_ mood: MoodLevel) {
        draft.currentMood = mood
        previewedMood = nil
        advance(to: .c1Mirroring)
    }

    // MARK: - C · Yansıtma ve ikna
    //
    // Burada soru sorulmuyor, anlatılıyor. Her ekranın tek bir ileri yolu var;
    // ayrı bir "geç" bağlantısı yok çünkü CTA zaten hızlı yol.

    func finishMirroring() {
        advance(to: .c2NotAlone)
    }

    /// C3 koşulludur: kullanıcı başka bir meditasyon uygulaması denemediyse
    /// karşılaştıracağı bir deneyimi yok ve ekran akışı boş yere uzatır
    /// (PRD-Ek Onboarding §4.3). Koşul `OnboardingDraft`ta hesaplanır.
    func finishNotAlone() {
        advance(to: draft.showsLibraryComparison ? .c3PathNotLibrary : .c4HonestExpectation)
    }

    func finishLibraryComparison() {
        advance(to: .c4HonestExpectation)
    }

    func finishHonestExpectation() {
        advance(to: .d0MeasurementIntro)
    }

    // MARK: - D · Baseline ölçüm
    //
    // Bu bölüm atlanamaz (PRD-Ek Onboarding §10): baseline olmadan 7. günde
    // karşılaştırılacak bir şey kalmıyor ve ürünün tamamı o karşılaştırmaya
    // dayanıyor. Bu yüzden hiçbir D ekranında "geç" bağlantısı yok.

    /// Onboarding'de yapılan ölçüm her zaman baseline'dır; varyantı da oradan
    /// gelir (PRD §8.3 madde rotasyonu).
    var measurementPoint: MeasurementPoint { .baseline }
    var measurementVariant: MeasurementVariant { measurementPoint.variant }

    /// Sorular kategoriye göre değişir (D5, PRD §8.5) — bu yüzden taslaktan
    /// türetiliyor, sabit bir dizi değil.
    var measurementItems: [MeasurementItem] {
        MeasurementLibrary.items(for: measurementPoint, category: draft.primaryCategory)
    }

    /// `index` 1 tabanlıdır: ekran adları D1…D8.
    func measurementItem(at index: Int) -> MeasurementItem {
        let items = measurementItems
        let position = min(max(index, 1), items.count) - 1
        return items[position]
    }

    func startMeasurement() {
        advance(to: .dMeasurement(1))
    }

    /// Ham cevap madde kimliğiyle saklanır (`Measurement.rawResponses` ile aynı
    /// anahtar). Normalize etme ve skorlama burada **yapılmaz**: bu ekranların
    /// hiçbirinde skor gösterilmiyor (PRD §7.3) ve skoru üretmenin yeri path
    /// üretimiyle birlikte gelecek olan ölçüm servisi.
    func commitMeasurementAnswer(_ value: Double, at index: Int) {
        draft.measurementResponses[measurementItem(at: index).id] = value

        if index < measurementItems.count {
            advance(to: .dMeasurement(index + 1))
        } else {
            advance(to: .e1Reminder)
        }
    }

    // MARK: - E · Tercihler
    //
    // E3 (ton) 2026-09-22'de kaldırıldı (ürün sahibi kararı, bkz. karar günlüğü):
    // `TonePreference` sıralı bir küme değildi ve ekranın yerini alacak bir kaydırıcı
    // yoktu. Enum, `resolvedTonePreference` ve sunucu alanı kalıyor — sunucu şeması
    // `tone`u zorunlu ve doğrulanan bir alan olarak istiyor.

    /// E1'in önerdiği saat B3'ten geliyor — sorduğumuz her şeyin görünür bir
    /// karşılığı olmalı.
    var suggestedReminderHour: Int { draft.suggestedReminderHour }
    var suggestedReminderMinute: Int { draft.reminderMinute }

    func commitReminder(hour: Int, minute: Int) {
        draft.reminderHour = hour
        draft.reminderMinute = minute
        // Adım uzunluğu ve ses kullanıcıya sorulmuyor (2026-09-21): uzunluk taslağın
        // varsayılanı (10 dk, `SessionLength.standard`), ses MVP'nin tek sesi. Sunucu ve
        // oturum bu alanları okumaya devam ediyor. Bu satır E3 silinince (2026-09-22)
        // buraya taşındı — E3'ün commit'i bu satırı taşımıyordu, yoksa ses tercihi hiç
        // kurulmazdı.
        draft.voicePreference = .feminine
        advance(to: .h2Priming)
    }

    // MARK: - F · Üretim ve teslim

    /// Üretilen path. F2 başlığını ve uzunluğunu, G1 ilk adımını buradan okur.
    private(set) var generatedPath: GeneratedPath?

    /// Path uzunluğu üretimden gelir; cevap yoksa 21 güne düşer (PRD §9.2).
    var pathLength: PathLength {
        guard let days = generatedPath?.steps.count,
              let length = PathLength(rawValue: days)
        else { return .threeWeeks }
        return length
    }

    /// Başlık üretimden gelir; kategori yedeği çevrimdışı ve hata durumları için
    /// kalır — kullanıcı boş bir başlık görmemeli.
    var pathTitle: LocalizedStringResource {
        if let title = generatedPath?.title, !title.isEmpty {
            return LocalizedStringResource(stringLiteral: title)
        }
        return draft.primaryCategory.provisionalPathTitle
    }

    /// G1'in oynatacağı adım. Path yoksa nil — ekran o zaman kendi kurtarma
    /// yolunu izler (sunucudan en son path'i okur, o da yoksa jenerik bloklar).
    var firstStep: GeneratedPathStep? { generatedPath?.steps.first }

    func finishGeneration() {
        advance(to: .f2Roadmap)
    }

    /// JIT ses üretimi (PRD-Ek Path Üretimi §6): F1'de planın tamamı **ve
    /// yalnızca 1. adımın sesi** üretilir. Ücretsiz penceredeki üretimin ~%43'ü
    /// aksi hâlde boşa gidiyor.
    ///
    /// Bilerek "ateşle ve unut": ses **ek**, oturumun kendisi değil. Burada bir
    /// hata olması F2'yi ya da G1'i durdurmaz — kullanıcı sessiz sürümü dinler.
    /// Erken başlatılmasının tek sebebi, kullanıcı haritayı okurken sesin
    /// üretilmeye başlaması.
    func prepareFirstStepAudio() {
        guard let pathId = generatedPath?.id, audioPreparation == nil else { return }
        audioPreparation = Task { [services] in
            do {
                let token = try await services.auth.validAccessToken()
                let step = try await services.backend.pathStep(
                    pathId: pathId,
                    day: 1,
                    accessToken: token
                )
                firstStepId = step.id
                guard step.audioStatus == .pending else { return }
                try await requestFirstStepAudio(stepId: step.id, accessToken: token)
            } catch {
                services.observability.capture(.audioGeneration)
            }
        }
    }

    /// G1 adımı hâlâ `pending` görüyorsa çağrılır: F1'in isteği ya sunucuya
    /// ulaşmadı ya da başarısız oldu.
    ///
    /// Önce F1'in görevini bekler — isteği uçuştayken ikinci bir istek aynı iş için
    /// ikinci bir kuyruk mesajı demek (`enqueue_audio_job`), yani iki işçinin aynı
    /// slotları aynı anda seslendirmesi. F1 isteği yaptıysa burada hiçbir şey yapılmaz.
    func requestFirstStepAudioIfStillPending(stepId: UUID) async {
        await audioPreparation?.value
        guard !didRequestFirstStepAudio else { return }
        do {
            let token = try await services.auth.validAccessToken()
            try await requestFirstStepAudio(stepId: stepId, accessToken: token)
        } catch {
            services.observability.capture(.audioGeneration)
        }
    }

    private func requestFirstStepAudio(stepId: UUID, accessToken: String) async throws {
        didRequestFirstStepAudio = true
        let outcome = try await services.backend.requestAudioWithRetry(
            pathStepId: stepId,
            accessToken: accessToken,
            idempotencyKey: firstStepAudioKey
        )
        if case .unavailable = outcome { isFirstStepAudioUnavailable = true }
    }

    func generatePath(idempotencyKey: UUID) async throws -> PathGenerationResult {
        if !didTrackPathGenerationStart {
            didTrackPathGenerationStart = true
            services.observability.capture(.pathGenerationStarted)
        }
        do {
            let token = try await services.auth.validAccessToken()
            let result = try await services.backend.generatePathWithReconciliation(
                from: draft,
                measurementVariant: measurementVariant,
                accessToken: token,
                idempotencyKey: idempotencyKey
            )
            if case .ready = result {
                services.observability.capture(.pathGenerationFinished(succeeded: true))
            }
            if case .ready(let path) = result {
                generatedPath = path
            }
            return result
        } catch {
            services.observability.capture(.pathGenerationFinished(succeeded: false))
            services.observability.capture(.pathGeneration)
            throw error
        }
    }

    /// Taahhüt ekranındaki imza sonrası basılı tutma bunu tetikler. Buradan sonrası G1:
    /// kullanıcı kayıt olmadan ilk oturumunu dinliyor (PRD-Ek Onboarding §8).
    ///
    /// **Geri dönülmez.** Harita geride kalıyor ve oturum başlıyor; geçmişi
    /// temizlemek, oturumun ortasında geri tuşuyla haritaya düşmeyi engelliyor.
    func startFirstSession() {
        markStepCompleted(step)
        history.removeAll()
        step = .g1FirstSession
        markStepViewed(step)
    }

    func finishRoadmap() {
        advance(to: .commitment)
    }

    /// G1 bitti. `completed` false ise kullanıcı "Burada duralım" dedi.
    ///
    /// **Yarım bırakılan oturum tamamlanmış sayılmaz** ve `completed_at`
    /// yazılmaz: o sütun profildeki ilerlemeyi ve sonraki adımın açılmasını
    /// besleyecek, dolduramadığı bir adımı dolmuş göstermek kullanıcının kendi
    /// kaydını yalanlamak olurdu. Akış yine G2'ye gider — yarıda bırakmak bir
    /// hata değil ve cezası yok.
    func finishFirstSession(completed: Bool) {
        markStepCompleted(step)
        if completed { services.observability.capture(.sessionCompleted(source: .first)) }
        sessionVoiceEnergy = 0
        didCompleteFirstSession = completed
        // Geri dönülmez: oturum arkada kaldı.
        history.removeAll()
        step = .g2SessionComplete
        markStepViewed(step)
    }

    var firstStepQuestion: String? {
        guard didCompleteFirstSession, generatedPath?.kind == .personalized else { return nil }
        return firstStep?.question
    }

    func completeFirstStep(answer: String?, skipped: Bool) async -> Bool {
        guard didCompleteFirstSession, let stepId = firstStepId else { return true }
        if let answer, CrisisClassifier.evaluate(answer).hasSignal {
            flagCrisis()
            return false
        }
        do {
            let token = try await services.auth.validAccessToken()
            switch try await services.backend.completeStep(
                pathStepId: stepId,
                answer: answer,
                skipped: skipped,
                accessToken: token
            ) {
            case .completed:
                // Kayıt burada da kurulur: G2 cevabı defterin ilk kişisel
                // cümlesi ve kullanıcı H1'de uygulamayı kapatsa bile kalmalı.
                services.profile.recordOnboarding(draft)
                return true
            case .crisis:
                flagCrisis()
                return false
            }
        } catch {
            services.observability.capture(.stepCompletion)
            return false
        }
    }

    func updateSessionVoiceEnergy(_ value: Double) {
        sessionVoiceEnergy = min(max(value, 0), 1)
    }

    /// Only a completed first session can lead to a purchase offer.
    func finishSessionSummary() {
        advance(to: didCompleteFirstSession && generatedPath?.kind == .personalized ? .price : .h1Account)
    }

    func finishPrice() {
        advance(to: .h1Account)
    }

    /// H2. İzin yalnızca "İzin ver" ile ve ekranda ne alınacağı görüldükten sonra istenir
    /// (`ReminderScheduler.apply` sistem penceresini o an açar). Reddetmek ya da izin
    /// verilmemesi akışı durdurmaz: hatırlatma kapalı kalır, Ben sekmesi ayarlardan açmayı
    /// gösterir. Sonuç taslakta tutulur; profil G2/H1'de kurulurken E1 saatiyle birlikte yazılır.
    func finishReminderPriming(enable: Bool) async {
        if enable {
            let reminder = ReminderSetting(
                isEnabled: true,
                hour: draft.reminderHour,
                minute: draft.reminderMinute,
                isSuggested: draft.timing?.suggestedReminderHour == draft.reminderHour
            )
            draft.reminderEnabled = await ReminderScheduler.apply(reminder) == .scheduled
        } else {
            draft.reminderEnabled = false
        }
        services.observability.capture(.reminderPreferenceChanged(enabled: draft.reminderEnabled))
        advance(to: .f1Generation)
    }

    /// Kalan adım sayısı — G2'nin "yolunda N adım daha var" cümlesi.
    var remainingSteps: Int { max(0, pathLength.days - 1) }

    var reminderTimeText: String { draft.reminderTimeText }

    func linkAccount(_ provider: AuthProvider) async -> Bool {
        if !didTrackAccountChoice {
            didTrackAccountChoice = true
            services.observability.capture(.accountChoice(provider == .apple ? .apple : .google))
        }
        guard await services.auth.link(provider: provider) else {
            services.observability.capture(.accountLinkFinished(provider: provider, succeeded: false))
            services.observability.capture(.accountLink)
            return false
        }
        services.observability.capture(.accountLinkFinished(provider: provider, succeeded: true))
        await completeOnboarding()
        return true
    }

    func skipAccountLink() async {
        if !didTrackAccountChoice {
            didTrackAccountChoice = true
            services.observability.capture(.accountChoice(.later))
        }
        await completeOnboarding()
    }

    // MARK: - Güvenlik

    /// PRD §11.1. Sinyal geldiğinde akış durur ve geri dönülemez.
    func flagCrisis() {
        draft.crisisDetected = true
        history.removeAll()
        step = .crisis
    }

    func completeOnboarding() async {
        if step == .h1Account { markStepCompleted(step) }
        // "Ben" sekmesinin başlangıcı: ad, ilk cümle, baseline ve tercihler
        // cihazda kalır. Kriz sinyali verilmiş akış kaydedilmez.
        services.profile.recordOnboarding(draft)
        if let token = try? await services.auth.validAccessToken(),
           let userID = services.auth.session?.userID {
            do {
                try await services.backend.markOnboardingCompleted(userID: userID, accessToken: token)
                // Hitap adı sunucuda şifreli durur: uygulama yeniden kurulduğunda
                // ya da başka bir cihazda "Ben" aynı adı gösterir.
                if let name = draft.displayName {
                    _ = try await services.backend.updateDisplayName(name, accessToken: token)
                }
            } catch {
                services.observability.capture(.profileSync)
            }
        }
        onFinished()
    }
}

extension OnboardingFlowViewModel {
    /// Preview'lar için akışı ortasından kurar. Aynı dosyada duruyor çünkü
    /// `step` ve `draft` yalnızca burada yazılabilir — ve öyle kalmalı.
    static func preview(
        step: OnboardingStep,
        draft: OnboardingDraft
    ) -> OnboardingFlowViewModel {
        let flow = OnboardingFlowViewModel(services: .live())
        flow.step = step
        flow.draft = draft
        return flow
    }
}

#if DEBUG
extension OnboardingFlowViewModel {
    /// Geliştirme sırasında akışı ileri sarmak için — `OnboardingDebugSkip`.
    ///
    /// `step` ve `draft` bilerek `private(set)`: dışarıdan yazılamamalı. Bu iki
    /// kapı aynı dosyada duruyor ve `#if DEBUG` içinde; Release'te yok.
    func debugApply(draft: OnboardingDraft) {
        self.draft = draft
    }

    func debugSetStep(_ target: OnboardingStep) {
        history.removeAll()
        step = target
    }

    func debugPreparePaywallPreview() {
        generatedPath = GeneratedPath(
            id: UUID(uuidString: "AB000000-0000-4000-8000-000000000007")!,
            kind: .personalized,
            title: "Preview path",
            steps: (1...7).map {
                GeneratedPathStep(day: $0, title: "Preview step", blockIds: [], slotCopy: [:], question: nil)
            }
        )
        didCompleteFirstSession = true
    }
}
#endif
