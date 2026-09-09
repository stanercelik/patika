create schema if not exists private;

revoke all on schema private from public, anon, authenticated;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  locale text not null default 'tr-TR' check (char_length(locale) between 2 and 35),
  analytics_subject_id uuid not null default gen_random_uuid() unique,
  name_ciphertext text,
  gender text check (gender is null or gender in ('woman', 'man', 'other', 'undisclosed')),
  age_range text check (age_range is null or age_range in ('eighteenToTwentyFour', 'twentyFiveToThirtyFour', 'thirtyFiveToFortyFour', 'fortyFiveToFiftyFour', 'fiftyFivePlus', 'undisclosed')),
  onboarding_completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.problem_statements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  raw_text_ciphertext text,
  generation_summary text check (generation_summary is null or char_length(generation_summary) <= 400),
  created_at timestamptz not null default now()
);

create table public.measurements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  variant text not null check (variant in ('a', 'b', 'c')),
  measurement_day integer not null check (measurement_day in (0, 1, 7, 14, 21, 28)),
  raw_responses jsonb not null check (jsonb_typeof(raw_responses) = 'object'),
  emotion_score numeric(5,2) check (emotion_score between 0 and 100),
  behavior_score numeric(5,2) check (behavior_score between 0 and 100),
  self_efficacy_score numeric(5,2) check (self_efficacy_score between 0 and 100),
  created_at timestamptz not null default now()
);

create table public.program_paths (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  length_days integer not null check (length_days in (7, 14, 21, 28)),
  status text not null default 'generating' check (status in ('generating', 'active', 'completed', 'cancelled', 'failed')),
  template_id text not null check (char_length(template_id) between 1 and 100),
  title text not null check (char_length(title) between 1 and 120),
  personalization_context jsonb not null default '{}'::jsonb check (jsonb_typeof(personalization_context) = 'object'),
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  check ((status = 'completed' and completed_at is not null) or status <> 'completed')
);

create table public.path_steps (
  id uuid primary key default gen_random_uuid(),
  path_id uuid not null references public.program_paths(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  day integer not null check (day between 1 and 28),
  title text not null check (char_length(title) between 1 and 120),
  block_ids text[] not null check (cardinality(block_ids) between 1 and 12),
  slot_copy jsonb not null default '{}'::jsonb check (jsonb_typeof(slot_copy) = 'object'),
  audio_status text not null default 'pending' check (audio_status in ('pending', 'processing', 'ready', 'failed')),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (path_id, day)
);

create table public.generation_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  path_id uuid references public.program_paths(id) on delete cascade,
  kind text not null check (kind in ('path', 'audio')),
  provider text not null check (provider in ('gemini', 'fallback', 'fal', 'elevenlabs')),
  provider_request_id text,
  status text not null default 'queued' check (status in ('queued', 'processing', 'succeeded', 'failed', 'blocked')),
  attempt_count integer not null default 0 check (attempt_count between 0 and 10),
  idempotency_key text not null unique check (char_length(idempotency_key) between 16 and 200),
  last_error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

create table public.audio_assets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  path_step_id uuid not null references public.path_steps(id) on delete cascade,
  storage_path text not null unique check (storage_path !~ '(^|/)\.\.(/|$)'),
  content_type text not null check (content_type in ('audio/mpeg', 'audio/wav', 'audio/mp4')),
  duration_ms integer check (duration_ms is null or duration_ms > 0),
  created_at timestamptz not null default now(),
  expires_at timestamptz
);

create index problem_statements_user_id_idx on public.problem_statements(user_id);
create index measurements_user_id_created_at_idx on public.measurements(user_id, created_at desc);
create index program_paths_user_id_status_idx on public.program_paths(user_id, status);
create index path_steps_user_id_idx on public.path_steps(user_id);
create index generation_jobs_user_id_status_idx on public.generation_jobs(user_id, status);
create index generation_jobs_provider_request_id_idx on public.generation_jobs(provider_request_id) where provider_request_id is not null;
create index audio_assets_user_id_idx on public.audio_assets(user_id);

create trigger profiles_set_updated_at before update on public.profiles
for each row execute function private.set_updated_at();

create trigger generation_jobs_set_updated_at before update on public.generation_jobs
for each row execute function private.set_updated_at();

alter table public.profiles enable row level security;
alter table public.problem_statements enable row level security;
alter table public.measurements enable row level security;
alter table public.program_paths enable row level security;
alter table public.path_steps enable row level security;
alter table public.generation_jobs enable row level security;
alter table public.audio_assets enable row level security;

create policy profiles_select_own on public.profiles
for select to authenticated using ((select auth.uid()) = user_id);
create policy profiles_insert_own on public.profiles
for insert to authenticated with check ((select auth.uid()) = user_id);
create policy profiles_update_own on public.profiles
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy profiles_delete_own on public.profiles
for delete to authenticated using ((select auth.uid()) = user_id);

create policy problem_statements_select_own on public.problem_statements
for select to authenticated using ((select auth.uid()) = user_id);
create policy measurements_select_own on public.measurements
for select to authenticated using ((select auth.uid()) = user_id);
create policy program_paths_select_own on public.program_paths
for select to authenticated using ((select auth.uid()) = user_id);
create policy path_steps_select_own on public.path_steps
for select to authenticated using ((select auth.uid()) = user_id);
create policy generation_jobs_select_own on public.generation_jobs
for select to authenticated using ((select auth.uid()) = user_id);
create policy audio_assets_select_own on public.audio_assets
for select to authenticated using ((select auth.uid()) = user_id);

revoke all on all tables in schema public from anon, authenticated;
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles to authenticated;
grant select on public.problem_statements, public.measurements, public.program_paths,
  public.path_steps, public.generation_jobs, public.audio_assets to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('private_audio', 'private_audio', false, 52428800, array['audio/mpeg', 'audio/wav', 'audio/mp4'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy private_audio_select_own on storage.objects
for select to authenticated
using (
  bucket_id = 'private_audio'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
