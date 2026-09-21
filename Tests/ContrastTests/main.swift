import Foundation

// Onboarding kontrast denetimi (docs/onboarding-redesign.md, Bölüm 2 ve Doğrulama 8).
//   bash scripts/run-swift-tests.sh Contrast
//
// Renkler kaynak dosyalardan **okunur**, testte tekrar yazılmaz: bir renk değişince
// bu test sessizce eskimez. Bu, `Theme.minimumContrast` sabitlerinin ilk gerçek
// okuyucusu; CLAUDE.md'nin vaat ettiği "palet x ekran" kontrast testinin değer
// seviyesindeki karşılığı.
//
// Kâğıt ekranlar için argüman: koyu mürekkep krem kâğıdın üstünde palete bağlı değil,
// sabit bir orandır. Bu yüzden kâğıt ekranlarda palet x ekran kombinasyonu yok;
// yalnızca zemin katmanında kalan A2, B6 ve D ekranları palete bağlı.

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
let textPrimary = hex("textPrimary", in: "MyApp/DesignSystem/Theme.swift")

let aa = 4.5           // Theme.minimumContrast
let aaLarge = 3.0      // Theme.minimumContrastLargeText

// MARK: Kâğıt: sabit oranlar

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

// MARK: Zemin: her palet ve her harman

// `Palette.all` ruh hâli paletlerini de (`mood-...`) taşır; harmanlanan yalnızca kategori paletleri.
let palettes = Palette.all.values.filter { !$0.key.hasPrefix("mood-") }.sorted { $0.key < $1.key }
let moodPalettes = Palette.all.values.filter { $0.key.hasPrefix("mood-") }.sorted { $0.key < $1.key }
check(palettes.count == 10, "10 kategori paleti bekleniyordu, \(palettes.count) bulundu")

var candidates: [Palette] = palettes + moodPalettes
for a in palettes { for b in palettes where a.key < b.key { candidates.append(Palette.blend(a, b)) } }
check(candidates.count == 10 + 45 + moodPalettes.count, "10 + 45 harman + ruh hâli paleti bekleniyordu, \(candidates.count) bulundu")

var worstBackground = (ratio: Double.infinity, key: "")
var worstSpot = (ratio: Double.infinity, key: "")
for palette in candidates {
    let onBackground = textPrimary.contrastRatio(against: palette.background)
    if onBackground < worstBackground.ratio { worstBackground = (onBackground, palette.key) }
    // Açık mürekkep zeminde yalnızca A2, B6 ve D ekranlarında kalıyor.
    check(onBackground >= aa, "\(palette.key): metin/arka plan \(onBackground) < \(aa)")
    for spot in palette.spots {
        let ratio = textPrimary.contrastRatio(against: spot)
        if ratio < worstSpot.ratio { worstSpot = (ratio, palette.key) }
    }
}
// Ham renk noktaları **denetlenmez, yalnızca raporlanır**: metin bandını okunur tutan şey
// Metal scrim'i (`grainAndScrim`), ham nokta değil; ham noktaya eşik koymak gerçek
// görüntüyü ölçmezdi. Görüntü tabanlı ölçüm (ImageRenderer, birkaç zaman noktası, çünkü
// arka plan hareket ediyor) hâlâ yazılmadı ve zemin katmanındaki A2, B6, D ekranlarının
// asıl açığı bu.
_ = aaLarge

if !failures.isEmpty {
    failures.forEach { print($0) }
    fatalError("\(failures.count) kontrast kuralı ihlal edildi")
}
print(String(format: "ContrastTests passed: mürekkep/kâğıt %.1f:1, ikincil %.1f:1, en zayıf zemin %.1f:1 (%@), en zayıf renk noktası %.1f:1 (%@), %d palet",
             inkOnPaper, secondaryOnPaper, worstBackground.ratio, worstBackground.key, worstSpot.ratio, worstSpot.key, candidates.count))
