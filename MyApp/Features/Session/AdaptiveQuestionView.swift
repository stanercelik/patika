import SwiftUI

/// Oturum sonu kişisel soru — **yalnızca kişiselleştirilmiş patikada**.
///
/// ## Neden hazır patikada yok
///
/// Hazır patika önceden hazırlanmış içerik ve önceden render edilmiş ses
/// kullanıyor; cevabın değiştirebileceği bir sonraki adım yok. Soruyu yine de
/// sormak, cevabın bir işe yaradığını ima etmek olurdu — "sorduğumuz her şeyin
/// karşılığı olmalı" kuralının tersi. Sunucu da aynı sınırı koruyor: hazır
/// patikada cevap kabul edilmiyor.
///
/// ## Soru isteğe bağlı ve "Şimdilik değil" gerçekten çalışıyor
///
/// Cevap yazılmazsa sonraki adım mevcut özetle hazır kalıyor. Zorunlu bir
/// günlük, meditasyonun sonuna ödev eklemek olurdu.
struct AdaptiveQuestionView: View {
    let question: String
    let isSubmitting: Bool
    let showsError: Bool
    var onSave: (String) -> Void
    var onSkip: () -> Void

    @State private var answer = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: question)
                .font(.title3.weight(Theme.Weight.title))
                .foregroundStyle(Theme.textPrimary.color)
            Text(Copy.Session.reflectionHint)
                .font(.footnote.weight(Theme.Weight.body))
                .foregroundStyle(Theme.textSecondary.color)
            OnboardingTextInput(
                text: $answer,
                placeholder: Copy.Session.reflectionPlaceholder,
                lineRange: 3...6
            )
            if showsError {
                Text(Copy.Session.reflectionError)
                    .font(.footnote.weight(Theme.Weight.body))
                    .foregroundStyle(Theme.textSecondary.color)
            }

            VStack(spacing: 10) {
                PrimaryButton(title: Copy.Session.reflectionSave, isEnabled: canSave && !isSubmitting) {
                    onSave(answer)
                }
                Button(Copy.Session.reflectionSkip) {
                    onSkip()
                }
                .buttonStyle(.calm)
                .foregroundStyle(Theme.textSecondary.color)
                .frame(minHeight: 44)
                .disabled(isSubmitting)
            }
            .padding(.top, 6)
        }
    }

    private var canSave: Bool {
        answer.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }
}
