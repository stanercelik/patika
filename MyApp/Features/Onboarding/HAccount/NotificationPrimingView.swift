import SwiftUI

/// H2 — bildirim ön hazırlığı (PRD §9; docs/onboarding-redesign.md, Bölüm 1).
///
/// Sistem izin penceresi **tek atış**: reddedilirse ancak ayarlardan geri açılır. Bu
/// yüzden izin, kullanıcı ne alacağını gördükten sonra ve yalnızca "İzin ver" ile
/// istenir. Açılışta ya da bu ekrandan önce sistem penceresi hiç gösterilmez.
///
/// Ekran üç şeyi söyler ve üçü de kodda doğru:
/// - **Gerçek bir bildirim önizlemesi**: metin `Copy.Notification.dailyStep`, yani
///   gerçekten planlanacak cümle.
/// - **Gizlilik**: bildirim asla path adını ya da dertini yazmaz (`ReminderScheduler`).
/// - **Suçlamama**: kaçırılan gün hiçbir şeyi geri almaz ve kaçırdıkların için mesaj
///   gitmez; bildirimde seri anılmaz.
///
/// Reddetmek suçsuz: "Şimdilik değil" akışı aynı yere götürür, hatırlatma kapalı kalır
/// ve Ben sekmesi ayarlardan açmayı gösterir. `.active` seviyesi, `.provisional` yok.
struct NotificationPrimingView: View {
    let flow: OnboardingFlowViewModel
    @State private var isWorking = false

    var body: some View {
        OnboardingQuestionLayout(headline: Copy.Onboarding.notificationPrimingHeadline(flow.reminderTimeText)) {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingArtworkView(artwork: .lantern, height: 150)
                    .statementReveal(1)

                preview.statementReveal(2)

                BodyText(.meSettingsNotificationPrivacy).statementReveal(3)
                BodyText(.notificationPrimingNoGuilt).statementReveal(4)
            }
        } footer: {
            OnboardingQuestionFooter(
                primaryTitle: .notificationPrimingAllow,
                isPrimaryEnabled: !isWorking,
                primaryAction: {
                    isWorking = true
                    Task {
                        await flow.finishReminderPriming(enable: true)
                        isWorking = false
                    }
                },
                skipTitle: Copy.Button.cancel,
                skipAction: { Task { await flow.finishReminderPriming(enable: false) } }
            )
        }
    }

    /// Sistem bildiriminin sade bir taklidi; **yalnızca gösterim**, dokunulmaz.
    private var preview: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.body.weight(Theme.Weight.action))
                .foregroundStyle(WoodlandStyle.paper)
                .frame(width: 36, height: 36)
                .background(WoodlandStyle.ink, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(.notificationPrimingPreviewApp)
                        .font(.subheadline.weight(Theme.Weight.action))
                    Spacer(minLength: 8)
                    Text(.notificationPrimingPreviewTime)
                        .font(.caption.weight(Theme.Weight.body))
                        .inkStyle(.secondary)
                }
                Text(Copy.Notification.dailyStep)
                    .font(.subheadline.weight(Theme.Weight.body))
            }
            .inkStyle(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { PaperInsetSurface() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(.notificationPrimingPreviewAccessibility))
    }
}

#Preview {
    OnboardingPreviewHost(step: .h2Priming) { flow in
        NotificationPrimingView(flow: flow)
    }
}
