-- Supabase Audit: 4.1 Check for Sensitive Columns Exposed to Anon
-- Purpose: Ensure passwords, tokens, emails are not readable by anonymous users
-- Safe: Read-only query, no data modification

-- Get list of sensitive column patterns that should NOT be readable
WITH sensitive_patterns AS (
  SELECT *
  FROM (
    VALUES
      ('password'),
      ('secret'),
      ('token'),
      ('api_key'),
      ('private_key'),
      ('credential'),
      ('salt'),
      ('hash'),
      ('authorization')
  ) AS patterns(name)
),
table_columns AS (
  SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable
  FROM information_schema.columns
  WHERE table_schema = 'public'
)
SELECT
  tc.table_schema,
  tc.table_name,
  tc.column_name,
  tc.data_type,
  '⚠ SENSITIVE COLUMN DETECTED' as alert,
  'Verify this column is NOT exposed in SELECT policies for anon/authenticated users' as check_required
FROM table_columns tc
CROSS JOIN sensitive_patterns sp
WHERE LOWER(tc.column_name) LIKE '%' || sp.name || '%'
ORDER BY tc.table_name, tc.column_name;

-- Then, manually check policies in Supabase Studio:
-- 1. Go to Authentication → Policies
-- 2. For each policy on tables with sensitive columns:
--    - Ensure the USING clause excludes these columns, OR
--    - Ensure the role is not anon/authenticated

-- Expected Output:
-- May list columns like 'password_hash', 'secret_key' (expected)
-- Manual verification: Check Supabase Studio that these columns aren't exposed in public policies
