import SwiftUI

struct CategorySelectionView: View {
    @State private var viewModel: CategorySelectionViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(initialValue: CategorySelectionViewModel(flow: flow))
    }

    var body: some View {
        // İki eşit sütun hızlı taranır; ortak iskelet daha kısa ekranlarda ve
        // büyük Dynamic Type'ta doğal olarak kaydırır.
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.categoriesHeadline,
            hint: Copy.Onboarding.categoriesHint
        ) {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 10),
                    count: dynamicTypeSize.isAccessibilitySize ? 1 : 2
                ),
                spacing: 10
            ) {
                ForEach(viewModel.categories) { category in
                    CategoryCard(
                        category: category,
                        isSelected: viewModel.isSelected(category),
                        isDimmed: viewModel.isDimmed(category)
                    ) {
                        viewModel.toggle(category)
                    }
                }
            }
        } footer: {
            // Ham `PrimaryButton` değil: ortak footer ikincil satırın yerini de
            // ayırıyor ve buton A2'den B6'ya kadar aynı yükseklikte kalıyor.
            OnboardingQuestionFooter(
                primaryTitle: Copy.Button.next,
                primaryDisabledTitle: Copy.Onboarding.chooseOneCTA,
                isPrimaryEnabled: viewModel.canContinue,
                primaryAction: { viewModel.continueTapped() }
            )
        }
    }
}

/// Kategori kartı.
///
/// Seçili durum üç sinyalle birden anlatılır — dolgu, kenarlık ve metin ağırlığı.
/// Renk tek başına anlam taşımaz (Ton eki §7).
struct CategoryCard: View {
    let category: ProblemCategory
    let isSelected: Bool
    let isDimmed: Bool
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button {
            Theme.softHaptic()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: category.icon)
                        .font(.title3)
                        .symbolRenderingMode(.monochrome)
                        .accessibilityHidden(true)
                    Spacer(minLength: 8)
                    SelectionMark(isSelected: isSelected)
                }

                Text(category.label)
                    .font(.body.weight(isSelected ? Theme.Weight.action : Theme.Weight.body))
                    .multilineTextAlignment(.leading)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.textPrimary.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(
                maxWidth: .infinity,
                minHeight: dynamicTypeSize.isAccessibilitySize ? 260 : 148,
                maxHeight: dynamicTypeSize.isAccessibilitySize ? nil : 148,
                alignment: .leading
            )
            .background { CalmSurface(isEmphasized: isSelected) }
            .opacity(isDimmed ? 0.62 : 1.0)
        }
        .buttonStyle(.calm)
        .animation(Theme.Motion.crossFade, value: isSelected)
        .animation(Theme.Motion.crossFade, value: isDimmed)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    OnboardingPreviewHost(step: .a2Categories) { flow in
        CategorySelectionView(flow: flow)
    }
}
