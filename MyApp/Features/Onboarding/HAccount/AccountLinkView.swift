import SwiftUI

struct AccountLinkView: View {
    @Environment(AppServices.self) private var services
    let flow: OnboardingFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.stack) {
            Spacer()
            DisplayText(Copy.Auth.linkTitle, size: 30)
            BodyText(Copy.Auth.linkBody)

            AuthProviderButtons(isWorking: services.auth.isWorking) { provider in
                Task { _ = await flow.linkAccount(provider) }
            }

            if let message = services.auth.errorMessage {
                Text(message)
                    .font(.footnote.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
            }

            SecondaryTextButton(title: Copy.Auth.skipLink) {
                Task { await flow.completeOnboarding() }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }
}
