import SwiftUI

struct WelcomeView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var viewModel: WelcomeViewModel
    private let flow: OnboardingFlowViewModel

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
        self._viewModel = State(initialValue: WelcomeViewModel(flow: flow))
    }

    /// Karşılama sahnesi çizilecek mi? Kabuk aynı koşulu kullanır (`showsScene`).
    private var usesScene: Bool {
        OnboardingArtwork.threshold.isAvailable && !reduceTransparency && !dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Üstte kelime markası yok: marka kimliği açılış manzarasının kendisi.
                    // Sahne varsa üst yarı manzaraya bırakılır ve başlık ile düğme alt %40'a
                    // oturur. Sahne yoksa (Reduce Transparency, erişilebilirlik boyutu ya da
                    // görsel eksik) çıplak mesh üstünde başlık ve düğme kalır: yol animasyonu
                    // (`PathDrawAnimation`) silindi, `onboarding-threshold` onun yerini aldı.
                    Spacer(minLength: usesScene ? geometry.size.height * 0.56 : 24)

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
                .frame(minHeight: geometry.size.height)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
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
