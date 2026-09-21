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
    // Üç ekran tek kartta birleşti (2026-09-21, docs/onboarding-redesign.md): cinsiyet ve
    // yaş ürünün hiçbir davranışını değiştirmiyor, iki tam ekran bir istatistiğe gidiyordu.
    case identity
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
    /// Taahhüt anı (2026-09-21): kullanıcının kendi cümlesinin üstünde bir kaydırma.
    case commitment
    // D — Baseline ölçüm (9 ekran: giriş + 8 soru). Atlanamayan tek bölüm.
    case d0MeasurementIntro
    /// D1–D8. `index` 1 tabanlı ve `OnboardingDraft.measurementItems`
    /// dizisindeki sırayı gösterir.
    case dMeasurement(Int)
    // E — Tercihler (2 ekran). İkisinin de ürün davranışında görünür karşılığı var.
    // E2 (adım uzunluğu) ve E4 (rehber sesi) 2026-09-21'de kaldırıldı: uzunluğu ürün
    // sahibi ayarlıyor (varsayılan 10 dk), MVP tek ses (kadın).
    case e1Reminder
    case e3Tone
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
        // Kimlik tek ekran olunca soru bölümü 8 ekran: kimlik + A2 + B1–B6.
        case .identity: 1.0 / 8.0
        case .a2Categories: 2.0 / 8.0
        case .b1ProblemText: 3.0 / 8.0
        case .b2Duration: 4.0 / 8.0
        case .b3Timing: 5.0 / 8.0
        case .b4Avoidance: 6.0 / 8.0
        case .b5PreviousAttempts: 7.0 / 8.0
        case .b6CurrentMood: 1.0
        // D kendi ölçeğiyle yeniden başlar: soru bölümünün izi B6'da dolmuştu,
        // ölçüm ayrı bir bölüm ve kendi uzunluğu var. Giriş ekranında (D0) soru
        // sorulmadığı için iz solar — tıpkı C bölümünde olduğu gibi.
        case .dMeasurement(let index):
            Double(index) / Double(MeasurementPoint.baseline.questionCount)
        // E kendi ölçeğiyle yeniden başlar — iki ekranlık kısa bir bölüm.
        case .e1Reminder: 1.0 / 2.0
        case .e3Tone: 1.0
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
        // Fiyat ve H2'de geri yok: G2'ye dönmek, bitmiş oturumun özetini yeniden açardı.
        case .a1Welcome, .f1Generation, .f2Roadmap, .g1FirstSession, .g2SessionComplete,
             .price, .h2Priming, .h1Account, .crisis: false
        default: true
        }
    }

    /// Adımın malzemesi (docs/onboarding-redesign.md, Bölüm 2.2). Görsel politika
    /// `backgroundSafeY` ve `breathAmplitude` gibi burada, sıradaki enum'da durur;
    /// kabuk yalnızca okur ve 20 çağrı noktası değişmez.
    var surfaceStyle: OnboardingSurfaceStyle {
        switch self {
        // Zemin katmanında yalnızca A2, B6 ve D1–D8 kalır: onların cevabı arka planın kendisi
        // (A2 paleti, B6 ruh hâli) ya da ölçüm aracı.
        case .identity, .b1ProblemText, .b2Duration, .b3Timing, .b4Avoidance, .b5PreviousAttempts,
             .c1Mirroring, .c2NotAlone, .c3PathNotLibrary, .c4HonestExpectation, .commitment,
             .d0MeasurementIntro, .e1Reminder, .e3Tone, .price, .h2Priming, .h1Account: .paper
        default: .ground
        }
    }

    /// Tam ekran sahne zemini olan adımlar: opak guaj mesh'in yerine geçer. Görsel yoksa
    /// (henüz üretilmedi ya da `-patika-debug-no-art`) mesh ve mevcut yerleşim kalır.
    var sceneArtwork: OnboardingArtwork? {
        switch self {
        case .a1Welcome: .threshold
        default: nil
        }
    }

    /// Metin bandının karartma gücü. Scrim koyu zeminde açık metni okunur tutmak
    /// için vardı; kâğıt kartın altında görünmez ve tek etkisi mesh'i kısmak olur —
    /// A2 ve B6'nın paleti göstermek için ihtiyaç duyduğu şeyin tam tersi
    /// (docs/onboarding-redesign.md, Bölüm 2.4).
    var backgroundScrimStrength: Float {
        surfaceStyle == .paper ? 0.06 : 0.45
    }

    /// Metin bandının dikey merkezi — ekran bazlı değerler Görsel Sistem eki §7'de.
    var backgroundSafeY: Float {
        switch self {
        case .a1Welcome: 0.72   // başlık alt yarıda
        case .crisis: 0.40
        // C ekranlarında soru yok, paragraf var: metin bandı soru ekranlarından
        // uzun ve biraz daha aşağı iniyor.
        case .c1Mirroring, .c2NotAlone, .c3PathNotLibrary, .c4HonestExpectation,
             .d0MeasurementIntro: 0.30
        // F1'de metin en üstte ve tek: iz aşağı doğru iniyor, arka planın açık
        // bandı onun altında kalmalı. F2 uzun bir liste; scrim üst şeride.
        case .f1Generation: 0.16
        case .f2Roadmap: 0.14
        // G1'de tek bir cümle ekranın ortasında duruyor; açık bant onun altında.
        case .g1FirstSession: 0.50
        // G2 oturumdan çıkış: metin bloğu alt yarıda, A1'in kanca yerleşimi gibi.
        case .g2SessionComplete: 0.62
        default: 0.18           // soru ekranlarında metin üstte
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

/// Onboarding akışının sahibi. Adım yönlendirmesi, taslak veri ve palet
/// senkronizasyonu buradadır; görünümler karar vermez.
@Observable
@MainActor
final class OnboardingFlowViewModel {
    private(set) var step: OnboardingStep = .a1Welcome
    private(set) var draft = OnboardingDraft()

    /// Palet, kategori seçimiyle canlı değişir (Görsel Sistem eki §6.4).
    private let palette: PaletteController
    /// Oturum ekranı da aynı istemcileri kullanıyor (ses üretimi, imzalı adres);
    /// ikinci bir servis kabı kurmak yerine akışınki paylaşılıyor.
    let services: AppServices
    /// Onboarding bittiğinde çağrılır.
    private let onFinished: () -> Void

    private var history: [OnboardingStep] = []
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
    /// Oturumdaki ses zarfı. Yalnızca dekoratif mesh bunu okur; analitiğe ve
    /// kalıcı depoya gitmez.
    private(set) var sessionVoiceEnergy: Double = 0

    init(
        palette: PaletteController,
        services: AppServices,
        onFinished: @escaping () -> Void = {}
    ) {
        self.palette = palette
        self.services = services
        self.onFinished = onFinished
    }

    // MARK: - Navigasyon

    func advance(to next: OnboardingStep) {
        history.append(step)
        step = next
    }

    func goBack() {
        guard let previous = history.popLast() else { return }
        step = previous
    }

    // MARK: - A1

    /// A1'de "Başlayalım" da "atla" da aynı yere gider — A2 atlanamaz, çünkü
    /// path tipi oradan belirlenir (PRD-Ek Onboarding §10 kaçış tablosu).
    func finishWelcome() async -> Bool {
        guard await services.auth.ensureAnonymousSession() else {
            services.observability.capture(.anonymousAuthentication)
            return false
        }
        services.observability.capture(.onboardingStarted)
        advance(to: .identity)
        return true
    }

    // MARK: - Kimlik

    /// Ad da serbest metin — "kullanıcının yazdığı **her** serbest metin
    /// sınıflandırıcıdan geçer" kuralının istisnası yok. Ad alanına kriz sinyali
    /// yazılması beklenmiyor ama kuralın istisnası olduğu an kural değildir.
    ///
    /// Ad boşsa isimsiz devam eder: isimsiz sürüm eksik bir sürüm değil. Cinsiyet ve
    /// yaş cevapsızsa `undisclosed`.
    func commitIdentity(name: String, gender: Gender, ageRange: AgeRange) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if CrisisClassifier.evaluate(trimmed).hasSignal {
            flagCrisis()
            return
        }

        draft.name = trimmed.isEmpty ? nil : trimmed
        draft.gender = gender
        draft.ageRange = ageRange
        advance(to: .a2Categories)
    }

    // MARK: - A2

    func commitCategories(_ categories: [ProblemCategory]) {
        draft.categories = categories
        palette.select(categories)
        advance(to: .b1ProblemText)
    }

    /// Kategori seçimi değiştikçe arka plan anında tepki verir.
    func previewCategories(_ categories: [ProblemCategory]) {
        palette.select(categories)
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
        advance(to: .b2Duration)
    }

    /// "Yazmak istemiyorum". Kişiselleştirme zayıflar, akış durmaz (§10).
    func skipProblemText() {
        draft.problemText = ""
        advance(to: .b2Duration)
    }

    // MARK: - B2 · Süre

    func commitDuration(_ duration: ProblemDuration) {
        draft.duration = duration
        advance(to: .b3Timing)
    }

    // MARK: - B3 · Zamanlama

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

    func commitPreviousAttempts(_ attempts: [PreviousAttempt]) {
        draft.previousAttempts = attempts
        advance(to: .b6CurrentMood)
    }

    // MARK: - B6 · Şu an nasılsın?

    /// Kademe seçildiği anda arka plan tepki verir — A2'deki kategori
    /// önizlemesiyle aynı mantık, cevabın karşılığı hemen görünür.
    func previewCurrentMood(_ mood: MoodLevel) {
        palette.setMood(mood)
    }

    func commitCurrentMood(_ mood: MoodLevel) {
        draft.currentMood = mood
        palette.setMood(mood)
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
        advance(to: .commitment)
    }

    /// Söz saklanmaz ve kimseye gitmez: karşılığı bir ürün davranışı değil, bir an.
    func finishCommitment() {
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
    // Üç cevabın üçü de ürünün davranışını değiştiriyor: hatırlatma saati
    // bildirimi, süre blok seçimini, ton TTS istemini. "Kişiselleştirme
    // tiyatrosu" değil (PRD-Ek Onboarding §6).

    /// E1'in önerdiği saat B3'ten geliyor — sorduğumuz her şeyin görünür bir
    /// karşılığı olmalı.
    var suggestedReminderHour: Int { draft.suggestedReminderHour }
    var suggestedReminderMinute: Int { draft.reminderMinute }

    func commitReminder(hour: Int, minute: Int) {
        draft.reminderHour = hour
        draft.reminderMinute = minute
        advance(to: .e3Tone)
    }

    func commitTonePreference(_ tone: TonePreference) {
        draft.tonePreference = tone
        // Adım uzunluğu ve ses kullanıcıya sorulmuyor (2026-09-21): uzunluk taslağın
        // varsayılanı (10 dk, `SessionLength.standard`), ses MVP'nin tek sesi. Sunucu ve
        // oturum bu alanları okumaya devam ediyor.
        draft.voicePreference = .feminine
        advance(to: .f1Generation)
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
        let token = try await services.auth.validAccessToken()
        do {
            let result = try await services.backend.generatePathWithReconciliation(
                from: draft,
                measurementVariant: measurementVariant,
                accessToken: token,
                idempotencyKey: idempotencyKey
            )
            services.observability.capture(.pathGenerationFinished(
                result: result == .crisis ? .crisis : .ready
            ))
            if case .ready(let path) = result {
                generatedPath = path
            }
            return result
        } catch {
            services.observability.capture(.pathGenerationFinished(result: .failed))
            services.observability.capture(.pathGeneration)
            throw error
        }
    }

    /// F2'nin "Yola çık"ı — basılı tutularak tetiklenir. Buradan sonrası G1:
    /// kullanıcı kayıt olmadan ilk oturumunu dinliyor (PRD-Ek Onboarding §8).
    ///
    /// **Geri dönülmez.** Harita geride kalıyor ve oturum başlıyor; geçmişi
    /// temizlemek, oturumun ortasında geri tuşuyla haritaya düşmeyi engelliyor.
    func startFirstSession() {
        history.removeAll()
        step = .g1FirstSession
    }

    /// G1 bitti. `completed` false ise kullanıcı "Burada duralım" dedi.
    ///
    /// **Yarım bırakılan oturum tamamlanmış sayılmaz** ve `completed_at`
    /// yazılmaz: o sütun profildeki ilerlemeyi ve sonraki adımın açılmasını
    /// besleyecek, dolduramadığı bir adımı dolmuş göstermek kullanıcının kendi
    /// kaydını yalanlamak olurdu. Akış yine G2'ye gider — yarıda bırakmak bir
    /// hata değil ve cezası yok.
    func finishFirstSession(completed: Bool) {
        sessionVoiceEnergy = 0
        didCompleteFirstSession = completed
        // Geri dönülmez: oturum arkada kaldı.
        history.removeAll()
        step = .g2SessionComplete
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

    /// G2'nin "Devam"ı. Sıra: fiyat şeffaflığı, bildirim ön hazırlığı, hesap.
    func finishSessionSummary() {
        advance(to: .price)
    }

    func finishPrice() {
        advance(to: .h2Priming)
    }

    /// H2. İzin yalnızca "İzin ver" ile ve ekranda ne alınacağı görüldükten sonra istenir
    /// (`ReminderScheduler.apply` sistem penceresini o an açar). Reddetmek ya da izin
    /// verilmemesi akışı durdurmaz: hatırlatma kapalı kalır, Ben sekmesi ayarlardan açmayı
    /// gösterir. Kayıt önce kurulur ki hatırlatma satırı E1'in saatini taşısın.
    func finishReminderPriming(enable: Bool) async {
        if enable {
            services.profile.recordOnboarding(draft)
            if var reminder = services.profile.record?.reminder {
                reminder.isEnabled = true
                let outcome = await ReminderScheduler.apply(reminder)
                if outcome == .denied { reminder.isEnabled = false }
                services.profile.setReminder(reminder)
            }
        }
        advance(to: .h1Account)
    }

    /// Kalan adım sayısı — G2'nin "yolunda N adım daha var" cümlesi.
    var remainingSteps: Int { max(0, pathLength.days - 1) }

    var reminderTimeText: String { draft.reminderTimeText }

    func linkAccount(_ provider: AuthProvider) async -> Bool {
        guard await services.auth.link(provider: provider) else {
            services.observability.capture(.accountLinkFinished(provider: provider, succeeded: false))
            services.observability.capture(.accountLink)
            return false
        }
        services.observability.capture(.accountLinkFinished(provider: provider, succeeded: true))
        await completeOnboarding()
        return true
    }

    // MARK: - Güvenlik

    /// PRD §11.1. Sinyal geldiğinde akış durur ve geri dönülemez.
    func flagCrisis() {
        draft.crisisDetected = true
        history.removeAll()
        step = .crisis
    }

    func completeOnboarding() async {
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

#if DEBUG
extension OnboardingFlowViewModel {
    /// Preview'lar için akışı ortasından kurar. Aynı dosyada duruyor çünkü
    /// `step` ve `draft` yalnızca burada yazılabilir — ve öyle kalmalı.
    static func preview(
        step: OnboardingStep,
        draft: OnboardingDraft,
        palette: PaletteController
    ) -> OnboardingFlowViewModel {
        let flow = OnboardingFlowViewModel(palette: palette, services: .live())
        flow.step = step
        flow.draft = draft
        return flow
    }

    /// Geliştirme sırasında akışı ileri sarmak için — `OnboardingDebugSkip`.
    ///
    /// `step` ve `draft` bilerek `private(set)`: dışarıdan yazılamamalı. Bu iki
    /// kapı aynı dosyada duruyor ve `#if DEBUG` içinde; Release'te yok.
    func debugApply(draft: OnboardingDraft) {
        self.draft = draft
        palette.select(draft.categories)
        palette.setMood(draft.currentMood)
    }

    func debugSetStep(_ target: OnboardingStep) {
        history.removeAll()
        step = target
    }
}
#endif
