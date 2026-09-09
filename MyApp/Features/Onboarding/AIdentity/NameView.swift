import SwiftUI

/// Ad — akışın ilk sorusu (ürün sahibi kararı, 2026-09-08; PRD'de yok).
///
/// ## Neden burada
///
/// A1'in **sonrasında**: kanca ekranı markanın ilk izlenimi ve önüne form
/// koyulmaz. A2'nin **öncesinde**: ad akışın geri kalanında kullanılıyor, en geç
/// C1'de gerekiyor.
///
/// ## İsimsiz de tam bir yol
///
/// "İsim vermek istemiyorum" akışın hiçbir yerini kapatmaz: metinlerin ada göre
/// iki sürümü var ve isimsiz sürüm eksik bir sürüm değil. Bu yüzden alan
/// zorunlu değil ve boş bırakmak ayrı bir bağlantıyla açıkça söyleniyor —
/// zorunlu görünen bir alan, kaygılı kullanıcının çıktığı yerdir.
struct NameView: View {
    let flow: OnboardingFlowViewModel

    @State private var text: String

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
        self._text = State(initialValue: flow.draft.name ?? "")
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.nameHeadline,
            hint: Copy.Onboarding.nameHint
        ) {
            OnboardingTextInput(
                text: $text,
                placeholder: Copy.Onboarding.namePlaceholder,
                lineRange: 1...1,
                capitalization: .words
            )
        } footer: {
            OnboardingQuestionFooter(
                primaryTitle: Copy.Button.next,
                isPrimaryEnabled: !trimmed.isEmpty,
                primaryAction: { flow.commitName(text) },
                skipTitle: Copy.Onboarding.nameSkip,
                skipAction: { flow.skipName() }
            )
        }
    }
}

#Preview {
    OnboardingPreviewHost(step: .identityName) { flow in
        NameView(flow: flow)
    }
}
