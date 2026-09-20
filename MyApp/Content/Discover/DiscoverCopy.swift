import Foundation

/// Arayüz metinleri `AppLocale`e uyar (TR/EN); çeviriler Discover.xcstrings'te.
/// Ses ilk sürümde yalnızca İngilizce — bu, `DiscoverLibrary.audioLocale`in işi.
enum DiscoverCopy {
    static var personalBody: String { localized("discover.personalBody") }
    static var personalAction: String { localized("discover.personalAction") }
    static var personalConfirm: String { localized("discover.personalConfirm") }
    static var personalConfirmBody: String { localized("discover.personalConfirmBody") }
    static var cancel: String { localized("discover.cancel") }
    static var collectionNote: String { localized("discover.collectionNote") }
    static var preview: String { localized("discover.preview") }
    static var previewNote: String { localized("discover.previewNote") }
    static var join: String { localized("discover.join") }
    static var joinTitle: String { localized("discover.joinTitle") }
    static var joinBody: String { localized("discover.joinBody") }
    static var voice: String { localized("discover.voice") }
    static var voiceNote: String { localized("discover.voiceNote") }
    static var feminine: String { localized("discover.feminine") }
    static var masculine: String { localized("discover.masculine") }
    static var steps: String { localized("discover.steps") }
    static var start: String { localized("discover.start") }
    static var replay: String { localized("discover.replay") }
    static var nextLocked: String { localized("discover.nextLocked") }
    static var continuePath: String { localized("discover.continuePath") }
    static var ready: String { localized("discover.ready") }
    static var completed: String { localized("discover.completed") }
    static var completedBody: String { localized("discover.completedBody") }
    static var close: String { localized("discover.close") }
    static var backToPath: String { localized("discover.backToPath") }
    static var quiet: String { localized("discover.quiet") }
    static var loading: String { localized("discover.loading") }
    static var audioUnavailable: String { localized("discover.audioUnavailable") }
    static var retry: String { localized("discover.retry") }
    static var catalogError: String { localized("discover.catalogError") }
    static var audioPreparing: String { localized("discover.audioPreparing") }
    static var duration: String { localized("discover.duration") }
    static var offline: String { localized("discover.offline") }
    static var done: String { localized("discover.done") }
    static var now: String { localized("discover.now") }
    static var allDone: String { localized("discover.allDone") }
    static var allDoneBody: String { localized("discover.allDoneBody") }
    static var saveError: String { localized("discover.saveError") }
    static var pause: String { localized("discover.pause") }
    static var resume: String { localized("discover.resume") }
    static var sectionRelief: String { localized("discover.section.relief") }
    static var sectionRest: String { localized("discover.section.rest") }
    static var sectionAttention: String { localized("discover.section.attention") }
    static var sectionToSelf: String { localized("discover.section.toSelf") }
    static var comingSoon: String { localized("discover.comingSoon") }
    static var continuing: String { localized("discover.continuing") }
    static var headerTitle: String { localized("discover.headerTitle") }
    static var expandHint: String { localized("discover.expandHint") }
    static var collapseHint: String { localized("discover.collapseHint") }
    static func progress(done: Int, total: Int) -> String {
        String(format: localized("discover.progress"), done, total)
    }
    static func stepNumber(_ number: Int) -> String {
        String(format: localized("discover.stepNumber"), number)
    }
    /// Çeviriyi `AppLocale`e göre **alt paketten** okur. `String(localized:locale:)`
    /// yalnızca biçimlendirmeyi etkiliyor, dili seçmiyor: cihaz İngilizce, bölge
    /// Türkiye iken içerik Türkçe ama arayüz İngilizce çıkıyordu.
    private static func localized(_ key: String) -> String {
        localizedBundle.localizedString(forKey: key, value: nil, table: "Discover")
    }

    private static var localizedBundle: Bundle {
        guard let path = Bundle.main.path(forResource: AppLocale.current.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }
}
