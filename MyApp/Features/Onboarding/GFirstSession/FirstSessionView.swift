import SwiftUI

/// G1 — ilk oturum (PRD-Ek Onboarding §8).
///
/// ## Ekranda tek bir cümle var
///
/// Meditasyon ekranı bir arayüz değil, bir alan. Sahne metni ortada duruyor ve
/// nefes döngüsüyle değişiyor; altında yalnızca iki dokunulabilir şey var
/// (duraklat, burada duralım) ve ikisi de soluk. Kalan süre **sayıyla
/// gösterilmiyor** — geri sayan bir sayı, oturumu bitmesi beklenen bir şeye
/// çevirir. Yerinde ince bir iz var; onboarding'in geri kalanıyla aynı dil.
///
/// ## Nefes genliği tam
///
/// Bu ekranda kullanıcı gerçekten nefesini arka plana uyduruyor
/// (`BreathAmplitude.session`), ölçüm ekranlarının kısılmış genliği burada geçerli
/// değil. Kabuk `OnboardingStep.breathAmplitude`den okuyor.
struct FirstSessionView: View {
    let flow: OnboardingFlowViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: FirstSessionViewModel

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
        self._viewModel = State(initialValue: FirstSessionViewModel(flow: flow))
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .preparing:
                preparing
            case .running:
                running
            case .completed:
                // Bitiş ekranı artık burada değil, G2'de. Oturum biter bitmez
                // akış ilerliyor; arada bir kare boş kalmasın diye son sahne
                // yerinde duruyor.
                running
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .task { viewModel.start() }
        .onDisappear { viewModel.teardown() }
        .onChange(of: viewModel.audio.audioEnergy) { _, energy in
            flow.updateSessionVoiceEnergy(energy)
        }
        // Oturum bitince (ya da "Burada duralım" denince) akış G2'ye geçer.
        // Kararı ViewModel veriyor, görünüm yalnızca haberi taşıyor.
        .onChange(of: viewModel.phase) { _, phase in
            guard phase == .completed else { return }
            flow.finishFirstSession(completed: viewModel.didReachEnd)
        }
    }

    // MARK: - Hazırlık

    private var preparing: some View {
        VStack {
            Spacer()
            Text(Copy.Session.preparing)
                .font(.title3.weight(Theme.Weight.title))
                .foregroundStyle(Theme.textPrimary.color.opacity(0.75))
            Spacer()
        }
    }

    // MARK: - Oturum

    /// Sahne paylaşılıyor: aynı görünüm onboarding sonrası günlük adımda da
    /// çalışıyor (`PathSessionView`).
    private var running: some View {
        SessionStageView(runner: viewModel.runner)
    }
}

#Preview {
    OnboardingPreviewHost(
        step: .g1FirstSession,
        draft: {
            var draft = OnboardingDraft()
            draft.name = "Taner"
            draft.categories = [.sleep]
            draft.problemText = "Geceleri yatağa girince kafam durmuyor."
            draft.currentMood = .heavy
            return draft
        }()
    ) { flow in
        FirstSessionView(flow: flow)
    }
}
