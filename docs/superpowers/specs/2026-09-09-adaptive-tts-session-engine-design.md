# Adaptive TTS Session Engine Design

**Date:** 2026-09-09  
**Status:** Approved by product owner  
**Scope:** Personalized paths, ready-made paths, onboarding E4–G2, and the reusable iOS session engine

## Outcome

Patika will play real Turkish and English sessions assembled from pre-rendered approved block audio, short personalized ElevenLabs v3 speech assets, and client-timed silence. Generation will be durable and idempotent. A personalized session may ask one optional, safe question after completion and use the answer to frame the next step. Ready-made paths never ask this question and never invoke personalized generation.

## Product contract

- `program_paths.kind` is either `personalized` or `prepared`.
- Onboarding-created paths are `personalized`.
- Only a `personalized` path may have a `step_question`, accept a free-text step answer, or regenerate the next step's personal speech.
- A `prepared` path uses reviewed, pre-rendered scripts and audio only. The server rejects an answer or personalization request for it even if a client attempts one.
- Every free-text input is checked on device and on the server. A crisis signal blocks path generation and next-step generation and routes to support.
- Technical block content, breathing cadence, measurements, outcomes, payment decisions, and crisis decisions are deterministic and never delegated to an LLM.
- Raw problem text and raw step answers never enter analytics or error reports.

## Voice choice and locale

- E4 presents two blind samples named `Ses A`/`Voice A` and `Ses B`/`Voice B`; no gender or quality adjectives and no default selection.
- Tapping a sample stops the other sample, starts playback, and selects it. Continue remains disabled until explicit selection.
- Preview files use the exact production voice ID, ElevenLabs model, language, and voice settings.
- Four fixed preview assets exist: two voices multiplied by `tr` and `en`.
- Locale is Turkish when the preferred device language is Turkish or the device region is Turkey. Otherwise it is English.
- User-facing content in the path-generation/session slice is localized consistently; the locale does not change midway through the flow.

## TTS policy

- Provider: ElevenLabs EU residency endpoint.
- Model: `eleven_v3` for both fixed and personalized speech so seams do not expose a model change.
- Voice settings: Natural stability, conservative similarity, no exaggerated style, automatic text normalization.
- SSML breaks are not used. Silence is an explicit timeline event on the client.
- The model cannot emit arbitrary audio tags. It emits a semantic prosody enum; the server maps that enum through a versioned allowlist.
- Initial production allowlist is conservative. Unreviewed or undocumented tags are not sent. User text has bracket-based tag syntax neutralized before TTS.
- Connected personalized sentences are grouped when possible. Separate assets receive `previous_text` and `next_text` for stitching context.
- Speech is normalized to approximately -16 LUFS integrated with peaks at or below -1 dBTP. The application respects system volume and never changes it.

## Session manifest

The server publishes an immutable manifest version for each ready step. A manifest contains ordered events:

```json
{
  "version": 1,
  "stepId": "uuid",
  "locale": "tr-TR",
  "voice": "voiceA",
  "events": [
    { "type": "speech", "source": "personal", "assetId": "uuid", "text": "..." },
    { "type": "gap", "milliseconds": 300 },
    { "type": "speech", "source": "block", "assetId": "uuid", "text": "..." },
    { "type": "silence", "breaths": 3, "landOn": "exhale" }
  ]
}
```

Rules:

- Connected speech receives a 250–350 ms transition, not a multi-second pause.
- Silence exists only when the user is expected to breathe, notice, or act.
- Breathing defaults to 4 seconds inhale, 0.5 seconds hold, and 5.5 seconds exhale. A reviewed block may carry an explicit alternate pattern.
- Speech is never stretched to fill a target duration and never rounded to a breath boundary.
- Display copy changes with the corresponding timeline event. Silence cues retain the preceding instruction rather than introducing unrelated copy.
- The first session is a 3–4 minute version of step 1; later sessions respect the selected 5/10/15-minute content plan.

## Durable generation

Supabase is the system of record. Audio generation uses an explicit durable job record plus a PGMQ queue:

1. `generate-path` creates the 21-day skeleton and finalizes step 1.
2. `request-audio` creates or reuses a rendition job keyed by step, locale, voice, model, prompt policy, and normalized text digest.
3. A worker claims a queued job with a visibility timeout, renders missing fixed/personal assets, builds the manifest, and marks the step ready.
4. An Edge background wake starts the worker immediately. If the runtime dies, the PGMQ message remains; a repeated request/status reconciliation wakes it again.
5. Partial assets are reused. Retrying never pays for an asset whose rendition hash already exists.

The mobile request returns quickly with `queued`, `processing`, or `ready`. It never holds the F1 connection open for four sequential TTS calls.

## Two-phase next-step preparation

For personalized paths:

1. While step N plays, fixed assets and the immutable skeleton for N+1 are primed.
2. G2 displays the question created with step N. It is optional, at most 120 characters, non-diagnostic, and never requests trauma detail.
3. The answer is screened locally and on the server.
4. If safe, the raw answer is encrypted with AES-GCM using an Edge-only key; only a bounded summary is added to the next generation context.
5. Only N+1's short personal frame is generated. Its reviewed technique body is not rewritten.
6. If the answer is skipped, N+1 is finalized from the existing summary and is immediately eligible to become ready.

For prepared paths, the same completion call marks progress but never displays or accepts a question and never invokes Gemini or personalized TTS.

## Gemini boundary

Gemini may generate a JSON-schema-constrained path skeleton, bounded personal slot copy, a bounded answer summary, and a bounded step question. It receives summarized context wherever possible. It cannot create techniques, change clinical/safety rules, choose payment/outcome behavior, or control timings.

The existing key-based Gemini Developer API may be used for development. Production sensitive-data processing is abstracted behind the same provider interface so it can use a supported EU regional Vertex AI endpoint and service-account authentication without changing callers.

## Audio-reactive visual behavior

- Base mesh drift always continues while motion is permitted.
- A mixer tap samples voice RMS in 50 ms windows.
- An 80 ms attack and 450 ms release envelope prevents jitter.
- Voice energy adds at most 0.03 to the mesh center displacement and at most four percent to brightness.
- During breathing silence, the authored breath value remains the primary motion signal.
- Reduce Motion removes voice and breathing response. Reduce Transparency uses the existing solid fallback. Background/low-power/thermal rules remain active.
- The audio envelope is narrow state passed directly to the background; it is not placed in a broad global environment object that would invalidate the onboarding tree every frame.

## Privacy and storage

- Fixed block audio and voice previews contain no user data and may live in the public `block_audio` bucket with immutable cache headers.
- Personalized audio lives in `private_audio`, is addressed by a non-guessable path, and is served through short-lived signed URLs.
- Raw problem text and step answers are AES-GCM encrypted before storage. Nonces are unique per value and stored with the ciphertext envelope.
- PostHog receives only identifiers, status, latency, character counts, cache outcome, and fallback flags. Sentry receives error codes and provider/request metadata, never copy.
- Account deletion cascades database rows and storage cleanup. Anonymous-to-Apple/Google linking preserves the Supabase user ID and progress.
- English block copy remains `reviewed_at = null` until human review. Development can exercise it behind an explicit non-production flag; release validation rejects unreviewed blocks.

## Failure behavior

- A transient network error is reconciled using the same idempotency key before showing failure.
- F1 stages reflect server states, not timers.
- First-step audio failure offers text mode and continues retrying in the background; it does not discard onboarding answers.
- Later audio failure stays in the queue and does not block other steps.
- A crisis/refusal blocks generation rather than falling through to a generic personalized path.
- The app persists playback event/index/offset so an interruption or termination can resume without replaying the entire session.

## Cost policy

- Step 1 uses stronger personalization for the onboarding value moment.
- Later steps use the universal B+ policy: personal opening, at most one bridge, and personal closing; the technique body is shared.
- Target fresh speech for a ten-minute step is 700–900 characters.
- The full path skeleton is cheap and generated once; audio is generated just in time and one step ahead.
- Fixed audio and exact personalized renditions are content-addressed and reused.
- Provider usage, billed character count, cache hit, and generated-but-never-played ratios are measured without recording text.

## Acceptance criteria

- E4 plays four real bundled samples and requires explicit choice.
- A Turkish/Turkey device receives Turkish path/session content; other devices default to English.
- F1 survives a dropped response and reconciles the original job without duplicate path/audio rows.
- G1 plays the complete ordered hybrid timeline, not only the first personal MP3.
- Spoken and displayed cues stay synchronized; connected speech has no excessive pause.
- The mesh follows smoothed voice energy while retaining base motion.
- Completing a personalized step shows one optional question and safely prepares the next step from its answer.
- Completing a prepared step shows no question and makes no personalized provider call.
- Crisis input blocks next-step generation.
- All RLS/security advisors introduced by this work are resolved; intentional anonymous-user warnings are documented.
- Server contract tests, Swift source tests, clean iOS build, and simulator accessibility checks pass.

