import SwiftUI

enum RootTab: Hashable {
    case path
    case discover
    case me

    static var initial: RootTab {
        #if DEBUG
        DebugDirectEntry.initialTab ?? .path
        #else
        .path
        #endif
    }
}

/// Bilgi mimarisi — PRD §6.
///
/// Üç sekme (Yolum / Keşfet / Ben). Ürün sahibi kararı (2026-09-17): sabit SOS
/// düğmesi ve nefes ekranı kaldırıldı; destek erişimi Ben sekmesindeki
/// "Destek al" kartında, kriz yakalaması serbest metin sınıflandırıcısında kalır.
struct RootView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.scenePhase) private var scenePhase

    @State private var selection = RootTab.initial
    /// İlk karede sahne henüz `.active` değil; perde yalnızca uygulama bir kez
    /// etkin olduktan sonra devreye girer, açılışta yanıp sönmesin.
    @State private var hasBeenActive = false

    var body: some View {
        TabView(selection: $selection) {
            Tab(.tabPath, systemImage: "point.topleft.down.to.point.bottomright.curvepath", value: RootTab.path) {
                MyPathView()
            }
            Tab(.tabDiscover, systemImage: "square.grid.2x2", value: RootTab.discover) {
                DiscoverView { selection = .path }
            }
            Tab(.tabMe, systemImage: "person", value: RootTab.me) {
                MeTab()
            }
        }
        .tint(Theme.textPrimary.color)
        .overlay { privacyLayer }
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active:
                hasBeenActive = true
                services.appLock.sceneBecameActive()
            case .background:
                services.appLock.sceneMovedToBackground()
            default:
                break
            }
        }
    }

    @ViewBuilder
    private var privacyLayer: some View {
        if services.appLock.isLocked {
            AppLockView(controller: services.appLock)
                .transition(.opacity)
        } else if hasBeenActive, scenePhase != .active {
            PrivacyShieldView()
        }
    }
}

// MARK: - Sekme iskeletleri
//
// Yolum `MyPathView`, Ben `MeView`. Hazır patikalar Keşfet'te kalır; Yolum yalnızca
// kişisel patikayı gösterir.

/// Kriz ekranı hariç her yerde kullanılabilir basit yerleşim.
struct ScreenPlaceholder: View {
    let title: LocalizedStringResource
    let message: LocalizedStringResource

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.stack) {
            Text(title)
                .font(.largeTitle.weight(Theme.Weight.title))
                .foregroundStyle(Theme.textPrimary.color)
            Text(message)
                .font(.body.weight(Theme.Weight.body))
                .foregroundStyle(Theme.textSecondary.color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 100)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
}

#Preview {
    RootView()
        .environment(PaletteController())
        .environment(AppServices.live())
        .environment(DiscoverLibrary())
        .preferredColorScheme(.dark)
}
