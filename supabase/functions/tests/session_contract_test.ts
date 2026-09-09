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
  locale: "tr-TR",
  voice: "feminine",
  question: "Bugün zihnin en çok hangi anda hızlandı?",
  events: [
    {
      type: "speech",
      source: "personal",
      assetId: "19536cb3-cac8-412c-b42e-2e0017152d6e",
      storagePath: "user/step/opening.mp3",
      text: "Şimdi birkaç dakika burada duracağız.",
      durationMs: 2_400,
    },
    { type: "gap", milliseconds: 300 },
    {
      type: "silence",
      breaths: 2,
      landOn: "exhale",
      displayText: "Nefesini olduğu gibi bırak.",
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
