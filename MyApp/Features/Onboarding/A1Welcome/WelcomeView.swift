import SwiftUI

struct WelcomeView: View {
    @State private var viewModel: WelcomeViewModel

    init(flow: OnboardingFlowViewModel) {
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
                viewModel.startTapped()
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.top, 32)
            .padding(.bottom, 12)
        }
    }
}

#Preview {
    OnboardingPreviewHost(step: .a1Welcome) { flow in
        WelcomeView(flow: flow)
    }
}
