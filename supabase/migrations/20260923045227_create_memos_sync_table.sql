create table if not exists public.memos (
  id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_id, id)
);

create index if not exists memos_user_updated_idx on public.memos (user_id, updated_at);

alter table public.memos enable row level security;

create policy "select own memos" on public.memos
  for select using (auth.uid() = user_id);
create policy "insert own memos" on public.memos
  for insert with check (auth.uid() = user_id);
create policy "update own memos" on public.memos
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "delete own memos" on public.memos
  for delete using (auth.uid() = user_id);

drop trigger if exists set_updated_at on public.memos;
create trigger set_updated_at before insert or update on public.memos
for each row execute function public.set_updated_at();
