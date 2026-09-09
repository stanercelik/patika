alter table public.generation_jobs
  drop constraint if exists generation_jobs_idempotency_key_key;

alter table public.generation_jobs
  add constraint generation_jobs_user_id_idempotency_key_key
  unique (user_id, idempotency_key);
