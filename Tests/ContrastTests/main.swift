import Foundation

// Kontrast denetimi (docs/onboarding-redesign.md, Faz 1 ve Doğrulama).
//   bash scripts/run-swift-tests.sh Contrast
//
// Renkler kaynak dosyalardan **okunur**, testte tekrar yazılmaz: bir renk değişince
// bu test sessizce eskimez.
//
// **2026-09-22'de yeniden yazıldı.** Gradyan ve 10 kategori paleti kalktı; eski test
// `Palette.all` üzerinden 55 kombinasyonu tarıyordu, artık derlenmiyor. Yeni dünyada
// zemin metni her zaman `Theme.textPrimary` ve arka plan ya gerçek bir tam ekran guaj
// sahnesi (görsel + düz karartma) ya da görsel yokken düz `WoodlandStyle.background`.
//
// **Sınır, dürüstçe:** bu ikili yalnızca `swiftc` ile derlenip komut satırında çalışıyor
// (Xcode test hedefi yok), gerçek bir görüntüleme bağlamı yok. Guaj sahnenin gerçek
// piksellerinin en kötü luminansını burada ölçemeyiz — bu, `ImageRenderer` tabanlı bir
// XCTest hedefi gerektirir ve CLAUDE.md'nin baştan beri not ettiği açık bir eksik. Bu test
// ölçebildiğini ölçer: (1) kâğıt üstü sabit oranlar, (2) görsel yokken düz zemin üstü metin
// — her ekranın **en az** düştüğü hâl budur ve gerçek denetim varlık başına elle yapılmalı.
setbuf(stdout, nil)
var failures: [String] = []
func check(_ condition: Bool, _ message: String) { if !condition { failures.append(message) } }

func hex(_ name: String, in file: String) -> RGB {
    let text = try! String(contentsOfFile: file, encoding: .utf8)
    let pattern = "static let \(name) = RGB\\(hex: 0x([0-9A-Fa-f]{6})\\)"
    let regex = try! NSRegularExpression(pattern: pattern)
    guard let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
          let range = Range(match.range(at: 1), in: text),
          let value = UInt32(text[range], radix: 16)
    else { fatalError("\(name) \(file) içinde bulunamadı") }
    return RGB(hex: value)
}

let woodland = "MyApp/DesignSystem/WoodlandStyle.swift"
let paper = hex("paper", in: woodland)
let ink = hex("ink", in: woodland)
let secondaryInk = hex("secondaryInk", in: woodland)
let background = hex("background", in: woodland)
let scenePlate = hex("scenePlate", in: woodland)
let scenePlateSecondary = hex("scenePlateSecondary", in: woodland)
let scenePlateBorder = hex("scenePlateBorder", in: woodland)
let textPrimary = hex("textPrimary", in: "MyApp/DesignSystem/Theme.swift")

let aa = 4.5           // Theme.minimumContrast
let aaLarge = 3.0      // Theme.minimumContrastLargeText

// MARK: Kâğıt: sabit oranlar (palete hiç bağlı değil)

let inkOnPaper = ink.contrastRatio(against: paper)
let secondaryOnPaper = secondaryInk.contrastRatio(against: paper)
check(inkOnPaper >= 7.0, "mürekkep/kâğıt \(inkOnPaper) (AAA 7.0 bekleniyor)")
check(secondaryOnPaper >= aa, "ikincil mürekkep/kâğıt \(secondaryOnPaper) < \(aa)")

// Kâğıdın içindeki seçili satır kâğıdın üstüne %10 mürekkep bindirir; metin orada da okunmalı.
func over(_ base: RGB, _ top: RGB, _ alpha: Double) -> RGB {
    RGB(r: base.r * (1 - alpha) + top.r * alpha, g: base.g * (1 - alpha) + top.g * alpha, b: base.b * (1 - alpha) + top.b * alpha)
}
let selectedRow = over(paper, ink, 0.10)
check(ink.contrastRatio(against: selectedRow) >= aa, "mürekkep/seçili satır \(ink.contrastRatio(against: selectedRow))")
check(secondaryInk.contrastRatio(against: selectedRow) >= aa, "ikincil/seçili satır \(secondaryInk.contrastRatio(against: selectedRow))")

// MARK: Sahne yokken (ya da Reduce Transparency/AX'te): düz WoodlandStyle.background

// `OnboardingSceneLayer` görsel yoksa/kapalıysa doğrudan bu renk üstünde açık metin çizer —
// her sahne ekranının en kötü (en az kontrastlı) hâli budur.
let textOnFlatBackground = textPrimary.contrastRatio(against: background)
check(textOnFlatBackground >= aa, "açık metin/düz zemin \(textOnFlatBackground) < \(aa)")

let primaryOnScenePlate = textPrimary.contrastRatio(against: scenePlate)
let secondaryOnScenePlate = scenePlateSecondary.contrastRatio(against: scenePlate)
let borderOnScenePlate = scenePlateBorder.contrastRatio(against: scenePlate)
check(primaryOnScenePlate >= aa, "primary/scene plate \(primaryOnScenePlate) < \(aa)")
check(secondaryOnScenePlate >= aa, "secondary/scene plate \(secondaryOnScenePlate) < \(aa)")
check(borderOnScenePlate >= aaLarge, "border/scene plate \(borderOnScenePlate) < \(aaLarge)")

// MARK: Sahne + gerçek görsel: ölçülmüyor, bilerek

// `OnboardingSceneLayer`'ın perdesi (`WoodlandStyle.background.opacity(dimming)`) sahnenin
// üstüne biniyor ve dimming B6'da 0,26–0,50 arasında değişiyor (`MoodLevel.sceneDimming`).
// Bunun gerçek bir guaj görselinin üstünde ne kadar kontrast bıraktığını buradan ölçmek
// imkânsız: perde rengi zeminle aynı olduğu için (bindirme aynı renkle aynı rengi verir)
// sentetik bir "en kötü durum" hesaplamak yanıltıcı olur — ölçmediğimiz bir şeyi ölçmüş gibi
// göstermek bu kuralın kendisini ihlal eder. Görsel gelince (ve `ImageRenderer` tabanlı bir
// XCTest hedefi kurulunca) her sahne + en açık kademe kombinasyonu elle/otomatik denetlenmeli.

if !failures.isEmpty {
    failures.forEach { print($0) }
    fatalError("\(failures.count) kontrast kuralı ihlal edildi")
}
print(String(format: "ContrastTests passed: mürekkep/kâğıt %.1f:1, ikincil %.1f:1, açık metin/düz zemin %.1f:1",
             inkOnPaper, secondaryOnPaper, textOnFlatBackground))
