-- Supabase Audit: 3.1 Baseline Grant Review - List ALL Grants
-- Purpose: Comprehensive view of all object grants for security review
-- Safe: Read-only query, no data modification

SELECT
  grantee,
  table_schema,
  table_name,
  object_type,
  string_agg(privilege_type, ', ' ORDER BY privilege_type) as privileges,
  is_grantable
FROM (
  -- Table privileges
  SELECT
    grantee,
    table_schema,
    table_name,
    'TABLE' as object_type,
    privilege_type,
    is_grantable
  FROM information_schema.table_privileges
  WHERE table_schema = 'public'
  UNION ALL
  -- Sequence privileges
  SELECT
    grantee,
    table_schema,
    table_name,
    'SEQUENCE' as object_type,
    privilege_type,
    is_grantable
  FROM information_schema.sequences
  WHERE table_schema = 'public'
    AND table_name IS NOT NULL
) grants
WHERE grantee NOT IN ('postgres', 'pg_database_owner')
GROUP BY grantee, table_schema, table_name, object_type, is_grantable
ORDER BY grantee, table_schema, table_name;

-- Expected Output:
-- anon, authenticated: SELECT only on public tables
-- service_role: SELECT, INSERT, UPDATE, DELETE on all tables
-- No other explicit grants visible
