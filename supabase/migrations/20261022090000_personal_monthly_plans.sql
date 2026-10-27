-- Personal planning documents; deliberately excluded from accessible_ledgers().
create table public.personal_monthly_plans (
  user_id uuid not null references auth.users(id) on delete cascade,
  period text not null check (period in ('template','reserves') or period ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),
  data jsonb not null check (jsonb_typeof(data) = 'object' and octet_length(data::text) <= 524288),
  revision bigint not null default 1 check (revision > 0),
  updated_at timestamptz not null default now(),
  primary key(user_id,period)
);
alter table public.personal_monthly_plans enable row level security;
create policy own_plan_read on public.personal_monthly_plans for select to authenticated
  using (user_id = (select auth.uid()));
-- Only the narrow RPC writes. Authenticated clients cannot bypass revision checks.
revoke all on public.personal_monthly_plans from anon, authenticated;
grant select on public.personal_monthly_plans to authenticated;

create schema if not exists wallet_private;
revoke all on schema wallet_private from public, anon;
grant usage on schema wallet_private to authenticated;
create function wallet_private.save_personal_monthly_plan(p_period text, p_expected_revision bigint, p_data jsonb)
returns bigint language plpgsql security definer set search_path = '' as $$
declare actor uuid := auth.uid(); next_revision bigint;
begin
  if actor is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if p_expected_revision is null or p_expected_revision < 0 then raise exception 'Invalid revision'; end if;
  if p_data->>'version' is distinct from '1' or jsonb_typeof(p_data->'items') is distinct from 'array'
    or jsonb_array_length(p_data->'items') > 200 then raise exception 'Invalid plan'; end if;
  if p_expected_revision = 0 then
    insert into public.personal_monthly_plans(user_id,period,data) values(actor,p_period,p_data)
      on conflict do nothing returning revision into next_revision;
  else
    update public.personal_monthly_plans set data=p_data, revision=revision+1, updated_at=now()
      where user_id=actor and period=p_period and revision=p_expected_revision returning revision into next_revision;
  end if;
  if next_revision is null then raise exception 'Rencana berubah di perangkat lain. Muat versi server sebelum menggabungkan perubahan.' using errcode = '40001'; end if;
  return next_revision;
end $$;
revoke all on function wallet_private.save_personal_monthly_plan(text,bigint,jsonb) from public, anon;
grant execute on function wallet_private.save_personal_monthly_plan(text,bigint,jsonb) to authenticated;
create function public.save_personal_monthly_plan(p_period text,p_expected_revision bigint,p_data jsonb)
returns bigint language sql security invoker set search_path = '' as $$
  select wallet_private.save_personal_monthly_plan(p_period,p_expected_revision,p_data);
$$;
revoke all on function public.save_personal_monthly_plan(text,bigint,jsonb) from public, anon;
grant execute on function public.save_personal_monthly_plan(text,bigint,jsonb) to authenticated;
