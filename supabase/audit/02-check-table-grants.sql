-- Supabase Audit: 1.2 Check Table-Level Grants
-- Purpose: Verify that overly broad INSERT/UPDATE/DELETE grants don't exist
-- Safe: Read-only query, no data modification

SELECT
  grantee,
  table_schema,
  table_name,
  string_agg(privilege_type, ', ' ORDER BY privilege_type) as privileges,
  CASE 
    WHEN grantee IN ('anon', 'authenticated') AND 
         string_agg(privilege_type, ',') LIKE '%INSERT%' OR
         string_agg(privilege_type, ',') LIKE '%UPDATE%' OR
         string_agg(privilege_type, ',') LIKE '%DELETE%'
    THEN '⚠ WARNING: Write access granted to ' || grantee
    WHEN grantee IN ('anon', 'authenticated') AND 
         string_agg(privilege_type, ',') = 'SELECT'
    THEN '✓ Safe: ' || grantee || ' can only SELECT'
    ELSE '→ Check: ' || grantee
  END as audit_note
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND grantee NOT IN ('postgres', 'pg_database_owner')
GROUP BY grantee, table_schema, table_name
ORDER BY table_name, grantee;

-- Expected Output:
-- anon/authenticated on users/snapshots should show: "✓ Safe: can only SELECT"
-- If WARNING appears for write privileges, run:
--   REVOKE INSERT, UPDATE, DELETE ON public.table_name FROM anon, authenticated;
--   GRANT INSERT, UPDATE, DELETE ON public.table_name TO service_role;
