import SwiftUI
import SwiftData

@main
struct PatikaApp: App {
    @State private var paletteController = PaletteController()
    @State private var appState = AppState()
    @State private var services = AppServices.live()
    @State private var discoverLibrary = DiscoverLibrary()
    @State private var isEntryPrepared = !Self.opensRootDirectly
    /// Onboarding tamamlanmamış görünen ama sunucuda patikası olan kullanıcı
    /// kontrolü bitene kadar giriş ekranı çizilmez; onboarding'in bir an
    /// görünüp kaybolması yanıp sönme olurdu.
    @State private var isOnboardingStateResolved = false

    /// Release'te her zaman false — `DebugDirectEntry` yalnızca DEBUG'ta var.
    private static var opensRootDirectly: Bool {
        #if DEBUG
        DebugDirectEntry.opensRoot
        #else
        false
        #endif
    }

    /// Onboarding'in son ekranına gelmeden (H1) uygulama kapatıldıysa yerel
    /// "tamamlandı" işareti hiç yazılmaz; sonraki açılış onboarding'i baştan
    /// başlatır ve ikinci bir patika üretirdi. Sunucuda bu kimliğe ait bir patika
    /// varsa onboarding'in işi bitmiştir: kalan ekran yalnızca hesap bağlama
    /// teklifi ve o da "Ben" sekmesinde duruyor.
    ///
    /// Yalnızca cihazda kayıtlı oturum varsa sorar (ilk kurulumda sunucuya gitmez)
    /// ve dört saniyede vazgeçer: çevrimdışı açılış splash'te takılmasın.
    private func adoptExistingPathIfAny() async {
        guard await services.auth.hasStoredSession() else { return }
        let lookup = Task { @MainActor () -> Bool in
            guard let token = try? await services.auth.validAccessToken(),
                  let path = try? await services.backend.activePath(accessToken: token)
            else { return false }
            return !path.steps.isEmpty
        }
        let timeout = Task {
            try? await Task.sleep(for: .seconds(4))
            lookup.cancel()
        }
        let found = await lookup.value
        timeout.cancel()
        if found { appState.hasCompletedOnboarding = true }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !isEntryPrepared || !isOnboardingStateResolved {
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
                if !appState.hasCompletedOnboarding, !Self.opensRootDirectly {
                    await adoptExistingPathIfAny()
                }
                isOnboardingStateResolved = true
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
