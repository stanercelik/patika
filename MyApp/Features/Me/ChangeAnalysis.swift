import Foundation

/// "Ne değişti" kartının hazır hâli. Görünüm yalnızca bunu çizer.
struct ChangeSummary: Equatable {
    struct Row: Identifiable, Equatable {
        let layer: MeasurementLayer
        /// nil: henüz karşılaştırma yok.
        let direction: MeasurementComparison.Direction?
        /// −1…1, iyi yön pozitif. nil: nokta çizilmez.
        let offset: Double?

        var id: MeasurementLayer { layer }
    }

    let headline: String
    let isPending: Bool
    let rows: [Row]
    let legend: String
    let isProvisional: Bool
    let latestMeasurementID: UUID?

    /// Üç katmanın üçü de kötü yöndeyse Destek al kartı değişim kartının hemen
    /// altına taşınır — kriz sinyali değil, ama yalnız bırakılmamalı.
    var allWorsened: Bool {
        !isPending && !rows.isEmpty && rows.allSatisfy { $0.direction == .worsened }
    }
}

/// Ölçüm kayıtlarından "Ne değişti"yi kurar. Model yok, tamamen deterministik:
/// yön `MeasurementScoring`in eşiğinden, cümle sabit şablondan gelir.
enum ChangeAnalysis {
    /// Nokta bu kadar puanlık değişimde izin ucuna ulaşır. Bir görsel sınır,
    /// yorum değil. 25 denendi: dört kovalı maddelerde tek kova değişimi bile
    /// ucu buluyordu ve bütün noktalar kenarda toplanıyordu.
    static let fullScalePoints: Double = 40

    struct Point: Identifiable, Equatable {
        let id: UUID
        let label: String
        /// Başlangıca göre iyi yönde puan farkı. Başlangıç noktası 0.
        let improvement: Double
        let direction: MeasurementComparison.Direction
        let isBaseline: Bool
    }

    struct ItemChange: Identifiable, Equatable {
        let id: String
        let prompt: String
        let direction: MeasurementComparison.Direction
        let magnitude: Double
    }

    static func summary(
        measurements: [MeasurementRecord],
        category: ProblemCategory,
        pathStepCount: Int?,
        isFinished: Bool
    ) -> ChangeSummary? {
        let sorted = measurements.sorted { $0.takenAt < $1.takenAt }
        guard let baselineRecord = sorted.first(where: { $0.point == .baseline }) else { return nil }
        let baselineItems = MeasurementLibrary.items(for: .baseline, category: category)
        guard MeasurementScoring.score(
            responses: baselineRecord.responses,
            items: baselineItems
        ) != nil else { return nil }

        guard let latestRecord = sorted.last(where: { $0.point != .baseline }),
              let pair = comparableScores(baselineRecord, latestRecord, category: category)
        else {
            return ChangeSummary(
                headline: String(localized: Copy.Me.changePending(
                    stepDay: firstComparisonDay(stepCount: pathStepCount)
                )),
                isPending: true,
                rows: MeasurementLayer.allCases.map { .init(layer: $0, direction: nil, offset: nil) },
                legend: String(localized: Copy.Me.baselineLegendPending(
                    date: MeFormat.dayMonth(baselineRecord.takenAt)
                )),
                isProvisional: true,
                latestMeasurementID: nil
            )
        }

        let (baseline, latest, commonItems) = pair
        let isProvisional = MeasurementScoring.baseline(from: [baseline])?.isProvisional ?? true
        let comparison = MeasurementScoring.compare(
            baseline: baseline,
            latest: latest,
            items: commonItems,
            baselineIsProvisional: isProvisional
        )

        let rows = MeasurementLayer.allCases.compactMap { layer -> ChangeSummary.Row? in
            guard let before = baseline.value(for: layer),
                  let after = latest.value(for: layer)
            else { return nil }
            let direction = comparison.direction(for: layer)
            // Eşik altındaki değişim kaydırılmaz: gürültüyü hareket gibi
            // göstermek sahte ilerleme üretir.
            let offset = direction == .unchanged ? 0 : clamped((before - after) / fullScalePoints)
            return .init(layer: layer, direction: direction, offset: offset)
        }

        var directions: [MeasurementLayer: MeasurementComparison.Direction] = [:]
        for row in rows {
            if let direction = row.direction { directions[row.layer] = direction }
        }

        return ChangeSummary(
            headline: ChangeSentence.make(directions, finished: isFinished),
            isPending: false,
            rows: rows,
            legend: String(localized: Copy.Me.baselineLegendCompared(point: pointLabel(latestRecord))),
            isProvisional: comparison.baselineIsProvisional,
            latestMeasurementID: latestRecord.id
        )
    }

    /// Bir katmanın bütün ölçüm noktaları — başlangıç 0'da.
    static func series(
        for layer: MeasurementLayer,
        measurements: [MeasurementRecord],
        category: ProblemCategory
    ) -> [Point] {
        let sorted = measurements.sorted { $0.takenAt < $1.takenAt }
        guard let baselineRecord = sorted.first(where: { $0.point == .baseline }) else { return [] }

        return sorted.compactMap { record in
            if record.id == baselineRecord.id {
                return Point(id: record.id, label: pointLabel(record), improvement: 0, direction: .unchanged, isBaseline: true)
            }
            guard let (before, after, items) = comparableScores(baselineRecord, record, category: category),
                  let beforeValue = before.value(for: layer),
                  let afterValue = after.value(for: layer)
            else { return nil }
            let improvement = beforeValue - afterValue
            return Point(
                id: record.id,
                label: pointLabel(record),
                improvement: improvement,
                direction: direction(improvement, threshold: MeasurementScoring.resolution(of: layer, items: items)),
                isBaseline: false
            )
        }
    }

    /// Katman içinde en çok ve en az değişen madde — PRD §7.9 raporunun sayısız,
    /// madde düzeyindeki karşılığı. İfade son ölçümde kullanılan varyanttan gelir.
    static func itemChanges(
        for layer: MeasurementLayer,
        measurements: [MeasurementRecord],
        category: ProblemCategory
    ) -> (most: ItemChange?, least: ItemChange?) {
        let sorted = measurements.sorted { $0.takenAt < $1.takenAt }
        guard let baselineRecord = sorted.first(where: { $0.point == .baseline }),
              let latestRecord = sorted.last(where: { $0.point != .baseline })
        else { return (nil, nil) }

        let items = MeasurementLibrary.items(for: latestRecord.point, category: category)
            .filter { $0.layer == layer }
        let changes = items.compactMap { item -> ItemChange? in
            guard let before = baselineRecord.responses[item.id],
                  let after = latestRecord.responses[item.id]
            else { return nil }
            let improvement = MeasurementScoring.normalized(before, for: item)
                - MeasurementScoring.normalized(after, for: item)
            return ItemChange(
                id: item.id,
                prompt: String(localized: item.prompt(for: latestRecord.point.variant)),
                direction: direction(
                    improvement,
                    threshold: MeasurementScoring.resolution(of: layer, items: [item])
                ),
                magnitude: abs(improvement)
            )
        }

        guard let most = changes.max(by: { $0.magnitude < $1.magnitude }) else { return (nil, nil) }
        let least = changes.min(by: { $0.magnitude < $1.magnitude })
        return (most, least == most ? nil : least)
    }

    /// Yol sonu kovası (PRD §7.9): baseline ile son ölçüm karşılaştırması.
    /// Deterministik — kovayı model belirlemez ("Kova C'de satış yok" taahhüdü).
    /// Son ölçüm yoksa nil: kova uydurulmaz.
    static func bucket(measurements: [MeasurementRecord], category: ProblemCategory) -> OutcomeBucket? {
        let sorted = measurements.sorted { $0.takenAt < $1.takenAt }
        guard let baselineRecord = sorted.first(where: { $0.point == .baseline }),
              let finalRecord = sorted.last(where: { $0.point == .final }),
              let (before, after, items) = comparableScores(baselineRecord, finalRecord, category: category)
        else { return nil }
        let comparison = MeasurementScoring.compare(
            baseline: before,
            latest: after,
            items: items,
            baselineIsProvisional: MeasurementScoring.baseline(from: [before])?.isProvisional ?? true
        )
        return MeasurementScoring.bucket(for: comparison)
    }

    // MARK: - Yardımcılar

    static func pointLabel(_ record: MeasurementRecord) -> String {
        switch record.point {
        case .baseline: String(localized: Copy.Me.pointBaseline)
        case .final: String(localized: Copy.Me.pointFinal)
        case .day7, .day14: String(localized: Copy.Me.pointStep(day: record.stepDay))
        }
    }

    /// İki ölçümü **yalnızca ikisinde de cevaplanmış maddeler** üzerinden
    /// skorlar. 14. gün kısa form (6 madde): baseline'ın 8 maddesiyle 6 maddelik
    /// bir skoru karşılaştırmak, hiçbir cevap değişmemişken katmanı hareket
    /// etmiş gösteriyordu (duygu katmanı sıklık maddesini kaybediyor).
    private static func comparableScores(
        _ baseline: MeasurementRecord,
        _ later: MeasurementRecord,
        category: ProblemCategory
    ) -> (MeasurementScore, MeasurementScore, [MeasurementItem])? {
        let common = MeasurementLibrary.items(for: later.point, category: category).filter {
            baseline.responses[$0.id] != nil && later.responses[$0.id] != nil
        }
        guard let before = MeasurementScoring.score(responses: baseline.responses, items: common),
              let after = MeasurementScoring.score(responses: later.responses, items: common)
        else { return nil }
        return (before, after, common)
    }

    private static func direction(
        _ improvement: Double,
        threshold: Double
    ) -> MeasurementComparison.Direction {
        guard abs(improvement) + 0.0001 >= threshold else { return .unchanged }
        return improvement > 0 ? .improved : .worsened
    }

    /// Baseline onboarding'de yapıldığı için 1. gün sayılmaz.
    private static func firstComparisonDay(stepCount: Int?) -> Int {
        let length = stepCount.flatMap(PathLength.init(rawValue:)) ?? .threeWeeks
        return length.measurementDays.first { $0 > 1 } ?? 7
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, -1), 1)
    }
}

/// Değişim cümlesi — deterministik şablon (profile-design §12.2).
enum ChangeSentence {
    /// Davranış en ağır ve en sağlam katman (%40); eşitlikte önce o gelir.
    private static let priority: [MeasurementLayer] = [.behavior, .emotion, .selfEfficacy]

    static func make(
        _ directions: [MeasurementLayer: MeasurementComparison.Direction],
        finished: Bool
    ) -> String {
        let layers = priority.filter { directions[$0] != nil }
        guard !layers.isEmpty else { return "" }

        let values = Set(layers.compactMap { directions[$0] })
        if layers.count == MeasurementLayer.allCases.count, values.count == 1, let only = values.first {
            return String(localized: Copy.Me.uniformChange(only, finished: finished))
        }

        // Kötüleşen katman cümleye **mutlaka** girer: yalnızca iyileşmeyi
        // söylemek ölçümü reklama çevirir.
        var chosen = layers.filter { directions[$0] == .worsened }
        for layer in layers.filter({ directions[$0] == .improved })
            + layers.filter({ directions[$0] == .unchanged })
            where chosen.count < 2 {
            chosen.append(layer)
        }

        return priority
            .filter { chosen.contains($0) }
            .compactMap { layer in
                directions[layer].map {
                    String(localized: Copy.Me.fragment(layer, $0, finished: finished))
                }
            }
            .joined(separator: " ")
    }
}

/// "Ben" sekmesinin tarih biçimi. Arayüz metinleri sabit Türkçe olduğu için tarih
/// de Türkçe biçimlenir; cihaz İngilizceyken "8 September" ile "adımdan sonra"
/// yan yana düşmesin.
enum MeFormat {
    static let locale = Locale(identifier: "tr_TR")

    static func dayMonth(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).locale(locale))
    }

    static func monthYear(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year().locale(locale))
    }

    static func relativeDay(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return String(localized: Copy.Me.today) }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return String(localized: Copy.Me.yesterday)
        }
        return dayMonth(date)
    }
}
