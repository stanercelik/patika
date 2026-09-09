import SwiftUI

/// İri başlık. Punto `@ScaledMetric` ile ölçeklenir — sabit punto yok, AX5'te de
/// büyür (Ton eki §7: Dynamic Type zorunlu).
struct DisplayText: View {
    let text: LocalizedStringResource
    var size: CGFloat = 38

    @ScaledMetric(relativeTo: .largeTitle) private var scaledSize: CGFloat = 38

    init(_ text: LocalizedStringResource, size: CGFloat = 38) {
        self.text = text
        self.size = size
        self._scaledSize = ScaledMetric(wrappedValue: size, relativeTo: .largeTitle)
    }

    var body: some View {
        Text(text)
            .font(.system(size: scaledSize, weight: Theme.Weight.display))
            .foregroundStyle(Theme.textPrimary.color)
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

    init(_ text: LocalizedStringResource) { self.text = text }

    var body: some View {
        Text(text)
            .font(.body.weight(Theme.Weight.body))
            .foregroundStyle(Theme.textSecondary.color)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }
}
