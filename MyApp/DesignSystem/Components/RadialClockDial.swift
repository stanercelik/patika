import SwiftUI

/// 24 saatlik kadran: hatırlatma saatini bir halka üstünde gösterir ve sürüklenirse
/// değiştirir. Öğle tepede, gece altta: gün boyunca güneşin gidişi.
///
/// **Onaylama bir dokunuştur, sürükleme isteğe bağlıdır.** E1'in işi B3'ten türeyen
/// bir öneriyi onaylatmak; kadran bunu bir el becerisi görevine çevirmemeli, yalnızca
/// önerinin günün neresine düştüğünü göstermeli. Bu yüzden `suggestionHour` halkada
/// içi boş bir işaretle görünür ve kullanıcı sürükleyip başka yere gidebilir.
///
/// `hour` ve `minute` `Int`: `Date` bir kadranın içinde saat dilimi hatasına davetiye
/// (`commitReminder(hour:minute:)` sınırda çeviriyor). Dakika 5'e yuvarlanır.
///
/// Erişilebilirlik boyutlarında ve VoiceOver açıkken `ReminderTimeView` kadranı hiç
/// göstermez, tekerleğe düşer: sürükleme bir yardımcı teknoloji için bir cevap
/// yolu değil.
struct RadialClockDial: View {
    let hour: Int
    let minute: Int
    var suggestionHour: Int?
    var isCompact = false
    let onChange: (Int, Int) -> Void

    @Environment(\.patikaInk) private var ink
    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = 248
    @ScaledMetric(relativeTo: .body) private var compactDiameter: CGFloat = 208
    @ScaledMetric(relativeTo: .body) private var thumbDiameter: CGFloat = 30

    private var totalMinutes: Int { hour * 60 + minute }
    private var resolvedDiameter: CGFloat { isCompact ? compactDiameter : diameter }

    var body: some View {
        let ring = resolvedDiameter - thumbDiameter
        ZStack {
            Circle()
                .stroke(ink.primary.opacity(0.14), lineWidth: 10)
                .frame(width: ring, height: ring)

            ForEach(0..<24, id: \.self) { h in
                Capsule()
                    .fill(ink.primary.opacity(h % 6 == 0 ? 0.55 : 0.25))
                    .frame(width: 2, height: h % 6 == 0 ? 12 : 7)
                    .offset(y: -(ring / 2 - 20))
                    .rotationEffect(.degrees(Double(h) * 15 + 180))
            }

            // Gün yönü: öğle üstte, gece altta. Simge yalnızca yön, saat bilgisi başka yerde.
            Image(systemName: "sun.max")
                .font(.caption.weight(Theme.Weight.emphasis))
                .foregroundStyle(ink.secondary)
                .offset(y: -(ring / 2 - 42))
            Image(systemName: "moon")
                .font(.caption.weight(Theme.Weight.emphasis))
                .foregroundStyle(ink.secondary)
                .offset(y: ring / 2 - 42)

            if let suggestionHour, suggestionHour != hour {
                Circle()
                    .strokeBorder(ink.primary.opacity(0.7), lineWidth: 2)
                    .frame(width: thumbDiameter - 8, height: thumbDiameter - 8)
                    .offset(point(forMinutes: suggestionHour * 60, radius: ring / 2))
            }

            Circle()
                .fill(ink.primary)
                .overlay { Circle().strokeBorder(ink.secondary.opacity(0.35), lineWidth: Theme.Line.border) }
                .frame(width: thumbDiameter, height: thumbDiameter)
                .offset(point(forMinutes: totalMinutes, radius: ring / 2))

            Text(verbatim: String(format: "%02d:%02d", hour, minute))
                .font(.system(size: 40, weight: Theme.Weight.display, design: .rounded))
                .foregroundStyle(ink.primary)
                .monospacedDigit()
                .accessibilityHidden(true)
        }
        // Jest daire çerçevesine bağlı, genişleyen çerçeveye değil: yerel koordinatlar
        // dairenin köşesinden başlamalı, yoksa merkez kayar.
        .frame(width: resolvedDiameter, height: resolvedDiameter)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in update(from: value.location) }
        )
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel(.reminderDialAccessibility)
        .accessibilityValue(Text(verbatim: String(format: "%02d:%02d", hour, minute)))
        .accessibilityHint(.reminderDialAccessibilityHint)
        .accessibilityAdjustableAction { direction in
            let delta = direction == .increment ? 15 : -15
            apply(minutes: (totalMinutes + delta + 1440) % 1440)
        }
    }

    /// Öğle (720. dakika) tepede, saat yönünde ilerler.
    private func point(forMinutes minutes: Int, radius: CGFloat) -> CGSize {
        let angle = (Double((minutes + 720) % 1440) / 1440) * 2 * .pi
        return CGSize(width: sin(angle) * radius, height: -cos(angle) * radius)
    }

    private func update(from location: CGPoint) {
        let dx = location.x - (frameSize / 2)
        let dy = location.y - (frameSize / 2)
        guard dx != 0 || dy != 0 else { return }
        var angle = atan2(dx, -dy)
        if angle < 0 { angle += 2 * .pi }
        let raw = Int((angle / (2 * .pi)) * 1440)
        let minutes = ((raw + 720) % 1440) / 5 * 5
        apply(minutes: minutes)
    }

    /// Dokunma noktası çerçeve ortasına göre hesaplanır; çerçeve `diameter` kare.
    private var frameSize: CGFloat { resolvedDiameter }

    private func apply(minutes: Int) {
        guard minutes != totalMinutes else { return }
        // Haptik 15 dakikada bir: 5'lik her adımda vurmak sürüklemeyi titreşime çevirirdi.
        if minutes / 15 != totalMinutes / 15 { Theme.softHaptic(intensity: 0.5) }
        onChange(minutes / 60, minutes % 60)
    }
}

#Preview("Kadran") {
    ZStack {
        WoodlandStyle.background.ignoresSafeArea()
        RadialClockDial(hour: 22, minute: 30, suggestionHour: 21, onChange: { _, _ in })
            .padding(PatikaSurfaceMetrics.padding)
            .paperSurface()
            .environment(\.patikaInk, .ink)
            .padding(.horizontal, Theme.Spacing.screenMargin)
    }
    .preferredColorScheme(.dark)
}
