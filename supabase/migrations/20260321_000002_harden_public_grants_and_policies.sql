-- Harden client-facing table grants and deduplicate permissive read policies.
-- Keeps public read access for leaderboard views while removing unnecessary table privileges.

begin;

-- Restrict table privileges for client roles to SELECT only.
revoke all privileges on table public.users from anon, authenticated;
revoke all privileges on table public.snapshots from anon, authenticated;

grant select on table public.users to anon, authenticated;
grant select on table public.snapshots to anon, authenticated;

-- Remove legacy duplicate policies with broad public role scope.
do $$
begin
  if exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'users'
      and policyname = 'Public read users'
  ) then
    drop policy "Public read users" on public.users;
  end if;
end
$$;

do $$
begin
  if exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'snapshots'
      and policyname = 'Public read users'
  ) then
    drop policy "Public read users" on public.snapshots;
  end if;
end
$$;

-- Ensure exactly one explicit read policy per table for anon/authenticated.
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
