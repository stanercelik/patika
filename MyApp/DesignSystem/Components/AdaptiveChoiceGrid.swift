import SwiftUI

/// All onboarding answer choices use a predictable, full-width vertical list.
struct AdaptiveChoiceGrid<Option: OnboardingChoice>: View {
    let options: [Option]
    let isSelected: (Option) -> Bool
    let onSelect: (Option) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(options) { option in
                ChoiceRow(label: option.label, isSelected: isSelected(option)) {
                    onSelect(option)
                }
            }
        }
    }
}
