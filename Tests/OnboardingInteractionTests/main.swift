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

check(ReactiveSceneState.time(for: .morning) == .morning, "morning")
check(ReactiveSceneState.time(for: .daytime) == .daytime, "daytime")
check(ReactiveSceneState.time(for: .evening) == .evening, "evening")
check(ReactiveSceneState.time(for: .bedtime) == .night, "bedtime")
check(ReactiveSceneState.time(for: .noPattern) == .neutral, "no pattern")
check(ReactiveSceneState.mood(for: .veryHeavy) == .veiled, "very heavy")
check(ReactiveSceneState.mood(for: .heavy) == .quiet, "heavy")
check(ReactiveSceneState.mood(for: .middling) == .balanced, "middle")
check(ReactiveSceneState.mood(for: .okay) == .opening, "okay")
check(ReactiveSceneState.mood(for: .calm) == .clear, "calm")

await MainActor.run {
    var committedAttempts: ([PreviousAttempt], String?)?
    var crisisFlagged = false
    let attempts = PreviousAttemptsViewModel(
        selection: [],
        otherText: "",
        commit: { committedAttempts = ($0, $1) },
        flagCrisis: { crisisFlagged = true }
    )
    attempts.toggle(.nothing)
    attempts.toggle(.youtube)
    check(attempts.selection == [.youtube], "nothing must remain exclusive")
    attempts.toggle(.other)
    attempts.otherText = "  I tried journaling  "
    attempts.continueTapped()
    check(committedAttempts?.1 == "I tried journaling", "trimmed Other text must commit")

    committedAttempts = nil
    attempts.otherText = "I want to die"
    attempts.continueTapped()
    check(crisisFlagged, "Other text must be crisis screened")
    check(committedAttempts == nil, "crisis text must not commit")
}

if !failures.isEmpty {
    failures.forEach { print($0) }
    fatalError("\(failures.count) onboarding interaction checks failed")
}
print("OnboardingInteractionTests passed")
