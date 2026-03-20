-- Supabase Audit: 1.1 Check RLS Enabled on All Public Tables
-- Purpose: Verify that Row-Level Security is enabled on critical tables
-- Safe: Read-only query, no data modification

SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  CASE 
    WHEN rowsecurity = true THEN '✓ RLS enabled'
    ELSE '✗ RLS DISABLED - FIX REQUIRED'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Expected Output:
-- Tables like 'users', 'snapshots' should have rls_enabled = true
-- If any table shows false, run: ALTER TABLE public.table_name ENABLE ROW LEVEL SECURITY;
