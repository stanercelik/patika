import Foundation

/// Exact age exists only for this onboarding run; persistence keeps the coarse bucket.
enum AgeSelection {
    static let allowed = 18...100

    static func range(for age: Int) -> AgeRange {
        precondition(allowed.contains(age))
        switch age {
        case 18...24: return .eighteenToTwentyFour
        case 25...34: return .twentyFiveToThirtyFour
        case 35...44: return .thirtyFiveToFortyFour
        case 45...54: return .fortyFiveToFiftyFour
        default: return .fiftyFivePlus
        }
    }
}
