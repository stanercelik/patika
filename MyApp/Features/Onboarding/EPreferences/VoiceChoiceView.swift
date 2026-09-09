import AVFoundation
import Observation
import SwiftUI

/// E4 — "Hangi ses sana daha iyi geliyor?" (ürün sahibi kararı, 2026-09-09).
///
/// ## Sıfat sorulmaz, ses dinletilir
///
/// Bu ekran "nasıl bir ses istersin" diye sormuyor. Sıfat saydırmak — sıcak mı,
/// nötr mü — kullanıcıya cevaplayamayacağı bir soru sormak: sıfatın karşılığının
/// nasıl duyulduğunu bilmiyor. İki örnek dinletmek aynı kararı bir saniyede ve
/// doğru bilgiyle aldırıyor.
///
/// ## Önceden seçim yok
///
/// E2'de öneri var (10 dakika) çünkü PRD bir öneri veriyor. Burada yok: iki ses
/// arasında ürünün bir tercihi yok ve varsayılan koymak, dinlemeden geçen
/// kullanıcıyı seçmediği bir sesle on dakika baş başa bırakırdı. Devam butonu
/// ancak bir seçim yapılınca açılıyor.
///
/// ## Önizleme çalarken kaydırma durur
///
/// İki örnek aynı anda çalmaz; ikinciye basmak birinciyi keser. Üst üste binen
/// iki ses karşılaştırmayı imkânsız kılıyordu.
struct VoiceChoiceView: View {
    @State private var viewModel: VoiceChoiceViewModel

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(initialValue: VoiceChoiceViewModel(flow: flow))
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.voiceHeadline,
            hint: Copy.Onboarding.voiceHint
        ) {
            VStack(spacing: 12) {
                ForEach(VoicePreference.allCases) { voice in
                    VoicePreviewRow(
                        voice: voice,
                        isSelected: viewModel.selection == voice,
                        isPlaying: viewModel.playing == voice,
                        isAvailable: viewModel.isPreviewAvailable(voice),
                        onTap: { viewModel.select(voice) }
                    )
                }

                if !viewModel.hasAnyPreview {
                    // Önizleme yoksa gizlenmiyor. Kullanıcı dinleyemediğini
                    // bilmeli — sessiz kalan bir düğme arızalı görünüyor.
                    Text(Copy.Onboarding.voicePreviewUnavailable)
                        .font(.footnote.weight(Theme.Weight.body))
                        .foregroundStyle(Theme.textPrimary.color.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
            }
        } footer: {
            OnboardingQuestionFooter(
                primaryTitle: Copy.Button.next,
                primaryDisabledTitle: Copy.Onboarding.voiceChooseCTA,
                isPrimaryEnabled: viewModel.canContinue,
                primaryAction: { viewModel.submit() }
            )
        }
        .onDisappear { viewModel.stop() }
    }
}

/// Tek bir ses satırı: dokunmak hem seçer hem çalar.
///
/// İki ayrı hedef (bir "dinle" düğmesi + bir "seç" kutusu) denendiğinde
/// kullanıcıların çoğu yalnızca dinliyor ve seçmeden devam etmeye çalışıyordu.
/// Dokunuşun ikisini birden yapması doğru davranışı tek harekete indiriyor.
private struct VoicePreviewRow: View {
    let voice: VoicePreference
    let isSelected: Bool
    let isPlaying: Bool
    let isAvailable: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: isPlaying ? "speaker.wave.2.fill" : "play.circle")
                    .font(.title3)
                    .foregroundStyle(Theme.textPrimary.color.opacity(isAvailable ? 0.85 : 0.35))
                    .frame(width: 28)
                    .contentTransition(.symbolEffect(.replace))

                Text(voice.label)
                    .font(.body.weight(Theme.Weight.action))
                    .foregroundStyle(Theme.textPrimary.color)

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(Theme.Weight.action))
                        .foregroundStyle(Theme.textPrimary.color)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.12 : 0.06))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        Theme.textPrimary.color.opacity(isSelected ? 0.55 : 0.14),
                        lineWidth: Theme.Line.border
                    )
            }
        }
        .buttonStyle(.calm)
        .accessibilityLabel(Text(voice.label))
        .accessibilityHint(Text(Copy.Onboarding.voicePreviewHint))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

@Observable
@MainActor
final class VoiceChoiceViewModel {
    private(set) var selection: VoicePreference?
    private(set) var playing: VoicePreference?

    private let flow: OnboardingFlowViewModel
    private let locale: AppLocale
    private var player: AVAudioPlayer?
    private var stopObserver: NSObjectProtocol?

    init(flow: OnboardingFlowViewModel, locale: AppLocale? = nil) {
        self.flow = flow
        self.locale = locale ?? .current
        self.selection = flow.draft.voicePreference
    }

    var canContinue: Bool { selection != nil }

    var hasAnyPreview: Bool {
        VoicePreference.allCases.contains(where: isPreviewAvailable)
    }

    func isPreviewAvailable(_ voice: VoicePreference) -> Bool {
        previewURL(for: voice) != nil
    }

    /// Dokunmak hem seçer hem çalar. Önizleme yoksa yalnızca seçer — ses
    /// dosyasının eksikliği kullanıcının seçim yapmasını engellememeli.
    func select(_ voice: VoicePreference) {
        selection = voice
        play(voice)
    }

    func submit() {
        guard let selection else { return }
        stop()
        flow.commitVoicePreference(selection)
    }

    func stop() {
        player?.stop()
        player = nil
        playing = nil
        // Ses oturumu bırakılıyor: onboarding'in ortasında uygulamanın sesi
        // elinde tutması, kullanıcının müziğini susturulmuş bırakıyordu.
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func play(_ voice: VoicePreference) {
        // İkinci örneğe basmak birincisini keser: üst üste binen iki ses
        // karşılaştırmayı imkânsız kılıyor.
        player?.stop()
        player = nil
        playing = nil

        guard let url = previewURL(for: voice) else { return }
        do {
            // `.playback`: sessize alma anahtarı örneği susturmamalı —
            // kullanıcı sesi duyamayınca seçimi rastgele yapıyor.
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            self.player = player
            self.playing = voice
            scheduleStop(after: player.duration)
        } catch {
            playing = nil
        }
    }

    /// `AVAudioPlayerDelegate` yerine süreyle zamanlayıcı: delege için bir
    /// `NSObject` alt sınıfı gerekiyor ve bu ViewModel'in `@Observable` olması
    /// onu gereksiz yere karmaşıklaştırıyordu.
    private func scheduleStop(after duration: TimeInterval) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard let self, self.player?.isPlaying != true else { return }
            self.playing = nil
        }
    }

    private func previewURL(for voice: VoicePreference) -> URL? {
        Bundle.main.url(
            forResource: voice.previewAssetName(locale: locale),
            withExtension: "mp3"
        )
    }
}
