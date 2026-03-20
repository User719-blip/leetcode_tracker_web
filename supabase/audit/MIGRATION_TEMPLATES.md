# Supabase Migration Template & Audit Fix Examples

Use these templates to create migrations for audit findings.

---

## Template 1: Enable RLS on a Table

**When**: Audit script 01 shows RLS disabled on a table

```sql
-- supabase/migrations/20260320_000002_enable_rls_TABLE_NAME.sql

BEGIN;

-- Enable RLS
ALTER TABLE public.TABLE_NAME ENABLE ROW LEVEL SECURITY;

-- Create basic policy (adjust as needed)
DROP POLICY IF EXISTS TABLE_NAME_read_public ON public.TABLE_NAME;
CREATE POLICY TABLE_NAME_read_public
  ON public.TABLE_NAME
  FOR SELECT
  TO authenticated, anon
  USING (true);

-- Verify setup
\echo 'RLS Status for TABLE_NAME:'
SELECT tablename, rowsecurity FROM pg_tables 
WHERE tablename = 'TABLE_NAME' AND schemaname = 'public';

COMMIT;
```

---

## Template 2: Fix Overly Broad Grants

**When**: Audit script 02 shows anon/authenticated can INSERT/UPDATE/DELETE

```sql
-- supabase/migrations/20260320_000002_fix_grants_TABLE_NAME.sql

BEGIN;

-- Revoke write access from anon and authenticated
REVOKE INSERT, UPDATE, DELETE ON public.TABLE_NAME FROM anon;
REVOKE INSERT, UPDATE, DELETE ON public.TABLE_NAME FROM authenticated;

-- Ensure service_role has write access (for Edge Functions/FastAPI)
GRANT INSERT, UPDATE, DELETE ON public.TABLE_NAME TO service_role;

-- Keep SELECT for public if needed (for leaderboard)
GRANT SELECT ON public.TABLE_NAME TO anon, authenticated;

-- Verify grants
\echo 'Current grants on TABLE_NAME:'
SELECT grantee, privilege_type 
FROM information_schema.table_privileges
WHERE table_name = 'TABLE_NAME' AND table_schema = 'public'
ORDER BY grantee;

COMMIT;
```

---

## Template 3: Fix RLS with No Policies

**When**: Audit script 03 shows RLS enabled but 0 policies

```sql
-- supabase/migrations/20260320_000002_create_policies_TABLE_NAME.sql

BEGIN;

-- Create SELECT policy for public access
CREATE POLICY TABLE_NAME_select_all
  ON public.TABLE_NAME
  FOR SELECT
  TO authenticated, anon
  USING (true);

-- Create INSERT policy for admins/service_role (if needed)
CREATE POLICY TABLE_NAME_insert_admin
  ON public.TABLE_NAME
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid()
      -- Add additional admin check here
    )
  );

-- Create UPDATE policy for service_role (Edge Functions)
CREATE POLICY TABLE_NAME_update_admin
  ON public.TABLE_NAME
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid()
      -- Add check
    )
  );

-- Verify policies created
\echo 'Policies on TABLE_NAME:'
SELECT policyname, cmd, roles FROM pg_policies 
WHERE tablename = 'TABLE_NAME';

COMMIT;
```

---

## Template 4: Create an RPC Function with SECURITY INVOKER

**When**: You need a new public-facing RPC that respects caller permissions

```sql
-- supabase/migrations/20260320_000002_create_function_get_user_data.sql

BEGIN;

-- Create function with SECURITY INVOKER (safer for public RPC)
CREATE OR REPLACE FUNCTION public.get_user_data(user_id UUID)
RETURNS TABLE (
  id UUID,
  username TEXT,
  total_solved INT,
  easy_solved INT,
  medium_solved INT,
  hard_solved INT
)
LANGUAGE plpgsql
SECURITY INVOKER  -- <-- Important: function runs as caller, respects their permissions
AS $$
BEGIN
  -- Input validation
  IF user_id IS NULL OR user_id = '00000000-0000-0000-0000-000000000000'::UUID THEN
    RAISE EXCEPTION 'Invalid user_id';
  END IF;

  -- Query respects RLS policies defined on the tables
  -- Only returns data the caller is allowed to see
  RETURN QUERY
  SELECT 
    u.id,
    u.username,
    COALESCE(s.total, 0) as total_solved,
    COALESCE(s.easy, 0) as easy_solved,
    COALESCE(s.medium, 0) as medium_solved,
    COALESCE(s.hard, 0) as hard_solved
  FROM public.users u
  LEFT JOIN (
    -- Get latest snapshot per user
    SELECT user_id, easy, medium, hard, 
           COALESCE(easy, 0) + COALESCE(medium, 0) + COALESCE(hard, 0) as total
    FROM public.snapshots
    WHERE user_id = $1
    ORDER BY date DESC
    LIMIT 1
  ) s ON u.id = s.user_id
  WHERE u.id = $1;  -- <-- Key: only returns data for the requested user_id
  
  -- If no results, caller doesn't have access (RLS rejected the row)
  RETURN;
END;
$$;

-- Grant EXECUTE to authenticated users
GRANT EXECUTE ON FUNCTION public.get_user_data(UUID) TO authenticated, anon;

-- Verify function created
\echo 'Function created:'
SELECT proname, prosecdef FROM pg_proc 
WHERE proname = 'get_user_data' AND pronamespace = 'public'::regnamespace;

COMMIT;
```

---

## Template 5: Create an Admin RPC with SECURITY DEFINER

**When**: You need a privileged RPC that should only be called by service_role (Edge Functions/FastAPI)

**Important**: Keep this function PRIVATE if possible, or require auth checks

```sql
-- supabase/migrations/20260320_000002_create_function_admin_update_snapshot.sql

BEGIN;

-- Create admin function with SECURITY DEFINER
-- This function should ONLY be called by service_role (Edge Functions/FastAPI backend)
-- Do NOT expose this in Supabase REST API
CREATE OR REPLACE FUNCTION public.admin_update_user_snapshot(
  p_user_id UUID,
  p_date DATE,
  p_easy INT,
  p_medium INT,
  p_hard INT,
  p_total INT,
  p_ranking INT
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  date DATE,
  easy INT,
  medium INT,
  hard INT,
  total INT,
  ranking INT,
  created_at TIMESTAMPTZ,
  status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER  -- <-- Runs as function owner (postgres), not caller
SET search_path TO public
AS $$
BEGIN
  -- Only service_role should call this
  -- But add explicit check just in case
  IF current_role NOT IN ('service_role', 'postgres') THEN
    RAISE EXCEPTION 'Only service_role can update snapshots';
  END IF;

  -- Input validation
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id is required';
  END IF;
  
  IF p_easy < 0 OR p_medium < 0 OR p_hard < 0 THEN
    RAISE EXCEPTION 'Difficulty counts cannot be negative';
  END IF;

  -- Insert or update snapshot
  RETURN QUERY
  INSERT INTO public.snapshots (user_id, date, easy, medium, hard, total, ranking)
  VALUES (p_user_id, p_date, p_easy, p_medium, p_hard, p_total, p_ranking)
  ON CONFLICT (user_id, date) DO UPDATE SET
    easy = EXCLUDED.easy,
    medium = EXCLUDED.medium,
    hard = EXCLUDED.hard,
    total = EXCLUDED.total,
    ranking = EXCLUDED.ranking
  RETURNING 
    id, user_id, date, easy, medium, hard, total, ranking, created_at,
    'snapshot_updated'::TEXT as status;
  
END;
$$;

-- Revoke from all public roles
REVOKE ALL ON FUNCTION public.admin_update_user_snapshot(
  UUID, DATE, INT, INT, INT, INT, INT
) FROM public, anon, authenticated;

-- Grant only to service_role (explicitly)
-- Note: service_role gets access by default, but being explicit is good for audit
GRANT EXECUTE ON FUNCTION public.admin_update_user_snapshot(
  UUID, DATE, INT, INT, INT, INT, INT
) TO service_role;

COMMIT;
```

---

## Template 6: Fix Weak Policy (Too Permissive)

**When**: Audit script 09 shows USING (true) or USING (NULL)

```sql
-- supabase/migrations/20260320_000002_fix_weak_policies_TABLE_NAME.sql

BEGIN;

-- Drop overly permissive policies
DROP POLICY IF EXISTS TABLE_NAME_all_access ON public.TABLE_NAME;
DROP POLICY IF EXISTS TABLE_NAME_anyone ON public.TABLE_NAME;

-- Create specific policies with proper checks

-- 1. SELECT policy for public leaderboard (if data is public)
CREATE POLICY TABLE_NAME_select_public
  ON public.TABLE_NAME
  FOR SELECT
  TO authenticated, anon
  USING (
    -- Option A: Public field check
    status = 'public'
    -- Option B: Or always for leaderboard (users read-only)
    -- OR TRUE (for public leaderboard)
  );

-- 2. INSERT policy for owners only
CREATE POLICY TABLE_NAME_insert_own
  ON public.TABLE_NAME
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- User can only insert for themselves
    auth.uid() = user_id
  );

-- 3. UPDATE policy for owners only
CREATE POLICY TABLE_NAME_update_own
  ON public.TABLE_NAME
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 4. DELETE policy for owners or admins
CREATE POLICY TABLE_NAME_delete_own
  ON public.TABLE_NAME
  FOR DELETE
  TO authenticated
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Verify new policies
\echo 'New policies on TABLE_NAME:'
SELECT policyname, cmd, roles, qual FROM pg_policies 
WHERE tablename = 'TABLE_NAME';

COMMIT;
```

---

## Template 7: Audit Everything - Quick Verification

**When**: You want to create a snapshot of current security state

```sql
-- supabase/migrations/20260320_000002_create_security_audit_snapshot.sql

BEGIN;

-- Create a table to store audit snapshots (optional)
CREATE TABLE IF NOT EXISTS public.security_audits (
  id BIGSERIAL PRIMARY KEY,
  audit_date TIMESTAMPTZ DEFAULT NOW(),
  description TEXT,
  status JSONB,
  actionable_items TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.security_audits ENABLE ROW LEVEL SECURITY;

CREATE POLICY security_audits_view ON public.security_audits
  FOR SELECT TO authenticated USING (auth.uid() IS NOT NULL);

-- Quick verification queries as views

-- View all table RLS status
CREATE OR REPLACE VIEW public.v_rls_status AS
SELECT
  tablename,
  rowsecurity,
  CASE WHEN rowsecurity THEN 'enabled' ELSE 'DISABLED' END as status
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- View all grants
CREATE OR REPLACE VIEW public.v_table_grants AS
SELECT
  grantee,
  table_name,
  string_agg(privilege_type, ', ' ORDER BY privilege_type) as privileges
FROM information_schema.table_privileges
WHERE table_schema = 'public'
GROUP BY grantee, table_name
ORDER BY table_name, grantee;

-- View all policies
CREATE OR REPLACE VIEW public.v_policies AS
SELECT
  schemaname,
  tablename,
  policyname,
  cmd,
  roles,
  qual as using_clause
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

COMMIT;
```

Then query the views:
```sql
SELECT * FROM public.v_rls_status;
SELECT * FROM public.v_table_grants;
SELECT * FROM public.v_policies;
```

---

## Template 8: Document Your RPC Functions

**When**: You want to create a reference for what each RPC does

```sql
-- supabase/migrations/20260320_000002_create_rpc_documentation.sql

BEGIN;

CREATE TABLE IF NOT EXISTS public.rpc_function_docs (
  id BIGSERIAL PRIMARY KEY,
  function_name TEXT NOT NULL,
  description TEXT,
  parameters JSONB,  -- Store as {param_name: param_type, ...}
  return_type TEXT,
  security BOOLEAN DEFAULT FALSE,  -- true = SECURITY DEFINER
  callable_by TEXT[] DEFAULT ARRAY['authenticated', 'anon'],  -- Who can execute
  example_query TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.rpc_function_docs ENABLE ROW LEVEL SECURITY;

CREATE POLICY rpc_docs_view ON public.rpc_function_docs
  FOR SELECT TO authenticated USING (TRUE);

-- Insert documentation for your RPCs
INSERT INTO public.rpc_function_docs (function_name, description, parameters, return_type, callable_by, example_query, notes)
VALUES
  (
    'get_latest_snapshots',
    'Returns the latest snapshot for each user with computed stats',
    '{}',  -- No parameters
    'TABLE(id UUID, user_id UUID, username TEXT, easy INT, medium INT, hard INT, total INT, ranking INT)',
    ARRAY['authenticated', 'anon'],
    'SELECT * FROM get_latest_snapshots();',
    'Used by leaderboard. Public read access.'
  ),
  (
    'get_weekly_comparison',
    'Compares user progress for the past week with delta calculations',
    '{}',
    'TABLE(user_id UUID, username TEXT, delta_total INT, delta_easy INT, ...)',
    ARRAY['authenticated', 'anon'],
    'SELECT * FROM get_weekly_comparison();',
    'Used by analytics dashboard. Public read access.'
  );

COMMIT;
```

---

## Before Deploying: Checklist

- [ ] All input parameters validated (type, length, pattern)
- [ ] All RPC functions reviewed for SECURITY context
- [ ] All policies reviewed for proper USING clauses
- [ ] No `USING (true)` on sensitive operations
- [ ] anon/authenticated cannot write to main data tables
- [ ] service_role has access for Edge Functions/FastAPI
- [ ] No passwords/tokens/secrets selected in policies
- [ ] Migrations tested locally first
- [ ] Migrations backed up (git commit)
- [ ] Deployment plan documented (which migrations to run)

---

**Ready to audit?** Start with:
```bash
./supabase/audit/run-audit.sh
```

Then use these templates to create fixes.
