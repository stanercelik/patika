-- Durable just-in-time session generation for personalized paths.
-- Prepared paths deliberately bypass questions, Gemini and personal TTS.

create schema if not exists pgmq;
create extension if not exists pgmq with schema pgmq;

do $$
begin
  if not exists (
    select 1 from pgmq.list_queues() where queue_name = 'patika_audio_jobs'
  ) then
    perform pgmq.create('patika_audio_jobs');
  end if;
end;
$$;

alter table public.program_paths
  add column kind text not null default 'personalized'
    check (kind in ('personalized', 'prepared'));

alter table public.path_steps
  drop constraint if exists path_steps_step_question_check;

alter table public.path_steps
  add constraint path_steps_step_question_check
    check (step_question is null or char_length(step_question) between 1 and 120);

alter table public.generation_jobs
  add column path_step_id uuid references public.path_steps(id) on delete cascade,
  add column rendition_hash text check (
    rendition_hash is null or rendition_hash ~ '^[a-f0-9]{64}$'
  ),
  add column generation_payload_ciphertext text;

create index generation_jobs_path_step_id_idx
  on public.generation_jobs(path_step_id)
  where path_step_id is not null;

create unique index generation_jobs_active_audio_rendition_idx
  on public.generation_jobs(user_id, path_step_id, rendition_hash)
  where kind = 'audio' and rendition_hash is not null
    and status in ('queued', 'processing', 'succeeded');

alter table public.audio_assets
  add column rendition_hash text check (
    rendition_hash is null or rendition_hash ~ '^[a-f0-9]{64}$'
  );

create unique index audio_assets_rendition_hash_idx
  on public.audio_assets(user_id, rendition_hash)
  where rendition_hash is not null;

alter table public.block_audio
  add column rendition_hash text check (
    rendition_hash is null or rendition_hash ~ '^[a-f0-9]{64}$'
  );

create unique index block_audio_rendition_hash_idx
  on public.block_audio(rendition_hash)
  where rendition_hash is not null;

create table public.voice_previews (
  id uuid primary key default gen_random_uuid(),
  locale text not null check (locale in ('tr', 'en')),
  voice_preference text not null check (voice_preference in ('feminine', 'masculine')),
  storage_path text not null unique check (storage_path !~ '(^|/)\.\.(/|$)'),
  content_type text not null default 'audio/mpeg' check (content_type = 'audio/mpeg'),
  duration_ms integer not null check (duration_ms > 0),
  model_id text not null,
  rendition_hash text not null unique check (rendition_hash ~ '^[a-f0-9]{64}$'),
  created_at timestamptz not null default now(),
  unique (locale, voice_preference)
);

alter table public.voice_previews enable row level security;
create policy voice_previews_select_all on public.voice_previews
for select to authenticated using (true);
grant select on public.voice_previews to authenticated;

create table public.session_manifests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  path_step_id uuid not null references public.path_steps(id) on delete cascade,
  version integer not null default 1 check (version > 0),
  path_kind text not null check (path_kind in ('personalized', 'prepared')),
  locale text not null check (locale in ('tr', 'en')),
  voice_preference text not null check (voice_preference in ('feminine', 'masculine')),
  adaptive_question text check (
    adaptive_question is null or char_length(adaptive_question) between 1 and 120
  ),
  manifest jsonb not null check (
    jsonb_typeof(manifest) = 'object'
    and jsonb_typeof(manifest->'events') = 'array'
    and jsonb_array_length(manifest->'events') between 1 and 100
  ),
  total_duration_ms integer not null check (total_duration_ms > 0),
  rendition_hash text not null check (rendition_hash ~ '^[a-f0-9]{64}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (path_step_id, version),
  unique (path_step_id, rendition_hash),
  constraint prepared_path_has_no_personalization check (
    path_kind <> 'prepared' or adaptive_question is null
  )
);

create index session_manifests_user_step_idx
  on public.session_manifests(user_id, path_step_id);

create trigger session_manifests_set_updated_at before update on public.session_manifests
for each row execute function private.set_updated_at();

alter table public.session_manifests enable row level security;
create policy session_manifests_select_own on public.session_manifests
for select to authenticated using ((select auth.uid()) = user_id);
grant select on public.session_manifests to authenticated;

create or replace function private.enforce_prepared_path_has_no_personalization()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  selected_kind text;
begin
  select kind into selected_kind
  from public.program_paths
  where id = new.path_id;

  if selected_kind = 'prepared' and (
    new.step_question is not null or new.slot_copy <> '{}'::jsonb
  ) then
    raise exception 'prepared_path_has_no_personalization';
  end if;
  return new;
end;
$$;

create trigger path_steps_prepared_path_has_no_personalization
before insert or update of path_id, step_question, slot_copy on public.path_steps
for each row execute function private.enforce_prepared_path_has_no_personalization();

create or replace function private.enforce_prepared_path_context()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.kind = 'prepared' and new.personalization_context <> '{}'::jsonb then
    raise exception 'prepared_path_has_no_personalization';
  end if;

  if new.kind = 'prepared' and exists (
    select 1 from public.path_steps
    where path_id = new.id
      and (step_question is not null or slot_copy <> '{}'::jsonb)
  ) then
    raise exception 'prepared_path_has_no_personalization';
  end if;
  return new;
end;
$$;

create trigger program_paths_prepared_path_has_no_personalization
before insert or update of kind, personalization_context on public.program_paths
for each row execute function private.enforce_prepared_path_context();

-- Keep the release gate readable without executing it with the view owner's
-- privileges. The view must be empty before production audio rendering is enabled.
create or replace view public.unreviewed_blocks
with (security_invoker = true)
as
select id, version, technique, created_at
from public.blocks
where reviewed_at is null;

create or replace function public.enqueue_audio_job(job_id uuid)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  message_id bigint;
begin
  if not exists (
    select 1 from public.generation_jobs
    where id = job_id and kind = 'audio' and status in ('queued', 'processing')
  ) then
    raise exception 'audio_job_not_enqueueable';
  end if;

  select pgmq.send(
    queue_name => 'patika_audio_jobs',
    msg => jsonb_build_object('job_id', job_id)
  ) into message_id;
  return message_id;
end;
$$;

create or replace function public.read_audio_jobs(visibility_timeout_seconds integer default 90, quantity integer default 1)
returns table (
  msg_id bigint,
  read_ct integer,
  enqueued_at timestamptz,
  vt timestamptz,
  message jsonb
)
language sql
security definer
set search_path = ''
as $$
  select r.msg_id, r.read_ct, r.enqueued_at, r.vt, r.message
  from pgmq.read(
    queue_name => 'patika_audio_jobs',
    vt => greatest(1, least(visibility_timeout_seconds, 900)),
    qty => greatest(1, least(quantity, 10))
  ) as r;
$$;

create or replace function public.archive_audio_job(message_id bigint)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select pgmq.archive('patika_audio_jobs', message_id);
$$;

revoke all on function public.enqueue_audio_job(uuid) from public, anon, authenticated;
revoke all on function public.read_audio_jobs(integer, integer) from public, anon, authenticated;
revoke all on function public.archive_audio_job(bigint) from public, anon, authenticated;
grant execute on function public.enqueue_audio_job(uuid) to service_role;
grant execute on function public.read_audio_jobs(integer, integer) to service_role;
grant execute on function public.archive_audio_job(bigint) to service_role;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('voice_previews', 'voice_previews', true, 10485760, array['audio/mpeg'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
