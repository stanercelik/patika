import Foundation

/// Mikrometin kütüphanesi — Ton eki §3.
///
/// **Bu dosyada metin yok.** Metnin tek yeri `Localizable.xcstrings` (kaynak dil
/// İngilizce); buradaki her satır, katalogdan Xcode'un ürettiği sembole işaret eden
/// gruplanmış bir ad alanı. Yeni metin katalogda başlar. Yorumlar Türkçe kaldı: tasarım
/// gerekçesi, metnin kendisi değil. PRD-Ek Onboarding §14: nihai hedef bunların remote
/// config üzerinden yönetilmesi — bir kelime değişikliği için mağaza incelemesi beklenemez.
enum Copy {

    enum Auth {
        static let returningLink: LocalizedStringResource = .authReturningLink
        static let returningTitle: LocalizedStringResource = .authReturningTitle
        static let returningBody: LocalizedStringResource =
            .authReturningBody
        static let apple: LocalizedStringResource = .authApple
        static let google: LocalizedStringResource = .authGoogle
        static let notNow: LocalizedStringResource = .authNotNow
        static let linkTitle: LocalizedStringResource = .authLinkTitle
        static let linkBody: LocalizedStringResource = .authLinkBody
        static let skipLink: LocalizedStringResource = .authSkipLink
        static let failed: LocalizedStringResource =
            .authFailed
        static let sessionMissing: LocalizedStringResource =
            .authSessionMissing
        static let identityAlreadyLinked: LocalizedStringResource =
            .authIdentityAlreadyLinked
        static let noSavedPath: LocalizedStringResource =
            .authNoSavedPath
        static let working: LocalizedStringResource = .authWorking
    }

    /// Buton metinleri standart değil, ürüne özeldir (Ton eki §3.4).
    enum Button {
        /// "Başla" değil — metafor tutarlılığı.
        static let start: LocalizedStringResource = .buttonStart
        /// "Devam et" değil — kayıp değil süreklilik vurgusu.
        static let resume: LocalizedStringResource = .buttonResume
        /// "İptal" değil — reddetmeyi suçsuzlaştırır.
        static let cancel: LocalizedStringResource = .buttonCancel
        /// "Atla" değil — "atlamak" kalıcı, "geçmek" geçici.
        static let skip: LocalizedStringResource = .buttonSkip
        /// Onboarding sorularının çıkışı. Aynı gerekçe: geçmek geçicidir,
        /// kullanıcı isterse geri dönüp cevaplayabilir.
        static let skipQuestion: LocalizedStringResource = .buttonSkipQuestion
        /// "Kaydet" değil — sahiplik.
        static let save: LocalizedStringResource = .buttonSave
        /// "Bitir" değil — off-ramp tonu.
        static let finish: LocalizedStringResource = .buttonFinish
        /// "Tekrar dene" değil — yumuşak.
        static let retry: LocalizedStringResource = .buttonRetry
        static let understood: LocalizedStringResource = .buttonUnderstood
        static let next: LocalizedStringResource = .buttonNext
        /// Çok satırlı yazı alanlarının klavye araç çubuğu — `return` sonraki satıra
        /// geçtiği için klavyeyi kapatan ayrı bir yol gerekiyor.
        static let doneKeyboard: LocalizedStringResource = .buttonDoneKeyboard
    }

    /// Boş durumlar (Ton eki §3.1). Hiçbirinde şaka yok, hiçbirinde suçlama yok.
    /// "Acelesi yok" cümlesi ürünün imzasıdır.
    enum Empty {
        static let discoverHeadline: LocalizedStringResource = .emptyDiscoverHeadline
        static let discoverBody: LocalizedStringResource = .emptyDiscoverBody
        static let returnToPath: LocalizedStringResource = .emptyReturnToPath
        static let pathInvitation: LocalizedStringResource = .emptyPathInvitation
        static let pathInvitationBody: LocalizedStringResource = .emptyPathInvitationBody
        static let pathInvitationNote: LocalizedStringResource = .emptyPathInvitationNote
        static let checkPath: LocalizedStringResource = .emptyCheckPath

        static let noPath: LocalizedStringResource =
            .emptyNoPath
        static let noBadges: LocalizedStringResource =
            .emptyNoBadges
        static let noSavedSessions: LocalizedStringResource =
            .emptyNoSavedSessions
        static let noSearchResults: LocalizedStringResource =
            .emptyNoSearchResults
        static let noMeasurements: LocalizedStringResource =
            .emptyNoMeasurements
    }

    /// Hata durumları (Ton eki §3.2).
    ///
    /// Her metinde "kaybolmadı / senin yüzünden değil" ifadesi geçer: kaygılı kullanıcı
    /// hatayı otomatik olarak kendine mal eder, bunu her seferinde kesiyoruz.
    enum Error {
        static let offline: LocalizedStringResource =
            .errorOffline
        static let audioFailed: LocalizedStringResource =
            .errorAudioFailed
        static let pathGenerationFailed: LocalizedStringResource =
            .errorPathGenerationFailed
        static let paymentFailed: LocalizedStringResource =
            .errorPaymentFailed
        static let server: LocalizedStringResource =
            .errorServer
    }

    /// Path üretimi sırasında sırayla gösterilir (Ton eki §3.3, Onboarding F1).
    ///
    /// Espri yok. Bu an ciddi — kullanıcı az önce derdini anlattı.
    enum Loading {
        static let steps: [LocalizedStringResource] = [
            .loadingSteps1,
            .loadingSteps2,
            .loadingSteps3,
            .loadingSteps4,
        ]
        /// Keşfet sekmesi Oyuncu — Oyuncu kademesinde — burada hafifleyebilir.
        static let discover: LocalizedStringResource = .loadingDiscover
    }

    /// Dönüş ve kaçırılan gün (PRD §7.5). Suçluluk dili yok, "seni özledik" yok.
    enum Returning {
        static let afterBreak: LocalizedStringResource =
            .returningAfterBreak
        static let afterLongBreak: LocalizedStringResource =
            .returningAfterLongBreak
    }

    /// Onboarding metinleri — PRD-Ek Onboarding §2.
    enum Onboarding {
        // A1 — Kanca. Özellik listelemez, sonucu satar.
        static let welcomeHeadline: LocalizedStringResource = .onboardingWelcomeHeadline
        static let welcomeBody: LocalizedStringResource = .onboardingWelcomeBody
        static let welcomeCTA: LocalizedStringResource = .onboardingWelcomeCTA
        static let firstSessionHeadline: LocalizedStringResource = .onboardingFirstSessionHeadline
        static let firstSessionBody: LocalizedStringResource =
            .onboardingFirstSessionBody
        static let firstSessionComplete: LocalizedStringResource = .onboardingFirstSessionComplete

        // MARK: Kimlik — akışın girişi (PRD'de yok, ürün sahibi kararı)

        /// Ad sorusu. "Adın ne?" değil "nasıl hitap edelim": kullanıcı takma ad
        /// da verebilir, kısaltma da — ürünün istediği kimlik değil, seslenme
        /// biçimi.
        static let nameHeadline: LocalizedStringResource = .onboardingNameHeadline
        /// Ne için kullanıldığını söylüyoruz ve boş bırakmanın serbest olduğunu
        /// aynı cümlede yazıyoruz — kaygılı kullanıcı zorunlu alan görünce çıkar.
        static let nameHint: LocalizedStringResource =
            .onboardingNameHint
        static let namePlaceholder: LocalizedStringResource = .onboardingNamePlaceholder
        static let nameSkip: LocalizedStringResource = .onboardingNameSkip

        static let genderHeadline: LocalizedStringResource = .onboardingGenderHeadline
        static let ageHeadline: LocalizedStringResource = .onboardingAgeHeadline
        /// Cinsiyet ve yaş ekranlarının ortak notu.
        ///
        /// Sorduğumuz her şeyin görünür bir karşılığı olmalı; bu ikisinin yok ve
        /// bunu **saklamıyoruz**. Karşılığı olmayan bir soruyu varmış gibi
        /// sunmak, akışın geri kalanındaki dürüstlük iddiasını zayıflatırdı.
        static let identityStatsNote: LocalizedStringResource =
            .onboardingIdentityStatsNote

        // A2 — İlk soru, hemen.
        static let categoriesHeadline: LocalizedStringResource = .onboardingCategoriesHeadline
        static let categoriesHint: LocalizedStringResource = .onboardingCategoriesHint
        /// Pasif CTA metni — ne eksik olduğunu suçlamadan söyler. A2 ve tek
        /// seçimlik B ekranlarının hepsinde aynı cümle: kullanıcı bir kez
        /// öğrendiği kalıbı her ekranda tanır.
        static let chooseOneCTA: LocalizedStringResource = .onboardingChooseOneCTA

        // MARK: B — Problem keşfi (PRD-Ek Onboarding §3)

        /// B1 — akışın en değerli ekranı. Bu metin F2'de kullanıcıya geri yansıtılır
        /// ve G1'de kendi kelimeleriyle seslendirilir; aha momentinin yakıtı burada.
        static let problemTextHeadline: LocalizedStringResource =
            .onboardingProblemTextHeadline
        /// "Kimse okumuyor" cümlesi gizlilik vaadinin kendisi (PRD §13.5) —
        /// süsleme değil, doldurma oranını taşıyan kısım.
        static let problemTextHint: LocalizedStringResource = .onboardingProblemTextHint
        /// Atlama görünür ama ikincil: teşvik ediyoruz, zorlamıyoruz.
        static let problemTextSkip: LocalizedStringResource = .onboardingProblemTextSkip

        static let durationHeadline: LocalizedStringResource = .onboardingDurationHeadline

        static let timingHeadline: LocalizedStringResource =
            .onboardingTimingHeadline
        /// Sorunun karşılığını hemen söylüyoruz — cevabın nereye gittiğini
        /// göstermek anket hissini kırar.
        static let timingHint: LocalizedStringResource =
            .onboardingTimingHint

        static let avoidanceHeadline: LocalizedStringResource =
            .onboardingAvoidanceHeadline
        static let avoidanceHint: LocalizedStringResource =
            .onboardingAvoidanceHint
        static let avoidancePlaceholder: LocalizedStringResource =
            .onboardingAvoidancePlaceholder
        static let avoidanceSkip: LocalizedStringResource = .onboardingAvoidanceSkip

        static let attemptsHeadline: LocalizedStringResource = .onboardingAttemptsHeadline
        static let attemptsHint: LocalizedStringResource = .onboardingAttemptsHint
        static let attemptsOtherPlaceholder: LocalizedStringResource = .onboardingAttemptsOtherPlaceholder
        static let attemptsOtherRequired: LocalizedStringResource = .onboardingAttemptsOtherRequired
        /// Terapi devam ediyorsa gösterilir. Ürün terapinin yerine geçme imasında
        /// **asla** bulunmaz (PRD §4) — bu cümle o sınırı açıkça çiziyor.
        static let attemptsTherapyNote: LocalizedStringResource =
            .onboardingAttemptsTherapyNote

        static let moodHeadline: LocalizedStringResource = .onboardingMoodHeadline
        /// Ölçüm bölümüne ısınma; bu ölçek günlük ön kontrolün aynısı.
        static let moodHint: LocalizedStringResource =
            .onboardingMoodHint

        // MARK: C — Yansıtma ve ikna (PRD-Ek Onboarding §4)
        //
        // Bu bölümde soru yok. Kural: kendimizden değil, kullanıcıdan bahsederek
        // anlatıyoruz — hiçbir ekranda özellik listesi yok.

        /// C1 — akışın en yüksek güven üreten anı. Cümleler `MirroringComposer`da
        /// kullanıcının cevaplarından kuruluyor; buradakiler yalnızca bağlaçlar.
        /// Ada göre iki sürüm. **Adın kullanıldığı iki yerden biri** (diğeri C4);
        /// akışın en yüksek güven üreten anı burası ve isimle seslenmek o anı
        /// taşıyor. Her ekranda tekrarlansaydı samimi değil ısrarcı olurdu.
        static func mirroringHeadline(name: String?) -> LocalizedStringResource {
            guard let name else { return .onboardingMirroringHeadline1 }
            return .onboardingMirroringHeadline2(name)
        }
        static let mirroringDurationLead: LocalizedStringResource = .onboardingMirroringDurationLead
        static let mirroringDurationTail: LocalizedStringResource = .onboardingMirroringDurationTail
        static let mirroringAvoidanceLead: LocalizedStringResource =
            .onboardingMirroringAvoidanceLead
        /// Kapanış: durumu normalleştirir ama "geçecek" demez — vaat değil, çerçeve.
        static let mirroringClosing: LocalizedStringResource =
            .onboardingMirroringClosing

        /// C2 — sosyal kanıt, **sayısız**. Kategori cümlesi
        /// `ProblemCategory.commonalityLine`dan gelir; sayı kuralı orada yazılı.
        static let notAloneHeadline: LocalizedStringResource = .onboardingNotAloneHeadline
        static let notAloneResearchLine: LocalizedStringResource =
            .onboardingNotAloneResearchLine

        /// C3 — yalnızca B5'te başka uygulama denemiş kullanıcıya gösterilir.
        /// Tarif edilen başarısızlık onun kendi hikâyesi; denememişe anlamsız gelir.
        /// C3 **grafik taşımaz** (ürün sahibi kararı, 2026-09-08). Karşılaştırma
        /// iki sütuna alındı: eğri, iki yaklaşımın farkını zaman ekseninde
        /// anlatmaya çalışırken kaçınılmaz olarak bir sonuç eğrisi gibi
        /// okunuyordu ve altına eklenen "bu bir vaat değil" notu ekranın en uzun
        /// cümlesiydi. Yan yana iki sütun aynı farkı tek bakışta, hiçbir sayı
        /// ima etmeden gösteriyor.
        static let libraryComparisonHeadline: LocalizedStringResource =
            .onboardingLibraryComparisonHeadline
        static let libraryComparisonTheirsTitle: LocalizedStringResource = .onboardingLibraryComparisonTheirsTitle
        static let libraryComparisonOursTitle: LocalizedStringResource = .onboardingLibraryComparisonOursTitle
        /// İki dizi **satır satır eşleşir**: aynı indeksteki iki metin aynı
        /// satırda yan yana durur ve aynı şeyin iki hâlini anlatır. Uzunlukları
        /// eşit olmalı; biri değişirse karşılığı da değişir.
        static let libraryComparisonTheirs: [LocalizedStringResource] = [
            .onboardingLibraryComparisonTheirs1,
            .onboardingLibraryComparisonTheirs2,
            .onboardingLibraryComparisonTheirs3,
            .onboardingLibraryComparisonTheirs4,
        ]
        static let libraryComparisonOurs: [LocalizedStringResource] = [
            .onboardingLibraryComparisonOurs1,
            .onboardingLibraryComparisonOurs2,
            .onboardingLibraryComparisonOurs3,
            .onboardingLibraryComparisonOurs4,
        ]
        /// Kapanış: sütunların söylediğini tek cümlede toplar. Sayı vermez —
        /// "rakamla görürsün" ölçümün yapılacağını söyler, sonucunu değil.
        static let libraryComparisonClosing: LocalizedStringResource =
            .onboardingLibraryComparisonClosing

        /// C4 — aşırı vaat vermemek erken churn'ü düşürür ve 7. gün paywall'ını
        /// sürpriz olmaktan çıkarıp beklenen bir kilometre taşına çevirir.
        /// Adın kullanıldığı ikinci yer. Bu ekranda kullanıcıya hoşuna gitmeyecek
        /// bir şey söylüyoruz ("ilk günlerde fark hissetmeyeceksin"); isimle
        /// seslenmek cümleyi kişisel ve dürüst tutuyor.
        static func honestExpectationHeadline(name: String?) -> LocalizedStringResource {
            guard let name else { return .onboardingHonestExpectationHeadline1 }
            return .onboardingHonestExpectationHeadline2(name)
        }
        static let honestExpectationEarlyDays: LocalizedStringResource =
            .onboardingHonestExpectationEarlyDays
        static let honestExpectationTimeline: LocalizedStringResource =
            .onboardingHonestExpectationTimeline
        static let honestExpectationMeasurement: LocalizedStringResource =
            .onboardingHonestExpectationMeasurement

        /// C4 süreç grafiği. Dikey eksen bilinçli olarak sayısızdır: çizgiler
        /// sonuç değil, iki yaklaşımın zaman içindeki ritmini anlatır.
        ///
        /// Grafik kompaktlaştırıldığında dönüm etiketi ve alt not kaldırıldı
        /// (ürün sahibi kararı, 2026-09-08): ekranda zaten üç cümle var, grafiğin
        /// çevresindeki dört metin katmanı onlarla yarışıyordu. Dönüm noktasını
        /// kesik dikey çizgi gösteriyor, sözünü `honestExpectationTimeline`
        /// cümlesi söylüyor.
        static let expectationOtherAppsLabel: LocalizedStringResource = .onboardingExpectationOtherAppsLabel
        static let expectationPatikaLabel: LocalizedStringResource = .onboardingExpectationPatikaLabel
        static let expectationStartCaption: LocalizedStringResource = .onboardingExpectationStartCaption
        static let expectationEndCaption: LocalizedStringResource = .onboardingExpectationEndCaption
        static let expectationChartAccessibilityLabel: LocalizedStringResource = .onboardingExpectationChartAccessibilityLabel

        // MARK: D — Baseline ölçüm (PRD-Ek Onboarding §5)

        /// D0. Soru sayısı metne gömülü değil, `MeasurementLibrary`den geliyor:
        /// madde listesi değiştiğinde cümle de değişsin, kullanıcıya yanlış bir
        /// sayı söylemeyelim.
        static func measurementIntroHeadline(_ count: Int) -> LocalizedStringResource {
            .onboardingMeasurementIntroHeadline(count)
        }
        /// Ölçümün gerekçesi. Sorunun **neden** sorulduğunu bilmeyen kullanıcı
        /// form dolduruyor gibi hisseder ve terk eder.
        static let measurementIntroPurpose: LocalizedStringResource = .onboardingMeasurementIntroPurpose
        /// "Doğru cevap yok" cümlesi ölçüm kaygısını kesen kısım; ölçüm bir sınav
        /// değil, kullanıcının kendi zemini.
        static let measurementIntroEffort: LocalizedStringResource =
            .onboardingMeasurementIntroEffort
        static let measurementIntroCTA: LocalizedStringResource = .onboardingMeasurementIntroCTA

        // MARK: E — Tercihler (PRD-Ek Onboarding §6)

        /// E1. Saat cümlenin içinde geçiyor çünkü ekranın işi bir **öneriyi
        /// onaylatmak**, boş bir alan doldurtmak değil.
        static func reminderHeadline(_ time: String) -> LocalizedStringResource {
            .onboardingReminderHeadline(time)
        }
        /// H2. Saat cümlenin içinde: izin, ne alacağını görmüş kullanıcıdan isteniyor.
        static func notificationPrimingHeadline(_ time: String) -> LocalizedStringResource {
            .notificationPrimingHeadline(time)
        }
        static let reminderAccept: LocalizedStringResource = .onboardingReminderAccept
        static let reminderChange: LocalizedStringResource = .onboardingReminderChange
        static let reminderPickerLabel: LocalizedStringResource = .onboardingReminderPickerLabel

        // MARK: F — Üretim ve teslim (PRD-Ek Onboarding §7)

        /// F1. Tek cümle, tek fiil. "Lütfen bekleyin" demiyoruz — bekleyen
        /// kullanıcı değil, kurulan bir şey var.
        static let generationHeadline: LocalizedStringResource = .onboardingGenerationHeadline

        /// F2. Akışın karşılığının verildiği cümle; adın kullanıldığı üçüncü ve
        /// son yer (diğerleri C1 ve C4).
        static func roadmapHeadline(name: String?) -> LocalizedStringResource {
            guard let name else { return .onboardingRoadmapHeadline1 }
            return .onboardingRoadmapHeadline2(name)
        }
        /// "21 adım · günde 10 dakika". Sayılar **kullanıcının kendi seçimi ve
        /// programın yapısı** — uydurulmuş bir sonuç değil, sayı yasağının
        /// kapsamına girmiyor.
        static func roadmapMeta(steps: Int, minutes: Int) -> LocalizedStringResource {
            .onboardingRoadmapMeta(steps, minutes)
        }
        static func dayLabel(_ range: ClosedRange<Int>) -> LocalizedStringResource {
            range.lowerBound == range.upperBound
                ? .onboardingDayLabel1(range.lowerBound)
                : .onboardingDayLabel2(range.lowerBound, range.upperBound)
        }
        static let roadmapFirstMeasurement: LocalizedStringResource = .onboardingRoadmapFirstMeasurement
        static let roadmapMeasurement: LocalizedStringResource = .onboardingRoadmapMeasurement
        /// Ölçüm satırının vaadi: **karşılaştırma** vaat ediyor, sonuç değil.
        /// "Ne kadar iyileşeceğini göreceksin" deseydi sonuç vaat etmiş olurduk.
        static let roadmapMeasurementDescription: LocalizedStringResource =
            .onboardingRoadmapMeasurementDescription

        static let commitmentHoldToStart: LocalizedStringResource = .commitmentHoldToStart
        static let roadmapContinue: LocalizedStringResource = .onboardingRoadmapContinue
        static let commitmentDayOneTransition: LocalizedStringResource = .commitmentDayOneTransition
        static let signatureClear: LocalizedStringResource = .commitmentClearSignature
        static let signatureSimpleMark: LocalizedStringResource = .commitmentSimpleMark
        static let signatureDrawHint: LocalizedStringResource = .commitmentDrawHint
        static let signatureSaveError: LocalizedStringResource = .commitmentSaveError

        /// D1'in pasif CTA metni. Kova listelerinde "Birini seçelim" kullanılıyor;
        /// şiddet ölçeğinde seçilecek bir liste yok, dokunulacak bir yer var.
        static let pickPointCTA: LocalizedStringResource = .onboardingPickPointCTA
    }

    /// G1 — ilk oturum (PRD-Ek Onboarding §8). Sakin kademe: bu ekranda
    /// kutlama, alkış ve "harika gidiyorsun" yok. Kullanıcı bir şey yapmıyor,
    /// bir yerde duruyor.
    enum Session {
        static let preparing: LocalizedStringResource = .sessionPreparing
        /// Sesin gelmesi bekleniyor. Gizlenmiyor ama özür de dilenmiyor.
        static let audioPreparing: LocalizedStringResource = .sessionAudioPreparing
        /// Kullanıcının kendi cümlesinden hemen önce okunan çerçeve.
        static let ownWordsFraming: LocalizedStringResource = .sessionOwnWordsFraming
        static let pause: LocalizedStringResource = .sessionPause
        static let resume: LocalizedStringResource = .sessionResume
        /// Oturumdan çıkış. "İptal" değil, "vazgeç" değil.
        static let leave: LocalizedStringResource = .sessionLeave
        /// Sarma düğmeleri görünür metin taşımaz; VoiceOver bunu okur.
        static let skipBackward: LocalizedStringResource = .sessionSkipBackward
        static let skipForward: LocalizedStringResource = .sessionSkipForward
        /// Duraklatıldığında sahnenin altındaki tek satır. Süre yok, uyarı yok.
        static let pausedNote: LocalizedStringResource = .sessionPausedNote
        /// Oturum ekranının üst satırı.
        static func stepEyebrow(day: Int, title: String) -> LocalizedStringResource {
            .sessionStepEyebrow(day, title)
        }

        // MARK: G2 — Oturum sonu (PRD-Ek Onboarding §8)
        //
        // Kutlama şiddeti 1/5. Konfeti yok, rozet yok, "harika iş" yok.
        // Söylenen şey yapılan şey: bir adım atıldı, yolun geri kalanı duruyor.

        static let completedHeadline: LocalizedStringResource = .sessionCompletedHeadline
        /// Yarıda bırakıldığında. **"Tamam" denmiyor** — olmayan bir şeyi
        /// olmuş göstermek, ölçtüğünü iddia eden bir üründe ilk yalan olurdu.
        /// Ama suçlama da yok: yarıda bırakmak bir hata değil.
        static let leftEarlyHeadline: LocalizedStringResource = .sessionLeftEarlyHeadline

        /// "Yolunda 20 adım daha var. Yarın 22:30'da buradayız."
        static func completedBody(remaining: Int, time: String) -> LocalizedStringResource {
            .sessionCompletedBody(remaining, time)
    }

        /// Yarıda bırakanda kalan adım sayısı **yazılmıyor**: bitirmemiş birine
        /// "20 adım daha var" demek, kalan yolu bir borç gibi okutuyor.
        static func leftEarlyBody(time: String) -> LocalizedStringResource {
            .sessionLeftEarlyBody(time)
        }

        static let completedCTA: LocalizedStringResource = .sessionCompletedCTA
        static let reflectionHint: LocalizedStringResource = .sessionReflectionHint
        static let reflectionPlaceholder: LocalizedStringResource = .sessionReflectionPlaceholder
        static let reflectionSave: LocalizedStringResource = .sessionReflectionSave
        static let reflectionSkip: LocalizedStringResource = .sessionReflectionSkip
        static let reflectionError: LocalizedStringResource = .sessionReflectionError

        /// Sunucudan içerik gelmediğinde. Jenerik ama dürüst — uydurma bir
        /// kişiselleştirme cümlesi yazmaktansa sade bir açılış.
        static let fallbackStepTitle: LocalizedStringResource = .sessionFallbackStepTitle
        static let fallbackOpening: LocalizedStringResource = .sessionFallbackOpening
        static let fallbackClosing: LocalizedStringResource = .sessionFallbackClosing
    }

    /// "Yolum" sekmesi — onboarding sonrası günlük adım.
    ///
    /// Ton kademesi 🟠 Sakin: harita, ölçüm ve oturumla aynı. Kutlama yok,
    /// "streak" yok, kaçırılan gün için tek kelime yok — kaçırılan gün hiçbir
    /// şeyi geri almıyor (Değiştirilemez kurallar: gamification yasağı).
    enum Path {
        static let currentLocation: LocalizedStringResource = .pathCurrentLocation
        static let expandDetails: LocalizedStringResource = .pathExpandDetails
        static let collapseDetails: LocalizedStringResource = .pathCollapseDetails
        static let detailsExpanded: LocalizedStringResource = .pathDetailsExpanded
        static let detailsCollapsed: LocalizedStringResource = .pathDetailsCollapsed
        static let screenTitle: LocalizedStringResource = .pathScreenTitle
        static let readyNote: LocalizedStringResource = .pathReadyNote
        static let loading: LocalizedStringResource = .pathLoading
        /// Adım satırının başlığı. Sayaç değil, adımın kendi adı yanında duran
        /// sade bir işaret.
        static func stepLabel(day: Int) -> LocalizedStringResource { .pathStepLabel(day) }
        /// Sıradaki adım hazır. "Devam et" değil — ürünün kendi kelimesi.
        static let continueCTA: LocalizedStringResource = .pathContinueCTA
        static let startCTA: LocalizedStringResource = .pathStartCTA
        /// Yolun sonu. Kutlama değil, bilgi: sonuç ekranı ayrı bir iş.
        static let finishedHeadline: LocalizedStringResource = .pathFinishedHeadline
        static let finishedBody: LocalizedStringResource =
            .pathFinishedBody
        static let loadError: LocalizedStringResource =
            .pathLoadError
        static let retry: LocalizedStringResource = .pathRetry
        /// Adım bitti, ekran kapanıyor.
        static let doneCTA: LocalizedStringResource = .pathDoneCTA
        /// Sırası gelmemiş adım. **Ceza dili yok**: kapalı olan şey adımın
        /// kendisi değil, bugün dinlenebilmesi.
        static let lockedHint: LocalizedStringResource = .pathLockedHint
        static let lockedAccessibility: LocalizedStringResource = .pathLockedAccessibility
        /// Tamamlanmış adım yeniden dinlenebilir — bitmiş bir şeyi tekrar
        /// açmak bir şeyi geri almaz.
        static let replayCTA: LocalizedStringResource = .pathReplayCTA
        static let completedNote: LocalizedStringResource = .pathCompletedNote
        static let measurementNote: LocalizedStringResource = .pathMeasurementNote
        /// Ölçüm gününün kartında, adımdan sonra ne olacağını önceden söyleyen
        /// satır. Sürpriz bir anket, ölçümü bir tuzağa çevirirdi.
        static let measurementNotice: LocalizedStringResource =
            .pathMeasurementNotice
    }

    /// Her ölçüm ekranının altında sabit (PRD §8.1).
    static let clinicalDisclaimer: LocalizedStringResource =
        .clinicalDisclaimer

    /// Bildirim metinleri (Ton eki §5.2).
    ///
    /// **Asla** path adını veya sorunu içermez. Kullanıcının telefonuna bakan biri,
    /// onun neyle uğraştığını öğrenmemeli.
    enum Notification {
        static let dailyStep: LocalizedStringResource = .notificationDailyStep
        static let missedOneDay: LocalizedStringResource = .notificationMissedOneDay
        static let missedFewDays: LocalizedStringResource =
            .notificationMissedFewDays
        static let microOffer: LocalizedStringResource =
            .notificationMicroOffer
        static let pathWaiting: LocalizedStringResource = .notificationPathWaiting
    }
}
