import SwiftUI

/// Rozet kazanıldığında açılan **sade** yaprak (`docs/profile-v2-plan.md`
/// Aşama 5). Sıcak kademe: rozet görseli 0.85 → 1 ölçeğinde belirir, tek yumuşak
/// haptik, rozet adı ve tek cümle, "Bende kalsın".
///
/// Konfeti, ses, Lottie ve özel damga animasyonu yok. Birden fazla rozet aynı
/// anda kazanıldıysa tek yaprakta yan yana.
///
/// **Kriz modunda ve Kova C'deki yol sonunda açılmaz** — çağıran bunu denetler
/// (`BadgeCelebration.shouldPresent`); rozet o durumlarda rafta sessizce belirir.
/// Reduce Motion'da ölçek animasyonu yok, yalnızca belirme.
struct BadgeEarnedSheet: View {
    let badges: [BadgeID]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            WoodlandStyle.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 8)

                HStack(spacing: 16) {
                    ForEach(badges) { badge in
                        BadgeMedallion(id: badge, isEarned: true, size: badges.count > 1 ? 88 : 128)
                    }
                }
                .scaleEffect(appeared || reduceMotion ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: 12) {
                    ForEach(badges) { badge in
                        VStack(spacing: 4) {
                            Text(Copy.Me.Badge.title(badge))
                                .font(Theme.TypeFace.sectionTitle)
                                .foregroundStyle(Theme.textPrimary.color)
                            Text(Copy.Me.Badge.earned(badge))
                                .font(Theme.TypeFace.rowValue)
                                .foregroundStyle(Theme.textSecondary.color)
                        }
                    }
                }
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .accessibilityElement(children: .combine)

                Spacer(minLength: 8)

                PrimaryButton(title: Copy.Button.save, isEnabled: true) { dismiss() }
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
        }
        .presentationDetents([.medium])
        .task {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: Theme.Motion.badgeReveal)) { appeared = true }
            }
            Theme.softHaptic(intensity: 0.55)
        }
    }
}

/// Kutlama yaprağının açılıp açılmayacağı: **kural, ekranın `if`'i değil**.
///
/// Kriz modunda hiçbir şey açılmaz (kayıt akışı durmuş olur, rozet o anda yanlış
/// bir dil). Kova C'de rozet verilir ama kutlama yapılmaz — rozet rafta
/// sessizce belirir (`OutcomeBucket` Nötr kademe).
enum BadgeCelebration {
    static func shouldPresent(
        badges: [BadgeID],
        isInCrisisMode: Bool,
        bucket: OutcomeBucket?
    ) -> Bool {
        guard !badges.isEmpty, !isInCrisisMode else { return false }
        return bucket != .noProgress
    }
}

/// `sheet(item:)` için sarmalayıcı.
struct BadgeCelebrationItem: Identifiable {
    let id = UUID()
    let badges: [BadgeID]
}
