#if DEBUG
import SwiftUI

/// Tüm onboarding adımları tek tuvalde (docs/onboarding-redesign.md, Bölüm 2.3).
///
/// Sapmanın en ucuz göstergesi: yeni bir ekran ya da yeniden tasarlanan bir ekran ortak
/// yerleşimi kullanmıyorsa, kâğıt/zemin/sahne dilini kaçırıyorsa burada yan yana durunca
/// görünür; bir lint kuralı bunu yakalayamaz. Adım listesi elle yazılı: yeni bir `case`
/// eklendiğinde `OnboardingStepContentView`nin `switch`i derlemeyi zaten kırar, buraya
/// eklemek ise bilinçli bir adım.
///
/// Xcode'da önizleme tuvalinde açılır; her ekran gerçek `OnboardingPreviewHost`la (kabuk,
/// sahne, üst çubuk) çizilir. Görsel yokluğunu da görmek için `-patika-debug-no-art`.
private let galleryDraft: OnboardingDraft = {
    var draft = OnboardingDraft.debugSample()
    draft.categories = [.sleep]
    return draft
}()

private let galleryEntries: [(String, OnboardingStep)] = [
    ("A1", .a1Welcome), ("İsim", .identityName), ("Cinsiyet", .identityGender), ("Yaş", .identityAge),
    ("A2", .a2Categories),
    ("B1", .b1ProblemText), ("B2", .b2Duration), ("B3", .b3Timing), ("B4", .b4Avoidance),
    ("B5", .b5PreviousAttempts), ("B6", .b6CurrentMood),
    ("C1", .c1Mirroring), ("C2", .c2NotAlone), ("C3", .c3PathNotLibrary), ("C4", .c4HonestExpectation),
    ("D0", .d0MeasurementIntro), ("D1", .dMeasurement(1)), ("D5", .dMeasurement(5)),
    ("E1", .e1Reminder), ("H2", .h2Priming),
    ("F1", .f1Generation), ("F2", .f2Roadmap), ("Taahhüt", .commitment),
    ("G1", .g1FirstSession), ("G2", .g2SessionComplete),
    ("Fiyat", .price), ("H1", .h1Account),
]

#Preview("Onboarding galerisi", traits: .fixedLayout(width: 6000, height: 900)) {
    ScrollView(.horizontal) {
        HStack(alignment: .top, spacing: 24) {
            ForEach(galleryEntries, id: \.0) { entry in
                VStack(spacing: 6) {
                    Text(verbatim: entry.0).font(.caption.bold()).foregroundStyle(.white)
                    OnboardingPreviewHost(step: entry.1, draft: galleryDraft) { flow in
                        OnboardingStepContentView(flow: flow)
                    }
                    .frame(width: 390, height: 780)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                }
            }
        }
        .padding(24)
    }
    .background(Color.black)
}
#endif
