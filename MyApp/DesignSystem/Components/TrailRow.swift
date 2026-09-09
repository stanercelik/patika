import SwiftUI

/// Dikey iz üzerinde bir düğüm ve yanındaki içerik.
///
/// F1'in üretim adımları ve F2'nin yol haritası aynı görsel dili konuşur:
/// yukarıdan aşağı inen tek bir iz, üzerinde noktalar. Bu, A1'deki yol
/// animasyonunun ve `PathProgressBar`ın devamı — ürünün tek metaforu "sonu olan
/// bir yol" ve her ekranda aynı çizgiyle anlatılıyor.
///
/// İz satırın **tüm yüksekliği** boyunca çizilir; komşu satırlar birleşince tek
/// bir kesintisiz çizgi olur. İlk satırın üstü ve son satırın altı kapalıdır,
/// yoksa çizgi boşluğa doğru devam ediyormuş gibi görünür.

/// İz üzerindeki bir düğümün hâli.
///
/// `TrailRow`un içinde iç içe tanımlı **değil**: durumu üreten yer ViewModel ve
/// ViewModel `SwiftUI` import etmiyor (`TrailRow<Content>` jenerik olduğu için
/// oradan `TrailRow<EmptyView>.Node` yazmak gerekirdi).
enum TrailNode: Equatable {
    /// Henüz gelinmedi.
    case pending
    /// Şu an olan şey. Nefes döngüsüyle birlikte soluk alıp verir.
    case active
    /// Tamamlandı.
    case done
    /// Yolun üstündeki işaretli nokta (ölçüm günü). Halkalı ve dolu —
    /// **yıldız/emoji değil**: aynı mürekkep, farklı biçim.
    case milestone
}

struct TrailRow<Content: View>: View {
    let node: TrailNode
    var showsLineAbove: Bool = true
    var showsLineBelow: Bool = true
    @ViewBuilder var content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Düğüm, yanındaki ilk metin satırının optik ortasına hizalanır. Dynamic
    /// Type büyüdükçe metin satırı da büyüdüğü için bu ölçü ölçeklenir.
    @ScaledMetric(relativeTo: .body) private var nodeCenterOffset: CGFloat = 11

    private let railWidth: CGFloat = 22
    private let contentSpacing: CGFloat = 14
    private let lineWidth: CGFloat = 2

    var body: some View {
        // İz **arka planda** çizilir, satırın yanında bir sütun olarak değil.
        // Sütun olarak konduğunda `maxHeight: .infinity` satırın kendisini
        // esnek yapıyordu: `Spacer` içeren bir `VStack`ta dört satır ekranın
        // tamamına yayılıyordu. Arka plan katmanı boyutu hiç etkilemez, ama
        // içeriğin yüksekliğini olduğu gibi alır — istediğimiz tam olarak bu.
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, railWidth + contentSpacing)
            .background(alignment: .topLeading) { rail }
    }

    private var rail: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                segment(isVisible: showsLineAbove)
                    .frame(height: nodeCenterOffset)
                segment(isVisible: showsLineBelow)
            }

            TrailNodeDot(node: node)
                .offset(y: nodeCenterOffset - TrailNodeDot.size(for: node) / 2)
        }
        .frame(width: railWidth)
        .accessibilityHidden(true)
    }

    private func segment(isVisible: Bool) -> some View {
        Rectangle()
            .fill(Theme.textPrimary.color.opacity(isVisible ? 0.16 : 0))
            .frame(width: lineWidth)
            .frame(maxWidth: .infinity)
    }

}

/// İz üzerindeki düğümün kendisi.
///
/// `TrailRow`dan ayrı bir tip: "Yolum" sekmesi izi satır satır değil **tek
/// parça** çiziyor (uçları solarak kesilsin diye) ama düğümler aynı olmak
/// zorunda — iki ekranın aynı yolu iki farklı noktayla anlatması, metaforu
/// ikiye bölerdi.
struct TrailNodeDot: View {
    let node: TrailNode

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static func size(for node: TrailNode) -> CGFloat {
        switch node {
        case .milestone: 16
        case .active, .done: 13
        case .pending: 10
        }
    }

    var body: some View {
        shape
            .frame(width: Self.size(for: node), height: Self.size(for: node))
    }

    @ViewBuilder
    private var shape: some View {
        switch node {
        case .pending:
            Circle()
                .strokeBorder(Theme.textPrimary.color.opacity(0.30), lineWidth: Theme.Line.border)

        case .active:
            // Nefes döngüsüyle aynı ritimde soluk alır: bekleyiş boyunca ekranda
            // hareket eden tek şey bu ve kullanıcının nefesiyle aynı hızda.
            BreathingDot(isAnimated: !reduceMotion)

        case .done:
            Circle().fill(Theme.textPrimary.color.opacity(0.92))

        case .milestone:
            ZStack {
                Circle()
                    .strokeBorder(Theme.textPrimary.color.opacity(0.45), lineWidth: Theme.Line.border)
                Circle()
                    .fill(Theme.textPrimary.color.opacity(0.95))
                    .padding(5)
            }
        }
    }
}

/// Nefes döngüsünün 10 saniyelik ritmini taşıyan tek nokta.
private struct BreathingDot: View {
    let isAnimated: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isAnimated)) { timeline in
            let breath = isAnimated
                ? BreathCycle.value(
                    at: timeline.date.timeIntervalSinceReferenceDate,
                    amplitude: BreathAmplitude.ambient
                )
                : 0.5

            Circle()
                .fill(Theme.textPrimary.color.opacity(0.55 + breath * 0.45))
                .scaleEffect(0.82 + breath * 0.18)
        }
    }
}

#Preview {
    ZStack {
        BreathingMeshBackground(palette: Palette.all["sleep"]!, safeY: 0.30)
        VStack(alignment: .leading, spacing: 0) {
            TrailRow(node: .done, showsLineAbove: false) {
                Text(verbatim: "Yazdıklarını okudum").padding(.bottom, 18)
            }
            TrailRow(node: .active) {
                Text(verbatim: "Yolu sıraya diziyorum...").padding(.bottom, 18)
            }
            TrailRow(node: .milestone) {
                Text(verbatim: "Gün 7 — İlk ölçüm").padding(.bottom, 18)
            }
            TrailRow(node: .pending, showsLineBelow: false) {
                Text(verbatim: "Sesini hazırlıyorum")
            }
        }
        .font(.body.weight(Theme.Weight.body))
        .foregroundStyle(Theme.textPrimary.color)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
    .preferredColorScheme(.dark)
}
