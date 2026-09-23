import SwiftUI

/// Covers the entire onboarding shell, including its persistent header.
struct DayOneTransitionView: View {
    var body: some View {
        ZStack {
            OnboardingSceneLayer(artwork: .session, dimming: 0.48)
            Text(Copy.Onboarding.commitmentDayOneTransition)
                .font(Theme.TypeFace.sectionTitle)
                .foregroundStyle(Theme.textPrimary.color)
                .multilineTextAlignment(.center)
                .padding(28)
                .background(WoodlandStyle.scenePlate.color, in: RoundedRectangle(cornerRadius: 24))
                .padding(Theme.Spacing.screenMargin)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
