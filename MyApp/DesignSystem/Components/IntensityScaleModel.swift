import Foundation

enum IntensityScaleModel {
    nonisolated static func step(at x: CGFloat, width: CGFloat) -> Int {
        guard width > 0 else { return 0 }
        let ratio = min(max(x / width, 0), 1)
        return Int((ratio * 10).rounded())
    }
}
