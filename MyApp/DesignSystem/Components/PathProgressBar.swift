import SwiftUI

/// Onboarding ilerleme göstergesi.
///
/// Sayı ("Adım 1 / 7") yerine **çizilen bir iz**: ürünün tüm metaforu "sonu olan bir
/// yol" ve A1'deki yol animasyonuyla aynı dili konuşur.
///
/// Sayı göstermemek bilinçli: kalan adım sayısını saydırmak "daha ne kadar var"
/// hissini öne çıkarır; iz ise kat edilen yolu öne çıkarır.
///
/// Ucunda düğüm **yok** (ürün sahibi kararı, 2026-09-08). Düğüm her adımda gözün
/// takip ettiği bir nesne yaratıyordu; izin kendisi yerine noktanın konumu
/// okunuyordu. Düz ve bir kademe kalın bir çizgi hem daha sakin hem daha okunur.
struct PathProgressBar: View {
    /// 0…1.
    let progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.textPrimary.color.opacity(0.16))

                Capsule()
                    .fill(Theme.textPrimary.color.opacity(0.85))
                    // Sıfırda bile bir tutam iz görünür: yol baştan var, kullanıcı
                    // onu yürüyor — boş bir çubuk "hiçbir şey yapmadın" diyor.
                    .frame(width: max(Theme.Line.progressTrack, geo.size.width * clamped))
            }
        }
        .frame(height: Theme.Line.progressTrack)
        .animation(reduceMotion ? nil : Theme.Motion.progress, value: clamped)
        .accessibilityElement()
        .accessibilityLabel(.commonProgress)
        .accessibilityValue(Text(.commonPercent(Int(clamped * 100))))
    }
}

#Preview {
    ZStack {
        BreathingMeshBackground(palette: .neutral)
        VStack(spacing: 40) {
            PathProgressBar(progress: 0.0)
            PathProgressBar(progress: 1.0 / 7.0)
            PathProgressBar(progress: 0.6)
            PathProgressBar(progress: 1.0)
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
}
