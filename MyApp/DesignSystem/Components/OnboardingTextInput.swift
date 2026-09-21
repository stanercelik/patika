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
    /// Kullanıcının kendi sözü serif ile yazılır (`Theme.Voice.user`); nil ise ürünün sesi.
    var font: Font?

    @FocusState private var isFocused: Bool
    @Environment(\.patikaInk) private var ink

    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(placeholder)
                .foregroundStyle(ink.secondary),
            axis: .vertical
        )
        .font(font ?? .body.weight(Theme.Weight.body))
        .foregroundStyle(ink.primary)
        .tint(ink.primary)
        .lineSpacing(3)
        .lineLimit(lineRange)
        .textInputAutocapitalization(capitalization)
        // Otomatik düzeltme kapalı. Kullanıcının **kendi kelimeleri** ürünün
        // kendisi: bu metin F2'de geri yansıtılıyor ve G1'de seslendiriliyor.
        // Türkçe otomatik düzeltmenin cümleyi yeniden yazması, sonra kullanıcıya
        // yazmadığı bir cümleyi okutmak demek.
        .autocorrectionDisabled()
        .focused($isFocused)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            if ink == .ink {
                PaperInsetSurface(isEmphasized: isFocused)
            } else {
                CalmSurface(isEmphasized: isFocused)
            }
        }
        .accessibilityLabel(Text(placeholder))
        .animation(Theme.Motion.crossFade, value: isFocused)
    }
}
