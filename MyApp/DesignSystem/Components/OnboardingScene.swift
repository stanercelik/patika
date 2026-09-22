import SwiftUI

/// Onboarding'in tam ekran sahne zemini (docs/onboarding-redesign.md, Faz 1–2).
///
/// Gradyan kalktı (2026-09-22): `MeshGradient` + Metal `grainAndScrim` shader'ı, 10
/// kategori paleti ve nefes hareketiyle sürülen mesh tamamen silindi. Yerine her bölüm
/// için tam ekran bir guaj sahnesi geldi — `OnboardingFlowViewModel.currentScene` hangi
/// sahnenin gösterileceğini, `currentSceneDimming` üstündeki düz karartmayı hesaplar.
///
/// Görsel eksikse (henüz üretilmedi, `-patika-debug-no-art`, Reduce Transparency ya da
/// AX Dynamic Type) düz `WoodlandStyle.background`'a düşer — hiçbir ekran kırılmaz.
/// Kriz ekranında `artwork` hep `nil`dir: krizde dekoratif görsel gösterilmez.
///
/// ## Sahneler birbirine erir, kesilmez
///
/// `Image`nin gösterdiği varlık adı **animatable bir özellik değil**: `artwork` A2'de
/// kategoriden kategoriye (`bg-category-sleep` → `bg-category-anxiety`) değişirken aynı
/// `if` dalı doğru kalmaya devam ettiği için SwiftUI görünümü kaldırıp yeniden eklemiyor,
/// yalnızca kaynağı yerinde değiştiriyordu — `.animation()` bunu yakalayamıyor ve sahne
/// sert bir kesme gibi değişiyordu (ürün sahibi geri bildirimi, 2026-09-22). Düzeltme:
/// `.id(artwork)` her sahneyi ayrı bir görünüm kimliğine bağlıyor, böylece kategori (ya da
/// bölüm) değiştiğinde eskisi **solarak çıkıyor**, yenisi **solarak giriyor** — ikisi aynı
/// `ZStack`te bir an üst üste biner ve göz bir kesme değil bir eriyiş görür. Süre bilerek
/// uzun (`Theme.Motion.palette`, 1,2 sn): tam ekran bir kimlik değişimi, eski palet
/// geçişiyle aynı gerekçeyle ("ani değişim irkiltir") aynı hızda yumuşatılıyor.
struct OnboardingSceneLayer: View {
    let artwork: OnboardingArtwork?
    var dimming: Double = 0.34

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var displayed: OnboardingArtwork?
    @State private var outgoing: OnboardingArtwork?
    @State private var displayedOpacity = 1.0
    @State private var outgoingOpacity = 0.0

    private func showsArt(_ candidate: OnboardingArtwork?) -> Bool {
        guard let artwork = candidate else { return false }
        return artwork.isAvailable && !reduceTransparency && !dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        ZStack {
            WoodlandStyle.background
            artworkLayer(outgoing)
                .opacity(outgoingOpacity)
            artworkLayer(displayed)
                .opacity(displayedOpacity)
        }
        .overlay(WoodlandStyle.background.opacity(dimming))
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(reduceMotion ? nil : Theme.Motion.crossFade, value: dimming)
        .onAppear { displayed = artwork }
        .onChange(of: artwork) { _, next in transition(to: next) }
    }

    @ViewBuilder
    private func artworkLayer(_ candidate: OnboardingArtwork?) -> some View {
        if showsArt(candidate), let candidate {
            GeometryReader { geo in
                Image(decorative: candidate.rawValue)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        }
    }

    private func transition(to next: OnboardingArtwork?) {
        guard next != displayed else { return }
        outgoing = displayed
        displayed = next
        guard !reduceMotion else {
            outgoing = nil
            outgoingOpacity = 0
            displayedOpacity = 1
            return
        }

        outgoingOpacity = 1
        displayedOpacity = 0
        withAnimation(Theme.Motion.palette) {
            outgoingOpacity = 0
            displayedOpacity = 1
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Theme.Motion.paletteTransition))
            guard displayed == next else { return }
            outgoing = nil
        }
    }
}
