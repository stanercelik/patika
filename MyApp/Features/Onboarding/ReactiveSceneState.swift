import Foundation

enum TimeScenePhase: String, Codable, Sendable {
    case morning, daytime, evening, night, neutral
}

enum MoodScenePhase: String, Codable, Sendable {
    case veiled, quiet, balanced, opening, clear
}

enum ReactiveSceneState {
    static func time(hour: Int) -> TimeScenePhase {
        switch hour {
        case 5..<11: .morning
        case 11..<17: .daytime
        case 17..<21: .evening
        default: .night
        }
    }

    static func time(for timing: ProblemTiming) -> TimeScenePhase {
        switch timing {
        case .morning: return .morning
        case .daytime: return .daytime
        case .evening: return .evening
        case .bedtime: return .night
        case .noPattern: return .neutral
        }
    }

    static func mood(for level: MoodLevel) -> MoodScenePhase {
        switch level {
        case .veryHeavy: return .veiled
        case .heavy: return .quiet
        case .middling: return .balanced
        case .okay: return .opening
        case .calm: return .clear
        }
    }
}
