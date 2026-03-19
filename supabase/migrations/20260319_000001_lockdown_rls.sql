-- Lock down direct client write access while keeping read access for leaderboard views.
-- Edge Functions using service_role continue to work because service_role bypasses RLS.

begin;

-- Ensure RLS is active.
alter table if exists public.users enable row level security;
alter table if exists public.snapshots enable row level security;

-- Remove broad table-level write privileges from client roles.
revoke insert, update, delete on table public.users from anon, authenticated;
revoke insert, update, delete on table public.snapshots from anon, authenticated;

-- Keep read capability for app screens that render leaderboard and stats.
grant select on table public.users to anon, authenticated;
grant select on table public.snapshots to anon, authenticated;

-- Recreate read-only policies idempotently.
do $$
begin
  if exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'users'
      and policyname = 'users_read_public'
  ) then
    drop policy users_read_public on public.users;
  end if;

  create policy users_read_public
    on public.users
    for select
    to anon, authenticated
    using (true);
end
$$;

do $$
begin
  if exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'snapshots'
      and policyname = 'snapshots_read_public'
  ) then
    drop policy snapshots_read_public on public.snapshots;
  end if;

  create policy snapshots_read_public
    on public.snapshots
    for select
    to anon, authenticated
    using (true);
end
$$;

commit;
