import SwiftUI

struct AuthProviderButtons: View {
    let isWorking: Bool
    let action: (AuthProvider) -> Void

    var body: some View {
        VStack(spacing: 12) {
            providerButton(Copy.Auth.apple, symbol: "apple.logo", provider: .apple, filled: true)
            providerButton(Copy.Auth.google, symbol: "g.circle", provider: .google, filled: false)
        }
    }

    private func providerButton(
        _ title: LocalizedStringResource,
        symbol: String,
        provider: AuthProvider,
        filled: Bool
    ) -> some View {
        Button { action(provider) } label: {
            Label(title, systemImage: symbol)
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
