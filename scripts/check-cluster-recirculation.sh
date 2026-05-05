#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/shared/config.sh"

fail=0

for site_key in "${CLUSTER_SITE_KEYS[@]}"; do
  public_dir="$ROOT_DIR/sites/$site_key/public"
  domain="${DOMAINS[$site_key]}"
  index="$public_dir/index.html"
  publicidad="$public_dir/publicidad.html"
  sitemap="$public_dir/sitemap.xml"
  ads="$public_dir/ads.txt"

  for file in "$index" "$publicidad" "$sitemap" "$ads"; do
    if [[ ! -f "$file" ]]; then
      echo "missing $file" >&2
      fail=1
    fi
  done

  if [[ -f "$index" ]]; then
    grep -q "cluster_recirculation_impression" "$index" || { echo "missing recirculation impression event in $index" >&2; fail=1; }
    grep -q "data-track-impression=\"cluster_recirculation\"" "$index" || { echo "missing recirculation impression marker in $index" >&2; fail=1; }
    grep -q "result_to_next_tool_click" "$index" || { echo "missing result click event in $index" >&2; fail=1; }
    grep -q "linker:{domains:" "$index" || { echo "missing cross-domain linker in $index" >&2; fail=1; }
    grep -q "cluster_session_id" "$index" || { echo "missing cluster session id in $index" >&2; fail=1; }
    grep -q "data-destination-site=" "$index" || { echo "missing destination site markers in $index" >&2; fail=1; }
  fi

  if [[ -f "$publicidad" ]]; then
    grep -qi "paquetes por intencion" "$publicidad" || { echo "missing cluster packages copy in $publicidad" >&2; fail=1; }
    grep -q "$domain" "$publicidad" || { echo "missing domain copy in $publicidad" >&2; fail=1; }
  fi

  if [[ -f "$ads" ]]; then
    grep -q "pub-9368517395014039" "$ads" || { echo "bad ads.txt for $site_key" >&2; fail=1; }
  fi
done

grep -q '"parameterName": "journey_stage"' "$ROOT_DIR/shared/ga4_custom_dimensions.json" || { echo "missing journey_stage custom dimension" >&2; fail=1; }
grep -q '"eventName": "result_to_next_tool_click"' "$ROOT_DIR/shared/ga4_key_events.json" || { echo "missing result_to_next_tool_click key event" >&2; fail=1; }

exit "$fail"
