#if DEBUG
import Foundation
import SwiftUI

/// Opt-in, memory-only UI fixture. Never substitutes a failed live request.
enum PathPreviewFixture {
    static var showsEmpty: Bool { ProcessInfo.processInfo.arguments.contains("-patika-debug-path-empty") }

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-patika-debug-path-preview")
    }

    static var startsCollapsed: Bool {
        ProcessInfo.processInfo.arguments.contains("-patika-debug-path-collapsed")
    }

    static var scrollDay: Int? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-patika-debug-path-day"),
              arguments.indices.contains(index + 1) else { return nil }
        return Int(arguments[index + 1])
    }

    static let path: ActivePath = {
        let arguments = ProcessInfo.processInfo.arguments
        func integer(after flag: String, fallback: Int) -> Int {
            guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return fallback }
            return Int(arguments[index + 1]) ?? fallback
        }
        let requestedLength = integer(after: "-patika-debug-path-length", fallback: 7)
        let length = [7, 14, 21, 28].contains(requestedLength) ? requestedLength : 7
        let completed = min(length, max(0, integer(after: "-patika-debug-path-completed", fallback: 2)))
        let titles = [
            "Nefesle yere inmek",
            "Zihnin sesini fark etmek",
            "Putting a small distance between you and the thought",
            "Slowly making room for what is in your body",
            "A small space in the day where you can return to yourself",
            "Kendi ritmini bulmak",
            "Looking again at where you started"
        ]
        let steps = (0..<length).map { index in
            PathStepRecord(
                id: UUID(), day: index + 1, title: titles[index % titles.count],
                blockIds: [], slotCopy: [:], audioStatus: .ready,
                question: nil, completedAt: index < completed ? Date(timeIntervalSince1970: 1) : nil
            )
        }
        return ActivePath(id: UUID(), kind: .personalized, title: "A path back to yourself", steps: steps)
    }()
}

struct PathPreviewEnvironment: ViewModifier {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let arguments = ProcessInfo.processInfo.arguments
        content
            .environment(\.accessibilityReduceMotion, reduceMotion || arguments.contains("-patika-debug-reduce-motion"))
            .environment(\.accessibilityReduceTransparency, reduceTransparency || arguments.contains("-patika-debug-reduce-transparency"))
            .environment(\.dynamicTypeSize, (arguments.contains("-patika-debug-ax5") || (PathPreviewFixture.isEnabled && arguments.contains("-patika-debug-path-ax5"))) ? .accessibility5 : typeSize)
    }
}
#endif
