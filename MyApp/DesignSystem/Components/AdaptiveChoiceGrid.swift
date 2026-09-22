import SwiftUI

/// Prefers a compact two-column choice field and falls back to a single column
/// when text or available height makes that layout too dense.
struct AdaptiveChoiceGrid<Option: OnboardingChoice>: View {
    let options: [Option]
    let isSelected: (Option) -> Bool
    let onSelect: (Option) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            singleColumn
        } else {
            ViewThatFits(in: .vertical) {
                Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                    ForEach(Array(stride(from: 0, to: options.count, by: 2)), id: \.self) { start in
                        GridRow {
                            row(options[start])
                            if options.indices.contains(start + 1) {
                                row(options[start + 1])
                            } else {
                                Color.clear.frame(minHeight: 44)
                            }
                        }
                    }
                }
                singleColumn
            }
        }
    }

    private var singleColumn: some View {
        VStack(spacing: 10) {
            ForEach(options) { option in row(option) }
        }
    }

    private func row(_ option: Option) -> some View {
        ChoiceRow(label: option.label, isSelected: isSelected(option)) {
            onSelect(option)
        }
    }
}
