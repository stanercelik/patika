import SwiftUI

struct CategorySelectionView: View {
    @State private var viewModel: CategorySelectionViewModel

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(initialValue: CategorySelectionViewModel(flow: flow))
    }

    // Aralık ve kart yoğunluğu, 10 seçeneğin ortak alt bölge yüksekliğiyle birlikte
    // kaydırmadan sığmasına göre ayarlı. Alt bölge değişirse burası da değişmeli.
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        // Varsayılan metin boyutunda 10 seçeneğin tamamı kaydırmadan görünür;
        // ScrollView yalnızca büyük Dynamic Type boyutlarında devreye girer.
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.categoriesHeadline,
            hint: Copy.Onboarding.categoriesHint
        ) {
            LazyVGrid(columns: columns, spacing: 8) {
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
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Image(systemName: category.icon)
                        .font(.title3)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(
                            Theme.textPrimary.color.opacity(isSelected ? 1.0 : 0.72)
                        )
                    Spacer(minLength: 0)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(Theme.Weight.action))
                            .foregroundStyle(Theme.textPrimary.color)
                            .transition(.opacity)
                    }
                }

                Spacer(minLength: 2)

                Text(category.label)
                    .font(
                        .subheadline.weight(
                            isSelected ? Theme.Weight.action : Theme.Weight.emphasis
                        )
                    )
                    .foregroundStyle(Theme.textPrimary.color)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.16 : 0.07))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        Theme.textPrimary.color.opacity(isSelected ? 0.55 : 0.0),
                        lineWidth: Theme.Line.border
                    )
            }
            .opacity(isDimmed ? 0.40 : 1.0)
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
