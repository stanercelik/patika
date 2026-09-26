import SwiftUI

/// Covers the entire onboarding shell, including its persistent header.
struct DayOneTransitionView: View {
    var threshold: OnboardingThreshold = .dayOne

    var body: some View {
        ZStack {
            OnboardingSceneLayer(artwork: threshold == .dayOne ? .session : .prepare, dimming: 0.48)
            Text(threshold == .dayOne
                 ? Copy.Onboarding.commitmentDayOneTransition
                 : Copy.Onboarding.commitmentContinueTransition)
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
