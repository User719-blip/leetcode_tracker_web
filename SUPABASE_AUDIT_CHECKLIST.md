# Supabase SQL Audit Checklist

## Overview
This checklist guides you through auditing your Supabase project for security, performance, and consistency issues related to Row-Level Security (RLS), grants, and RPC functions. Run the validation scripts in `supabase/audit/` against your project database.

---

## 1. Row-Level Security (RLS) Status

### 1.1 Table RLS Enablement
- [ ] All public tables have RLS enabled
- [ ] Use: `supabase/audit/01-check-rls-enabled.sql`
- **Expected**: Tables `users`, `snapshots`, and any other public tables should show `rls_enabled = true`
- **Risk**: RLS disabled = all users can read/write unless policies exist (should not rely on policies alone)

### 1.2 Table-Level Grants Review
- [ ] No overly broad `GRANT INSERT, UPDATE, DELETE` to `anon` or `authenticated` on public tables
- [ ] Use: `supabase/audit/02-check-table-grants.sql`
- **Expected**: 
  - `anon, authenticated` should have **SELECT only** for public leaderboard tables
  - Write access should be restricted to `service_role` or specific authenticated users
- **Risk**: Unrestricted write access = data corruption, unauthorized edits

### 1.3 Policy Enforcement
- [ ] Every table with RLS has at least one policy defined
- [ ] Use: `supabase/audit/03-check-policies.sql`
- **Expected**: Tables should list their policies with allowed operations (SELECT, INSERT, UPDATE, DELETE)
- **Risk**: RLS enabled but no policies = no one can access (except service_role)

---

## 2. RPC Function & Stored Procedure Audit

### 2.1 Function Definitions & SECURITY Scope
- [ ] All RPC functions have appropriate SECURITY settings (INVOKER or DEFINER)
- [ ] Use: `supabase/audit/04-check-function-security.sql`
- **Expected**:
  - Public-facing RPC (call from Flutter): `SECURITY INVOKER` (safer, enforces caller's permissions)
  - Admin RPC (call from Edge Functions with service_role): `SECURITY DEFINER` (if needed for privilege escalation)
- **Risk**: `SECURITY DEFINER` on public RPC = attacker inherits function owner's privileges

### 2.2 Function Parameter & Input Validation
- [ ] All RPC functions validate parameters (type, length, pattern)
- [ ] Manual Check: Review SQL in `supabase/functions/` and Supabase Studio → SQL Editor → Functions
- **Expected**: 
  - Username: regex check (e.g., `^[a-zA-Z0-9_-]{1,30}$`)
  - IDs: uuid or bigint type enforcement
  - Dates: timestamp or date type enforcement
- **Risk**: No validation = SQL injection, buffer overflow, unexpected behavior

### 2.3 Function Call Permissions
- [ ] Check who can execute each RPC function
- [ ] Use: `supabase/audit/05-check-function-permissions.sql`
- **Expected**:
  - Public RPC (like `get_latest_snapshots`): callable by `anon` and `authenticated`
  - Admin RPC: restricted to specific roles or users (via policies/auth checks in function body)
- **Risk**: Public-facing RPC with no caller checks = anyone can execute

---

## 3. Grant & Permission Audit

### 3.1 Baseline Grant Review
- [ ] Check all explicit grants to `anon`, `authenticated`, and `service_role`
- [ ] Use: `supabase/audit/06-list-all-grants.sql`
- **Expected**:
  - `anon, authenticated`: SELECT on public tables only (for leaderboard)
  - No INSERT, UPDATE, DELETE to `anon` on data tables
  - `service_role`: Full access (necessary for Edge Functions)
- **Risk**: Misconfigured grants = privilege escalation or unauthorized data access

### 3.2 Foreign Key Integrity
- [ ] No orphaned foreign key constraints (dropped tables but FK remains)
- [ ] Use: `supabase/audit/07-check-foreign-keys.sql`
- **Expected**: All FKs point to existing tables
- **Risk**: Can cause snapshot/restore failures

### 3.3 Dangerous Default Privileges
- [ ] No `ALTER DEFAULT PRIVILEGES` that grant write to `anon` or `authenticated`
- [ ] Manual Check: Search Supabase SQL Editor for `ALTER DEFAULT PRIVILEGES`
- **Risk**: Future tables inherit overly permissive grants

---

## 4. Data Exposure & Privacy

### 4.1 Sensitive Column Access
- [ ] No PII (passwords, tokens, emails) exposed to `anon` role in SELECT policies
- [ ] Use: `supabase/audit/08-check-sensitive-columns.sql`
- **Expected**: 
  - Password fields: never selectable by anon/authenticated
  - Email: restricted if not public
  - API keys / tokens: never selectable
- **Risk**: Data breach, credential theft

### 4.2 Policy Bypass Detection
- [ ] Check for policies using `USING (true)` or `USING (current_user_id() IS NOT NULL)` which are weak
- [ ] Use: `supabase/audit/09-check-weak-policies.sql`
- **Expected**: Policies should enforce specific ownership or role checks
- **Risk**: Attacker can read/modify other users' data

---

## 5. RPC Function Audit (FuncJector-Related)

### 5.1 RPC Function List
- [ ] Get a complete list of all RPC functions with definitions
- [ ] Use: `supabase/audit/10-list-rpc-functions.sql`
- **Expected**: Should list all functions in `public` schema that are invoked from your app
- **Risk**: Orphaned or unused functions consume resources

### 5.2 Function Dependencies
- [ ] Verify RPC functions call only expected tables/other functions
- [ ] Manual Check: Read SQL definition of each function in Supabase Studio → SQL Editor → Functions
- **Expected**:
  - `get_latest_snapshots`: should read from `snapshots` and `users` only
  - `get_weekly_comparison`: should read from `snapshots` only
- **Risk**: Function calls unintended data, causes data leaks

---

## 6. Audit Logging & Compliance

### 6.1 Audit Table Existence
- [ ] Check if audit logging tables exist (optional but recommended)
- [ ] Use: `supabase/audit/11-check-audit-tables.sql`
- **Expected**: May be empty if not using audit logging (OK for MVP)
- **Risk**: No trace of who accessed/modified data

---

## 7. Pre-Migration Checklist (FastAPI Backend Prep)

Before adding FastAPI backend, verify:

- [ ] **Service Role Key**: Securely stored in environment variables (never in code)
  - Use: `supabase/audit/12-verify-service-role-access.sql` (connectivity test)
- [ ] **JWT Configuration**: Check Supabase project settings for JWT secret and expiry
  - Manual: Supabase Dashboard → Project Settings → API → JWT Secret
  - Expected: Expiry 1 hour or less for access tokens
- [ ] **CORS Origin Whitelist**: Configured in Edge Functions env vars
  - Expected: Restrict to your FastAPI domain in production
- [ ] **RPC Functions Audit**: All RPC functions audited above
  - Before FastAPI: Ensure RPC functions are production-ready or plan to migrate to FastAPI endpoints

---

## 8. Post-Audit Actions

### High Priority (Critical)
- [ ] Fix any RLS disabled tables
- [ ] Remove overly broad GRANT statements
- [ ] Fix SECURITY DEFINER functions that should be INVOKER

### Medium Priority (Important)
- [ ] Add missing input validation to functions
- [ ] Tighten USING policies from `true` to specific checks
- [ ] Set up audit logging if storing PII

### Low Priority (Nice-to-Have)
- [ ] Document all RPC functions and their purpose
- [ ] Create monitoring alerts for unusual grant changes
- [ ] Schedule quarterly security reviews

---

## 9. Running the Audit

### Prerequisites
```bash
# Install Supabase CLI (if not already)
npm install -g @supabase/cli

# Or use Docker if CLI unavailable
docker run --rm -v ~/.config/supabase:~/.config/supabase supabase/cli supabase
```

### Audit Steps

1. **Connect to your Supabase project** (remote or local)
   ```bash
   # For remote project
   supabase link --project-ref YOUR_PROJECT_REF
   
   # Or for local development database
   supabase start
   ```

2. **Run each validation script** (in order)
   ```bash
   supabase db execute --file supabase/audit/01-check-rls-enabled.sql
   supabase db execute --file supabase/audit/02-check-table-grants.sql
   # ... run all scripts in order
   ```

3. **Review results** and cross-reference with checklist items above

4. **Address findings** with SQL migrations (create new migration files) or UI changes (Supabase Studio)

5. **Re-run scripts** after fixes to verify

---

## 10. Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| RLS disabled on table | Table created before RLS policy | `ALTER TABLE public.table_name ENABLE ROW LEVEL SECURITY;` |
| `permission denied` when querying | Missing SELECT grant | `GRANT SELECT ON public.table_name TO authenticated;` |
| Anon/authenticated can write | Missing revoke or overly broad policy | `REVOKE INSERT, UPDATE, DELETE ON public.table_name FROM anon, authenticated;` |
| `SECURITY DEFINER` on public RPC | Function inherits owner privileges | Change to `SECURITY INVOKER` and handle auth inside function body |
| Policy shows `(NULL)` in USING clause | Broken policy definition | Drop and recreate policy with correct logic |

---

## 11. Supabase Project URLs for Reference

- **Supabase Dashboard**: https://app.supabase.com
- **Project URL**: `https://sukxolpjeagqybohmjdk.supabase.co`
- **Local Dev**: `postgresql://postgres:postgres@127.0.0.1:54322/postgres` (after `supabase start`)

---

## 12. FastAPI Backend Integration Notes

Once you add FastAPI:

- [ ] FastAPI should verify JWT tokens from Supabase Auth
- [ ] FastAPI should use `SUPABASE_SERVICE_ROLE_KEY` (env var only, never exposed to frontend)
- [ ] FastAPI should replace Edge Function calls for admin/update operations
- [ ] RPC functions can remain for public read-only queries (leaderboard)
- [ ] CORS origin in Edge Functions & FastAPI should match frontend domain

---

## Appendix: Quick SQL Reference

| Query | Purpose |
|-------|---------|
| `SELECT * FROM pg_roles;` | List all database roles |
| `\dp public.*` (psql) | Show all grants on public schema objects |
| `SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';` | Check RLS status |
| `SELECT * FROM pg_policies;` | List all RLS policies |
| `SELECT * FROM pg_proc WHERE proname LIKE '%function_name%';` | Find function |

---

**Last Updated**: March 20, 2026  
**Audit Version**: 1.0  
**Status**: Ready for first audit run
