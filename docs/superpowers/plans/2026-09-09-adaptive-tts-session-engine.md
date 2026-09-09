# Adaptive TTS Session Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver real bilingual ElevenLabs v3 sessions with durable Supabase JIT generation, adaptive questions only for personalized paths, and a reusable audio-reactive iOS player.

**Architecture:** Supabase stores immutable block scripts, rendition assets, generation jobs, and compiled session manifests. PGMQ makes audio work durable while Edge Functions wake and drain the queue. SwiftUI consumes a typed manifest through an `AVAudioEngine` timeline player and feeds a smoothed voice envelope into the existing mesh.

**Tech Stack:** Swift 6.3, SwiftUI/Observation, AVFoundation, Supabase Postgres/Storage/Edge Functions/PGMQ, Deno TypeScript, Gemini structured output, ElevenLabs v3 EU endpoint.

**Spec:** `docs/superpowers/specs/2026-09-09-adaptive-tts-session-engine-design.md`

## Durum — 2026-09-09

Görev 1–11 tamamlandı ve doğrulandı. Görev 12 **ses dışında** tamamlandı:

- Beş Edge Function dağıtıldı (`generate-path` v6, `generate-audio` v5,
  `process-audio-jobs`, `render-shared-audio`, `complete-step`), migrasyonlar
  uzak projede uygulandı ve migrasyon defteri onarıldı.
- Canlı doğrulama (anonim kullanıcı, 2026-09-09): TR path 3 sn'de 21 adım,
  `kind=personalized`, soru üretildi; `complete-step` cevabı şifreleyip yalnızca
  2. adımı kişiselleştirip kuyruğa aldı (`nextStepStatus=queued`). EN path
  `breath.awareness.en.v1` bloğunu ve İngilizce metni kullandı. Kriz cevabı
  `status=crisis` döndürdü, adım tamamlanmadı ve sonraki adım **kuyruğa
  girmedi**.
- **Engelli:** Supabase'te duran `ELEVENLABS_API_KEY` sağlayıcı tarafından
  reddediliyor (`tts_request_failed_400_invalid_api_key`, ölçüldü). Dört ses
  örneğinin render'ı, sabit blok seslerinin render'ı ve G1'de gerçek sesin
  duyulması bu tek dış kimlik bilgisine bağlı. Geçerli bir `sk_...` anahtarı
  girildiğinde başka kod değişikliği gerekmiyor.
- Kalan iki iş bilinçli olarak ertelendi: arayüz String Catalog'u (arayüz metni
  hâlâ `Copy.swift` içinde sabit Türkçe; ses ve blok dili `AppLocale` ile zaten
  iki dilli) ve `fal-webhook` adlı artık işlevi olmayan dağıtılmış fonksiyonun
  silinmesi (kaynağı depoda yok; silme kararı ürün sahibinin).

## Global Constraints

- Deployment target is iOS 26.0 and the project remains native SwiftUI.
- `OnboardingDraft` stays transient until onboarding completes.
- Every free-text field is crisis-screened on device and server; a signal blocks generation.
- No raw problem, answer, measurement, or generated speech text enters analytics or error reporting.
- Only personalized paths ask or accept a step question; prepared paths never personalize.
- No emoji, clinical claim, diagnosis, treatment promise, medication guidance, or trauma-detail request.
- User-specific audio is private and signed; fixed audio/previews contain no personal data.
- Existing dirty-worktree changes are preserved; `.pbxproj` is not edited manually.

---

### Task 1: Lock the approved architecture into project documentation

**Files:**
- Create: `docs/superpowers/specs/2026-09-09-adaptive-tts-session-engine-design.md`
- Create: `docs/superpowers/plans/2026-09-09-adaptive-tts-session-engine.md`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: Product-owner approval from 2026-09-09.
- Produces: The source-of-truth `personalized` versus `prepared` contract used by all later tasks.

- [x] **Step 1: Add the approved design and implementation plan**

Write the documents listed above with the exact path-kind, safety, TTS, queue, playback, locale, and cost rules.

- [x] **Step 2: Verify the documents contain no unresolved placeholders**

Run:

```bash
rg -n 'T[B]D|T[O]DO|implement la[t]er|fill i[n]' docs/superpowers/specs/2026-09-09-adaptive-tts-session-engine-design.md docs/superpowers/plans/2026-09-09-adaptive-tts-session-engine.md
```

Expected: no matches.

- [x] **Step 3: Commit only the approved documentation**

```bash
git add docs/superpowers/specs/2026-09-09-adaptive-tts-session-engine-design.md docs/superpowers/plans/2026-09-09-adaptive-tts-session-engine.md CLAUDE.md
git commit -m "docs: approve adaptive TTS session architecture"
```

### Task 2: Add typed server contracts and failing contract tests

**Files:**
- Modify: `supabase/functions/_shared/schema.ts`
- Modify: `supabase/functions/_shared/providers.ts`
- Create: `supabase/functions/_shared/session.ts`
- Modify: `supabase/functions/tests/provider_contract_test.ts`
- Create: `supabase/functions/tests/session_contract_test.ts`

**Interfaces:**
- Consumes: `GeneratePathRequest`, `PathPlanDTO`, reviewed block identifiers.
- Produces: `PathKind`, `SessionManifestDTO`, `SessionEventDTO`, `CompleteStepRequest`, `validateSessionManifest`, `questionForStep`, and locale-aware block selection.

- [x] **Step 1: Write failing tests for the path-kind boundary**

Add tests proving `prepared` steps have no question/personal slot request, `personalized` questions are at most 120 characters, unsupported audio tags are stripped, and English fallback plans use English block IDs/copy.

- [x] **Step 2: Run the tests and observe RED**

```bash
npx --yes deno test --allow-env supabase/functions/tests/provider_contract_test.ts supabase/functions/tests/session_contract_test.ts
```

Expected: failures for missing `PathKind`, manifest validation, and locale-aware fallback behavior.

- [x] **Step 3: Implement the minimal contracts and validators**

Define discriminated event types (`speech`, `gap`, `silence`), strict bounds, approved slot names, a semantic prosody enum, and explicit `personalized`/`prepared` handling. Keep crisis decisions outside Gemini.

- [x] **Step 4: Run the contract tests and observe GREEN**

Run the same Deno command. Expected: all contract tests pass.

### Task 3: Migrate Supabase for durable jobs, manifests, and path kinds

**Files:**
- Create: `supabase/migrations/20260909150000_adaptive_session_engine.sql`

**Interfaces:**
- Consumes: Existing `program_paths`, `path_steps`, `generation_jobs`, `audio_assets`, `blocks`, and `block_audio`.
- Produces: `program_paths.kind`, `session_manifests`, rendition hashes, job-to-step relation, PGMQ queue functions, secure view behavior, and server-only completion writes.

- [x] **Step 1: Write SQL assertions before the migration**

Include post-migration assertions in a transaction-backed verification query for path-kind checks, unique rendition hashes, owner RLS, prepared-path question prohibition, and `security_invoker` on `unreviewed_blocks`.

- [x] **Step 2: Apply the migration locally or through the linked Supabase migration API**

Use the exact SQL in `20260909150000_adaptive_session_engine.sql`. The migration must enable `pgmq`, create `patika_audio_jobs`, expose only service-role queue RPCs, revoke them from `anon` and `authenticated`, and preserve existing rows as `personalized`.

- [x] **Step 3: Run verification queries**

Verify column constraints, RLS policies, queue existence, and zero externally facing SECURITY DEFINER views. Expected: all assertions succeed.

### Task 4: Make TTS content-addressed, tag-safe, and queue-driven

**Files:**
- Modify: `supabase/functions/_shared/tts.ts`
- Create: `supabase/functions/_shared/encryption.ts`
- Create: `supabase/functions/_shared/audio-worker.ts`
- Modify: `supabase/functions/generate-audio/index.ts`
- Create: `supabase/functions/process-audio-jobs/index.ts`
- Create: `supabase/functions/render-shared-audio/index.ts`
- Create: `supabase/functions/tests/tts_policy_test.ts`

**Interfaces:**
- Consumes: `SessionManifestDTO`, `PATIKA_DATA_ENCRYPTION_KEY`, ElevenLabs secrets, and service-role queue RPCs.
- Produces: `renditionHash`, `sanitizeSpeechText`, `audioTagForProsody`, `processAudioJob`, and fast `queued|processing|ready` responses.

- [x] **Step 1: Write failing tag, digest, and idempotency tests**

Test that bracket instructions from user copy are neutralized, undocumented tags cannot pass, identical inputs produce the same digest, and changed locale/voice/model/policy produces a new digest.

- [x] **Step 2: Observe RED with Deno**

```bash
npx --yes deno test --allow-env supabase/functions/tests/tts_policy_test.ts
```

Expected: missing policy/digest functions.

- [x] **Step 3: Implement the TTS policy and worker**

Use `eleven_v3`, EU base URL, `language_code`, Natural stability, stitching context, bounded timeouts, exact rendition hashes, partial-asset reuse, and immutable Storage paths. `generate-audio` must enqueue/wake and return without waiting for all speech calls.

- [x] **Step 4: Implement shared fixed audio and preview rendering**

Allow only constant server-defined preview texts and database block `fixed` events. Never accept arbitrary public render text. Cache four preview renditions and every block rendition by digest.

- [x] **Step 5: Run TTS policy and provider contract tests**

Expected: all Deno tests pass without live provider access.

### Task 5: Generate safe questions and personalize only the next custom step

**Files:**
- Modify: `supabase/functions/_shared/providers.ts`
- Modify: `supabase/functions/generate-path/index.ts`
- Create: `supabase/functions/complete-step/index.ts`
- Create: `supabase/functions/tests/complete_step_policy_test.ts`

**Interfaces:**
- Consumes: Path kind, current step, encrypted answer service, crisis classifier, and audio enqueue service.
- Produces: `complete-step` response `{status, nextStepStatus, crisis}` and the next step's bounded personal frame.

- [x] **Step 1: Write failing policy tests**

Prove a prepared path cannot accept an answer, a personalized safe answer updates only N+1 personal slots, a skipped answer still queues N+1, a crisis answer queues nothing, and questions contain no banned phrase or trauma request.

- [x] **Step 2: Observe RED**

Run the new Deno test. Expected: missing completion policy.

- [x] **Step 3: Implement completion and next-step generation**

Complete the current step server-side, encrypt raw answer with AES-GCM, store only a bounded summary for generation, validate Gemini JSON, run output safety checks, update only N+1 `slot_copy`, and enqueue N+1 audio. Prepared paths only complete progress.

- [x] **Step 4: Observe GREEN**

Run all Edge Function tests. Expected: all pass.

### Task 6: Seed bilingual draft blocks without falsely approving them

**Files:**
- Create: `supabase/migrations/20260909150100_seed_blocks_en.sql`
- Modify: `supabase/functions/_shared/schema.ts`
- Modify: `scripts/render-voice-previews.sh`

**Interfaces:**
- Consumes: Turkish block roles and timing.
- Produces: English `.en.v1` block IDs and the exact four preview asset names expected by iOS.

- [x] **Step 1: Add a failing locale contract test**

Assert every English approved block ID has a database seed and every preview locale/voice pair resolves to one immutable asset name.

- [x] **Step 2: Observe RED**

Run provider/session contract tests. Expected: missing English records.

- [x] **Step 3: Add natural English draft copy**

Translate meaning and tone, not word order. Keep `reviewed_at` null and add an explicit release-gate query. Do not mark either language clinically reviewed as part of engineering work.

- [x] **Step 4: Observe GREEN**

Run contract tests and migration verification. Expected: locale coverage passes and release-gate query still reports draft rows.

### Task 7: Add Swift manifest models and timeline compilation tests

**Files:**
- Create: `MyApp/Models/SessionManifest.swift`
- Create: `MyApp/Features/Session/SessionTimeline.swift`
- Create: `Tests/SessionTimelineTests/main.swift`
- Modify: `MyApp/Infrastructure/Backend/BackendClient.swift`

**Interfaces:**
- Consumes: Server manifest JSON.
- Produces: `SessionManifest`, `SessionEvent`, `SessionTimeline`, `SessionTimeline.currentEvent(at:)`, and `BackendClient.sessionManifest`.

- [x] **Step 1: Write failing pure Swift tests**

Test ordered duration calculation, 300 ms connected gaps, breath silence duration, event lookup at boundaries, prepared-path question absence, and decoding unknown manifest versions as an error.

- [x] **Step 2: Observe RED**

```bash
swiftc MyApp/DesignSystem/Breath.swift MyApp/Models/SessionManifest.swift MyApp/Features/Session/SessionTimeline.swift Tests/SessionTimelineTests/main.swift -o /tmp/patika-session-tests
```

Expected: compilation fails because manifest/timeline types do not exist.

- [x] **Step 3: Implement minimal Sendable value types**

Use explicit coding keys and discriminated event decoding. Keep timing/business logic independent of SwiftUI and AVFoundation.

- [x] **Step 4: Observe GREEN**

Compile and run `/tmp/patika-session-tests`. Expected: all assertions pass.

### Task 8: Expand the backend client with reconciliation and signed asset bundles

**Files:**
- Modify: `MyApp/Infrastructure/Backend/BackendClient.swift`
- Modify: `MyApp/Infrastructure/Backend/SupabaseBackendClient.swift`
- Create: `MyApp/Infrastructure/Backend/RetryPolicy.swift`
- Create: `Tests/RetryPolicyTests/main.swift`

**Interfaces:**
- Consumes: `SessionManifest` and Edge Function status payloads.
- Produces: `generatePathWithReconciliation`, `requestSession`, `completeStep`, `signedSessionManifest`, and a testable exponential retry policy.

- [x] **Step 1: Write failing retry tests**

Prove transient URL errors retry with the same idempotency key, permanent 4xx responses do not retry, and reconciliation returns an existing ready path/job.

- [x] **Step 2: Observe RED**

Compile the pure retry test. Expected: missing `RetryPolicy`.

- [x] **Step 3: Implement bounded retry/reconciliation**

Use three attempts with jittered exponential delay, preserve the idempotency key, and query server state before exposing failure. Never log payload text.

- [x] **Step 4: Observe GREEN**

Run retry and session timeline source tests. Expected: all pass.

### Task 9: Replace single-file playback with a resumable timeline engine

**Files:**
- Replace: `MyApp/Features/Session/SessionAudioPlayer.swift`
- Create: `MyApp/Features/Session/AudioEnvelopeFollower.swift`
- Create: `MyApp/Features/Session/SessionAssetCache.swift`
- Modify: `MyApp/Features/Onboarding/GFirstSession/FirstSessionViewModel.swift`

**Interfaces:**
- Consumes: Signed manifest assets and `SessionTimeline`.
- Produces: ordered play/pause/resume/stop, `currentEvent`, `progress`, persisted position, and `voiceEnergy` in `0...1`.

- [x] **Step 1: Write failing envelope tests**

Add a pure Swift test proving attack is faster than release, output is clamped, and silence decays smoothly instead of snapping to zero.

- [x] **Step 2: Observe RED**

Compile the envelope test. Expected: missing follower type.

- [x] **Step 3: Implement timeline scheduling and caching**

Download signed personal assets and public fixed assets to protected cache files, schedule speech in manifest order, advance explicit gaps/silence with a monotonic clock, install a mixer tap for RMS, and update narrow observable state only when values materially change.

- [x] **Step 4: Implement interruption and resume behavior**

Handle audio-session interruption, route changes, app termination checkpoints, lock-screen play/pause, and exact event/offset resume.

- [x] **Step 5: Run source tests and an iOS build**

Expected: tests pass and `xcodebuild` succeeds without actor-isolation warnings.

### Task 10: Finish E4, G1, G2, and the reusable path session UI

**Files:**
- Modify: `MyApp/Models/DomainEnums.swift`
- Modify: `MyApp/Content/Copy.swift`
- Modify: `MyApp/Features/Onboarding/EPreferences/VoiceChoiceView.swift`
- Modify: `MyApp/Features/Onboarding/GFirstSession/FirstSessionView.swift`
- Modify: `MyApp/Features/Onboarding/GFirstSession/SessionCompleteView.swift`
- Create: `MyApp/Features/Session/AdaptiveQuestionView.swift`
- Create: `MyApp/Features/Path/MyPathView.swift`
- Modify: `MyApp/App/RootView.swift`
- Add: `MyApp/Localizable.xcstrings`

**Interfaces:**
- Consumes: `voiceEnergy`, path kind, current question, completion status, and manifest playback state.
- Produces: blind voice samples, synchronized cue UI, personalized-only G2 question, and post-onboarding continuation sessions.

- [x] **Step 1: Add failing source assertions for copy and path-kind behavior**

Assert the two voice labels are neutral, all session keys have TR/EN values, prepared sessions expose no question, and crisis copy contains no animation/celebration path.

- [x] **Step 2: Observe RED**

Run the copy/path source test. Expected: missing localization and path-kind UI contract.

- [x] **Step 3: Implement E4 and session views**

Use `@Observable @MainActor` view models stored in private `@State`, native `Button` controls, semantic fonts, at least 44 pt targets, no default voice selection, text fallback, an optional question with `Bugün geç`, and the primary session off-ramp.

- [x] **Step 4: Add the post-onboarding My Path screen**

Load the active path, display the next eligible step, request its manifest, run the same session player, and show adaptive G2 only when the path is personalized.

- [x] **Step 5: Build and inspect accessibility variants**

Verify normal size, AX5, VoiceOver grouping, Reduce Motion, and Reduce Transparency on iPhone 17 Pro simulator.

### Task 11: Connect voice energy to the mesh without frame-wide invalidation

**Files:**
- Modify: `MyApp/DesignSystem/BreathingMeshBackground.swift`
- Modify: `MyApp/Features/Onboarding/OnboardingContainerView.swift`
- Modify: `MyApp/Features/Onboarding/GFirstSession/FirstSessionView.swift`
- Create: `Tests/AudioEnvelopeTests/main.swift`

**Interfaces:**
- Consumes: `voiceEnergy: Double` and `BreathCycle.value`.
- Produces: capped mesh displacement/brightness with base drift preserved.

- [x] **Step 1: Write a failing clamp/composition test**

Assert voice displacement never exceeds 0.03, brightness never exceeds four percent, base movement remains nonzero at voice energy zero, and Reduce Motion resolves to zero response.

- [x] **Step 2: Observe RED**

Compile/run the pure audio-envelope test. Expected: missing composition API.

- [x] **Step 3: Implement narrow visual input**

Pass the scalar directly from the session view to the background instance, smooth changes in the envelope follower rather than with per-frame SwiftUI animation, and keep existing thermal/power/accessibility fallbacks.

- [x] **Step 4: Observe GREEN and profile**

Run tests and use simulator/Instruments to verify the background remains within the documented two-millisecond render budget where measurement is available.

### Task 12: Deploy, render shared assets, and verify end to end

**Files:**
- Modify: `CLAUDE.md`
- Modify: `MyApp/Resources/README.md`
- Add generated assets: `MyApp/Resources/voice-preview-*.mp3`

**Interfaces:**
- Consumes: Linked project `aapxqeqduphafisyaadk`, configured Gemini/ElevenLabs secrets, migrations, and Edge Functions.
- Produces: deployed schema/functions, four bundled previews, fixed block renditions, and verified personalized step-1 playback.

- [x] **Step 1: Configure required secrets without logging their values**

Set Gemini, ElevenLabs, live-enable, encryption, and internal worker configuration. List only secret names afterward.

- [x] **Step 2: Apply migrations and deploy functions**

Deploy `generate-path`, `generate-audio`, `process-audio-jobs`, `complete-step`, and `render-shared-audio` with JWT verification and body-level service-role protection for the worker.

- [ ] **Step 3: Render and bundle the four previews** — ENGELLİ (bkz. Durum)

Invoke the constant-input shared render route, download exact TR/EN voice A/B assets, verify they are nonempty MPEG files, and add them under `MyApp/Resources`.

- [x] **Step 4: Exercise a real anonymous-user flow**

Generate a personalized path, observe queued-to-ready audio, fetch/decode the manifest, verify every referenced asset, complete step 1 with a safe answer, and verify only step 2 is personalized/queued. Also exercise a prepared-path completion and verify no answer/provider call.

- [x] **Step 5: Run final automated verification**

```bash
npx --yes deno test --allow-env supabase/functions/tests/*.ts
swiftc MyApp/DesignSystem/Breath.swift MyApp/Models/SessionManifest.swift MyApp/Features/Session/SessionTimeline.swift Tests/SessionTimelineTests/main.swift -o /tmp/patika-session-tests && /tmp/patika-session-tests
xcodebuild -project patika.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: all tests and build pass.

- [x] **Step 6: Re-run Supabase advisors and record intentional warnings**

Expected: no ERROR security advisory. Anonymous-owner RLS warnings remain intentional because onboarding begins with an anonymous authenticated user; leaked-password protection is irrelevant while email/password auth remains disabled.

- [x] **Step 7: Update the project decision log with verified reality**

Record deployed function versions, actual model, asset counts, observed generation latency, tests run, remaining human content-review gate, and the requirement to rotate any credential previously pasted into chat.
