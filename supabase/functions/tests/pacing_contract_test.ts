import { assertEquals } from "jsr:@std/assert@1.0.14";
import {
  alignedSilenceMs,
  breathMsFor,
  joinLeadInMs,
  JOIN_FLOOR_MS,
  JOIN_TARGET_MS,
  silenceEvent,
} from "../_shared/audio-worker.ts";

Deno.test("join fills the target gap, absorbing the provider padding", () => {
  // Sağlayıcı sessizliği yoksa: tam hedef.
  assertEquals(joinLeadInMs(0, 0), JOIN_TARGET_MS);
  // Dolgu boşluğun ÜSTÜNE binmez, içinde soğurulur.
  assertEquals(joinLeadInMs(120, 90), JOIN_TARGET_MS - 210);
});

Deno.test("join never drops below the floor, so sentences never fuse", () => {
  assertEquals(joinLeadInMs(400, 300), JOIN_FLOOR_MS);
  assertEquals(joinLeadInMs(10_000, 10_000), JOIN_FLOOR_MS);
});

Deno.test("breathMsFor uses the block's own rhythm", () => {
  assertEquals(breathMsFor({ breath_pattern: null }), 10_000);
  // Kutu nefesi 4-4-4-4 = 16 sn; 10 sn varsaymak sessizlikleri kısaltırdı.
  assertEquals(breathMsFor({ breath_pattern: { inhale: 4, hold: 4, exhale: 4, rest: 4 } }), 16_000);
  assertEquals(breathMsFor({ breath_pattern: { inhale: 4, hold: 0.5, exhale: 7, rest: 0 } }), 11_500);
});

Deno.test("a beat is written time and is never rounded to a breath", () => {
  const event = silenceEvent({ ms: 1_500 }, 10_000);
  assertEquals(event.type === "silence" && event.ms, 1_500);
});

Deno.test("a practice pause is whole breaths of the block's period, mirrored for old clients", () => {
  const event = silenceEvent({ breaths: 4, landOn: "exhale" }, 16_000);
  assertEquals(event.type === "silence" && event.ms, 64_000);
  assertEquals(event.type === "silence" && event.breaths, 4);
  assertEquals(event.type === "silence" && event.breathMs, 16_000);
});

Deno.test("alignedSilenceMs lands on the exhale boundary", () => {
  const breath = 10_000;
  for (const phase of [0, 1_000, 3_000, 4_999, 5_000, 7_500, 9_999]) {
    const duration = alignedSilenceMs(2, breath, "exhale", phase);
    assertEquals((phase + duration) % breath, 0, `phase ${phase} -> ${duration}`);
    // En yakın sınır: nominalden en çok yarım nefes sapar.
    assertEquals(Math.abs(duration - 2 * breath) <= breath / 2, true);
  }
});

Deno.test("alignedSilenceMs lands on the end of the inhale", () => {
  const duration = alignedSilenceMs(3, 10_000, "inhale", 2_000, 4_000);
  assertEquals((2_000 + duration) % 10_000, 4_000);
});

Deno.test("alignedSilenceMs without landOn is the plain nominal length", () => {
  assertEquals(alignedSilenceMs(4, 16_000, null, 7_000), 64_000);
  assertEquals(alignedSilenceMs(2, 10_000, undefined, 3_000), 20_000);
});
