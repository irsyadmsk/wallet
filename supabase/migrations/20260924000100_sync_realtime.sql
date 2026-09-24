-- Broadcast row changes on the sync tables so family members see each
-- other's edits live. Realtime applies each table's RLS per subscriber, so
-- a client only hears about ledgers it can already read.
do $$
declare
  t text;
begin
  foreach t in array array[
    'accounts', 'categories', 'transactions', 'tags', 'budgets',
    'recurring', 'goals', 'templates', 'debts', 'memos', 'household_members'
  ] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
