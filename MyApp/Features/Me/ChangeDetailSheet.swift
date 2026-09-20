import Charts
import SwiftUI

/// Değişim ayrıntısı (profile-design §8.1).
///
/// Oura'nın sağlık ekranlarının iskeleti, **sayısız**: eksenlerde sayı yok,
/// dikey eksende yalnızca yön adları, yatayda ölçüm noktası adları. Yüzde bu
/// ekranda da yok — sayılar path sonu raporunun işi.
struct ChangeDetailSheet: View {
    let viewModel: MeViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @SceneStorage("me.change-detail.layer") private var layerRaw = MeasurementLayer.behavior.rawValue

    private var layer: MeasurementLayer { MeasurementLayer(rawValue: layerRaw) ?? .behavior }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if let change = viewModel.change {
                        Text(verbatim: change.headline)
                            .font(.title3.weight(Theme.Weight.title))
                            .foregroundStyle(Theme.textPrimary.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Picker(selection: $layerRaw) {
                        ForEach(MeasurementLayer.allCases, id: \.self) { layer in
                            Text(Copy.Me.layerShort(layer)).tag(layer.rawValue)
                        }
                    } label: {
                        Text(Copy.Me.layerPickerLabel)
                    }
                    .pickerStyle(.segmented)

                    trend
                    itemChanges

                    NavigationLink {
                        MeasurementMethodView()
                    } label: {
                        HStack {
                            Text(Copy.Me.howWeMeasure)
                                .font(.body.weight(Theme.Weight.emphasis))
                                .foregroundStyle(Theme.textPrimary.color)
                            Spacer(minLength: 8)
                            ProfileChevron()
                        }
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.calm)

                    VStack(alignment: .leading, spacing: 6) {
                        if viewModel.change?.isProvisional == true {
                            Text(Copy.Me.baselineProvisional)
                        }
                        Text(Copy.clinicalDisclaimer)
                    }
                    .font(.footnote.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.vertical, 8)
            }
            .navigationTitle(Text(Copy.Me.changeTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Çizgi

    @ViewBuilder
    private var trend: some View {
        let points = viewModel.series(for: layer)
        if dynamicTypeSize.isAccessibilitySize {
            // AX boyutlarında grafik okunamayacak kadar küçülür; metin okunur.
            VStack(alignment: .leading, spacing: 14) {
                ForEach(points) { point in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: point.label)
                            .font(.body.weight(Theme.Weight.emphasis))
                            .foregroundStyle(Theme.textPrimary.color)
                        Text(point.isBaseline
                             ? Copy.Me.chartBaselinePoint
                             : Copy.Me.directionWord(layer, point.direction))
                            .font(.body.weight(Theme.Weight.body))
                            .foregroundStyle(Theme.textSecondary.color)
                    }
                }
            }
        } else {
            let span = max(
                ChangeAnalysis.fullScalePoints,
                (points.map { abs($0.improvement) }.max() ?? 0) + 8
            )
            VStack(alignment: .leading, spacing: 6) {
                axisCaption(Copy.Me.chartBetter(layer))
                Chart {
                    RuleMark(y: .value(String(localized: Copy.Me.chartBaseline), 0))
                        .foregroundStyle(Theme.textPrimary.color.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    ForEach(points) { point in
                        LineMark(
                            x: .value(String(localized: Copy.Me.chartXAxis), point.label),
                            y: .value(String(localized: Copy.Me.chartYAxis), point.improvement)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Theme.textPrimary.color)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

                        PointMark(
                            x: .value(String(localized: Copy.Me.chartXAxis), point.label),
                            y: .value(String(localized: Copy.Me.chartYAxis), point.improvement)
                        )
                        .foregroundStyle(Theme.textPrimary.color)
                        .symbolSize(56)
                        .accessibilityLabel(Text(verbatim: point.label))
                        .accessibilityValue(
                            point.isBaseline
                                ? Text(Copy.Me.chartBaselinePoint)
                                : Text(Copy.Me.directionWord(layer, point.direction))
                        )
                    }
                }
                .chartYScale(domain: -span...span)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption.weight(Theme.Weight.body))
                            .foregroundStyle(Theme.textSecondary.color)
                    }
                }
                .frame(height: 188)
                .animation(.easeInOut(duration: Theme.Motion.screenTransition), value: layer)
                axisCaption(Copy.Me.chartWorse(layer))
            }
        }
    }

    private func axisCaption(_ text: LocalizedStringResource) -> some View {
        Text(text)
            .font(.caption.weight(Theme.Weight.body))
            .foregroundStyle(Theme.textSecondary.color)
            .accessibilityHidden(true)
    }

    // MARK: - Maddeler

    @ViewBuilder
    private var itemChanges: some View {
        let changes = viewModel.itemChanges(for: layer)
        if changes.most != nil || changes.least != nil {
            VStack(alignment: .leading, spacing: 20) {
                if let most = changes.most {
                    itemBlock(title: Copy.Me.mostChanged, change: most)
                }
                if let least = changes.least {
                    itemBlock(title: Copy.Me.leastChanged, change: least)
                }
            }
        }
    }

    private func itemBlock(title: LocalizedStringResource, change: ChangeAnalysis.ItemChange) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote.weight(Theme.Weight.body))
                .foregroundStyle(Theme.textSecondary.color)
            Text(verbatim: change.prompt)
                .font(.body.weight(Theme.Weight.emphasis))
                .foregroundStyle(Theme.textPrimary.color)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 4) {
                Text(Copy.Me.directionWord(layer, change.direction))
                Image(systemName: Self.symbol(for: change.direction))
                    .accessibilityHidden(true)
            }
            .font(.subheadline.weight(Theme.Weight.emphasis))
            .foregroundStyle(Theme.textSecondary.color)
        }
        .padding(.leading, 16)
        .background(alignment: .leading) {
            Capsule()
                .fill(Theme.textPrimary.color.opacity(0.20))
                .frame(width: 2)
        }
        .accessibilityElement(children: .combine)
    }

    private static func symbol(for direction: MeasurementComparison.Direction) -> String {
        switch direction {
        case .improved: "arrow.up.right"
        case .unchanged: "arrow.right"
        case .worsened: "arrow.down.right"
        }
    }
}

/// "Nasıl ölçüyoruz" — güvenin kaynağı gizem değil şeffaflık.
///
/// Ayarların geri kalanıyla aynı dil: koyu orman zemini, adaçayı kartlar, projenin
/// tipografi rolleri.
struct MeasurementMethodView: View {
    var body: some View {
        ZStack {
            WoodlandStyle.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.sectionSpacing) {
                    Text(Copy.Me.Method.intro)
                        .font(Theme.TypeFace.rowValue)
                        .foregroundStyle(Theme.textPrimary.color)
                        .fixedSize(horizontal: false, vertical: true)

                    block(title: Copy.Me.Method.layersTitle, lines: [
                        Copy.Me.Method.emotion,
                        Copy.Me.Method.behavior,
                        Copy.Me.Method.selfEfficacy,
                    ])
                    block(title: Copy.Me.Method.rotationTitle, lines: [Copy.Me.Method.rotation])
                    block(title: Copy.Me.Method.clinicalTitle, lines: [Copy.Me.Method.clinical])
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(Text(Copy.Me.Method.title))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func block(title: LocalizedStringResource, lines: [LocalizedStringResource]) -> some View {
        VStack(alignment: .leading, spacing: PatikaSurfaceMetrics.labelSpacing) {
            Text(title)
                .font(Theme.TypeFace.sectionTitle)
                .foregroundStyle(Theme.textPrimary.color)
                .accessibilityAddTraits(.isHeader)
            ProfileCard {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(Theme.TypeFace.rowValue)
                            .foregroundStyle(Theme.textSecondary.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
