import SwiftUI

/// "Yolum" sekmesi — onboarding sonrası patikanın hâli (PRD §6).
///
/// ## İz dili
///
/// F1 ve F2 ile aynı görsel dil: yukarıdan aşağı inen tek bir iz, üzerinde
/// düğümler. Ürünün tek metaforu "sonu olan bir yol" ve her ekranda aynı
/// çizgiyle anlatılıyor.
///
/// ## İz burada **tek parça** çiziliyor
///
/// F2'de her satır kendi çizgi parçasını taşır; burada çizgi listenin arkasında
/// tek bir dikdörtgen ve uçları gradyanla soluyor. Gerekçe: liste kaydırıldığı
/// için çizginin ekran kenarında bıçakla kesilmiş gibi bitmesi, yolun orada
/// bittiğini söylüyordu. Solarak kesilen bir iz "devam ediyor ama görmüyorsun"
/// diyor — kaydırma davranışıyla aynı şey.
///
/// ## Bir satır açılınca diğerleri küçülür
///
/// Ekranda aynı anda tek bir şey büyük duruyor. Açılan satır kart hâline gelip
/// eylemini gösterirken kalanlar hem soluyor hem hafifçe küçülüyor — hangi
/// satırın konuştuğu tartışmasız kalıyor. Hareketin tamamı tek bir yay
/// (`Theme.Motion.pathExpand`) üzerinden gidiyor: iki ayrı animasyon eğrisi,
/// aynı anda çalışınca kayma hissi üretiyordu.
///
/// ## Sayaç yok, streak yok
///
/// Kaçırılan gün hiçbir şeyi geri almıyor: ekranda ne seri, ne "bugün de kaçtı",
/// ne yüzde. Tek söylenen, sıradaki adımın hazır olduğu.
struct MyPathView: View {
    @Environment(PaletteController.self) private var palette
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

            ScrollView {
                trail
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                    .padding(.top, 6)
                    // Son satır sekme çubuğunun altında kalmasın.
                    .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            // İzin uçları **kesilmiyor, soluyor**. Bıçakla kesilmiş bir çizgi
            // yolun orada bittiğini söylüyordu; solan bir iz "devam ediyor ama
            // görmüyorsun" diyor — kaydırmanın kendisiyle aynı şey.
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

    /// Adımlar ve arkalarındaki tek parça iz.
    private var trail: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel?.steps ?? []) { step in
                if let viewModel {
                    PathStepRow(
                        step: step,
                        viewModel: viewModel,
                        onStart: { runningStep = step }
                    )
                }
            }
        }
        .background(alignment: .topLeading) { rail }
    }

    /// Uçları solarak biten iz. Maske uzunluğu içeriğe göre değil sabit:
    /// oranla verilince kısa path'lerde iz neredeyse tamamen soluyordu.
    private var rail: some View {
        GeometryReader { geo in
            let fade = min(72, geo.size.height * 0.22)
            let ratio = fade / max(geo.size.height, 1)
            Rectangle()
                .fill(Theme.textPrimary.color.opacity(0.16))
                .frame(width: Theme.Line.trail)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: ratio),
                            .init(color: .black, location: 1 - ratio),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(width: PathStepRow.railWidth)
        .accessibilityHidden(true)
    }
}

/// İz üzerindeki tek adım. Kapalıyken bir satır, açıkken bir kart.
private struct PathStepRow: View {
    let step: PathStepRecord
    let viewModel: MyPathViewModel
    var onStart: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var nodeCenterOffset: CGFloat = 11

    static let railWidth: CGFloat = 22
    private static let contentSpacing: CGFloat = 14

    private var isExpanded: Bool { viewModel.isExpanded(step) }
    private var isLocked: Bool { viewModel.isLocked(step) }
    private var isCompleted: Bool { viewModel.isCompleted(step) }
    private var isNext: Bool { step.id == viewModel.nextStep?.id }

    var body: some View {
        Button {
            withAnimation(reduceMotion ? Theme.Motion.crossFade : Theme.Motion.pathExpand) {
                viewModel.toggle(step)
            }
        } label: {
            body(for: step)
        }
        .buttonStyle(.calm)
        .accessibilityElement(children: .combine)
        .accessibilityHint(isLocked ? Text(Copy.Path.lockedAccessibility) : Text(""))
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
                .fill(Color.white.opacity(isExpanded ? 0.10 : 0))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            Theme.textPrimary.color.opacity(isExpanded ? 0.16 : 0),
                            lineWidth: 1
                        )
                }
        }
        .padding(.leading, Self.railWidth + Self.contentSpacing)
        .padding(.trailing, isExpanded ? 0 : 4)
        .padding(.bottom, isExpanded ? 22 : 20)
        // Açık olan büyür, kalanlar hafifçe küçülüp soluyor. Ölçek sola
        // sabitlendi: merkeze göre küçülen satır izden kopuyordu.
        .scaleEffect(scale, anchor: .leading)
        .opacity(opacity)
        .overlay(alignment: .topLeading) { node }
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

    /// Düğüm, satırın **ilk metin satırının** optik ortasına oturur. Açık
    /// satırda kartın iç boşluğu kadar aşağı kayıyor: yoksa düğüm kartın üst
    /// köşesine yapışıp etiketten kopuyordu.
    private var node: some View {
        TrailNodeDot(node: viewModel.node(for: step))
            .frame(width: Self.railWidth)
            .offset(
                y: nodeCenterOffset
                    + (isExpanded ? 16 : 0)
                    - TrailNodeDot.size(for: viewModel.node(for: step)) / 2
            )
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

    private var scale: Double {
        guard !reduceMotion else { return 1 }
        return isExpanded ? 1 : 0.98
    }

    private var opacity: Double {
        if isExpanded { return 1 }
        // Bir şey açıkken kalanlar geri çekiliyor; hiçbiri açık değilse liste
        // kendi doğal kontrastında duruyor.
        return viewModel.expandedStepID == nil ? 1 : 0.72
    }
}

/// `fullScreenCover(item:)` kimlik istiyor; adımın kendi kimliği zaten var.
extension PathStepRecord: Identifiable {}
