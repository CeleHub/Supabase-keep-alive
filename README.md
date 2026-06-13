# Supabase Keep-Alive Action

This repository contains a GitHub Actions workflow that automatically pings my Supabase project **"Good's Location"** every day to prevent it from sleeping on the free tier.

## Purpose

Supabase free-tier projects pause after 7 days of inactivity. This workflow sends a lightweight request daily to keep the project awake.

## How It Works

- **Schedule**: Runs every day at 00:00 UTC
- **Table used**: `brands` (configurable via secrets)
- **Method**: Simple authenticated GET request to Supabase REST API

## Setup

1. **Repository Secrets** (required):

   | Secret Name            | Description                                      | Example |
   |------------------------|--------------------------------------------------|---------|
   | `SUPABASE_URL`         | Your Supabase project URL                        | `https://abcde.supabase.co` |
   | `SUPABASE_ANON_KEY`    | Your Supabase Anon (public) key                  | `eyJ...` |
   | `TABLE_NAME`           | Table to ping (lightweight table recommended)    | `time` |

2. Add the secrets in:  
   **Settings → Secrets and variables → Actions → New repository secret**

3. The workflow file is located at `.github/workflows/keep-supabase-alive.yml`

## Manual Testing

You can manually trigger the workflow anytime from the **Actions** tab.

## Supabase Project

- **Project Name**: Good's Location
- **Purpose**: Keep-alive for production / development project

---

Would you like me to make any changes to this README? For example:
- Add more details
- Change the tone
- Include troubleshooting section

Just say yes or tell me what to adjust and I’ll update it.