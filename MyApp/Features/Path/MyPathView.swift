import SwiftUI

/// "Yolum" sekmesi — onboarding sonrası patikanın hâli (PRD §6).
///
/// ## İz dili
///
/// F1 ve F2 ile aynı görsel dil: yukarıdan aşağı inen tek bir iz, üzerinde
/// düğümler. Ürünün tek metaforu "sonu olan bir yol" ve her ekranda aynı
/// çizgiyle anlatılıyor.
///
/// ## Sayaç yok, streak yok
///
/// Kaçırılan gün hiçbir şeyi geri almıyor: ekranda ne seri, ne "bugün de kaçtı",
/// ne geri sayan bir gün. Tek söylenen, sıradaki adımın hazır olduğu.
struct MyPathView: View {
    @Environment(PaletteController.self) private var palette
    @Environment(AppServices.self) private var services

    @State private var viewModel: MyPathViewModel?
    @State private var runningStep: PathStepRecord?

    var body: some View {
        ZStack {
            BreathingMeshBackground(palette: palette.current, safeY: 0.12)
                .ignoresSafeArea()
            content
        }
        .task {
            if viewModel == nil { viewModel = MyPathViewModel(services: services) }
            await viewModel?.load()
        }
        .fullScreenCover(item: $runningStep) { step in
            if let path = viewModel?.path {
                PathSessionView(services: services, path: path, step: step)
                    .environment(palette)
            }
        }
        .onChange(of: runningStep) { old, new in
            // Oturum kapandı: tamamlanma sunucuda, ekran yeniden okuyor.
            guard old != nil, new == nil else { return }
            Task { await viewModel?.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel?.state ?? .loading {
        case .loading:
            ProgressView()
                .tint(Theme.textPrimary.color)
                .accessibilityLabel(Text(Copy.Path.loading))
        case .empty:
            ScreenPlaceholder(title: "Yolum", message: Copy.Empty.noPath)
        case .failed:
            VStack(spacing: Theme.Spacing.stack) {
                BodyText(Copy.Path.loadError)
                Button(Copy.Path.retry) {
                    Task { await viewModel?.load() }
                }
                .buttonStyle(.calm)
                .foregroundStyle(Theme.textPrimary.color)
                .frame(minHeight: 44)
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
        case .ready(let path):
            ready(path)
        }
    }

    private func ready(_ path: ActivePath) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.stack) {
                    DisplayText(LocalizedStringResource(stringLiteral: path.title), size: 28)
                        .padding(.bottom, 4)

                    ForEach(Array(path.steps.enumerated()), id: \.element.id) { index, step in
                        TrailRow(
                            node: viewModel?.node(for: step) ?? .pending,
                            showsLineAbove: index > 0,
                            showsLineBelow: index < path.steps.count - 1
                        ) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Copy.Path.stepLabel(day: step.day))
                                    .font(.caption.weight(Theme.Weight.body))
                                    .foregroundStyle(Theme.textSecondary.color)
                                Text(verbatim: step.title)
                                    .font(.body.weight(Theme.Weight.emphasis))
                                    .foregroundStyle(Theme.textPrimary.color)
                            }
                            .padding(.bottom, 18)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.top, 24)
            }

            if let next = viewModel?.nextStep {
                PrimaryButton(
                    title: path.completedStepCount == 0 ? Copy.Path.startCTA : Copy.Path.continueCTA,
                    isEnabled: true
                ) {
                    runningStep = next
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.bottom, 12)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Copy.Path.finishedHeadline)
                        .font(.title3.weight(Theme.Weight.title))
                        .foregroundStyle(Theme.textPrimary.color)
                    BodyText(Copy.Path.finishedBody)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.bottom, 16)
            }
        }
    }
}

extension PathStepRecord: Identifiable {}
