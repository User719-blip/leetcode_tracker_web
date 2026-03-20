-- Supabase Audit: 6.1 Check for Audit Tables (Optional)
-- Purpose: Identify if audit logging infrastructure exists
-- Safe: Read-only query, no data modification

SELECT
  schemaname,
  tablename,
  CASE 
    WHEN tablename IN ('audit_log', 'audit_logs', 'changelog', 'history') THEN '✓ Audit table found'
    ELSE '→ Standard data table'
  END as table_type,
  CASE 
    WHEN tablename LIKE '%audit%' OR tablename LIKE '%history%' OR tablename LIKE '%log%'
    THEN 'Likely for audit/logging'
    ELSE 'Business data'
  END as purpose
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Expected Output:
-- For MVP: OK if no audit tables (can add later)
-- For production: Recommend adding audit_logs table that records:
--   - who (user_id)
--   - what (table, operation: INSERT/UPDATE/DELETE)
--   - when (timestamp)
--   - before/after values (optional)
--
-- Create audit table if needed:
/*
CREATE TABLE public.audit_logs (
  id BIGSERIAL PRIMARY KEY,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id),
  table_name TEXT NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
  record_id UUID NOT NULL,
  old_values JSONB,
  new_values JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY audit_logs_select_own ON public.audit_logs
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');
*/
