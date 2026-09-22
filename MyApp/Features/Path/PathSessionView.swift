import SwiftUI

/// Onboarding sonrası bir adımın oturum ekranı.
///
/// G1 ile aynı sahne (`SessionStageView`), aynı motor ve aynı ses. Farkı sonu:
/// akış yönlendirmesi yerine adım tamamlanıp ekran kapanıyor; ölçüm günüyse
/// arada kısa bir ölçüm var.
///
/// Keşfet'in hazır patikaları da bu ekranı kullanır (`init(services:preparedPath:step:library:)`):
/// aynı sahne, aynı kontroller, aynı ses motoru. Onlarda soru, ölçüm ve rozet yok.
struct PathSessionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: PathSessionViewModel
    @State private var celebration: BadgeCelebrationItem?
    @State private var reflectionAnswer = ""

    init(services: AppServices, path: ActivePath, step: PathStepRecord) {
        _viewModel = State(initialValue: PathSessionViewModel(services: services, path: path, step: step))
    }

    init(services: AppServices, preparedPath: DiscoverPath, step: DiscoverStep, library: DiscoverLibrary) {
        _viewModel = State(initialValue: PathSessionViewModel(
            services: services,
            preparedPath: preparedPath,
            step: step,
            library: library
        ))
    }

    var body: some View {
        ZStack {
            // Kriz ekranında dekoratif sahne yok; kalanında `bg-session` — G1'le aynı
            // sahne, aynı motor (docs/onboarding-redesign.md, Faz 7).
            if viewModel.phase == .crisis {
                WoodlandStyle.background.ignoresSafeArea()
            } else {
                OnboardingSceneLayer(artwork: .session)
                // Yalnızca hazırlanırken: `.running`da faz görseli zaten nefesle ölçekleniyor
                // (`SessionArtworkView`), ikisi aynı anda ekrandaysa iki ayrı nefes hareketi
                // çakışıyordu (G1'de simülatörde ölçüldü, bkz. `FirstSessionView`).
                if viewModel.phase == .preparing {
                    BreathOrb(amplitude: viewModel.breathAmplitude, voiceEnergy: viewModel.runner.audio.audioEnergy)
                }
            }

            content
        }
        .task { viewModel.start() }
        .onDisappear { viewModel.teardown() }
        .animation(Theme.Motion.crossFade, value: viewModel.phase)
        .onChange(of: viewModel.phase) { _, phase in
            guard phase == .finished else { return }
            let badges = viewModel.badgesToCelebrate
            if !badges.isEmpty { celebration = BadgeCelebrationItem(badges: badges) }
        }
        .sheet(item: $celebration) { item in
            BadgeEarnedSheet(badges: item.badges)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .preparing:
            Text(Copy.Session.preparing)
                .font(.title3.weight(Theme.Weight.title))
                .foregroundStyle(Theme.textPrimary.color.opacity(0.75))
                .padding(.horizontal, Theme.Spacing.screenMargin)
        case .running:
            SessionStageView(
                runner: viewModel.runner,
                eyebrow: viewModel.stepEyebrow,
                artwork: viewModel.artwork
            )
                .padding(.horizontal, Theme.Spacing.screenMargin)
        case .question:
            // Soru **yalnızca kişiselleştirilmiş patikada** kuruluyor; karar
            // ViewModel'de.
            VStack(alignment: .leading, spacing: Theme.Spacing.stack) {
                Spacer()
                AdaptiveQuestionView(
                    answer: $reflectionAnswer,
                    question: viewModel.question ?? "",
                    isSubmitting: viewModel.isSubmitting,
                    showsError: viewModel.showsError,
                    onSave: { viewModel.submit(answer: $0, skipped: false) },
                    onSkip: { viewModel.submit(answer: nil, skipped: true) }
                )
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
        case .completing:
            completing
        case .measurementIntro:
            OnboardingStatementLayout(
                headline: Copy.PathMeasurement.introHeadline(viewModel.measurementItems.count),
                ctaTitle: Copy.PathMeasurement.introCTA,
                action: { viewModel.beginMeasurement() }
            ) {
                StatementParagraph(Copy.PathMeasurement.introBody)
                    .sequentialReveal(1)
                Text(Copy.clinicalDisclaimer)
                    .font(.caption.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textPrimary.color.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
                    .sequentialReveal(2)
                    .padding(.top, 4)
            }
            .padding(.top, 44)
        case .measurement(let index):
            if let item = viewModel.measurementItem(at: index) {
                PathMeasurementQuestionView(session: viewModel, item: item, index: index)
                    .id(index)
                    .padding(.top, 44)
                    .transition(.onboardingStep(reduceMotion: false))
            }
        case .finished:
            if viewModel.isPrepared {
                preparedFinished
            } else {
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
                .padding(.horizontal, Theme.Spacing.screenMargin)
            }
        case .audioUnavailable:
            audioUnavailable
        case .crisis:
            // Kriz ekranında hareket yok ve akış durur (PRD §11).
            CrisisView()
        }
    }

    /// Hazır patikanın sonu. "İlk adım tamam" değil: G2'nin cümlesi yalnızca
    /// ilk adım içindir. Yarıda bırakılınca "tamam" denmez.
    private var preparedFinished: some View {
        VStack(spacing: Theme.Spacing.stack) {
            Spacer()
            if viewModel.didReachEnd {
                Text(verbatim: viewModel.finishedPreparedPath ? DiscoverCopy.allDone : DiscoverCopy.completed)
                    .font(Theme.TypeFace.coverTitle)
                    .foregroundStyle(Theme.textPrimary.color)
                Text(verbatim: viewModel.finishedPreparedPath ? DiscoverCopy.allDoneBody : DiscoverCopy.completedBody)
                    .font(Theme.TypeFace.rowValue)
                    .foregroundStyle(Theme.textSecondary.color)
            } else {
                DisplayText(Copy.Session.leftEarlyHeadline, size: 30)
            }
            Spacer()
            DiscoverAction(title: DiscoverCopy.close) { dismiss() }
                .padding(.bottom, 12)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    /// Hazır patikanın kaydı çalınamadı. Adım tamamlanmadı ve kaybolmadı.
    private var audioUnavailable: some View {
        VStack(spacing: Theme.Spacing.stack) {
            Spacer()
            Text(verbatim: DiscoverCopy.audioUnavailable)
                .font(Theme.TypeFace.rowValue)
                .foregroundStyle(Theme.textPrimary.color)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            DiscoverAction(title: DiscoverCopy.retry) { viewModel.retryPrepared() }
            SecondaryTextButton(title: Copy.Session.leave) { dismiss() }
                .frame(minHeight: 44)
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    @ViewBuilder
    private var completing: some View {
        VStack(spacing: Theme.Spacing.stack) {
            Spacer()
            if viewModel.showsError {
                BodyText(Copy.PathMeasurement.completionError)
                    .multilineTextAlignment(.center)
                PrimaryButton(title: Copy.Path.retry, isEnabled: !viewModel.isSubmitting) {
                    viewModel.retryCompletion()
                }
                SecondaryTextButton(title: Copy.Session.leave) { dismiss() }
                    .frame(minHeight: 44)
            } else {
                ProgressView()
                    .tint(Theme.textPrimary.color)
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
}

/// Yol içi ölçüm sorusu — onboarding D bölümüyle aynı cevap biçimi ve aynı kural:
/// önceden doldurulmuş cevap yok, skor yok, iyi/kötü işareti yok.
private struct PathMeasurementQuestionView: View {
    let session: PathSessionViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var question: MeasurementQuestionViewModel

    init(session: PathSessionViewModel, item: MeasurementItem, index: Int) {
        self.session = session
        _question = State(initialValue: MeasurementQuestionViewModel(
            item: item,
            variant: session.measurementVariant,
            value: session.measurementResponse(for: item),
            commit: { session.commitMeasurementAnswer($0, at: index) }
        ))
    }

    var body: some View {
        OnboardingQuestionLayout(headline: question.prompt, hint: question.hint) {
            SceneContentPlate {
                VStack(alignment: .leading, spacing: 20) {
                    MeasurementAnswerView(question: question)

                    if session.showsError {
                        Text(Copy.PathMeasurement.saveError)
                            .font(.footnote.weight(Theme.Weight.body))
                            .foregroundStyle(WoodlandStyle.scenePlateSecondary.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(Copy.clinicalDisclaimer)
                        .font(.caption.weight(Theme.Weight.body))
                        .foregroundStyle(WoodlandStyle.scenePlateSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } footer: {
            OnboardingQuestionFooter(
                primaryTitle: Copy.Button.next,
                primaryDisabledTitle: question.usesIntensityScale
                    ? Copy.Onboarding.pickPointCTA
                    : Copy.Onboarding.chooseOneCTA,
                isPrimaryEnabled: question.canContinue && !session.isSubmitting,
                primaryAction: { question.submit() },
                skipTitle: session.showsError ? Copy.Session.leave : nil,
                skipAction: session.showsError ? { dismiss() } : nil
            )
        }
    }
}
