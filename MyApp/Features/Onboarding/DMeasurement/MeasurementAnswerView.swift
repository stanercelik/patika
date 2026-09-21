import SwiftUI

/// Bir ölçüm sorusunun **cevap alanı** — onboarding D1–D8 ve yol içi gün 7/14/son ölçüm
/// aynı görünümü kullanır (docs/onboarding-redesign.md, Bölüm 2.5).
///
/// ## Neden tek yerde
///
/// Aracın baseline ile takip ölçümlerinde **aynı** olması bir estetik tutarlılık değil,
/// ölçümün kendisi: baseline bir denetimle, gün 7 başka bir denetimle toplanırsa
/// "iyileşme"nin bir kısmı araç farkı olur ve ürünün tek karşılaştırması kirlenir. İki ayrı
/// kopya zamanla ayrışırdı; bu görünüm ayrışmayı yapısal olarak imkânsız kılıyor.
///
/// ## Bilerek cetvel değil
///
/// D1 şiddet çubuklarıyla (`IntensityScale`), D2–D8 kova listesiyle çizilir. Kova
/// etiketleri cümle uzunluğunda ve **aracın parçası**: bir cetvel yalnızca seçili etiketi
/// gösterirdi, kullanıcı cevaplamadan önce seçenek metnini göremezdi. Bu da ölçümü değiştirir.
/// Varsayılan cevap yok, skor yok, iyi/kötü işareti yok.
struct MeasurementAnswerView: View {
    let question: MeasurementQuestionViewModel

    var body: some View {
        if question.usesIntensityScale {
            IntensityScale(selection: question.value) { question.select($0) }
                .padding(.top, 4)
        } else {
            VStack(spacing: 10) {
                ForEach(question.options) { option in
                    ChoiceRow(
                        label: option.label,
                        isSelected: question.isSelected(option)
                    ) {
                        question.select(option.value)
                    }
                }
            }
        }
    }
}
