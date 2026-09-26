import Foundation

/// Keşfet arayüz metinleri. Metnin kendisi `Localizable.xcstrings`te; burada yalnızca
/// `String` isteyen çağrı yerleri (`Text(verbatim:)`, `Label`) için ince bir erişim var.
/// Ses ilk sürümde yalnızca İngilizce ve tek ses (kadın) — bu, `DiscoverLibrary`nin işi.
enum DiscoverCopy {
    static var personalBody: String { String(localized: .discoverPersonalBody) }
    static var personalAction: String { String(localized: .discoverPersonalAction) }
    static var cancel: String { String(localized: .discoverCancel) }
    static var collectionNote: String { String(localized: .discoverCollectionNote) }
    static var preview: String { String(localized: .discoverPreview) }
    static var previewNote: String { String(localized: .discoverPreviewNote) }
    static var join: String { String(localized: .discoverJoin) }
    static var joinTitle: String { String(localized: .discoverJoinTitle) }
    static var joinBody: String { String(localized: .discoverJoinBody) }
    static var steps: String { String(localized: .discoverSteps) }
    static var start: String { String(localized: .discoverStart) }
    static var replay: String { String(localized: .discoverReplay) }
    static var nextLocked: String { String(localized: .discoverNextLocked) }
    static var continuePath: String { String(localized: .discoverContinuePath) }
    static var ready: String { String(localized: .discoverReady) }
    static var completed: String { String(localized: .discoverCompleted) }
    static var completedBody: String { String(localized: .discoverCompletedBody) }
    static var close: String { String(localized: .discoverClose) }
    static var backToPath: String { String(localized: .discoverBackToPath) }
    static var quiet: String { String(localized: .discoverQuiet) }
    static var loading: String { String(localized: .discoverLoading) }
    static var audioUnavailable: String { String(localized: .discoverAudioUnavailable) }
    static var retry: String { String(localized: .discoverRetry) }
    static var catalogError: String { String(localized: .discoverCatalogError) }
    static var audioPreparing: String { String(localized: .discoverAudioPreparing) }
    static var duration: String { String(localized: .discoverDuration) }
    static var offline: String { String(localized: .discoverOffline) }
    static var done: String { String(localized: .discoverDone) }
    static var now: String { String(localized: .discoverNow) }
    static var allDone: String { String(localized: .discoverAllDone) }
    static var allDoneBody: String { String(localized: .discoverAllDoneBody) }
    static var saveError: String { String(localized: .discoverSaveError) }
    static var pause: String { String(localized: .discoverPause) }
    static var resume: String { String(localized: .discoverResume) }
    static var sectionRelief: String { String(localized: .discoverSectionRelief) }
    static var sectionRest: String { String(localized: .discoverSectionRest) }
    static var sectionAttention: String { String(localized: .discoverSectionAttention) }
    static var sectionToSelf: String { String(localized: .discoverSectionToSelf) }
    static var comingSoon: String { String(localized: .discoverComingSoon) }
    static var continuing: String { String(localized: .discoverContinuing) }
    static var headerTitle: String { String(localized: .discoverHeaderTitle) }
    static var expandHint: String { String(localized: .discoverExpandHint) }
    static var collapseHint: String { String(localized: .discoverCollapseHint) }
    static func progress(done: Int, total: Int) -> String {
        String(localized: .discoverProgress(done, total))
    }
    static func stepNumber(_ number: Int) -> String {
        String(localized: .discoverStepNumber(number))
    }
}
