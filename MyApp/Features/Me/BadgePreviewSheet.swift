import SwiftUI

/// Natural content heights are measured before the shared height is applied.
/// All cards, across every family, grow to fit the longest localized description.
struct BadgeCardHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct BadgePreviewSheet: View {
    let badge: BadgeID
    let isEarned: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // The full artwork can be inspected even before earning it;
                    // the description below preserves its actual earned status.
                    BadgeMedallion(id: badge, isEarned: true, size: 260)
                    Text(Copy.Me.Badge.title(badge))
                        .font(Theme.TypeFace.sectionTitle)
                        .foregroundStyle(Theme.textPrimary.color)
                    Text(isEarned ? Copy.Me.Badge.earned(badge) : Copy.Me.Badge.howToEarn(badge))
                        .font(Theme.TypeFace.rowValue)
                        .foregroundStyle(Theme.textSecondary.color)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(WoodlandStyle.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(Text(.supportClose))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
