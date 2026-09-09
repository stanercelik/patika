import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

let otherApps = ExpectationCurveModel.otherApps
let patika = ExpectationCurveModel.patika

require(otherApps.first?.day == 0, "Diğer uygulamalar çizgisi başlangıç gününden başlamalı.")
require(otherApps.last?.day == 21, "Diğer uygulamalar çizgisi 21. günde bitmeli.")
require(
    (otherApps.last?.level ?? 1) < (otherApps.first?.level ?? 0),
    "Diğer uygulamalar çizgisi başlangıç seviyesinden aşağıda bitmeli."
)

let otherDeltas = zip(otherApps, otherApps.dropFirst()).map { $1.level - $0.level }
require(otherDeltas.contains(where: { $0 > 0 }), "Diğer uygulamalar çizgisi en az bir kez yükselmeli.")
require(otherDeltas.contains(where: { $0 < 0 }), "Diğer uygulamalar çizgisi en az bir kez düşmeli.")

require(ExpectationCurveModel.turningDay == 8, "Patika ivmesi 8. günde başlamalı.")
guard
    let patikaStart = patika.first,
    let turningPoint = patika.first(where: { $0.day == ExpectationCurveModel.turningDay }),
    let patikaEnd = patika.last
else {
    fatalError("Patika çizgisinin başlangıç, dönüş ve bitiş noktaları bulunmalı.")
}

let earlyGain = turningPoint.level - patikaStart.level
let laterGain = patikaEnd.level - turningPoint.level
require(earlyGain > 0 && earlyGain <= 0.12, "Patika ilk 8 günde sakin ilerlemeli.")
require(laterGain > earlyGain * 4, "Patika 8. günden sonra belirgin biçimde hızlanmalı.")

for series in [otherApps, patika] {
    require(series.allSatisfy { (0...21).contains($0.day) }, "Günler 0...21 aralığında olmalı.")
    require(series.allSatisfy { (0...1).contains($0.level) }, "Seviyeler 0...1 aralığında olmalı.")
    require(
        zip(series, series.dropFirst()).allSatisfy { $0.day < $1.day },
        "Noktalar gün sırasına göre artmalı."
    )
}

print("ExpectationCurveModelTests passed")
