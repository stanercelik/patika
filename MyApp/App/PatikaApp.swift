import SwiftUI
import SwiftData

@main
struct PatikaApp: App {
    @State private var paletteController = PaletteController()
    @State private var appState = AppState()
    @State private var services = AppServices.live()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
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
            // PRD karar #14: uygulama koyu moda sabit. Açık modda gradyan
            // interpolasyonu öngörülemeyen ara tonlar üretiyor; meditasyon
            // ürünü için de doğru karar.
            .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            UserProfile.self,
            ProblemStatement.self,
            ProgramPath.self,
            BadgeArtifact.self,
        ])
    }
}
