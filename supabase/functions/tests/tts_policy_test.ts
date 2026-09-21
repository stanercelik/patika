import {
  assertEquals,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  audioTagForProsody,
  renditionHash,
  sanitizeSpeechText,
} from "../_shared/tts.ts";

Deno.test("user brackets are neutralized before TTS prompting", () => {
  assertEquals(
    sanitizeSpeechText("Bugün [shouts] kötüydü.  [meditative] devam"),
    "Bugün shouts kötüydü. meditative devam",
  );
  assertEquals(sanitizeSpeechText("  sakin   bir  alan  "), "sakin bir alan");
});

Deno.test("only reviewed v3 tags can be emitted", () => {
  assertEquals(audioTagForProsody("neutral"), null);
  assertEquals(audioTagForProsody("soft"), null);
  assertEquals(audioTagForProsody("whisper"), "[whispers]");
  assertEquals(audioTagForProsody("meditative"), null);
  assertEquals(audioTagForProsody("[shouts]"), null);
});

Deno.test("rendition hashes are deterministic and policy-sensitive", async () => {
  const base = {
    text: "Burada biraz yerleş.",
    locale: "tr",
    voice: "feminine" as const,
    modelId: "eleven_v3",
    prosody: "soft",
  };
  const first = await renditionHash(base);
  const again = await renditionHash(base);

  assertEquals(first, again);
  assertEquals(first.length, 64);
  assertNotEquals(first, await renditionHash({ ...base, locale: "en" }));
  assertNotEquals(first, await renditionHash({ ...base, voice: "masculine" }));
  assertNotEquals(first, await renditionHash({ ...base, modelId: "eleven_v3_next" }));
  assertNotEquals(first, await renditionHash({ ...base, prosody: "whisper" }));
});


import { speechRequestBody } from "../_shared/tts.ts";

Deno.test("eleven_v3 requests never carry request stitching (provider rejects it)", () => {
  const body = speechRequestBody({
    text: "Rest here.", modelId: "eleven_v3", locale: "en-US", previousText: "Before.", nextText: "After.",
  });
  assertEquals("previous_text" in body && body.previous_text !== undefined, false);
  assertEquals(body.next_text, undefined);
  assertEquals(body.language_code, "en");
  assertEquals(body.voice_settings.stability, 0.5);
});

Deno.test("models that support stitching still receive neighbouring text", () => {
  const body = speechRequestBody({
    text: "Rest here.", modelId: "eleven_multilingual_v2", locale: "en", previousText: "Before.", nextText: "After.",
  });
  assertEquals(body.previous_text, "Before.");
  assertEquals(body.next_text, "After.");
});
