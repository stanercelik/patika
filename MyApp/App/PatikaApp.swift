import SwiftUI
import SwiftData

@main
struct PatikaApp: App {
    @State private var paletteController = PaletteController()
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    RootView()
                } else {
                    OnboardingContainerView(palette: paletteController) {
                        appState.hasCompletedOnboarding = true
                    }
                }
            }
            .environment(paletteController)
            .environment(appState)
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
