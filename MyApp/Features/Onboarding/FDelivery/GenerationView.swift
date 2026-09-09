import SwiftUI

/// F1 — Üretim ekranı (PRD-Ek Onboarding §7.1).
///
/// Ekranda tek bir şey oluyor: iz yukarıdan aşağı işaretleniyor. Bu, A1'deki yol
/// animasyonunun ve `PathProgressBar`ın aynı dili — "sonu olan bir yol" metaforu
/// burada da çizgiyle anlatılıyor, yeni bir görsel fikir icat edilmiyor.
///
/// **Butonu yok.** Kullanıcının yapacağı bir şey yok ve boş bir CTA koymak
/// bekleyişi kullanıcının sorunu gibi gösterirdi; ekran işi bitince kendi geçer.
/// Bu, onboarding'de kullanıcı dokunuşu beklemeyen tek ekran.
///
/// Aktif satırın düğümü nefes döngüsüyle soluk alır (`TrailRow.Node.active`):
/// bekleyiş boyunca ekranda hareket eden tek nesne, kullanıcının nefesiyle aynı
/// hızda. Yüzde göstergesi ve dönen çark yok — ikisi de bekleyişi ölçülecek bir
/// yük hâline getirir.
struct GenerationView: View {
    @State private var viewModel: GenerationViewModel

    init(flow: OnboardingFlowViewModel) {
        self._viewModel = State(
            initialValue: GenerationViewModel(flow: flow)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DisplayText(Copy.Onboarding.generationHeadline, size: 30)
                .padding(.bottom, 34)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(viewModel.stages.enumerated()), id: \.offset) { index, stage in
                    TrailRow(
                        node: viewModel.state(of: index),
                        showsLineAbove: index > 0,
                        showsLineBelow: index < viewModel.stages.count - 1
                    ) {
                        Text(stage)
                            .font(.body.weight(
                                viewModel.isActive(index) ? Theme.Weight.action : Theme.Weight.body
                            ))
                            .foregroundStyle(
                                Theme.textPrimary.color.opacity(opacity(of: index))
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 24)
                    }
                }
            }
            .animation(Theme.Motion.crossFade, value: viewModel.completedStages)

            if viewModel.hasFailed {
                Text(Copy.Error.pathGenerationFailed)
                    .font(.footnote.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                    .padding(.top, 18)

                SecondaryTextButton(title: Copy.Button.retry) {
                    viewModel.retry()
                }
                .padding(.top, 12)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, Theme.Spacing.screenMargin)
        .padding(.top, 24)
        .task { viewModel.start() }
        .onDisappear { viewModel.cancel() }
    }

    /// Gelecek adımlar soluk, tamamlananlar geri çekilmiş, olan şey en parlak.
    /// Kullanıcı listeyi okumuyor, nerede olduğuna bakıyor.
    private func opacity(of index: Int) -> Double {
        if viewModel.isActive(index) { return 0.95 }
        return index < viewModel.completedStages ? 0.55 : 0.32
    }
}

#Preview {
    OnboardingPreviewHost(
        step: .f1Generation,
        draft: {
            var draft = OnboardingDraft()
            draft.categories = [.sleep]
            return draft
        }()
    ) { flow in
        GenerationView(flow: flow)
    }
}
