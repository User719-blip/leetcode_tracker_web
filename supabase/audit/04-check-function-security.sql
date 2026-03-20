-- Supabase Audit: 2.1 Check Function Security Settings (SECURITY INVOKER vs DEFINER)
-- Purpose: Verify RPC functions use appropriate security context
-- Safe: Read-only query, no data modification

SELECT
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_functiondef(p.oid) as function_definition,
  CASE 
    WHEN p.prosecdef = true THEN 'SECURITY DEFINER'
    ELSE 'SECURITY INVOKER'
  END as security_context,
  u.usename as function_owner,
  CASE 
    WHEN p.prosecdef = true THEN '⚠ DEFINER: Function runs as owner. OK if internal-only, RISKY if public RPC'
    ELSE '✓ INVOKER: Function runs as caller. Safer for public RPC'
  END as audit_note
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
JOIN pg_user u ON p.proowner = u.usesysid
WHERE n.nspname = 'public'
  AND p.proname NOT LIKE 'pg_%'  -- Exclude system functions
ORDER BY p.proname;

-- Expected Output:
-- Most RPC functions should show "SECURITY INVOKER" (safer)
-- SECURITY DEFINER functions should be reviewed carefully:
--   - If public-facing: convert to INVOKER and handle auth in function body
--   - If admin-only: ensure functions are private and called only with service_role
