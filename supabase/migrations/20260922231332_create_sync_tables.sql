-- Generic per-entity sync tables. Each mirrors a Hive box on the client:
-- the Dart model's existing toJson()/fromJson() is stored verbatim as `data`,
-- so the Postgres schema never has to be kept in lockstep with Dart fields.
-- Sync protocol: client asks for rows where updated_at > last_sync_at
-- (including soft-deleted ones via deleted_at) and merges them into Hive.

do $$
declare
  entity text;
begin
  foreach entity in array array[
    'accounts', 'categories', 'transactions', 'tags', 'budgets',
    'recurring', 'goals', 'templates', 'debts', 'settings'
  ]
  loop
    execute format($f$
      create table if not exists public.%1$I (
        id text not null,
        user_id uuid not null references auth.users(id) on delete cascade,
        data jsonb not null,
        updated_at timestamptz not null default now(),
        deleted_at timestamptz,
        primary key (user_id, id)
      );

      create index if not exists %1$I_user_updated_idx
        on public.%1$I (user_id, updated_at);

      alter table public.%1$I enable row level security;

      drop policy if exists "select own %1$I" on public.%1$I;
      create policy "select own %1$I" on public.%1$I
        for select using (auth.uid() = user_id);

      drop policy if exists "insert own %1$I" on public.%1$I;
      create policy "insert own %1$I" on public.%1$I
        for insert with check (auth.uid() = user_id);

      drop policy if exists "update own %1$I" on public.%1$I;
      create policy "update own %1$I" on public.%1$I
        for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

      drop policy if exists "delete own %1$I" on public.%1$I;
      create policy "delete own %1$I" on public.%1$I
        for delete using (auth.uid() = user_id);
    $f$, entity);
  end loop;
end $$;

-- Always stamp updated_at server-side so conflict resolution never trusts
-- a client clock.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare
  entity text;
begin
  foreach entity in array array[
    'accounts', 'categories', 'transactions', 'tags', 'budgets',
    'recurring', 'goals', 'templates', 'debts', 'settings'
  ]
  loop
    execute format(
      'drop trigger if exists set_updated_at on public.%1$I;
       create trigger set_updated_at before insert or update on public.%1$I
       for each row execute function public.set_updated_at();',
      entity
    );
  end loop;
end $$;
