# Supabase Keep-Alive

GitHub Actions workflow to keep multiple Supabase projects awake on the free tier.

## Features

- Supports any number of Supabase projects
- Easy to add/remove projects without editing workflow code
- Daily ping schedule
- Clear success/failure reporting

## Setup

1. Add the following **Repository Secret**:

   | Secret Name         | Description                                      |
   |---------------------|--------------------------------------------------|
   | `PROJECTS_CONFIG`   | JSON array containing project configurations     |

2. Go to **Settings → Secrets and variables → Actions → New repository secret**

3. Use `PROJECTS_CONFIG` as the name and paste your configuration (example below).

### PROJECTS_CONFIG Example

```json
[
  {
    "name": "Good's Location",
    "url": "https://your-project-ref.supabase.co",
    "key": "fgjbndinIIBIB567CVhbuvuhvYCYT7VGYH...",
    "table": "profiles"
  },
  {
    "name": "Project 2",
    "url": "https://second-project-ref.supabase.co",
    "key": "fgjbndinIIBIB567CVhbuvuhvYCYT7VGYH...",
    "table": "users"
  }
]