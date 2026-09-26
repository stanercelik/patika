import Foundation

struct NormalizedSignaturePoint: Codable, Equatable, Sendable {
    let x: Double
    let y: Double

    init(x: Double, y: Double) {
        self.x = min(max(x, 0), 1)
        self.y = min(max(y, 0), 1)
    }
}

struct NormalizedSignature: Codable, Equatable, Sendable {
    var strokes: [[NormalizedSignaturePoint]]
    var isEmpty: Bool { strokes.allSatisfy(\.isEmpty) }
}

final class PromiseSignatureStore: @unchecked Sendable {
    private let fileURL: URL?

    init(fileURL: URL?) { self.fileURL = fileURL }

    static func live() -> PromiseSignatureStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return PromiseSignatureStore(fileURL: base?.appendingPathComponent("Profile/promise-signature.json"))
    }

    static func ephemeral() -> PromiseSignatureStore { PromiseSignatureStore(fileURL: nil) }

    @discardableResult
    func save(_ signature: NormalizedSignature) -> Bool {
        guard let fileURL else { return true }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(signature)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
            return true
        } catch { return false }
    }

    func load() -> NormalizedSignature? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(NormalizedSignature.self, from: data)
    }

    func clear() {
        guard let fileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }
}
