-- A consumable purchase opens exactly one personalized path. The client never
-- writes grants. RevenueCat's global entitlements are deliberately not used.
create table public.path_purchase_intents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  path_id uuid not null references public.program_paths(id) on delete cascade,
  product_id text not null check (product_id in (
    'path.unlock.7d', 'path.unlock.14d', 'path.unlock.21d', 'path.unlock.28d'
  )),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  fulfilled_at timestamptz,
  transaction_id text unique,
  check (expires_at > created_at)
);
create index path_purchase_intents_pending_idx
  on public.path_purchase_intents(user_id, product_id, created_at desc)
  where fulfilled_at is null;

create table public.path_purchase_grants (
  path_id uuid primary key references public.program_paths(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  source text not null check (source in ('purchase', 'shipaton_promo', 'free_continuation')),
  transaction_id text unique,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz
);
create index path_purchase_grants_user_idx on public.path_purchase_grants(user_id);

create table public.revenuecat_webhook_events (
  event_id text primary key,
  event_type text not null,
  transaction_id text,
  processed_at timestamptz not null default now()
);

alter table public.path_purchase_intents enable row level security;
alter table public.path_purchase_grants enable row level security;
alter table public.revenuecat_webhook_events enable row level security;
create policy path_purchase_intents_select_own on public.path_purchase_intents
  for select to authenticated using ((select auth.uid()) = user_id);
create policy path_purchase_grants_select_own on public.path_purchase_grants
  for select to authenticated using ((select auth.uid()) = user_id);
grant select on public.path_purchase_intents, public.path_purchase_grants to authenticated;

create or replace function public.can_access_path_step(p_step_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.path_steps s
    join public.program_paths p on p.id = s.path_id and p.user_id = s.user_id
    where s.id = p_step_id
      and s.user_id = (select auth.uid())
      and (
        p.kind = 'prepared' or s.day = 1 or exists (
          select 1 from public.path_purchase_grants g
          where g.path_id = s.path_id and g.user_id = s.user_id
            and g.revoked_at is null
        )
      )
  );
$$;
revoke all on function public.can_access_path_step(uuid) from public;
grant execute on function public.can_access_path_step(uuid) to authenticated;

-- Metadata remains visible on Yolum; playable manifests and audio do not.
drop policy if exists session_manifests_select_own on public.session_manifests;
create policy session_manifests_select_accessible on public.session_manifests
  for select to authenticated using (public.can_access_path_step(path_step_id));
drop policy if exists audio_assets_select_own on public.audio_assets;
create policy audio_assets_select_accessible on public.audio_assets
  for select to authenticated using (public.can_access_path_step(path_step_id));
drop policy if exists private_audio_select_own on storage.objects;
create policy private_audio_select_accessible on storage.objects
  for select to authenticated using (
    bucket_id = 'private_audio'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (
      select 1 from public.audio_assets a
      where a.storage_path = name
        and a.user_id = (select auth.uid())
        and public.can_access_path_step(a.path_step_id)
    )
  );

-- The old direct PATCH could mark paid steps complete without a purchase.
drop policy if exists path_steps_update_own on public.path_steps;
revoke update (completed_at) on public.path_steps from authenticated;

-- Called only by the service role after RevenueCat API verification. One SQL
-- transaction makes duplicate webhook deliveries and grant creation atomic.
create or replace function public.apply_path_purchase_event(
  p_event_id text, p_event_type text, p_user_id uuid,
  p_product_id text, p_transaction_id text, p_purchased_at timestamptz
)
returns text language plpgsql security definer set search_path = '' as $$
declare
  matched_intent public.path_purchase_intents%rowtype;
begin
  if p_event_id is null or p_transaction_id is null then
    raise exception 'invalid_purchase_event';
  end if;
  if exists (select 1 from public.revenuecat_webhook_events where event_id = p_event_id) then
    return 'duplicate';
  end if;

  if p_event_type = 'NON_RENEWING_PURCHASE' then
    select * into matched_intent from public.path_purchase_intents
    where user_id = p_user_id and product_id = p_product_id
      and fulfilled_at is null
      and p_purchased_at between created_at - interval '2 minutes' and expires_at
    order by created_at desc limit 1 for update;
    if matched_intent.id is null then
      -- Retry later if the intent has not arrived yet; never grant a different path.
      raise exception 'purchase_intent_missing';
    end if;
    if exists (select 1 from public.path_purchase_grants where transaction_id = p_transaction_id) then
      raise exception 'transaction_already_used';
    end if;
    insert into public.path_purchase_grants(path_id, user_id, source, transaction_id)
      values (matched_intent.path_id, p_user_id, 'purchase', p_transaction_id)
      on conflict (path_id) do nothing;
    update public.path_purchase_intents
      set fulfilled_at = now(), transaction_id = p_transaction_id
      where id = matched_intent.id;
  elsif p_event_type = 'CANCELLATION' then
    update public.path_purchase_grants set revoked_at = now()
      where transaction_id = p_transaction_id and source = 'purchase';
  else
    return 'ignored';
  end if;
  insert into public.revenuecat_webhook_events(event_id, event_type, transaction_id)
    values (p_event_id, p_event_type, p_transaction_id);
  return 'processed';
end;
$$;
revoke all on function public.apply_path_purchase_event(text,text,uuid,text,text,timestamptz) from public, authenticated;
grant execute on function public.apply_path_purchase_event(text,text,uuid,text,text,timestamptz) to service_role;
