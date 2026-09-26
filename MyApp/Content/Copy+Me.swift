import Foundation

/// "Ben" sekmesi, Destek al ve uygulama kilidi metinleri
/// (`docs/profile-design.md` §12).
///
/// Ton kademesi: sayfa 🟠 Sakin, Destek al 🔴 Nötr. Ünlem yok; "harika",
/// "tebrikler", "devam et", "aşacaksın" yok.
extension Copy {

    enum Me {
        static let screenTitle: LocalizedStringResource = .meScreenTitle

        // MARK: Başlık

        static let noActivePath: LocalizedStringResource = .meNoActivePath
        static let pathFinishedHeader: LocalizedStringResource = .mePathFinishedHeader
        static let offlineHeader: LocalizedStringResource =
            .meOfflineHeader
        static func stepPosition(day: Int) -> LocalizedStringResource { .meStepPosition(day) }

        // MARK: Ne değişti

        static let changeTitle: LocalizedStringResource = .meChangeTitle
        static let changeOpenHint: LocalizedStringResource = .meChangeOpenHint
        /// Beklenti durumu. Kilit, bulanıklık, "1/7" yok: saklanan bir şey değil,
        /// henüz ortada olmayan bir şey var.
        static func changePending(stepDay: Int) -> LocalizedStringResource {
            .meChangePending(stepDay)
        }
        static func baselineLegendPending(date: String) -> LocalizedStringResource {
            .meBaselineLegendPending(date)
        }
        static func baselineLegendCompared(point: String) -> LocalizedStringResource {
            .meBaselineLegendCompared(point)
        }
        static let baselineProvisional: LocalizedStringResource =
            .meBaselineProvisional

        static let pointBaseline: LocalizedStringResource = .mePointBaseline
        static let pointFinal: LocalizedStringResource = .mePointFinal
        static func pointStep(day: Int) -> LocalizedStringResource { .mePointStep(day) }

        /// Kısa katman adları — segment seçici ve satırlar. Uzun adlar
        /// `MeasurementLayer.label`da.
        static func layerShort(_ layer: MeasurementLayer) -> LocalizedStringResource {
            switch layer {
            case .emotion: .meLayerShortEmotion
            case .behavior: .meLayerShortBehavior
            case .selfEfficacy: .meLayerShortSelfEfficacy
            }
        }

        /// Her katman kendi fiilini kullanır: "arttı" duyguda kötü, öz-yeterlikte
        /// iyi bir haber. Kötü yöndeki kelimeler yargı taşımaz ("geriledi" yok).
        static func directionWord(
            _ layer: MeasurementLayer,
            _ direction: MeasurementComparison.Direction
        ) -> LocalizedStringResource {
            switch (layer, direction) {
            case (_, .unchanged): .meDirectionWordUnchanged
            case (.emotion, .improved): .meDirectionWordEmotionImproved
            case (.emotion, .worsened): .meDirectionWordEmotionWorsened
            case (.behavior, .improved): .meDirectionWordBehaviorImproved
            case (.behavior, .worsened): .meDirectionWordBehaviorWorsened
            case (.selfEfficacy, .improved): .meDirectionWordSelfEfficacyImproved
            case (.selfEfficacy, .worsened): .meDirectionWordSelfEfficacyWorsened
            }
        }

        static func layerAccessibility(layer: String, word: String) -> LocalizedStringResource {
            .meLayerAccessibility(layer, word)
        }

        // Cümle parçaları (profile-design §12.2). Süreç kipi yolun ortasında
        // bir gözlem söyler; geçmiş kip ancak yol bittiğinde kullanılır.

        static func fragment(
            _ layer: MeasurementLayer,
            _ direction: MeasurementComparison.Direction,
            finished: Bool
        ) -> LocalizedStringResource {
            switch (layer, direction, finished) {
            case (.emotion, .improved, false): .meFragmentEmotionImprovedFalse
            case (.emotion, .improved, true): .meFragmentEmotionImprovedTrue
            case (.emotion, .unchanged, false): .meFragmentEmotionUnchangedFalse
            case (.emotion, .unchanged, true): .meFragmentEmotionUnchangedTrue
            case (.emotion, .worsened, _): .meFragmentEmotionWorsened
            case (.behavior, .improved, false): .meFragmentBehaviorImprovedFalse
            case (.behavior, .improved, true): .meFragmentBehaviorImprovedTrue
            case (.behavior, .unchanged, false): .meFragmentBehaviorUnchangedFalse
            case (.behavior, .unchanged, true): .meFragmentBehaviorUnchangedTrue
            case (.behavior, .worsened, _): .meFragmentBehaviorWorsened
            case (.selfEfficacy, .improved, false): .meFragmentSelfEfficacyImprovedFalse
            case (.selfEfficacy, .improved, true): .meFragmentSelfEfficacyImprovedTrue
            case (.selfEfficacy, .unchanged, false): .meFragmentSelfEfficacyUnchangedFalse
            case (.selfEfficacy, .unchanged, true): .meFragmentSelfEfficacyUnchangedTrue
            case (.selfEfficacy, .worsened, _): .meFragmentSelfEfficacyWorsened
            }
        }

        static func uniformChange(
            _ direction: MeasurementComparison.Direction,
            finished: Bool
        ) -> LocalizedStringResource {
            switch (direction, finished) {
            case (.improved, _):
                .meUniformChangeImproved
            case (.unchanged, false):
                .meUniformChangeUnchangedFalse
            case (.unchanged, true):
                .meUniformChangeUnchangedTrue
            case (.worsened, _):
                .meUniformChangeWorsened
            }
        }

        // MARK: Değişim ayrıntısı

        static let layerPickerLabel: LocalizedStringResource = .meLayerPickerLabel
        static func chartBetter(_ layer: MeasurementLayer) -> LocalizedStringResource {
            switch layer {
            case .emotion: .meChartBetterEmotion
            case .behavior: .meChartBetterBehavior
            case .selfEfficacy: .meChartBetterSelfEfficacy
            }
        }
        static func chartWorse(_ layer: MeasurementLayer) -> LocalizedStringResource {
            switch layer {
            case .emotion: .meChartWorseEmotion
            case .behavior: .meChartWorseBehavior
            case .selfEfficacy: .meChartWorseSelfEfficacy
            }
        }
        static let chartBaseline: LocalizedStringResource = .meChartBaseline
        static let chartXAxis: LocalizedStringResource = .meChartXAxis
        static let chartYAxis: LocalizedStringResource = .meChartYAxis
        static let chartBaselinePoint: LocalizedStringResource = .meChartBaselinePoint
        static let mostChanged: LocalizedStringResource = .meMostChanged
        static let leastChanged: LocalizedStringResource = .meLeastChanged
        static let howWeMeasure: LocalizedStringResource = .meHowWeMeasure

        // MARK: Defter

        static let journalTitle: LocalizedStringResource = .meJournalTitle
        static let journalAll: LocalizedStringResource = .meJournalAll
        static func journalOrigin(date: String) -> LocalizedStringResource {
            .meJournalOrigin(date)
        }
        static func journalAvoidance(date: String) -> LocalizedStringResource {
            .meJournalAvoidance(date)
        }
        static func journalAfterStep(day: Int, date: String) -> LocalizedStringResource {
            .meJournalAfterStep(day, date)
        }
        static func journalQuestion(_ question: String) -> LocalizedStringResource {
            .meJournalQuestion(question)
        }
        static let journalEmpty: LocalizedStringResource =
            .meJournalEmpty
        static let journalHidden: LocalizedStringResource = .meJournalHidden
        static let journalDelete: LocalizedStringResource = .meJournalDelete
        static let journalDeleteTitle: LocalizedStringResource = .meJournalDeleteTitle
        static let journalDeleteBody: LocalizedStringResource =
            .meJournalDeleteBody
        static let journalDeleteOriginBody: LocalizedStringResource =
            .meJournalDeleteOriginBody
        static let journalDeleteFailed: LocalizedStringResource =
            .meJournalDeleteFailed
        static let reminderOffValue: LocalizedStringResource = .meReminderOffValue
        static let thisWeek: LocalizedStringResource = .meThisWeek
        static let lastWeek: LocalizedStringResource = .meLastWeek
        static let today: LocalizedStringResource = .meToday
        static let yesterday: LocalizedStringResource = .meYesterday

        // MARK: Yürüdüğün yollar

        static let pathsTitle: LocalizedStringResource = .mePathsTitle
        static let pathJustStarted: LocalizedStringResource = .mePathJustStarted
        static func pathActive(walked: Int) -> LocalizedStringResource { .mePathActive(walked) }
        static let pathCompleted: LocalizedStringResource = .mePathCompleted
        /// Yapılanı say, yapılmayanı sayma (İ2): "13 adım kaldı" yazılmaz.
        static func pathStopped(walked: Int) -> LocalizedStringResource { .mePathStopped(walked) }
        static let pathStoppedDetail: LocalizedStringResource = .mePathStoppedDetail
        static let pathClearProgress: LocalizedStringResource = .mePathClearProgress
        static let pathPartialProgress: LocalizedStringResource = .mePathPartialProgress
        static func pathDays(_ days: Int) -> LocalizedStringResource { .mePathDays(days) }
        static func pathSteps(_ steps: Int) -> LocalizedStringResource { .mePathSteps(steps) }
        static func pathDateRange(start: String, end: String) -> LocalizedStringResource {
            .mePathDateRange(start, end)
        }
        static let pathJournalTitle: LocalizedStringResource = .mePathJournalTitle
        static func sealAccessibility(title: String, detail: String) -> LocalizedStringResource {
            .meSealAccessibility(title, detail)
        }

        // MARK: Sana göre ayarlananlar

        static let preferencesTitle: LocalizedStringResource = .mePreferencesTitle
        static let reminderLabel: LocalizedStringResource = .meReminderLabel
        /// Sorduğumuz her şeyin karşılığı görünür olmalı: saat, kullanıcının B3
        /// cevabından geldiyse bu satır onu söyler.
        static func reminderSource(_ answer: String) -> LocalizedStringResource {
            .meReminderSource(answer)
        }
        static let reminderOff: LocalizedStringResource = .meReminderOff
        static let reminderToggle: LocalizedStringResource = .meReminderToggle
        static let reminderTimeLabel: LocalizedStringResource = .meReminderTimeLabel
        static let reminderDenied: LocalizedStringResource =
            .meReminderDenied
        static let openSettings: LocalizedStringResource = .meOpenSettings
        static let toneLabel: LocalizedStringResource = .meToneLabel
        /// Uzunluk, ton ve ses path üretilirken sunucuya gidiyor; sonradan
        /// değiştirmenin bir karşılığı henüz yok. Değişmiyormuş gibi davranan bir
        /// düğme koymak yerine bunu söylüyoruz.
        static let preferencesFootnote: LocalizedStringResource =
            .mePreferencesFootnote

        // MARK: Kimlik kartı (Ben v2)

        static let settingsButton: LocalizedStringResource = .meSettingsButton
        static let photoTitle: LocalizedStringResource = .mePhotoTitle
        static let photoChoose: LocalizedStringResource = .mePhotoChoose
        static let photoRemove: LocalizedStringResource = .mePhotoRemove
        static let photoFailed: LocalizedStringResource =
            .mePhotoFailed
        static let photoAccessibility: LocalizedStringResource = .mePhotoAccessibility
        static func weekDays(_ count: Int) -> LocalizedStringResource {
            .meWeekDays(count)
        }
        /// Kimlik kartı VoiceOver'da tek öğe: ad, yol, adım ve faz, hafta.
        static func identityAccessibility(parts: [String]) -> LocalizedStringResource {
            "\(parts.joined(separator: ", "))"
        }

        // MARK: Defter kartı

        static let journalCardInvite: LocalizedStringResource =
            .meJournalCardInvite
        static let journalCardWrite: LocalizedStringResource = .meJournalCardWrite
        static let journalCardOpenHint: LocalizedStringResource = .meJournalCardOpenHint
        static let journalCardLabel: LocalizedStringResource = .meJournalCardLabel

        // MARK: Defter sayfası ve not yazma

        static let journalNewNote: LocalizedStringResource = .meJournalNewNote
        static let journalEditNote: LocalizedStringResource = .meJournalEditNote
        static let journalEdit: LocalizedStringResource = .meJournalEdit
        static func journalNoteCaption(date: String) -> LocalizedStringResource { .meJournalNoteCaption(date) }
        static let journalOwnNote: LocalizedStringResource = .meJournalOwnNote
        static let notePlaceholder: LocalizedStringResource = .meNotePlaceholder
        static func noteRemaining(_ count: Int) -> LocalizedStringResource {
            .meNoteRemaining(count)
        }
        static let noteLimitReached: LocalizedStringResource = .meNoteLimitReached
        static let noteSaveFailed: LocalizedStringResource =
            .meNoteSaveFailed

        // MARK: Rozetler

        static let badgesTitle: LocalizedStringResource = .meBadgesTitle
        static let badgesAll: LocalizedStringResource = .meBadgesAll
        static let badgesFirstHint: LocalizedStringResource = .meBadgesFirstHint
        static let badgeLockedLabel: LocalizedStringResource = .meBadgeLockedLabel
        static func badgeAccessibility(title: String, detail: String, earned: Bool) -> LocalizedStringResource {
            earned ? .meBadgeAccessibilityEarned(title, detail) : .meBadgeAccessibility(title, detail)
        }

        /// Rozet adı, kazanıldığında söylenen tek cümle ve kazanma koşulu.
        ///
        /// Ton: 🟡 Sıcak (kriz ve Kova C'de 🔴 — orada kutlama yaprağı açılmaz,
        /// metin yalnızca rafta durur). Ünlem yok, "harika/tebrikler" yok; sayı
        /// yalnızca eşiğin kendisi.
        enum Badge {
            static func title(_ id: BadgeID) -> LocalizedStringResource {
                switch id {
                case .firstStep: .meBadgeTitleFirstStep
                case .phaseRelief: .meBadgeTitlePhaseRelief
                case .phaseAwareness: .meBadgeTitlePhaseAwareness
                case .phaseSkill: .meBadgeTitlePhaseSkill
                case .phaseBehavior: .meBadgeTitlePhaseBehavior
                case .phaseClosing: .meBadgeTitlePhaseClosing
                case .pathComplete: .meBadgeTitlePathComplete
                case .measureDay7: .meBadgeTitleMeasureDay7
                case .measureDay14: .meBadgeTitleMeasureDay14
                case .week3: .meBadgeTitleWeek3
                case .week5: .meBadgeTitleWeek5
                case .week7: .meBadgeTitleWeek7
                case .noteFirst: .meBadgeTitleNoteFirst
                case .note10: .meBadgeTitleNote10
                }
            }

            /// Kazanıldığında rozet yaprağında yazan cümle.
            static func earned(_ id: BadgeID) -> LocalizedStringResource {
                switch id {
                case .firstStep: .meBadgeEarnedFirstStep
                case .phaseRelief: .meBadgeEarnedPhaseRelief
                case .phaseAwareness: .meBadgeEarnedPhaseAwareness
                case .phaseSkill: .meBadgeEarnedPhaseSkill
                case .phaseBehavior: .meBadgeEarnedPhaseBehavior
                case .phaseClosing: .meBadgeEarnedPhaseClosing
                case .pathComplete: .meBadgeEarnedPathComplete
                case .measureDay7: .meBadgeEarnedMeasureDay7
                case .measureDay14: .meBadgeEarnedMeasureDay14
                case .week3: .meBadgeEarnedWeek3
                case .week5: .meBadgeEarnedWeek5
                case .week7: .meBadgeEarnedWeek7
                case .noteFirst: .meBadgeEarnedNoteFirst
                case .note10: .meBadgeEarnedNote10
                }
            }

            /// Kilitli rozetin altında yazan tek cümle. İlerleme çubuğu ya da
            /// "3/5" yok: sayaç, geri sayan bir sayıyla aynı baskıyı kurar.
            static func howToEarn(_ id: BadgeID) -> LocalizedStringResource {
                switch id {
                case .firstStep: .meBadgeHowToEarnFirstStep
                case .phaseRelief: .meBadgeHowToEarnPhaseRelief
                case .phaseAwareness: .meBadgeHowToEarnPhaseAwareness
                case .phaseSkill: .meBadgeHowToEarnPhaseSkill
                case .phaseBehavior: .meBadgeHowToEarnPhaseBehavior
                case .phaseClosing: .meBadgeHowToEarnPhaseClosing
                case .pathComplete: .meBadgeHowToEarnPathComplete
                case .measureDay7: .meBadgeHowToEarnMeasureDay7
                case .measureDay14: .meBadgeHowToEarnMeasureDay14
                case .week3: .meBadgeHowToEarnWeek3
                case .week5: .meBadgeHowToEarnWeek5
                case .week7: .meBadgeHowToEarnWeek7
                case .noteFirst: .meBadgeHowToEarnNoteFirst
                case .note10: .meBadgeHowToEarnNote10
                }
            }

            static func family(_ family: BadgeID.Family) -> LocalizedStringResource {
                switch family {
                case .path: .meBadgeFamilyPath
                case .measurement: .meBadgeFamilyMeasurement
                case .streak: .meBadgeFamilyStreak
                case .journal: .meBadgeFamilyJournal
                }
            }
        }

        // MARK: Destek, uygulama, hesap

        static let supportTitle: LocalizedStringResource = .meSupportTitle
        static let supportSubtitle: LocalizedStringResource = .meSupportSubtitle
        static let continuePathTitle: LocalizedStringResource = .meContinuePathTitle
        static func continuePathCaption(remaining: Int) -> LocalizedStringResource { .meContinuePathCaption(remaining) }
        static let continuePathCTA: LocalizedStringResource = .meContinuePathCTA
        static func continuePathProgress(walked: Int, total: Int) -> LocalizedStringResource {
            .meContinuePathProgress(walked, total)
        }
        static func continuePathCardLabel(remaining: Int) -> LocalizedStringResource { .meContinuePathCardLabel(remaining) }
        static let settingsRow: LocalizedStringResource = .meSettingsRow
        static let anonymousTitle: LocalizedStringResource = .meAnonymousTitle
        static let linkAccount: LocalizedStringResource = .meLinkAccount
        static let anonymousBody: LocalizedStringResource =
            .meAnonymousBody
        static func version(_ version: String, build: String) -> LocalizedStringResource {
            .meVersion(version, build)
        }

        enum Settings {
            static let title: LocalizedStringResource = .meSettingsTitle
            static let reminderHeader: LocalizedStringResource = .meSettingsReminderHeader
            static let notificationPrivacy: LocalizedStringResource =
                .meSettingsNotificationPrivacy
            static let privacyHeader: LocalizedStringResource = .meSettingsPrivacyHeader
            static let appLock: LocalizedStringResource = .meSettingsAppLock
            static let appLockFooter: LocalizedStringResource =
                .meSettingsAppLockFooter
            static let appLockUnavailable: LocalizedStringResource =
                .meSettingsAppLockUnavailable
            static let hideJournal: LocalizedStringResource = .meSettingsHideJournal
            static let analytics: LocalizedStringResource = .meSettingsAnalytics
            static let analyticsFooter: LocalizedStringResource =
                .meSettingsAnalyticsFooter
            static let dataHeader: LocalizedStringResource = .meSettingsDataHeader
            static let export: LocalizedStringResource = .meSettingsExport
            static let exportPreview: LocalizedStringResource = .meSettingsExportPreview
            static let exportFooter: LocalizedStringResource =
                .meSettingsExportFooter
            static let deleteJournal: LocalizedStringResource = .meSettingsDeleteJournal
            static let deleteJournalTitle: LocalizedStringResource =
                .meSettingsDeleteJournalTitle
            static let deleteJournalBody: LocalizedStringResource =
                .meSettingsDeleteJournalBody
            static let deleteAccount: LocalizedStringResource = .meSettingsDeleteAccount
            static let deleteAccountTitle: LocalizedStringResource =
                .meSettingsDeleteAccountTitle
            static let deleteAccountBody: LocalizedStringResource =
                .meSettingsDeleteAccountBody
            static let deleteAccountFailed: LocalizedStringResource =
                .meSettingsDeleteAccountFailed
            static let nameFailed: LocalizedStringResource =
                .meSettingsNameFailed
            static let accountHeader: LocalizedStringResource = .meSettingsAccountHeader
            static let nameRow: LocalizedStringResource = .meSettingsNameRow
            /// Sayfa başlığı: `nameRow` gezinme çubuğunda düğmenin yanında kırpılıyordu.
            static let nameTitle: LocalizedStringResource = .meSettingsNameTitle
            static let nameNone: LocalizedStringResource = .meSettingsNameNone
            static let namePlaceholder: LocalizedStringResource = .meSettingsNamePlaceholder
            static let nameHint: LocalizedStringResource =
                .meSettingsNameHint
            static let linkedRow: LocalizedStringResource = .meSettingsLinkedRow
            static let linkedYes: LocalizedStringResource = .meSettingsLinkedYes
            static let linkedNo: LocalizedStringResource = .meSettingsLinkedNo
            static let signOut: LocalizedStringResource = .meSettingsSignOut
            static let signOutTitle: LocalizedStringResource = .meSettingsSignOutTitle
            static let signOutBody: LocalizedStringResource = .meSettingsSignOutBody
            static let aboutHeader: LocalizedStringResource = .meSettingsAboutHeader
            static let versionRow: LocalizedStringResource = .meSettingsVersionRow
            static let irreversibleHeader: LocalizedStringResource = .meSettingsIrreversibleHeader
            static let eraseLocal: LocalizedStringResource = .meSettingsEraseLocal
            static let eraseFooter: LocalizedStringResource =
                .meSettingsEraseFooter
            static let eraseTitle: LocalizedStringResource = .meSettingsEraseTitle
        }

        enum Method {
            static let title: LocalizedStringResource = .meMethodTitle
            static let intro: LocalizedStringResource =
                .meMethodIntro
            static let layersTitle: LocalizedStringResource = .meMethodLayersTitle
            static let emotion: LocalizedStringResource =
                .meMethodEmotion
            static let behavior: LocalizedStringResource =
                .meMethodBehavior
            static let selfEfficacy: LocalizedStringResource =
                .meMethodSelfEfficacy
            static let rotationTitle: LocalizedStringResource = .meMethodRotationTitle
            static let rotation: LocalizedStringResource =
                .meMethodRotation
            static let clinicalTitle: LocalizedStringResource = .meMethodClinicalTitle
            static let clinical: LocalizedStringResource =
                .meMethodClinical
        }
    }

    /// Destek al — 🔴 Nötr kademe. Süsleme yok, hareket yok, satış yok.
    ///
    /// Metinler `Localizable.xcstrings`te. **Numara cihaz bölgesinden**
    /// (`SupportResources.lines`); metin dili şimdilik yalnızca İngilizce.
    enum Support {
        static var title: LocalizedStringResource { .supportTitle }
        static var body: LocalizedStringResource { .supportBody }
        static var call: LocalizedStringResource { .supportCall }
        static var close: LocalizedStringResource { .supportClose }
        /// "ALO 183, 183. Tap to call." Cümle parçaları katalogdan, birleşim burada.
        static func callAccessibility(name: String, number: String) -> String {
            "\(name), \(number). \(String(localized: .supportTapToCall))"
        }
        static var directory: LocalizedStringResource { .supportDirectory }
        static var notEmergencyService: LocalizedStringResource { .supportNotEmergencyService }
        static var emergencyName: LocalizedStringResource { .supportEmergencyName }
        static var emergencyDetail: LocalizedStringResource { .supportEmergencyDetail }
        static var trSocialSupportName: LocalizedStringResource { .supportTrSocialSupportName }
        static var trSocialSupportDetail: LocalizedStringResource { .supportTrSocialSupportDetail }
        static var deTelefonSeelsorgeName: LocalizedStringResource { .supportDeTelefonSeelsorgeName }
        static var deTelefonSeelsorgeDetail: LocalizedStringResource { .supportDeTelefonSeelsorgeDetail }
        static var us988Name: LocalizedStringResource { .supportUs988Name }
        static var us988Detail: LocalizedStringResource { .supportUs988Detail }
        static var gbSamaritansName: LocalizedStringResource { .supportGbSamaritansName }
        static var gbSamaritansDetail: LocalizedStringResource { .supportGbSamaritansDetail }
    }

    /// Yol içi ölçüm — 🟠 Sakin. Sınav değil; skor ve yorum yok.
    enum PathMeasurement {
        static func introHeadline(_ count: Int) -> LocalizedStringResource {
            .pathMeasurementIntroHeadline(count)
        }
        static let introBody: LocalizedStringResource =
            .pathMeasurementIntroBody
        static let introCTA: LocalizedStringResource = .pathMeasurementIntroCTA
        static let saveError: LocalizedStringResource =
            .pathMeasurementSaveError
        static let completionError: LocalizedStringResource =
            .pathMeasurementCompletionError
    }

    enum AppLock {
        static let title: LocalizedStringResource = .appLockTitle
        static let body: LocalizedStringResource = .appLockBody
        static let unlock: LocalizedStringResource = .appLockUnlock
        static let reason: LocalizedStringResource = .appLockReason
    }
}
