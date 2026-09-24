-- Family ("akun keluarga") sharing for the wallet sync tables.
--
-- Model: every synced row still lives under one `user_id` — the *ledger
-- owner*. A household is owned by one user; members who join it read and
-- write the owner's ledger instead of their own. A user belongs to at most
-- one household. Nothing here deletes or rewrites existing rows.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 60),
  owner_id uuid not null unique references auth.users (id) on delete cascade,
  invite_code text not null unique check (invite_code ~ '^[A-Z2-9]{8}$'),
  created_at timestamptz not null default now()
);

create table public.household_members (
  household_id uuid not null references public.households (id) on delete cascade,
  user_id uuid not null unique references auth.users (id) on delete cascade,
  role text not null check (role in ('owner', 'member')),
  display_name text check (display_name is null or char_length(display_name) <= 60),
  email text,
  joined_at timestamptz not null default now(),
  primary key (household_id, user_id)
);

alter table public.households enable row level security;
alter table public.household_members enable row level security;

-- Helpers live in `private` so PostgREST never exposes them as RPCs.
-- security definer lets them read membership without tripping RLS
-- recursion on household_members.
create or replace function private.my_household_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select m.household_id
  from public.household_members m
  where m.user_id = (select auth.uid());
$$;

-- Ledgers the caller may touch: their own, plus their household owner's.
create or replace function private.accessible_ledgers()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid())
  union
  select h.owner_id
  from public.household_members m
  join public.households h on h.id = m.household_id
  where m.user_id = (select auth.uid());
$$;

revoke all on function private.my_household_id() from public;
revoke all on function private.accessible_ledgers() from public;
grant execute on function private.my_household_id() to authenticated;
grant execute on function private.accessible_ledgers() to authenticated;

create policy "members read their household"
  on public.households for select to authenticated
  using (id = (select private.my_household_id()));

create policy "members read fellow members"
  on public.household_members for select to authenticated
  using (household_id = (select private.my_household_id()));

-- Writes to households/household_members only happen through the RPCs
-- below, so no insert/update/delete policies are granted.

-- Swap every sync table's "own rows only" policies for "own or family
-- ledger" ones. `user_id in (select ...)` runs the helper once per query
-- (initPlan), not once per row.
do $$
declare
  t text;
begin
  foreach t in array array[
    'accounts', 'categories', 'transactions', 'tags', 'budgets',
    'recurring', 'goals', 'templates', 'debts', 'memos'
  ] loop
    execute format('drop policy if exists "select own %1$s" on public.%1$I', t);
    execute format('drop policy if exists "insert own %1$s" on public.%1$I', t);
    execute format('drop policy if exists "update own %1$s" on public.%1$I', t);
    execute format('drop policy if exists "delete own %1$s" on public.%1$I', t);

    execute format(
      'create policy "select ledger %1$s" on public.%1$I for select to authenticated
         using (user_id in (select private.accessible_ledgers()))', t);
    execute format(
      'create policy "insert ledger %1$s" on public.%1$I for insert to authenticated
         with check (user_id in (select private.accessible_ledgers()))', t);
    execute format(
      'create policy "update ledger %1$s" on public.%1$I for update to authenticated
         using (user_id in (select private.accessible_ledgers()))
         with check (user_id in (select private.accessible_ledgers()))', t);
    execute format(
      'create policy "delete ledger %1$s" on public.%1$I for delete to authenticated
         using (user_id in (select private.accessible_ledgers()))', t);

    execute format(
      'create index if not exists %1$s_user_updated_idx on public.%1$I (user_id, updated_at)', t);
  end loop;
end $$;

-- 8 chars from an alphabet without look-alikes (no 0/O, 1/I/L).
create or replace function private.new_invite_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  code text;
begin
  loop
    code := '';
    for i in 1..8 loop
      code := code || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from public.households h where h.invite_code = code);
  end loop;
  return code;
end;
$$;
revoke all on function private.new_invite_code() from public;

create or replace function public.create_household(p_name text, p_display_name text default null)
returns public.households
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  result public.households;
begin
  if uid is null then
    raise exception 'Belum login.' using errcode = '42501';
  end if;
  if exists (select 1 from public.household_members m where m.user_id = uid) then
    raise exception 'Anda sudah tergabung dalam sebuah keluarga.' using errcode = 'P0001';
  end if;

  insert into public.households (name, owner_id, invite_code)
  values (btrim(p_name), uid, private.new_invite_code())
  returning * into result;

  insert into public.household_members (household_id, user_id, role, display_name, email)
  values (result.id, uid, 'owner', nullif(btrim(p_display_name), ''),
          (select u.email from auth.users u where u.id = uid));

  return result;
end;
$$;

create or replace function public.join_household(p_code text, p_display_name text default null)
returns public.households
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  result public.households;
begin
  if uid is null then
    raise exception 'Belum login.' using errcode = '42501';
  end if;
  if exists (select 1 from public.household_members m where m.user_id = uid) then
    raise exception 'Anda sudah tergabung dalam sebuah keluarga.' using errcode = 'P0001';
  end if;

  select * into result
  from public.households h
  where h.invite_code = upper(btrim(p_code));

  if result.id is null then
    raise exception 'Kode undangan tidak ditemukan.' using errcode = 'P0002';
  end if;

  insert into public.household_members (household_id, user_id, role, display_name, email)
  values (result.id, uid, 'member', nullif(btrim(p_display_name), ''),
          (select u.email from auth.users u where u.id = uid));

  return result;
end;
$$;

-- Owner leaving dissolves the household (members fall back to their own
-- ledgers); a member leaving just drops their membership.
create or replace function public.leave_household()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
begin
  if uid is null then
    raise exception 'Belum login.' using errcode = '42501';
  end if;
  delete from public.households h where h.owner_id = uid;
  delete from public.household_members m where m.user_id = uid;
end;
$$;

create or replace function public.remove_household_member(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  hid uuid;
begin
  select h.id into hid from public.households h where h.owner_id = uid;
  if hid is null then
    raise exception 'Hanya pemilik keluarga yang dapat mengeluarkan anggota.' using errcode = '42501';
  end if;
  if p_user_id = uid then
    raise exception 'Pemilik tidak dapat mengeluarkan dirinya sendiri.' using errcode = 'P0001';
  end if;
  delete from public.household_members m where m.household_id = hid and m.user_id = p_user_id;
end;
$$;

create or replace function public.regenerate_household_code()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  code text;
begin
  code := private.new_invite_code();
  update public.households h set invite_code = code where h.owner_id = uid;
  if not found then
    raise exception 'Hanya pemilik keluarga yang dapat mengganti kode.' using errcode = '42501';
  end if;
  return code;
end;
$$;

create or replace function public.update_household(p_name text default null, p_display_name text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
begin
  if uid is null then
    raise exception 'Belum login.' using errcode = '42501';
  end if;
  if p_name is not null then
    update public.households h set name = btrim(p_name) where h.owner_id = uid;
  end if;
  if p_display_name is not null then
    update public.household_members m
    set display_name = nullif(btrim(p_display_name), '')
    where m.user_id = uid;
  end if;
end;
$$;

revoke all on function public.create_household(text, text) from public, anon;
revoke all on function public.join_household(text, text) from public, anon;
revoke all on function public.leave_household() from public, anon;
revoke all on function public.remove_household_member(uuid) from public, anon;
revoke all on function public.regenerate_household_code() from public, anon;
revoke all on function public.update_household(text, text) from public, anon;
grant execute on function public.create_household(text, text) to authenticated;
grant execute on function public.join_household(text, text) to authenticated;
grant execute on function public.leave_household() to authenticated;
grant execute on function public.remove_household_member(uuid) to authenticated;
grant execute on function public.regenerate_household_code() to authenticated;
grant execute on function public.update_household(text, text) to authenticated;

grant select on public.households to authenticated;
grant select on public.household_members to authenticated;
