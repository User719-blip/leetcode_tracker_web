-- Supabase Audit: 4.2 Check for Weak RLS Policies
-- Purpose: Identify overly permissive USING clauses (like USING (true))
-- Safe: Read-only query, no data modification

SELECT
  schemaname,
  tablename,
  policyname,
  roles,
  qual as using_clause,
  with_check as check_clause,
  cmd as policy_type,
  CASE 
    WHEN schemaname = 'public'
      AND cmd = 'SELECT'
      AND qual = 'true'
      AND policyname IN ('users_read_public', 'snapshots_read_public')
      THEN 'ℹ INFO: Intentional public read policy for leaderboard-style data'
    WHEN qual = 'true' OR qual IS NULL THEN '⚠ WARNING: Overly permissive (USING true or NULL)'
    WHEN qual LIKE '%(true)%' THEN '⚠ WARNING: Policy contains (true) - may be overly permissive'
    WHEN qual LIKE '%current_user_id()%' OR qual LIKE '%auth.uid()%' THEN '✓ OK: Uses user ID check'
    WHEN qual LIKE '%current_setting%' OR qual LIKE '%auth.jwt()%' THEN '✓ OK: Uses auth context'
    ELSE '→ Review: Check if policy logic is correct'
  END as audit_note
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Expected Output:
-- All policies should show "✓ OK: Uses" or "→ Review"
-- Any "⚠ WARNING" requires review and likely needs to be rewritten
--
-- Example good policies:
--   USING (auth.uid() = user_id)  -- Only owner can access
--   USING (status = 'public')      -- Only public records visible
--
-- Example bad policies:
--   USING (true)                   -- Everyone can access everything
--   USING (NULL)                   -- No one can access
