# ⚡ Supabase Keep-Alive (Pro)

> Keep all your free-tier Supabase projects awake and active forever — completely automated, 100% serverless, running entirely on GitHub Actions with optional Telegram alerts.

---

## 🌟 Why This Repo? (The Zero-Deployment Advantage)

Unlike other keep-alive tools that require deploying to third-party services like **Vercel**, **Render**, **AWS Lambda**, or setting up external cron monitors like **cron-job.org** or **UptimeRobot**, this solution is **100% self-contained within GitHub**:

* 🚀 **Zero External Deployments** — No external hosting, no cloud providers, no API subscriptions.
* 💸 **100% Free Forever** — Runs within GitHub Actions' generous free tier (uses less than 30 seconds a day).
* 🔒 **Zero Table Dependency** — No need to create dummy tables or remember column names. It pings the database connection pool directly via the native PostgREST root endpoint (`/rest/v1/`).
* 📁 **Easy Multi-DB Management** — Add new databases anytime without re-typing or losing your existing database configurations.
* 📊 **Rich GitHub Summary & Telegram** — Native GitHub Actions Markdown report on every run + optional real-time Telegram notifications.

---

## 🚀 How It Works

Free-tier Supabase projects automatically pause after **7 days of inactivity**.

Every day at **midnight UTC** (`0 0 * * *`), GitHub Actions triggers a lightweight script that:
1. Reads your list of Supabase projects.
2. Pings each project via its PostgREST API with network timeouts (`--connect-timeout 10 --max-time 30`).
3. Diagnoses HTTP status codes (e.g. `200 OK`, `401 Unauthorized`, `503 Service Unavailable`).
4. Generates a clean execution report directly inside the GitHub Actions **Summary UI**.
5. (Optional) Sends an instant summary report to your **Telegram** bot.

---

## 🔑 Understanding the Configuration Keys

You might configure this once and forget where keys came from when you want to add another database months later. Here is the exact cheat sheet:

### 1. `url` (Supabase Project URL)
* **What it is:** The base URL of your Supabase project REST API.
* **Format:** `https://<your-project-ref>.supabase.co`
* **Where to find it in Supabase:**
  1. Open your [Supabase Dashboard](https://supabase.com/dashboard).
  2. Select your project.
  3. In the left sidebar, click the **Settings** gear icon (⚙️) at the bottom.
  4. Click **API** (or **Data API**).
  5. Under **Project URL**, copy the `URL`.

### 2. `apikey` (Supabase Anon Public Key)
* **What it is:** The public anonymous API key used to authenticate requests against PostgREST.
* **Format:** A long JWT string starting with `eyJhbGci...`
* **Where to find it in Supabase:**
  1. In the same **Settings -> API** page.
  2. Under **Project API keys**, look for the key labeled **`anon` `public`**.
  3. Click **Copy**.
  > [!TIP]
  > Always use the **`anon` `public`** key. You do NOT need the sensitive `service_role` key to keep your database alive.

### 3. `name` (Friendly Name)
* **What it is:** Any custom label for your project (e.g., `"Guardian Connect"`, `"Portfolio DB"`, `"SaaS Staging"`). Used in log tables and Telegram notifications.

### 4. `table` *(Completely Optional!)*
* **What it is:** An optional specific table name to query (e.g. `"profiles"`).
* **If omitted:** The script automatically pings the root endpoint (`/rest/v1/`), waking up PostgREST and the Postgres database pool without needing any specific table or schema!

---

## 🔒 Security: Public vs. Private Repositories

Before choosing how to manage your database configurations, consider your repository privacy:

* **If your repository is PRIVATE (Recommended ⭐):**
  * You can use **Option A (`projects.json`)** with total peace of mind.
  * GitHub gives you **unlimited free private repositories** with **2,000 free Actions minutes/month** (this tool uses only ~8 minutes/month).
  * You get maximum convenience: open `projects.json` directly on GitHub, click edit, append a new database, and commit.
* **If your repository is PUBLIC:**
  * **Use Option B (GitHub Secrets).**
  * In a public repository, any file committed to git is visible to the entire world.
  * `projects.json` is included in [`.gitignore`](file:///.gitignore) by default to prevent accidental exposure of your credentials.
  * *Pro tip for public repos:* Keep a master `projects.json` file locally on your computer (it will be ignored by git). Whenever you add a new database, just append it to your local file and paste the updated JSON into the `PROJECTS_CONFIG` secret in GitHub.

> [!WARNING]
> Never commit your Supabase `service_role` key anywhere. Always use the **`anon` `public`** key, which has Row Level Security and is all that is needed to keep your database awake.

---

## ⚙️ Configuration Guide (Recommended: Local Master File Pattern)

Because this repository is public, credentials should **never** be committed to git. 

To make it effortless to remember and manage your databases over time without losing track of previous ones, use the **Local Master File Pattern**:

---

### Step 1: Create your local `projects.json`
`projects.json` is already protected in [`.gitignore`](file:///.gitignore), meaning git will never track or publish it.

Create `projects.json` in the root of your local project by copying [`example-projects.json`](file:///example-projects.json):

```bash
cp example-projects.json projects.json
```

Edit `projects.json` with your real database details:
```json
[
  {
    "name": "Guardian Connect",
    "url": "https://xyzcompany.supabase.co",
    "apikey": "eyJhbGciOi..."
  },
  {
    "name": "Personal Portfolio",
    "url": "https://abcdefgh.supabase.co",
    "apikey": "eyJhbGciOi..."
  }
]
```

*(Optional)* You can test your configuration immediately from your terminal:
```bash
bash scripts/ping.sh
```

---

### Step 2: Add to GitHub Secrets (`PROJECTS_CONFIG`)
1. Go to your repository on GitHub.
2. Click **Settings** -> **Secrets and variables** -> **Actions**.
3. Click **New repository secret**.
4. Set the name to:
   ```
   PROJECTS_CONFIG
   ```
5. Open your local `projects.json`, copy the entire JSON array, paste it into the value field, and click **Add secret**.

---

### 💡 How to Add or Remove Databases in the Future
Whenever you need to add a 3rd or 4th database months from now:
1. Open your local `projects.json` file. All your existing database names and URLs are right there in plain sight.
2. Add your new database object to the array (or delete one you no longer need).
3. Copy the whole JSON array.
4. Go to GitHub -> **Settings** -> **Secrets and variables** -> **Actions** -> click `PROJECTS_CONFIG` -> click **Update** -> paste and save!

Your public repo stays 100% clean and credential-free, and you never have to guess what's currently being pinged.

---

> [!TIP]
> **Private Repo Alternative:** If you ever change this repository to **Private**, you can also choose to commit `projects.json` directly to the repository and edit it straight from the GitHub web UI. The script will automatically detect and use it.

---

## 📱 (Optional) Telegram Notifications Setup

If you want real-time ping alerts sent to your phone via Telegram, add these two secrets under **Settings -> Secrets and variables -> Actions**:

| Secret | Description | Where to get it |
| :--- | :--- | :--- |
| `TELEGRAM_BOT_TOKEN` | Bot API Token | Open Telegram, search for `@BotFather`, send `/newbot`, and copy the token. |
| `TELEGRAM_CHAT_ID` | Your Chat ID | Search for `@userinfobot` on Telegram, send `/start`, and copy your `Id`. |

> [!NOTE]
> Telegram notifications are **100% optional**. If you do not configure these secrets, the workflow runs normally without errors and displays the report in the GitHub Actions UI.

---

## 🧪 Testing Your Setup Manually

You don't have to wait until midnight to verify it works:
1. Go to the **Actions** tab in your GitHub repository.
2. In the left sidebar, click **Supabase Keep Alive**.
3. Click the **Run workflow** dropdown button on the right, and click **Run workflow**.
4. Click into the run to view the live logs and inspect the rich Markdown summary table!

---

## 📄 License

MIT License. Free to use, fork, and adapt for personal or commercial projects.