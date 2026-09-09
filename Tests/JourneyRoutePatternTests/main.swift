import Foundation

private var failures = 0

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if condition() { return }
    failures += 1
    FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
}

let expected: [Double] = [0.18, 0.76, 0.26, 0.82, 0.22, 0.72]
let positions = expected.indices.map {
    JourneyRoutePattern.normalizedX(at: $0, usesAccessibleLayout: false)
}

for (index, position) in positions.enumerated() {
    require(
        abs(position - expected[index]) < 0.0001,
        "Durak \(index) sakin kıvrım desenindeki yerini korumalı."
    )
    require(
        (0.16...0.84).contains(position),
        "Durak \(index) güvenli yatay koridordan çıkmamalı."
    )
}

for pair in zip(positions, positions.dropFirst()) {
    require(
        (pair.0 < 0.5) != (pair.1 < 0.5),
        "Ardışık duraklar yolun karşı kıyılarında olmalı."
    )
}

for index in 0..<12 {
    require(
        JourneyRoutePattern.normalizedX(at: index, usesAccessibleLayout: true) == 0.10,
        "Erişilebilir yerleşimde rota metne yer açmak için solda kalmalı."
    )
}

require(
    JourneyStepAccess.isLocked(day: 8, isCompleted: false, nextDay: 7),
    "Sıradaki adımın ilerisindeki gün kapalı olmalı."
)
require(
    !JourneyStepAccess.isLocked(day: 7, isCompleted: false, nextDay: 7),
    "Sıradaki adım açık olmalı."
)
require(
    !JourneyStepAccess.isLocked(day: 3, isCompleted: true, nextDay: 7),
    "Tamamlanan adım yeniden açılabilmeli."
)
require(
    JourneyStepAccess.isLocked(day: 8, isCompleted: false, nextDay: nil),
    "Açılacak sıradaki adım yoksa tamamlanmamış gün kapalı kalmalı."
)
require(
    JourneyStepAccess.isLocked(day: 3, isCompleted: false, nextDay: 7),
    "Tutarsız sunucu verisinde sıradakinden önceki tamamlanmamış gün de kapalı kalmalı."
)

if failures == 0 {
    print("JourneyRoutePattern: tüm vakalar geçti.")
} else {
    FileHandle.standardError.write(Data("\(failures) vaka başarısız.\n".utf8))
    exit(1)
}
