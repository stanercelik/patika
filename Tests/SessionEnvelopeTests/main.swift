import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

var envelope = SessionEnvelope()
let firstRise = envelope.advance(toward: 1, delta: 0.05)
let secondRise = envelope.advance(toward: 1, delta: 0.05)
expect(firstRise > 0 && firstRise < 1, "attack must be smooth")
expect(secondRise > firstRise, "attack must rise")
let firstFall = envelope.advance(toward: 0, delta: 0.05)
expect(firstFall < secondRise && firstFall > 0, "release must be smooth")
expect(envelope.meshOffset <= 0.03, "mesh movement cap")
expect(envelope.brightnessLift <= 0.04, "brightness cap")

for _ in 0..<100 { _ = envelope.advance(toward: 0, delta: 0.05) }
expect(envelope.value < 0.001, "envelope should settle")

print("SessionEnvelopeTests passed")

