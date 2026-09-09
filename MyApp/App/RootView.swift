import SwiftUI

/// Bilgi mimarisi — PRD §6.
///
/// Üç sekme (Yolum / Keşfet / Ben) ve **her ekranda sabit** SOS butonu.
struct RootView: View {
    @Environment(PaletteController.self) private var palette
    @State private var isShowingSOS = false

    var body: some View {
        TabView {
            Tab("Yolum", systemImage: "point.topleft.down.to.point.bottomright.curvepath") {
                MyPathTab()
            }
            Tab("Keşfet", systemImage: "square.grid.2x2") {
                DiscoverTab()
            }
            Tab("Ben", systemImage: "person") {
                MeTab()
            }
        }
        .tint(Theme.textPrimary.color)
        // SOS her ekranda sağ üstte sabittir (PRD §6, §7.12).
        .overlay(alignment: .topTrailing) {
            SOSButton { isShowingSOS = true }
                .padding(.trailing, Theme.Spacing.stack)
        }
        .fullScreenCover(isPresented: $isShowingSOS) {
            SOSPlaceholderView()
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
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.calm)
        .accessibilityLabel("Acil sakinleşme")
        .accessibilityHint("Kısa bir nefes oturumu başlatır")
    }
}

// MARK: - Sekme iskeletleri
//
// Bunlar yapı yerleşimi için placeholder'dır. Gerçek ekranlar
// PRD §7 ve PRD-Ek-Onboarding'e göre ayrı dosyalarda yazılacak.

struct MyPathTab: View {
    var body: some View {
        MyPathView()
    }
}

struct DiscoverTab: View {
    @Environment(PaletteController.self) private var palette

    var body: some View {
        ZStack {
            // Keşfet nötr palet kullanır — kişisel path'e bağlı değil.
            BreathingMeshBackground(palette: Palette.neutral.nightAdjusted(), safeY: 0.20)
            ScreenPlaceholder(title: "Keşfet", message: Copy.Empty.noSearchResults)
        }
    }
}

struct MeTab: View {
    var body: some View {
        ZStack {
            BreathingMeshBackground(palette: Palette.neutral.nightAdjusted(), safeY: 0.20)
            ScreenPlaceholder(title: "Ben", message: Copy.Empty.noBadges)
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
        .preferredColorScheme(.dark)
}
