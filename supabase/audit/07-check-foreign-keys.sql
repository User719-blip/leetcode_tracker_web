-- Supabase Audit: 3.2 Check Foreign Key Integrity
-- Purpose: Detect orphaned foreign keys or broken relationships
-- Safe: Read-only query, no data modification

SELECT
  constraint_name,
  table_schema,
  table_name,
  column_name,
  referenced_table_schema,
  referenced_table_name,
  referenced_column_name,
  CASE 
    WHEN referenced_table_name IS NULL THEN '✗ BROKEN: Referenced table does not exist'
    ELSE '✓ OK: Foreign key is valid'
  END as status
FROM (
  SELECT
    tc.constraint_name,
    tc.table_schema,
    tc.table_name,
    kcu.column_name,
    ccu.table_schema as referenced_table_schema,
    ccu.table_name as referenced_table_name,
    ccu.column_name as referenced_column_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
  LEFT JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
  WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
) fk_info
ORDER BY table_name, constraint_name;

-- Expected Output:
-- All rows should show "✓ OK: Foreign key is valid"
-- If any "✗ BROKEN" appears:
--   1. Identify the broken FK
--   2. Run: ALTER TABLE table_name DROP CONSTRAINT constraint_name;
--   3. Document why the FK was broken (was the referenced table dropped?)
