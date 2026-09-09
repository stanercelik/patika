import Foundation

// MARK: - Sorun kategorileri

/// A2 ekranındaki 10 kart (PRD-Ek Onboarding §2.2). Her biri bir palet anahtarıdır.
///
/// `unnamed` kritiktir: kaygının en yaygın hâli isimsiz olanıdır ve bu seçeneği
/// koymamak o kullanıcıyı dışlar.
enum ProblemCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case anxiety, sleep, burnout, focus, anger, selfcrit, social, exam, grief, unnamed

    var id: String { rawValue }

    /// SF Symbol adı.
    ///
    /// **Emoji kullanılmaz** — hiçbir yerde. Emoji çok renkli ve platforma göre
    /// değişken; tek mürekkepli tasarım sistemimizi bozuyor ve ürünün ciddiyetiyle
    /// çelişiyor. SF Symbols monokrom, metin ağırlığıyla eşleşir, Dynamic Type ile
    /// büyür ve VoiceOver'a hazırdır.
    ///
    /// Markaya özel bir ikon setine geçilecekse **yalnızca burası** değişir.
    var icon: String {
        switch self {
        case .anxiety: "wind"
        case .sleep: "moon"
        case .burnout: "flame"
        case .focus: "scope"
        case .anger: "bolt"
        case .selfcrit: "exclamationmark.bubble"
        case .social: "person.2"
        case .exam: "book"
        case .grief: "heart.slash"
        case .unnamed: "questionmark.circle"
        }
    }

    var label: LocalizedStringResource {
        switch self {
        case .anxiety: "Kaygı, huzursuzluk"
        case .sleep: "Uyuyamamak"
        case .burnout: "Tükenmişlik, bitkinlik"
        case .focus: "Odaklanamamak"
        case .anger: "Öfke, sinirlilik"
        case .selfcrit: "Kendime sert davranmak"
        case .social: "Sosyal ortamlar"
        case .exam: "Sınav, performans baskısı"
        case .grief: "Ayrılık, kayıp"
        case .unnamed: "Tam adını koyamıyorum"
        }
    }

    /// B1'deki serbest metin alanının placeholder'ı kategoriye göre değişir
    /// (PRD-Ek Onboarding §3.1) — doldurma oranını ciddi artıran detay.
    var textPlaceholder: LocalizedStringResource {
        switch self {
        case .sleep: "Akşamları yatağa girince zihnim durmuyor..."
        case .burnout: "Sabah kalktığımda zaten yorgunum..."
        case .exam: "Sınav yaklaştıkça çalışmaktan kaçıyorum..."
        case .social: "Kalabalık ortamlara girmeden önce..."
        case .anger: "Küçük şeylere aşırı tepki veriyorum..."
        case .grief: "Aklımdan çıkmıyor ve..."
        case .selfcrit: "Kendime sürekli kızıyorum..."
        case .focus: "Bir işe başlıyorum ama..."
        case .anxiety: "İçimde sürekli bir tedirginlik var..."
        case .unnamed: "Tam olarak ne olduğunu bilmiyorum ama..."
        }
    }

    /// F2 yol haritasındaki path başlığı — **geçici**.
    ///
    /// Gerçek başlık path üretiminden gelir (PRD §9.1): LLM onaylanmış
    /// şablonlardan seçim yapar ve başlığı kullanıcının kendi cümlesine göre
    /// kurar. Ağ katmanı yazılana kadar harita boş başlıkla görünmesin diye
    /// kategori başına bir yedek tutuluyor. Üretim geldiğinde bu tablo silinmez,
    /// **çevrimdışı yedek** olarak kalır.
    var provisionalPathTitle: LocalizedStringResource {
        switch self {
        case .anxiety: "Tedirginliği yavaşlatma"
        case .sleep: "Zihni akşam yavaşlatma"
        case .burnout: "Enerjiyi geri toplama"
        case .focus: "Dikkati toparlama"
        case .anger: "Tepkiyle araya mesafe koyma"
        case .selfcrit: "Kendine yumuşak davranma"
        case .social: "Kalabalıkta rahatlama"
        case .exam: "Baskı altında sakin kalma"
        case .grief: "Kayıpla birlikte yürüme"
        case .unnamed: "Adı konmamışla başlama"
        }
    }

    /// C1'de kullanıcıya geri okunan yüklem — ikinci tekil şahıs, yargısız,
    /// teşhissiz (PRD-Ek Onboarding §4.1).
    ///
    /// Zaman ifadesinden sonra gelir: "Yatağa girdiğinde **zihnin durmuyor.**"
    var mirrorPhrase: LocalizedStringResource {
        switch self {
        case .anxiety: "içindeki tedirginlik yükseliyor"
        case .sleep: "zihnin durmuyor"
        case .burnout: "enerjin bitmiş oluyor"
        case .focus: "dikkatin dağılıyor"
        case .anger: "tepkilerin sertleşiyor"
        case .selfcrit: "kendine sert davranıyorsun"
        case .social: "insanların arasında zorlanıyorsun"
        case .exam: "baskıyı üstünde hissediyorsun"
        case .grief: "aklından çıkmıyor"
        case .unnamed: "kendini iyi hissetmiyorsun"
        }
    }

    /// C2 — "Yalnız değilsin" (PRD-Ek Onboarding §4.2).
    ///
    /// **Bu cümlelerde sayı yoktur ve olmayacak.** PRD bu ekranı kategori düzeyinde
    /// dürüst veriyle tarif ediyor; kaynağı gösterilmemiş bir yaygınlık yüzdesi
    /// uydurmak, uydurma kullanıcı sayısıyla aynı şey. Sayı ancak (a) gerçek
    /// kullanıcı verisi oluştuğunda veya (b) her kategori için atıf verilebilir bir
    /// epidemiyolojik kaynak bulunduğunda eklenir — ikisi de henüz yok.
    var commonalityLine: LocalizedStringResource {
        switch self {
        case .anxiety: "Kaygı, yetişkinlerin en sık yaşadığı zorlanma biçimlerinden biri."
        case .sleep: "Uykuya dalmakta zorlanmak, çoğu insanın hayatının bir döneminde yaşadığı bir şey."
        case .burnout: "Tükenmişlik, uzun süre yüksek tempoda kalan hemen herkesin karşılaştığı bir hâl."
        case .focus: "Dikkatin dağılması, sürekli bölünen bir zihnin olağan tepkisi."
        case .anger: "Öfkenin kolay tetiklenmesi, uzun süre baskı altında kalan insanlarda sık görülür."
        case .selfcrit: "Kendine sert davranmak, en yaygın ve en az konuşulan zorlanmalardan biri."
        case .social: "Sosyal ortamlarda zorlanmak, insanların büyük bölümünün tanıdığı bir his."
        case .exam: "Sınav ve performans baskısı altında zorlanmak, bu süreçten geçen herkesin bildiği bir şey."
        case .grief: "Bir kaybın ardından böyle hissetmek olağan — herkesin geçtiği bir yol."
        case .unnamed: "Adını koyamamak çok yaygın. Zorlanmanın en sık hâli, isimsiz olanı."
        }
    }
}

// MARK: - Kimlik (onboarding girişi)

/// Cinsiyet — **ürünün hiçbir davranışını değiştirmez.**
///
/// Bu bilinçli bir sınır: kategori, ruh hâli ve ölçüm cevapları path'i değiştirir,
/// bu alan değiştirmez. Yalnızca kimin kullandığını bilmek için toplanıyor
/// (ürün sahibi kararı, 2026-09-08). Bir gün path üretimine girecekse bu **ayrı
/// bir karar** olur ve gerekçesi yazılır — "elimizde var" gerekçe değildir.
///
/// "Belirtmek istemiyorum" gerçek bir seçenek ve listede son sırada; olmadığında
/// kullanıcı ya yalan söyler ya ekranı terk eder.
enum Gender: String, CaseIterable, Codable, Sendable, Identifiable {
    case woman, man, other, undisclosed

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .woman: "Kadın"
        case .man: "Erkek"
        case .other: "Başka şekilde tanımlıyorum"
        case .undisclosed: "Belirtmek istemiyorum"
        }
    }
}

/// Yaş aralığı. Doğum tarihi **sorulmuyor**: onboarding'de kesin tarihe ihtiyaç
/// yok ve kesin tarih kimliklendirici bir veri. Bağlayıcı 18+ kontrolü kayıt
/// ekranında (H1) doğum tarihiyle yapılır (PRD §11.4) — buradaki aralık
/// istatistik içindir, kapı değildir.
///
/// Ürün 18+ olduğu için en alt kova 18–24. Yaş da cinsiyet gibi ürünün hiçbir
/// davranışını değiştirmez.
enum AgeRange: String, CaseIterable, Codable, Sendable, Identifiable {
    case eighteenToTwentyFour, twentyFiveToThirtyFour, thirtyFiveToFortyFour
    case fortyFiveToFiftyFour, fiftyFivePlus, undisclosed

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .eighteenToTwentyFour: "18–24"
        case .twentyFiveToThirtyFour: "25–34"
        case .thirtyFiveToFortyFour: "35–44"
        case .fortyFiveToFiftyFour: "45–54"
        case .fiftyFivePlus: "55 ve üzeri"
        case .undisclosed: "Belirtmek istemiyorum"
        }
    }
}

// MARK: - Problem keşfi (B bölümü)

/// B2 — "Bu ne kadar zamandır böyle?" (PRD-Ek Onboarding §3.2)
///
/// "Emin değilim" seçeneği bu ekranın kaçış kapısıdır: B2 atlanabilir olmalı
/// (§10 kaçış tablosu) ama ayrı bir "geç" bağlantısı koymak yerine dürüst bir
/// cevap sunmak daha iyi veri veriyor — atlamak ile bilmemek aynı şey değil.
enum ProblemDuration: String, CaseIterable, Codable, Sendable, Identifiable {
    case fewDays, fewWeeks, months, years, unsure

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .fewDays: "Birkaç gündür"
        case .fewWeeks: "Birkaç haftadır"
        case .months: "Aylardır"
        case .years: "Yıllardır"
        case .unsure: "Emin değilim"
        }
    }

    /// Kronikleşmiş bir şikâyete 7 günlük patika önermek yanlış beklenti kurar
    /// (PRD §9.2). Uzunluk kovası seçimi bu sinyali kullanır.
    var suggestsLongerPath: Bool {
        self == .months || self == .years
    }

    /// C1'de vurgulanarak geri okunur: "Bu **aylardır** sürüyor."
    /// `unsure` için nil — bilmediğini söyleyen kullanıcıya süre atfetmeyiz.
    var mirrorPhrase: LocalizedStringResource? {
        switch self {
        case .fewDays: "birkaç gündür"
        case .fewWeeks: "birkaç haftadır"
        case .months: "aylardır"
        case .years: "yıllardır"
        case .unsure: nil
        }
    }
}

/// B3 — "Genelde ne zaman ortaya çıkıyor?" (PRD-Ek Onboarding §3.3)
///
/// Bu cevabın **görünür bir karşılığı olmak zorunda**: E1'deki varsayılan
/// hatırlatma saatini doğrudan buradan alıyoruz. Sorduğumuz her sorunun
/// kullanıcının gördüğü bir sonucu olmalı, yoksa anket gibi hissettirir.
enum ProblemTiming: String, CaseIterable, Codable, Sendable, Identifiable {
    case morning, daytime, evening, bedtime, noPattern

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .morning: "Sabah uyanınca"
        case .daytime: "Gün içinde"
        case .evening: "Akşama doğru"
        case .bedtime: "Yatağa girince"
        case .noPattern: "Belli bir zamanı yok"
        }
    }

    /// E1'de önerilen hatırlatma saati. Şikâyetin **öncesine** denk gelir:
    /// sorun çıktıktan sonra hatırlatma yapmak geç kalmış oluyor.
    var suggestedReminderHour: Int {
        switch self {
        case .morning: 8
        case .daytime: 13
        case .evening: 19
        case .bedtime: 22
        // Örüntü yoksa akşam saati en yüksek tamamlama oranını veriyor varsayımı;
        // Faz 0 verisiyle doğrulanmalı.
        case .noPattern: 22
        }
    }

    /// E1'de önerilen saatin **gerekçesi**, kullanıcının kendi cevabına atıfla.
    ///
    /// Öneriyi gerekçesiz sunmak "biz böyle uygun gördük" demek olurdu; cevabını
    /// hatırladığımızı göstermek, sorduğumuz şeyin karşılığını da göstermiş
    /// oluyor (PRD-Ek Onboarding §6, E1).
    var reminderReason: LocalizedStringResource {
        switch self {
        case .morning: "\"Sabah uyanınca\" demiştin — güne başlamadan önce iyi çalışıyor."
        case .daytime: "\"Gün içinde\" demiştin — öğle sonrası, yoğunluk dağılmadan."
        case .evening: "\"Akşama doğru\" demiştin — gün kapanmadan biraz önce."
        case .bedtime: "\"Yatağa girince\" demiştin — yatmadan biraz önce iyi çalışıyor."
        case .noPattern: "Belli bir saat söylememiştin; akşam saati çoğu kişide oturuyor."
        }
    }

    /// C1'in ilk cümlesini açan zaman ifadesi:
    /// "**Yatağa girdiğinde** zihnin durmuyor."
    var mirrorPhrase: LocalizedStringResource {
        switch self {
        case .morning: "sabah uyandığında"
        case .daytime: "gün içinde"
        case .evening: "akşama doğru"
        case .bedtime: "yatağa girdiğinde"
        case .noPattern: "belli bir saate bağlı olmadan"
        }
    }
}

/// B5 — "Daha önce ne denedin?" (PRD-Ek Onboarding §3.5)
///
/// Çoklu seçim. İki ürün kuralını taşır: C3 ekranının koşulu ve terapi tonunun
/// tetikleyicisi. Bu yüzden serbest metin değil, kapalı küme.
enum PreviousAttempt: String, CaseIterable, Codable, Sendable, Identifiable {
    case otherApps, youtube, therapyOngoing, therapyPast, breathing, nothing, other

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .otherApps: "Başka meditasyon uygulamaları"
        case .youtube: "YouTube videoları"
        case .therapyOngoing: "Terapi (şu an devam ediyor)"
        case .therapyPast: "Terapi (geçmişte)"
        case .breathing: "Nefes egzersizleri"
        case .nothing: "Hiçbir şey"
        case .other: "Diğer"
        }
    }

    /// C3 ("Neden kütüphane değil, yol") **koşullu** bir ekrandır: kullanıcı başka
    /// bir meditasyon uygulaması denemediyse gösterilmez, çünkü karşılaştırma
    /// yapacağı bir deneyimi yok (PRD-Ek Onboarding §4.3).
    var showsLibraryComparison: Bool {
        self == .otherApps
    }

    /// Terapi devam ediyorsa ürün **asla** terapinin yerine geçme imasında
    /// bulunmaz; ton "birlikte kullanılır"a döner (PRD §4, yasak ifadeler).
    var requiresTherapyAwareTone: Bool {
        self == .therapyOngoing
    }

    /// "Hiçbir şey" diğerleriyle birlikte seçilemez — mantıksal çelişki.
    var isExclusive: Bool {
        self == .nothing
    }
}

/// B6 — "Şu an, tam bu anda nasılsın?" (PRD-Ek Onboarding §3.6)
///
/// **Emoji ölçek değil.** PRD bu ekranı 5'li emoji ölçek olarak tarif ediyor; emoji
/// hiçbir yerde kullanılmıyor (çok renkli, platforma göre değişken, tek mürekkepli
/// tasarım sistemini bozar). Yerine monokrom SF Symbols hava metaforu: aynı beş
/// kademe, aynı tek dokunuş, aynı skorlama.
///
/// Etiketler kasıtlı olarak yargısız — "kötü" değil "ağır". Kullanıcı kendi hâline
/// not vermiyor, tarif ediyor.
enum MoodLevel: Int, CaseIterable, Codable, Sendable, Identifiable {
    case veryHeavy = 1
    case heavy = 2
    case middling = 3
    case okay = 4
    case calm = 5

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .veryHeavy: "cloud.heavyrain"
        case .heavy: "cloud.rain"
        case .middling: "cloud"
        case .okay: "cloud.sun"
        case .calm: "sun.max"
        }
    }

    var label: LocalizedStringResource {
        switch self {
        case .veryHeavy: "Çok ağır"
        case .heavy: "Ağır"
        case .middling: "Ortalarda"
        case .okay: "Fena değil"
        case .calm: "Sakin"
        }
    }

    /// Onboarding'in ilk oturumu (G1) düşük ruh haliyle gelen kullanıcıda daha
    /// kısa ve daha yönlendirici başlar. Ölçüm değil, ısınma sinyali —
    /// baseline skoru D bölümünden gelir (PRD §8.6).
    var suggestsGentlerStart: Bool {
        rawValue <= 2
    }
}

// MARK: - Path

/// Sabit uzunluk kovaları (PRD karar #7). "Sana özel 19 günlük patika" satılamaz;
/// "21 günlük program" satılır. Fiyatlandırma ve beklenti yönetimi bunu gerektirir.
enum PathLength: Int, CaseIterable, Codable, Sendable, Identifiable {
    case week = 7
    case twoWeeks = 14
    case threeWeeks = 21
    case fourWeeks = 28

    var id: Int { rawValue }
    var days: Int { rawValue }

    /// Ölçüm noktalarının denk geldiği gün indeksleri (1 tabanlı).
    var measurementDays: [Int] {
        switch self {
        case .week: [1, 4, 7]
        case .twoWeeks: [1, 7, 14]
        case .threeWeeks, .fourWeeks: [1, 7, 14, days]
        }
    }
}

/// 21 günlük standart ark (PRD §9.3). Zor ve en değerli içerik bilinçli olarak
/// arka yarıdadır — hem pedagojik olarak doğru hem "bu kadarı yeter" hissini geciktirir.
enum PathPhase: String, Codable, Sendable, CaseIterable {
    case relief, awareness, skill, behavior, closing

    var label: LocalizedStringResource {
        switch self {
        case .relief: "Rahatlama"
        case .awareness: "Farkındalık"
        case .skill: "Beceri"
        case .behavior: "Davranış"
        case .closing: "Kapanış"
        }
    }

    /// F2 yol haritasında fazın altına yazılan tek cümle.
    ///
    /// **Bunlar jenerik sürüm.** PRD-Ek Onboarding §7.2 fazların kullanıcının
    /// kendi cevaplarından türetilmesini istiyor ("Zihnini ne hızlandırıyor,
    /// birlikte bakacağız"); o kişiselleştirme path üretimiyle birlikte gelecek
    /// (PRD §9.1). O gün geldiğinde bu metinler **yedek** olarak kalır: üretim
    /// başarısız olursa harita boş satırla değil, doğru ama genel bir cümleyle
    /// görünür.
    var roadmapDescription: LocalizedStringResource {
        switch self {
        case .relief: "Yükü hafifleten temel teknikler"
        case .awareness: "Neyin tetiklediğine birlikte bakacağız"
        case .skill: "İşe yarayanı tekrar edilebilir hâle getiriyoruz"
        case .behavior: "Kaçındığın şeye küçük adımlarla yaklaşıyoruz"
        case .closing: "Kapanış ve son ölçüm"
        }
    }
}

enum PathStatus: String, Codable, Sendable {
    case active, paused, completed, abandoned
}

// MARK: - Ölçüm

/// Dört ölçüm noktası (PRD §8.6). İki nokta karşılaştırması ortalamaya dönüş
/// yanılsamasına açıktır; dört nokta trend gösterir.
enum MeasurementPoint: String, Codable, Sendable, CaseIterable {
    case baseline, day7, day14, final

    var questionCount: Int {
        switch self {
        case .baseline, .day7, .final: 8
        case .day14: 6
        }
    }

    /// Madde rotasyonu (PRD §8.3): aynı yapı, aynı skorlama, farklı ifade.
    /// İnsanlar ne cevap verdiklerini hatırlar ve "ilerlemiş görünme" eğilimine girer.
    var variant: MeasurementVariant {
        switch self {
        case .baseline: .a
        case .day7: .b
        case .day14: .c
        case .final: .a
        }
    }
}

enum MeasurementVariant: String, Codable, Sendable, CaseIterable {
    case a, b, c
}

/// Üç katman ve ağırlıkları (PRD §8.2).
///
/// Davranış en yüksek ağırlığı alır çünkü en sağlam sinyaldir ve en zor manipüle
/// edilir. Öz-yeterlik meditasyonun en gerçekçi çıktısıdır ve genelde en hızlı
/// iyileşen boyuttur.
enum MeasurementLayer: String, Codable, Sendable, CaseIterable {
    case emotion, behavior, selfEfficacy

    var weight: Double {
        switch self {
        case .emotion: 0.30
        case .behavior: 0.40
        case .selfEfficacy: 0.30
        }
    }

    var label: LocalizedStringResource {
        switch self {
        case .emotion: "Duygu şiddeti"
        case .behavior: "Davranış"
        case .selfEfficacy: "Öz-yeterlik"
        }
    }
}

// MARK: - Sonuç

/// Path sonu üç kova (PRD §7.9). `başarılı/başarısız` dili hiçbir yerde kullanılmaz —
/// kaygılı kullanıcıya yetersizlik belgesi vermek zarar verir (karar #2).
///
/// Eşikler şu an tahmindir ve Faz 0 verisiyle kalibre edilmelidir (PRD açık soru #5).
enum OutcomeBucket: String, Codable, Sendable, CaseIterable {
    /// Bileşik skorda ≥%25 iyileşme veya ≥2 alt boyutta ≥%30.
    case clearProgress
    /// %10–25 iyileşme veya karışık sinyal.
    case partialProgress
    /// ≤%5 değişim veya herhangi bir boyutta kötüleşme.
    case noProgress

    /// KRİTİK TİCARİ KURAL (PRD karar #3): Kova C'de satış yapılmaz ve devam
    /// patikası ücretsizdir. Teşvik hizalaması — şirket sadece kullanıcı iyileştiğinde
    /// kazanır. Bu bayrağı paywall'ı çağıran her yerde kontrol edin.
    var allowsSelling: Bool {
        self != .noProgress
    }

    /// Kutlama kalibrasyonu (Ton eki §6). Kova C: 0/5, hiçbir kutlama unsuru yok.
    var celebrationIntensity: Int {
        switch self {
        case .clearProgress: 5
        case .partialProgress: 3
        case .noProgress: 0
        }
    }

    /// Kova C'de rozet verilir ama üstünde sayı değil, sadece süre yazar.
    /// Emek tanınır, sonuç uydurulmaz (Ton eki §6).
    var badgeShowsNumbers: Bool {
        self != .noProgress
    }

    var toneTier: ToneTier {
        switch self {
        case .clearProgress, .partialProgress: .warm
        case .noProgress: .neutral
        }
    }
}

// MARK: - Oturum

/// Oturum sonu geri bildirimi (PRD §7.6). Üst üste 3 kez olumsuz gelirse sonraki
/// adım sessizce uyarlanır — kullanıcıya "başaramadın" denmez.
enum SessionFeedback: String, Codable, Sendable, CaseIterable {
    case helped, struggled, couldNotFocus

    var label: LocalizedStringResource {
        switch self {
        case .helped: "İyi geldi"
        case .struggled: "Zorlandım"
        case .couldNotFocus: "Odaklanamadım"
        }
    }

    var isDifficulty: Bool { self != .helped }
}

// MARK: - Tercihler

/// E3 / Ton eki §5.1. Bu tercih TTS prompt'una doğrudan girer — kullanıcı farkı duyar.
/// E2 — adım uzunluğu (PRD-Ek Onboarding §6). Üç seçenek, ortadaki önerilen.
///
/// Cevap ürünün davranışını doğrudan değiştiriyor: seçilen süre blok seçimini ve
/// ses uzunluğunu belirliyor. "Kişiselleştirme tiyatrosu" değil — kullanıcıya renk
/// seçtirmek kişiselleştirme değildir.
enum SessionLength: Int, CaseIterable, Codable, Sendable, Identifiable {
    case short = 5
    case standard = 10
    case deep = 15

    var id: Int { rawValue }
    var minutes: Int { rawValue }

    /// Önerilen seçenek E2'de önceden seçili gelir. Varsayılan yanlılığı burada
    /// serbest; **ödeme ve abonelik kararlarında** yasak (PRD-Ek 5.6).
    var isRecommended: Bool { self == .standard }

    var label: LocalizedStringResource {
        switch self {
        case .short: "5 dakika · kısa ve öz"
        case .standard: "10 dakika · önerilen"
        case .deep: "15 dakika · derin"
        }
    }
}

/// E4 — rehber sesin kimliği (ürün sahibi kararı, 2026-09-09).
///
/// ## Neden soruluyor
///
/// Meditasyonu dinleyen kişi bir sesle on dakika baş başa kalıyor. Ses kimliği
/// üzerinde hiçbir söz hakkı olmaması, ürünün en uzun temas ettiği yerde
/// kullanıcıyı seyirci bırakıyor.
///
/// ## Soru, sesin **kendisi** dinletilerek sorulur
///
/// "Nasıl bir ses istersin" diye sıfat saydırmak (sıcak mı, nötr mü, robotik mi)
/// kullanıcıya cevaplayamayacağı bir soru sormaktır: sıfatın karşılığının nasıl
/// duyulduğunu bilmiyor. İki örnek dinletip seçtirmek aynı kararı bir saniyede
/// ve doğru bilgiyle aldırıyor.
///
/// ## Sağlayıcının `voice_id`si burada yok
///
/// Bu enum ürünün teknik ses yuvasını taşır; hangi sağlayıcının hangi
/// kimliği kullandığı sunucunun bilgisi. Sağlayıcı değişince kullanıcı
/// satırlarının değişmesi gerekmemeli.
enum VoicePreference: String, Codable, Sendable, CaseIterable, Identifiable {
    case feminine, masculine

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .feminine: "Ses A"
        case .masculine: "Ses B"
        }
    }

    /// Önizleme dosyasının uygulama paketindeki adı. Dile göre değişir —
    /// aynı ses iki dilde farklı duyuluyor ve kullanıcı kendi dilinde
    /// duymadığı bir sesi seçemez.
    func previewAssetName(locale: AppLocale) -> String {
        "voice-preview-\(rawValue)-\(locale.rawValue)"
    }

    var icon: String {
        switch self {
        case .feminine: "waveform"
        case .masculine: "waveform"
        }
    }
}

/// Ürünün taşıdığı diller (v1: TR + EN).
///
/// **Yalnızca sesin ve blok metinlerinin dilini** belirler. Arayüz metinleri
/// hâlâ `Copy.swift` içinde sabit Türkçe; arayüz yerelleştirmesi String Catalog
/// ile ayrı bir iş (CLAUDE.md "henüz yok" listesi).
///
/// Varsayılan İngilizce, cihaz Türkçeye ya da Türkiye bölgesine ayarlıysa
/// Türkçe (ürün sahibi kararı, 2026-09-09).
enum AppLocale: String, Codable, Sendable, CaseIterable {
    case turkish = "tr"
    case english = "en"

    static var current: AppLocale {
        let locale = Locale.current
        if locale.language.languageCode?.identifier == "tr" { return .turkish }
        if locale.region?.identifier == "TR" { return .turkish }
        return .english
    }

    /// Sunucuya gönderilen tam tanımlayıcı.
    var identifier: String {
        switch self {
        case .turkish: "tr-TR"
        case .english: "en-US"
        }
    }
}

enum TonePreference: String, Codable, Sendable, CaseIterable, Identifiable {
    case calmAndShort, moreGuiding, infoOnly

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .calmAndShort: "Sakin ve kısa"
        case .moreGuiding: "Biraz daha yönlendirici"
        case .infoOnly: "Sadece bilgi, yorum yok"
        }
    }
}

/// Ton eki §5.1. Nudge frekansı zamanla artmaz, azalır (karar #7).
enum ReminderFrequency: String, Codable, Sendable, CaseIterable {
    case daily, onlyWhenMissed, weekly, never

    var label: LocalizedStringResource {
        switch self {
        case .daily: "Her gün"
        case .onlyWhenMissed: "Sadece kaçırdığımda"
        case .weekly: "Haftada bir"
        case .never: "Hiç hatırlatma"
        }
    }
}

enum SubscriptionStatus: String, Codable, Sendable {
    case free, singlePath, monthly, yearly

    var hasUnlimitedPaths: Bool {
        self == .monthly || self == .yearly
    }
}
