#!/bin/bash
set -eo pipefail

# =============================================================================
# Supabase Keep-Alive Ping Script
# =============================================================================
# Supports:
#   1. PROJECTS_CONFIG environment variable (from GitHub Secrets)
#   2. projects.json file in the repository root
#   3. Automatic merging of both sources
#   4. Optional "table" parameter (defaults to root /rest/v1/ if omitted)
#   5. Network timeouts, exact HTTP status diagnostics, and rich summary outputs
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SECRET_JSON="[]"
FILE_JSON="[]"

# 1. Read from PROJECTS_CONFIG environment variable (GitHub Secrets) if available
if [ -n "$PROJECTS_CONFIG" ]; then
  if echo "$PROJECTS_CONFIG" | jq -e 'if type == "array" then true else false end' >/dev/null 2>&1; then
    SECRET_JSON="$PROJECTS_CONFIG"
  else
    echo "⚠️ Warning: PROJECTS_CONFIG environment variable is not a valid JSON array."
  fi
fi

# 2. Read from projects.json in repository root if available
if [ -f "$REPO_DIR/projects.json" ]; then
  if jq -e 'if type == "array" then true else false end' "$REPO_DIR/projects.json" >/dev/null 2>&1; then
    FILE_JSON=$(cat "$REPO_DIR/projects.json")
  else
    echo "⚠️ Warning: projects.json exists but is not a valid JSON array."
  fi
fi

# 3. Merge configurations: combine both sources and deduplicate by URL or Name
PROJECTS=$(jq -n --argjson f "$FILE_JSON" --argjson s "$SECRET_JSON" '
  ($f + $s)
  | map(select(.url != null and .url != "" and (.url | test("(project-ref|your-project-ref)\\.supabase\\.co") | not)))
  | map(select(.apikey != null and .apikey != "" and (.apikey | test("YOUR_SUPABASE_ANON_KEY") | not)))
  | group_by(.url // .name)
  | map(last)
')

NUM_PROJECTS=$(echo "$PROJECTS" | jq 'length')

if [ "$NUM_PROJECTS" -eq 0 ]; then
  ERROR_MSG="No valid projects found to ping! Please configure either the PROJECTS_CONFIG secret or add projects to projects.json."
  echo "❌ $ERROR_MSG"
  
  if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    echo "### ❌ Supabase Keep-Alive Error" >> "$GITHUB_STEP_SUMMARY"
    echo "$ERROR_MSG" >> "$GITHUB_STEP_SUMMARY"
  fi
  
  if [ -n "$GITHUB_OUTPUT" ]; then
    {
      echo "summary<<EOF"
      echo "$ERROR_MSG"
      echo "EOF"
      echo "telegram_message<<EOF"
      echo "$ERROR_MSG"
      echo "EOF"
    } >> "$GITHUB_OUTPUT"
  fi
  exit 1
fi

echo "=================================================="
echo "  Supabase Keep-Alive: Starting Ping ($NUM_PROJECTS project(s))"
echo "=================================================="

SUCCESS=0
FAIL=0

SUMMARY_ROWS=""
TELEGRAM="🚀 Supabase Keep-Alive Report
"

while read -r project; do
  NAME=$(echo "$project" | jq -r '.name // "Unnamed Project"')
  URL=$(echo "$project" | jq -r '.url // empty')
  KEY=$(echo "$project" | jq -r '.apikey // empty')
  TABLE=$(echo "$project" | jq -r 'if (.table | type == "string") and (.table != "") then .table else empty end')

  # Clean URL: strip trailing slash and prepend https:// if protocol is omitted
  URL="${URL%/}"
  if [[ ! "$URL" =~ ^https?:// ]]; then
    URL="https://$URL"
  fi

  if [ -z "$KEY" ]; then
    echo "❌ $NAME: Missing 'apikey' in configuration."
    ((FAIL++))
    SUMMARY_ROWS+="| 🔴 | **$NAME** | \`N/A\` | N/A | Missing API Key |"$'\n'
    TELEGRAM+="❌ $NAME (Config Error: Missing API Key)"$'\n'
    continue
  fi

  # Determine target endpoint: table is completely optional
  if [ -n "$TABLE" ]; then
    ENDPOINT="$URL/rest/v1/$TABLE?limit=1"
    TARGET_DISPLAY="/rest/v1/$TABLE"
  else
    ENDPOINT="$URL/rest/v1/"
    TARGET_DISPLAY="/rest/v1/ (root)"
  fi

  echo "Pinging $NAME ($URL)..."
  echo "  Endpoint: $TARGET_DISPLAY"

  RESP_BODY=$(mktemp)
  RESP_ERR=$(mktemp)

  # Execute curl: 10s connect timeout, 30s max total time, follow redirects (-L)
  HTTP_CODE=$(curl -s -S -L -o "$RESP_BODY" -w "%{http_code}" \
    --connect-timeout 10 \
    --max-time 30 \
    "$ENDPOINT" \
    -H "apikey: $KEY" \
    -H "Authorization: Bearer $KEY" \
    2>"$RESP_ERR") || true
  HTTP_CODE="${HTTP_CODE:-000}"

  if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo "  ✅ SUCCESS: HTTP $HTTP_CODE"
    ((SUCCESS++))
    SUMMARY_ROWS+="| 🟢 | **$NAME** | \`$HTTP_CODE\` | \`$TARGET_DISPLAY\` | OK |"$'\n'
    TELEGRAM+="✅ $NAME (HTTP $HTTP_CODE)"$'\n'
  else
    # Extract error reason for diagnostics
    if [ "$HTTP_CODE" = "000" ]; then
      ERR_DETAIL=$(head -n 1 "$RESP_ERR" | sed -E 's/curl: \([0-9]+\) //' | tr -d '\r\n')
      [ -z "$ERR_DETAIL" ] && ERR_DETAIL="Connection timed out or network error"
    else
      # Attempt extracting JSON error message from response
      ERR_DETAIL=$(jq -r '.message // .error // .hint // empty' "$RESP_BODY" 2>/dev/null || true)
      if [ -z "$ERR_DETAIL" ]; then
        ERR_DETAIL=$(head -c 80 "$RESP_BODY" | tr -d '\r\n' | sed 's/[|]/ /g')
      fi
      [ -z "$ERR_DETAIL" ] && ERR_DETAIL="HTTP Request Failed"
    fi

    echo "  ❌ FAILED: HTTP $HTTP_CODE ($ERR_DETAIL)"
    ((FAIL++))
    SUMMARY_ROWS+="| 🔴 | **$NAME** | \`$HTTP_CODE\` | \`$TARGET_DISPLAY\` | $ERR_DETAIL |"$'\n'
    TELEGRAM+="❌ $NAME (HTTP $HTTP_CODE: $ERR_DETAIL)"$'\n'
  fi

  rm -f "$RESP_BODY" "$RESP_ERR"

done < <(echo "$PROJECTS" | jq -c '.[]')

TOTAL=$((SUCCESS + FAIL))

echo ""
echo "=================================================="
echo "  Ping Summary: Total: $TOTAL | Success: $SUCCESS | Failed: $FAIL"
echo "=================================================="

# Build Rich Markdown for GitHub Step Summary
MARKDOWN_SUMMARY="### 🚀 Supabase Keep-Alive Execution Report

| Status | Project | HTTP Status | Target Endpoint | Details |
| :---: | :--- | :---: | :--- | :--- |
$SUMMARY_ROWS
> **Results:** **$SUCCESS** succeeded, **$FAIL** failed out of **$TOTAL** total project(s).
"

# Build Telegram message
TELEGRAM+="
📊 Summary: $SUCCESS Succeeded | $FAIL Failed | $TOTAL Total"

# Write directly to GitHub Step Summary if running in GitHub Actions
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
  echo "$MARKDOWN_SUMMARY" >> "$GITHUB_STEP_SUMMARY"
fi

# Write step outputs for downstream workflow steps
if [ -n "$GITHUB_OUTPUT" ]; then
  {
    echo "summary<<EOF"
    echo "$MARKDOWN_SUMMARY"
    echo "EOF"
  } >> "$GITHUB_OUTPUT"

  {
    echo "telegram_message<<EOF"
    echo "$TELEGRAM"
    echo "EOF"
  } >> "$GITHUB_OUTPUT"
fi