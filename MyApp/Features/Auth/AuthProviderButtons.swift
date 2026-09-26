import SwiftUI

struct AuthProviderButtons: View {
    let isWorking: Bool
    let action: (AuthProvider) -> Void

    var body: some View {
        VStack(spacing: 12) {
            providerButton(Copy.Auth.apple, provider: .apple, filled: true) {
                Image(systemName: "apple.logo")
            }
            // Google marka yönergesi: dört renkli resmî "G", değiştirilmeden, beyaz
            // bir zeminde. Koyu butonda logo kendi beyaz dairesinin içinde durur.
            providerButton(Copy.Auth.google, provider: .google, filled: false) {
                Image("google-g")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .padding(5)
                    .background(Color.white, in: Circle())
                    .accessibilityHidden(true)
            }
        }
    }

    private func providerButton<Icon: View>(
        _ title: LocalizedStringResource,
        provider: AuthProvider,
        filled: Bool,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        Button { action(provider) } label: {
            Label { Text(title) } icon: { icon() }
                .font(.body.weight(Theme.Weight.action))
                .foregroundStyle(filled ? Color.black : Theme.textPrimary.color)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 54)
                .background {
                    Capsule().fill(filled ? Theme.textPrimary.color : Color.white.opacity(0.08))
                }
                .overlay {
                    if !filled {
                        Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: Theme.Line.border)
                    }
                }
        }
        .buttonStyle(.calm)
        .disabled(isWorking)
    }
}
