# Codex Working Agreements

- Use only the minimum context needed for the current task.
- Prefer targeted reads over broad repository scans.
- Prefer small, reversible diffs over broad refactors.
- Respond concisely and keep explanations high signal.
- If `gh` fails from the sandbox with a network/connectivity error, retry the same scoped `gh` command with escalated permissions immediately instead of spending time on alternate debugging.

## Authentication Management

### Quick Start
```bash
# 1. Set service account (single credential for all)
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/service-account.json"

# 2. Verify all services
./scripts/relogin-all.sh

# 3. Ready to deploy/work
firebase deploy
gcloud firestore query
```

### Commands
```bash
# Normal relogin (checks before refreshing)
./scripts/relogin-all.sh

# Force full reauthentication
./scripts/relogin-all.sh --force

# Preview without changes
./scripts/relogin-all.sh --dry-run
```

**Services managed:**
- GitHub CLI (`gh`) — repository operations (andres20980)
- gcloud SDK — GCP/Firestore/Cloud Functions (poorku@gmail.com)
- Firebase CLI — hosting deployments (via service account)
- Google Application Credentials — Gmail, GA4, AdSense APIs (poorku@gmail.com)

**🎯 Best Practice:** Use service account for Firebase (no interactive login)

See [RELOGIN_RUNBOOK.md](docs/RELOGIN_RUNBOOK.md) for full documentation and setup guide.

## Final response

Cuando haya cambios reales en código, configuración o decisiones operativas, termina en español con:

- Cambios
- Riesgo
- Verificación
