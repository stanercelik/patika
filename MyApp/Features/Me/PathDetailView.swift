import SwiftUI

/// Yol ayrıntısı (profile-design §8.3) — path sonu raporunun kalıcı kopyası.
///
/// Kova A/B'nin sayısal başlığı yalnızca burada görünür; Kova C'de o alan zaten
/// yok (`badgeShowsNumbers`). Yarım kalan yolda yürünen adım yazılır, kalan adım
/// yazılmaz (İ2).
struct PathDetailView: View {
    let viewModel: MeViewModel
    let sealID: String

    @Environment(PaletteController.self) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            BreathingMeshBackground(
                palette: palette.current,
                safeY: 0.3,
                breathAmplitude: BreathAmplitude.measurement
            )
            .ignoresSafeArea()

            if let seal = viewModel.seal(id: sealID) {
                ScrollView {
                    content(seal)
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                        .padding(.top, 12)
                        .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ seal: MeViewModel.SealItem) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            RouteSeal(
                stepCount: seal.stepCount,
                walkedFraction: seal.walkedFraction,
                style: seal.style,
                size: dynamicTypeSize.isAccessibilitySize ? 88 : 120,
                animatesDrawing: true
            )
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: seal.title)
                    .font(.title.weight(Theme.Weight.display))
                    .foregroundStyle(Theme.textPrimary.color)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: seal.meta)
                    .font(.subheadline.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                Text(verbatim: seal.detail)
                    .font(.subheadline.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color.opacity(0.86))
            }
            .fixedSize(horizontal: false, vertical: true)

            if let headline = seal.headline {
                Text(verbatim: headline)
                    .font(.title3.weight(Theme.Weight.title))
                    .foregroundStyle(Theme.textPrimary.color)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if seal.style == .stopped {
                Text(Copy.Me.pathStoppedDetail)
                    .font(.body.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
            }

            let entries = viewModel.journalItems(forPath: seal.pathID)
            if !entries.isEmpty, !viewModel.isJournalObscured {
                VStack(alignment: .leading, spacing: 20) {
                    ProfileSectionHeader(title: Copy.Me.pathJournalTitle)
                    ForEach(entries) { item in
                        UserQuote(text: item.text, caption: item.caption, detail: item.detail)
                    }
                }
            }
        }
    }
}
