import SwiftUI

/// İri başlık. Semantik büyük başlık stili ölçekli punto ile kullanılır —
/// `@ScaledMetric` AX5'te de büyür (Ton eki §7: Dynamic Type zorunlu).
struct DisplayText: View {
    let text: LocalizedStringResource
    var size: CGFloat

    @ScaledMetric(relativeTo: .largeTitle) private var scaledSize: CGFloat = 38
    @Environment(\.patikaInk) private var ink

    init(_ text: LocalizedStringResource, size: CGFloat = 38) {
        self.text = text
        self.size = size
        self._scaledSize = ScaledMetric(wrappedValue: size, relativeTo: .largeTitle)
    }

    var body: some View {
        Text(text)
            .font(.system(size: scaledSize, weight: Theme.Weight.display, design: .rounded))
            .foregroundStyle(ink.primary)
            // Ağırlık bir kademe arttığında harfler birbirine yaklaşır; kerning
            // eskisi kadar sıkı kalırsa iri puntoda harfler yapışıyor.
            .kerning(-0.3)
            .lineSpacing(-2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Başlık altı açıklama metni.
struct BodyText: View {
    let text: LocalizedStringResource
    @Environment(\.patikaInk) private var ink

    init(_ text: LocalizedStringResource) { self.text = text }

    var body: some View {
        Text(text)
            .font(Theme.TypeFace.product(.body, Theme.Weight.body))
            .foregroundStyle(ink.secondary)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }
}
