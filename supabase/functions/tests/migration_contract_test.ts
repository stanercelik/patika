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

