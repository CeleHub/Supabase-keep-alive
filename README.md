# Supabase Keep-Alive

GitHub Actions workflow to regularly ping a Supabase project.

## Workflow

- Runs daily at 00:00 UTC
- Uses configurable secrets for flexibility

## Setup

1. Add the following **Repository Secrets**:

   | Secret Name            | Description                            |
   |------------------------|----------------------------------------|
   | `SUPABASE_URL`         | Supabase project URL                   |
   | `SUPABASE_ANON_KEY`    | Supabase Anon key                      |
   | `TABLE_NAME`           | Table name to ping                     |

2. Secrets can be added under:  
   **Settings → Secrets and variables → Actions**

## Files

- `.github/workflows/keep-supabase-alive.yml` — Main workflow