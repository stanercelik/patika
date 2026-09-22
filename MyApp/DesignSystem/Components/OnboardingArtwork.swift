import SwiftUI

/// Onboarding'in guaj parçaları — hem kâğıt kart içi şeffaf kesitler hem tam ekran
/// opak sahneler (docs/onboarding-redesign.md, Faz 2 ve Bölüm 7'nin devamı; prompt'lar
/// `assets/illustrations/onboarding/prompts.md` ve `assets/illustrations/scenes/prompts.md`).
///
/// Adlar burada, çağrı noktalarında ham metin yok. Hiçbiri zorunlu değil: varlık
/// pakette yoksa görsel **yer kaplamaz** (kâğıt içi kesit) ya da düz zemine düşer
/// (tam ekran sahne) — `-patika-debug-no-art` bunu denetler.
enum OnboardingArtwork: String, CaseIterable {
    // MARK: - Kâğıt kart içi şeffaf kesitler (PAPER bloğu)

    case identity = "onboarding-identity"
    case timeOfDay = "onboarding-b-weather"
    case fork = "onboarding-c3-fork"
    case horizon = "onboarding-c4-horizon"
    case commit = "onboarding-commit"
    case stillPool = "onboarding-d0-still"
    /// F2 — sahne zemini üstünde.
    case pathReady = "illustration-f2-path-ready"
    case lantern = "onboarding-h2-lantern"
    case shelter = "onboarding-h1-shelter"

    // MARK: - Tam ekran opak sahneler (SCENE bloğu)

    /// A1 karşılama.
    case threshold = "onboarding-threshold"
    /// Kimlik: isim, cinsiyet, yaş.
    case gathering = "bg-gathering"
    /// C1–C4 ve taahhüt.
    case reflection = "bg-reflection"
    /// D0–D8.
    case measure = "bg-measure"
    /// E1, F1, F2.
    case prepare = "bg-prepare"
    /// G1 ve bütün Yolum oturumları.
    case session = "bg-session"
    /// G2, fiyat, H2, H1.
    case settle = "bg-settle"

    /// A2'den B6'ya kadar — seçilen (ya da henüz commit edilmemiş, canlı önizlenen)
    /// birincil kategoriye göre. `ProblemCategory` ile bire bir (`bg-category-<key>`).
    case categoryAnxiety = "bg-category-anxiety"
    case categorySleep = "bg-category-sleep"
    case categoryBurnout = "bg-category-burnout"
    case categoryFocus = "bg-category-focus"
    case categoryAnger = "bg-category-anger"
    case categorySelfcrit = "bg-category-selfcrit"
    case categorySocial = "bg-category-social"
    case categoryExam = "bg-category-exam"
    case categoryGrief = "bg-category-grief"
    case categoryUnnamed = "bg-category-unnamed"
    case timeMorning = "bg-time-morning"
    case timeDaytime = "bg-time-daytime"
    case timeEvening = "bg-time-evening"
    case timeNight = "bg-time-night"
    case timeNeutral = "bg-time-neutral"
    case moodVeiled = "bg-mood-veiled"
    case moodQuiet = "bg-mood-quiet"
    case moodBalanced = "bg-mood-balanced"
    case moodOpening = "bg-mood-opening"
    case moodClear = "bg-mood-clear"

    var isAvailable: Bool { PatikaArt.exists(rawValue) }

    var sceneTint: RGB? {
        switch self {
        case .timeMorning: WoodlandStyle.timeMorningTint
        case .timeDaytime: WoodlandStyle.timeDayTint
        case .timeEvening: WoodlandStyle.timeEveningTint
        case .timeNight: WoodlandStyle.timeNightTint
        case .timeNeutral: WoodlandStyle.timeNeutralTint
        case .moodVeiled: WoodlandStyle.moodVeiledTint
        case .moodQuiet: WoodlandStyle.moodQuietTint
        case .moodBalanced: WoodlandStyle.moodBalancedTint
        case .moodOpening: WoodlandStyle.moodOpeningTint
        case .moodClear: WoodlandStyle.moodClearTint
        default: nil
        }
    }

    /// Kategori sahnesi. Öfke için kırmızı yok — bu bir ürün kararı (öfkeli kullanıcıya
    /// kırmızı göstermek durumu pekiştirir), sahnesi de yeşil-teal bir akarsu.
    static func category(_ category: ProblemCategory) -> OnboardingArtwork {
        switch category {
        case .anxiety: .categoryAnxiety
        case .sleep: .categorySleep
        case .burnout: .categoryBurnout
        case .focus: .categoryFocus
        case .anger: .categoryAnger
        case .selfcrit: .categorySelfcrit
        case .social: .categorySocial
        case .exam: .categoryExam
        case .grief: .categoryGrief
        case .unnamed: .categoryUnnamed
        }
    }

    static func time(_ timing: ProblemTiming?) -> OnboardingArtwork {
        guard let timing else { return .timeNeutral }
        switch ReactiveSceneState.time(for: timing) {
        case .morning: return .timeMorning
        case .daytime: return .timeDaytime
        case .evening: return .timeEvening
        case .night: return .timeNight
        case .neutral: return .timeNeutral
        }
    }

    static func mood(_ level: MoodLevel?) -> OnboardingArtwork {
        guard let level else { return .moodBalanced }
        switch ReactiveSceneState.mood(for: level) {
        case .veiled: return .moodVeiled
        case .quiet: return .moodQuiet
        case .balanced: return .moodBalanced
        case .opening: return .moodOpening
        case .clear: return .moodClear
        }
    }
}

/// Kâğıt kartın içindeki (ya da sahne üstündeki) şeffaf parça. Varlık yoksa hiç yer
/// kaplamaz; Dynamic Type erişilebilirlik boyutlarında saklanır, çünkü metin ekranın
/// asıl içeriği ve görsel onu aşağı iterdi.
struct OnboardingArtworkView: View {
    let artwork: OnboardingArtwork
    var height: CGFloat = 150

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    var body: some View {
        if artwork.isAvailable, !dynamicTypeSize.isAccessibilitySize {
            Image(decorative: artwork.rawValue)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
