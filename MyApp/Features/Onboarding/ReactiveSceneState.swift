import Foundation

enum TimeScenePhase: String, Codable, Sendable {
    case morning, daytime, evening, night, neutral
}

enum ReactiveSceneState {
    static func time(for timing: ProblemTiming) -> TimeScenePhase {
        switch timing {
        case .morning: return .morning
        case .daytime: return .daytime
        case .evening: return .evening
        case .bedtime: return .night
        case .noPattern: return .neutral
        }
    }
}
