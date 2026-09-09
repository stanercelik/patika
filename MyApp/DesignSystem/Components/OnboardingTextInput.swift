import SwiftUI

/// Serbest metin alanı (B1, B4).
///
/// Kutu bilinçli olarak sakin: kalın kenarlık, imleç yanıp sönmesi dışında hareket
/// yok, karakter sayacı yok. Sayaç yazmayı ödeve çevirir — B1 akışın en değerli
/// verisi ve kullanıcı ne kadar isterse o kadar yazmalı.
///
/// Placeholder A2'de seçilen kategoriye göre değişir (`ProblemCategory.textPlaceholder`) —
/// doldurma oranını ciddi artıran detay (PRD-Ek Onboarding §3.1).
struct OnboardingTextInput: View {
    @Binding var text: String
    let placeholder: LocalizedStringResource
    /// Görünür satır aralığı. B1 uzun anlatım, B4 tek cümle, ad alanı tek satır.
    var lineRange: ClosedRange<Int> = 4...9
    /// Ad alanında kelime başı büyük harf; cümle alanlarında cümle başı.
    var capitalization: TextInputAutocapitalization = .sentences

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(placeholder)
                .foregroundStyle(Theme.textSecondary.color.opacity(0.75)),
            axis: .vertical
        )
        .font(.body.weight(Theme.Weight.body))
        .foregroundStyle(Theme.textPrimary.color)
        .tint(Theme.textPrimary.color)
        .lineSpacing(3)
        .lineLimit(lineRange)
        .textInputAutocapitalization(capitalization)
        // Otomatik düzeltme kapalı. Kullanıcının **kendi kelimeleri** ürünün
        // kendisi: bu metin F2'de geri yansıtılıyor ve G1'de seslendiriliyor.
        // Türkçe otomatik düzeltmenin cümleyi yeniden yazması, sonra kullanıcıya
        // yazmadığı bir cümleyi okutmak demek.
        .autocorrectionDisabled()
        .focused($isFocused)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.07))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    Theme.textPrimary.color.opacity(isFocused ? 0.45 : 0.14),
                    lineWidth: Theme.Line.border
                )
        }
        .animation(Theme.Motion.crossFade, value: isFocused)
    }
}
