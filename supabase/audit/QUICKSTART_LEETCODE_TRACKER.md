# LeetCode Tracker - Supabase Security Audit Guide

This is your project-specific quick start guide for the Supabase security audit.

## Your Project Context

**Project**: leetcode_tracker_web  
**Supabase Project ID**: sukxolpjeagqybohmjdk  
**Current Setup**:
- Database: PostgreSQL (Supabase)
- Tables: `users`, `snapshots`
- RPC Functions: `get_latest_snapshots`, `get_weekly_comparison`
- Edge Functions: `leetcode-fetch`, `admin-users`, `daily-update`
- Frontend: Flutter Web
- Planned: FastAPI Backend

## Your Current Security Status

Based on codebase analysis:

✅ **Good**:
- RLS is enabled on `users` and `snapshots` tables
- Write access revoked from anon/authenticated roles
- Edge Functions use `service_role` for data mutations
- Admin functions check for authorized admin emails

⚠️ **Needs Verification**:
- RPC functions (`get_latest_snapshots`, `get_weekly_comparison`) definitions not in migrations
- Sensitive columns exposure not yet validated
- Weak policy patterns should be checked
- Function input validation hardened recently (see Edge Functions)

🔴 **Action Items**:
1. Run the audit scripts to verify actual state
2. Move admin operations from Edge Functions to FastAPI (when ready)
3. Replace direct RPC calls with FastAPI endpoints for privileged ops

## Quick Audit (5 minutes)

### ⚠️ Prerequisites

The audit scripts require **psql** (PostgreSQL command-line client) to run SQL queries.

**Install psql:**
- **macOS**: `brew install postgresql`
- **Ubuntu/Debian**: `sudo apt-get install postgresql-client`
- **Windows**: Download from https://www.postgresql.org/download/windows/
- **Docker**: `docker run -it postgres:latest psql -h host.docker.internal`

### Option 1: Automated Script (Recommended — requires psql)

```bash
# Start local Supabase
cd ~/Desktop/flutter_garbage/leetcode_tracker_web
supabase start

# Run the audit script
./supabase/audit/run-audit.sh local
```

Or for remote project (after installing psql):
```bash
./supabase/audit/run-audit.sh sukxolpjeagqybohmjdk
```

### Option 2: Manual Queries in Supabase Studio (No psql required)

1. Go to: https://app.supabase.com/project/sukxolpjeagqybohmjdk
2. Click: SQL Editor → New Query
3. Copy-paste each script from `supabase/audit/*.sql`
4. Run and save results

## Critical Checks for Your Project

### Check 1: RLS on Your Tables

**Script**: `supabase/audit/01-check-rls-enabled.sql`

**Expected**:
```
tablename | rls_enabled | status
users     | true        | ✓ RLS enabled
snapshots | true        | ✓ RLS enabled
```

**If not enabled**:
```sql
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.snapshots ENABLE ROW LEVEL SECURITY;
```

---

### Check 2: No Write Access for Anonymous

**Script**: `supabase/audit/02-check-table-grants.sql`

**Expected**:
```
grantee | table          | privileges | audit_note
anon    | users          | SELECT     | ✓ Safe: anon can only SELECT
anon    | snapshots      | SELECT     | ✓ Safe: anon can only SELECT
authenticated | users    | SELECT     | ✓ Safe: authenticated can only SELECT
authenticated | snapshots| SELECT     | ✓ Safe: authenticated can only SELECT
```

**If you see INSERT/UPDATE/DELETE on anon/authenticated**:
```sql
-- Revoke write access
REVOKE INSERT, UPDATE, DELETE ON public.users FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.snapshots FROM anon, authenticated;

-- Grant write access to service_role (used by Edge Functions)
GRANT INSERT, UPDATE, DELETE ON public.users TO service_role;
GRANT INSERT, UPDATE, DELETE ON public.snapshots TO service_role;
```

---

### Check 3: Your RPC Functions

**Script**: `supabase/audit/10-list-rpc-functions.sql`

**Expected Results**: Should show these functions:
- `get_latest_snapshots` - Read-only, used by leaderboard/analytics
- `get_weekly_comparison` - Read-only, used by analytics
- Any admin functions - Should be verified

**What to look for**:
```sql
-- Example of a GOOD read-only RPC
CREATE OR REPLACE FUNCTION public.get_latest_snapshots()
RETURNS TABLE (...) AS $$
BEGIN
  RETURN QUERY
  SELECT id, username, easy, medium, hard, total, ranking
  FROM snapshots
  JOIN users ON snapshots.user_id = users.id
  WHERE (date = ...);  -- Latest snapshot only
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
```

---

### Check 4: Admin Function Access

**Script**: `supabase/audit/05-check-function-permissions.sql`

**Expected**: 
- Public RPC functions (`get_latest_*`) → callable by authenticated/anon
- Admin functions → NO EXECUTE grant to anon/authenticated (rely on Edge Function auth checks)

---

### Check 5: Service Role Can Access Everything

**Script**: `supabase/audit/12-verify-service-role-access.sql`

**Expected**:
```
tablename | service_role_privileges_count | status
users     | 8                             | ✓ Public schema
snapshots | 8                             | ✓ Public schema
```

This is critical for:
- Edge Functions to write data
- Future FastAPI backend to access data with service_role key

---

## Your Edge Functions Security

Recent improvements made:

1. **leetcode-fetch**:
   - ✓ Input validation on username (regex: `^[a-zA-Z0-9_-]{1,30}$`)
   - ✓ HTTP method check (POST only)
   - ✓ Response status validation

2. **admin-users**:
   - ✓ Username validation
   - ✓ JSON payload validation
   - ✓ Email-based admin check

3. **daily-update**:
   - ✓ Admin email verification
   - ✓ Batch error handling
   - ✓ Logging for troubleshooting

---

## Fixing Issues: Examples for Your Project

### Issue: Accidentally created write policy for anon on users

**Evidence**: `supabase/audit/02-check-table-grants.sql` shows anon has INSERT

**Fix**: Create a migration file

```sql
-- supabase/migrations/20260320_000002_fix_anon_write_access.sql

BEGIN;

-- Revoke write from anon
REVOKE INSERT, UPDATE, DELETE ON public.users FROM anon, authenticated;

-- Ensure grant to service_role exists
GRANT INSERT, UPDATE, DELETE ON public.users TO service_role;

-- Verify select still works for public
GRANT SELECT ON public.users TO anon, authenticated;

-- List current grants to confirm
\echo 'Verifying grants on public.users:'
SELECT grantee, privilege_type 
FROM information_schema.table_privileges 
WHERE table_name = 'users' AND table_schema = 'public';

COMMIT;
```

Then deploy:
```bash
supabase db push
```

---

### Issue: Found weak policy USING (true)

**Evidence**: `supabase/audit/09-check-weak-policies.sql` shows overly permissive

**Fix**: Tighten the policy

```sql
-- supabase/migrations/20260320_000003_fix_weak_policy.sql

BEGIN;

-- Drop old weak policy
DROP POLICY IF EXISTS snapshots_all_access ON public.snapshots;

-- Create specific policies
CREATE POLICY snapshots_select_all ON public.snapshots
  FOR SELECT
  TO authenticated, anon
  USING (true);  -- Still true for reads (public leaderboard)

CREATE POLICY snapshots_insert_admin ON public.snapshots
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid()
        AND email IN (SELECT unnest(string_to_array(current_setting('app.admin_emails', true), ',')))
    )
  );

COMMIT;
```

---

## FastAPI Integration Checklist

Before adding FastAPI backend, complete:

- [ ] All audit scripts pass (no RED items)
- [ ] Service role can access all tables (script 12)
- [ ] No sensitive data exposed to anon/authenticated
- [ ] RPC functions are documented and tested
- [ ] Edge Functions input validation is in place ✓ (done)

Then FastAPI can:
- [ ] Replace `admin-users` Edge Function
- [ ] Replace `daily-update` Edge Function
- [ ] Keep `leetcode-fetch` OR move to FastAPI too
- [ ] Call Supabase with `service_role` key (stored in env vars, never in code)

---

## Common Commands

```bash
# Start local dev environment
supabase start

# Stop local dev
supabase stop

# View local database
supabase db start

# Link to remote project
supabase link --project-ref sukxolpjeagqybohmjdk

# Push a migration to remote
supabase db push

# Pull remote schema to local
supabase db pull

# Create new migration
supabase migration new <name>

# Run audit (after installing)
chmod +x supabase/audit/run-audit.sh
./supabase/audit/run-audit.sh local
```

---

## Audit Results Locations

After running audit:

```
audit_results/
├── 01-check-rls-enabled.txt          → RLS status
├── 02-check-table-grants.txt         → Grant review
├── 03-check-policies.txt              → Policy count
├── 04-check-function-security.txt    → SECURITY INVOKER/DEFINER
├── 05-check-function-permissions.txt → Who can exec each RPC
├── 06-list-all-grants.sql            → Complete grant list
├── 07-check-foreign-keys.txt         → FK integrity
├── 08-check-sensitive-columns.txt    → PII exposure
├── 09-check-weak-policies.txt        → Weak USING clauses
├── 10-list-rpc-functions.txt         → All RPC definitions
├── 11-check-audit-tables.txt         → Audit logging setup
├── 12-verify-service-role-access.txt → FastAPI readiness
└── AUDIT_SUMMARY_20260320_152345.txt → Final report
```

---

## Getting Help

- **Supabase Docs**: https://supabase.com/docs
- **Your Project**: https://app.supabase.com/project/sukxolpjeagqybohmjdk
- **Audit Checklist**: See `SUPABASE_AUDIT_CHECKLIST.md` in repo root

---

**Status**: Ready to audit  
**Next Step**: Run `./supabase/audit/run-audit.sh local` or `remote`  
**Time Estimate**: 5-10 minutes to run, 30-60 minutes to review and fix issues
