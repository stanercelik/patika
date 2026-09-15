import SwiftUI

/// Değişimin kullanıcının **kendi başlangıcına** göre yeri — sayı değil, konum
/// (profile-design §6.2).
///
/// İzin tam ortasında kesik bir başlangıç işareti durur; nokta iyi yönde sağa,
/// öbür yönde sola kayar. Sağ = iyi yön, çünkü Patika'daki bütün ilerleme dilleri
/// (onboarding izi, rota) "ileri"yi o yöne okuyor.
///
/// Konumun anlamı yalnızca bu kişinin başlangıcına göre var: başka biriyle
/// karşılaştırılamaz, mutlak bir skor iddia etmez (PRD §8.1).
struct BaselineTrack: View {
    /// −1…1. nil ise karşılaştırma yok ve nokta çizilmez — yapı görünür, sonuç
    /// görünmez (7. adımdan önceki beklenti durumu).
    let offset: Double?
    /// false iken nokta başlangıç işaretinde bekler; ilk gösterimde oradan kayar.
    var isRevealed = true

    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 22
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let midX = width / 2
            let midY = geometry.size.height / 2
            let travel = max(width / 2 - 6, 0)

            ZStack {
                Capsule()
                    .fill(Theme.textPrimary.color.opacity(contrast == .increased ? 0.36 : 0.18))
                    .frame(width: width, height: Theme.Line.trail)
                    .position(x: midX, y: midY)

                Path { path in
                    path.move(to: CGPoint(x: midX, y: midY - 8))
                    path.addLine(to: CGPoint(x: midX, y: midY + 8))
                }
                .stroke(
                    Theme.textPrimary.color.opacity(0.62),
                    style: StrokeStyle(
                        lineWidth: 1,
                        lineCap: .round,
                        dash: contrast == .increased ? [] : [2, 2]
                    )
                )

                if let offset {
                    Circle()
                        .fill(Theme.textPrimary.color)
                        .frame(width: 9, height: 9)
                        .position(
                            x: midX + CGFloat(isRevealed ? min(max(offset, -1), 1) : 0) * travel,
                            y: midY
                        )
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// Göstergedeki küçük başlangıç işareti örneği: "┆ Başlangıcın".
struct BaselineLegendMark: View {
    @ScaledMetric(relativeTo: .footnote) private var height: CGFloat = 13

    var body: some View {
        Path { path in
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: 0, y: height))
        }
        .stroke(
            Theme.textPrimary.color.opacity(0.62),
            style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [2, 2])
        )
        .frame(width: 1, height: height)
        .accessibilityHidden(true)
    }
}
