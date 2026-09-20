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

        // MARK: Kimlik kartı (Ben v2)

        static let settingsButton: LocalizedStringResource = "Ayarlar"
        static let photoTitle: LocalizedStringResource = "Profil fotoğrafı"
        static let photoChoose: LocalizedStringResource = "Fotoğraf seç"
        static let photoRemove: LocalizedStringResource = "Fotoğrafı kaldır"
        static let photoFailed: LocalizedStringResource =
            "Fotoğraf kaydedilemedi. Bu senin yüzünden değil; yeniden deneyebilirsin."
        static let photoAccessibility: LocalizedStringResource = "Profil fotoğrafı"
        static func weekDays(_ count: Int) -> LocalizedStringResource {
            "bu hafta \(count) gün"
        }
        /// Kimlik kartı VoiceOver'da tek öğe: ad, yol, adım ve faz, hafta.
        static func identityAccessibility(parts: [String]) -> LocalizedStringResource {
            "\(parts.joined(separator: ", "))"
        }

        // MARK: Defter kartı

        static let journalCardInvite: LocalizedStringResource =
            "İç dünyana ait notları burada biriktirebilirsin."
        static let journalCardWrite: LocalizedStringResource = "İlk notunu yaz"
        static let journalCardOpenHint: LocalizedStringResource = "Defteri açar"
        static let journalCardLabel: LocalizedStringResource = "Defter"

        // MARK: Defter sayfası ve not yazma

        static let journalNewNote: LocalizedStringResource = "Yeni not"
        static let journalEditNote: LocalizedStringResource = "Notu düzenle"
        static let journalEdit: LocalizedStringResource = "Düzenle"
        static func journalNoteCaption(date: String) -> LocalizedStringResource { "Notun · \(date)" }
        static let journalOwnNote: LocalizedStringResource = "Kendi notun"
        static let notePlaceholder: LocalizedStringResource = "Yazmak istediğin ne varsa."
        static func noteRemaining(_ count: Int) -> LocalizedStringResource {
            "\(count) karakter kaldı"
        }
        static let noteLimitReached: LocalizedStringResource = "Not sınırına geldin."
        static let noteSaveFailed: LocalizedStringResource =
            "Yazdığın kaybolmadı. Bu senin yüzünden değil; yeniden deneyebilirsin."

        // MARK: Rozetler

        static let badgesTitle: LocalizedStringResource = "Rozetler"
        static let badgesAll: LocalizedStringResource = "Tümü"
        static let badgesFirstHint: LocalizedStringResource = "İlk adımı attığında burada"
        static let badgeLockedLabel: LocalizedStringResource = "Henüz kazanılmadı"
        static func badgeAccessibility(title: String, detail: String, earned: Bool) -> LocalizedStringResource {
            earned ? "\(title). \(detail)" : "\(title), henüz kazanılmadı. \(detail)"
        }

        /// Rozet adı, kazanıldığında söylenen tek cümle ve kazanma koşulu.
        ///
        /// Ton: 🟡 Sıcak (kriz ve Kova C'de 🔴 — orada kutlama yaprağı açılmaz,
        /// metin yalnızca rafta durur). Ünlem yok, "harika/tebrikler" yok; sayı
        /// yalnızca eşiğin kendisi.
        enum Badge {
            static func title(_ id: BadgeID) -> LocalizedStringResource {
                switch id {
                case .firstStep: "İlk adım"
                case .phaseRelief: "Rahatlama"
                case .phaseAwareness: "Farkındalık"
                case .phaseSkill: "Beceri"
                case .phaseBehavior: "Davranış"
                case .phaseClosing: "Kapanış"
                case .pathComplete: "Yolun sonu"
                case .measureDay7: "7. adım ölçümü"
                case .measureDay14: "14. adım ölçümü"
                case .week3: "Haftada 3 gün"
                case .week5: "Haftada 5 gün"
                case .week7: "Haftada 7 gün"
                case .noteFirst: "İlk not"
                case .note10: "On not"
                }
            }

            /// Kazanıldığında rozet yaprağında yazan cümle.
            static func earned(_ id: BadgeID) -> LocalizedStringResource {
                switch id {
                case .firstStep: "İlk adımı attın."
                case .phaseRelief: "İlk fazı geride bıraktın."
                case .phaseAwareness: "Farkındalık fazını geride bıraktın."
                case .phaseSkill: "Beceri fazını geride bıraktın."
                case .phaseBehavior: "Davranış fazını geride bıraktın."
                case .phaseClosing: "Kapanış adımını tamamladın."
                case .pathComplete: "Yolu sonuna kadar yürüdün."
                case .measureDay7: "7. adımdaki ölçüme katıldın."
                case .measureDay14: "14. adımdaki ölçüme katıldın."
                case .week3: "Bir haftada 3 gün adım attın."
                case .week5: "Bir haftada 5 gün adım attın."
                case .week7: "Bir haftada 7 gün adım attın."
                case .noteFirst: "Defterine ilk notunu yazdın."
                case .note10: "Defterine on not yazdın."
                }
            }

            /// Kilitli rozetin altında yazan tek cümle. İlerleme çubuğu ya da
            /// "3/5" yok: sayaç, geri sayan bir sayıyla aynı baskıyı kurar.
            static func howToEarn(_ id: BadgeID) -> LocalizedStringResource {
                switch id {
                case .firstStep: "İlk adımı tamamladığında."
                case .phaseRelief: "Rahatlama fazının adımlarını tamamladığında."
                case .phaseAwareness: "Farkındalık fazının adımlarını tamamladığında."
                case .phaseSkill: "Beceri fazının adımlarını tamamladığında."
                case .phaseBehavior: "Davranış fazının adımlarını tamamladığında."
                case .phaseClosing: "Kapanış adımını tamamladığında."
                case .pathComplete: "Yolun son adımını tamamladığında."
                case .measureDay7: "7. adımdaki ölçüme katıldığında."
                case .measureDay14: "14. adımdaki ölçüme katıldığında."
                case .week3: "Bir takvim haftasında 3 gün adım attığında."
                case .week5: "Bir takvim haftasında 5 gün adım attığında."
                case .week7: "Bir takvim haftasında 7 gün adım attığında."
                case .noteFirst: "Defterine ilk notunu yazdığında."
                case .note10: "Defterine on not yazdığında."
                }
            }

            static func family(_ family: BadgeID.Family) -> LocalizedStringResource {
                switch family {
                case .path: "Yol"
                case .measurement: "Ölçüm"
                case .streak: "Hafta"
                case .journal: "Defter"
                }
            }
        }

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
            /// Sayfa başlığı: `nameRow` gezinme çubuğunda düğmenin yanında kırpılıyordu.
            static let nameTitle: LocalizedStringResource = "Adın"
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
    ///
    /// Metinler `Support.xcstrings`te (TR + EN). **Numara cihaz bölgesinden**
    /// (`SupportResources.lines`), **metnin dili uygulama dilinden**
    /// (`AppLocale.current`): Almanya'da Türkçe kullanan biri TelefonSeelsorge'yi
    /// Türkçe açıklamayla görür. Arayüzün geri kalanı hâlâ sabit Türkçe; bu ekran
    /// kriz anında bir kullanıcının anlayacağı dilde durmalı.
    enum Support {
        private static func text(_ key: String.LocalizationValue) -> LocalizedStringResource {
            LocalizedStringResource(
                key,
                table: "Support",
                locale: Locale(identifier: AppLocale.current.rawValue)
            )
        }

        static var title: LocalizedStringResource { text("support.title") }
        static var body: LocalizedStringResource { text("support.body") }
        static var call: LocalizedStringResource { text("support.call") }
        static var close: LocalizedStringResource { text("support.close") }
        /// "ALO 183, 183. Aramak için dokun." Cümle parçaları katalogdan, birleşim
        /// burada: katalog anahtarında enterpolasyon yok.
        static func callAccessibility(name: String, number: String) -> String {
            "\(name), \(number). \(String(localized: text("support.tapToCall")))"
        }
        static var directory: LocalizedStringResource { text("support.directory") }
        static var notEmergencyService: LocalizedStringResource { text("support.notEmergencyService") }
        static var emergencyName: LocalizedStringResource { text("support.emergency.name") }
        static var emergencyDetail: LocalizedStringResource { text("support.emergency.detail") }
        static var trSocialSupportName: LocalizedStringResource { text("support.tr.socialSupport.name") }
        static var trSocialSupportDetail: LocalizedStringResource { text("support.tr.socialSupport.detail") }
        static var deTelefonSeelsorgeName: LocalizedStringResource { text("support.de.telefonSeelsorge.name") }
        static var deTelefonSeelsorgeDetail: LocalizedStringResource { text("support.de.telefonSeelsorge.detail") }
        static var us988Name: LocalizedStringResource { text("support.us.988.name") }
        static var us988Detail: LocalizedStringResource { text("support.us.988.detail") }
        static var gbSamaritansName: LocalizedStringResource { text("support.gb.samaritans.name") }
        static var gbSamaritansDetail: LocalizedStringResource { text("support.gb.samaritans.detail") }
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
