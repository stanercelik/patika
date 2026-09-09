import SwiftUI

/// Onboarding kabuğu: arka planı, üst çubuğu ve adım geçişlerini sahiplenir.
///
/// **Kabuk adım değişirken yeniden kurulmaz.** Arka plan, geri butonu ve ilerleme
/// izi burada bir kez oluşur ve yerinde kalır; yalnızca ortadaki içerik solup
/// beliriyor. Önceki hâlde her ekran kendi üst çubuğunu çiziyordu ve geçişte
/// buton gidip geliyor, iz sıfırdan doluyordu — akış tek bir yol değil, 31 ayrı
/// ekran gibi görünüyordu (ürün sahibi kararı, 2026-09-08).
struct OnboardingContainerView: View {
    @Environment(PaletteController.self) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flow: OnboardingFlowViewModel

    init(palette: PaletteController, services: AppServices, onFinished: @escaping () -> Void) {
        self._flow = State(
            initialValue: OnboardingFlowViewModel(
                palette: palette,
                services: services,
                onFinished: onFinished
            )
        )
    }

    var body: some View {
        ZStack {
            BreathingMeshBackground(
                palette: palette.current,
                safeY: flow.step.backgroundSafeY,
                breathAmplitude: breathAmplitude,
                boostsFrameRate: palette.isTransitioning
            )

            VStack(spacing: 0) {
                OnboardingHeader(
                    showsBack: flow.step.canGoBack,
                    progress: flow.step.progress,
                    onBack: { flow.goBack() }
                )

                // Geçiş sırasında iki ekran kısa süre üst üste bulunur; ZStack
                // yerleşimi sabit tutar, VStack olsa yükseklik farkı zıplatırdı.
                ZStack {
                    content
                        .transition(.onboardingStep(reduceMotion: reduceMotion))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        #if DEBUG
        // Akışı ileri sarma — yalnızca DEBUG. Kabukta duruyor ki her adımdan
        // erişilebilsin; ekranların hiçbiri bunu bilmiyor.
        .overlay(alignment: .topTrailing) {
            OnboardingDebugSkipButton(flow: flow)
                .padding(.trailing, 4)
        }
        .task { flow.applyDebugLaunchStepIfNeeded() }
        #endif
        .animation(Theme.Motion.crossFade, value: flow.step)
    }

    @ViewBuilder
    private var content: some View {
        switch flow.step {
        case .a1Welcome:
            WelcomeView(flow: flow)
        case .identityName:
            NameView(flow: flow)
        case .identityGender:
            GenderView(flow: flow)
        case .identityAge:
            AgeRangeView(flow: flow)
        case .a2Categories:
            CategorySelectionView(flow: flow)
        case .b1ProblemText:
            ProblemTextView(flow: flow)
        case .b2Duration:
            DurationView(flow: flow)
        case .b3Timing:
            TimingView(flow: flow)
        case .b4Avoidance:
            AvoidanceView(flow: flow)
        case .b5PreviousAttempts:
            PreviousAttemptsView(flow: flow)
        case .b6CurrentMood:
            CurrentMoodView(flow: flow)
        case .c1Mirroring:
            MirroringView(flow: flow)
        case .c2NotAlone:
            NotAloneView(flow: flow)
        case .c3PathNotLibrary:
            PathNotLibraryView(flow: flow)
        case .c4HonestExpectation:
            HonestExpectationView(flow: flow)
        case .d0MeasurementIntro:
            MeasurementIntroView(flow: flow)
        case .dMeasurement(let index):
            // Sekiz soru aynı görünüm tipinden çiziliyor; kimlik verilmezse
            // SwiftUI ekranı yerinde tutup yalnızca içeriğini değiştiriyor —
            // ne geçiş oynuyor ne de soru ViewModel'i yenileniyor.
            MeasurementQuestionView(flow: flow, index: index)
                .id(index)
        case .e1Reminder:
            ReminderTimeView(flow: flow)
        case .e2SessionLength:
            SessionLengthView(flow: flow)
        case .e3Tone:
            TonePreferenceView(flow: flow)
        case .e4Voice:
            VoiceChoiceView(flow: flow)
        case .f1Generation:
            GenerationView(flow: flow)
        case .f2Roadmap:
            RoadmapView(flow: flow)
        case .g1FirstSession:
            FirstSessionView(flow: flow)
        case .g2SessionComplete:
            SessionCompleteView(flow: flow)
        case .h1Account:
            AccountLinkView(flow: flow)
        case .crisis:
            CrisisView()
        }
    }

    /// Genlik ekran grubuna ait bir özellik; kabuk yalnızca okuyor.
    private var breathAmplitude: Double { flow.step.breathAmplitude }
}

/// Henüz yazılmamış adımlar için dürüst yer tutucu.
///
/// Üst çubuk taşımaz — kabuk zaten çiziyor.
struct NotYetBuiltView: View {
    let step: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.stack) {
            Text(verbatim: step)
                .font(.title2.weight(Theme.Weight.title))
                .foregroundStyle(Theme.textPrimary.color)
            Text(verbatim: "Bu adım henüz yazılmadı.")
                .font(.body.weight(Theme.Weight.body))
                .foregroundStyle(Theme.textSecondary.color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
}

/// Kriz ekranı — PRD §11.1. Nötr — Nötr kademe: hareket yok, süsleme yok, satış yok.
/// Yer tutucudur; gerçek ekran yardım hatlarını ülkeye göre yerelleştirmeli ve
/// tek dokunuşla arama başlatmalıdır.
struct CrisisView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.stack) {
            Spacer()
            Text(verbatim: "Yazdığın şey ciddi ve önemli.")
                .font(.title2.weight(Theme.Weight.title))
                .foregroundStyle(Theme.textPrimary.color)
            Text(verbatim: """
                Bu uygulama bu konuda sana yardımcı olabilecek doğru yer değil — \
                ama yardım alabileceğin yerler var.
                """)
                .font(.body.weight(Theme.Weight.body))
                .foregroundStyle(Theme.textSecondary.color)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
}

/// Preview'lar için akış kurulumu.
///
/// Kabuğun üst çubuğunu da kurar — tek bir ekranı önizlerken de gerçek yerleşim
/// görünür, ekranlar çubuğu kendileri çizmediği için.
struct OnboardingPreviewHost<Content: View>: View {
    @State private var palette = PaletteController()
    var step: OnboardingStep = .a2Categories
    /// C ekranları taslağı okuyarak metin ürettiği için preview'da doldurulabilir.
    var draft = OnboardingDraft()
    let content: (OnboardingFlowViewModel) -> Content

    init(
        step: OnboardingStep = .a2Categories,
        draft: OnboardingDraft = OnboardingDraft(),
        @ViewBuilder content: @escaping (OnboardingFlowViewModel) -> Content
    ) {
        self.step = step
        self.draft = draft
        self.content = content
    }

    var body: some View {
        let flow = OnboardingFlowViewModel.preview(step: step, draft: draft, palette: palette)
        return ZStack {
            BreathingMeshBackground(
                palette: palette.current,
                safeY: step.backgroundSafeY,
                boostsFrameRate: palette.isTransitioning
            )
            VStack(spacing: 0) {
                OnboardingHeader(
                    showsBack: step.canGoBack,
                    progress: step.progress,
                    onBack: {}
                )
                content(flow)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environment(palette)
        .preferredColorScheme(.dark)
        .task {
            palette.select(draft.categories)
            palette.setMood(draft.currentMood)
        }
    }
}
