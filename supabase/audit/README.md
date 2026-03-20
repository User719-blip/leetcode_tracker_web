# Supabase Audit Scripts

This directory contains SQL scripts to audit your Supabase project for security, compliance, and configuration issues. 

## Quick Start

### Prerequisites

**psql** (PostgreSQL command-line client) is required to run audit scripts against your database.

**Install psql:**
```bash
# macOS
brew install postgresql

# Ubuntu/Debian
sudo apt-get install postgresql-client

# Windows
# Download from: https://www.postgresql.org/download/windows/

# Docker (if you have Docker but not psql)
docker run -it postgres:latest psql
```

### Option 1: Using the Provided Bash Script (Easiest)

The repository includes `supabase/audit/run-audit.sh` which automates everything:

```bash
# Make it executable
chmod +x supabase/audit/run-audit.sh

# For local development
./supabase/audit/run-audit.sh local

# For remote project (requires psql)
./supabase/audit/run-audit.sh sukxolpjeagqybohmjdk
```

The script will:
- ✓ Start local Supabase if needed
- ✓ Run all 12 audit SQL scripts sequentially
- ✓ Save results to `audit_results/` directory
- ✓ Generate a summary report with pass/fail/warning counts

### Option 2: Using psql Directly

If you prefer manual execution:

```bash
# For local development database (after supabase start)
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -f supabase/audit/01-check-rls-enabled.sql

# For remote database (create connection string in Supabase Dashboard → Database → Connection string)
psql "postgresql://[user]:[password]@[host]:[port]/postgres" -f supabase/audit/01-check-rls-enabled.sql
```

### Option 3: Using Supabase Studio Web UI (No Installation Required)

1. Go to your Supabase project dashboard
2. Click **SQL Editor** in the left sidebar
3. Create a new query
4. Copy-paste each script from `supabase/audit/*.sql` and run individually
5. Copy results and cross-reference with the checklist

---

## Scripts Overview

| Script | Purpose | Priority |
|--------|---------|----------|
| `01-check-rls-enabled.sql` | Verify RLS is enabled on all tables | 🔴 Critical |
| `02-check-table-grants.sql` | Check for overly broad write permissions | 🔴 Critical |
| `03-check-policies.sql` | Verify all RLS-enabled tables have policies | 🔴 Critical |
| `04-check-function-security.sql` | Audit RPC function SECURITY settings | 🟡 Important |
| `05-check-function-permissions.sql` | Verify who can execute each RPC | 🟡 Important |
| `06-list-all-grants.sql` | Comprehensive grant review | 🟡 Important |
| `07-check-foreign-keys.sql` | Detect orphaned foreign keys | 🟠 Medium |
| `08-check-sensitive-columns.sql` | Find columns that should be protected | 🟠 Medium |
| `09-check-weak-policies.sql` | Identify weak USING clauses | 🟠 Medium |
| `10-list-rpc-functions.sql` | Full RPC function definitions | 🟠 Medium |
| `11-check-audit-tables.sql` | Check for audit logging tables | 🟢 Optional |
| `12-verify-service-role-access.sql` | Test service_role connectivity | 🟢 Pre-FastAPI |

---

## Running the Complete Audit

### Using the Automated Runner Script

The `run-audit.sh` script handles all execution details automatically:

```bash
chmod +x supabase/audit/run-audit.sh
./supabase/audit/run-audit.sh [local|project-ref]

# Examples:
./supabase/audit/run-audit.sh local              # Local dev database
./supabase/audit/run-audit.sh sukxolpjeagqybohmjdk  # Remote project (requires psql)
```

The script outputs:
- ✓ Progress indicators for each script
- ✓ Color-coded status (green=pass, yellow=warning, red=fail)
- ✓ Summary statistics
- ✓ Results saved to `audit_results/*.txt`

### Step 1: Verify Prerequisites

Before running the audit, ensure you have the required tools:

```bash
# Check local database status
supabase status

# Check psql availability (for remote audits)
which psql   # macOS/Linux
psql --version  # All platforms
```

If psql is missing:
- macOS: `brew install postgresql`
- Ubuntu: `sudo apt-get install postgresql-client`
- Windows: https://www.postgresql.org/download/windows/

### Step 2: Run the Audit

```bash
chmod +x supabase/audit/run-audit.sh

# Local development
./supabase/audit/run-audit.sh local

# Remote project
./supabase/audit/run-audit.sh sukxolpjeagqybohmjdk
```

### Step 3: Review Results

After the audit completes, review the output files:

```bash
# View summary
cat audit_results/AUDIT_SUMMARY_*.txt

# Check specific scripts
cat audit_results/01-check-rls-enabled.txt
cat audit_results/02-check-table-grants.txt
cat audit_results/03-check-policies.txt

# Look for these markers:
# ✓ PASS - Issue not found
# ⚠ WARNING - Issue found but may be intentional  
# ✗ FAIL - Issue requires fixing
```

Cross-reference findings with [SUPABASE_AUDIT_CHECKLIST.md](../SUPABASE_AUDIT_CHECKLIST.md) to understand what each check validates.

### Step 4: Address Findings

For each finding:
1. Note the issue
2. Create a new migration file in `supabase/migrations/` (e.g., `20260320_000002_fix-rls-issue.sql`)
3. Write the fix SQL
4. Push the migration
5. Re-run the audit script to verify

---

## Common Findings & Fixes

### Finding: RLS Disabled on a Table

**Output:**
```
tablename | rls_enabled | status
users     | false       | ✗ RLS DISABLED - FIX REQUIRED
```

**Fix:**
```sql
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
```

---

### Finding: Anon Can Write to Table

**Output:**
```
grantee   | privilege_type | audit_note
anon      | INSERT,UPDATE  | ⚠ WARNING: Write access granted to anon
```

**Fix:**
```sql
REVOKE INSERT, UPDATE, DELETE ON public.users FROM anon;
GRANT SELECT ON public.users TO anon;
```

---

### Finding: SECURITY DEFINER on Public RPC

**Output:**
```
function_name | security_context | audit_note
my_rpc        | SECURITY DEFINER | ⚠ DEFINER: Function runs as owner...
```

**Fix (Option 1: Change to INVOKER):**
```sql
CREATE OR REPLACE FUNCTION public.my_rpc(...)
RETURNS ... LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
  -- Add auth checks in function body:
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  -- ... rest of function
END;
$$;
```

**Fix (Option 2: Make Function Private):**
If function is admin-only, create in private schema:
```sql
CREATE SCHEMA IF NOT EXISTS private;

CREATE FUNCTION private.admin_rpc(...)
RETURNS ... LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Only accessible to service_role
  ...
END;
$$;

-- Revoke from public
REVOKE ALL ON FUNCTION private.admin_rpc(...) FROM public;
```

Then call from Edge Functions with service_role key.

---

### Finding: Weak Policy (USING true)

**Output:**
```
tablename | policyname       | audit_note
posts     | posts_all_access | ⚠ WARNING: Overly permissive (USING true)
```

**Fix:**
```sql
DROP POLICY posts_all_access ON public.posts;

CREATE POLICY posts_select_public ON public.posts
  FOR SELECT
  TO authenticated, anon
  USING (published = true);

CREATE POLICY posts_update_own ON public.posts
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = author_id);
```

---

## Before Adding FastAPI Backend

Complete this audit first:

- [ ] All RLS scripts pass (01-03)
- [ ] No weak policies (09)  
- [ ] Function security reviewed (04)
- [ ] Service role can access all tables (12)
- [ ] No sensitive columns exposed (08)

Then, proceed to FastAPI integration.

---

## Automation: Cron Audit (Optional)

For production, run the audit automatically:

```sql
-- Create a function to send audit results
CREATE OR REPLACE FUNCTION public.run_security_audit()
RETURNS TABLE (check_name TEXT, status TEXT, details TEXT)
LANGUAGE SQL AS $$
  SELECT 'RLS_ENABLED' as check_name, 
         (SELECT COUNT(*) FILTER (WHERE NOT rowsecurity)::TEXT FROM pg_tables WHERE schemaname='public') as status,
         'Disabled tables: ' || STRING_AGG(tablename, ', ') as details
  FROM pg_tables WHERE schemaname='public' AND NOT rowsecurity
  GROUP BY schemaname;
$$;
```

Then schedule it with a cron job (Supabase doesn't have native cron, but Edge Functions can call it):

```typescript
// Edge Function: daily-audit.ts
import { createClient } from "@supabase/supabase-js";

export default async function handler(req: any) {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { data, error } = await supabase.rpc("run_security_audit");
  
  if (error) {
    console.error("Audit failed:", error);
    return new Response(JSON.stringify({ error }), { status: 500 });
  }

  // Send email/Slack notification with results
  console.log("Audit results:", data);
  return new Response(JSON.stringify({ success: true }), { status: 200 });
}
```

---

## Need Help?

- **Supabase Docs**: https://supabase.com/docs/guides/auth/row-level-security
- **PostgreSQL RLS**: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- **Project Security**: https://app.supabase.com/project/YOUR_PROJECT_REF/settings/auth

---

**Last Audit**: Not completed yet  
**Status**: Ready to run  
**Version**: 1.0
