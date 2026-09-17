import SwiftUI

/// Yolun üstünde yüzen, kompakt başlık.
///
/// ## Neden cam, neden kenardan kenara değil
///
/// Önce `.regularMaterial` kullanıyordu; o malzeme açık renkli gouache görselin
/// üstünde beyazlıyor ve ekranın üst üçte biri süt beyazı bir banda dönüşüyordu
/// (ürün sahibi geri bildirimi, 2026-09-17). Yerine sistemin Liquid Glass'ı:
/// arkasındaki manzarayı kırpmadan taşıyor, kendi rengi yok, koyu ya da açık
/// değil — altında ne varsa onun bulanık hâli.
///
/// Kenardan kenara da uzanmıyor. Yüzen bir gövde iki yanında görseli açık
/// bırakıyor; bant hâlindeki bir başlık manzarayı ikiye bölüyordu.
///
/// Yükseklik 280 pt'den ~130 pt'ye indi: `largeTitle` yerine `screenTitle`,
/// aralıklar 16'dan 6'ya.
struct PathHomeHeader: View {
    let title: String
    let hasNextStep: Bool
    let phase: PathPhase

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .accessibilityHidden(true)
                Text(Copy.Path.screenTitle)
                    .tracking(1.2)
            }
            .font(Theme.TypeFace.eyebrow)
            .foregroundStyle(Theme.textSecondary.color)

            Text(verbatim: title)
                .font(Theme.TypeFace.screenTitle)
                .foregroundStyle(Theme.textPrimary.color)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(hasNextStep ? Copy.Path.readyNote : Copy.Path.finishedHeadline)
                .font(Theme.TypeFace.screenNote)
                .foregroundStyle(Theme.textSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .modifier(WoodlandGlassSurface(cornerRadius: 26))
    }
}
