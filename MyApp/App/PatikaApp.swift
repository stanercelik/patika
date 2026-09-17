import SwiftUI
import SwiftData

@main
struct PatikaApp: App {
    @State private var paletteController = PaletteController()
    @State private var appState = AppState()
    @State private var services = AppServices.live()
    @State private var discoverLibrary = DiscoverLibrary()
    @State private var isEntryPrepared = !Self.opensRootDirectly

    /// Release'te her zaman false — `DebugDirectEntry` yalnızca DEBUG'ta var.
    private static var opensRootDirectly: Bool {
        #if DEBUG
        DebugDirectEntry.opensRoot
        #else
        false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !isEntryPrepared {
                    ZStack {
                        Palette.neutral.background.color.ignoresSafeArea()
                        ProgressView().tint(Theme.textPrimary.color)
                    }
                } else if appState.hasCompletedOnboarding || Self.opensRootDirectly {
                    RootView()
                } else {
                    OnboardingContainerView(palette: paletteController, services: services) {
                        appState.hasCompletedOnboarding = true
                    }
                }
            }
            .environment(paletteController)
            .environment(appState)
            .environment(services)
            .environment(discoverLibrary)
            // PRD karar #14: uygulama koyu moda sabit. Açık modda gradyan
            // interpolasyonu öngörülemeyen ara tonlar üretiyor; meditasyon
            // ürünü için de doğru karar.
            .preferredColorScheme(.dark)
            #if DEBUG
            .modifier(PathPreviewEnvironment())
            #endif
            // DEBUG'ta `-patika-debug-step yolum` doğrudan kabuğu açar ve
            // gerekirse gerçek path üretimini tetikler. Release'te bu blok yok.
            .task {
                // Palet uygulama yeniden açıldığında nötre düşüyordu: kategori ve
                // ruh hâli yalnızca onboarding belleğinde duruyordu.
                if let record = services.profile.record, !record.categories.isEmpty {
                    paletteController.select(record.categories)
                    paletteController.setMood(record.mood)
                }
                #if DEBUG
                await DebugDirectEntry.prepareIfNeeded(services: services, palette: paletteController)
                isEntryPrepared = true
                #endif
            }
        }
        .modelContainer(for: [
            UserProfile.self,
            ProblemStatement.self,
            ProgramPath.self,
            BadgeArtifact.self,
        ])
    }
}
