# Onboarding redesign — woodland language, expressive inputs, restructured flow

> **Partially superseded (22 Sep 2026).** The product owner removed gradients app-wide;
> see `CLAUDE.md`'s "22 Eylül 2026 — gradyan kaldırıldı" entry for the full decision log.
> This invalidates every mention below of `BreathingMeshBackground` "at full strength",
> the category palette, A2/B6 staying on live mesh because "the background is content",
> and the merged three-screen identity card (`IdentityView`) — identity is three separate
> screens again (`NameView`, `GenderView`, `AgeRangeView`). The paper-vs-ground split this
> document introduces is still correct in spirit; it's now paper-vs-**scene** (a full-bleed
> gouache image replaces the mesh everywhere, including A2/B6, whose "content" is now a
> per-category scene rather than a live-tinted mesh).

## Context

The app's visual language moved on twice (Discover v2, Me v2, Path) and onboarding never
followed. Everything built after 17 Sep 2026 uses the **three-layer woodland system** —
ground (gouache landscape) → paper (cream `#EDE7D9`) → glass (navigation only) — while all 29
onboarding screens still use the original dark `CalmSurface` language. A user walks through
five minutes of one product and lands in a different-looking one.

Second: 20 of the questions are asked as flat vertical option-lists. Nine screens are the same
control repeated. The questions are good; the way they're asked reads as a survey.

Third: the C section reveals paragraphs one at a time at 1.5 s intervals. The product owner is
reversing that decision — the waiting reads as the app being slow.

Fourth: the generated voice — the aha moment — doesn't reliably play, due to a race in
`FirstSessionViewModel`.

**Scope was widened by the product owner (this session):** screens may be merged, cut and
added; price transparency may appear inside onboarding; gamification is permitted in
onboarding. Target shape ~30 screens. Two constraints stay, and not for taste reasons:
**no fabricated testimonials or user counts** (deceptive; App Store review and consumer-
protection law both bite — real numbers the moment they exist), and the **crisis path stays
intact** (health-category review requirement). The baseline measurement keeps all 8 items.

---

## Design direction

| Layer      | Onboarding use                                    |
| ---------- | ------------------------------------------------- |
| **Ground** | `BreathingMeshBackground` at **full strength**.   |
| **Paper**  | Cream `paperSurface()` for reading and answering. |
| **Scene**  | Full-bleed gouache for the moment screens.        |

### The one thing this migration can break

Me dims the mesh to `opacity(0.16)` (`MeView.swift:50`) and Discover dims its ground to `0.58`
(`DiscoverView.swift:101`) — both because there the background is _decor_. In onboarding the
background is **content**: it is the entire payoff of A2 (category palette) and B6 (mood
modulation). Cream at ~86% lightness next to a saturated mesh makes the mesh read as noise,
and inheriting either prior composition would make the palette response invisible.

**So onboarding gets a third composition the app doesn't have yet: full-strength mesh as
ground, paper only as the answer surface.** Screens are assigned a tier:

| Tier       | Screens                                                               | Treatment                                    |
| ---------- | --------------------------------------------------------------------- | -------------------------------------------- |
| **Paper**  | identity, b1, b2, b3, b4, b5, c1–c4, d0, e3, commitment, price, H1/H2 | Cream card, ink `#203C36`                    |
| **Ground** | **a2, b6**, d1–d8                                                     | Control sits directly on the mesh, light ink |
| **Scene**  | a1, f1, f2, g2                                                        | Gouache ground replaces the mesh             |

A2 and B6 are deliberate, visible exceptions: A2's grid never fills the screen so the mesh
stays the field around it, and B6's answer _literally drives_ the background — putting a card
in front of that severs cause from effect.

**Argue the migration from contrast, not taste.** `Theme.minimumContrast` and
`minimumContrastLargeText` exist and nothing reads them; CLAUDE.md promises a CI contrast test
for "55 palette×screen combinations" that was never written. Ink-on-paper is a fixed ~9.5:1
regardless of palette, collapsing that combinatorial problem down to the handful of
ground-tier screens.

---

## Part 1 — The new flow shape

29 → ~30 screens. Every question that drives product behaviour is kept.

| Change                                      | Rationale                                                                                                                                                                                                                                                                                                                         |
| ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Merge identity ×3 → 1**                   | Gender and age change _nothing_ in the product (documented in `DomainEnums`). Two full screens each for a statistic is the weakest ratio in the flow. One paper card: name, then gender and age revealed progressively. **−2**                                                                                                    |
| **Add a commitment moment** after C4        | Now that gamification is permitted. A slide-to-commit gesture over the user's own stated goal. This is the flow's strongest unused conversion device and it costs no server change. **+1**                                                                                                                                        |
| **Add price transparency (F4)** after G2    | The PRD designed F4, then orphaned it when F2 began launching G1 directly. Its own preferred new home is "after G2, before H1". Honest framing: nothing is charged now, here is what it costs on day 7. **Not a hard paywall** — StoreKit isn't built, and asking for money before day 7 contradicts the Bucket C promise. **+1** |
| **Add notification priming (H2)** before H1 | Fully specified in the PRD §9, never built. A real notification preview, the privacy guarantee, and the no-guilt promise. `UNUserNotificationCenter.requestAuthorization` fires only on opt-in. **+1**                                                                                                                            |
| **Keep D0–D8 as 9 screens**                 | Product owner's decision. Redesigned to feel fast, not made shorter.                                                                                                                                                                                                                                                              |
| **Keep C3 conditional**                     | Unchanged.                                                                                                                                                                                                                                                                                                                        |

Net 29 − 2 + 3 = **30**.

Each added screen needs a case in `OnboardingStep`, a `progress`, a `breathAmplitude`, a
`backgroundSafeY` and a `surfaceStyle` (Part 2.2), plus routing in `OnboardingFlowViewModel`.
The identity merge removes two cases and their transitions.

---

## Part 2 — Foundation

### 2.1 `CalmSurface` stays exactly as it is

The blast radius is not what it looks like. `MyApp/Features/Path/PathSessionView.swift` — the
**mid-audio-session** screen — consumes six of the things being redesigned:
`OnboardingStatementLayout` + `StatementParagraph` (`:89`), `sequentialReveal` (`:95`, `:100`),
`OnboardingQuestionLayout` (`:217`), `IntensityScale` (`:222`), `ChoiceRow` (`:226`),
`OnboardingQuestionFooter` (`:248`).

**Restyling `CalmSurface` in place is precisely the edit that puts a cream card in the middle
of a running meditation.** Don't. Also don't mark it deprecated — that emits warnings at the
call sites that are meant to keep it.

Instead: add `PaperChoiceRow.swift` (a paper twin, plus a `PaperSelectionMark` — the existing
`SelectionMark` is white-on-dark and also used by `CategoryCard`), and rescope `CalmSurface`'s
doc comment to "legacy dark language — session and ground-tier surfaces". `CalmSurface` and
the paper surface are the two halves of a two-material system, which is what
`PatikaSurface.swift` already describes. It may legitimately never be deleted.

### 2.2 The seam: an environment value, not parameters

1. Add `OnboardingSurfaceStyle` (`.ground` | `.paper` | `.scene`) and an
   `EnvironmentValues.onboardingSurface` key **defaulting to `.ground`**.
2. Add `var surfaceStyle: OnboardingSurfaceStyle` to `OnboardingStep`, as a sibling of the
   existing `backgroundSafeY` and `breathAmplitude` switches
   (`OnboardingFlowViewModel.swift:106`, `:131`). This is already the codebase's pattern:
   per-step visual policy lives on the enum and the container only reads it.
3. `OnboardingContainerView` sets the environment from `flow.step.surfaceStyle`.
4. Both shared layouts read it and wrap their content accordingly. **The 20 call sites don't
   change**, and the A2/B6 exception costs one line in one switch.

**The `.ground` default is the whole de-risking move**: `PathSessionView` never sets the
environment, so it keeps today's look for free — no branch, no duplicate layout, no flag to
forget.

### 2.3 The 6 custom screens

Don't force `a1`, `f1`, `f2`, `g1`, `g2`, `h1` into the shared layouts — they're custom for
logged reasons (F1 deliberately has no button; F2 needs `HoldToStartButton` + the auto-tour;
G1 is a session stage).

Instead extract an `.onboardingScreen()` modifier owning what they each re-implement:
horizontal `Theme.Spacing.screenMargin`, the duplicated `ScrollView` configuration
(`.scrollIndicators(.hidden)`, `.scrollBounceBehavior(.basedOnSize)`,
`.scrollDismissesKeyboard(.interactively)`), the bottom inset, and the surface environment.
Drift then costs a _missing modifier_, visible in a diff, rather than a missing redesign.

**Anti-drift:** add a DEBUG-only gallery preview rendering all ~30 steps through the existing
`OnboardingPreviewHost` (`OnboardingContainerView.swift:171`). One canvas showing every screen
catches drift better than any lint rule.

**Do not lose:** `OnboardingQuestionFooter`'s reserved 44 pt escape row
(`OnboardingQuestionLayout.swift:88`, `:109`) including its accessibility-size branch. That's
a documented fix for the CTA jumping between B2 and B4.

### 2.4 `backgroundSafeY` will silently rot

`OnboardingStep.backgroundSafeY` feeds the Metal `grainAndScrim` shader, which darkens a band
so light text is readable there. Under a paper card that scrim is invisible, and its only
remaining effect is dimming the mesh — eroding the very A2/B6 payoff this plan protects.
Retune per step (paper screens want `scrimStrength` near 0) or redefine the switch. Don't
leave 20 values that no longer correspond to anything.

### 2.5 Measurement: the instrument must stay identical across time points

`PathSessionView.swift:201` defines `PathMeasurementQuestionView`, a near-duplicate of the
onboarding measurement view driving the _same_ `MeasurementQuestionViewModel`. Onboarding
collects the baseline; that one collects day 7, day 14 and final.

**Changing the D-screen control in onboarding only would be a measurement bug, not a cosmetic
inconsistency.** Baseline would be captured through one control and follow-ups through
another, so part of any day-7 "improvement" would be an artefact of the changed instrument —
inside the single comparison the product's core promise rests on.

Therefore: measurement screens are **ground tier in both places**, and the answer area is
extracted into one shared view used by both call sites. This is not scope creep; it is the
minimum for the D-screen change to be safe at all.

---

## Part 3 — Motion: removing the C-section wait

`Theme.Motion.revealStagger = 1.50` drives `sequentialReveal`, used across 7 files (C1–C4, D0,
`OnboardingStatementLayout`, and `PathSessionView`). `listReveal` (0.11 s) is independent and
unaffected.

**Don't add a faster token and don't just lower the number** — lowering it to ~0.1 makes it a
duplicate of `listRevealStagger`, and a second token means a permanent judgement call at every
new call site.

**Switch the C section to the existing `woodlandReveal`** (`Components/WoodlandReveal.swift`),
which is already the entrance used by Discover and Me: opacity 0.65→1, 6 pt offset,
`0.045s × min(index, 5)`. The cap matters — C1's paragraph count is _dynamic_
(`MirroringComposer.paragraphs`), which is exactly why an uncapped stagger was dangerous there.

- C4 needs no new chart code: `ExpectationCurveChart(startsImmediately: true)` already exists.
- `PathNotLibraryView.swift:35`'s index arithmetic becomes pointless once capped; collapse it.
- Afterwards `revealStagger` has two consumers left (D0, `PathSessionView`). Decide those
  separately; if both follow, delete `revealStagger` and `sequentialReveal` entirely.

> **The hazard here is process, not code.** The 1.5 s value carries a dated rationale in three
> places — `Theme.swift:173`, `Theme.swift:333` and `CLAUDE.md`. This repo treats doc comments
> as a decision log. Rewrite all three, with the new date and reasoning, **in the same commit**,
> or the next person restores it.

---

## Part 4 — New input components

All in `MyApp/DesignSystem/Components/`, following the `IntensityScale` / `MoodScale` /
`ChoiceRow` conventions: never `@Binding` (always `let selection: X?` + `onSelect`), no default
selection, `Theme.softHaptic()` fired inside the component, `@ScaledMetric` for every fixed
dimension, `accessibilityAdjustableAction`, reserved space for the readout, and a `#Preview`
over `BreathingMeshBackground`.

**`TickRuler.swift`** — build first. `steps`, `selection: Int?`, `onSelect`, low/high labels,
`ink: PatikaInk`. Then make `IntensityScale` a thin preconfigured wrapper over it, so D1 and
the in-session D1 keep byte-identical behaviour while new screens get the richer control. Use
`PatikaInk` (`PatikaSurface.swift:49`) rather than a bool — it's the established way to make
one component work on both materials.

**`DualStatementSlider.swift`** — generic over `OnboardingChoice`, mirroring `ChoiceList`.
**It must emit a bucket, not a float**: the server contract is enumerated, and a continuous
value would need a mapping layer — the first way this redesign could break the payload.

> **Audit every enum before slider-izing it.** `ProblemDuration` has `.unsure`, which cannot
> sit on a continuum. Escape options stay a separate tappable row _below_ the slider, never a
> stop on it.

**`CommitmentSlide.swift`** — the new commitment moment. Slide-to-commit over the user's own
goal. Reuse `HoldToStartButton`'s haptic ramp and its Reduce Motion fallback (fill instead of
growth), and its VoiceOver treatment (activates as a plain button, since assistive tech
produces no drag).

**`RadialClockDial.swift`** — B3 and E1. `hour`/`minute` as `Int`s, not `Date`
(`commitReminder(hour:minute:)` already converts at the boundary; a `Date` inside a dial
invites timezone bugs), plus `suggestionHour` to show where B3's suggestion sits on the ring.

> **Flagging this one.** E1's job is to _confirm_ a suggestion derived from B3 — today that's
> one tap. A dial turns a one-tap confirmation into a manipulation task and carries the worst
> accessibility burden of the four. Recommendation: build it as a _readable_ dial showing where
> the suggested time falls in the day, with confirm still one tap and dragging optional. If
> schedule slips, this is the second thing to cut.

**Gesture multi-select** — _cut candidate, build last._ A `DragGesture(minimumDistance: 0)`
over a grid inside a vertical `ScrollView` will either steal scrolling or be stolen by it, and
drag-across is invisible to VoiceOver, Switch Control and Voice Control. If built, it is
strictly an overlay on an already-tappable grid (`CategoryCard` is already correct), gated
behind a long-press.

---

## Part 5 — Screen by screen

| Screen                 | Tier       | Change                                                                                                                                                                                                                                                                                  |
| ---------------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A1 Welcome**         | Scene      | Delete `PathDrawAnimation.swift` (152 lines, one consumer). Full-bleed gouache, bottom-anchored headline + CTA. **Must fall back to bare mesh + headline + CTA when the art is absent** — "one line over nothing" is a broken screen, so A1 is the one slot needing a non-art fallback. |
| **Identity (merged)**  | Paper      | One card: name in `Theme.Voice.user` serif (it's the user's own word), then gender chips and an age `TickRuler` revealed progressively. Skip-name still closes nothing.                                                                                                                 |
| **A2 Categories**      | **Ground** | Keep grid, max-2, live palette preview. Cards restyled, mesh stays the field.                                                                                                                                                                                                           |
| **B1 / B4 text**       | Paper      | Journal-idiom writing surface. Autocorrect stays **off** (these words are replayed in G1). No counter.                                                                                                                                                                                  |
| **B2 Duration**        | Paper      | `DualStatementSlider`; `.unsure` as a separate row beneath.                                                                                                                                                                                                                             |
| **B3 Timing**          | Paper      | `RadialClockDial`, feeding E1's suggestion.                                                                                                                                                                                                                                             |
| **B5 Attempts**        | Paper      | Paper chips; exclusive-option rule and therapy note preserved.                                                                                                                                                                                                                          |
| **B6 Mood**            | **Ground** | Continuous drag across the five detents, mesh recoloring live under the finger.                                                                                                                                                                                                         |
| **C1 Mirroring**       | Paper      | The emotional peak. User's sentence via the existing `UserQuote` component. `woodlandReveal`.                                                                                                                                                                                           |
| **C2 / C3 / C4**       | Paper      | `woodlandReveal`. `ComparisonColumns` and `ExpectationCurveChart` keep their one-ink, no-number rules.                                                                                                                                                                                  |
| **Commitment** _(new)_ | Paper      | `CommitmentSlide` over the user's own goal. No fabricated pledge list — the commitment is to themselves, in their words.                                                                                                                                                                |
| **D0 + D1–D8**         | **Ground** | D1 keeps `IntensityScale`; D2–D8 move to `TickRuler` **in both onboarding and Yolum together** (Part 2.5). Clinical disclaimer stays. **No defaults anywhere** — render with no thumb until first touch.                                                                                |
| **E1 Reminder**        | Paper      | `RadialClockDial` pre-filled from B3, reason line kept, wheel retained as the accessibility path.                                                                                                                                                                                       |
| **E3 Tone**            | Paper      | `DualStatementSlider` showing a real sample sentence per tone. No pre-selection.                                                                                                                                                                                                        |
| **F1 Generation**      | Scene      | Keep the trail and the real ~11 s timing. Still the only screen with no tap target.                                                                                                                                                                                                     |
| **F2 Roadmap**         | Scene      | `JourneyMapRow` already matches. Wire the real F2 illustration. Keep `HoldToStartButton` + auto-tour.                                                                                                                                                                                   |
| **G1 First session**   | —          | Already house language. Import the missing session art (Part 7), fix the audio race (Part 6).                                                                                                                                                                                           |
| **G2 Complete**        | Scene      | Two headline states preserved — "left early" must still not say "done". Surface the genuinely earned `badge-first-step` here (gamification now permitted; the badge already exists and is real).                                                                                        |
| **Price (F4)** _(new)_ | Paper      | What it costs, when, and that nothing is charged today. No countdown, no discount, no urgency.                                                                                                                                                                                          |
| **H2 Priming** _(new)_ | Paper      | Real notification preview, privacy guarantee ("never says what you're working on"), no-guilt promise. `.active` interruption level only; no `.provisional`.                                                                                                                             |
| **H1 Account**         | Paper      | Apple primary. Adopt `.onboardingScreen()`.                                                                                                                                                                                                                                             |

---

## Part 6 — Make the first-session voice actually play

**The bug.** `MyApp/Features/Onboarding/GFirstSession/FirstSessionViewModel.swift:~115`:

```swift
if status == .failed || status == .pending { return }
```

`prepareFirstStepAudio()` (`OnboardingFlowViewModel.swift:471`) is deliberately fire-and-forget
and fires at F1. If the user reaches G1 before that request lands, the step is still
`.pending` — and the poll loop treats `.pending` as terminal and gives up permanently. The
session runs silent forever, which reads as "the voice is broken".

`AudioStatus` is `pending / processing / ready / failed`, where `pending` means _not requested
yet_ — transient on this path, not terminal.

**Fix:** treat `.pending` as "keep waiting" inside the existing 45 s deadline, and have G1
request generation itself if the step is still pending after the first poll (idempotent via
`Idempotency-Key`, so a duplicate is safe). `.failed` stays terminal. The silent fallback must
survive — a genuine failure still yields a complete session.

This is why the live smoke test passes while the app doesn't: `scripts/live-smoke-audio.py`
requests audio _before_ polling, so it never hits the race.

**Also:** G1's `preparing` state is currently the bare word "Preparing" between two spacers —
exactly what the user stares at during the wait this bug makes permanent. Give it the
breathing mesh at session amplitude and one calm line. No quota cost.

---

## Part 7 — Art

**Two finished sets are already paid for and unused. Do these first — no generation needed:**

1. **Four session illustrations were never imported.**
   `assets/illustrations/session/session-{trailhead,relief,practice,closing}.png` (1–2 MB each)
   have no imageset, so `SessionArtwork` renders **nothing** in G1 _and_ every Yolum session
   today. Create `MyApp/Assets.xcassets/Session/` and import all four.
2. **`illustration-f2-path-ready.imageset` is an empty shell** (`Contents.json` only) — F2
   silently falls back to `illustration-trail`.

**Hygiene:** `Onboarding/illustration-c1-mirror` and `illustration-c2-common` are orphans —
nothing references them (C1/C2 use `illustration-reflection` / `illustration-belonging`).
Delete them.

**Resolve the contradictory brief.** `assets/illustrations/README.md` still mandates monochrome
broken-white art "so the illustration brings no color of its own"; CLAUDE.md's 17 Sep gouache
decision supersedes it. The README is stale and the new pieces sit exactly on that fault line.
Rewrite it, with this rule: **colored gouache is allowed on paper or on a dimmed scene ground,
never floating on a live category mesh.**

New pieces (~10, landing the total at 12–18). Prompts into
`assets/illustrations/onboarding/prompts.md`, copying the `prompt` field of any entry in
`assets/illustrations/gouache/prompts.json` **verbatim** and changing only the final subject
sentence — it already encodes style, palette, alpha and the content prohibitions (no people,
no faces, no hands, no summit, no trophy, no text).

| Slot                         | Screen     | Note                                                                                    |
| ---------------------------- | ---------- | --------------------------------------------------------------------------------------- |
| `onboarding-threshold`       | A1         | Full-bleed, **opaque** — the only scene, not a cutout.                                  |
| `onboarding-identity`        | identity   | Quiet motif.                                                                            |
| `onboarding-b-weather`       | B2/B3      | Time-of-day motif behind the dial.                                                      |
| `onboarding-c3-fork`         | C3         | Two routes, no winner marked.                                                           |
| `onboarding-c4-horizon`      | C4         | Distance, not a summit.                                                                 |
| `onboarding-commit`          | commitment | New.                                                                                    |
| `onboarding-d0-still`        | D0         | Calm, instrument-free.                                                                  |
| `illustration-f2-path-ready` | F2         | Fills the empty imageset.                                                               |
| `onboarding-h2-lantern`      | H2         | New.                                                                                    |
| `onboarding-h1-shelter`      | H1         | New — `illustration-shelter` is **not** free, `JourneyPhaseDecoration.swift:9` uses it. |

Reused as-is: `illustration-reflection` (C1), `illustration-belonging` (C2),
`illustration-rest` (G2). Register every new name as a case in the `PatikaArtwork` enum — no
raw strings at call sites.

---

## Part 8 — Cleanup

Five dead catalog entries whose screens were deleted with E2/E4:
`sessionLength.label.{short,standard,deep}` and `voicePreference.label.{feminine,masculine}` in
`Localizable.xcstrings`, plus their accessors in `DomainEnums.swift:573` and `:607`.

Delete those. **Keep** the `SessionLength` / `VoicePreference` enums and the `OnboardingDraft`
fields — the server contract and `PathSessionViewModel` still read them; only the unreachable
display strings go.

---

## Sequencing

Each phase leaves the app buildable and reviewable. New files need no `.pbxproj` edit
(`PBXFileSystemSynchronizedRootGroup`). Strings may only be born in `Localizable.xcstrings`,
enforced by `Tests/LocalizationCatalogTests`.

| #   | Phase                                                                                                                                                                                 | Why here                                                                                                                   |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| 0   | **Copy + decision log.** All new strings into the catalog, `python3 scripts/generate-string-symbol-shim.py`, and write the dated CLAUDE.md entries **now**, not at the end.           | Unblocks everything; the decision log is what stops this being reverted.                                                   |
| 1   | **Free wins**: import the 4 session illustrations, resolve the empty F2 imageset, delete the 2 orphans and the 5 dead strings.                                                        | No design decisions, immediately visible.                                                                                  |
| 2   | **Audio fix** (Part 6).                                                                                                                                                               | Independent and the highest-value single change. Ship before touching 30 screens so a later regression clearly isn't this. |
| 3   | **Primitives, zero call sites changed**: `PaperChoiceRow`, the surface environment key defaulting to `.ground`.                                                                       | Nothing changes visually. Build and screenshot to prove it.                                                                |
| 4   | **The seam**: both layouts read the environment; `OnboardingStep.surfaceStyle` returns `.ground` for every case.                                                                      | Still no visual change. The reviewable "seam works" commit.                                                                |
| 5   | **Flip one section and prove isolation.** Set `.paper` for identity + B2/B3/B5 + E3 only, and **screenshot an in-path measurement alongside** to prove `PathSessionView` didn't move. | This is where a wrong call costs most — prove it here, not at the end.                                                     |
| 6   | **C section**: `woodlandReveal` + `startsImmediately: true` + `.paper`. Update all three decision-log sites.                                                                          |                                                                                                                            |
| 7   | **A1** — delete the animation, add the scene (ships without art via the mesh fallback).                                                                                               |                                                                                                                            |
| 8   | **New inputs**, one commit each, by risk-adjusted value: `TickRuler` → `DualStatementSlider` (B2) → `CommitmentSlide` → `RadialClockDial` → gesture select (cut candidate).           |                                                                                                                            |
| 9   | **Flow restructure**: merge identity, add commitment / price / H2.                                                                                                                    | After the language is settled, so new screens are born correct.                                                            |
| 10  | **A2 and B6 last** — the two that must _not_ go paper.                                                                                                                                | Doing them last makes the exception read as deliberate contrast, not leftover styling.                                     |
| 11  | **Art integration**, then rewrite `assets/illustrations/README.md`. Verify every screen with `-patika-debug-no-art`.                                                                  |                                                                                                                            |
| 12  | **Contrast + accessibility sweep.**                                                                                                                                                   |                                                                                                                            |

---

## Verification

1. `bash scripts/run-swift-tests.sh` (regenerates the string shim). `JourneyRoutePatternTests`
   is already stale and excluded.
2. `npx --yes deno test --no-prompt --allow-read --allow-env --allow-net supabase/functions/tests/`
   — must stay green. Nothing here touches the server, so a failure means the draft contract
   drifted.
3. `xcodebuild -project patika.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
4. **Walk the whole flow on the simulator** — the new inputs are gestural, screenshots won't do.
   `-patika-debug-step a1|b3|d1|e1|f2|g1`. `xcrun simctl erase` is required for a true first run
   (`cfprefsd` serves stale `UserDefaults` after `uninstall`).
5. **Audio:** reach G1 with a real generated path and confirm the voice plays. Then _force the
   race_ — reach G1 as fast as possible after F1 — and confirm it still plays.
   `live-smoke-audio.py` covers the server side but **not** this race.
6. **Prove the isolation:** an in-path measurement and a mid-session screen must look
   unchanged.
7. **Accessibility sweep** at AX5, Reduce Motion, Reduce Transparency, plus VoiceOver over
   every new input. The dial must fall back to the wheel at accessibility sizes.
8. **Add a value-level contrast test** (`Tests/ContrastTests/main.swift`, manual-swiftc style)
   checking ink-on-paper and `textPrimary` against every palette background — this finally
   makes `Theme.minimumContrast` mean something.
9. Confirm no measurement screen offers a default, and D2–D8 render with no thumb until touched.

---

## Out of scope

- Real StoreKit purchase (the price screen is transparency only; StoreKit 2 isn't built).
- Turkish localization — catalog stays English-only, `AppLocale.current` stays `.english`.
- Server, migration or Edge Function changes.
- Flipping the rest of the app to paper — enabled by Part 2.2, not done here.
- Fabricated testimonials or user counts, in any form.

## On the skill's default framework

`/app-onboarding-questionnaire` proposes archetypes this product rejected in writing
(`docs/PRD-Ek-Onboarding.md` §15). With the widened scope, its paywall and gamification
archetypes are now partly adopted — as price _transparency_ and as a commitment moment plus a
genuinely earned badge. Its social-proof and pain-amplification archetypes are **not** adopted:
the first requires inventing numbers, and the second means deliberately deepening distress in
a product for anxious people. Its "app demo inside onboarding" principle is already built as
G1, in a stronger form than the archetype — the user hears their own words.
