-- Batch-level configurable Venmo surcharge (was hardcoded 10% everywhere)
-- Applied live via Supabase MCP on 2026-09-03; captured here after the fact
-- so the schema change is reproducible from Git, not just from the live DB.
alter table public.v3_batches
  add column venmo_surcharge_percent numeric not null default 10
    check (venmo_surcharge_percent between 0 and 30);

-- Per-order snapshot of the rate actually charged, so historical displays
-- (order detail, packing slip) never drift if the batch rate changes later
alter table public.v3_orders
  add column venmo_surcharge_percent numeric;

-- Backfill: every existing Venmo order was charged exactly 10% (the only
-- rate that ever existed before this migration)
update public.v3_orders
  set venmo_surcharge_percent = 10
  where payment_method = 'venmo' and venmo_fee > 0;

-- get_active_v3_batch() explicitly lists columns (deliberate cost-hiding
-- pattern) so the new column must be added to its return list by hand.
-- drop+create resets privileges, so the execute grant is re-applied below.
drop function public.get_active_v3_batch();

create function public.get_active_v3_batch()
 returns table(id uuid, label text, status text, close_date timestamptz, customer_flyer_url text, shipping_fee numeric, admin_fee numeric, venmo_enabled boolean, venmo_surcharge_percent numeric, info_bullets jsonb)
 language sql security definer set search_path to 'public'
as $$
  select id, label, status, close_date, customer_flyer_url, shipping_fee, admin_fee, venmo_enabled, venmo_surcharge_percent, info_bullets
  from public.v3_batches
  where status = 'open'
  order by created_at desc
  limit 1;
$$;

grant execute on function public.get_active_v3_batch() to public, anon, authenticated, service_role;
