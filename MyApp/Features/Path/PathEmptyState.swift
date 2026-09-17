import SwiftUI

/// A missing path has a clear recovery action, rather than a dead end.
struct PathEmptyState: View {
    let onCreate: () -> Void
    let onRetry: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(Copy.Path.screenTitle)
                    .font(.caption.weight(Theme.Weight.emphasis))
                    .tracking(2)
                    .foregroundStyle(Theme.textSecondary.color)

                if !dynamicTypeSize.isAccessibilitySize {
                    PatikaIllustration(artwork: .trail)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                Text(Copy.Empty.pathInvitation)
                    .font(.largeTitle.weight(Theme.Weight.display))
                    .foregroundStyle(Theme.textPrimary.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(Copy.Empty.pathInvitationBody)
                    .font(.body.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)

                PrimaryButton(title: Copy.Button.start, action: onCreate)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 12) {
                    Text(Copy.Empty.pathInvitationNote)
                        .font(.footnote.weight(Theme.Weight.body))
                        .foregroundStyle(Theme.textSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(action: onRetry) {
                        Label(Copy.Empty.checkPath, systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(Theme.Weight.action))
                            .foregroundStyle(Theme.textPrimary.color)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.calm)
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.top, 72)
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}
