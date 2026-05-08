# Relogin Runbook
> Automated authentication refresh for astro-cluster services

## Overview

`relogin-all.sh` is a centralized authentication orchestrator that manages credentials across all services with clear account segregation by operational level.

---

## Account Configuration

```
├─ Level 1: CLI Tools
│  ├─ GitHub CLI (gh)          → andres20980 (repository)
│  ├─ Firebase CLI             → poorku@gmail.com (hosting deploy)
│  └─ gcloud SDK               → poorku@gmail.com (GCP)
│
├─ Level 2: Service Account
│  └─ GOOGLE_APPLICATION_CREDENTIALS → poorku@gmail.com (APIs)
│
├─ Level 3: Environment Variables
│  └─ OPENAI_API_KEY, GEMINI_API_KEY, etc.
│
├─ Level 4: Gmail/Workspace Aliases
│  └─ @licitago.es domain
│     (publicidad@carta-astral-gratis.es, etc.)
│
├─ Level 5: Google Services Dashboard
│  ├─ Google Search Console    → poorku@gmail.com
│  ├─ Google Analytics 4       → poorku@gmail.com
│  └─ AdSense                  → poorku@gmail.com
│
└─ Level 6: GitHub Secrets
   └─ CI/CD Service Account    → andres20980
```

---

## Quick Start

### Normal relogin (checks before refreshing)
```bash
./scripts/relogin-all.sh
```

### Force full reauthentication
```bash
./scripts/relogin-all.sh --force
```

### Preview without making changes
```bash
./scripts/relogin-all.sh --dry-run
```

### Skip validation tests after reauth
```bash
./scripts/relogin-all.sh --skip-tests
```

---

## Service Details

### Level 1: CLI Tools

#### GitHub CLI (`gh`)
**Account:** andres20980  
**Purpose:** Repository operations, PR/issue automation, commit signing  
**Status Check:**
```bash
gh auth status
```
**Manual Reauth:**
```bash
gh auth login --web
# Switch if needed:
gh auth switch
```
**Required for:**
- `git push` operations
- PR automation scripts
- GitHub Actions workflows
- Repository management

---

#### Firebase CLI
**Account:** poorku@gmail.com (via service account or gcloud auth)  
**Purpose:** Firebase Hosting deployments for all 6 sites  
**Best Practice:** Uses `GOOGLE_APPLICATION_CREDENTIALS` (service account) instead of interactive login  
**Status Check:**
```bash
firebase projects:list
```
**Setup (Best Practice):**

Option 1 — Service Account (Recommended):
```bash
# Set environment variable to point to service account key
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# Firebase will automatically use it
firebase deploy
```

Option 2 — gcloud auth (Fallback):
```bash
# Use gcloud credentials
gcloud auth application-default login

# Firebase will use gcloud's credentials
firebase deploy
```

Option 3 — Interactive Login (Not Recommended):
```bash
# Only if service account and gcloud auth are unavailable
firebase login
```

**Why Service Account is Better:**
- No interactive browser login needed
- Works in CI/CD environments
- Same account as gcloud/Firestore
- Easier to rotate and manage
- No credential expiration issues

**Required for:**
- `firebase deploy` (all 6 sites)
- Local Firebase emulator
- Hosting preview URLs

---

#### gcloud SDK
**Account:** poorku@gmail.com  
**Purpose:** GCP project access, Firestore, Cloud Functions, Pub/Sub  
**Status Check:**
```bash
gcloud auth list --filter=status:ACTIVE
gcloud config get-value account
```
**Manual Reauth:**
```bash
gcloud auth login
gcloud config set account poorku@gmail.com
```
**Required for:**
- Firestore local queries (GA4 data)
- Cloud Functions deployments
- GCS bucket operations
- Project management

---

### Level 2: Google Application Credentials (Service Account)
**Account:** poorku@gmail.com  
**Purpose:** Server-side API access for Gmail, GA4, AdSense without user interaction  
**Status Check:**
```bash
echo $GOOGLE_APPLICATION_CREDENTIALS
cat ~/.config/gcloud/service-account.json
```

#### Expected Locations (checked in order):
1. `$GOOGLE_APPLICATION_CREDENTIALS` env var
2. `.firebase/service-account.json`
3. `~/.config/gcloud/service-account.json`
4. `service-account.json` (repo root)

#### How to Create/Rotate Service Account Key:

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate: **APIs & Services** → **Service Accounts**
3. Click your service account email
4. Go to **Keys** tab
5. Click **Add Key** → **Create new key** → **JSON**
6. Save the downloaded JSON file to one of the locations above

#### Validation:
- Keys are rotated if older than 90 days (warning only)
- JSON structure is validated automatically

#### Required for:
- Gmail API access (automated outreach)
- GA4 Reporting API
- AdSense API
- Firestore backend operations
- Background jobs

---

### Level 4: Gmail/Workspace
**Domain:** licitago.es  
**Purpose:** Email operations, aliases for astro-cluster  
**Aliases:**
```
publicidad@carta-astral-gratis.es → info@licitago.es
(and other site-specific aliases)
```

#### SMTP/IMAP Tests:
```bash
# Test SMTP
GMAIL_USER="publicidad@carta-astral-gratis.es" \
GMAIL_PASS="app-specific-password" \
ASTRO_MAIL_TO="info@licitago.es" \
npm run smoke:smtp --prefix functions-gmail

# Test IMAP
GMAIL_USER="publicidad@carta-astral-gratis.es" \
GMAIL_PASS="app-specific-password" \
ASTRO_MAIL_TO="info@licitago.es" \
ASTRO_MAIL_SUBJECT="test subject" \
npm run smoke:imap --prefix functions-gmail
```

#### Domain-Wide Delegation (DWD):
For automated Gmail operations via service account:
- OAuth Client ID: `103499506294515431597`
- Scopes: Gmail send/read/modify, Admin directory
- Setup: Google Admin > Security > API controls > Domain-wide delegation

---

### Level 5: Google Services (Dashboard/UI)
**Account:** poorku@gmail.com  
**Purpose:** SEO, Analytics, Revenue reports  

#### Google Search Console (GSC)
- Purpose: Sitemap submission, keyword analysis, indexing status
- Domains: All 6 astro-cluster sites
- Manual check: https://search.google.com/search-console

#### Google Analytics 4 (GA4)
- Property ID: `G-DEWMQ73FH5`
- Purpose: Traffic reports, custom dimensions, conversion tracking
- Manual check: https://analytics.google.com

#### AdSense
- Publisher ID: `ca-pub-9368517395014039`
- Purpose: Revenue reports, auto ads configuration
- Manual check: https://adsense.google.com

---

### Level 6: GitHub Secrets (CI/CD)
**Account:** andres20980  
**Purpose:** GitHub Actions workflows, automated deployments  
**Secrets managed:**
- Service Account Key (JSON) — for `update_weekly_public_stats.sh` workflow
- GA4 Reporting API token generation

---

## Environment Configuration

### Set Service Account Explicitly
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
./scripts/relogin-all.sh
```

### Persistent (add to `~/.bashrc` or `~/.zshrc`)
```bash
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/service-account.json"
```

## Best Practices Summary

### ✅ Recommended Workflow

1. **Level 2 Service Account** — Single source of truth
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/service-account.json"
   ```
   This **single credential** automatically unlocks:
   - ✅ Firebase deployments (no interactive login)
   - ✅ gcloud commands
   - ✅ GA4 Reporting API
   - ✅ Gmail API
   - ✅ AdSense API

2. **CLI Tools** — Use account-specific auth
   ```bash
   gh auth switch        # Switch to andres20980
   gcloud config set account poorku@gmail.com
   ```

3. **Never Do:**
   - ❌ Interactive `firebase login` (use service account instead)
   - ❌ Store API keys in code (use env vars / secrets)
   - ❌ Commit service account keys (use `.gitignore`)
   - ❌ Mix multiple gcloud accounts in deploy scripts

### 🔄 Setup Order

```bash
# 1. Generate service account key (GCP Console)
# 2. Place it in ~/.config/gcloud/service-account.json
# 3. Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/service-account.json"

# 4. Verify all services work
./scripts/relogin-all.sh

# 5. You're ready:
firebase deploy        # Works (no login needed)
gcloud firestore ...   # Works
ga4-api-script.py      # Works
```

### 📋 Why Service Account?

| Aspect | Interactive Login | Service Account |
|--------|------------------|-----------------|
| Browser required | ✅ Yes | ❌ No |
| CI/CD friendly | ❌ No | ✅ Yes |
| Expiration | ⚠️ 30+ days | ✅ 90+ days (rotatable) |
| Multi-service | ❌ Firebase only | ✅ All APIs |
| Security audit | ⚠️ Personal account | ✅ Service-specific |

---

### "gcloud not found"
```bash
# Install GCP SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

### "firebase not found"
```bash
npm install -g firebase-tools
firebase login
```

### "gh not found"
```bash
# On macOS:
brew install gh

# On Linux (Ubuntu/Debian):
curl -fsSLo /usr/share/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

### Service account credentials are invalid
1. Check file exists: `ls -la $GOOGLE_APPLICATION_CREDENTIALS`
2. Validate JSON: `python3 -m json.tool < $GOOGLE_APPLICATION_CREDENTIALS`
3. If corrupted, delete and regenerate:
   ```bash
   rm $GOOGLE_APPLICATION_CREDENTIALS
   # Then follow "How to Create/Rotate Service Account Key" above
   ```

### "403 ACCESS_TOKEN_SCOPE_INSUFFICIENT" in GA4 queries
- Regenerate service account key with proper scopes
- Add `roles/analytics.viewer` to service account in GCP

### Credentials older than 90 days
This is a warning only, but best practice is to rotate:
1. Delete old key from GCP Console
2. Create new key (JSON)
3. Replace in storage location
4. Run `./scripts/relogin-all.sh --force`

### Wrong account active
```bash
# GitHub: switch active account
gh auth switch

# gcloud: switch active account
gcloud config set account poorku@gmail.com

# Firebase: logout and relogin
firebase logout
firebase login
```

---

## Maintenance Schedule

| Level | Service | Frequency | Action |
|-------|---------|-----------|--------|
| 1 | GitHub CLI | Auto-refreshed | Monthly check: `gh auth status` |
| 1 | Firebase | Auto-refreshed | Monthly check: `firebase auth:list` |
| 1 | gcloud | Auto-refreshed | Monthly check: `gcloud auth list` |
| 2 | Service Account | Manual rotation | Every 90 days |
| 5 | GA4/GSC/AdSense | Browser login | Refresh if OAuth expires |
| 6 | GitHub Secrets | Manual update | When SA key rotates |

---

## Integration with Other Scripts

Once authenticated, other scripts can safely assume credentials are available:

```bash
# In other scripts:
source "${REPO_ROOT}/scripts/relogin-all.sh" || exit 1

# Or before deployment:
./scripts/relogin-all.sh --force
./deploy.sh
```

---

## Automation / CI/CD Context

⚠️ **Note:** In CI/CD (GitHub Actions), use service account credentials only:
```yaml
# GitHub Actions example
env:
  GOOGLE_APPLICATION_CREDENTIALS: /tmp/sa-key.json
  
steps:
  - name: Setup credentials
    run: |
      echo "${{ secrets.GCP_SERVICE_ACCOUNT }}" > /tmp/sa-key.json
  
  - name: Deploy
    run: ./deploy.sh
```

Never commit service account keys. Use GitHub Secrets for CI/CD.

---

## Log & Debugging

All operations are logged to `.relogin.log`:
```bash
tail -f .relogin.log
```

For debugging, run with verbose output:
```bash
bash -x ./scripts/relogin-all.sh --dry-run
```

---

## Related Scripts

- [`deploy.sh`](../deploy.sh) — Firebase Hosting deployment (requires Firebase auth)
- [`functions-gmail/scripts/gmail-probe.js`](../functions-gmail/scripts/gmail-probe.js) — Gmail API test (requires service account)
- [`.github/scripts/update_weekly_public_stats.sh`](../.github/scripts/update_weekly_public_stats.sh) — GA4 data pull (requires service account in Secrets)
