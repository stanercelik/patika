import SwiftUI

/// Onboarding sonrası bir adımın oturum ekranı.
///
/// G1 ile aynı sahne (`SessionStageView`), aynı motor ve aynı ses. Farkı sonu:
/// akış yönlendirmesi yerine adım tamamlanıp ekran kapanıyor.
struct PathSessionView: View {
    @Environment(PaletteController.self) private var palette
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: PathSessionViewModel

    init(services: AppServices, path: ActivePath, step: PathStepRecord) {
        _viewModel = State(initialValue: PathSessionViewModel(services: services, path: path, step: step))
    }

    var body: some View {
        ZStack {
            BreathingMeshBackground(
                palette: palette.current,
                safeY: 0.5,
                breathAmplitude: BreathAmplitude.session,
                voiceEnergy: viewModel.runner.audio.audioEnergy
            )
            .ignoresSafeArea()

            content
                .padding(.horizontal, Theme.Spacing.screenMargin)
        }
        .task { viewModel.start() }
        .onDisappear { viewModel.teardown() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .preparing:
            Text(Copy.Session.preparing)
                .font(.title3.weight(Theme.Weight.title))
                .foregroundStyle(Theme.textPrimary.color.opacity(0.75))
        case .running:
            SessionStageView(runner: viewModel.runner)
        case .question:
            // Soru **yalnızca kişiselleştirilmiş patikada** kuruluyor; karar
            // ViewModel'de.
            VStack(alignment: .leading, spacing: Theme.Spacing.stack) {
                Spacer()
                AdaptiveQuestionView(
                    question: viewModel.question ?? "",
                    isSubmitting: viewModel.isSubmitting,
                    showsError: viewModel.showsError,
                    onSave: { viewModel.submit(answer: $0, skipped: false) },
                    onSkip: { viewModel.submit(answer: nil, skipped: true) }
                )
                Spacer()
            }
        case .finished:
            VStack(spacing: Theme.Spacing.stack) {
                Spacer()
                DisplayText(
                    viewModel.didReachEnd
                        ? Copy.Session.completedHeadline
                        : Copy.Session.leftEarlyHeadline,
                    size: 30
                )
                Spacer()
                PrimaryButton(title: Copy.Path.doneCTA, isEnabled: true) { dismiss() }
                    .padding(.bottom, 12)
            }
        case .crisis:
            // Kriz ekranında hareket yok ve akış durur (PRD §11).
            CrisisView()
        }
    }
}
