#!/usr/bin/env bash
# Shared configuration for all esoteric cluster sites
# Source this file from any site generator script

# — AdSense (same account for all sites)
ADSENSE_PUB="ca-pub-9368517395014039"

# — GA4 Measurement IDs (one per site — create in GA4 console)
declare -A GA4_IDS=(
  [carta-astral]="G-DEWMQ73FH5"
  [compatibilidad-signos]="G-XXXXXXXXXX"
  [tarot-del-dia]="G-XXXXXXXXXX"
  [calcular-numerologia]="G-XXXXXXXXXX"
  [horoscopo-de-hoy]="G-XXXXXXXXXX"
)

# — Domains
declare -A DOMAINS=(
  [carta-astral]="carta-astral-gratis.es"
  [compatibilidad-signos]="compatibilidad-signos.es"
  [tarot-del-dia]="tarot-del-dia.es"
  [calcular-numerologia]="calcular-numerologia.es"
  [horoscopo-de-hoy]="horoscopo-de-hoy.es"
)

# — Shared brand
BRAND_FONTS="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700&family=Inter:wght@300;400;500;600&display=swap"
CONTACT_EMAIL="contacto@carta-astral-gratis.es"

# — CSS Variables (same palette across all sites)
CSS_VARS=':root{--bg:#faf8f5;--surface:#fff;--border:#e8e0d8;--text:#2d2a26;--muted:#7a7268;--accent:#7c3aed;--accent2:#c084fc;--gold:#d4a017;--gradient:linear-gradient(135deg,#7c3aed 0%,#c084fc 50%,#d4a017 100%);--shadow:0 2px 12px rgba(124,58,237,.08)}'

# — Cross-link network (all sites link to each other)
declare -A CROSSLINKS=(
  [carta-astral]="Carta Astral Gratis"
  [compatibilidad-signos]="Compatibilidad de Signos"
  [tarot-del-dia]="Tarot del Día"
  [calcular-numerologia]="Calcular Numerología"
  [horoscopo-de-hoy]="Horóscopo de Hoy"
)

# Helper: generate cross-link footer HTML for a given site key
crosslink_footer() {
  local current="$1"
  local html='<div class="network">Nuestras herramientas: '
  local first=true
  for key in carta-astral compatibilidad-signos tarot-del-dia calcular-numerologia horoscopo-de-hoy; do
    [[ "$key" == "$current" ]] && continue
    local domain="${DOMAINS[$key]}"
    local name="${CROSSLINKS[$key]}"
    $first || html+=" · "
    html+="<a href=\"https://${domain}/\" rel=\"noopener\">${name}</a>"
    first=false
  done
  html+='</div>'
  echo "$html"
}
