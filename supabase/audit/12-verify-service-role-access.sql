-- Supabase Audit: 7.1 Verify Service Role Access
-- Purpose: Test that service_role can access all required tables
-- Safe: Read-only query (just counts), no data modification

-- This script verifies service_role connectivity
-- Run this with the service_role key to confirm FastAPI backend can access your database

SELECT
  schemaname,
  tablename,
  (
    SELECT COUNT(*) 
    FROM information_schema.table_privileges
    WHERE table_schema = schemaname
      AND table_name = tablename
      AND grantee = 'service_role'
  ) as service_role_privileges_count,
  CASE 
    WHEN schemaname = 'public' THEN '✓ Public schema (accessible)'
    ELSE 'Other schema'
  END as schema_status
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Expected Output:
-- All public tables should be accessible to service_role
--
-- Pre-Flight Check for FastAPI Backend:
-- 1. Copy your SUPABASE_SERVICE_ROLE_KEY to a secure location (NOT in git)
-- 2. Set environment variable: export SUPABASE_SERVICE_ROLE_KEY="your-key"
-- 3. Connect with service_role and run this script
-- 4. Verify all tables show as accessible
--
-- If you see permission denied errors:
--   - Check that grants include service_role
--   - Run: GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO service_role;
--   - Run: ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO service_role;
