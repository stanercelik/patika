import Foundation

/// Mikrometin kütüphanesi — Ton eki §3.
///
/// Metinler `String Catalog`'a çıkarılabilsin diye `LocalizedStringResource` olarak
/// tanımlanır. PRD-Ek Onboarding §14: nihai hedef bunların remote config üzerinden
/// yönetilmesi — bir kelime değişikliği için mağaza incelemesi beklenemez.
enum Copy {

    enum Auth {
        static let returningLink: LocalizedStringResource = "Zaten hesabım var"
        static let returningTitle: LocalizedStringResource = "Hesabına dön"
        static let returningBody: LocalizedStringResource =
            "Apple veya Google ile devam edebilirsin."
        static let apple: LocalizedStringResource = "Apple ile devam et"
        static let google: LocalizedStringResource = "Google ile devam et"
        static let notNow: LocalizedStringResource = "Şimdilik değil"
        static let linkTitle: LocalizedStringResource = "İlerlemeni kaydedelim mi?"
        static let linkBody: LocalizedStringResource = """
            Yolun ve ölçümlerin bu hesapta durur. Apple veya Google hesabını bağlarsan başka bir cihazdan geri dönebilirsin.
            """
        static let skipLink: LocalizedStringResource = "Şimdilik geç"
        static let failed: LocalizedStringResource =
            "Bağlantı kurulamadı. Bu senin yüzünden değil; cihazındaki ilerleme olduğu gibi duruyor."
        static let sessionMissing: LocalizedStringResource =
            "Oturum bulunamadı. Cihazındaki ilerleme kaybolmadı; yeniden deneyebilirsin."
        static let identityAlreadyLinked: LocalizedStringResource =
            "Bu hesap başka bir Patika yoluna bağlı. Buradaki ilerleme kaybolmadı."
        static let noSavedPath: LocalizedStringResource =
            "Bu hesapta tamamlanmış bir Patika yolu bulamadık. Buradaki ilerleme kaybolmadı."
        static let working: LocalizedStringResource = "Bağlantı kuruluyor"
    }

    /// Buton metinleri standart değil, ürüne özeldir (Ton eki §3.4).
    enum Button {
        /// "Başla" değil — metafor tutarlılığı.
        static let start: LocalizedStringResource = "Yola çık"
        /// "Devam et" değil — kayıp değil süreklilik vurgusu.
        static let resume: LocalizedStringResource = "Kaldığın yerden"
        /// "İptal" değil — reddetmeyi suçsuzlaştırır.
        static let cancel: LocalizedStringResource = "Şimdilik değil"
        /// "Atla" değil — "atlamak" kalıcı, "geçmek" geçici.
        static let skip: LocalizedStringResource = "Bugün geç"
        /// Onboarding sorularının çıkışı. Aynı gerekçe: geçmek geçicidir,
        /// kullanıcı isterse geri dönüp cevaplayabilir.
        static let skipQuestion: LocalizedStringResource = "Bu soruyu geç"
        /// "Kaydet" değil — sahiplik.
        static let save: LocalizedStringResource = "Bende kalsın"
        /// "Bitir" değil — off-ramp tonu.
        static let finish: LocalizedStringResource = "Burada duralım"
        /// "Tekrar dene" değil — yumuşak.
        static let retry: LocalizedStringResource = "Bir daha bakalım"
        static let understood: LocalizedStringResource = "Anladım"
        static let next: LocalizedStringResource = "Devam"
    }

    /// Boş durumlar (Ton eki §3.1). Hiçbirinde şaka yok, hiçbirinde suçlama yok.
    /// "Acelesi yok" cümlesi ürünün imzasıdır.
    enum Empty {
        static let noPath: LocalizedStringResource =
            "Burası şimdilik boş. Bir şey anlatmaya hazır olduğunda buradayız."
        static let noBadges: LocalizedStringResource =
            "İlk patikanı bitirdiğinde burada bir şey olacak. Acelesi yok."
        static let noSavedSessions: LocalizedStringResource =
            "Bir patikayı tamamladığında, sana ait kalıcı bir kayıt burada duracak."
        static let noSearchResults: LocalizedStringResource =
            "Bunu bulamadık. Ama belki aradığın şey aşağıdakilerden biridir."
        static let noMeasurements: LocalizedStringResource =
            "İlk ölçümünü yaptığında burada bir çizgi belirmeye başlayacak."
    }

    /// Hata durumları (Ton eki §3.2).
    ///
    /// Her metinde "kaybolmadı / senin yüzünden değil" ifadesi geçer: kaygılı kullanıcı
    /// hatayı otomatik olarak kendine mal eder, bunu her seferinde kesiyoruz.
    enum Error {
        static let offline: LocalizedStringResource =
            "Bağlantı gitti. Merak etme — indirdiğin oturumlar çevrimdışı da çalışıyor."
        static let audioFailed: LocalizedStringResource =
            "Ses yüklenemedi. Tekrar deneyelim mi, yoksa şimdilik metin olarak mı okuyalım?"
        static let pathGenerationFailed: LocalizedStringResource =
            "Bir şeyler ters gitti, bizim tarafımızda. Yazdıkların kayboldu değil — tekrar deniyoruz."
        static let paymentFailed: LocalizedStringResource =
            "Ödeme geçmedi. Yolun olduğu gibi duruyor, hiçbir şey kaybolmadı."
        static let server: LocalizedStringResource =
            "Şu an bir sorun yaşıyoruz. Bu senin yüzünden değil ve birazdan düzelecek."
    }

    /// Path üretimi sırasında sırayla gösterilir (Ton eki §3.3, Onboarding F1).
    ///
    /// Espri yok. Bu an ciddi — kullanıcı az önce derdini anlattı.
    enum Loading {
        static let steps: [LocalizedStringResource] = [
            "Yazdıklarını okuyorum...",
            "Sana uygun adımları seçiyorum...",
            "Yolu sıraya diziyorum...",
            "Neredeyse hazır.",
        ]
        /// Keşfet sekmesi Oyuncu — Oyuncu kademesinde — burada hafifleyebilir.
        static let discover: LocalizedStringResource = "Rafları karıştırıyoruz..."
    }

    /// Dönüş ve kaçırılan gün (PRD §7.5). Suçluluk dili yok, "seni özledik" yok.
    enum Returning {
        static let afterBreak: LocalizedStringResource =
            "Buradasın. Kaldığın yerden devam edelim."
        static let afterLongBreak: LocalizedStringResource =
            "Bir ara buradaydın. Ne zaman istersen."
    }

    /// Onboarding metinleri — PRD-Ek Onboarding §2.
    enum Onboarding {
        // A1 — Kanca. Özellik listelemez, sonucu satar.
        static let welcomeHeadline: LocalizedStringResource = "Sonu olan bir yol."
        static let welcomeBody: LocalizedStringResource = """
            Derdini anlat, sana özel bir program çıkaralım. \
            21 gün sonra neyin değiştiğini birlikte görelim.
            """
        static let welcomeCTA: LocalizedStringResource = "Başlayalım"
        static let firstSessionHeadline: LocalizedStringResource = "İlk adımın."
        static let firstSessionBody: LocalizedStringResource =
            "Şimdi birlikte kısa bir duruş yapacağız."
        static let firstSessionComplete: LocalizedStringResource = "İlk adımı tamamla"

        // MARK: Kimlik — akışın girişi (PRD'de yok, ürün sahibi kararı)

        /// Ad sorusu. "Adın ne?" değil "nasıl hitap edelim": kullanıcı takma ad
        /// da verebilir, kısaltma da — ürünün istediği kimlik değil, seslenme
        /// biçimi.
        static let nameHeadline: LocalizedStringResource = "Sana nasıl hitap edelim?"
        /// Ne için kullanıldığını söylüyoruz ve boş bırakmanın serbest olduğunu
        /// aynı cümlede yazıyoruz — kaygılı kullanıcı zorunlu alan görünce çıkar.
        static let nameHint: LocalizedStringResource =
            "Yalnızca sana seslenirken kullanıyoruz. Boş bırakabilirsin."
        static let namePlaceholder: LocalizedStringResource = "Adın"
        static let nameSkip: LocalizedStringResource = "İsim vermek istemiyorum"

        static let genderHeadline: LocalizedStringResource = "Kendini nasıl tanımlıyorsun?"
        static let ageHeadline: LocalizedStringResource = "Kaç yaşındasın?"
        /// Cinsiyet ve yaş ekranlarının ortak notu.
        ///
        /// Sorduğumuz her şeyin görünür bir karşılığı olmalı; bu ikisinin yok ve
        /// bunu **saklamıyoruz**. Karşılığı olmayan bir soruyu varmış gibi
        /// sunmak, akışın geri kalanındaki dürüstlük iddiasını zayıflatırdı.
        static let identityStatsNote: LocalizedStringResource =
            "Bu cevap programını değiştirmiyor — kimin kullandığını bilmek için soruyoruz."

        // A2 — İlk soru, hemen.
        static let categoriesHeadline: LocalizedStringResource = "Seni buraya ne getirdi?"
        static let categoriesHint: LocalizedStringResource = "En fazla iki tane seçebilirsin."
        /// Pasif CTA metni — ne eksik olduğunu suçlamadan söyler. A2 ve tek
        /// seçimlik B ekranlarının hepsinde aynı cümle: kullanıcı bir kez
        /// öğrendiği kalıbı her ekranda tanır.
        static let chooseOneCTA: LocalizedStringResource = "Birini seçelim"

        // MARK: B — Problem keşfi (PRD-Ek Onboarding §3)

        /// B1 — akışın en değerli ekranı. Bu metin F2'de kullanıcıya geri yansıtılır
        /// ve G1'de kendi kelimeleriyle seslendirilir; aha momentinin yakıtı burada.
        static let problemTextHeadline: LocalizedStringResource =
            "Kendi cümlelerinle anlatır mısın?"
        /// "Kimse okumuyor" cümlesi gizlilik vaadinin kendisi (PRD §13.5) —
        /// süsleme değil, doldurma oranını taşıyan kısım.
        static let problemTextHint: LocalizedStringResource = """
            Ne kadar kısa ya da uzun istersen. Bu metni kimse okumuyor — \
            sadece sana bir yol çizmek için kullanılıyor.
            """
        /// Atlama görünür ama ikincil: teşvik ediyoruz, zorlamıyoruz.
        static let problemTextSkip: LocalizedStringResource = "Yazmak istemiyorum"

        static let durationHeadline: LocalizedStringResource = "Bu ne kadar zamandır böyle?"

        static let timingHeadline: LocalizedStringResource =
            "Genelde ne zaman ortaya çıkıyor?"
        /// Sorunun karşılığını hemen söylüyoruz — cevabın nereye gittiğini
        /// göstermek anket hissini kırar.
        static let timingHint: LocalizedStringResource =
            "Hatırlatma saatini buna göre öneriyoruz. Sonra değiştirebilirsin."

        static let avoidanceHeadline: LocalizedStringResource =
            "Bu yüzden yapmaktan kaçındığın bir şey var mı?"
        static let avoidanceHint: LocalizedStringResource =
            "Örneğin: bir konuşmayı ertelemek, bir yere gitmemek, bir işe başlamamak."
        static let avoidancePlaceholder: LocalizedStringResource =
            "Bir türlü başlayamadığım şey..."
        static let avoidanceSkip: LocalizedStringResource = "Yok / emin değilim"

        static let attemptsHeadline: LocalizedStringResource = "Daha önce ne denedin?"
        static let attemptsHint: LocalizedStringResource = "Birden fazla seçebilirsin."
        /// Terapi devam ediyorsa gösterilir. Ürün terapinin yerine geçme imasında
        /// **asla** bulunmaz (PRD §4) — bu cümle o sınırı açıkça çiziyor.
        static let attemptsTherapyNote: LocalizedStringResource =
            "Terapinle birlikte kullanabileceğin bir şey kuralım."

        static let moodHeadline: LocalizedStringResource = "Şu an, tam bu anda nasılsın?"
        /// Ölçüm bölümüne ısınma; bu ölçek günlük ön kontrolün aynısı.
        static let moodHint: LocalizedStringResource =
            "Şu anki hâlin, arka planın rengine yansır."

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
            guard let name else { return "Anladığım kadarıyla:" }
            return "Anladığım kadarıyla, \(name):"
        }
        static let mirroringDurationLead: LocalizedStringResource = "Bu"
        static let mirroringDurationTail: LocalizedStringResource = "sürüyor."
        static let mirroringAvoidanceLead: LocalizedStringResource =
            "Bu yüzden kaçındığın bir şey de var:"
        /// Kapanış: durumu normalleştirir ama "geçecek" demez — vaat değil, çerçeve.
        static let mirroringClosing: LocalizedStringResource =
            "Bu, en sık karşılaştığımız örüntülerden biri. Ve üzerine çalışılabilir bir şey."

        /// C2 — sosyal kanıt, **sayısız**. Kategori cümlesi
        /// `ProblemCategory.commonalityLine`dan gelir; sayı kuralı orada yazılı.
        static let notAloneHeadline: LocalizedStringResource = "Bu çok yaygın."
        static let notAloneResearchLine: LocalizedStringResource =
            "İyi haber şu: bu, üzerine çalışılabilir bir alan — ve nasıl çalışıldığı biliniyor."

        /// C3 — yalnızca B5'te başka uygulama denemiş kullanıcıya gösterilir.
        /// Tarif edilen başarısızlık onun kendi hikâyesi; denememişe anlamsız gelir.
        /// C3 **grafik taşımaz** (ürün sahibi kararı, 2026-09-08). Karşılaştırma
        /// iki sütuna alındı: eğri, iki yaklaşımın farkını zaman ekseninde
        /// anlatmaya çalışırken kaçınılmaz olarak bir sonuç eğrisi gibi
        /// okunuyordu ve altına eklenen "bu bir vaat değil" notu ekranın en uzun
        /// cümlesiydi. Yan yana iki sütun aynı farkı tek bakışta, hiçbir sayı
        /// ima etmeden gösteriyor.
        static let libraryComparisonHeadline: LocalizedStringResource =
            "Daha önce denediysen tanıdık gelecek:"
        static let libraryComparisonTheirsTitle: LocalizedStringResource = "Kütüphane"
        static let libraryComparisonOursTitle: LocalizedStringResource = "Patika"
        /// İki dizi **satır satır eşleşir**: aynı indeksteki iki metin aynı
        /// satırda yan yana durur ve aynı şeyin iki hâlini anlatır. Uzunlukları
        /// eşit olmalı; biri değişirse karşılığı da değişir.
        static let libraryComparisonTheirs: [LocalizedStringResource] = [
            "Yüzlerce başlık",
            "Nereden başlayacağın belirsiz",
            "Birkaç gün, sonra unutulur",
            "İşe yaradı mı, belirsiz",
        ]
        static let libraryComparisonOurs: [LocalizedStringResource] = [
            "Tek bir yol",
            "Sırası belli adımlar",
            "Sonu olan bir program",
            "Başında ve sonunda ölçüm",
        ]
        /// Kapanış: sütunların söylediğini tek cümlede toplar. Sayı vermez —
        /// "rakamla görürsün" ölçümün yapılacağını söyler, sonucunu değil.
        static let libraryComparisonClosing: LocalizedStringResource =
            "Sonunda ne değiştiğini rakamla görüyorsun."

        /// C4 — aşırı vaat vermemek erken churn'ü düşürür ve 7. gün paywall'ını
        /// sürpriz olmaktan çıkarıp beklenen bir kilometre taşına çevirir.
        /// Adın kullanıldığı ikinci yer. Bu ekranda kullanıcıya hoşuna gitmeyecek
        /// bir şey söylüyoruz ("ilk günlerde fark hissetmeyeceksin"); isimle
        /// seslenmek cümleyi kişisel ve dürüst tutuyor.
        static func honestExpectationHeadline(name: String?) -> LocalizedStringResource {
            guard let name else { return "Baştan söyleyelim:" }
            return "Baştan söyleyelim, \(name):"
        }
        static let honestExpectationEarlyDays: LocalizedStringResource =
            "İlk 2–3 gün muhtemelen büyük bir fark hissetmeyeceksin. Bu normal."
        static let honestExpectationTimeline: LocalizedStringResource =
            "Değişim genelde 7–10. günde fark edilmeye başlıyor."
        static let honestExpectationMeasurement: LocalizedStringResource =
            "Zaten ilk ölçümünü 7. günde yapacağız — o zaman rakamlarla göreceksin."

        /// C4 süreç grafiği. Dikey eksen bilinçli olarak sayısızdır: çizgiler
        /// sonuç değil, iki yaklaşımın zaman içindeki ritmini anlatır.
        ///
        /// Grafik kompaktlaştırıldığında dönüm etiketi ve alt not kaldırıldı
        /// (ürün sahibi kararı, 2026-09-08): ekranda zaten üç cümle var, grafiğin
        /// çevresindeki dört metin katmanı onlarla yarışıyordu. Dönüm noktasını
        /// kesik dikey çizgi gösteriyor, sözünü `honestExpectationTimeline`
        /// cümlesi söylüyor.
        static let expectationOtherAppsLabel: LocalizedStringResource = "Diğer uygulamalar"
        static let expectationPatikaLabel: LocalizedStringResource = "Patika"
        static let expectationStartCaption: LocalizedStringResource = "Başlangıç"
        static let expectationEndCaption: LocalizedStringResource = "21. gün"
        static let expectationChartAccessibilityLabel: LocalizedStringResource = """
            Süreç grafiği. Diğer uygulamalar çizgisi dalgalanarak başlangıçtan daha aşağıda bitiyor. \
            Patika çizgisi ilk sekiz gün küçük adımlarla ilerliyor, ardından giderek hızlanarak yükseliyor.
            """

        // MARK: D — Baseline ölçüm (PRD-Ek Onboarding §5)

        /// D0. Soru sayısı metne gömülü değil, `MeasurementLibrary`den geliyor:
        /// madde listesi değiştiğinde cümle de değişsin, kullanıcıya yanlış bir
        /// sayı söylemeyelim.
        static func measurementIntroHeadline(_ count: Int) -> LocalizedStringResource {
            "Şimdi \(count) kısa soru."
        }
        /// Ölçümün gerekçesi. Sorunun **neden** sorulduğunu bilmeyen kullanıcı
        /// form dolduruyor gibi hisseder ve terk eder.
        static let measurementIntroPurpose: LocalizedStringResource = """
            Bunlar senin başlangıç noktan. Aynılarını 7. günde tekrar soracağız — \
            ne değiştiğini görmek için.
            """
        /// "Doğru cevap yok" cümlesi ölçüm kaygısını kesen kısım; ölçüm bir sınav
        /// değil, kullanıcının kendi zemini.
        static let measurementIntroEffort: LocalizedStringResource =
            "Yaklaşık bir dakika sürüyor. Doğru cevap yok."
        static let measurementIntroCTA: LocalizedStringResource = "Başlayalım"

        // MARK: E — Tercihler (PRD-Ek Onboarding §6)

        /// E1. Saat cümlenin içinde geçiyor çünkü ekranın işi bir **öneriyi
        /// onaylatmak**, boş bir alan doldurtmak değil.
        static func reminderHeadline(_ time: String) -> LocalizedStringResource {
            "Günlük adımın için \(time)'u ayarladım."
        }
        static let reminderAccept: LocalizedStringResource = "Uygun"
        static let reminderChange: LocalizedStringResource = "Başka saat seç"
        static let reminderPickerLabel: LocalizedStringResource = "Hatırlatma saati"

        static let sessionLengthHeadline: LocalizedStringResource =
            "Adımların ne kadar sürsün?"
        /// Süre gerçekten değişiyor: seçilen uzunluk blok seçimini ve ses
        /// uzunluğunu belirliyor. Bunu söylemek "tiyatro değil" iddiasını
        /// kullanıcıya da gösteriyor.
        static let sessionLengthHint: LocalizedStringResource =
            "Sonra değiştirebilirsin. Adımlar seçtiğin süreye göre kuruluyor."

        static let toneHeadline: LocalizedStringResource = "Sana nasıl bir ses iyi gelir?"
        static let toneHint: LocalizedStringResource =
            "Seslendirmenin dili buna göre değişiyor."

        // MARK: F — Üretim ve teslim (PRD-Ek Onboarding §7)

        /// F1. Tek cümle, tek fiil. "Lütfen bekleyin" demiyoruz — bekleyen
        /// kullanıcı değil, kurulan bir şey var.
        static let generationHeadline: LocalizedStringResource = "Yolun kuruluyor."

        /// F2. Akışın karşılığının verildiği cümle; adın kullanıldığı üçüncü ve
        /// son yer (diğerleri C1 ve C4).
        static func roadmapHeadline(name: String?) -> LocalizedStringResource {
            guard let name else { return "Yolun hazır." }
            return "Yolun hazır, \(name)."
        }
        /// "21 adım · günde 10 dakika". Sayılar **kullanıcının kendi seçimi ve
        /// programın yapısı** — uydurulmuş bir sonuç değil, sayı yasağının
        /// kapsamına girmiyor.
        static func roadmapMeta(steps: Int, minutes: Int) -> LocalizedStringResource {
            "\(steps) adım · günde \(minutes) dakika"
        }
        static func dayLabel(_ range: ClosedRange<Int>) -> LocalizedStringResource {
            range.lowerBound == range.upperBound
                ? "Gün \(range.lowerBound)"
                : "Gün \(range.lowerBound)–\(range.upperBound)"
        }
        static let roadmapFirstMeasurement: LocalizedStringResource = "İlk ölçüm"
        static let roadmapMeasurement: LocalizedStringResource = "Ara ölçüm"
        /// Ölçüm satırının vaadi: **karşılaştırma** vaat ediyor, sonuç değil.
        /// "Ne kadar iyileşeceğini göreceksin" deseydi sonuç vaat etmiş olurduk.
        static let roadmapMeasurementDescription: LocalizedStringResource =
            "Ne değiştiğini rakamla göreceksin"

        /// Basılı tutma jesti görünmez; yazıyla söylenmek zorunda.
        static let holdToStartHint: LocalizedStringResource = "Başlamak için basılı tut"

        /// D1'in pasif CTA metni. Kova listelerinde "Birini seçelim" kullanılıyor;
        /// şiddet ölçeğinde seçilecek bir liste yok, dokunulacak bir yer var.
        static let pickPointCTA: LocalizedStringResource = "Ölçekten bir yer seç"
    }

    /// G1 — ilk oturum (PRD-Ek Onboarding §8). Sakin kademe: bu ekranda
    /// kutlama, alkış ve "harika gidiyorsun" yok. Kullanıcı bir şey yapmıyor,
    /// bir yerde duruyor.
    enum Session {
        static let preparing: LocalizedStringResource = "Başlıyoruz."
        /// Sesin gelmesi bekleniyor. Gizlenmiyor ama özür de dilenmiyor.
        static let audioPreparing: LocalizedStringResource = "Ses hazırlanıyor..."
        /// Kullanıcının kendi cümlesinden hemen önce okunan çerçeve.
        static let ownWordsFraming: LocalizedStringResource = "Kendi cümlelerinle şöyle demiştin:"
        static let pause: LocalizedStringResource = "Duraklat"
        static let resume: LocalizedStringResource = "Devam"
        /// Oturumdan çıkış. "İptal" değil, "vazgeç" değil.
        static let leave: LocalizedStringResource = "Burada duralım"

        // MARK: G2 — Oturum sonu (PRD-Ek Onboarding §8)
        //
        // Kutlama şiddeti 1/5. Konfeti yok, rozet yok, "harika iş" yok.
        // Söylenen şey yapılan şey: bir adım atıldı, yolun geri kalanı duruyor.

        static let completedHeadline: LocalizedStringResource = "İlk adım tamam."
        /// Yarıda bırakıldığında. **"Tamam" denmiyor** — olmayan bir şeyi
        /// olmuş göstermek, ölçtüğünü iddia eden bir üründe ilk yalan olurdu.
        /// Ama suçlama da yok: yarıda bırakmak bir hata değil.
        static let leftEarlyHeadline: LocalizedStringResource = "Bugünlük burada bıraktık."

        /// "Yolunda 20 adım daha var. Yarın 22:30'da buradayız."
        static func completedBody(remaining: Int, time: String) -> LocalizedStringResource {
            "Yolunda \(remaining) adım daha var. Yarın \(time)'da buradayız."
        }

        /// Yarıda bırakanda kalan adım sayısı **yazılmıyor**: bitirmemiş birine
        /// "20 adım daha var" demek, kalan yolu bir borç gibi okutuyor.
        static func leftEarlyBody(time: String) -> LocalizedStringResource {
            "Kaldığın yer duruyor. Yarın \(time)'da buradayız."
        }

        static let completedCTA: LocalizedStringResource = "Devam"

        /// Sunucudan içerik gelmediğinde. Jenerik ama dürüst — uydurma bir
        /// kişiselleştirme cümlesi yazmaktansa sade bir açılış.
        static let fallbackStepTitle: LocalizedStringResource = "İlk adım"
        static let fallbackOpening: LocalizedStringResource = """
            Şimdilik yapman gereken bir şey yok. Birkaç dakika burada duracağız.
            """
        static let fallbackClosing: LocalizedStringResource = """
            Burada bırakıyoruz. Gözlerini açtığında acele etme.
            """
    }

    /// Her ölçüm ekranının altında sabit (PRD §8.1).
    static let clinicalDisclaimer: LocalizedStringResource =
        "Bu bir klinik değerlendirme değildir."

    /// Bildirim metinleri (Ton eki §5.2).
    ///
    /// **Asla** path adını veya sorunu içermez. Kullanıcının telefonuna bakan biri,
    /// onun neyle uğraştığını öğrenmemeli.
    enum Notification {
        static let dailyStep: LocalizedStringResource = "Bugünün adımı hazır."
        static let missedOneDay: LocalizedStringResource = "Bugün devam edelim mi?"
        static let missedFewDays: LocalizedStringResource =
            "Buradayız. Kaldığın yerden devam edebilirsin."
        static let microOffer: LocalizedStringResource =
            "İstersen bugün sadece 2 dakikalık bir versiyon var."
        static let pathWaiting: LocalizedStringResource = "Yolun duruyor, kaybolmadı."
    }
}
