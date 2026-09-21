import SwiftUI

/// Onboarding'in yeni guaj parçaları (docs/onboarding-redesign.md, Bölüm 7;
/// prompt'lar `assets/illustrations/onboarding/prompts.md`).
///
/// Adlar burada, çağrı noktalarında ham metin yok. Hiçbiri zorunlu değil: varlık
/// pakette yoksa görsel **yer kaplamaz** ve ekran yalnızca metinle tam çalışır
/// (`-patika-debug-no-art` bunu denetler).
///
/// Renkli guaj yalnızca kâğıt kartta ya da karartılmış sahne zemininde durur, canlı
/// kategori mesh'inin üstünde asla: A2 ve B6'da mesh içeriktir.
enum OnboardingArtwork: String, CaseIterable {
    /// A1 — tam ekran opak sahne zemini.
    case threshold = "onboarding-threshold"
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

    var isAvailable: Bool { PatikaArt.exists(rawValue) }
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

/// Tam ekran opak sahne zemini (A1). Mesh'in üstünde durur ve onu tamamen örter; alt
/// kısımdaki karartma başlık ile düğmenin okunurluğunu sağlar. Dekoratif ve VoiceOver'dan gizli.
struct OnboardingSceneBackdrop: View {
    let artwork: OnboardingArtwork

    var body: some View {
        GeometryReader { geo in
            Image(decorative: artwork.rawValue)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.55), Color.black.opacity(0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.55)
                }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
