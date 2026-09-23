import SwiftUI

struct ReturningUserAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var localMessage: LocalizedStringResource?

    let services: AppServices
    let onSignedIn: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.045, green: 0.055, blue: 0.075).ignoresSafeArea()
            VStack(alignment: .leading, spacing: Theme.Spacing.stack) {
                Text(Copy.Auth.returningTitle)
                    .font(.title2.weight(Theme.Weight.title))
                    .foregroundStyle(Theme.textPrimary.color)
                Text(Copy.Auth.returningBody)
                    .font(.body.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)

                AuthProviderButtons(isWorking: services.auth.isWorking) { provider in
                    Task { await signIn(provider) }
                }

                if let message = localMessage ?? services.auth.errorMessage {
                    Text(message)
                        .font(.footnote.weight(Theme.Weight.body))
                        .foregroundStyle(Theme.textSecondary.color)
                }

                SecondaryTextButton(title: Copy.Auth.notNow) { dismiss() }
                    .frame(maxWidth: .infinity)
            }
            .padding(Theme.Spacing.screenMargin)
        }
    }

    private func signIn(_ provider: AuthProvider) async {
        localMessage = nil
        guard await services.auth.signIn(provider: provider) else {
            services.observability.capture(.authenticationFinished(provider: provider, succeeded: false))
            services.observability.capture(.returningAuthentication)
            return
        }
        services.observability.capture(.authenticationFinished(provider: provider, succeeded: true))
        guard
              let token = try? await services.auth.validAccessToken()
        else { return }
        do {
            if try await services.backend.hasCompletedOnboarding(accessToken: token) {
                dismiss()
                onSignedIn()
            } else {
                localMessage = Copy.Auth.noSavedPath
            }
        } catch {
            #if DEBUG
            print("⚠️ ReturningUserAuthView.signIn — hasCompletedOnboarding threw: \(error)")
            #endif
            localMessage = Copy.Auth.failed
        }
    }
}
