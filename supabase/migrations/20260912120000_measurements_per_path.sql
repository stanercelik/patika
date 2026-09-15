-- Ölçümler yola bağlanır ("Ben" sekmesi, docs/profile-design.md §18).
--
-- Tekil dizin `(user_id, measurement_day)` ikinci bir yolun 7. gün ölçümünü
-- birinci yolunkiyle çakıştırıyordu: kullanıcı ikinci yolunda ölçüm yapamazdı.
-- Yol içi ölçümler artık `path_id` taşır ve tekillik yol başına. Baseline
-- (gün 0) kullanıcıya ait kalır: onboarding'de bir kez alınır, yol taşımaz.

alter table public.measurements
  add column path_id uuid references public.program_paths(id) on delete cascade;

create index measurements_path_id_idx
  on public.measurements (path_id)
  where path_id is not null;

-- Mevcut yol içi ölçümler, kullanıcının o ölçümden önce açılmış en yeni yoluna
-- bağlanır. Eski dizin kullanıcı başına gün tekilliği sağladığı için bu
-- eşlemede mükerrer oluşmaz.
update public.measurements m
set path_id = (
  select p.id
  from public.program_paths p
  where p.user_id = m.user_id
    and p.created_at <= m.created_at
  order by p.created_at desc
  limit 1
)
where m.measurement_day > 0
  and m.path_id is null;

drop index if exists public.measurements_user_day_idx;

create unique index measurements_user_baseline_idx
  on public.measurements (user_id)
  where measurement_day = 0;

create unique index measurements_path_day_idx
  on public.measurements (path_id, measurement_day)
  where path_id is not null;

-- Yol içi ölçüm yolsuz yazılamaz, baseline yol taşımaz. Eşlenemeyen eski satırlar
-- (yolu hiç olmayan kullanıcı) geriye dönük doğrulanmaz.
alter table public.measurements
  add constraint measurements_path_matches_day check (
    (measurement_day = 0 and path_id is null)
    or (measurement_day > 0 and path_id is not null)
  ) not valid;

-- Kullanıcı yalnızca kendi yoluna ölçüm yazabilir.
drop policy if exists measurements_insert_own on public.measurements;
create policy measurements_insert_own on public.measurements
for insert to authenticated with check (
  (select auth.uid()) = user_id
  and (
    path_id is null
    or exists (
      select 1 from public.program_paths p
      where p.id = path_id and p.user_id = (select auth.uid())
    )
  )
);
