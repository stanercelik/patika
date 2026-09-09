import Foundation

// Ölçüm skorlamasının vaka tablosu.
//
// Test hedefi henüz yok (CLAUDE.md), o yüzden `ExpectationCurveModelTests` ile
// aynı kalıp: bağımsız çalıştırılabilir bir `main.swift`.
//
//   swift MyApp/Models/DomainEnums.swift \
//         MyApp/Models/MeasurementLibrary.swift \
//         MyApp/Models/MeasurementScoring.swift \
//         Tests/MeasurementScoringTests/main.swift
//
// Test hedefi eklendiğinde bu dosya XCTest'e taşınmalı.

private var failures = 0

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if condition() { return }
    failures += 1
    FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
}

private func requireClose(_ value: Double, _ expected: Double, _ message: String, tolerance: Double = 0.001) {
    require(abs(value - expected) < tolerance, "\(message) (beklenen \(expected), gelen \(value))")
}

let items = MeasurementLibrary.items(for: .baseline, category: .sleep)
require(items.count == 8, "Baseline sekiz madde olmalı.")

// MARK: - Tek madde normalizasyonu

let intensity = items.first { $0.id == "emotion.intensity" }!
requireClose(MeasurementScoring.normalized(0, for: intensity), 0, "Şiddet 0 sıfır zorlanma.")
requireClose(MeasurementScoring.normalized(10, for: intensity), 100, "Şiddet 10 tam zorlanma.")
requireClose(MeasurementScoring.normalized(5, for: intensity), 50, "Şiddet ölçeği doğrusal.")

let knows = items.first { $0.id == "selfEfficacy.knowsWhatToDo" }!
require(knows.higherMeansBetter, "Öz-yeterlik maddesinde yüksek cevap iyidir.")
requireClose(
    MeasurementScoring.normalized(4, for: knows), 0,
    "Ters yönlü maddede en yüksek cevap sıfır zorlanma vermeli."
)
requireClose(
    MeasurementScoring.normalized(0, for: knows), 100,
    "Ters yönlü maddede en düşük cevap tam zorlanma vermeli."
)

// Cevap tavanı elle yazılmıyor, maddeden okunuyor.
requireClose(MeasurementScoring.maximumRawValue(for: intensity), 10, "Şiddet tavanı 10.")
requireClose(MeasurementScoring.maximumRawValue(for: knows), 4, "Katılım ölçeği tavanı 4.")

// MARK: - Uçlar

var worst: [String: Double] = [:]
var best: [String: Double] = [:]
for item in items {
    let maximum = MeasurementScoring.maximumRawValue(for: item)
    worst[item.id] = item.higherMeansBetter ? 0 : maximum
    best[item.id] = item.higherMeansBetter ? maximum : 0
}

let worstScore = MeasurementScoring.score(responses: worst, items: items)!
requireClose(worstScore.composite, 100, "En kötü cevaplar bileşik skoru 100 yapmalı.")
let bestScore = MeasurementScoring.score(responses: best, items: items)!
requireClose(bestScore.composite, 0, "En iyi cevaplar bileşik skoru 0 yapmalı.")

for layer in MeasurementLayer.allCases {
    requireClose(worstScore.value(for: layer) ?? -1, 100, "\(layer) en kötü uçta 100 olmalı.")
    requireClose(bestScore.value(for: layer) ?? -1, 0, "\(layer) en iyi uçta 0 olmalı.")
}

// MARK: - Cevapsız madde sıfır sayılmaz

var partial = worst
partial.removeValue(forKey: "selfEfficacy.knowsWhatToDo")
partial.removeValue(forKey: "selfEfficacy.believesChangePossible")
let partialScore = MeasurementScoring.score(responses: partial, items: items)!
requireClose(
    partialScore.composite, 100,
    "Cevapsız katman sıfır sayılmamalı; kalan ağırlıklar normalize edilmeli."
)
require(
    partialScore.value(for: .selfEfficacy) == nil,
    "Hiç cevaplanmamış katman skorda görünmemeli."
)
require(MeasurementScoring.score(responses: [:], items: items) == nil, "Boş cevap seti nil vermeli.")

// MARK: - Ağırlıklar (PRD §8.2)

// Yalnızca davranış katmanı en kötü, diğerleri en iyi: bileşik skor davranışın
// ağırlığı kadar olmalı (%40).
var behaviorOnly = best
for item in items where item.layer == .behavior {
    behaviorOnly[item.id] = item.higherMeansBetter ? 0 : MeasurementScoring.maximumRawValue(for: item)
}
requireClose(
    MeasurementScoring.score(responses: behaviorOnly, items: items)!.composite, 40,
    "Davranış katmanının ağırlığı %40 olmalı."
)

// MARK: - Cevap tavanı maddeye göre değişir
//
// Bu vaka bir hatayı yakaladı: sunucudaki `calculateScores` tavanı
// "emotion.intensity ise 10, değilse 4" diye alıyordu. Oysa davranış
// maddelerinin çoğu **dört kovalı** (0–3), beş değil. En kötü cevabı veren
// kullanıcı 100 yerine 75 puan alıyor, yani zorlanması sistematik olarak
// olduğundan düşük ölçülüyordu. Sunucu düzeltildi
// (`_shared/measurement.ts`); bu vaka iki tarafı da bağlar.

let sample: [String: Double] = [
    "emotion.intensity": 7, "emotion.frequency": 3,
    "behavior.sleepLatency": 3, "behavior.avoidanceCount": 2,
    "behavior.nightWakings": 2, "behavior.dailyImpact": 3,
    "selfEfficacy.knowsWhatToDo": 2, "selfEfficacy.believesChangePossible": 3,
]
let sampleScore = MeasurementScoring.score(responses: sample, items: items)!
// Duygu:      şiddet 7/10 → 70,  sıklık 3/4 → 75            → 72.5
// Davranış:   uyku 3/4 → 75, kaçınma 2/**3** → 66.7,
//             uyanma 2/**3** → 66.7, etki 3/4 → 75          → 70.83
// Öz-yeterlik: 2/4 ve 3/4, ters çevrilmiş → 50 ve 25        → 37.5
requireClose(sampleScore.value(for: .emotion) ?? -1, 72.5, "Duygu katmanı.")
requireClose(
    sampleScore.value(for: .behavior) ?? -1,
    (75 + (2.0 / 3 * 100) + (2.0 / 3 * 100) + 75) / 4,
    "Davranış katmanı — dört kovalı maddelerin tavanı 3, 4 değil."
)
requireClose(sampleScore.value(for: .selfEfficacy) ?? -1, 37.5, "Öz-yeterlik katmanı.")

// Tavanların madde başına doğru okunduğunu açıkça bağla.
for item in items where item.id.hasPrefix("behavior.") {
    let maximum = MeasurementScoring.maximumRawValue(for: item)
    require(
        maximum == 3 || maximum == 4,
        "Davranış maddesinin tavanı 3 ya da 4 olmalı: \(item.id) → \(maximum)"
    )
    requireClose(
        MeasurementScoring.normalized(maximum, for: item),
        item.higherMeansBetter ? 0 : 100,
        "En uç cevap uç değeri vermeli: \(item.id)"
    )
}

// MARK: - Çözünürlük (yön eşiği)

// Duygu: iki madde. Şiddet kademesi 100/10 = 10, sıklık kademesi 100/4 = 25.
// En küçüğü 10, katmana yansıması 10/2 = 5.
requireClose(
    MeasurementScoring.resolution(of: .emotion, items: items), 5,
    "Duygu katmanının çözünürlüğü 5 puan olmalı."
)
// Öz-yeterlik: iki madde, ikisi de 5 kovalı → 25/2 = 12.5.
requireClose(
    MeasurementScoring.resolution(of: .selfEfficacy, items: items), 12.5,
    "Öz-yeterlik katmanının çözünürlüğü 12.5 puan olmalı."
)

// MARK: - Baseline ortalaması (PRD §8)

let a = MeasurementScore(layers: [.emotion: 80, .behavior: 60, .selfEfficacy: 40], composite: 60)
let b = MeasurementScore(layers: [.emotion: 60, .behavior: 40, .selfEfficacy: 20], composite: 40)

let single = MeasurementScoring.baseline(from: [a])!
require(single.isProvisional, "Tek noktalı baseline geçici işaretlenmeli.")
requireClose(single.score.composite, 60, "Tek nokta olduğu gibi kullanılmalı.")

let paired = MeasurementScoring.baseline(from: [a, b])!
require(!paired.isProvisional, "İki noktalı baseline geçici olmamalı.")
requireClose(paired.score.composite, 50, "Baseline ilk iki ölçümün ortalaması olmalı.")
requireClose(paired.score.layers[.emotion] ?? -1, 70, "Katman ortalaması da alınmalı.")

let triple = MeasurementScoring.baseline(from: [a, b, MeasurementScore(layers: [:], composite: 0)])!
requireClose(triple.score.composite, 50, "Üçüncü nokta baseline'a katılmamalı.")
require(MeasurementScoring.baseline(from: []) == nil, "Ölçüm yoksa baseline yok.")

// MARK: - Karşılaştırma yönü

func comparison(baseline: MeasurementScore, latest: MeasurementScore) -> MeasurementComparison {
    MeasurementScoring.compare(
        baseline: baseline, latest: latest, items: items, baselineIsProvisional: false
    )
}

// Duygu katmanında 4 puanlık düşüş — çözünürlüğün (5) altında, "değişmedi".
let noise = comparison(
    baseline: MeasurementScore(layers: [.emotion: 80], composite: 80),
    latest: MeasurementScore(layers: [.emotion: 76], composite: 76)
)
require(noise.direction(for: .emotion) == .unchanged, "Çözünürlük altındaki düşüş değişim sayılmamalı.")

let real = comparison(
    baseline: MeasurementScore(layers: [.emotion: 80], composite: 80),
    latest: MeasurementScore(layers: [.emotion: 70], composite: 70)
)
require(real.direction(for: .emotion) == .improved, "Çözünürlük üstündeki düşüş iyileşme olmalı.")
requireClose(real.improvement(for: .emotion), 12.5, "İyileşme yüzdesi baseline'a göre hesaplanmalı.")

let worse = comparison(
    baseline: MeasurementScore(layers: [.emotion: 60], composite: 60),
    latest: MeasurementScore(layers: [.emotion: 75], composite: 75)
)
require(worse.direction(for: .emotion) == .worsened, "Yükselen skor kötüleşme olmalı.")

// MARK: - Kova ataması (PRD §7.9)

func bucket(_ before: [MeasurementLayer: Double], _ after: [MeasurementLayer: Double]) -> OutcomeBucket {
    func composite(_ layers: [MeasurementLayer: Double]) -> Double {
        layers.reduce(0) { $0 + $1.value * $1.key.weight }
    }
    return MeasurementScoring.bucket(
        for: comparison(
            baseline: MeasurementScore(layers: before, composite: composite(before)),
            latest: MeasurementScore(layers: after, composite: composite(after))
        )
    )
}

let flat: [MeasurementLayer: Double] = [.emotion: 80, .behavior: 80, .selfEfficacy: 80]

require(
    bucket(flat, [.emotion: 50, .behavior: 50, .selfEfficacy: 50]) == .clearProgress,
    "%37.5 iyileşme Kova A olmalı."
)
require(
    bucket(flat, [.emotion: 68, .behavior: 68, .selfEfficacy: 68]) == .partialProgress,
    "%15 iyileşme Kova B olmalı."
)
require(
    bucket(flat, [.emotion: 74, .behavior: 74, .selfEfficacy: 74]) == .noProgress,
    "%7.5 iyileşme — B ile C arasındaki boşluk C'ye yuvarlanmalı."
)
require(
    bucket(flat, flat) == .noProgress,
    "Değişim yoksa Kova C olmalı."
)
// Kritik kural: bir katman kötüleştiyse diğerleri ne kadar iyileşirse iyileşsin C.
require(
    bucket(flat, [.emotion: 20, .behavior: 20, .selfEfficacy: 95]) == .noProgress,
    "Bir katmanda kötüleşme varsa Kova C olmalı."
)
// Kova C'de satış yapılmaz — ticari kuralın kod tarafındaki bağı.
require(
    !OutcomeBucket.noProgress.allowsSelling,
    "Kova C'de satış yapılmamalı."
)

if failures == 0 {
    print("MeasurementScoring: tüm vakalar geçti.")
} else {
    FileHandle.standardError.write(Data("\(failures) vaka başarısız.\n".utf8))
    exit(1)
}
