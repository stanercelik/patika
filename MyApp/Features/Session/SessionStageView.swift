import SwiftUI

/// Oturumun sahnesi: üstte adımın adı, ortada nefes alan guaj görsel ve tek
/// cümle, altta iz ve oynatma kontrolleri.
///
/// Meditasyon ekranı bir arayüz değil, bir alan. Kalan süre **sayıyla
/// gösterilmiyor** — geri sayan bir sayı, oturumu bitmesi beklenen bir şeye
/// çevirir. Aynı sahne hem onboarding'in ilk oturumunda hem onboarding sonrası
/// günlük adımda kullanılıyor; iki ekranın aynı şeyi iki farklı biçimde
/// göstermesi ürünü iki ayrı ürün gibi okutuyordu.
///
/// ## Kontroller (ürün sahibi talebi, 2026-09-19)
///
/// 15 sn geri · oynat/duraklat · 15 sn ileri. Ortadaki düğme "Yolum"daki
/// tabelayla aynı krem kâğıttan; iki yanındaki sarma düğmeleri cam — kâğıt
/// eylem, cam gezinme (`PatikaSurface` katmanları). Sarma düğmelerinde görünür
/// metin yok, simgenin içindeki "15" yeterli; VoiceOver tam cümleyi okur.
/// İleri sarma kapanışın içine atlamaz (`SessionRunner.canSkipForward`).
struct SessionStageView: View {
    let runner: SessionRunner
    /// "12. adım · Nefesi fark etmek". G1'de yok: onboarding kabuğu zaten
    /// yerini söylüyor.
    var eyebrow: String?
    var artwork: SessionArtwork?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            if let eyebrow {
                Text(verbatim: eyebrow)
                    .font(Theme.TypeFace.cardMeta)
                    .foregroundStyle(Theme.textSecondary.color)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .accessibilityAddTraits(.isHeader)
            }

            ScrollView {
                sceneContent
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .defaultScrollAnchor(.center, for: .alignment)

            SessionProgressTrail(progress: runner.progress)
                .padding(.bottom, 28)

            SessionTransportControls(runner: runner)
                .padding(.bottom, 10)

            Button {
                runner.leave()
            } label: {
                Text(Copy.Session.leave)
                    .font(Theme.TypeFace.rowAction)
                    .foregroundStyle(Theme.textSecondary.color)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.calm)
            .padding(.bottom, 8)
        }
        // Sahne değişimi 600 ms: 800 ms bütçesinin içinde ama ekran
        // geçişlerinden belirgin şekilde yavaş — burada acele edilecek bir şey
        // yok.
        .animation(.easeInOut(duration: 0.6), value: runner.currentSegment?.id)
        .animation(Theme.Motion.glide, value: runner.isPaused)
    }

    private var sceneContent: some View {
        VStack(spacing: 0) {
            // AX boyutlarında metin ekranın asıl içeriği: görsel yer kaplamaz.
            if let artwork, !dynamicTypeSize.isAccessibilitySize {
                SessionArtworkView(artwork: artwork, isPaused: runner.isPaused)
                    .frame(maxWidth: 280, maxHeight: 220)
                    .padding(.bottom, 28)
                    .opacity(runner.isPaused ? 0.6 : 1)
            }

            if runner.currentSegment?.kind == .ownWords {
                Text(Copy.Session.ownWordsFraming)
                    .font(.subheadline.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textSecondary.color)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 14)
                    .transition(.opacity)
            }

            // Sahne metni. `id` ile kimliklendirildi: SwiftUI aksi hâlde aynı
            // `Text`in içeriğini yerinde değiştirip geçişi hiç oynatmıyordu.
            Text(verbatim: runner.currentSegment?.text ?? "")
                .font(sceneFont)
                .fontDesign(runner.currentSegment?.kind == .ownWords ? .serif : .rounded)
                .foregroundStyle(Theme.textPrimary.color.opacity(runner.isPaused ? 0.6 : 0.94))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .id(runner.currentSegment?.id ?? "")
                .transition(sceneTransition)
                .accessibilityAddTraits(.updatesFrequently)

            Group {
                if runner.isPaused {
                    Text(Copy.Session.pausedNote)
                } else if let note = runner.audioNote {
                    Text(note)
                }
            }
            .font(.footnote.weight(Theme.Weight.body))
            .foregroundStyle(Theme.textSecondary.color)
            .padding(.top, 18)
            .transition(.opacity)
        }
    }

    /// Kullanıcının kendi cümlesi diğer sahnelerden ayrılıyor: aynı puntoyla
    /// yazılınca yönerge gibi okunuyordu, oysa bu onun cümlesi.
    private var sceneFont: Font {
        switch runner.currentSegment?.kind {
        case .ownWords: Theme.Voice.user(.title2)
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

/// 15 sn geri · oynat/duraklat · 15 sn ileri.
///
/// Simgeler Dynamic Type ile büyür ama `xxxLarge`da durur: sabit çaplı dairenin
/// içinde AX boyutundaki simge kenara taşıyordu. Dokunma alanları her boyutta
/// 44 pt'nin üstünde.
private struct SessionTransportControls: View {
    let runner: SessionRunner

    var body: some View {
        HStack(spacing: 32) {
            skipButton(
                symbol: "gobackward.15",
                label: Copy.Session.skipBackward,
                isEnabled: runner.canSkipBackward
            ) { runner.skip(by: -SessionAudioPlayer.skipInterval) }

            Button {
                Theme.softHaptic(intensity: 0.5)
                runner.togglePause()
            } label: {
                Image(systemName: runner.isPaused ? "play.fill" : "pause.fill")
                    .font(.title.weight(Theme.Weight.action))
                    .foregroundStyle(WoodlandStyle.ink)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 76, height: 76)
                    .background(WoodlandStyle.paper, in: Circle())
                    .shadow(color: .black.opacity(0.22), radius: 12, y: 5)
                    .contentShape(Circle())
            }
            .buttonStyle(.calm)
            .accessibilityLabel(Text(runner.isPaused ? Copy.Session.resume : Copy.Session.pause))

            skipButton(
                symbol: "goforward.15",
                label: Copy.Session.skipForward,
                isEnabled: runner.canSkipForward
            ) { runner.skip(by: SessionAudioPlayer.skipInterval) }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func skipButton(
        symbol: String,
        label: LocalizedStringResource,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(Theme.Weight.title))
                .foregroundStyle(Theme.textPrimary.color)
                .frame(width: 54, height: 54)
                .modifier(WoodlandGlassSurface(cornerRadius: 27))
                .contentShape(Circle())
        }
        .buttonStyle(.calm)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(Text(label))
    }
}

/// Oturum izi — `PathProgressBar` ile aynı fikir, sayısız ve daha soluk.
struct SessionProgressTrail: View {
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
