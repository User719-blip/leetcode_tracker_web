-- Supabase Audit: 5.1 RPC Function List with Full Definitions
-- Purpose: Audit all RPC functions to understand what they do
-- Safe: Read-only query, no data modification

SELECT
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_functiondef(p.oid) as complete_definition,
  CASE 
    WHEN p.proname IN ('get_latest_snapshots', 'get_weekly_comparison') THEN 'Public Read-Only'
    WHEN p.proname LIKE '%admin%' THEN 'Admin Only'
    WHEN p.proname LIKE '%update%' THEN 'Update Operation'
    ELSE 'Other'
  END as category
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname NOT LIKE 'pg_%'  -- Exclude system functions
  AND p.proname NOT LIKE 'cron_%'  -- Exclude cron functions
ORDER BY p.proname;

-- Expected Output:
-- Complete SQL definition for each RPC function
-- Review each function:
--   1. What tables does it read/write?
--   2. Does it have input validation?
--   3. Who should be allowed to call it?
--   4. Does it correctly enforce security?
--
-- Save this output and cross-reference with your Flutter code
-- to ensure RPC functions match expected behavior
