import SwiftUI

/// H1 — hesap bağlama. Kâğıt katmanı: başlık, gövde ve sığınak görseli kartta; giriş
/// düğmeleri alt bölgede, mesh üzerinde (kimlik sağlayıcıların kendi düğme malzemesi var).
///
/// Bağlamak zorunlu değil: "Şimdilik geç" onboarding'i hesapsız bitirir, kayıt sonradan
/// Ben sekmesinden yapılır. Görsel yoksa yer kaplamaz.
struct AccountLinkView: View {
    @Environment(AppServices.self) private var services
    let flow: OnboardingFlowViewModel

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Auth.linkTitle,
            hint: Copy.Auth.linkBody
        ) {
            OnboardingArtworkView(artwork: .shelter, height: 150)
        } footer: {
            VStack(spacing: Theme.Spacing.stack) {
                AuthProviderButtons(isWorking: services.auth.isWorking) { provider in
                    Task { _ = await flow.linkAccount(provider) }
                }

                if let message = services.auth.errorMessage {
                    Text(message)
                        .font(.footnote.weight(Theme.Weight.body))
                        .foregroundStyle(Theme.textSecondary.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                SecondaryTextButton(title: Copy.Auth.skipLink) {
                    Task { await flow.skipAccountLink() }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    OnboardingPreviewHost(step: .h1Account) { flow in
        AccountLinkView(flow: flow)
    }
}
