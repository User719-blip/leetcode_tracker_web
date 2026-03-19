# Admin Setup Guide

## Overview

This app uses **Supabase Auth** for admin access. There's no separate "admin table"—admin privileges are determined by email allowlist.

## How It Works

1. User signs in with Supabase Auth (email + password)
2. Edge Functions validate the JWT token
3. If user's email is in `ADMIN_EMAILS`, they get access
4. User operations (add/delete/fetch stats) run server-side with service role

## Setup Steps

### 1. Create Admin User in Supabase Auth

**Local Development:**
```bash
supabase start
# Opens http://localhost:54323
# Go: Authentication → Users → New User
# Example: admin@company.com / MyPassword123
```

**Production (supabase.com):**
- Dashboard → Authentication → Users → New User
- Create with desired email and password

### 2. Configure ADMIN_EMAILS

**Local (.env):**
Edit `supabase/.env`:
```env
# Comma-separated list of admin emails
ADMIN_EMAILS=admin@company.com,admin2@company.com
```

**Production (Dashboard):**
1. Go to your Supabase project
2. Settings → Edge Functions
3. Add Secret named `ADMIN_EMAILS`
4. Value: `admin@company.com,admin2@company.com`

### 3. Deploy Functions

After setting secrets, deploy:
```bash
supabase functions deploy admin-users
supabase functions deploy daily-update
```

### 4. Test Admin Access

1. Run the app (Flutter web)
2. Click Admin Panel
3. Sign in with: `admin@company.com` / `MyPassword123`
4. Should access admin UI without hardcoded password

## Email Matching

- Email check is **case-insensitive**
- Whitespace is trimmed automatically
- Examples that will work:
  - `ADMIN_EMAILS=Admin@Company.com` ✅ matches `admin@company.com`
  - `ADMIN_EMAILS=admin@company.com, admin2@company.com` ✅ (with spaces)

## Production Deployment with GitHub Secrets

If you use GitHub Actions for deployment:

1. **Add to GitHub repo secrets:**
   - Name: `SUPABASE_ADMIN_EMAILS`
   - Value: `admin@company.com,admin2@company.com`

2. **In your GitHub Actions workflow** (`.github/workflows/deploy.yml`):
```yaml
- name: Deploy Supabase Functions
  run: supabase functions deploy
  env:
    ADMIN_EMAILS: ${{ secrets.SUPABASE_ADMIN_EMAILS }}
    SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
```

## Security Notes

- **Never commit** real admin emails in `.env` to Git
- `.env.local` is recommended for **local development only**
- Use Supabase Dashboard secrets for **production**
- Each Supabase project gets its own secret values
- Changing ADMIN_EMAILS requires redeploying Edge Functions (in Supabase)

## Troubleshooting

**"Unauthorized: admin access required"** error?
- Check email is exactly in ADMIN_EMAILS (case-insensitive still)
- Verify Edge Functions are deployed
- Check function logs in Supabase Dashboard

**Can't sign in?**
- Ensure user exists in Supabase Auth (Settings → Users)
- Verify correct email/password
- Check auth is enabled in your Supabase project
