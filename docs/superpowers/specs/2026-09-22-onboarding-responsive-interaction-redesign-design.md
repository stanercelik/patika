# Onboarding responsive interaction redesign

**Date:** 2026-09-22  
**Status:** Approved  
**Scope:** Native iOS onboarding layout, selection controls, scene feedback, measurement readability, reminder permission placement, path delivery, commitment signature, and first-session completion.

## 1. Objective

Refine the current woodland onboarding so it remains readable and complete across iPhone sizes, gives immediate and meaningful feedback to user choices, and removes interactions that feel like work or require unnecessary scrolling.

The redesign keeps the current product boundaries:

- The app is an 18+ measured wellbeing program, not therapy, diagnosis, or clinical assessment.
- The eight baseline questions remain intact and use the same answer instrument during later measurements.
- B1, B4, and every newly introduced free-text input remain crisis-screened.
- Notification permission is requested only after an in-app explanation and explicit opt-in.
- There is no onboarding paywall. The existing price-transparency screen remains informational.
- No emoji, gradients, fabricated claims, social proof, urgency, streaks, or guilt language are introduced.

## 2. Approved direction

Use a **living but calm scene system**. Existing full-screen gouache scenes remain the visual foundation. Selection state changes a limited number of scene variants or overlays instead of creating a combinatorial asset set for every category and state.

This direction was chosen over:

1. A fully cinematic asset matrix, which would create excessive asset weight and maintenance cost.
2. A component-only treatment, which would be lighter but would not provide the requested feeling that the world responds to the user.

The design must preserve the same composition during state changes. Light, haze, buds, lanterns, and similar environmental details may change, but the scene must not jump to a different location.

## 3. Responsive onboarding shell

### 3.1 Layout contract

The onboarding shell continues to own the background, top bar, progress trace, and step transition. Individual screens do not draw their own header.

The content area resolves into one of three height tiers:

- **Comfortable:** Default layout for modern iPhones with full artwork and standard spacing.
- **Compact:** Reduced artwork height and spacing while preserving type roles and 44 pt touch targets.
- **Scroll required:** Used only when the content genuinely cannot fit, including short-height devices, landscape, keyboard presentation, or accessibility Dynamic Type.

At the default text size, all redesigned screens except free-text-with-keyboard states should fit without scrolling on typical iPhones. Scroll views may remain in the hierarchy for safe fallback, but they must not create visible bounce or an apparent scroll affordance when content fits.

### 3.2 Bottom action area

Remove the full-width dark footer backdrop that currently reads as a black horizontal band. The scene must continue through the bottom safe area and behind the home indicator.

The CTA remains visually independent through its own opaque capsule or local surface. Footer content must not paint an unrelated full-width black region over the scene. Any local readability surface must be limited to the control that needs it.

The CTA remains inside a safe-area inset so it stays clear of the home indicator and keyboard. Scrolled content receives a matching bottom content inset and is never hidden behind the CTA.

### 3.3 Scene transitions

Scene changes use a two-layer crossfade:

1. Keep the outgoing scene visible.
2. Insert the incoming scene above it at zero opacity.
3. Fade the incoming scene in while fading the outgoing scene out.
4. Remove the outgoing scene only after the transition completes.

The fallback background must sit below both scene layers, not between them. This prevents a black or flat-color frame from appearing during a swap.

The transition uses the shared scene timing token and is interruptible. A new selection supersedes an in-progress transition without flashing. Reduce Motion removes spatial or blur animation and uses a clean state replacement or short opacity-only crossfade according to system accessibility preference.

### 3.4 Readability surfaces

Introduce a semantic `SceneContentPlate` for scene-backed content that cannot rely on the artwork's local luminance. It is a largely opaque deep woodland surface with token-driven text, border, and selected states. It is not a material blur and does not use a gradient.

Use it for:

- Measurement questions and choices.
- The compact path summary.
- First-step reflection input.
- Any scene-backed option group whose real composite contrast fails.

Primary and secondary text must meet 4.5:1 for normal text against the composed plate. Large display text must meet at least 3:1. Controls and meaningful icons must meet 3:1 against adjacent colors. Contrast is measured against rendered scenes, not inferred from raw color constants.

## 4. Identity age selection

### 4.1 Interaction

Replace the age-range slider with a vertical wheel covering ages 18 through 100. The selected age is centered, larger, and fully sharp. Adjacent values progressively reduce in scale and opacity and receive a restrained depth blur as they move away from the center.

`Prefer not to say` remains a separate visible option outside the wheel. There is no default selection. Selection does not auto-advance; the user confirms with the bottom action.

### 4.2 Data minimization

The exact displayed age is ephemeral UI state. On commit, map it into the existing `AgeRange` domain value:

| Selected age | Stored value |
|---|---|
| 18–24 | `eighteenToTwentyFour` |
| 25–34 | `twentyFiveToThirtyFour` |
| 35–44 | `thirtyFiveToFortyFour` |
| 45–54 | `fortyFiveToFiftyFour` |
| 55–100 | `fiftyFivePlus` |

The exact age is not stored in `OnboardingDraft`, SwiftData, analytics, or backend requests. `Prefer not to say` stores `undisclosed`.

VoiceOver exposes the wheel as an adjustable control with the selected age as its value. Switch Control and VoiceOver users can increment or decrement without dragging.

## 5. Problem-discovery interactions

### 5.1 B2 duration

Replace the dual-statement slider with direct options:

- A few days
- A few weeks
- A few months
- Years
- I’m not sure

The first four appear as a compact 2×2 card grid. `I’m not sure` is a full-width row beneath the grid because it is an escape answer rather than a point on the duration continuum.

Each card preserves at least a 44 pt touch target and exposes selected state through border, symbol or checkmark, and text—not color alone. Selection may subtly extend a path detail in the scene, but that reaction is decorative and hidden from VoiceOver. Selection does not auto-advance.

The domain values and path-length rules remain unchanged.

### 5.2 B3 occurrence timing

Remove the static time-of-day illustration. Present direct options for:

- Morning
- During the day
- Evening
- Bedtime
- No clear pattern

The first four form a compact time strip or adaptive 2×2 grid. `No clear pattern` is a separate full-width option.

The background keeps one composition and changes among morning, daytime, evening, and nighttime lighting states. Light, sky, window, and lantern details may respond. `No clear pattern` uses a neutral overcast or balanced state rather than implying a specific time.

The visual change combines a direct scene crossfade with a brief, restrained focus softening. It never fades through black. Reduce Motion removes the focus animation.

The selected `ProblemTiming` continues to determine the suggested E1 reminder time.

### 5.3 B5 previous attempts and Other

Replace the long vertical list with an adaptive two-column selection layout. Labels may wrap, but no text truncates. At the default text size the full option set and CTA must fit on a typical iPhone.

Existing rules remain:

- Multiple attempts may be selected.
- `Nothing` is exclusive and clears all other selections.
- Choosing another option clears `Nothing`.
- Ongoing therapy shows the compact therapy-aware boundary note.
- Selecting another meditation app continues to control the later comparison step.

Selecting `Other` reveals a labeled single-line input inside or immediately below the Other card. Keyboard presentation may enable scrolling. When `Other` is deselected, its text is cleared.

Add `previousAttemptOtherText` to the temporary onboarding draft and device-side problem record. Before commit, trim and run it through the same on-device crisis prefilter used for B1 and B4. A signal immediately enters the crisis flow and prevents path generation, measurement continuation, notification permission, account, and pricing steps.

The raw Other text is not sent to analytics or the path-generation model. It remains device-only until a separate encrypted server contract and server-side crisis classification are explicitly designed.

### 5.4 B6 current mood

Remove weather symbols and weather language. Present five labeled, tappable stones on a compact path. The selected label remains visible and each stop has a minimum 44 pt target.

The same scene composition responds across five states:

- Heavier states use denser haze, quieter light, and closed buds.
- Middle states use balanced visibility and neutral light.
- Lighter states use clearer depth, warmer light, and open buds.

Do not use dead, broken, or decaying plants to represent the user. The scene expresses weight and openness, not good and bad. Text and selection marks carry meaning independently of color and artwork.

Tap selection remains available alongside optional drag-across behavior. Dragging is never the only way to answer.

## 6. Baseline measurement D1–D8

### 6.1 Shared instrument

`MeasurementAnswerView` remains the single answer surface used by onboarding baseline and day 7/14/final measurements. Any control redesign is made there so the comparison instrument does not diverge across time points.

The clinical disclaimer remains present on every measurement screen. No default answer or baseline score is shown.

### 6.2 D1 intensity

The full `None` and `Very strong` endpoint labels must remain within horizontal content margins. The 0–10 stops must expose at least 44 pt effective targets through expanded hit regions even if their visual bars are narrower.

The selected value is repeated as readable text, not expressed only by bar height or color. Empty state remains truly unanswered.

### 6.3 D2–D8 choices

Keep the existing bucket wording and value mapping. Use compact, high-contrast rows inside `SceneContentPlate`:

- Full-opacity primary label text.
- Visible unselected boundaries.
- Selected state expressed by checkmark or symbol, border, and text weight.
- Stable row geometry when selection changes.

The disabled CTA must remain legible while clearly disabled. Gray-on-gray text and borders are not acceptable.

### 6.4 Fit behavior

At default text size, D1–D8 should fit without scrolling on typical iPhones. Compact mode reduces vertical gaps before changing font roles or touch targets. AX Dynamic Type uses scrolling and never truncates a question or answer.

## 7. E1 reminder and notification permission

### 7.1 Reminder time scene

E1 retains the suggestion derived from B3 and the sentence explaining why it was suggested. As the user changes the time, the same background composition changes continuously or in bounded phases from daylight to evening and night.

The accessible wheel `DatePicker` remains the fallback for VoiceOver and accessibility Dynamic Type. The custom dial may remain for standard presentation if it passes touch and contrast checks.

### 7.2 New placement

Immediately after E1 commit, show the existing in-app notification priming screen. The priming screen displays:

- The selected reminder time.
- A faithful preview of the neutral notification copy.
- The privacy statement that no path name or sensitive topic appears.
- The no-guilt statement that missing a day resets nothing.

Only the affirmative action calls the system notification authorization API. Declining continues onboarding with reminders disabled. The permission is not requested again at the end of onboarding.

The relevant flow becomes:

```text
D8 → E1 reminder → notification priming/system prompt if accepted → F1 generation
```

The final flow no longer includes a second notification priming step.

## 8. Compact path delivery

### 8.1 Path-ready summary

Remove the self-scrolling tour and the onboarding list of all 21 step titles. The onboarding path-ready screen contains:

- Personalized headline.
- Path title.
- Total steps and daily duration.
- The first step.
- Four or five compact phase or milestone nodes.

All content fits on a typical iPhone without user scrolling. The complete step list remains available after onboarding in the `Yolum` screen.

The summary uses `SceneContentPlate` over the path-ready scene. Locked future phases are visually quieter but remain readable. The CTA uses a normal tap and is labeled `Continue`; it does not start the session or require a hold.

### 8.2 No automatic motion

Delete the automatic down/up roadmap tour. The onboarding path summary does not move without user input. This removes scroll-jacking, motion conflict, and the requirement that a user understand a moving screen before acting.

## 9. Promise signature and hold-to-start

### 9.1 Placement

Remove the current pre-measurement commitment step and its slide control. Insert the commitment after the path-ready summary and before G1.

The path-ready CTA opens the promise screen. The flow is:

```text
F2 path ready → Promise/signature → Hold to start → transition message → G1
```

### 9.2 Copy and reflection

If B4 contains the user's own words, reflect that short sentence. Otherwise use B1. If neither exists, do not fabricate a quote. The promise must not guarantee success, recovery, or improvement.

### 9.3 Signature canvas

Provide a bounded drawing area with immediate stroke feedback. The user may clear and redraw before continuing.

Store strokes as normalized point arrays relative to the canvas bounds. Store them only on device in a dedicated signature store. Do not send the points to the backend or analytics. The store may later support rendering a small starting mark in `Yolum`, but that rendering is not required for this implementation.

Freehand drawing is not crisis-classified because it contains no machine-interpreted text. It is treated as private local visual data.

Dragging cannot be the only way to complete the step. Provide a visible `Use a simple mark` action that creates a standard non-biometric mark. VoiceOver and Switch Control expose the same action. `Clear` is labeled and has a 44 pt target.

### 9.4 Hold button

After a signature or simple mark exists, show one CTA whose label is:

`Press and hold to start your path`

Do not repeat this instruction beneath the button.

Use a zero-distance press gesture rather than a delayed long-press recognizer. On touch-down, progress and soft haptic feedback begin within 100 ms. Completion takes approximately 1.2 seconds.

While held, the capsule expands into the screen. Releasing early cancels completion and smoothly restores the button. Cancellation is not an error and produces no warning.

Reduce Motion replaces expansion with an in-place left-to-right fill. Assistive technologies expose a normal accessibility action that completes the intent without requiring a physical hold.

### 9.5 Transition message

After hold completion, keep the completed surface in place and show:

`Let’s begin with day one.`

Keep the message readable for approximately one second, then crossfade into G1. Do not show a black interstitial frame and do not navigate at the instant the hold reaches 100%.

## 10. First-step completion

Recompose G2 using the same height tiers and `SceneContentPlate`:

- Comfortable mode shows the full illustration.
- Compact mode reduces illustration height before reducing content clarity.
- Accessibility mode may omit decorative artwork and scroll.

On typical iPhones, the completion headline, schedule statement, reflection prompt, field, CTA, and skip action fit without scrolling.

The reflection field uses an opaque readable surface. Placeholder and helper text meet contrast requirements. If submission fails, preserve the user's text, keep the screen in place, and state that nothing was lost and the error was not the user's fault.

The completed and left-early headline distinction remains. A session that ended early is not described as completed.

## 11. Flow and domain changes

### 11.1 Step order

The relevant approved step order is:

```text
A1
→ identity name
→ identity gender
→ identity age
→ A2
→ B1–B6
→ C1–C4
→ D0–D8
→ E1
→ notification priming
→ F1
→ F2 compact summary
→ commitment signature
→ G1
→ G2
→ price transparency
→ H1 account
```

The previous commitment position after C4 is removed. The notification priming position after price transparency is removed.

### 11.2 State ownership

`OnboardingFlowViewModel` remains the single flow owner. Step views do not navigate directly and do not know each other.

Suggested boundaries:

- `AgePickerViewModel`: ephemeral exact age and mapping to `AgeRange`.
- `PreviousAttemptsViewModel`: selection, exclusive choice, Other text, validation, and crisis-safe submit.
- `ReactiveSceneState`: domain-to-visual state mapping for B3, B6, and E1.
- `SignatureViewModel`: normalized strokes, clear/simple-mark state, and local persistence result.
- `CommitmentStartViewModel`: hold progress, cancellation, completion message timing, and navigation callback.

View models remain `@Observable @MainActor final class` and do not import SwiftUI. Views own layout and bindings only.

### 11.3 Data flow

```text
UI selection
→ step ViewModel validates/previews
→ OnboardingFlowViewModel commits domain value
→ OnboardingDraft stores only necessary data
→ final persistence occurs at the existing onboarding completion boundary
```

Exact age stops at the age view model. Signature points go to the local signature store, not `OnboardingDraft`. B5 Other text enters the draft only after trim and crisis prefilter.

## 12. Error handling and fallback behavior

- **Notification denial:** Continue onboarding with reminders disabled.
- **Notification API failure:** Keep the explanation screen stable, show a calm retry/continue state, and never loop the system prompt.
- **Scene asset missing:** Use the static woodland background with the same readable surfaces; never show black.
- **Rapid scene selection:** Interrupt and retarget the crossfade without stacking unbounded scene views.
- **Hold cancellation:** Reset progress smoothly and remain on the promise screen.
- **Signature persistence failure:** Keep the in-memory drawing visible, explain that it was not saved, and offer retry or simple mark.
- **Free-text crisis signal:** Enter the existing neutral crisis flow immediately and block all downstream generation, measurement, notification, pricing, and account actions.
- **G2 submission failure:** Preserve the reflection text and communicate that nothing was lost.

## 13. Accessibility

- All touch targets are at least 44×44 pt.
- No selection depends on color alone.
- Decorative scene transitions and overlays are hidden from VoiceOver.
- Every custom drag interaction has a tap or adjustable-control alternative.
- Screen-reader focus follows visual order: headline, hint, answer, primary action, secondary action.
- Dynamic Type uses semantic type roles and supports AX5 without clipping.
- Reduce Motion removes spatial expansion, focus blur, and automatic scene movement.
- Reduce Transparency uses the existing opaque fallback while retaining content plates and state clarity.
- Increase Contrast strengthens plate boundaries and selection marks through semantic tokens.
- The signature canvas has an accessible name, state, Clear action, and simple-mark alternative.
- The hold button exposes a normal accessibility action.

## 14. Asset plan

Avoid a category × mood × time asset matrix.

Required visual states should be limited to reusable sets:

- B3/E1 time-of-day states sharing one composition: morning, daytime, evening, night, neutral/no-pattern.
- B6 mood states sharing one composition: five haze/light/bud states.

Prefer reusable transparent overlays when they preserve the gouache style and composite cleanly. Use full scene variants only where lighting cannot be achieved without visible compositing artifacts.

All raster assets must be sized for the actual phone render budget and loaded through the asset catalog. Missing variants must have a deterministic fallback. No image generation is required until the implementation plan identifies an actual missing state that cannot be built from existing art.

## 15. Verification

### 15.1 Automated checks

- Every age 18–100 maps to the expected `AgeRange`.
- Exact age never appears in persistent models, backend payloads, or analytics.
- B5 `Nothing` exclusivity remains correct.
- Deselecting Other clears its text.
- B5 Other text is trimmed and crisis-screened before commit.
- Notification authorization is called only after E1 priming opt-in and at most once in onboarding.
- Approved step order is enforced, including the moved commitment and priming steps.
- Signature coordinates normalize and denormalize within tolerance.
- Signature data is written only to the local store.
- Releasing the hold before completion never advances.
- Hold completion shows the transition message before G1.
- D1–D8 continue using the shared answer view for baseline and later measurements.

### 15.2 Visual and interaction matrix

Verify on:

- Short-height/small iPhone.
- iPhone 17 Pro.
- Large Pro Max phone.
- Portrait and landscape fallback.
- Default Dynamic Type and AX5.
- Reduce Motion.
- Reduce Transparency.
- Increase Contrast.
- VoiceOver.

For each state, verify:

- No bottom black band or uncovered safe area.
- No horizontal overflow.
- Default-size content fits without scrolling on typical phones.
- Scroll fallback reveals every control when required.
- Footer does not cover content or keyboard focus.
- D1 endpoint labels are fully visible.
- D2–D8 option text is readable before and after selection.
- F2 summary fits without auto-scroll.
- Direct scene-to-scene crossfade never exposes black.
- Tap, drag, hold, cancellation, and accessibility alternatives all respond immediately.

### 15.3 Contrast verification

Render real scene composites with `ImageRenderer` and sample the regions behind text and controls. Tests fail when:

- Normal text is below 4.5:1.
- Large text is below 3:1.
- Meaningful control boundaries or icons are below 3:1.

Value-only token tests remain useful but do not replace rendered composite tests.

## 16. Out of scope

- RevenueCat paywall implementation or offering configuration.
- Changes to pricing or subscription segmentation.
- Changing the eight baseline questions or scoring weights.
- Sending the signature to the backend or analytics.
- Persisting exact age.
- Showing all 21 path steps during onboarding.
- Android, web, social features, chatbot, or therapist marketplace work.
- Broad visual redesign of post-onboarding tabs beyond the optional future display of the local starting mark.

## 17. Acceptance criteria

The redesign is complete when:

1. The approved flow order is implemented without duplicate commitment or notification steps.
2. Standard iPhones show the redesigned screens without required scrolling at default text size.
3. Small-height and accessibility layouts remain fully operable through deliberate scroll fallback.
4. No onboarding screen shows the current bottom black band.
5. Scene changes crossfade directly without black frames.
6. Exact age is selectable but only the mapped age range persists.
7. B2 and B3 use direct choices, B5 supports screened Other text, and B6 no longer uses weather metaphors.
8. D1 endpoints and all D1–D8 choices are fully readable and meet contrast requirements.
9. Notification priming follows E1 and the system prompt appears only on explicit opt-in.
10. F2 is a compact, non-auto-scrolling summary; the full path remains in `Yolum`.
11. The commitment occurs after F2, accepts a local signature or accessible simple mark, and starts through an immediately responsive hold.
12. Hold completion shows `Let’s begin with day one.` before G1.
13. G2 is readable, preserves user input on failure, and fits the responsive shell.
14. Automated and visual verification passes for the matrix in Section 15.
