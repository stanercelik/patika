import SwiftUI

/// "Yolum" sekmesi — onboarding sonrası patikanın hâli (PRD §6).
///
/// ## İz dili
///
/// F2 ile aynı görsel dil: sağa ve sola sakinçe kıvrılan tek bir iz, üzerinde
/// durum düğümleri. Satırlar aynı sınır noktasında birleştiği için yol uzun
/// kişisel başlıklarda ve Dynamic Type'ta kopmadan devam ediyor.
///
/// Sıradaki adım daha büyük, nefes ritminde bir düğüm ve açılabilen kartla
/// belirginleşiyor. Gelecek adımların gerçek başlıkları görünür kalıyor; kilit
/// işareti ve kesikli iz henüz açılamadıklarını birlikte anlatıyor.
///
/// ## Sayaç yok, streak yok
///
/// Kaçırılan gün hiçbir şeyi geri almıyor: ekranda ne seri, ne "bugün de kaçtı",
/// ne yüzde. Tek söylenen, sıradaki adımın hazır olduğu.
struct MyPathView: View {
    @Environment(PaletteController.self) private var palette
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var viewModel: MyPathViewModel?
    @State private var runningStep: PathStepRecord?

    var body: some View {
        ZStack {
            BreathingMeshBackground(
                palette: palette.current,
                safeY: 0.12,
                boostsFrameRate: true
            )
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
        .onChange(of: viewModel?.recentlyCompletedStepID) { _, completedID in
            guard completedID != nil, !reduceMotion else { return }
            Theme.softHaptic(intensity: 0.55)
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
        VStack(alignment: .leading, spacing: 0) {
            // Başlık path üretiminden geliyor: kullanıcının kendi kategorisinden
            // ve cümlesinden türetilmiş ad. Kaydırmanın **dışında** duruyor:
            // yirmi bir satırlık bir listede yolun adı ekrandan çıkınca
            // kullanıcı hangi yolda olduğunu kaybediyordu.
            DisplayText(LocalizedStringResource(stringLiteral: path.title), size: 28)
                // SOS her ekranda sağ üstte sabit; başlık onun altından başlar.
                .padding(.top, 48)
                .padding(.trailing, 56)
                .padding(.bottom, 22)
                .padding(.horizontal, Theme.Spacing.screenMargin)

            ScrollViewReader { proxy in
                ScrollView {
                    trail
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                        .padding(.top, 6)
                        // Son satır sekme çubuğunun altında kalmasın.
                        .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                // İlk açılışta kullanıcı tamamladığı satırları yeniden geçmek
                // zorunda kalmaz; sıradaki düğüm görünür alanın merkezine gelir.
                .task(id: path.nextStep?.id) {
                    guard let nextID = path.nextStep?.id else { return }
                    await Task.yield()
                    proxy.scrollTo(
                        nextID,
                        anchor: dynamicTypeSize.isAccessibilitySize ? .top : .center
                    )
                }
                // İzin uçları **kesilmiyor, soluyor**. Bıçakla kesilmiş bir
                // çizgi yolun orada bittiğini söylüyordu; solan iz devam eden
                // içeriği anlatıyor.
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.045),
                            .init(color: .black, location: 0.86),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        }
    }

    /// Adımlar ve kıvrımlı ortak iz.
    private var trail: some View {
        let steps = viewModel?.steps ?? []
        let phases = steps.map { viewModel?.phase(for: $0) }
        let positions = JourneyRouteLayout.positions(
            for: phases,
            usesAccessibleLayout: dynamicTypeSize.isAccessibilitySize
        )

        return LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                if let viewModel {
                    PathStepRow(
                        index: index,
                        totalCount: viewModel.steps.count,
                        position: positions[index],
                        phase: phases[index],
                        startsPhase: viewModel.startsPhase(step),
                        step: step,
                        viewModel: viewModel,
                        onStart: { runningStep = step }
                    )
                    .id(step.id)
                }
            }
        }
    }
}

/// İz üzerindeki tek adım. Kapalıyken bir satır, açıkken bir kart.
private struct PathStepRow: View {
    let index: Int
    let totalCount: Int
    let position: JourneyRoutePosition
    let phase: PathPhase?
    let startsPhase: Bool
    let step: PathStepRecord
    let viewModel: MyPathViewModel
    var onStart: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var isExpanded: Bool { viewModel.isExpanded(step) }
    private var isLocked: Bool { viewModel.isLocked(step) }
    private var isCompleted: Bool { viewModel.isCompleted(step) }

    var body: some View {
        JourneyMapRow(
            index: index,
            totalCount: totalCount,
            position: position,
            phase: phase,
            startsPhase: startsPhase,
            node: viewModel.node(for: step),
            showsLock: isLocked,
            isProminent: isExpanded
        ) {
            Button {
                Theme.softHaptic(intensity: 0.25)
                withAnimation(reduceMotion ? Theme.Motion.crossFade : Theme.Motion.pathExpand) {
                    viewModel.toggle(step)
                }
            } label: {
                body(for: step)
            }
            .buttonStyle(.calm)
            .disabled(isLocked)
            .accessibilityElement(children: .combine)
            .accessibilityHint(isLocked ? Text(Copy.Path.lockedAccessibility) : Text(""))
        }
    }

    private func body(for step: PathStepRecord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if isExpanded { expanded }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isExpanded ? 16 : 0)
        .background {
            // Kart yüzeyi `ChoiceRow`un yüzeyi; açık satır bir kademe belirgin.
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    reduceTransparency
                        ? Color.black.opacity(isExpanded ? 0.86 : 0)
                        : Color.white.opacity(isExpanded ? 0.075 : 0)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            Theme.textPrimary.color.opacity(isExpanded ? 0.14 : 0),
                            lineWidth: Theme.Line.journeyConnector
                        )
                }
        }
        .padding(.trailing, isExpanded ? 0 : 4)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(Copy.Path.stepLabel(day: step.day))
                    .font(.caption.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color.opacity(isLocked ? 0.62 : 1))
                if isLocked {
                    // Kilit tek başına anlam taşımıyor: açık satırda aynı şey
                    // cümleyle de yazıyor (renk tek başına anlam taşımaz kuralı).
                    Image(systemName: "lock")
                        .font(.caption2.weight(Theme.Weight.emphasis))
                        .foregroundStyle(Theme.textPrimary.color.opacity(0.34))
                        .accessibilityHidden(true)
                }
            }

            Text(verbatim: step.title)
                .font(titleFont)
                .foregroundStyle(Theme.textPrimary.color.opacity(titleOpacity))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.isMeasurementDay(step), !isExpanded {
                Text(Copy.Path.measurementNote)
                    .font(.caption2.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color.opacity(0.62))
                    .padding(.top, 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Açık satırın gövdesi. Buradaki her satır **gerçek path verisinden**
    /// geliyor: faz gün sayısından, teknikler sunucunun seçtiği `block_ids`den.
    @ViewBuilder
    private var expanded: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let phase = viewModel.phase(for: step) {
                Text(phase.label)
                    .font(.caption.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color.opacity(0.58))
            }

            // Teknik satırı başlıkla aynıysa yazılmıyor: aynı cümleyi iki kez
            // okutmak bilgi değil, gürültü.
            if let techniques = viewModel.techniques(for: step), techniques != step.title {
                Text(verbatim: techniques)
                    .font(.subheadline.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if viewModel.isMeasurementDay(step) {
                Text(Copy.Path.measurementNotice)
                    .font(.footnote.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }

            action
        }
        .padding(.top, 12)
        .transition(.opacity)
    }

    @ViewBuilder
    private var action: some View {
        if isLocked {
            Text(Copy.Path.lockedHint)
                .font(.subheadline.weight(Theme.Weight.emphasis))
                .foregroundStyle(Theme.textPrimary.color.opacity(0.52))
                .padding(.top, 2)
        } else {
            PrimaryButton(
                title: isCompleted ? Copy.Path.replayCTA : Copy.Path.continueCTA,
                isEnabled: true,
                action: onStart
            )
            .padding(.top, 4)
        }
    }

    // MARK: - Türetilen görünüm değerleri

    private var titleFont: Font {
        isExpanded
            ? .title3.weight(Theme.Weight.title)
            : .body.weight(Theme.Weight.emphasis)
    }

    private var titleOpacity: Double {
        if isExpanded { return 1 }
        if isCompleted { return 0.46 }
        return isLocked ? 0.62 : 0.92
    }

}

/// `fullScreenCover(item:)` kimlik istiyor; adımın kendi kimliği zaten var.
extension PathStepRecord: Identifiable {}
