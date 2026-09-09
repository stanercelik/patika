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

    private var running: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            if viewModel.currentSegment?.kind == .ownWords {
                Text(Copy.Session.ownWordsFraming)
                    .font(.subheadline.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 14)
                    .transition(.opacity)
            }

            // Sahne metni. `id` ile kimliklendirildi: SwiftUI aksi hâlde aynı
            // `Text`in içeriğini yerinde değiştirip geçişi hiç oynatmıyordu.
            Text(verbatim: viewModel.currentSegment?.text ?? "")
                .font(sceneFont)
                .foregroundStyle(Theme.textPrimary.color.opacity(0.94))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .id(viewModel.currentSegment?.id ?? "")
                .transition(sceneTransition)
                .accessibilityAddTraits(.updatesFrequently)

            if let note = viewModel.audioNote {
                Text(note)
                    .font(.footnote.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textPrimary.color.opacity(0.40))
                    .padding(.top, 18)
            }

            Spacer(minLength: 0)

            SessionProgressTrail(progress: viewModel.progress)
                .padding(.bottom, 24)

            controls
                .padding(.bottom, 16)
        }
        // Sahne değişimi 600 ms: 800 ms bütçesinin içinde ama ekran geçişlerinden
        // belirgin şekilde yavaş — burada acele edilecek bir şey yok.
        .animation(.easeInOut(duration: 0.6), value: viewModel.currentSegment?.id)
    }

    private var controls: some View {
        HStack(spacing: 28) {
            Button {
                viewModel.togglePause()
            } label: {
                Label {
                    Text(viewModel.isPaused ? Copy.Session.resume : Copy.Session.pause)
                } icon: {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                }
                .font(.subheadline.weight(Theme.Weight.action))
                .foregroundStyle(Theme.textPrimary.color.opacity(0.72))
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.calm)

            Button {
                viewModel.leave()
            } label: {
                Text(Copy.Session.leave)
                    .font(.subheadline.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color.opacity(0.48))
            }
            .buttonStyle(.calm)
        }
    }

    /// Kullanıcının kendi cümlesi diğer sahnelerden ayrılıyor: aynı puntoyla
    /// yazılınca yönerge gibi okunuyordu, oysa bu onun cümlesi.
    private var sceneFont: Font {
        switch viewModel.currentSegment?.kind {
        case .ownWords: .title2.weight(Theme.Weight.title).italic()
        case .opening, .closing: .title3.weight(Theme.Weight.title)
        default: .title3.weight(Theme.Weight.body)
        }
    }

    private var sceneTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .opacity.combined(with: .offset(y: 10)),
                removal: .opacity
            )
    }

}

/// Oturum izi — `PathProgressBar` ile aynı fikir, sayısız ve daha soluk.
///
/// Ayrı bir bileşen çünkü onboarding izi kabuğun parçası ve bu ekranda kabuğun
/// izi yok (`OnboardingStep.progress` G1'de nil): oradaki iz "kaç soru kaldı"yı
/// anlatıyor, buradaki oturumun kendisini.
private struct SessionProgressTrail: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.textPrimary.color.opacity(0.14))
                Capsule()
                    .fill(Theme.textPrimary.color.opacity(0.42))
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 3)
        .animation(.linear(duration: 0.2), value: progress)
        .accessibilityHidden(true)
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
