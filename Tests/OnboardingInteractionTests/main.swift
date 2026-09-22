import Foundation

private var failures: [String] = []
private func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { failures.append(message) }
}

check(AgeSelection.range(for: 18) == .eighteenToTwentyFour, "18")
check(AgeSelection.range(for: 24) == .eighteenToTwentyFour, "24")
check(AgeSelection.range(for: 25) == .twentyFiveToThirtyFour, "25")
check(AgeSelection.range(for: 34) == .twentyFiveToThirtyFour, "34")
check(AgeSelection.range(for: 35) == .thirtyFiveToFortyFour, "35")
check(AgeSelection.range(for: 44) == .thirtyFiveToFortyFour, "44")
check(AgeSelection.range(for: 45) == .fortyFiveToFiftyFour, "45")
check(AgeSelection.range(for: 54) == .fortyFiveToFiftyFour, "54")
check(AgeSelection.range(for: 55) == .fiftyFivePlus, "55")
check(AgeSelection.range(for: 100) == .fiftyFivePlus, "100")

if !failures.isEmpty {
    failures.forEach { print($0) }
    fatalError("\(failures.count) onboarding interaction checks failed")
}
print("OnboardingInteractionTests passed")
