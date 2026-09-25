-- One-off data fix: an .mmbak "replace all" import ran on a device that had
-- only part of the ledger (pulls were capped at 1,000 rows), so older rows
-- it never saw were left beside their re-imported copies (identical
-- externalId). Soft-delete the older copy only; `data` is kept and the ids
-- are recorded so this can be undone:
--   update public.transactions t set deleted_at = null
--   from private.dedupe_20260925 d where t.user_id = d.user_id and t.id = d.id;
create table if not exists private.dedupe_20260925 (
  user_id uuid not null,
  id text not null,
  external_id text,
  primary key (user_id, id)
);
revoke all on private.dedupe_20260925 from public, anon, authenticated;

with newer as (
  select distinct user_id, data->>'externalId' ext
  from public.transactions
  where deleted_at is null and data->>'externalId' is not null
    and updated_at >= '2026-09-25 06:00:00+00'
)
insert into private.dedupe_20260925 (user_id, id, external_id)
select t.user_id, t.id, t.data->>'externalId'
from public.transactions t
join newer n on n.user_id = t.user_id and n.ext = t.data->>'externalId'
where t.deleted_at is null and t.updated_at < '2026-09-25 06:00:00+00'
on conflict do nothing;

update public.transactions t
set deleted_at = now()
from private.dedupe_20260925 d
where t.user_id = d.user_id and t.id = d.id and t.deleted_at is null;
