-- Supabase Audit: 1.3 Check RLS Policies Are Defined
-- Purpose: Verify every table with RLS has at least one policy
-- Safe: Read-only query, no data modification

WITH table_rls_status AS (
  SELECT
    schemaname,
    tablename,
    rowsecurity
  FROM pg_tables
  WHERE schemaname = 'public'
),
policy_counts AS (
  SELECT
    schemaname,
    tablename,
    COUNT(*) as policy_count
  FROM pg_policies
  GROUP BY schemaname, tablename
)
SELECT
  t.schemaname,
  t.tablename,
  t.rowsecurity as rls_enabled,
  COALESCE(p.policy_count, 0) as policy_count,
  CASE 
    WHEN t.rowsecurity = true AND COALESCE(p.policy_count, 0) = 0 
    THEN '⚠ ERROR: RLS enabled but NO POLICIES (nothing accessible except service_role)'
    WHEN t.rowsecurity = true AND COALESCE(p.policy_count, 0) > 0
    THEN '✓ OK: ' || p.policy_count || ' policy/policies defined'
    WHEN t.rowsecurity = false
    THEN '→ RLS disabled'
  END as status
FROM table_rls_status t
LEFT JOIN policy_counts p ON t.tablename = p.tablename
ORDER BY t.tablename;

-- Expected Output:
-- Each table should show "✓ OK: N policy/policies defined"
-- If ERROR appears, check policies in next script and ensure they exist
