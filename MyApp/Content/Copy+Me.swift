import Foundation

/// "Ben" sekmesi, Destek al ve uygulama kilidi metinleri
/// (`docs/profile-design.md` §12).
///
/// Ton kademesi: sayfa 🟠 Sakin, Destek al 🔴 Nötr. Ünlem yok; "harika",
/// "tebrikler", "devam et", "aşacaksın" yok.
extension Copy {

    enum Me {
        static let screenTitle: LocalizedStringResource = "Ben"

        // MARK: Başlık

        static let noActivePath: LocalizedStringResource = "Şu an bir yolda değilsin."
        static let pathFinishedHeader: LocalizedStringResource = "Yolun tamamlandı."
        static let offlineHeader: LocalizedStringResource =
            "Bağlantı gelince yolun burada görünecek."
        static func stepPosition(day: Int) -> LocalizedStringResource { "\(day). adım" }

        // MARK: Ne değişti

        static let changeTitle: LocalizedStringResource = "Ne değişti"
        static let changeOpenHint: LocalizedStringResource = "Ayrıntıyı açar"
        /// Beklenti durumu. Kilit, bulanıklık, "1/7" yok: saklanan bir şey değil,
        /// henüz ortada olmayan bir şey var.
        static func changePending(stepDay: Int) -> LocalizedStringResource {
            "İlk karşılaştırma \(stepDay). adımda. O güne kadar ölçecek bir fark yok."
        }
        static func baselineLegendPending(date: String) -> LocalizedStringResource {
            "Başlangıcın · \(date)"
        }
        static func baselineLegendCompared(point: String) -> LocalizedStringResource {
            "Başlangıcın · son ölçüm: \(point)"
        }
        static let baselineProvisional: LocalizedStringResource =
            "Başlangıcın şimdilik tek ölçüme dayanıyor; karşılaştırma biraz oynayabilir."

        static let pointBaseline: LocalizedStringResource = "Başlangıç"
        static let pointFinal: LocalizedStringResource = "Son"
        static func pointStep(day: Int) -> LocalizedStringResource { "\(day). adım" }

        /// Kısa katman adları — segment seçici ve satırlar. Uzun adlar
        /// `MeasurementLayer.label`da.
        static func layerShort(_ layer: MeasurementLayer) -> LocalizedStringResource {
            switch layer {
            case .emotion: "Duygu"
            case .behavior: "Davranış"
            case .selfEfficacy: "Öz-yeterlik"
            }
        }

        /// Her katman kendi fiilini kullanır: "arttı" duyguda kötü, öz-yeterlikte
        /// iyi bir haber. Kötü yöndeki kelimeler yargı taşımaz ("geriledi" yok).
        static func directionWord(
            _ layer: MeasurementLayer,
            _ direction: MeasurementComparison.Direction
        ) -> LocalizedStringResource {
            switch (layer, direction) {
            case (_, .unchanged): "aynı"
            case (.emotion, .improved): "hafifledi"
            case (.emotion, .worsened): "ağırlaştı"
            case (.behavior, .improved): "azaldı"
            case (.behavior, .worsened): "arttı"
            case (.selfEfficacy, .improved): "güçlendi"
            case (.selfEfficacy, .worsened): "zayıfladı"
            }
        }

        static func layerAccessibility(layer: String, word: String) -> LocalizedStringResource {
            "\(layer): \(word), başlangıcına göre"
        }

        // Cümle parçaları (profile-design §12.2). Süreç kipi yolun ortasında
        // bir gözlem söyler; geçmiş kip ancak yol bittiğinde kullanılır.

        static func fragment(
            _ layer: MeasurementLayer,
            _ direction: MeasurementComparison.Direction,
            finished: Bool
        ) -> LocalizedStringResource {
            switch (layer, direction, finished) {
            case (.emotion, .improved, false): "Duygunun şiddeti hafifliyor."
            case (.emotion, .improved, true): "Duygunun şiddeti hafifledi."
            case (.emotion, .unchanged, false): "Duygunun şiddeti başladığın yerde."
            case (.emotion, .unchanged, true): "Duygunun şiddeti başladığın yerde kaldı."
            case (.emotion, .worsened, _): "Duygunun şiddeti başlangıcından ağır."
            case (.behavior, .improved, false): "Kaçınman azalıyor."
            case (.behavior, .improved, true): "Kaçınman azaldı."
            case (.behavior, .unchanged, false): "Kaçınman başladığın yerde."
            case (.behavior, .unchanged, true): "Kaçınman başladığın yerde kaldı."
            case (.behavior, .worsened, _): "Kaçınman başlangıcından fazla."
            case (.selfEfficacy, .improved, false): "Baş edebileceğine dair inancın güçleniyor."
            case (.selfEfficacy, .improved, true): "Baş edebileceğine dair inancın güçlendi."
            case (.selfEfficacy, .unchanged, false): "Baş edebileceğine dair inancın başladığın yerde."
            case (.selfEfficacy, .unchanged, true): "Baş edebileceğine dair inancın başladığın yerde kaldı."
            case (.selfEfficacy, .worsened, _): "Baş edebileceğine dair inancın başlangıcından zayıf."
            }
        }

        static func uniformChange(
            _ direction: MeasurementComparison.Direction,
            finished: Bool
        ) -> LocalizedStringResource {
            switch (direction, finished) {
            case (.improved, _):
                "Üç katmanda da başladığın yerden farklı bir yerdesin."
            case (.unchanged, false):
                "Şimdilik üç katman da başladığın yerde. Bu, yolun ortasında sık görülür."
            case (.unchanged, true):
                "Üç katman da başladığın yerde kaldı."
            case (.worsened, _):
                "Üç katmanda da başlangıcından ağır bir yerdesin. Bunu konuşmak istersen Destek al burada."
            }
        }

        // MARK: Değişim ayrıntısı

        static let layerPickerLabel: LocalizedStringResource = "Katman"
        static func chartBetter(_ layer: MeasurementLayer) -> LocalizedStringResource {
            switch layer {
            case .emotion: "daha hafif"
            case .behavior: "daha az kaçınma"
            case .selfEfficacy: "daha güçlü"
            }
        }
        static func chartWorse(_ layer: MeasurementLayer) -> LocalizedStringResource {
            switch layer {
            case .emotion: "daha ağır"
            case .behavior: "daha çok kaçınma"
            case .selfEfficacy: "daha zayıf"
            }
        }
        static let chartBaseline: LocalizedStringResource = "Başlangıcın"
        static let chartXAxis: LocalizedStringResource = "Ölçüm"
        static let chartYAxis: LocalizedStringResource = "Başlangıca göre"
        static let chartBaselinePoint: LocalizedStringResource = "başlangıç çizgisi"
        static let mostChanged: LocalizedStringResource = "En çok değişen"
        static let leastChanged: LocalizedStringResource = "En az değişen"
        static let howWeMeasure: LocalizedStringResource = "Nasıl ölçüyoruz"

        // MARK: Defter

        static let journalTitle: LocalizedStringResource = "Defter"
        static let journalAll: LocalizedStringResource = "Tümü"
        static func journalOrigin(date: String) -> LocalizedStringResource {
            "Başlangıçta · \(date)"
        }
        static func journalAvoidance(date: String) -> LocalizedStringResource {
            "Başlangıçta, kaçındığın şey · \(date)"
        }
        static func journalAfterStep(day: Int, date: String) -> LocalizedStringResource {
            "\(day). adımdan sonra · \(date)"
        }
        static func journalQuestion(_ question: String) -> LocalizedStringResource {
            "Soru: \(question)"
        }
        static let journalEmpty: LocalizedStringResource =
            "Adımların sonunda yazdıkların burada birikecek. Yazmak zorunda değilsin."
        static let journalHidden: LocalizedStringResource = "Gizli · göstermek için dokun"
        static let journalDelete: LocalizedStringResource = "Sil"
        static let journalDeleteTitle: LocalizedStringResource = "Bu cümle silinsin mi?"
        static let journalDeleteBody: LocalizedStringResource =
            "Bu cümle kalıcı olarak silinir. Yolun değişmez."
        static let journalDeleteOriginBody: LocalizedStringResource =
            "Başlangıçta yazdığın cümleler birlikte kalıcı olarak silinir. Yolun değişmez."
        static let journalDeleteFailed: LocalizedStringResource =
            "Silme tamamlanamadı. Bu senin yüzünden değil; cümle yerinde duruyor, yeniden deneyebilirsin."
        static let reminderOffValue: LocalizedStringResource = "Kapalı"
        static let thisWeek: LocalizedStringResource = "Bu hafta"
        static let lastWeek: LocalizedStringResource = "Geçen hafta"
        static let today: LocalizedStringResource = "Bugün"
        static let yesterday: LocalizedStringResource = "Dün"

        // MARK: Yürüdüğün yollar

        static let pathsTitle: LocalizedStringResource = "Yürüdüğün yollar"
        static let pathJustStarted: LocalizedStringResource = "Yola yeni çıktın"
        static func pathActive(walked: Int) -> LocalizedStringResource { "Yoldasın · \(walked) adım" }
        static let pathCompleted: LocalizedStringResource = "Tamamlandı"
        /// Yapılanı say, yapılmayanı sayma (İ2): "13 adım kaldı" yazılmaz.
        static func pathStopped(walked: Int) -> LocalizedStringResource { "\(walked) adım yürüdün" }
        static let pathStoppedDetail: LocalizedStringResource = "Yol kayıtlı duruyor."
        static let pathClearProgress: LocalizedStringResource = "Belirgin bir fark oluştu"
        static let pathPartialProgress: LocalizedStringResource = "Bazı şeyler değişti"
        static func pathDays(_ days: Int) -> LocalizedStringResource { "\(days) gün" }
        static func pathSteps(_ steps: Int) -> LocalizedStringResource { "\(steps) adım" }
        static func pathDateRange(start: String, end: String) -> LocalizedStringResource {
            "\(start) – \(end)"
        }
        static let pathJournalTitle: LocalizedStringResource = "Bu yolda yazdıkların"
        static func sealAccessibility(title: String, detail: String) -> LocalizedStringResource {
            "\(title) yolu. \(detail)"
        }

        // MARK: Sana göre ayarlananlar

        static let preferencesTitle: LocalizedStringResource = "Sana göre ayarlananlar"
        static let reminderLabel: LocalizedStringResource = "Hatırlatma"
        /// Sorduğumuz her şeyin karşılığı görünür olmalı: saat, kullanıcının B3
        /// cevabından geldiyse bu satır onu söyler.
        static func reminderSource(_ answer: String) -> LocalizedStringResource {
            "“\(answer)” dediğin için"
        }
        static let reminderOff: LocalizedStringResource = "Henüz açık değil"
        static let reminderToggle: LocalizedStringResource = "Günlük hatırlatma"
        static let reminderTimeLabel: LocalizedStringResource = "Saat"
        static let reminderDenied: LocalizedStringResource =
            "Bildirim izni kapalı. İstersen telefonunun ayarlarından açabilirsin; hatırlatma o zamana kadar kapalı kalır."
        static let openSettings: LocalizedStringResource = "Ayarları aç"
        static let sessionLengthLabel: LocalizedStringResource = "Adım uzunluğu"
        static func minutes(_ minutes: Int) -> LocalizedStringResource { "\(minutes) dakika" }
        static let toneLabel: LocalizedStringResource = "Anlatım"
        static let voiceLabel: LocalizedStringResource = "Rehber sesi"
        /// Uzunluk, ton ve ses path üretilirken sunucuya gidiyor; sonradan
        /// değiştirmenin bir karşılığı henüz yok. Değişmiyormuş gibi davranan bir
        /// düğme koymak yerine bunu söylüyoruz.
        static let preferencesFootnote: LocalizedStringResource =
            "Adım uzunluğu, anlatım ve ses bu yol kurulurken seçildi. Yeni bir yolda yeniden seçebilirsin."

        // MARK: Destek, uygulama, hesap

        static let supportTitle: LocalizedStringResource = "Destek al"
        static let supportSubtitle: LocalizedStringResource = "Konuşabileceğin biri, şimdi."
        static let settingsRow: LocalizedStringResource = "Ayarlar ve gizlilik"
        static let anonymousTitle: LocalizedStringResource = "Bu kayıt şimdilik yalnızca bu telefonda."
        static let linkAccount: LocalizedStringResource = "Hesaba bağla"
        static let anonymousBody: LocalizedStringResource =
            "Hesaba bağlarsan telefon değişince kaybolmaz."
        static func version(_ version: String, build: String) -> LocalizedStringResource {
            "Patika \(version) (\(build))"
        }

        enum Settings {
            static let title: LocalizedStringResource = "Ayarlar ve gizlilik"
            static let reminderHeader: LocalizedStringResource = "Hatırlatma"
            static let notificationPrivacy: LocalizedStringResource =
                "Bildirim metni hiçbir zaman yolunun adını ya da derdini içermez."
            static let privacyHeader: LocalizedStringResource = "Gizlilik"
            static let appLock: LocalizedStringResource = "Uygulama kilidi"
            static let appLockFooter: LocalizedStringResource =
                "Açılırken Face ID ya da parola ister."
            static let appLockUnavailable: LocalizedStringResource =
                "Bu telefonda parola kurulu olmadığı için kilit açılamıyor."
            static let hideJournal: LocalizedStringResource = "Cümlelerimi Ben sekmesinde gizle"
            static let analytics: LocalizedStringResource = "Kullanım verisi paylaş"
            static let analyticsFooter: LocalizedStringResource =
                "Hangi dokunuşların işe yaradığını anlamamıza yardım eder. Yazdıkların ve ölçümlerin hiçbir zaman buna dahil değildir."
            static let dataHeader: LocalizedStringResource = "Verim"
            static let export: LocalizedStringResource = "Bu cihazdaki kaydını indir"
            static let exportPreview: LocalizedStringResource = "Patika kaydı"
            static let exportFooter: LocalizedStringResource =
                "Cümlelerin, ölçüm cevapların ve tercihlerin tek bir dosyada."
            static let deleteJournal: LocalizedStringResource = "Cümlelerimi sil"
            static let deleteJournalTitle: LocalizedStringResource =
                "Defterdeki bütün cümleler silinsin mi?"
            static let deleteJournalBody: LocalizedStringResource =
                "Cümleler kalıcı olarak silinir. Yolun ve ölçümlerin kalır."
            static let deleteAccount: LocalizedStringResource = "Hesabı ve bütün verileri sil"
            static let deleteAccountTitle: LocalizedStringResource =
                "Hesabın ve bütün verilerin silinsin mi?"
            static let deleteAccountBody: LocalizedStringResource =
                "Yolun, cümlelerin, ölçümlerin ve kayıtların kalıcı olarak silinir. Bu geri alınamaz."
            static let deleteAccountFailed: LocalizedStringResource =
                "Silme tamamlanamadı. Bu senin yüzünden değil; hiçbir şey silinmedi, yeniden deneyebilirsin."
            static let nameFailed: LocalizedStringResource =
                "Adın kaydedilemedi. Bu senin yüzünden değil; yeniden deneyebilirsin."
            static let accountHeader: LocalizedStringResource = "Hesap"
            static let nameRow: LocalizedStringResource = "Sana nasıl hitap edelim"
            static let nameNone: LocalizedStringResource = "Ad yok"
            static let namePlaceholder: LocalizedStringResource = "Adın"
            static let nameHint: LocalizedStringResource =
                "İstersen boş bırakabilirsin. Ad yalnızca birkaç yerde kullanılıyor."
            static let linkedRow: LocalizedStringResource = "Bağlı hesap"
            static let linkedYes: LocalizedStringResource = "Bağlı"
            static let linkedNo: LocalizedStringResource = "Yalnızca bu telefon"
            static let aboutHeader: LocalizedStringResource = "Hakkında"
            static let versionRow: LocalizedStringResource = "Sürüm"
            static let irreversibleHeader: LocalizedStringResource = "Geri alınamaz"
            static let eraseLocal: LocalizedStringResource = "Bu cihazdaki kaydı sil"
            static let eraseFooter: LocalizedStringResource =
                "Defterin, ölçüm cevapların ve tercihlerin bu telefondan silinir. Sunucudaki yolun etkilenmez."
            static let eraseTitle: LocalizedStringResource = "Bu cihazdaki kayıt silinsin mi?"
        }

        enum Method {
            static let title: LocalizedStringResource = "Nasıl ölçüyoruz"
            static let intro: LocalizedStringResource =
                "Ölçüm bir sınav değil. Aynı soruları belli adımlarda yeniden soruyoruz ve cevaplarını yalnızca kendi başlangıcınla karşılaştırıyoruz."
            static let layersTitle: LocalizedStringResource = "Üç katman"
            static let emotion: LocalizedStringResource =
                "Duygu şiddeti · %30 — zorlandığın şeyin ne kadar ağır geldiği ve ne sıklıkla geldiği."
            static let behavior: LocalizedStringResource =
                "Davranış · %40 — kaçınma ve gündelik hayata etkisi. En sağlam katman, çünkü yapılan şeyi soruyor."
            static let selfEfficacy: LocalizedStringResource =
                "Öz-yeterlik · %30 — ne yapacağını bildiğin ve değişimin mümkün olduğuna inandığın ölçü."
            static let rotationTitle: LocalizedStringResource = "Neden sorular biraz farklı"
            static let rotation: LocalizedStringResource =
                "İnsanlar önceki cevaplarını hatırlar. Bu yüzden her ölçümde aynı şeyi farklı bir cümleyle soruyoruz; hesap aynı kalıyor."
            static let clinicalTitle: LocalizedStringResource = "Neden klinik bir ölçek değil"
            static let clinical: LocalizedStringResource =
                "Klinik ölçekler teşhis için yapılmış. Burada teşhis yok; amaç yalnızca kendi değişimini görmen. Sonuç hiçbir zaman başka biriyle karşılaştırılmıyor."
        }
    }

    /// Destek al — 🔴 Nötr kademe. Süsleme yok, hareket yok, satış yok.
    enum Support {
        static let title: LocalizedStringResource = "Destek al"
        static let body: LocalizedStringResource =
            "Şu an zorlanıyorsan bununla yalnız kalmak zorunda değilsin. Aşağıdaki hatlarda seni dinleyecek biri var."
        static let call: LocalizedStringResource = "Ara"
        static func callAccessibility(name: String, number: String) -> LocalizedStringResource {
            "\(name), \(number). Aramak için dokun."
        }
        static let directory: LocalizedStringResource = "Bulunduğun ülkedeki diğer hatlar"
        static let notEmergencyService: LocalizedStringResource =
            "Patika bir acil durum ya da tedavi hizmeti değildir."
        static let emergencyName: LocalizedStringResource = "Acil çağrı"
        static let emergencyDetail: LocalizedStringResource =
            "Sen ya da bir başkası hemen tehlikedeyse"
        static let trSocialSupportName: LocalizedStringResource = "ALO 183"
        static let trSocialSupportDetail: LocalizedStringResource = "Sosyal destek hattı"
        static let deTelefonSeelsorgeName: LocalizedStringResource = "TelefonSeelsorge"
        static let deTelefonSeelsorgeDetail: LocalizedStringResource = "Anonim telefonla destek"
        static let us988Name: LocalizedStringResource = "988 Lifeline"
        static let us988Detail: LocalizedStringResource = "Kriz hattı · arayabilir ya da mesaj atabilirsin"
        static let gbSamaritansName: LocalizedStringResource = "Samaritans"
        static let gbSamaritansDetail: LocalizedStringResource = "Duygusal destek hattı"
    }

    /// Yol içi ölçüm — 🟠 Sakin. Sınav değil; skor ve yorum yok.
    enum PathMeasurement {
        static func introHeadline(_ count: Int) -> LocalizedStringResource {
            "Kısa bir ölçüm: \(count) soru."
        }
        static let introBody: LocalizedStringResource =
            "İlk günkü sorular, biraz farklı cümlelerle. Cevapların yalnızca kendi başlangıcınla karşılaştırılıyor."
        static let introCTA: LocalizedStringResource = "Başlayalım"
        static let saveError: LocalizedStringResource =
            "Cevapların kaybolmadı, senin yüzünden değil. Bağlantıyı kontrol edip yeniden deneyebilirsin."
        static let completionError: LocalizedStringResource =
            "Adımın kaydedilemedi. Bu senin yüzünden değil; yeniden deneyebilirsin."
    }

    enum AppLock {
        static let title: LocalizedStringResource = "Kaydın kilitli."
        static let body: LocalizedStringResource = "Açmak için kimliğini doğrula."
        static let unlock: LocalizedStringResource = "Kilidi aç"
        static let reason: LocalizedStringResource = "Kaydını yalnızca senin açabilmen için"
    }
}
