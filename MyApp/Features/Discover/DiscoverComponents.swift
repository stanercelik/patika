import SwiftUI

/// Patikanın guaj görseli. Görsel pakette yoksa **hiç yer kaplamaz**
/// (`PatikaArt.exists`): `Image(decorative:)` eksik adı sessizce boş çizer ve
/// çerçevesinin boşluğunu bırakır.
///
/// Boyutu şeffaf bir çerçeve belirler, görsel `overlay`de kırpılır: `scaledToFill`
/// bir görselin ideal genişliği piksel boyutudur ve yerleşimde durursa kartı
/// ekrandan geniş yapar.
struct DiscoverArtwork: View {
    let name: String
    var height: CGFloat

    var body: some View {
        if PatikaArt.exists(name) {
            Color.clear
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .overlay { Image(decorative: name).resizable().scaledToFill() }
                .clipped()
                .accessibilityHidden(true)
        }
    }
}

/// Keşfet'in birincil eylemi. Yüzey **zeminde** (krem kapsül) ya da **kâğıtta**
/// (mürekkep kapsül) durabilir; Yolum'daki tabela düğmesiyle aynı ikinci hâl.
struct DiscoverAction: View {
    enum Surface { case ground, paper }

    let title: String
    var enabled = true
    var surface: Surface = .ground
    let action: () -> Void

    var body: some View {
        Button {
            Theme.softHaptic(intensity: 0.4)
            action()
        } label: {
            Text(title)
                .font(Theme.TypeFace.action)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(foreground)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(fill, in: Capsule())
        }
        .buttonStyle(.calm)
        .disabled(!enabled)
    }

    private var foreground: Color {
        switch (surface, enabled) {
        case (.ground, true): WoodlandStyle.ink
        case (.ground, false): Theme.textSecondary.color
        case (.paper, true): WoodlandStyle.paper
        case (.paper, false): WoodlandStyle.secondaryInk
        }
    }

    private var fill: Color {
        switch (surface, enabled) {
        case (.ground, true): Theme.textPrimary.color
        case (.ground, false): WoodlandStyle.surface
        case (.paper, true): WoodlandStyle.ink
        case (.paper, false): WoodlandStyle.secondaryInk.opacity(0.14)
        }
    }
}

/// Kaydırma miktarını **gözlemlenebilir bir kutuda** tutar; ekranın kendisi bu
/// değeri okumaz. Yalnızca hero katmanı okur, böylece her kaydırma pikselinde
/// bütün detay ekranı değil yalnızca hero yeniden çizilir.
@Observable @MainActor
final class ScrollOffsetBox {
    var offset: CGFloat = 0
}

extension View {
    /// DEBUG: `-patika-debug-discover-scroll <pt>` sayfayı o kadar kaydırır; simülatörde
    /// dokunmadan kaydırma davranışını (saklanan başlık, sönen hero, rota) görmek için.
    /// Release'te hiçbir şey yapmaz.
    func discoverDebugScroll() -> some View { modifier(DiscoverDebugScroll()) }
}

private struct DiscoverDebugScroll: ViewModifier {
    #if DEBUG
    @State private var position = ScrollPosition()

    func body(content: Content) -> some View {
        content
            .scrollPosition($position)
            .task {
                let args = ProcessInfo.processInfo.arguments
                guard let index = args.firstIndex(of: "-patika-debug-discover-scroll"),
                      args.indices.contains(index + 1), let offset = Double(args[index + 1]) else { return }
                try? await Task.sleep(for: .seconds(1.5))
                position.scrollTo(y: offset)
            }
    }
    #else
    func body(content: Content) -> some View { content }
    #endif
}
