import Foundation
import Observation

/// Tek bir ölçüm sorusu (D1–D8).
///
/// Cevap **önceden doldurulmaz** ve varsayılanı yoktur: hazır bir cevap
/// baseline'ı kirletir ve 7. gündeki karşılaştırmayı anlamsız kılar. Varsayılan
/// yanlılığı ürünün başka yerlerinde bilinçli bir araç (E1'in hatırlatma saati),
/// ölçümde ise doğrudan veri sahtekârlığı olurdu.
///
/// Cevap seçilince ekran kendiliğinden ilerlemez — B2/B3/B6'daki karar burada da
/// geçerli: dokunmak seçimdir, "Devam" işler. Sekiz soruluk bir dizide yanlış
/// dokunuşun bedeli daha da yüksek.
@Observable
@MainActor
final class MeasurementQuestionViewModel {
    let item: MeasurementItem
    let variant: MeasurementVariant

    private(set) var value: Double?

    private let commit: (Double) -> Void

    init(
        item: MeasurementItem,
        variant: MeasurementVariant,
        value: Double?,
        commit: @escaping (Double) -> Void
    ) {
        self.item = item
        self.variant = variant
        self.value = value
        self.commit = commit
    }

    var prompt: LocalizedStringResource { item.prompt(for: variant) }
    var hint: LocalizedStringResource? { item.hint }
    var canContinue: Bool { value != nil }

    /// Kova listesi; şiddet ölçeğinde boş.
    var options: [MeasurementOption] {
        if case .choice(let options) = item.style { return options }
        return []
    }

    var usesIntensityScale: Bool {
        if case .intensity = item.style { return true }
        return false
    }

    func isSelected(_ option: MeasurementOption) -> Bool { value == option.value }

    func select(_ newValue: Double) {
        value = newValue
    }

    func submit() {
        guard let value else { return }
        commit(value)
    }
}
