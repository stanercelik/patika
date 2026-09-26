-- Purchase grants no longer wait for the webhook: path-purchase-status verifies an
-- owned transaction with RevenueCat and applies it immediately. This makes the
-- event function idempotent per transaction so the later webhook is accepted.
create or replace function public.apply_path_purchase_event(
  p_event_id text, p_event_type text, p_user_id uuid,
  p_product_id text, p_transaction_id text, p_purchased_at timestamptz,
  p_expiration_at timestamptz default null
)
returns text language plpgsql security definer set search_path = '' as $$
declare
  matched_intent public.path_purchase_intents%rowtype;
  review_path_id uuid;
  changed_rows integer;
begin
  if p_event_id is null or p_transaction_id is null then
    raise exception 'invalid_purchase_event';
  end if;
  if exists (select 1 from public.revenuecat_webhook_events where event_id = p_event_id) then
    return 'duplicate';
  end if;

  if p_event_type = 'NON_RENEWING_PURCHASE' then
    -- The same transaction may arrive twice: once from path-purchase-status, which
    -- verifies it with RevenueCat right after the purchase, and later from the
    -- webhook. The second arrival is recorded, not retried forever.
    if exists (select 1 from public.path_purchase_grants
               where transaction_id = p_transaction_id and user_id = p_user_id
                 and source = 'purchase') then
      insert into public.revenuecat_webhook_events(event_id, event_type, transaction_id)
        values (p_event_id, p_event_type, p_transaction_id);
      return 'already_applied';
    end if;
    select * into matched_intent from public.path_purchase_intents
    where user_id = p_user_id and product_id = p_product_id
      and fulfilled_at is null and cancelled_at is null
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
      on conflict (path_id) do update set
        source = 'purchase', transaction_id = excluded.transaction_id,
        granted_at = now(), expires_at = null, revoked_at = null
      where public.path_purchase_grants.user_id = p_user_id
        and (public.path_purchase_grants.revoked_at is not null
          or public.path_purchase_grants.expires_at <= now());
    get diagnostics changed_rows = row_count;
    if changed_rows <> 1 then raise exception 'path_already_unlocked'; end if;
    update public.path_purchase_intents
      set fulfilled_at = now(), transaction_id = p_transaction_id
      where id = matched_intent.id;
  elsif p_event_type = 'CANCELLATION' then
    update public.path_purchase_grants set revoked_at = now()
      where transaction_id = p_transaction_id and source = 'purchase';
  elsif p_event_type = 'REFUND_REVERSED' then
    update public.path_purchase_grants set revoked_at = null
      where transaction_id = p_transaction_id and source = 'purchase'
        and user_id = p_user_id;
  elsif p_event_type = 'SHIPATON_PROMO' then
    if p_product_id <> 'shipaton_review' or p_expiration_at is null
       or p_expiration_at <= now() then
      raise exception 'invalid_promo';
    end if;
    select p.id into review_path_id from public.program_paths p
      join public.path_steps s on s.path_id = p.id and s.day = 1
    where p.user_id = p_user_id and p.kind = 'personalized'
      and p.status = 'active' and s.completed_at is not null
    order by p.created_at desc limit 1;
    if review_path_id is null then raise exception 'promo_path_missing'; end if;
    insert into public.path_purchase_grants(
      path_id, user_id, source, transaction_id, expires_at
    ) values (
      review_path_id, p_user_id, 'shipaton_promo', p_transaction_id, p_expiration_at
    ) on conflict (path_id) do update set
      transaction_id = excluded.transaction_id,
      granted_at = now(), expires_at = excluded.expires_at, revoked_at = null
    where public.path_purchase_grants.user_id = p_user_id
      and public.path_purchase_grants.source = 'shipaton_promo'
      and public.path_purchase_grants.expires_at <= now();
  else
    return 'ignored';
  end if;
  insert into public.revenuecat_webhook_events(event_id, event_type, transaction_id)
    values (p_event_id, p_event_type, p_transaction_id);
  return 'processed';
end;
$$;
revoke all on function public.apply_path_purchase_event(text,text,uuid,text,text,timestamptz,timestamptz) from public, authenticated;
grant execute on function public.apply_path_purchase_event(text,text,uuid,text,text,timestamptz,timestamptz) to service_role;
