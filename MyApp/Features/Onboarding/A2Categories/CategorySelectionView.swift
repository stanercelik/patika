import SwiftUI

struct CategorySelectionView: View {
    @State private var viewModel: CategorySelectionViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(initialValue: CategorySelectionViewModel(flow: flow))
    }

    var body: some View {
        // Varsayılan metin boyutunda 10 seçeneğin tamamı kaydırmadan görünür;
        // ScrollView yalnızca büyük Dynamic Type boyutlarında devreye girer.
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.categoriesHeadline,
            hint: Copy.Onboarding.categoriesHint
        ) {
            VStack(spacing: 10) {
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

    var body: some View {
        Button {
            Theme.softHaptic()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 26)
                    .accessibilityHidden(true)
                Text(category.label)
                    .font(.body.weight(isSelected ? Theme.Weight.action : Theme.Weight.body))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                SelectionMark(isSelected: isSelected)
            }
            .foregroundStyle(Theme.textPrimary.color)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
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
