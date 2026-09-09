create index generation_jobs_path_id_idx
  on public.generation_jobs(path_id)
  where path_id is not null;

create index audio_assets_path_step_id_idx
  on public.audio_assets(path_step_id);
