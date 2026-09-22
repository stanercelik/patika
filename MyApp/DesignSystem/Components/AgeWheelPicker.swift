import SwiftUI

struct AgeWheelPicker: View {
    @Binding var selection: Int
    var onSelect: (Int) -> Void

    @State private var scrollID: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title2) private var rowHeight: CGFloat = 48

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(AgeSelection.allowed, id: \.self) { age in
                    Text(age.formatted())
                        .font(Theme.TypeFace.screenTitle)
                        .foregroundStyle(WoodlandStyle.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: rowHeight)
                        .id(age)
                        .scrollTransition(.interactive, axis: .vertical) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity || reduceMotion ? 1 : 0.84)
                                .opacity(phase.isIdentity ? 1 : 0.34)
                                .blur(radius: phase.isIdentity || reduceMotion ? 0 : 2.5)
                        }
                        .accessibilityHidden(true)
                }
            }
            .scrollTargetLayout()
        }
        .frame(height: rowHeight * 5)
        .contentMargins(.vertical, rowHeight * 2, for: .scrollContent)
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollPosition(id: $scrollID, anchor: .center)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(WoodlandStyle.ink.opacity(0.30), lineWidth: Theme.Line.border)
                .frame(height: rowHeight)
                .allowsHitTesting(false)
        }
        .onAppear { scrollID = selection }
        .onChange(of: scrollID) { _, next in
            guard let next, AgeSelection.allowed.contains(next), next != selection else { return }
            selection = next
            onSelect(next)
            Theme.softHaptic(intensity: 0.55)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Copy.Onboarding.ageHeadline))
        .accessibilityValue(Text(verbatim: selection.formatted()))
        .accessibilityAdjustableAction { direction in
            let delta = direction == .increment ? 1 : -1
            let next = min(max(selection + delta, AgeSelection.allowed.lowerBound), AgeSelection.allowed.upperBound)
            guard next != selection else { return }
            selection = next
            scrollID = next
            onSelect(next)
        }
    }
}
