import SwiftUI

/// "Ben" sayfasının en üstündeki kısa guaj çayır şeridi. Zemin (koyu orman ve
/// düşük genlikli mesh) sayfanın kendisinde; bu katman yalnızca şeridi çizer.
///
/// Şerit aşağı doğru zemine karışır ve sayfa kaydıkça solar; en fazla 10 pt
/// parallax. Yalnızca dekor: veri, ilerleme ya da durum anlatmaz.
///
/// Hiçbir şey çizmez: kriz modunda (`showsArtwork` false), Reduce Transparency
/// açıkken ve erişilebilir Dynamic Type boyutlarında (şerit içeriği aşağı
/// iterdi). Bu durumlarda sayfa düz koyu zeminde kalır.
struct MeBackdrop: View {
    /// Kaydırma miktarı (pt). Yukarı kaydırınca pozitif.
    var scrollOffset: CGFloat = 0
    var showsArtwork = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let height: CGFloat = 260

    var body: some View {
        ZStack(alignment: .top) {
            if showsArtwork, !reduceTransparency, !dynamicTypeSize.isAccessibilitySize, PatikaArt.exists("me-backdrop") {
                // Boyutu şeffaf bir çerçeve belirler, görsel `overlay`de kırpılır:
                // `scaledToFill` bir görselin ideal genişliği piksel boyutudur ve
                // yerleşimde durursa üst `ZStack`i (ve sayfayı) ekrandan geniş yapar.
                Color.clear
                    .frame(height: Self.height)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .top) {
                        Image(decorative: "me-backdrop")
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white.opacity(0.85), location: 0.35),
                                .init(color: .clear, location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .opacity(fade)
                    .offset(y: parallax)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .ignoresSafeArea()
    }

    /// Şerit ilk 220 pt kaydırmada solar; Reduce Motion'da yalnızca solma, kayma
    /// yok.
    private var fade: Double {
        max(0, 1 - Double(max(scrollOffset, 0)) / 220)
    }

    private var parallax: CGFloat {
        reduceMotion ? 0 : -min(10, max(0, scrollOffset) * 0.04)
    }
}
