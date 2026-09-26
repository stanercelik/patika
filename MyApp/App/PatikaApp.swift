import GoogleSignIn
import SwiftUI
import SwiftData

@main
struct PatikaApp: App {
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

    private static var opensOnboardingStepDirectly: Bool {
        #if DEBUG
        DebugDirectEntry.opensOnboardingStep
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
                        WoodlandStyle.background.ignoresSafeArea()
                        ProgressView().tint(Theme.textPrimary.color)
                    }
                } else if appState.hasCompletedOnboarding || Self.opensRootDirectly {
                    RootView()
                } else {
                    OnboardingContainerView(services: services) {
                        appState.hasCompletedOnboarding = true
                    }
                }
            }
            .environment(appState)
            .environment(services)
            .environment(discoverLibrary)
            // PRD karar #14: uygulama koyu moda sabit. Açık modda gradyan
            // interpolasyonu öngörülemeyen ara tonlar üretiyor; meditasyon
            // ürünü için de doğru karar.
            .preferredColorScheme(.dark)
            // Google Sign-In'in sistem tarayıcısından döndüğü OAuth geri çağırması
            // (reversed client ID URL scheme) burada tamamlanır; GoogleSignIn SDK'sı
            // bunu kendi bekleyen giriş isteğine eşler.
            .onOpenURL { url in
                _ = GIDSignIn.sharedInstance.handle(url)
            }
            #if DEBUG
            .modifier(PathPreviewEnvironment())
            #endif
            // DEBUG'ta `-patika-debug-step yolum` doğrudan kabuğu açar ve
            // gerekirse gerçek path üretimini tetikler. Release'te bu blok yok.
            .task {
                // RevenueCat identity is always the Supabase UUID, including
                // anonymous sessions. Account linking preserves that UUID.
                if let _ = try? await services.auth.validAccessToken(),
                   let userID = services.auth.session?.userID {
                    try? await services.purchases.configure(for: userID)
                }
                if !appState.hasCompletedOnboarding, !Self.opensRootDirectly, !Self.opensOnboardingStepDirectly {
                    await adoptExistingPathIfAny()
                }
                isOnboardingStateResolved = true
                #if DEBUG
                await DebugDirectEntry.prepareIfNeeded(services: services)
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
