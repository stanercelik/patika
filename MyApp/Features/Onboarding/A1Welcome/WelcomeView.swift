import SwiftUI

struct WelcomeView: View {
    @Environment(AppServices.self) private var services
    @State private var viewModel: WelcomeViewModel
    private let flow: OnboardingFlowViewModel

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
        self._viewModel = State(initialValue: WelcomeViewModel(flow: flow))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Üstte kelime markası yok: marka kimliği yol animasyonunun kendisi.
            // Logo hazır olduğunda animasyonun kapanış karesine yerleşecek.
            Spacer(minLength: 24)

            PathDrawAnimation()
                .frame(maxWidth: .infinity)
                .frame(height: 300)

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: Theme.Spacing.stack) {
                DisplayText(viewModel.headline)
                BodyText(viewModel.body)
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)

            PrimaryButton(title: viewModel.ctaTitle) {
                Task { await viewModel.startTapped() }
            }
            .disabled(viewModel.isWorking)
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.top, 32)

            if let message = services.auth.errorMessage {
                Text(message)
                    .font(.footnote.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                    .padding(.top, 12)
            }

            SecondaryTextButton(title: Copy.Auth.returningLink) {
                viewModel.returningTapped()
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 18)
            .padding(.bottom, 12)
        }
        .sheet(isPresented: $viewModel.showsReturningAuth) {
            ReturningUserAuthView(services: services) {
                Task { await flow.completeOnboarding() }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    OnboardingPreviewHost(step: .a1Welcome) { flow in
        WelcomeView(flow: flow)
    }
}
