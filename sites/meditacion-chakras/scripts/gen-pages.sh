#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBLIC="$SITE_DIR/public"
DOCS="$SITE_DIR/docs"
REPO_ROOT="$(cd "$SITE_DIR/../.." && pwd)"

source "$REPO_ROOT/shared/config.sh"

SITE_KEY="meditacion-chakras"
DOMAIN="${DOMAINS[$SITE_KEY]}"
GA4="${GA4_IDS[$SITE_KEY]}"

mkdir -p "$PUBLIC" "$DOCS"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 no disponible" >&2
  exit 1
fi

VENV_DIR="$SITE_DIR/.venv"
if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv "$VENV_DIR"
fi

"$VENV_DIR/bin/python" -m pip install --quiet --upgrade pip
"$VENV_DIR/bin/python" -m pip install --quiet -r "$SITE_DIR/requirements.txt"

echo "[1/3] Extrayendo funnel de 23 preguntas con Scrapling..."
"$VENV_DIR/bin/python" "$SCRIPT_DIR/extract_slowdive_quiz.py" \
  --output "$DOCS/QUIZ_DATA_ES.json" \
  --raw "$DOCS/SLOWDIVE_ES_RAW.js"

echo "[2/3] Construyendo sitio estatico ES-ES..."
"$VENV_DIR/bin/python" "$SCRIPT_DIR/build_static_site.py" \
  --public-dir "$PUBLIC" \
  --quiz-data "$DOCS/QUIZ_DATA_ES.json" \
  --domain "$DOMAIN" \
  --ga4 "$GA4" \
  --adsense-pub "$ADSENSE_PUB"

echo "[3/3] Aplicando snippets de cluster..."
adsense_apply_head_snippet_to_file "$PUBLIC/index.html"

echo "OK: generado ${SITE_KEY} en $PUBLIC"
