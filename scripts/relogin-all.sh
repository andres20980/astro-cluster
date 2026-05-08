#!/usr/bin/env bash
set -euo pipefail
##
# Relogin orchestrator for astro-cluster
# 
# ╔══════════════════════════════════════════════════════════════════╗
# ║  ACCOUNT CONFIGURATION FOR ASTRO-CLUSTER                         ║
# ╠══════════════════════════════════════════════════════════════════╣
# ║  Level 1 - CLI Tools:                                            ║
# ║    GitHub CLI (gh)       → andres20980 (repository account)      ║
# ║    Firebase CLI          → poorku@gmail.com (Hosting deploy)     ║
# ║    gcloud SDK            → poorku@gmail.com (GCP primary)        ║
# ║                                                                  ║
# ║  Level 2 - Service Account:                                      ║
# ║    GOOGLE_APPLICATION_CREDENTIALS → poorku@gmail.com             ║
# ║                     (Gmail, GA4, AdSense APIs)                   ║
# ║                                                                  ║
# ║  Level 4 - Gmail/Workspace:                                      ║
# ║    Aliases               → @licitago.es domain                   ║
# ║    (publicidad@carta-astral-gratis.es, etc.)                    ║
# ║                                                                  ║
# ║  Level 5 - Google Services (Dashboard):                          ║
# ║    GSC, GA4, AdSense OAuth → poorku@gmail.com                    ║
# ║                                                                  ║
# ║  Level 6 - GitHub Secrets:                                       ║
# ║    CI/CD Secrets → andres20980                                   ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Centralizes authentication refresh across all required services:
#  - GitHub CLI (gh)                    → andres20980 (repository operations)
#  - GCP/gcloud (gcloud)                → poorku@gmail.com (Firestore, Cloud Functions)
#  - Firebase CLI (firebase)            → poorku@gmail.com (Hosting deployments)
#  - Google Application Credentials     → poorku@gmail.com (APIs: Gmail, GA4, AdSense)
#
# Usage: ./relogin-all.sh [--force] [--dry-run] [--skip-tests]
##

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly REPO_ROOT="$(dirname "$SCRIPT_DIR")"
readonly LOG_FILE="${REPO_ROOT}/.relogin.log"

# Styling
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

DRY_RUN=false
FORCE_REAUTH=false
SKIP_TESTS=false

# Account Configuration
readonly GITHUB_ACCOUNT="andres20980"               # Level 1: Repository
readonly GCP_ACCOUNT="poorku@gmail.com"             # Level 2/5: GCP, Firestore, GA4, AdSense
readonly FIREBASE_ACCOUNT="poorku@gmail.com"        # Level 1: Firebase Hosting
readonly WORKSPACE_DOMAIN="licitago.es"             # Level 4: Gmail aliases
readonly GITHUB_SECRETS_ACCOUNT="andres20980"       # Level 6: CI/CD

# Config
declare -A GCP_PROJECTS=(
  [default]="carta-astral-f4ab9"
)

declare -a SERVICES=(
  "github"
  "gcloud"
  "firebase"
  "serviceaccount"
)

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

OPTIONS:
  --force          Force reauthentication even if credentials exist
  --dry-run        Show what would be done without making changes
  --skip-tests     Skip validation checks after reauth
  -h, --help       Show this help

EXAMPLE:
  $0                   # Normal relogin flow
  $0 --force           # Force all services to reauthenticate
  $0 --dry-run         # Preview what would happen

EOF
  exit 0
}

log_info() {
  echo -e "${BLUE}ℹ ${1}${NC}" | tee -a "$LOG_FILE"
}

log_success() {
  echo -e "${GREEN}✅ ${1}${NC}" | tee -a "$LOG_FILE"
}

log_error() {
  echo -e "${RED}❌ ${1}${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
  echo -e "${YELLOW}⚠ ${1}${NC}" | tee -a "$LOG_FILE"
}

run_cmd() {
  local cmd="$1"
  local desc="$2"
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY-RUN] Would run: $cmd"
    return 0
  fi
  
  log_info "Running: $desc"
  if eval "$cmd"; then
    log_success "$desc"
    return 0
  else
    log_error "$desc"
    return 1
  fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE_REAUTH=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      log_error "Unknown option: $1"
      usage
      ;;
  esac
done

##
# Service: GitHub CLI
# Account: andres20980 (project repository account)
# Purpose: Repository operations, PRs, issues, commits
##
relogin_github() {
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "GITHUB CLI"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "Expected account: $GITHUB_ACCOUNT"
  
  if ! command -v gh &>/dev/null; then
    log_error "gh CLI not found. Install from: https://cli.github.com"
    return 1
  fi
  
  if gh auth status >/dev/null 2>&1 && [[ "$FORCE_REAUTH" != "true" ]]; then
    local active_account
    active_account=$(gh auth status 2>&1 | grep "Active account: true" -B 1 | grep "account" | sed 's/.*account //;s/ .*//' || echo "unknown")
    log_success "GitHub already authenticated"
    
    if [[ "$active_account" == "$GITHUB_ACCOUNT" ]]; then
      log_success "✅ Active account is correct: $active_account"
    else
      log_warning "⚠️  Active account is $active_account (expected: $GITHUB_ACCOUNT)"
      log_info "Switch with: gh auth switch"
    fi
    gh auth status
    return 0
  fi
  
  if [[ "$DRY_RUN" != "true" ]]; then
    log_warning "GitHub authentication required. Opening browser..."
    log_info "→ Use account: $GITHUB_ACCOUNT"
    gh auth login --web --git https
  else
    log_info "[DRY-RUN] Would run: gh auth login --web"
  fi
}

##
# Service: gcloud SDK
# Account: poorku@gmail.com (GCP primary account)
# Purpose: Firestore, Cloud Functions, GCP project operations
##
relogin_gcloud() {
  log_info ""
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "GCLOUD SDK"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "Expected account: $GCP_ACCOUNT"
  
  if ! command -v gcloud &>/dev/null; then
    log_error "gcloud not found. Install from: https://cloud.google.com/sdk"
    return 1
  fi
  
  local current_account
  current_account=$(gcloud config get-value account 2>/dev/null || echo "")
  
  if [[ -n "$current_account" && "$FORCE_REAUTH" != "true" ]]; then
    log_success "GCP authenticated as: $current_account"
    if [[ "$current_account" != "$GCP_ACCOUNT" ]]; then
      log_warning "⚠️  Active account is NOT $GCP_ACCOUNT"
      log_info "Switch to $GCP_ACCOUNT with: gcloud config set account $GCP_ACCOUNT"
    fi
    return 0
  fi
  
  if [[ "$DRY_RUN" != "true" ]]; then
    log_warning "GCP authentication required. Opening browser..."
    gcloud auth login --no-launch-browser || gcloud auth login
  else
    log_info "[DRY-RUN] Would run: gcloud auth login"
  fi
}

##
# Service: Firebase CLI
# Account: poorku@gmail.com (via gcloud auth / service account)
# Purpose: Hosting deployments for all 6 sites
# Strategy: Uses GOOGLE_APPLICATION_CREDENTIALS (service account) when available
#           Falls back to gcloud auth if service account not configured
##
relogin_firebase() {
  log_info ""
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "FIREBASE CLI"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "Expected: GOOGLE_APPLICATION_CREDENTIALS or gcloud auth"
  
  if ! command -v firebase &>/dev/null; then
    log_warning "firebase CLI not found. Install: npm install -g firebase-tools"
    return 0
  fi
  
  # Check if service account is configured
  local sa_configured=false
  if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]] && [[ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
    sa_configured=true
    log_success "Service account configured: $GOOGLE_APPLICATION_CREDENTIALS"
  fi
  
  # Check if gcloud auth is available
  if gcloud auth application-default print-access-token >/dev/null 2>&1; then
    log_success "gcloud auth available (fallback for Firebase)"
    return 0
  fi
  
  if [[ "$sa_configured" == "true" ]]; then
    log_success "Firebase will use service account credentials"
    return 0
  fi
  
  log_warning "Firebase auth not ready. Configure service account or run:"
  log_info "  gcloud auth application-default login"
}

##
# Service: Google Application Credentials (Service Account)
##
relogin_serviceaccount() {
  log_info ""
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "GOOGLE APPLICATION CREDENTIALS (SERVICE ACCOUNT)"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  local creds_path="${GOOGLE_APPLICATION_CREDENTIALS:-}"
  local default_paths=(
    "$REPO_ROOT/.firebase/service-account.json"
    "$HOME/.config/gcloud/service-account.json"
    "$REPO_ROOT/service-account.json"
  )
  
  # Try to find creds if not set
  if [[ -z "$creds_path" ]]; then
    for path in "${default_paths[@]}"; do
      if [[ -f "$path" ]]; then
        creds_path="$path"
        break
      fi
    done
  fi
  
  if [[ -z "$creds_path" ]]; then
    log_warning "No service account credentials found"
    log_info "Expected one of:"
    for path in "${default_paths[@]}"; do
      log_info "  - $path"
    done
    log_info "To generate:"
    log_info "  1. Go to GCP Console → Service Accounts"
    log_info "  2. Create new key (JSON format)"
    log_info "  3. Save to: ${default_paths[0]}"
    return 1
  fi
  
  if [[ ! -f "$creds_path" ]]; then
    log_error "Credentials file not found: $creds_path"
    return 1
  fi
  
  local creds_age
  creds_age=$(( $(date +%s) - $(stat -c %Y "$creds_path" 2>/dev/null || stat -f %m "$creds_path") ))
  local days_old=$(( creds_age / 86400 ))
  
  log_success "Service account credentials found: $creds_path"
  log_info "Last updated: ${days_old} days ago"
  
  if [[ $days_old -gt 90 ]]; then
    log_warning "Credentials older than 90 days - consider rotating"
    log_info "To rotate: Go to GCP Console → Service Accounts → Create new key"
  fi
  
  # Validate JSON structure
  if ! python3 -c "import json; json.load(open('$creds_path'))" 2>/dev/null; then
    log_error "Service account credentials are not valid JSON"
    return 1
  fi
  
  log_success "Service account credentials are valid"
}

##
# Validation & Tests
##
test_github() {
  if ! gh auth status >/dev/null 2>&1; then
    log_error "GitHub authentication test failed"
    return 1
  fi
  log_success "GitHub authentication test passed"
}

test_gcloud() {
  if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" >/dev/null 2>&1; then
    log_error "GCloud authentication test failed"
    return 1
  fi
  log_success "GCloud authentication test passed"
}

test_firebase() {
  if ! command -v firebase &>/dev/null; then
    log_warning "Firebase CLI not installed, skipping test"
    return 0
  fi

  # Preferred path: service account / ADC (non-interactive, CI-friendly)
  if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]] && [[ -f "${GOOGLE_APPLICATION_CREDENTIALS}" ]]; then
    if gcloud auth application-default print-access-token >/dev/null 2>&1; then
      log_success "Firebase authentication test passed (service account / ADC)"
      return 0
    fi
  fi

  # Fallback path: interactive Firebase CLI login
  if firebase login:list >/dev/null 2>&1; then
    log_success "Firebase authentication test passed (firebase login)"
    return 0
  fi

  log_error "Firebase authentication test failed"
  return 1
}

test_serviceaccount() {
  if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]] && [[ ! -f "$REPO_ROOT/.firebase/service-account.json" ]]; then
    log_warning "Service account not configured, skipping test"
    return 0
  fi
  log_success "Service account credentials test passed"
}

run_tests() {
  log_info ""
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "VALIDATION TESTS"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  local failures=0
  
  test_github || ((failures++))
  test_gcloud || ((failures++))
  test_firebase || ((failures++))
  test_serviceaccount || ((failures++))
  
  if [[ $failures -eq 0 ]]; then
    log_success "All tests passed! 🎉"
    return 0
  else
    log_error "$failures test(s) failed"
    return 1
  fi
}

##
# Main orchestration
##
main() {
  echo "Starting relogin orchestration..."
  echo "Timestamp: $(date)" >> "$LOG_FILE"
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "DRY-RUN MODE - No changes will be made"
  fi
  
  local failures=0
  
  for service in "${SERVICES[@]}"; do
    "relogin_$service" || ((failures++))
  done
  
  if [[ "$SKIP_TESTS" != "true" ]]; then
    run_tests || ((failures++))
  fi
  
  log_info ""
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "SUMMARY"
  log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  if [[ $failures -eq 0 ]]; then
    log_success "Relogin process completed successfully"
    echo "Log: $LOG_FILE"
    exit 0
  else
    log_error "Relogin process had $failures failure(s)"
    echo "Log: $LOG_FILE"
    exit 1
  fi
}

main "$@"
