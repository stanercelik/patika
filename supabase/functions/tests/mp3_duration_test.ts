import { assert, assertEquals } from "jsr:@std/assert@1.0.14";
import { mp3DurationMs } from "../_shared/mp3.ts";

const fixture = (name: string) => Deno.readFile(new URL(`./fixtures/${name}`, import.meta.url));

// Ayrıştırıcı **kodlanmış çerçeve** süresini verir: 44.1 kHz Katman III'te çerçeve
// başına 1152 örnek (~26 ms) ve LAME kodlayıcı gecikmesi (~1105 örnek) çözülmüş
// süreye ek olarak çerçevelerde durur. Toplam sapma en çok iki çerçeve; bu bir
// planlama değeri, oynatıcı yüklediği dosyayı kendisi ölçüyor.
const tolerance = 60;

Deno.test("plain mp3 without any tag measures one second", async () => {
  const ms = mp3DurationMs(await fixture("plain-1s.mp3"));
  assert(Math.abs(ms - 1_000) <= tolerance, `plain duration ${ms}`);
});

Deno.test("ID3v2 and Xing frame are skipped, not counted as audio", async () => {
  const tagged = mp3DurationMs(await fixture("tagged-1s.mp3"));
  const plain = mp3DurationMs(await fixture("plain-1s.mp3"));
  assert(Math.abs(tagged - 1_000) <= tolerance, `tagged duration ${tagged}`);
  assert(Math.abs(tagged - plain) <= tolerance, `tagged ${tagged} vs plain ${plain}`);
});

Deno.test("leading garbage and truncated tail do not throw", async () => {
  const bytes = await fixture("plain-1s.mp3");
  const noisy = new Uint8Array(bytes.length + 40);
  noisy.set(bytes, 20);
  const ms = mp3DurationMs(noisy.subarray(0, noisy.length - 7));
  assert(ms > 900 && ms < 1_100, `noisy duration ${ms}`);
});

Deno.test("non-audio input yields zero", () => {
  assertEquals(mp3DurationMs(new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])), 0);
  assertEquals(mp3DurationMs(new Uint8Array(0)), 0);
});
