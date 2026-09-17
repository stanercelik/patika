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
/// Üç sekme (Yolum / Keşfet / Ben) ve **her ekranda sabit** SOS butonu.
struct RootView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.scenePhase) private var scenePhase

    @State private var isShowingSOS = false
    @State private var selection = RootTab.initial
    /// İlk karede sahne henüz `.active` değil; perde yalnızca uygulama bir kez
    /// etkin olduktan sonra devreye girer, açılışta yanıp sönmesin.
    @State private var hasBeenActive = false

    var body: some View {
        TabView(selection: $selection) {
            Tab("Yolum", systemImage: "point.topleft.down.to.point.bottomright.curvepath", value: RootTab.path) {
                MyPathTab()
            }
            Tab("Keşfet", systemImage: "square.grid.2x2", value: RootTab.discover) {
                DiscoverView { selection = .path }
            }
            Tab("Ben", systemImage: "person", value: RootTab.me) {
                MeTab()
            }
        }
        .tint(Theme.textPrimary.color)
        .overlay { privacyLayer }
        // SOS her ekranda sağ üstte sabittir (PRD §6, §7.12) — kilidin de üstünde.
        .overlay(alignment: .topTrailing) {
            SOSButton { isShowingSOS = true }
                .padding(.trailing, Theme.Spacing.stack)
        }
        .fullScreenCover(isPresented: $isShowingSOS) {
            SOSPlaceholderView()
        }
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

/// PRD §7.12: iki dokunuşta ses başlar, önceden üretilmiş, ücretsiz, çevrimdışı.
/// Basılı tutunca büyür, bırakınca ses başlar — kaza koruması (Ton eki §2.2).
/// **Asla ücretli olmamalı.**
struct SOSButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("SOS")
                .font(.footnote.weight(Theme.Weight.action))
                .foregroundStyle(Theme.textPrimary.color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(minWidth: 44, minHeight: 44)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.calm)
        .accessibilityLabel("Acil sakinleşme")
        .accessibilityHint("Kısa bir nefes oturumu başlatır")
    }
}

// MARK: - Sekme iskeletleri
//
// Keşfet hâlâ yer tutucu. Yolum `MyPathView`, Ben `MeView`.

struct MyPathTab: View {
    @Environment(DiscoverLibrary.self) private var library
    var body: some View {
        if let path = library.activePath {
            DiscoverPathView(path: path, isPreview: false)
                .id(path.id)
        } else {
            MyPathView()
        }
    }
}

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

/// SOS ekranı — Nötr — Nötr kademe. Tek bir büyük nefes animasyonu, başka hiçbir şey.
/// Whimsy bütçesi 0 (Ton eki §4).
struct SOSPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            BreathingMeshBackground(
                palette: Palette.neutral,
                safeY: 0.85,
                breathAmplitude: BreathAmplitude.session
            )
            VStack {
                Spacer()
                Text("Birlikte nefes alalım.")
                    .font(.title3.weight(Theme.Weight.title))
                    .foregroundStyle(Theme.textPrimary.color)
                Button(Copy.Button.finish) { dismiss() }
                    .buttonStyle(.calm)
                    .foregroundStyle(Theme.textSecondary.color)
                    .padding(.top, Theme.Spacing.stack)
                    .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(PaletteController())
        .environment(AppServices.live())
        .environment(DiscoverLibrary())
        .preferredColorScheme(.dark)
}
