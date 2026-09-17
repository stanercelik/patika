import SwiftUI

/// Oturumun sahnesi: ortada tek bir cümle, altında iz ve iki soluk düğme.
///
/// Meditasyon ekranı bir arayüz değil, bir alan. Kalan süre **sayıyla
/// gösterilmiyor** — geri sayan bir sayı, oturumu bitmesi beklenen bir şeye
/// çevirir. Aynı sahne hem onboarding'in ilk oturumunda hem onboarding sonrası
/// günlük adımda kullanılıyor; iki ekranın aynı şeyi iki farklı biçimde
/// göstermesi ürünü iki ayrı ürün gibi okutuyordu.
struct SessionStageView: View {
    let runner: SessionRunner

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                sceneContent
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .defaultScrollAnchor(.center, for: .alignment)

            SessionProgressTrail(progress: runner.progress)
                .padding(.bottom, 24)

            controls
                .padding(.bottom, 16)
        }
        // Sahne değişimi 600 ms: 800 ms bütçesinin içinde ama ekran
        // geçişlerinden belirgin şekilde yavaş — burada acele edilecek bir şey
        // yok.
        .animation(.easeInOut(duration: 0.6), value: runner.currentSegment?.id)
    }

    private var sceneContent: some View {
        VStack(spacing: 0) {

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
                .foregroundStyle(Theme.textPrimary.color.opacity(0.94))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .id(runner.currentSegment?.id ?? "")
                .transition(sceneTransition)
                .accessibilityAddTraits(.updatesFrequently)

            if let note = runner.audioNote {
                Text(note)
                    .font(.footnote.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                    .padding(.top, 18)
            }


        }
    }

    private var controlsLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 28))
    }

    private var controls: some View {
        controlsLayout {
            Button {
                runner.togglePause()
            } label: {
                Label {
                    Text(runner.isPaused ? Copy.Session.resume : Copy.Session.pause)
                } icon: {
                    Image(systemName: runner.isPaused ? "play.fill" : "pause.fill")
                }
                .font(.subheadline.weight(Theme.Weight.action))
                .foregroundStyle(Theme.textPrimary.color.opacity(0.72))
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .frame(minWidth: 44, minHeight: 44)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.calm)

            Button {
                runner.leave()
            } label: {
                Text(Copy.Session.leave)
                    .font(.subheadline.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textSecondary.color)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.calm)
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
