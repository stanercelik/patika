import SwiftUI

/// Uzun boyanmış çayır, eşleşen açıklıklardan tekrar ederek akar. Yalnızca yeni
/// karo opak bir öncekinin üstünde beliriyor: opaklık hiçbir yerde koyu boşluk
/// açmıyor.
///
/// ## Görselin ucu ekrana girmez
///
/// Sahne, kaydırılan içeriğin arka planı — yani manzara yolla birlikte akıyor,
/// sabit durmuyor. Bunun bedeli, içerik yüksekliği bittiğinde görselin de
/// bitmesiydi: en üste ya da en alta yaslanınca karonun ucu ve altındaki koyu
/// zemin görünüyordu (ürün sahibi geri bildirimi, 2026-09-17).
///
/// Çözüm ucu gizlemek değil, ucu ekranın dışına taşımak: içeriğin **üstüne bir,
/// altına bir** fazladan karo çiziliyor ve sahne artık kırpılmıyor. Bir karo
/// genişliğin üç katı (~1180 pt) olduğundan, esneme payı ne kadar olursa olsun
/// görselin bittiği yer görünür alana giremiyor.
struct PathLandscapeScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // Sendable closure main-actor özelliğini okuyamaz; karar closure'a
        // girmeden alınır.
        let allowsParallax = !reduceMotion
        return GeometryReader { geometry in
            if !reduceTransparency && !dynamicTypeSize.isAccessibilitySize {
                let height = geometry.size.width * 3
                let overlap = height * 0.12
                let stride = height - overlap
                let count = Int(ceil(geometry.size.height / stride)) + 1
                ZStack(alignment: .top) {
                    // -1: içeriğin başlangıcının üstünde kalan karo. Esnemede
                    // görünen yer burası.
                    ForEach(-1..<(count + 1), id: \.self) { index in
                        Image(decorative: "journey-world-continuous")
                            .resizable()
                            .frame(width: geometry.size.width, height: height)
                            .mask {
                                if index == -1 {
                                    Rectangle()
                                } else {
                                    LinearGradient(stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .black, location: 0.12),
                                        .init(color: .black, location: 1)
                                    ], startPoint: .top, endPoint: .bottom)
                                }
                            }
                            .offset(y: CGFloat(index) * stride)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                .visualEffect { content, proxy in
                    let y = proxy.frame(in: .scrollView(axis: .vertical)).minY
                    return content.offset(y: allowsParallax ? min(24, max(0, -y * 0.025)) : 0)
                }
                // Kırpma yok: fazladan karolar tam da çerçevenin dışında durup
                // esneme payını kapatmak için var.
                .ignoresSafeArea()
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
