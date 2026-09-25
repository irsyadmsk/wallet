-- Crypto portfolio holdings, synced like every other ledger table: one
-- jsonb `data` row per holding under the ledger owner's `user_id`, readable
-- and writable by the owner and their household members. Purely additive.

create table if not exists public.crypto_holdings (
  id text not null,
  user_id uuid not null references auth.users (id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_id, id)
);

create index if not exists crypto_holdings_user_updated_idx
  on public.crypto_holdings (user_id, updated_at);

-- Server clock drives the pull cursor (see SyncService._pullRemote).
drop trigger if exists set_updated_at on public.crypto_holdings;
create trigger set_updated_at
  before insert or update on public.crypto_holdings
  for each row execute function public.set_updated_at();

alter table public.crypto_holdings enable row level security;

create policy "select ledger crypto_holdings" on public.crypto_holdings
  for select to authenticated
  using (user_id in (select private.accessible_ledgers()));
create policy "insert ledger crypto_holdings" on public.crypto_holdings
  for insert to authenticated
  with check (user_id in (select private.accessible_ledgers()));
create policy "update ledger crypto_holdings" on public.crypto_holdings
  for update to authenticated
  using (user_id in (select private.accessible_ledgers()))
  with check (user_id in (select private.accessible_ledgers()));
create policy "delete ledger crypto_holdings" on public.crypto_holdings
  for delete to authenticated
  using (user_id in (select private.accessible_ledgers()));

-- Live updates for family members (Realtime applies RLS per subscriber).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'crypto_holdings'
  ) then
    alter publication supabase_realtime add table public.crypto_holdings;
  end if;
end $$;
