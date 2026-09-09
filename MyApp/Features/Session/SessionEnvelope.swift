import Foundation

struct SessionEnvelope: Equatable, Sendable {
    private(set) var value: Double = 0

    mutating func advance(toward rawTarget: Double, delta: TimeInterval) -> Double {
        let target = min(max(rawTarget, 0), 1)
        let timeConstant = target > value ? 0.08 : 0.45
        let alpha = 1 - exp(-max(0, delta) / timeConstant)
        value += (target - value) * alpha
        if abs(value - target) < 0.000_1 { value = target }
        return value
    }

    var meshOffset: Double { min(0.03, value * 0.03) }
    var brightnessLift: Double { min(0.04, value * 0.04) }
}

