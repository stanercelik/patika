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
    // D — Baseline ölçüm (9 ekran: giriş + 8 soru). Atlanamayan tek bölüm.
    case d0MeasurementIntro
    /// D1–D8. `index` 1 tabanlı ve `OnboardingDraft.measurementItems`
    /// dizisindeki sırayı gösterir.
    case dMeasurement(Int)
    // E — Tercihler (3 ekran). Üçünün de ürün davranışında görünür karşılığı var.
    case e1Reminder
    case e2SessionLength
    case e3Tone
    /// E4 — rehber sesi. PRD'de yok, sonradan eklendi (ürün sahibi kararı,
    /// 2026-09-09): ses kimliği kullanıcının en uzun temas ettiği yer.
    case e4Voice
    // F — Üretim ve teslim. PRD'de 4 ekran; F2 ile F3 **birleştirildi**
    // (ürün sahibi kararı, 2026-09-09), yani 3 ekran.
    case f1Generation
    case f2Roadmap
    // G — İlk değer / aha momenti (2 ekran, PRD-Ek Onboarding §8)
    case g1FirstSession
    case g2SessionComplete
    // H — hesap baglama. Bildirim izni sonraki uygulama diliminde eklenecek.
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
        // E kendi ölçeğiyle yeniden başlar — üç ekranlık kısa bir bölüm.
        case .e1Reminder: 1.0 / 4.0
        case .e2SessionLength: 2.0 / 4.0
        case .e3Tone: 3.0 / 4.0
        case .e4Voice: 1.0
        case .a1Welcome, .c1Mirroring, .c2NotAlone, .c3PathNotLibrary,
             .c4HonestExpectation, .d0MeasurementIntro, .f1Generation, .f2Roadmap,
             .g1FirstSession, .g2SessionComplete, .h1Account, .crisis: nil
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
        case .a1Welcome, .f1Generation, .f2Roadmap, .g1FirstSession, .g2SessionComplete,
             .h1Account, .crisis: false
        default: true
        }
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
    /// 1. adımın sunucudaki satır kimliği — G1 sesi bununla arıyor, G2 de
    /// tamamlanmayı bununla yazıyor.
    private(set) var firstStepId: UUID?
    /// G1 sonuna kadar dinlendi mi? G2'nin metnini bu belirliyor.
    private(set) var didCompleteFirstSession = false

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
        advance(to: .identityName)
        return true
    }

    // MARK: - Kimlik

    /// Ad da serbest metin — "kullanıcının yazdığı **her** serbest metin
    /// sınıflandırıcıdan geçer" kuralının istisnası yok. Ad alanına kriz sinyali
    /// yazılması beklenmiyor ama kuralın istisnası olduğu an kural değildir.
    func commitName(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if CrisisClassifier.evaluate(trimmed).hasSignal {
            flagCrisis()
            return
        }

        draft.name = trimmed.isEmpty ? nil : trimmed
        advance(to: .identityGender)
    }

    /// "İsim vermek istemiyorum". Akışın hiçbir yeri kapanmaz; metinler
    /// isimsiz sürümlerine düşer.
    func skipName() {
        draft.name = nil
        advance(to: .identityGender)
    }

    func commitGender(_ gender: Gender) {
        draft.gender = gender
        advance(to: .identityAge)
    }

    func commitAgeRange(_ range: AgeRange) {
        draft.ageRange = range
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
        advance(to: .e2SessionLength)
    }

    func commitSessionLength(_ length: SessionLength) {
        draft.sessionLength = length
        advance(to: .e3Tone)
    }

    func commitTonePreference(_ tone: TonePreference) {
        draft.tonePreference = tone
        advance(to: .e4Voice)
    }

    /// E4 — rehber sesi. Ton (E3) metnin nasıl **yazıldığını**, ses kimliği
    /// nasıl **okunduğunu** belirliyor; ikisi ayrı karar ve ikisi de gerçekten
    /// ürünün davranışını değiştiriyor.
    func commitVoicePreference(_ voice: VoicePreference) {
        draft.voicePreference = voice
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
                _ = try await services.backend.requestAudio(
                    pathStepId: step.id,
                    accessToken: token,
                    idempotencyKey: UUID()
                )
            } catch {
                services.observability.capture(.audioGeneration)
            }
        }
    }

    func generatePath(idempotencyKey: UUID) async throws -> PathGenerationResult {
        let token = try await services.auth.validAccessToken()
        do {
            let result = try await services.backend.generatePath(
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
        didCompleteFirstSession = completed
        if completed { markFirstStepCompleted() }
        // Geri dönülmez: oturum arkada kaldı.
        history.removeAll()
        step = .g2SessionComplete
    }

    /// G2'nin "Devam"ı.
    func finishSessionSummary() {
        advance(to: .h1Account)
    }

    /// Kalan adım sayısı — G2'nin "yolunda N adım daha var" cümlesi.
    var remainingSteps: Int { max(0, pathLength.days - 1) }

    var reminderTimeText: String { draft.reminderTimeText }

    /// Yazma **beklenmez**: G2 ağ cevabını bekleyip kullanıcıyı bekletmemeli.
    /// Başarısız olursa ilerleme kaydı eksik kalır; oturumun kendisi etkilenmez.
    private func markFirstStepCompleted() {
        guard let stepId = firstStepId else { return }
        Task { [services] in
            do {
                let token = try await services.auth.validAccessToken()
                try await services.backend.markStepCompleted(
                    pathStepId: stepId,
                    at: .now,
                    accessToken: token
                )
            } catch {
                services.observability.capture(.stepCompletion)
            }
        }
    }

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
        if let token = try? await services.auth.validAccessToken() {
            do {
                try await services.backend.markOnboardingCompleted(accessToken: token)
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
