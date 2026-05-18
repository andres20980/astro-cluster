#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT_DIR/../.." && pwd)"
PUBLIC_DIR="$ROOT_DIR/public"

bash "$REPO_ROOT/scripts/generate-legal-pages.sh" meditacion-chakras

required=(index.html privacy.html terms.html publicidad.html robots.txt sitemap.xml ads.txt 404.html)
missing=0

for file in "${required[@]}"; do
  if [[ ! -f "$PUBLIC_DIR/$file" ]]; then
    echo "Missing required file: $PUBLIC_DIR/$file" >&2
    missing=1
  fi
done

if [[ "$missing" -eq 1 ]]; then
  exit 1
fi

echo "meditacion-chakras static files ready"
