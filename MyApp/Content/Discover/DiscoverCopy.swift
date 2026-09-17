import Foundation

/// Discover launches in English. All interface translations live in Discover.xcstrings.
enum DiscoverCopy {
    static var title: String { localized("discover.title") }
    static var headline: String { localized("discover.headline") }
    static var intro: String { localized("discover.intro") }
    static var personalEyebrow: String { localized("discover.personalEyebrow") }
    static var personalTitle: String { localized("discover.personalTitle") }
    static var personalBody: String { localized("discover.personalBody") }
    static var personalAction: String { localized("discover.personalAction") }
    static var personalConfirm: String { localized("discover.personalConfirm") }
    static var personalConfirmBody: String { localized("discover.personalConfirmBody") }
    static var cancel: String { localized("discover.cancel") }
    static var collection: String { localized("discover.collection") }
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
    private static func localized(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), table: "Discover", locale: Locale(identifier: "en"))
    }
}
