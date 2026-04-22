#!/usr/bin/env bash
set -euo pipefail
# Deploy one or all sites to Firebase Hosting
# Usage: ./deploy.sh [site-name]   (blank = all sites)

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
source "${REPO_ROOT}/shared/config.sh"

declare -A PROJECTS=(
  [carta-astral]="carta-astral-f4ab9"
  [compatibilidad-signos]="compat-signos-es"
  [tarot-del-dia]="tarot-del-dia-es"
  [calcular-numerologia]="calc-numerologia-es"
  [horoscopo-de-hoy]="horoscopo-hoy-es"
)

deploy_site() {
  local site="$1"
  local project="${PROJECTS[$site]}"
  local site_dir="${REPO_ROOT}/sites/${site}"

  if [[ ! -d "$site_dir/public" ]]; then
    echo "❌ No public/ found for ${site}. Run gen-pages.sh first."
    return 1
  fi
  adsense_apply_head_snippet_to_file "$site_dir/public/index.html"

  echo ""
  echo "🚀 Deploying ${site} → ${project}"
  cd "$site_dir"
  firebase deploy --only hosting --project "$project"
  echo "✅ ${site} deployed"
}

if [[ $# -ge 1 && -n "$1" ]]; then
  # Deploy single site
  if [[ -z "${PROJECTS[$1]+x}" ]]; then
    echo "❌ Unknown site: $1"
    echo "Available: ${!PROJECTS[*]}"
    exit 1
  fi
  deploy_site "$1"
else
  # Deploy all
  echo "🚀 Deploying all 5 sites..."
  for site in carta-astral compatibilidad-signos tarot-del-dia calcular-numerologia horoscopo-de-hoy; do
    deploy_site "$site"
  done
  echo ""
  echo "🎉 All sites deployed!"
fi
