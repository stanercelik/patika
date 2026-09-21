import { assert, assertEquals, assertMatch } from "jsr:@std/assert@1.0.14";
import { TTS_POLICY_VERSION } from "../_shared/tts.ts";

const root = new URL("../../../", import.meta.url);
const read = (path: string) => Deno.readTextFile(new URL(path, root));

Deno.test("Discover render script reads only the canonical catalog and never the network edge", async () => {
  const script = await read("scripts/render-discover-audio.py");
  assertMatch(script, /MyApp\/Content\/Discover\/discover-catalog\.json/);
  // Eski yol: edge fonksiyonuna konuşup katalog dışı metin seslendirmek. Artık yok.
  assert(!/functions\/v1/.test(script), "render script must not call an edge function");
  assert(!/render-discover-audio\b.*urlopen/s.test(script));
  // Anahtar yalnızca ortamdan gelir.
  const common = await read("scripts/patika_tts.py");
  assertMatch(common, /os\.environ\.get\("ELEVENLABS_API_KEY"/);
});

Deno.test("post-processing constants are the plan's, and the policy version matches the server", async () => {
  const common = await read("scripts/patika_tts.py");
  assertMatch(common, /"lufs": -16/);
  assertMatch(common, /"true_peak": -1\.5/);
  assertMatch(common, /"declick_s": 0\.015/);
  assertMatch(common, /-write_xing/);
  // İki geçişli loudnorm: tek geçiş dinamik ve deterministik değil.
  assertMatch(common, /measured_I=/);
  assert(common.includes(`POLICY_VERSION = "${TTS_POLICY_VERSION}"`), "python and server policy versions diverged");
});

Deno.test("voice settings in the script equal the server's", async () => {
  const server = await read("supabase/functions/_shared/tts.ts");
  const python = await read("scripts/patika_tts.py");
  for (const [key, value] of [["stability", "0.5"], ["similarity_boost", "0.8"], ["style", "0.0"]]) {
    assertMatch(server, new RegExp(`${key}: ${value.replace(".", "\\.")}`));
    assertMatch(python, new RegExp(`"${key}": ${value.replace(".", "\\.")}`));
  }
});

Deno.test("shared golden vectors cover the server hash", async () => {
  const vectors = JSON.parse(await read("supabase/functions/tests/fixtures/rendition-vectors.json"));
  assertEquals(vectors.policy, TTS_POLICY_VERSION);
  assert(vectors.edge_rendition_hash.length >= 5);
});

async function* walk(dir: URL): AsyncGenerator<URL> {
  for await (const entry of Deno.readDir(dir)) {
    if (["build", ".git", "node_modules", "DerivedData", ".build", "xcuserdata"].includes(entry.name)) continue;
    const child = new URL(entry.name + (entry.isDirectory ? "/" : ""), dir);
    if (entry.isDirectory) yield* walk(child);
    else yield child;
  }
}

Deno.test("no ElevenLabs or Supabase secret key is committed anywhere in the repository", async () => {
  const pattern = /\b(sk_[0-9a-f]{32,}|sb_secret_[A-Za-z0-9_-]{20,}|eyJhbGciOi[A-Za-z0-9_-]{60,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,})/;
  const skip = /\.(mp3|png|jpg|jpeg|pdf|caf|wav|lock|xcuserstate)$/i;
  const offenders: string[] = [];
  for await (const file of walk(root)) {
    if (skip.test(file.pathname)) continue;
    let text: string;
    try { text = await Deno.readTextFile(file); } catch { continue; }
    if (pattern.test(text)) offenders.push(file.pathname.replace(root.pathname, ""));
  }
  assertEquals(offenders, [], "secret-looking key found in: " + offenders.join(", "));
});
