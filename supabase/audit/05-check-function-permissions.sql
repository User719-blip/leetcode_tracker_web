-- Supabase Audit: 2.3 Check Function call permissions
-- Purpose: Verify who has EXECUTE permission on RPC functions
-- Safe: Read-only query, no data modification

SELECT
  n.nspname as schema_name,
  p.proname as function_name,
  grantee,
  string_agg(privilege_type, ', ' ORDER BY privilege_type) as privileges,
  CASE 
    WHEN grantee = 'authenticated' AND p.proname IN ('get_latest_snapshots', 'get_weekly_comparison')
    THEN '✓ OK: Public read-only RPC accessible to authenticated users'
    WHEN grantee = 'anon' AND p.proname IN ('get_latest_snapshots', 'get_weekly_comparison')
    THEN '✓ OK: Public read-only RPC accessible to anonymous users'
    WHEN grantee IN ('anon', 'authenticated') AND p.proname LIKE '%admin%'
    THEN '⚠ WARNING: Admin function callable by anon/authenticated - should restrict to service_role only'
    ELSE '→ Check context: ' || grantee || ' has access to ' || p.proname
  END as audit_note
FROM information_schema.routine_privileges
JOIN pg_proc p ON routine_name = p.proname
LEFT JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE routine_schema = 'public'
  AND routine_type = 'FUNCTION'
  AND grantee NOT IN ('postgres', 'pg_database_owner')
GROUP BY n.nspname, p.proname, grantee, p.proname
ORDER BY p.proname, grantee;

-- Expected Output:
-- Public RPC (get_latest_snapshots): should show EXECUTE for authenticated/anon
-- Admin RPC (admin-users, daily-update): should NOT show EXECUTE for anon/authenticated
