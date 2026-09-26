-- Kişisel slot sesi hiç kaydedilemiyordu: `audio_assets` upsert'i
-- `on conflict (path_step_id, slot_name)` ile yazılıyor (PostgREST `on_conflict`), ama
-- indeks **kısmi** (`where slot_name is not null`). Postgres, koşulu yazılmamış bir
-- conflict hedefini kısmi indeksle eşleştiremiyor: SQLSTATE 42P10 -> `database_write_failed`.
-- Canlı duman testinde ölçüldü (2026-09-21); anahtar geçersizken sorun hiç görünmemişti.
--
-- Koşulsuz tekil indeks: `slot_name` boş olabilir ve NULL'lar birbirinden farklı sayılır,
-- yani davranış aynı, yalnızca conflict hedefi artık eşleşiyor. Tablo bu noktada boş.
drop index if exists public.audio_assets_step_slot_idx;
create unique index audio_assets_step_slot_idx
  on public.audio_assets (path_step_id, slot_name);
