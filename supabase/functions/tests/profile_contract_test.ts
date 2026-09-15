import {
  assert,
  assertEquals,
  assertMatch,
  assertNotEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// "Ben" sekmesinin sunucu sözleşmesi: şifreli alanlar sahibine geri okunabilir,
// ölçümler yol başına tekil.

Deno.env.set("PATIKA_DATA_ENCRYPTION_KEY", btoa(String.fromCharCode(...new Uint8Array(32).fill(7))));
const { encryptSensitiveText, decryptSensitiveText } = await import("../_shared/encryption.ts");

Deno.test("sensitive text round-trips and never repeats ciphertext", async () => {
  const text = "Geceleri yatağa girince kafam durmuyor.";
  const first = await encryptSensitiveText(text);
  const second = await encryptSensitiveText(text);
  assertMatch(first, /^v1\.[A-Za-z0-9+/=]+\.[A-Za-z0-9+/=]+$/);
  assertNotEquals(first, second);
  assertEquals(await decryptSensitiveText(first), text);
});

Deno.test("tampered or malformed ciphertext is rejected", async () => {
  const ciphertext = await encryptSensitiveText("Deneme");
  const [version, nonce, payload] = ciphertext.split(".");
  const tampered = `${version}.${nonce}.${payload.slice(0, -4)}AAAA`;
  await assertRejects(() => decryptSensitiveText(tampered));
  await assertRejects(() => decryptSensitiveText("v2.abc.def"), Error, "invalid_ciphertext");
});

Deno.test("measurement migration scopes uniqueness per path and keeps one baseline", async () => {
  const sql = await Deno.readTextFile(
    new URL("../../migrations/20260912120000_measurements_per_path.sql", import.meta.url),
  );
  assertMatch(sql, /add column path_id uuid references public\.program_paths\(id\) on delete cascade/i);
  assertMatch(sql, /drop index if exists public\.measurements_user_day_idx/i);
  assertMatch(sql, /measurements_user_baseline_idx[\s\S]+where measurement_day = 0/i);
  assertMatch(sql, /measurements_path_day_idx[\s\S]+\(path_id, measurement_day\)/i);
  assert(/p\.user_id = \(select auth\.uid\(\)\)/i.test(sql), "insert policy must check path ownership");
});
