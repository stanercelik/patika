import SwiftUI

/// A scrolling introduction. Effects stay in the render layer, so the route
/// does not relayout on every scroll frame or jump when the header fades.
struct PathHomeHeader: View {
    let title: String
    let hasNextStep: Bool
    let phase: PathPhase

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .accessibilityHidden(true)
                Text(Copy.Path.screenTitle)
                    .tracking(2)
            }
            .font(.caption.weight(Theme.Weight.emphasis))
            .foregroundStyle((reduceTransparency ? Theme.textSecondary.color : WoodlandStyle.secondaryInk))

            Text(verbatim: title)
                .font(.largeTitle.weight(Theme.Weight.display))
                .foregroundStyle((reduceTransparency ? Theme.textPrimary.color : WoodlandStyle.ink))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(hasNextStep ? Copy.Path.readyNote : Copy.Path.finishedHeadline)
                .font(.subheadline.weight(Theme.Weight.body))
                .foregroundStyle((reduceTransparency ? Theme.textSecondary.color : WoodlandStyle.secondaryInk))
                .fixedSize(horizontal: false, vertical: true)


        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
