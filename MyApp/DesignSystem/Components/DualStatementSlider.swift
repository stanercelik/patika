import SwiftUI

/// İki uç ifade arasında sıralı bir cevap kümesi: `ChoiceList`in kaydırıcı hâli.
///
/// **Sayı değil kova üretir.** Sunucu sözleşmesi numaralandırılmış bir küme bekliyor
/// (`ProblemDuration`, `AgeRange`); sürekli bir değer bir eşleme katmanı isterdi ve
/// yeniden tasarımın yükü bozabileceği ilk yer orası. Seçilen kova adıyla yazılır.
///
/// > **Her enum'u bu bileşene vermeden önce sıralı mı diye bak.** `TonePreference`
/// > sıralı değil (kısa/sakin, yönlendirici, yalnızca bilgi: üç ayrı tercih);
/// > kaydırıcı olmayan bir sırayı ima ederdi. `ProblemDuration.unsure` da bir süre
/// > değil: kaçış seçenekleri kaydırıcının bir durağı olmaz, altında ayrı bir satır
/// > olarak durur.
struct DualStatementSlider<Option: OnboardingChoice>: View {
    /// Sıralı, kaçış seçeneği hariç.
    let options: [Option]
    let selection: Option?
    let onSelect: (Option) -> Void
    let lowStatement: LocalizedStringResource
    let highStatement: LocalizedStringResource
    let accessibilityLabel: LocalizedStringResource
    var fillsTrack = true

    @Environment(\.patikaInk) private var ink
    @ScaledMetric(relativeTo: .title3) private var readoutHeight: CGFloat = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TickRuler(
                count: options.count,
                selection: selection.flatMap { options.firstIndex(of: $0) },
                onSelect: { onSelect(options[$0]) },
                accessibilityLabel: accessibilityLabel,
                accessibilityValue: { String(localized: options[$0].label) },
                fillsTrack: fillsTrack
            )

            HStack {
                Text(lowStatement)
                Spacer(minLength: 8)
                Text(highStatement)
            }
            .font(.caption.weight(Theme.Weight.emphasis))
            .foregroundStyle(ink.secondary)
            .accessibilityHidden(true)

            // Yer her zaman ayrılır: cevap verilince satır zıplamasın.
            Group {
                if let selection {
                    Text(selection.label)
                } else {
                    Text(verbatim: " ")
                }
            }
            .font(.title3.weight(Theme.Weight.title))
            .foregroundStyle(ink.primary)
            .frame(maxWidth: .infinity, minHeight: readoutHeight, alignment: .center)
            .accessibilityHidden(true)
        }
    }
}
