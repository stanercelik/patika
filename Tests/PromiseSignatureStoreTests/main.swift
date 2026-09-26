import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError(message) }
}

let signature = NormalizedSignature(strokes: [[
    .init(x: -0.10, y: 0.20),
    .init(x: 1.20, y: 0.80),
]])
check(signature.strokes[0][0].x == 0, "lower clamp")
check(signature.strokes[0][1].x == 1, "upper clamp")
let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
let store = PromiseSignatureStore(fileURL: directory.appendingPathComponent("signature.json"))
check(store.save(signature), "save")
check(store.load() == signature, "round trip")
store.clear()
check(store.load() == nil, "clear")
print("PromiseSignatureStoreTests passed")
