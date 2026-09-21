import {
  assert,
  assertMatch,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const migrationUrl = new URL(
  "../../migrations/20260909150000_adaptive_session_engine.sql",
  import.meta.url,
);

Deno.test("adaptive session migration creates durable queue and manifests", async () => {
  const sql = await Deno.readTextFile(migrationUrl);

  assertMatch(sql, /create extension if not exists pgmq/i);
  assertMatch(sql, /pgmq\.create\('patika_audio_jobs'/i);
  assertMatch(sql, /add column kind text not null default 'personalized'/i);
  assertMatch(sql, /create table public\.session_manifests/i);
  assertMatch(sql, /create or replace function public\.enqueue_audio_job/i);
  assertMatch(sql, /create or replace function public\.read_audio_jobs/i);
  assertMatch(sql, /create or replace function public\.archive_audio_job/i);
});

Deno.test("adaptive session migration preserves privacy and prepared-path boundary", async () => {
  const sql = await Deno.readTextFile(migrationUrl);

  assertMatch(sql, /path_kind in \('personalized', 'prepared'\)/i);
  assertMatch(sql, /prepared_path_has_no_personalization/i);
  assertMatch(sql, /enable row level security/i);
  assertMatch(sql, /session_manifests_select_own/i);
  assertMatch(sql, /security_invoker\s*=\s*true/i);
  assert(!/grant\s+select[^;]+generation_payload_ciphertext[^;]+authenticated/is.test(sql));
});


const migration = (name: string) => Deno.readTextFile(new URL(`../../migrations/${name}`, import.meta.url));

Deno.test("pacing migration turns single-breath beats into written milliseconds", async () => {
  const sql = await migration("20260921100000_block_script_pacing.sql");
  // Yalnızca iki konuşma arası, landOn'suz tek nefeslik bekleme vuruşa dönüşür.
  assertMatch(sql, /\{"type":"silence","ms":\d+\}/);
  assert(!/"breaths":1\}/.test(sql), "no plain single-breath pause may remain in updated scripts");
  // Kasten bir fazda biten bekleme (landOn) ve gerçek pratik duraklamaları korunur.
  assertMatch(sql, /"breaths":1,"landOn":"exhale"/);
  assertMatch(sql, /"breaths":4,"landOn":"exhale"/);
  // Eski seed'ler düzenlenmez; blok sürümü artmaz (ses yeniden render edilmez).
  assert(!/set\s+version/i.test(sql));
});

Deno.test("pacing migration updates rows before adding the CHECK constraint", async () => {
  const sql = await migration("20260921100000_block_script_pacing.sql");
  assert(sql.lastIndexOf("update public.blocks") < sql.indexOf("add constraint blocks_script_shape"));
  assertMatch(sql, /\(entry \? 'ms'\) = \(entry \? 'breaths'\)/);
});

Deno.test("invalidation touches derived artifacts only, never the audio files", async () => {
  const sql = await migration("20260921100100_invalidate_session_manifests.sql");
  assertMatch(sql, /delete from public\.session_manifests/i);
  assertMatch(sql, /completed_at is null/i);
  assert(!/(delete from|truncate|update)\s+public\.(block_audio|audio_assets)/i.test(sql));
});

Deno.test("silence metrics migration is additive and nullable", async () => {
  const sql = await migration("20260921090000_audio_silence_metrics.sql");
  assertMatch(sql, /add column lead_silence_ms integer/i);
  assertMatch(sql, /add column tail_silence_ms integer/i);
  assert(!/not null/i.test(sql));
});
