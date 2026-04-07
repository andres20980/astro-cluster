#!/usr/bin/env bash
set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────
GA4_PROPERTY="properties/531527723"
GA4_STREAM="properties/531527723/dataStreams/14325968472"
ADSENSE_ACCOUNT="accounts/pub-9368517395014039"
DOMAIN="carta-astral-gratis.es"

_token() { gcloud auth application-default print-access-token; }
_api()   { curl -s -H "Authorization: Bearer $(_token)" "$@"; }

# ── Commands ─────────────────────────────────────────────────────────

cmd_status() {
  echo "━━━ GA4 Property ━━━"
  _api "https://analyticsadmin.googleapis.com/v1beta/$GA4_PROPERTY" | python3 -m json.tool

  echo ""
  echo "━━━ GA4 Data Streams ━━━"
  _api "https://analyticsadmin.googleapis.com/v1beta/$GA4_PROPERTY/dataStreams" | python3 -m json.tool

  echo ""
  echo "━━━ AdSense Sites ━━━"
  _api "https://adsense.googleapis.com/v2/$ADSENSE_ACCOUNT/sites" | python3 -m json.tool

  echo ""
  echo "━━━ AdSense Ad Clients ━━━"
  _api "https://adsense.googleapis.com/v2/$ADSENSE_ACCOUNT/adclients" | python3 -m json.tool
}

cmd_ga4_realtime() {
  echo "━━━ GA4 Realtime (last 30 min) ━━━"
  _api -X POST \
    -H "Content-Type: application/json" \
    -d '{
      "dimensions": [{"name": "unifiedScreenName"}],
      "metrics": [{"name": "activeUsers"}],
      "limit": 20
    }' \
    "https://analyticsdata.googleapis.com/v1beta/$GA4_PROPERTY:runRealtimeReport" | python3 -m json.tool
}

cmd_ga4_report() {
  local days="${1:-7}"
  echo "━━━ GA4 Report (last ${days} days) ━━━"
  _api -X POST \
    -H "Content-Type: application/json" \
    -d "{
      \"dateRanges\": [{\"startDate\": \"${days}daysAgo\", \"endDate\": \"today\"}],
      \"dimensions\": [
        {\"name\": \"date\"},
        {\"name\": \"sessionDefaultChannelGroup\"}
      ],
      \"metrics\": [
        {\"name\": \"sessions\"},
        {\"name\": \"totalUsers\"},
        {\"name\": \"screenPageViews\"},
        {\"name\": \"averageSessionDuration\"}
      ],
      \"orderBys\": [{\"dimension\": {\"dimensionName\": \"date\"}, \"desc\": true}],
      \"limit\": 50
    }" \
    "https://analyticsdata.googleapis.com/v1beta/$GA4_PROPERTY:runReport" | python3 -m json.tool
}

cmd_ga4_top_pages() {
  local days="${1:-30}"
  echo "━━━ Top Pages (last ${days} days) ━━━"
  _api -X POST \
    -H "Content-Type: application/json" \
    -d "{
      \"dateRanges\": [{\"startDate\": \"${days}daysAgo\", \"endDate\": \"today\"}],
      \"dimensions\": [{\"name\": \"pagePath\"}],
      \"metrics\": [
        {\"name\": \"screenPageViews\"},
        {\"name\": \"totalUsers\"},
        {\"name\": \"averageSessionDuration\"}
      ],
      \"orderBys\": [{\"metric\": {\"metricName\": \"screenPageViews\"}, \"desc\": true}],
      \"limit\": 20
    }" \
    "https://analyticsdata.googleapis.com/v1beta/$GA4_PROPERTY:runReport" | python3 -m json.tool
}

cmd_ga4_key_events() {
  echo "━━━ GA4 Key Events ━━━"
  _api "https://analyticsadmin.googleapis.com/v1beta/$GA4_PROPERTY/keyEvents" | python3 -m json.tool
}

cmd_ga4_create_key_event() {
  local event_name="${1:?Usage: $0 ga4-create-key-event <event_name>}"
  echo "Creating key event: $event_name"
  _api -X POST \
    -H "Content-Type: application/json" \
    -d "{\"eventName\": \"$event_name\"}" \
    "https://analyticsadmin.googleapis.com/v1beta/$GA4_PROPERTY/keyEvents" | python3 -m json.tool
}

cmd_adsense_earnings() {
  local days="${1:-7}"
  local start end
  start=$(date -d "$days days ago" +%Y-%m-%d)
  end=$(date +%Y-%m-%d)
  echo "━━━ AdSense Earnings ($start → $end) ━━━"
  _api "https://adsense.googleapis.com/v2/$ADSENSE_ACCOUNT/reports:generate?\
dateRange=CUSTOM&\
startDate.year=$(date -d "$start" +%Y)&startDate.month=$(date -d "$start" +%-m)&startDate.day=$(date -d "$start" +%-d)&\
endDate.year=$(date -d "$end" +%Y)&endDate.month=$(date -d "$end" +%-m)&endDate.day=$(date -d "$end" +%-d)&\
metrics=ESTIMATED_EARNINGS&metrics=PAGE_VIEWS&metrics=IMPRESSIONS&metrics=CLICKS&\
dimensions=DATE&\
reportingTimeZone=ACCOUNT_TIME_ZONE" | python3 -m json.tool
}

cmd_adsense_sites() {
  echo "━━━ AdSense Sites ━━━"
  _api "https://adsense.googleapis.com/v2/$ADSENSE_ACCOUNT/sites" | python3 -m json.tool
}

cmd_adsense_alerts() {
  echo "━━━ AdSense Alerts ━━━"
  _api "https://adsense.googleapis.com/v2/$ADSENSE_ACCOUNT/alerts" | python3 -m json.tool
}

cmd_help() {
  cat <<EOF
Usage: $(basename "$0") <command> [args]

  status              Full status (GA4 + AdSense)
  ga4-realtime        Active users right now
  ga4-report [days]   Traffic report (default: 7 days)
  ga4-top-pages [d]   Top pages by views (default: 30 days)
  ga4-key-events      List key events (conversions)
  ga4-create-key-event <name>  Create a key event
  adsense-earnings [d] Earnings report (default: 7 days)
  adsense-sites       Site approval status
  adsense-alerts      Active alerts/warnings
  help                This message
EOF
}

# ── Dispatch ─────────────────────────────────────────────────────────
case "${1:-help}" in
  status)               cmd_status ;;
  ga4-realtime)         cmd_ga4_realtime ;;
  ga4-report)           cmd_ga4_report "${2:-7}" ;;
  ga4-top-pages)        cmd_ga4_top_pages "${2:-30}" ;;
  ga4-key-events)       cmd_ga4_key_events ;;
  ga4-create-key-event) cmd_ga4_create_key_event "${2:-}" ;;
  adsense-earnings)     cmd_adsense_earnings "${2:-7}" ;;
  adsense-sites)        cmd_adsense_sites ;;
  adsense-alerts)       cmd_adsense_alerts ;;
  help|*)               cmd_help ;;
esac
