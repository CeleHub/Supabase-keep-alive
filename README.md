# Supabase Keep Alive (Pro Version)

Keeps multiple Supabase projects awake + sends real-time alerts to Telegram.

---

## Features

- Unlimited Supabase projects
- Daily automated ping
- GitHub Actions summary UI
- Telegram notifications
- Success / failure tracking per project

---

## Setup

### 1. Create GitHub Secrets

| Secret | Description |
|--------|------------|
| PROJECTS_CONFIG | JSON list of projects |
| TELEGRAM_BOT_TOKEN | Telegram bot token |
| TELEGRAM_CHAT_ID | Your chat ID |

---

### 2. Example PROJECTS_CONFIG

```json
[
  {
    "name": "Guardian Connect",
    "url": "https://xxx.supabase.co",
    "apikey": "key",
    "table": "students"
  }
]