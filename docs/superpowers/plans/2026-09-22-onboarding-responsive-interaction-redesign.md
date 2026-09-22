# Onboarding Responsive Interaction Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the affected onboarding screens so they fit typical iPhones without required scrolling, remain readable over Patika's current gouache scenes, react meaningfully to selections, and move notification priming and the signature commitment into the approved flow.

**Architecture:** Keep `OnboardingFlowViewModel` as the only navigation owner and preserve the existing MVVM boundaries. Add reusable adaptive layout/readability components, pure domain mappers for testable selection behavior, a bounded reactive-scene state model, and a protected local signature store. Reuse the existing woodland palette, rounded type roles, paper surfaces, SF Symbols, motion tokens, and asset catalog rather than introducing a parallel visual system.

**Tech Stack:** Swift 6, SwiftUI, Observation, SwiftData/Codable local persistence, Asset Catalog, UserNotifications, custom `swiftc` test runner, Xcode iOS 26 simulator.

**Spec:** `docs/superpowers/specs/2026-09-22-onboarding-responsive-interaction-redesign-design.md`

## Global Constraints

- Deployment target remains iOS 26.0; do not add third-party dependencies.
- Match the current full-screen gouache woodland language, fixed dark appearance, rounded product typography, paper/woodland tokens, and monochrome SF Symbols.
- Do not introduce gradients, emoji, material blur over content, or raw per-screen colors.
- Keep normal-text contrast at least 4.5:1, large display text at least 3:1, and meaningful non-text controls at least 3:1.
- Keep touch targets at least 44×44 pt and preserve Dynamic Type through AX5.
- Honor Reduce Motion, Reduce Transparency, Increase Contrast, VoiceOver, and Switch Control.
- Exact age is ephemeral; persist only the existing `AgeRange`.
- Every new free-text field runs through `CrisisClassifier` before commit and never enters analytics.
- Baseline D1–D8 and later measurements continue to use the same `MeasurementAnswerView`.
- Notification authorization is called only after E1 priming opt-in and never with `.provisional`, `.timeSensitive`, or `.critical`.
- Signature strokes remain device-only and use complete file protection; clear them on local/account data deletion.
- Keep RevenueCat/paywall work out of scope; retain the current informational price screen.
- Add all user-visible English text to `MyApp/Content/Localizable.xcstrings`; views contain no literal copy.
- Run Xcode builds with `SWIFT_EMIT_LOC_STRINGS=NO` and confirm the catalog is unchanged except for intentional edits.

---

## File Structure

### New files

- `MyApp/DesignSystem/Components/SceneContentPlate.swift` — reusable high-contrast scene-backed content surface.
- `MyApp/DesignSystem/Components/AdaptiveChoiceGrid.swift` — two-column/one-column adaptive option grid.
- `MyApp/DesignSystem/Components/AgeWheelPicker.swift` — exact-age wheel with depth treatment and accessibility adjustment.
- `MyApp/DesignSystem/Components/IntensityScaleModel.swift` — pure D1 pointer-to-step mapping shared by the view and tests.
- `MyApp/Features/Onboarding/AIdentity/AgeSelection.swift` — pure exact-age-to-`AgeRange` mapping.
- `MyApp/Features/Onboarding/ReactiveSceneState.swift` — bounded time/mood scene state mapping without SwiftUI view logic.
- `MyApp/Infrastructure/Persistence/PromiseSignatureStore.swift` — protected local normalized-stroke persistence.
- `MyApp/DesignSystem/Components/SignatureCanvas.swift` — drawing surface and accessible simple-mark control.
- `MyApp/Features/Onboarding/CReflection/CommitmentViewModel.swift` — signature state, persistence result, and hold-completion message state.
- `Tests/OnboardingInteractionTests/main.swift` — age mapping, B5 Other policy, and scene-state domain tests.
- `Tests/PromiseSignatureStoreTests/main.swift` — normalization, round-trip persistence, and clear behavior.

### Major modified files

- `MyApp/DesignSystem/Theme.swift`
- `MyApp/DesignSystem/WoodlandStyle.swift`
- `MyApp/DesignSystem/Components/OnboardingQuestionLayout.swift`
- `MyApp/DesignSystem/Components/OnboardingScene.swift`
- `MyApp/DesignSystem/Components/IntensityScale.swift`
- `MyApp/DesignSystem/Components/MoodScale.swift`
- `MyApp/DesignSystem/Components/HoldToStartButton.swift`
- `MyApp/Features/Onboarding/AIdentity/IdentityChoiceViews.swift`
- `MyApp/Features/Onboarding/BProblemDiscovery/DurationView.swift`
- `MyApp/Features/Onboarding/BProblemDiscovery/TimingView.swift`
- `MyApp/Features/Onboarding/BProblemDiscovery/PreviousAttemptsView.swift`
- `MyApp/Features/Onboarding/BProblemDiscovery/PreviousAttemptsViewModel.swift`
- `MyApp/Features/Onboarding/BProblemDiscovery/CurrentMoodView.swift`
- `MyApp/Features/Onboarding/DMeasurement/MeasurementQuestionView.swift`
- `MyApp/Features/Onboarding/DMeasurement/MeasurementAnswerView.swift`
- `MyApp/Features/Onboarding/EPreferences/ReminderTimeView.swift`
- `MyApp/Features/Onboarding/FDelivery/RoadmapView.swift`
- `MyApp/Features/Onboarding/CReflection/CommitmentView.swift`
- `MyApp/Features/Onboarding/GFirstSession/SessionCompleteView.swift`
- `MyApp/Features/Session/AdaptiveQuestionView.swift`
- `MyApp/Features/Onboarding/OnboardingDraft.swift`
- `MyApp/Features/Onboarding/OnboardingFlowViewModel.swift`
- `MyApp/Features/Onboarding/OnboardingContainerView.swift`
- `MyApp/Features/Onboarding/OnboardingDebugSkip.swift`
- `MyApp/Features/Onboarding/OnboardingGallery.swift`
- `MyApp/DesignSystem/Components/OnboardingArtwork.swift`
- `MyApp/App/AppServices.swift`
- `MyApp/Features/Me/MeViewModel.swift`
- `MyApp/Content/Copy.swift`
- `MyApp/Content/Localizable.xcstrings`
- `Tests/ContrastTests/main.swift`
- `Tests/LocalizationCatalogTests/main.swift`
- `scripts/run-swift-tests.sh`
- `CLAUDE.md`

---

### Task 1: Adaptive shell, local content plate, and direct scene crossfade

**Files:**
- Create: `MyApp/DesignSystem/Components/SceneContentPlate.swift`
- Modify: `MyApp/DesignSystem/Theme.swift`
- Modify: `MyApp/DesignSystem/WoodlandStyle.swift`
- Modify: `MyApp/DesignSystem/Components/OnboardingQuestionLayout.swift`
- Modify: `MyApp/DesignSystem/Components/OnboardingScene.swift`
- Modify: `Tests/ContrastTests/main.swift`

**Interfaces:**
- Consumes: `Theme`, `WoodlandStyle`, `OnboardingSurfaceStyle`, `OnboardingArtwork`.
- Produces: `SceneContentPlate`, `OnboardingHeightClass`, `EnvironmentValues.onboardingHeightClass`, and a two-layer `OnboardingSceneLayer` used by later screen tasks.

- [ ] **Step 1: Extend the contrast test with the approved scene-plate colors**

Add semantic RGB tokens to `WoodlandStyle` and make the test read them by name. The failing assertions must cover primary text, secondary text, and borders:

```swift
let scenePlate = hex("scenePlate", in: woodland)
let scenePlateSecondary = hex("scenePlateSecondary", in: woodland)
check(textPrimary.contrastRatio(against: scenePlate) >= aa,
      "primary/scene plate below AA")
check(scenePlateSecondary.contrastRatio(against: scenePlate) >= aa,
      "secondary/scene plate below AA")
```

- [ ] **Step 2: Run the focused test and verify failure**

Run:

```bash
bash scripts/run-swift-tests.sh Contrast
```

Expected: `BUILD FAIL Contrast` because the new scene-plate tokens do not exist.

- [ ] **Step 3: Add semantic layout and contrast tokens**

Add fixed woodland colors, corner radius, and motion tokens; do not use ad-hoc values in screens:

```swift
enum WoodlandStyle {
    static let scenePlate = RGB(hex: 0x15211F)
    static let scenePlateSecondary = RGB(hex: 0xB9C4BF)
    static let scenePlateBorder = RGB(hex: 0x60716B)
}

extension Theme {
    enum OnboardingLayout {
        static let comfortableMinimumHeight: CGFloat = 760
        static let compactMinimumHeight: CGFloat = 640
        static let plateCornerRadius: CGFloat = 24
    }
}
```

- [ ] **Step 4: Implement the local readability surface**

Create a reusable surface that stays opaque under Reduce Transparency and becomes more distinct under Increase Contrast:

```swift
struct SceneContentPlate<Content: View>: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: Theme.OnboardingLayout.plateCornerRadius)
                    .fill(WoodlandStyle.scenePlate.color.opacity(contrast == .increased ? 1 : 0.94))
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.OnboardingLayout.plateCornerRadius)
                    .strokeBorder(WoodlandStyle.scenePlateBorder.color,
                                  lineWidth: Theme.Line.border)
            }
    }
}
```

- [ ] **Step 5: Add height-class resolution to the shared question layout**

Resolve height from the content container, not `UIScreen`, and place it in the environment:

```swift
enum OnboardingHeightClass: Sendable { case comfortable, compact, scrollRequired }

static func heightClass(availableHeight: CGFloat, accessibility: Bool) -> OnboardingHeightClass {
    if accessibility || availableHeight < Theme.OnboardingLayout.compactMinimumHeight { return .scrollRequired }
    if availableHeight < Theme.OnboardingLayout.comfortableMinimumHeight { return .compact }
    return .comfortable
}
```

Keep `safeAreaInset(edge: .bottom)` for keyboard avoidance, but remove `footerBackdrop`. The footer background must be `Color.clear`; the CTA owns its own opaque capsule.

- [ ] **Step 6: Replace the scene swap with explicit outgoing/incoming layers**

Maintain displayed and previous art so the flat fallback never appears between two images:

```swift
@State private var displayed: OnboardingArtwork?
@State private var outgoing: OnboardingArtwork?

private func transition(to next: OnboardingArtwork?) {
    guard next != displayed else { return }
    outgoing = displayed
    displayed = next
    if reduceMotion { outgoing = nil; return }
    Task { @MainActor in
        try? await Task.sleep(for: .seconds(Theme.Motion.paletteTransition))
        guard displayed == next else { return }
        outgoing = nil
    }
}
```

Render `outgoing` below `displayed`, both above `WoodlandStyle.background`; use opacity only and never insert black.

- [ ] **Step 7: Run tests and build**

Run:

```bash
bash scripts/run-swift-tests.sh Contrast
xcodebuild -project patika.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' SWIFT_EMIT_LOC_STRINGS=NO build
```

Expected: contrast tests pass and `** BUILD SUCCEEDED **`.

- [ ] **Step 8: Commit**

```bash
git add MyApp/DesignSystem Tests/ContrastTests/main.swift
git commit -m "fix: make onboarding shell adaptive and readable"
```

---

### Task 2: Exact-age wheel with range-only persistence

**Files:**
- Create: `MyApp/Features/Onboarding/AIdentity/AgeSelection.swift`
- Create: `MyApp/DesignSystem/Components/AgeWheelPicker.swift`
- Create: `Tests/OnboardingInteractionTests/main.swift`
- Modify: `MyApp/Features/Onboarding/AIdentity/IdentityChoiceViews.swift`
- Modify: `scripts/run-swift-tests.sh`

**Interfaces:**
- Consumes: existing `AgeRange`, `Theme`, `PatikaInk`, `OnboardingQuestionLayout`.
- Produces: `AgeSelection.range(for:) -> AgeRange`, `AgeWheelPicker(selection:onSelect:)`, and no persistent exact-age field.

- [ ] **Step 1: Write the failing age-boundary tests**

```swift
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
```

Add a runner entry compiling `DomainEnums.swift`, `AgeSelection.swift`, the localization shim, and this test.

- [ ] **Step 2: Run and verify failure**

Run:

```bash
bash scripts/run-swift-tests.sh OnboardingInteraction
```

Expected: failure because `AgeSelection` is undefined.

- [ ] **Step 3: Implement the pure mapper**

```swift
enum AgeSelection {
    static let allowed = 18...100

    static func range(for age: Int) -> AgeRange {
        precondition(allowed.contains(age))
        switch age {
        case 18...24: .eighteenToTwentyFour
        case 25...34: .twentyFiveToThirtyFour
        case 35...44: .thirtyFiveToFortyFour
        case 45...54: .fortyFiveToFiftyFour
        default: .fiftyFivePlus
        }
    }
}
```

- [ ] **Step 4: Implement `AgeWheelPicker`**

Use a vertical `ScrollView` with view-aligned snapping and a `scrollTransition` that applies scale, opacity, and a capped blur away from the identity phase. Expose the entire wheel as one adjustable accessibility element. Do not store the exact value outside the view state.

```swift
ScrollView(.vertical) {
    LazyVStack(spacing: 0) {
        ForEach(AgeSelection.allowed, id: \.self) { age in
            Text(age.formatted())
                .font(Theme.TypeFace.screenTitle)
                .containerRelativeFrame(.vertical, count: 5, spacing: 0)
                .scrollTransition { content, phase in
                    content
                        .scaleEffect(phase.isIdentity ? 1 : 0.82)
                        .opacity(phase.isIdentity ? 1 : 0.34)
                        .blur(radius: phase.isIdentity ? 0 : 2.5)
                }
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.viewAligned)
```

- [ ] **Step 5: Replace `AgeRangeView`'s slider**

Keep the exact age only in transient flow memory so navigating back restores the number the user actually chose without persisting it:

```swift
private(set) var selectedExactAge: Int?

func previewAge(_ age: Int?) {
    selectedExactAge = age
}

func commitAge(_ age: Int) {
    selectedExactAge = age
    draft.ageRange = AgeSelection.range(for: age)
    advance(to: .a2Categories)
}

func commitAgeUndisclosed() {
    selectedExactAge = nil
    draft.ageRange = .undisclosed
    advance(to: .a2Categories)
}
```

`AgeRangeView` initializes from `flow.selectedExactAge`, previews wheel changes through `flow.previewAge`, and submits through `commitAge`. The exact number remains in memory only; it never enters `OnboardingDraft`, persistence, analytics, or a backend payload.

Do not add age to `OnboardingDraft`, `UserProfile.birthYear`, analytics, or backend payloads.

- [ ] **Step 6: Run tests, build, and inspect the catalog diff**

```bash
bash scripts/run-swift-tests.sh OnboardingInteraction
xcodebuild -project patika.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' SWIFT_EMIT_LOC_STRINGS=NO build
git diff -- MyApp/Content/Localizable.xcstrings
```

Expected: tests pass, build succeeds, catalog has no incidental changes.

- [ ] **Step 7: Commit**

```bash
git add MyApp/Features/Onboarding/AIdentity MyApp/DesignSystem/Components/AgeWheelPicker.swift Tests/OnboardingInteractionTests scripts/run-swift-tests.sh
git commit -m "feat: select an exact onboarding age privately"
```

---

### Task 3: Direct duration and occurrence-time choices with reactive scenes

**Files:**
- Create: `MyApp/DesignSystem/Components/AdaptiveChoiceGrid.swift`
- Create: `MyApp/Features/Onboarding/ReactiveSceneState.swift`
- Modify: `MyApp/Features/Onboarding/BProblemDiscovery/DurationView.swift`
- Modify: `MyApp/Features/Onboarding/BProblemDiscovery/TimingView.swift`
- Modify: `MyApp/Features/Onboarding/OnboardingFlowViewModel.swift`
- Modify: `MyApp/DesignSystem/Components/OnboardingArtwork.swift`
- Modify: `MyApp/Assets.xcassets/Onboarding/`
- Modify: `assets/illustrations/scenes/`
- Modify: `Tests/OnboardingInteractionTests/main.swift`

**Interfaces:**
- Consumes: `ProblemDuration`, `ProblemTiming`, `SingleChoiceStepViewModel`, `OnboardingSceneLayer`.
- Produces: `AdaptiveChoiceGrid`, `TimeScenePhase`, `ReactiveSceneState.time(for:)`, and five bounded time scene assets.

- [ ] **Step 1: Add failing scene-state tests**

```swift
check(ReactiveSceneState.time(for: .morning) == .morning, "morning")
check(ReactiveSceneState.time(for: .daytime) == .daytime, "daytime")
check(ReactiveSceneState.time(for: .evening) == .evening, "evening")
check(ReactiveSceneState.time(for: .bedtime) == .night, "bedtime")
check(ReactiveSceneState.time(for: .noPattern) == .neutral, "no pattern")
```

- [ ] **Step 2: Run the focused test and verify failure**

```bash
bash scripts/run-swift-tests.sh OnboardingInteraction
```

Expected: missing `ReactiveSceneState` and `TimeScenePhase`.

- [ ] **Step 3: Add the pure scene-state mapping**

```swift
enum TimeScenePhase: String, Codable, Sendable {
    case morning, daytime, evening, night, neutral
}

enum ReactiveSceneState {
    static func time(for timing: ProblemTiming) -> TimeScenePhase {
        switch timing {
        case .morning: .morning
        case .daytime: .daytime
        case .evening: .evening
        case .bedtime: .night
        case .noPattern: .neutral
        }
    }
}
```

- [ ] **Step 4: Build `AdaptiveChoiceGrid`**

Use `ViewThatFits(in: .vertical)` to prefer a two-column `Grid`, then fall back to a single-column stack. The component takes `options`, `isSelected`, and `onSelect`, and renders existing `ChoiceRow` semantics without fixed widths.

- [ ] **Step 5: Replace B2 with a 2×2 grid plus full-width unsure row**

Remove `DualStatementSlider` from `DurationView`. Order the four actual durations explicitly and render `.unsure` below the grid. Preserve the separate Continue action and existing domain commit.

- [ ] **Step 6: Replace B3 illustration/list with direct choices and live preview**

Initialize `SingleChoiceStepViewModel` with an `onChange` callback:

```swift
onChange: { flow.previewTiming($0) },
commit: { flow.commitTiming($0) }
```

Render morning/day/evening/bedtime in the adaptive grid and `.noPattern` as a full-width row. Remove `OnboardingArtworkView(.timeOfDay)`.

- [ ] **Step 7: Add the bounded time artwork set**

Use the current Patika gouache prompt language from `assets/illustrations/scenes/prompts.md`. Generate or derive five images with identical composition and crop:

```text
bg-time-morning
bg-time-daytime
bg-time-evening
bg-time-night
bg-time-neutral
```

Source PNGs go in `assets/illustrations/scenes/`; app JPEGs use the existing 887×1774, opaque, q85 asset-catalog convention. Do not introduce gradients or photorealistic lighting.

- [ ] **Step 8: Wire scene preview into the flow**

Add `previewedTiming: ProblemTiming?`, `previewTiming(_:)`, and clear it on commit. For `.b3Timing`, resolve `currentScene` from the previewed or draft timing; all other category screens keep their current category art.

- [ ] **Step 9: Run test, build, and visually smoke B2/B3**

```bash
bash scripts/run-swift-tests.sh OnboardingInteraction
xcodebuild -project patika.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' SWIFT_EMIT_LOC_STRINGS=NO build
xcrun simctl launch booted com.tanercelik.Patika -patika-debug-step b2
xcrun simctl launch booted com.tanercelik.Patika -patika-debug-step b3
```

Expected: B2 and B3 fit at default type; time selections crossfade without black.

- [ ] **Step 10: Commit**

```bash
git add MyApp/DesignSystem/Components/AdaptiveChoiceGrid.swift MyApp/Features/Onboarding MyApp/DesignSystem/Components/OnboardingArtwork.swift MyApp/Assets.xcassets/Onboarding assets/illustrations/scenes Tests/OnboardingInteractionTests/main.swift
git commit -m "feat: make duration and timing choices direct"
```

---

### Task 4: B5 compact attempts grid and crisis-screened Other text

**Files:**
- Modify: `MyApp/Features/Onboarding/OnboardingDraft.swift`
- Modify: `MyApp/Features/Onboarding/BProblemDiscovery/PreviousAttemptsViewModel.swift`
- Modify: `MyApp/Features/Onboarding/BProblemDiscovery/PreviousAttemptsView.swift`
- Modify: `MyApp/Models/PersistentModels.swift`
- Modify: `MyApp/Models/ProfileRecord.swift`
- Modify: `MyApp/Infrastructure/Persistence/ProfileStore.swift`
- Modify: `MyApp/Content/Copy.swift`
- Modify: `MyApp/Content/Localizable.xcstrings`
- Modify: `Tests/OnboardingInteractionTests/main.swift`
- Modify: `scripts/run-swift-tests.sh`

**Interfaces:**
- Consumes: `AdaptiveChoiceGrid`, `PreviousAttempt`, `CrisisClassifier`, `OnboardingTextInput`.
- Produces: `OnboardingDraft.previousAttemptOtherText`, testable callback-based `PreviousAttemptsViewModel`, and device-side `ProblemStatement.previousAttemptOtherText`.

- [ ] **Step 1: Write failing selection and crisis tests**

Construct `PreviousAttemptsViewModel` with callbacks rather than an entire flow:

```swift
var committed: ([PreviousAttempt], String?)?
var crisis = false
let model = PreviousAttemptsViewModel(
    selection: [],
    otherText: "",
    commit: { committed = ($0, $1) },
    flagCrisis: { crisis = true }
)

model.toggle(.nothing)
model.toggle(.youtube)
check(model.selection == [.youtube], "nothing must remain exclusive")

model.toggle(.other)
model.otherText = "I tried journaling"
model.continueTapped()
check(committed?.1 == "I tried journaling", "trimmed Other text must commit")
```

Add a crisis phrase using the existing CrisisClassifier fixture vocabulary and assert `crisis == true` and no commit.

- [ ] **Step 2: Run and verify failure**

```bash
bash scripts/run-swift-tests.sh OnboardingInteraction
```

Expected: initializer and `otherText` are missing.

- [ ] **Step 3: Refactor `PreviousAttemptsViewModel` for explicit dependencies**

Use this interface:

```swift
init(
    selection: [PreviousAttempt],
    otherText: String,
    commit: @escaping ([PreviousAttempt], String?) -> Void,
    flagCrisis: @escaping () -> Void
)
```

In `continueTapped`, require non-empty trimmed text only when `.other` is selected. Run `CrisisClassifier.evaluate(trimmed)` before commit. Deselecting `.other` sets `otherText = ""`.

- [ ] **Step 4: Add the draft and device-side record field**

```swift
var previousAttemptOtherText: String?
```

Pass it from `OnboardingDraft` into `ProblemStatement`. Also add `previousAttemptOtherText: String?` to `ProfileRecord`, decode it with `decodeIfPresent`, and assign it in `ProfileRecord.mergeOnboarding(_:)`. This makes the approved device-only persistence real in the current `ProfileStore` architecture instead of relying on the legacy SwiftData model alone. Keep it out of backend generation payloads and analytics. Because both persistence formats have existing data, default/decode missing values as `nil` and verify an existing store still launches.

- [ ] **Step 5: Render the compact grid and conditional field**

Use `AdaptiveChoiceGrid` for the seven options. When `.other` is selected, show:

```swift
OnboardingTextInput(
    text: $viewModel.otherText,
    placeholder: Copy.Onboarding.attemptsOtherPlaceholder,
    lineRange: 1...1
)
.transition(.opacity)
```

Keep the therapy note compact and below the option group. Keyboard-open state may scroll; keyboard-closed default state must fit a typical iPhone.

- [ ] **Step 6: Add manual localization entries and regenerate the shim**

Add at minimum:

```text
onboarding.attemptsOtherPlaceholder = "What else did you try?"
onboarding.attemptsOtherRequired = "Write a few words, or deselect Other."
```

Run:

```bash
python3 scripts/generate-string-symbol-shim.py
bash scripts/run-swift-tests.sh LocalizationCatalog
```

Update the `OnboardingInteraction` runner entry so it compiles `PreviousAttemptsViewModel.swift` and `CrisisClassifier.swift` in addition to `DomainEnums.swift`, `AgeSelection.swift`, the localization shim, and the test file.

- [ ] **Step 7: Run all focused tests and build**

```bash
bash scripts/run-swift-tests.sh OnboardingInteraction
bash scripts/run-swift-tests.sh CrisisClassifier
bash scripts/run-swift-tests.sh LocalizationCatalog
xcodebuild -project patika.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' SWIFT_EMIT_LOC_STRINGS=NO build
```

- [ ] **Step 8: Commit**

```bash
git add MyApp/Features/Onboarding MyApp/Models/PersistentModels.swift MyApp/Content Tests scripts/run-swift-tests.sh
git commit -m "feat: accept a private Other attempt response"
```

---

### Task 5: Replace weather mood controls with a living woodland response

**Files:**
- Modify: `MyApp/DesignSystem/Components/MoodScale.swift`
- Modify: `MyApp/Features/Onboarding/BProblemDiscovery/CurrentMoodView.swift`
- Modify: `MyApp/Features/Onboarding/ReactiveSceneState.swift`
- Modify: `MyApp/Features/Onboarding/OnboardingFlowViewModel.swift`
- Modify: `MyApp/DesignSystem/Components/OnboardingArtwork.swift`
- Modify: `MyApp/Assets.xcassets/Onboarding/`
- Modify: `assets/illustrations/scenes/`
- Modify: `Tests/OnboardingInteractionTests/main.swift`

**Interfaces:**
- Consumes: `MoodLevel`, flow preview callbacks, two-layer scene crossfade.
- Produces: `MoodScenePhase`, five fixed mood scene assets, and a text-first five-stop mood path.

- [ ] **Step 1: Add failing mood-scene mapping tests**

```swift
check(ReactiveSceneState.mood(for: .veryHeavy) == .veiled, "very heavy")
check(ReactiveSceneState.mood(for: .heavy) == .quiet, "heavy")
check(ReactiveSceneState.mood(for: .middling) == .balanced, "middle")
check(ReactiveSceneState.mood(for: .okay) == .opening, "okay")
check(ReactiveSceneState.mood(for: .calm) == .clear, "calm")
```

- [ ] **Step 2: Implement `MoodScenePhase` and mapping**

```swift
enum MoodScenePhase: String, Codable, Sendable {
    case veiled, quiet, balanced, opening, clear
}
```

Keep the mapping exhaustive and outside the view.

- [ ] **Step 3: Redesign `MoodScale`**

Remove `MoodLevel.icon` usage. Render five 44 pt-or-larger stone buttons connected by the existing trail line token. Under the path, reserve one stable line for the selected `MoodLevel.label`. Preserve tap and drag-across selection; buttons remain the accessible alternative.

- [ ] **Step 4: Add five same-composition mood assets**

Create:

```text
bg-mood-veiled
bg-mood-quiet
bg-mood-balanced
bg-mood-opening
bg-mood-clear
```

All five share camera, path, flora placement, and crop. Change only haze, light, and bud openness. Do not show dead or decaying plants.

- [ ] **Step 5: Wire live mood preview**

For `.b6CurrentMood`, resolve `currentScene` from `previewedMood ?? draft.currentMood`; use `.moodBalanced` before selection. Retire `MoodLevel.sceneDimming` as the primary response and keep only a fixed contrast dimming value needed by rendered-scene tests.

- [ ] **Step 6: Test and visually verify**

```bash
bash scripts/run-swift-tests.sh OnboardingInteraction
xcodebuild -project patika.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' SWIFT_EMIT_LOC_STRINGS=NO build
xcrun simctl launch booted com.tanercelik.Patika -patika-debug-step b6
```

Verify tap and drag, selected label, no weather symbol, no black frame, and Reduce Motion.

- [ ] **Step 7: Commit**

```bash
git add MyApp/DesignSystem/Components/MoodScale.swift MyApp/Features/Onboarding MyApp/DesignSystem/Components/OnboardingArtwork.swift MyApp/Assets.xcassets/Onboarding assets/illustrations/scenes Tests/OnboardingInteractionTests/main.swift
git commit -m "feat: make the mood scene respond without weather metaphors"
```

---

### Task 6: Rebuild the shared measurement presentation for fit and contrast

**Files:**
- Create: `MyApp/DesignSystem/Components/IntensityScaleModel.swift`
- Modify: `MyApp/DesignSystem/Components/IntensityScale.swift`
- Modify: `MyApp/Features/Onboarding/DMeasurement/MeasurementQuestionView.swift`
- Modify: `MyApp/Features/Onboarding/DMeasurement/MeasurementAnswerView.swift`
- Modify: `MyApp/Features/Path/PathMeasurementQuestionView.swift`
- Modify: `Tests/ContrastTests/main.swift`

**Interfaces:**
- Consumes: `SceneContentPlate`, `MeasurementQuestionViewModel`, `ChoiceRow`.
- Produces: one unchanged measurement instrument with readable scene presentation in onboarding and path follow-ups.

- [ ] **Step 1: Add a pure D1 hit-mapping helper and failing boundary tests**

Create a Foundation/CoreGraphics-only helper so the command-line test does not need to compile SwiftUI:

```swift
enum IntensityScaleModel {
    nonisolated static func step(at x: CGFloat, width: CGFloat) -> Int {
        guard width > 0 else { return 0 }
        let ratio = min(max(x / width, 0), 1)
        return Int((ratio * 10).rounded())
    }
}
```

Make `IntensityScale.select(at:width:)` call:

```swift
let step = IntensityScaleModel.step(at: x, width: width)
```

Add the model file to the `OnboardingInteraction` runner and test:

```swift
check(IntensityScaleModel.step(at: 0, width: 320) == 0, "left edge")
check(IntensityScaleModel.step(at: 160, width: 320) == 5, "midpoint")
check(IntensityScaleModel.step(at: 320, width: 320) == 10, "right edge")
check(IntensityScaleModel.step(at: 10, width: 0) == 0, "zero width")
```

- [ ] **Step 2: Make D1 labels and hit targets fit**

Inset the visual bars from both edges while allowing the gesture area to span the full available width. Give each stop an expanded content shape equivalent to at least 44 pt without forcing 11 visible 44 pt columns. Keep `None` and `Very strong` inside the panel margins and render the selected number plus endpoint description.

- [ ] **Step 3: Wrap the shared answer group in `SceneContentPlate`**

Apply the plate at the `MeasurementQuestionView`/shared host level, not separately to each row. Use `WoodlandStyle.scenePlateSecondary.color` for the clinical disclaimer and unselected supporting text.

- [ ] **Step 4: Preserve the identical later-measurement instrument**

Update `PathMeasurementQuestionView` to host the same `MeasurementAnswerView` inside the same plate component. Do not fork D1–D8 controls or alter option labels/values.

- [ ] **Step 5: Extend contrast assertions**

Test scene-plate primary, secondary, selected row, unselected border, and disabled CTA tokens. The test must fail if any normal text drops below 4.5:1.

- [ ] **Step 6: Run tests and build**

```bash
bash scripts/run-swift-tests.sh OnboardingInteraction
bash scripts/run-swift-tests.sh Contrast
bash scripts/run-swift-tests.sh MeasurementScoring
xcodebuild -project patika.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' SWIFT_EMIT_LOC_STRINGS=NO build
```

- [ ] **Step 7: Visual verification**

Capture D1, D2, and D8 at default type and AX5. Confirm endpoint labels are fully visible, every choice is readable before selection, and AX5 scrolls without CTA overlap.

- [ ] **Step 8: Commit**

```bash
git add MyApp/DesignSystem/Components/IntensityScale.swift MyApp/Features/Onboarding/DMeasurement MyApp/Features/Path/PathMeasurementQuestionView.swift Tests
git commit -m "fix: make every measurement question readable"
```

---

### Task 7: Build protected local signature storage and the new promise screen

**Files:**
- Create: `MyApp/Infrastructure/Persistence/PromiseSignatureStore.swift`
- Create: `MyApp/DesignSystem/Components/SignatureCanvas.swift`
- Create: `MyApp/Features/Onboarding/CReflection/CommitmentViewModel.swift`
- Create: `Tests/PromiseSignatureStoreTests/main.swift`
- Modify: `MyApp/App/AppServices.swift`
- Modify: `MyApp/Features/Onboarding/CReflection/CommitmentView.swift`
- Modify: `MyApp/DesignSystem/Components/HoldToStartButton.swift`
- Modify: `MyApp/Features/Me/MeViewModel.swift`
- Modify: `MyApp/Content/Copy.swift`
- Modify: `MyApp/Content/Localizable.xcstrings`
- Modify: `scripts/run-swift-tests.sh`

**Interfaces:**
- Consumes: current user quote logic, `Theme.softHaptic`, `AppServices`.
- Produces: `NormalizedSignature`, `PromiseSignatureStore.save/load/clear`, `SignatureCanvas`, callback-based `CommitmentViewModel`, and immediate hold behavior.

- [ ] **Step 1: Write failing normalization and persistence tests**

```swift
let document = NormalizedSignature(strokes: [[
    .init(x: 0.10, y: 0.20),
    .init(x: 0.90, y: 0.80),
]])
let url = temporaryDirectory.appending(path: "signature.json")
let store = PromiseSignatureStore(fileURL: url)
check(store.save(document), "save")
check(store.load() == document, "round trip")
store.clear()
check(store.load() == nil, "clear")
```

Also assert the initializer clamps all coordinates into `0...1`.

- [ ] **Step 2: Run and verify failure**

```bash
bash scripts/run-swift-tests.sh PromiseSignatureStore
```

Expected: missing types.

- [ ] **Step 3: Implement the protected local store**

```swift
struct NormalizedSignaturePoint: Codable, Equatable, Sendable {
    var x: Double
    var y: Double
}

struct NormalizedSignature: Codable, Equatable, Sendable {
    var strokes: [[NormalizedSignaturePoint]]
}

@MainActor
final class PromiseSignatureStore {
    private let fileURL: URL?

    @discardableResult
    func save(_ signature: NormalizedSignature) -> Bool {
        guard let fileURL else { return true }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(signature)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
            return true
        } catch { return false }
    }
}
```

Provide `.live()` under `Application Support/Profile/promise-signature.json` and `.ephemeral()` for previews/tests.

- [ ] **Step 4: Inject and clear the store**

Add `let promiseSignature: PromiseSignatureStore` to `AppServices`. Instantiate `.live()` in production and `.ephemeral()` in preview/debug fixtures. In account/local-data deletion, call `services.promiseSignature.clear()` alongside `profile.erase()` and `avatar.clear()`.

- [ ] **Step 5: Implement `SignatureCanvas`**

Use `Canvas` to draw current and completed strokes with the woodland ink token. A zero-distance `DragGesture` appends normalized points immediately. Provide visible `Clear` and `Use a simple mark` buttons; the simple mark inserts a fixed non-biometric two-segment stroke.

Do not rasterize the signature and do not expose stroke points to observability.

- [ ] **Step 6: Refactor `HoldToStartButton`**

Change the public interface to:

```swift
struct HoldToStartButton: View {
    let title: LocalizedStringResource
    var holdDuration: TimeInterval = 1.2
    let action: () -> Void
}
```

Remove the separate hint `Text`. Keep `DragGesture(minimumDistance: 0)` so progress begins on touch-down. Fire the first soft haptic immediately, then bounded pulses. Keep the accessibility action as a direct completion path.

- [ ] **Step 7: Rebuild `CommitmentView` around signature state**

`CommitmentViewModel` owns strokes, save error, and completion-message visibility. It receives `store` and `onStart` closures. The view shows the existing B4/B1 quote priority, signature canvas, persistence error, and hold button only after a signature/simple mark exists.

After hold completion:

```swift
guard viewModel.persist() else { return }
viewModel.showTransitionMessage()
Task { @MainActor in
    try? await Task.sleep(for: .seconds(1))
    viewModel.start()
}
```

- [ ] **Step 8: Add localization entries**

Add manual keys for headline, body, clear, simple mark, draw hint, save error, hold title, and transition message. Required values include:

```text
commitment.holdToStart = "Press and hold to start your path"
commitment.dayOneTransition = "Let’s begin with day one."
commitment.clearSignature = "Clear"
commitment.simpleMark = "Use a simple mark"
commitment.saveError = "Your mark is still here. It wasn’t saved, and that wasn’t your fault."
```

- [ ] **Step 9: Run tests and build**

```bash
python3 scripts/generate-string-symbol-shim.py
bash scripts/run-swift-tests.sh PromiseSignatureStore
bash scripts/run-swift-tests.sh LocalizationCatalog
xcodebuild -project patika.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' SWIFT_EMIT_LOC_STRINGS=NO build
```

- [ ] **Step 10: Commit**

```bash
git add MyApp/Infrastructure/Persistence/PromiseSignatureStore.swift MyApp/DesignSystem/Components/SignatureCanvas.swift MyApp/Features/Onboarding/CReflection MyApp/DesignSystem/Components/HoldToStartButton.swift MyApp/App/AppServices.swift MyApp/Features/Me/MeViewModel.swift MyApp/Content Tests scripts/run-swift-tests.sh
git commit -m "feat: add a private signature promise"
```

---

### Task 8: Compact path summary and approved onboarding route

**Files:**
- Modify: `MyApp/Features/Onboarding/FDelivery/RoadmapView.swift`
- Modify: `MyApp/Features/Onboarding/OnboardingFlowViewModel.swift`
- Modify: `MyApp/Features/Onboarding/OnboardingContainerView.swift`
- Modify: `MyApp/Features/Onboarding/OnboardingDebugSkip.swift`
- Modify: `MyApp/Features/Onboarding/OnboardingGallery.swift`
- Modify: `MyApp/Features/Onboarding/EPreferences/ReminderTimeView.swift`
- Modify: `MyApp/Features/Onboarding/HAccount/NotificationPrimingView.swift`
- Modify: `MyApp/Features/Onboarding/OnboardingDraft.swift`
- Modify: `MyApp/Infrastructure/Persistence/ProfileStore.swift`
- Modify: `MyApp/Content/Copy.swift`
- Modify: `MyApp/Content/Localizable.xcstrings`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: new `CommitmentView`, existing notification priming, `PathPlan`, `SceneContentPlate`.
- Produces: compact F2 phase summary and exact route `D8 → E1 → H2 → F1 → F2 → commitment → G1 → G2 → price → H1`.

- [ ] **Step 1: Add an explicit route regression check**

Create a small source-level route test in `Tests/OnboardingInteractionTests/main.swift` that reads `OnboardingFlowViewModel.swift` and asserts these exact call fragments are present:

```swift
check(source.contains("advance(to: .h2Priming)"), "E1 must lead to priming")
check(source.contains("advance(to: .f1Generation)"), "priming must lead to generation")
check(source.contains("advance(to: .commitment)"), "F2 must lead to commitment")
check(source.contains("step = .g1FirstSession"), "commitment must lead to G1")
check(source.contains("advance(to: .h1Account)"), "price must lead to account")
```

Keep this as a narrow regression guard; behavior remains verified in the simulator.

- [ ] **Step 2: Replace the long roadmap with compact summary data**

Delete `ScrollPosition`, tour task, auto-scroll methods, and full generated-step list from onboarding F2. Keep full map code in `Yolum` untouched.

Build at most five summary rows from `PathPlan.rows(for:)`, with the first generated step promoted above them. Wrap the summary in `SceneContentPlate` and use a normal `PrimaryButton` labeled by a new `roadmapContinue` key.

- [ ] **Step 3: Route F2 to commitment**

Add:

```swift
func finishRoadmap() {
    advance(to: .commitment)
}
```

The F2 CTA calls `finishRoadmap()`. `startFirstSession()` remains the commitment completion action and retains the irreversible-history behavior.

- [ ] **Step 4: Remove the old pre-measurement commitment route**

Change:

```swift
func finishHonestExpectation() {
    advance(to: .d0MeasurementIntro)
}
```

Delete `finishCommitment()` if the rebuilt commitment calls `startFirstSession()` directly.

- [ ] **Step 5: Move notification priming after E1**

Add `var reminderEnabled = false` to `OnboardingDraft`. Change `commitReminder` to set the time/voice and `advance(to: .h2Priming)`.

Do not call `profile.recordOnboarding` this early in the flow. Instead, construct a temporary `ReminderSetting`, request/schedule it, and keep only the result in the draft:

```swift
func finishReminderPriming(enable: Bool) async {
    if enable {
        let reminder = ReminderSetting(
            isEnabled: true,
            hour: draft.reminderHour,
            minute: draft.reminderMinute,
            isSuggested: draft.timing?.suggestedReminderHour == draft.reminderHour
        )
        draft.reminderEnabled = await ReminderScheduler.apply(reminder) == .scheduled
    } else {
        draft.reminderEnabled = false
    }
    advance(to: .f1Generation)
}
```

Update `ProfileRecord.mergeOnboarding(_:)` so the eventual existing completion-boundary write uses `draft.reminderEnabled`. This preserves the rule that a partial pre-generation onboarding does not write a profile record.

Change `finishPrice()` to `advance(to: .h1Account)`. No second priming step remains after price.

- [ ] **Step 6: Update step metadata and debug routes**

Update comments, `progress`, `canGoBack`, `surfaceStyle`, `currentScene`, debug string parsing, gallery order, and debug menu. Commitment uses `.prepare`/path-ready scene, not `.reflection`. H2 uses `.prepare` because it now precedes generation. H2 permits back navigation to E1 before the system prompt; F1 and all irreversible generated-path steps keep back disabled.

- [ ] **Step 7: Add copy and document the new product-owner decision**

Add `onboarding.roadmapContinue = "Continue"` and remove dead slide/hint keys only after `rg` confirms no consumers.

Add a dated `CLAUDE.md` entry recording:

- Exact age UI maps to stored ranges.
- B2/B3 direct choices.
- B5 Other text is local and crisis-screened.
- B6 weather metaphor removed.
- H2 moved after E1.
- F2 compact summary replaces full auto-tour.
- Commitment moved after F2 and uses local signature + immediate hold.

- [ ] **Step 8: Run tests and build**

```bash
python3 scripts/generate-string-symbol-shim.py
bash scripts/run-swift-tests.sh OnboardingInteraction
bash scripts/run-swift-tests.sh LocalizationCatalog
xcodebuild -project patika.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' SWIFT_EMIT_LOC_STRINGS=NO build
```

- [ ] **Step 9: Run a full debug flow**

Walk from C4 through H1 and verify this order:

```text
C4 → D0–D8 → E1 → H2 → F1 → F2 → commitment → G1 → G2 → price → H1
```

Accept notifications once, then repeat with decline. Confirm the OS prompt appears only in the accepted route.

- [ ] **Step 10: Commit**

```bash
git add MyApp/Features/Onboarding MyApp/Content CLAUDE.md Tests/OnboardingInteractionTests/main.swift
git commit -m "feat: reorder onboarding delivery and permission flow"
```

---

### Task 9: Responsive first-step completion and preserved reflection input

**Files:**
- Modify: `MyApp/Features/Onboarding/GFirstSession/SessionCompleteView.swift`
- Modify: `MyApp/Features/Session/AdaptiveQuestionView.swift`
- Modify: `MyApp/DesignSystem/Components/OnboardingTextInput.swift`
- Modify: `MyApp/Content/Localizable.xcstrings`

**Interfaces:**
- Consumes: `OnboardingHeightClass`, `SceneContentPlate`, existing `completeFirstStep` flow API.
- Produces: a no-scroll default G2 layout and input state that survives submission failure.

- [ ] **Step 1: Move reflection text ownership to the parent**

Change `AdaptiveQuestionView` to accept a binding:

```swift
struct AdaptiveQuestionView: View {
    @Binding var answer: String
    let question: String
    let isSubmitting: Bool
    let showsError: Bool
    var onSave: (String) -> Void
    var onSkip: () -> Void
}
```

Add `@State private var answer = ""` to `SessionCompleteView`. This guarantees a failed submit cannot recreate the child and lose the value.

- [ ] **Step 2: Recompose G2 by height class**

Use one `GeometryReader` and the environment height class:

- Comfortable: 132–152 pt illustration.
- Compact: 88–104 pt illustration and reduced stack spacing.
- Scroll required/AX: omit decorative illustration and allow vertical scroll.

Wrap headline/body/question/input in one `SceneContentPlate`. Keep CTA/skip inside the plate so all text has measured contrast.

- [ ] **Step 3: Keep error copy calm and preserve the field**

Retain the existing `session.reflectionError` if it already says the text was not lost and the failure was not the user's fault. Otherwise update it to that exact meaning. Never clear `answer` on failure.

- [ ] **Step 4: Build and visually verify**

```bash
xcodebuild -project patika.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' SWIFT_EMIT_LOC_STRINGS=NO build
xcrun simctl launch booted com.tanercelik.Patika -patika-debug-step g2
```

Check default, compact height, keyboard open, AX5, completed, left-early, and forced network failure states.

- [ ] **Step 5: Commit**

```bash
git add MyApp/Features/Onboarding/GFirstSession/SessionCompleteView.swift MyApp/Features/Session/AdaptiveQuestionView.swift MyApp/DesignSystem/Components/OnboardingTextInput.swift MyApp/Content/Localizable.xcstrings
git commit -m "fix: make first-step completion fit and preserve input"
```

---

### Task 10: Full verification, rendered contrast audit, and cleanup

**Files:**
- Modify: `Tests/ContrastTests/main.swift`
- Modify: `docs/superpowers/specs/2026-09-22-onboarding-responsive-interaction-redesign-design.md` only if implementation revealed a documented mismatch.
- Modify: `CLAUDE.md` only for final verified status and exact deviations.
- Delete: `MyApp/DesignSystem/Components/CommitmentSlide.swift` after confirming no consumers.
- Delete: unused time/weather artwork registration only after `rg` confirms no consumers.

**Interfaces:**
- Consumes: all previous tasks.
- Produces: verified, documented, warning-clean onboarding implementation.

- [ ] **Step 1: Remove dead components and strings**

Run:

```bash
rg -n 'CommitmentSlide|DualStatementSlider|onboarding-b-weather|holdToStartHint|commitment.slide' MyApp Tests
```

Delete only zero-consumer components/assets/keys. Keep `DualStatementSlider` if another feature still uses it.

- [ ] **Step 2: Run all command-line tests**

```bash
bash scripts/run-swift-tests.sh
```

Expected: every registered suite passes. Report the pre-existing stale `JourneyRoutePatternTests` comment separately; do not count it as a newly executed test.

- [ ] **Step 3: Run the clean simulator build**

```bash
xcodebuild -project patika.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' SWIFT_EMIT_LOC_STRINGS=NO build
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Confirm localization integrity and exact-age privacy**

```bash
bash scripts/run-swift-tests.sh LocalizationCatalog
rg -n 'selectedAge|exactAge|birthYear' MyApp/Features/Onboarding MyApp/Infrastructure/Backend MyApp/Infrastructure/Observability
git diff -- MyApp/Content/Localizable.xcstrings
```

Expected: no exact-age persistence/payload/analytics path and only intentional catalog entries.

- [ ] **Step 5: Verify device matrix**

On a short-height iPhone, iPhone 17 Pro, and large Pro Max, verify default and AX5. On iPhone 17 Pro also verify Reduce Motion, Reduce Transparency, Increase Contrast, VoiceOver, and landscape fallback.

Capture at minimum:

```text
identityAge, B2, B3 morning/night, B5 Other closed/open,
B6 heaviest/lightest, D1, D2, D8, E1 day/night, H2,
F2, commitment empty/drawn/holding/message, G2 keyboard/error
```

- [ ] **Step 6: Audit rendered contrast**

If an XCTest target is still unavailable, render the listed screens in simulator, sample the darkest/lightest text regions, and record ratios in `CLAUDE.md` with the exact device/state. Do not claim automated image contrast coverage unless an actual ImageRenderer/XCTest path was added and run.

- [ ] **Step 7: Confirm no black transition frame or footer band**

Screen-record rapid B3 and B6 selection changes plus F2→commitment→G1. Review frame-by-frame for fallback/black flashes and confirm the scene fills the bottom safe area throughout.

- [ ] **Step 8: Update verified status**

In `CLAUDE.md`, record the commands actually run, pass counts, simulator/device matrix, accessibility states, asset names, and any approved deviation from the spec. Do not mark untested gestures as verified.

- [ ] **Step 9: Review working tree and commit final cleanup**

```bash
git diff --check
git status --short
git diff --stat
git add CLAUDE.md MyApp Tests docs scripts assets
git commit -m "test: verify responsive onboarding redesign"
```

Do not stage unrelated user changes.

---

## Completion Gate

Do not declare the feature complete until all of the following are true:

- The full approved route runs from C4 through H1 in both notification accept and decline paths.
- Default text fits typical iPhones without required scrolling; short-height/AX layouts scroll safely.
- The footer black band is gone and no scene transition exposes black.
- Exact age maps to `AgeRange` and is absent from persistence/network/analytics.
- B2/B3 are direct choices, B5 Other is crisis-screened, and B6 has no weather metaphor.
- D1 endpoints and D2–D8 choices are fully visible and meet measured contrast.
- F2 is compact and never auto-scrolls.
- Signature data is protected, local-only, accessible without dragging, and deleted with local/account data.
- Hold feedback begins immediately, canceling never advances, and the day-one message appears before G1.
- G2 preserves reflection text on error.
- All registered Swift tests pass and the iPhone 17 Pro build succeeds with localization emission disabled.
