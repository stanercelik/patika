import { assertEquals, assertThrows } from "jsr:@std/assert@1.0.14";
import {
  shouldAskAdaptiveQuestion,
  validateSessionManifest,
  type SessionManifestDTO,
} from "../_shared/session.ts";

const manifest: SessionManifestDTO = {
  version: 1,
  stepId: "2c43e408-ef17-4c67-b2d4-843b0cf45db3",
  pathKind: "personalized",
  locale: "en-US",
  voice: "feminine",
  question: "When did your mind speed up the most today?",
  events: [
    {
      type: "speech",
      source: "personal",
      assetId: "19536cb3-cac8-412c-b42e-2e0017152d6e",
      storagePath: "user/step/opening.mp3",
      text: "We will stay here for a few minutes.",
      durationMs: 2_400,
    },
    {
      type: "speech",
      source: "block",
      assetId: "6f0e3f4e-2f8b-4a4e-9d55-3c1d9c1f7a10",
      storagePath: "en/feminine/practice.mp3",
      text: "Let your breath arrive in its own way.",
      durationMs: 3_100,
      leadInMs: 320,
    },
    {
      type: "silence",
      ms: 20_000,
      breaths: 2,
      breathMs: 10_000,
      landOn: "exhale",
      displayText: "Let your breath be as it is.",
    },
  ],
};

Deno.test("validates a bounded personalized session manifest", () => {
  assertEquals(validateSessionManifest(manifest), manifest);
  assertEquals(shouldAskAdaptiveQuestion(manifest.pathKind, manifest.question), true);
});

Deno.test("prepared manifests never expose an adaptive question", () => {
  assertEquals(shouldAskAdaptiveQuestion("prepared", "Ignored question"), false);
  assertThrows(
    () => validateSessionManifest({ ...manifest, pathKind: "prepared" }),
    Error,
    "invalid_session_manifest",
  );
});

Deno.test("rejects excessive gaps and questions", () => {
  assertThrows(
    () => validateSessionManifest({
      ...manifest,
      question: "x".repeat(121),
    }),
    Error,
    "invalid_session_manifest",
  );
  assertThrows(
    () => validateSessionManifest({
      ...manifest,
      events: [{ type: "gap", milliseconds: 2_000 }],
    }),
    Error,
    "invalid_session_manifest",
  );
});


const silence = (event: Record<string, unknown>): SessionManifestDTO => ({
  ...manifest,
  events: [manifest.events[0], { type: "silence", ...event } as never],
});

Deno.test("accepts a beat that is shorter than one breath and is not rounded", () => {
  const result = validateSessionManifest(silence({ ms: 1_500, breaths: 1 }));
  assertEquals((result.events[1] as { ms: number }).ms, 1_500);
});

Deno.test("silence must carry ms or breaths, and the mirror cannot lie", () => {
  assertThrows(() => validateSessionManifest(silence({})), Error, "invalid_session_manifest");
  // 20 s at a 10 s breath is 2 breaths, not 3: an old client would play it wrong.
  assertThrows(() => validateSessionManifest(silence({ ms: 20_000, breaths: 3 })), Error, "invalid_session_manifest");
  // Box breathing: 4 breaths of 16 s are 64 s, mirrored as 4.
  validateSessionManifest(silence({ ms: 64_000, breaths: 4, breathMs: 16_000 }));
  assertThrows(() => validateSessionManifest(silence({ ms: 64_000, breaths: 6, breathMs: 16_000 })), Error, "invalid_session_manifest");
});

Deno.test("legacy breaths-only silence and gap events are still valid", () => {
  validateSessionManifest(silence({ breaths: 2, landOn: "exhale" }));
  validateSessionManifest({ ...manifest, events: [manifest.events[0], { type: "gap", milliseconds: 300 }] });
});

Deno.test("silence ranges are bounded", () => {
  assertThrows(() => validateSessionManifest(silence({ ms: 100 })), Error, "invalid_session_manifest");
  assertThrows(() => validateSessionManifest(silence({ ms: 300_001 })), Error, "invalid_session_manifest");
  assertThrows(() => validateSessionManifest(silence({ ms: 2_000, breathMs: 3_000 })), Error, "invalid_session_manifest");
  assertThrows(() => validateSessionManifest({ ...manifest, breathMs: 40_000 }), Error, "invalid_session_manifest");
});

Deno.test("leadInMs is bounded and stays a property of speech", () => {
  const withLead = (leadInMs: number): SessionManifestDTO => ({
    ...manifest,
    events: [{ ...(manifest.events[0] as object), leadInMs } as never],
  });
  validateSessionManifest(withLead(0));
  validateSessionManifest(withLead(2_000));
  assertThrows(() => validateSessionManifest(withLead(2_001)), Error, "invalid_session_manifest");
  assertThrows(() => validateSessionManifest(withLead(-1)), Error, "invalid_session_manifest");
  assertThrows(() => validateSessionManifest(withLead(350.5)), Error, "invalid_session_manifest");
});
