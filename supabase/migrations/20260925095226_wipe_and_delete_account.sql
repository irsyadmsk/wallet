-- "Hapus total" from Settings, and in-app account deletion (also required
-- by Google Play). Both act only on the caller.

-- Soft-deletes every row of the caller's own ledger. Rows become
-- tombstones (deleted_at set, data emptied) so the caller's other devices
-- and family members pull the deletion instead of keeping stale copies.
-- A family member calling this clears their personal ledger only, never
-- the family owner's book.
create or replace function public.wipe_my_ledger()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  t text;
begin
  if uid is null then
    raise exception 'Belum login.' using errcode = '42501';
  end if;
  foreach t in array array[
    'accounts', 'categories', 'transactions', 'tags', 'budgets',
    'recurring', 'goals', 'templates', 'debts', 'memos', 'crypto_holdings'
  ] loop
    execute format(
      'update public.%I set deleted_at = now(), data = ''{}''::jsonb where user_id = $1 and deleted_at is null',
      t
    ) using uid;
  end loop;
end;
$$;

-- Permanently deletes the caller's account. Their ledger rows, household
-- (if they own one — members fall back to their own books) and membership
-- go with it through the existing ON DELETE CASCADE foreign keys.
create or replace function public.delete_my_account()
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
  delete from auth.users u where u.id = uid;
end;
$$;

revoke all on function public.wipe_my_ledger() from public, anon;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.wipe_my_ledger() to authenticated;
grant execute on function public.delete_my_account() to authenticated;
