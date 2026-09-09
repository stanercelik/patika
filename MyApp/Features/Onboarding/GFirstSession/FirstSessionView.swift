import SwiftUI

struct FirstSessionView: View {
    let flow: OnboardingFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.stack) {
            Spacer()
            DisplayText(Copy.Onboarding.firstSessionHeadline, size: 30)
            BodyText(Copy.Onboarding.firstSessionBody)
            if flow.draft.hasOwnWords {
                Text(verbatim: "“\(flow.draft.problemText)”")
                    .font(.body.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(flow.draft.problemText)
            }
            Spacer()
            PrimaryButton(title: Copy.Onboarding.firstSessionComplete) {
                flow.finishFirstSession()
            }
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .padding(.bottom, 12)
    }
}
