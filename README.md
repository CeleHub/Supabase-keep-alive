# Supabase Keep-Alive

This repository contains a GitHub Actions workflow that pings my Supabase project named "Good's location" regularly to prevent it from sleeping on the free tier.

### Workflow
- Runs every Monday and Thursday
- Pings one of the available tables to keep the database alive

### Setup
1. Add the following secrets in **Settings → Secrets and variables → Actions**:
   - `SUPABASE_URL` → `https://your-project-ref.supabase.co`
   - `SUPABASE_ANON_KEY` → Your Supabase anon key
   - `TABLE_NAME` → Name of any table in your database
2. Manually trigger the workflow once to test.