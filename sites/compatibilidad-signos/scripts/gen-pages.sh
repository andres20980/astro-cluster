#!/usr/bin/env bash
set -euo pipefail
# Generate canonical compatibility pages + redirects + index + sitemap for compatibilidad-signos.es

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBLIC="$SITE_DIR/public"
REPO_ROOT="$(cd "$SITE_DIR/../.." && pwd)"

source "$REPO_ROOT/shared/config.sh"

SITE_KEY="compatibilidad-signos"
DOMAIN="${DOMAINS[$SITE_KEY]}"
GA4="${GA4_IDS[$SITE_KEY]}"
TODAY=$(date +%Y-%m-%d)
AD_CSS="$(ad_css)"
CLUSTER_CSS="$(cluster_css)"

mkdir -p "$PUBLIC"

# ── Sign data ────────────────────────────────────────────────
SLUGS=(aries tauro geminis cancer leo virgo libra escorpio sagitario capricornio acuario piscis)
declare -A NAME=([aries]="Aries" [tauro]="Tauro" [geminis]="Géminis" [cancer]="Cáncer" [leo]="Leo" [virgo]="Virgo" [libra]="Libra" [escorpio]="Escorpio" [sagitario]="Sagitario" [capricornio]="Capricornio" [acuario]="Acuario" [piscis]="Piscis")
declare -A GLYPH=([aries]="♈" [tauro]="♉" [geminis]="♊" [cancer]="♋" [leo]="♌" [virgo]="♍" [libra]="♎" [escorpio]="♏" [sagitario]="♐" [capricornio]="♑" [acuario]="♒" [piscis]="♓")
declare -A ELEMENT=([aries]="Fuego" [tauro]="Tierra" [geminis]="Aire" [cancer]="Agua" [leo]="Fuego" [virgo]="Tierra" [libra]="Aire" [escorpio]="Agua" [sagitario]="Fuego" [capricornio]="Tierra" [acuario]="Aire" [piscis]="Agua")
declare -A RULER=([aries]="Marte" [tauro]="Venus" [geminis]="Mercurio" [cancer]="Luna" [leo]="Sol" [virgo]="Mercurio" [libra]="Venus" [escorpio]="Plutón" [sagitario]="Júpiter" [capricornio]="Saturno" [acuario]="Urano" [piscis]="Neptuno")
declare -A MODALITY=([aries]="Cardinal" [tauro]="Fijo" [geminis]="Mutable" [cancer]="Cardinal" [leo]="Fijo" [virgo]="Mutable" [libra]="Cardinal" [escorpio]="Fijo" [sagitario]="Mutable" [capricornio]="Cardinal" [acuario]="Fijo" [piscis]="Mutable")
declare -A SIGN_ORDER=([aries]=0 [tauro]=1 [geminis]=2 [cancer]=3 [leo]=4 [virgo]=5 [libra]=6 [escorpio]=7 [sagitario]=8 [capricornio]=9 [acuario]=10 [piscis]=11)
declare -A REL_STYLE=([aries]="iniciativa directa y deseo de moverse sin demasiada espera" [tauro]="constancia, presencia física y necesidad de confianza demostrable" [geminis]="curiosidad, conversación y cambios de estímulo frecuentes" [cancer]="cuidado emocional, memoria afectiva y búsqueda de refugio" [leo]="calidez, orgullo sano y necesidad de sentirse elegido" [virgo]="atención al detalle, actos concretos de ayuda y mejora gradual" [libra]="búsqueda de equilibrio, belleza compartida y acuerdos justos" [escorpio]="intensidad, lealtad y lectura profunda de lo no dicho" [sagitario]="apertura, humor y deseo de crecer sin sentirse encerrado" [capricornio]="compromiso sobrio, objetivos claros y paciencia para construir" [acuario]="independencia, amistad mental y respeto por lo diferente" [piscis]="empatía, imaginación y sensibilidad ante el clima emocional")
declare -A REL_NEED=([aries]="espacio para actuar y hablar claro" [tauro]="seguridad, ritmo estable y gestos consistentes" [geminis]="variedad, escucha ágil y libertad mental" [cancer]="ternura, continuidad y señales de pertenencia" [leo]="reconocimiento, juego y generosidad afectiva" [virgo]="orden, sinceridad práctica y pequeñas pruebas de cuidado" [libra]="diálogo, reciprocidad y decisiones compartidas" [escorpio]="profundidad, honestidad radical y límites claros" [sagitario]="confianza, aventura y margen para explorar" [capricornio]="responsabilidad, proyecto y coherencia en el tiempo" [acuario]="autonomía, amistad y conversación sin posesividad" [piscis]="comprensión emocional, delicadeza y espacios de inspiración")
declare -A REL_SHADOW=([aries]="precipitar decisiones antes de escuchar el matiz del otro" [tauro]="resistirse al cambio cuando la relación pide flexibilidad" [geminis]="quedarse en la palabra y evitar conversaciones vulnerables" [cancer]="leer distancia donde quizá solo hay cansancio o necesidad de espacio" [leo]="tomar una crítica práctica como falta de amor" [virgo]="convertir el cuidado en corrección constante" [libra]="aplazar conflictos por mantener una paz aparente" [escorpio]="probar la lealtad del otro en vez de pedir seguridad" [sagitario]="confundir libertad con falta de responsabilidad afectiva" [capricornio]="priorizar el deber hasta enfriar la expresión emocional" [acuario]="intelectualizar emociones que necesitan presencia" [piscis]="ceder demasiado y perder claridad sobre sus propios límites")
declare -A REL_REPAIR=([aries]="bajar la velocidad y transformar la reacción en una petición concreta" [tauro]="nombrar el miedo al cambio sin convertirlo en inmovilidad" [geminis]="resumir lo entendido antes de responder o bromear" [cancer]="pedir cuidado explícito en lugar de esperar que el otro adivine" [leo]="separar orgullo de necesidad afectiva y pedir reconocimiento" [virgo]="ofrecer una mejora posible sin convertirla en lista de fallos" [libra]="elegir una postura clara aunque incomode durante unos minutos" [escorpio]="decir qué necesita para confiar sin recurrir al silencio estratégico" [sagitario]="acordar compromisos concretos que no apaguen su espontaneidad" [capricornio]="reservar tiempo emocional, no solo resolver tareas" [acuario]="volver al cuerpo y a la presencia antes de analizar la situación" [piscis]="poner límites suaves pero visibles antes de saturarse")

# ── Compatibility scoring ────────────────────────────────────
element_base() {
  local e1="$1" e2="$2"
  [[ "$e1" == "$e2" ]] && echo 82 && return
  case "${e1}-${e2}" in
    Fuego-Aire|Aire-Fuego) echo 78;;
    Tierra-Agua|Agua-Tierra) echo 76;;
    Fuego-Tierra|Tierra-Fuego) echo 45;;
    Fuego-Agua|Agua-Fuego) echo 40;;
    Aire-Tierra|Tierra-Aire) echo 48;;
    Aire-Agua|Agua-Aire) echo 55;;
    *) echo 50;;
  esac
}

modality_mod() {
  local m1="$1" m2="$2"
  [[ "$m1" == "$m2" ]] && echo -3 && return
  case "${m1}-${m2}" in
    Cardinal-Mutable|Mutable-Cardinal) echo 5;;
    Fijo-Mutable|Mutable-Fijo) echo 4;;
    Cardinal-Fijo|Fijo-Cardinal) echo -1;;
    *) echo 0;;
  esac
}

# Deterministic per-pair modifier from slug hash
pair_mod() {
  local hash
  hash=$(echo -n "${1}-${2}" | cksum | cut -d' ' -f1)
  echo $(( (hash % 13) - 6 ))  # range -6..+6
}

calc_score() {
  local s1="$1" s2="$2"
  local base mod_m mod_p score
  base=$(element_base "${ELEMENT[$s1]}" "${ELEMENT[$s2]}")
  mod_m=$(modality_mod "${MODALITY[$s1]}" "${MODALITY[$s2]}")
  mod_p=$(pair_mod "$s1" "$s2")
  score=$(( base + mod_m + mod_p ))
  (( score > 98 )) && score=98
  (( score < 25 )) && score=25
  echo "$score"
}

score_label() {
  local s=$1
  if (( s >= 80 )); then echo "Muy Alta"
  elif (( s >= 65 )); then echo "Alta"
  elif (( s >= 50 )); then echo "Media"
  elif (( s >= 35 )); then echo "Baja"
  else echo "Muy Baja"
  fi
}

score_emoji() {
  local s=$1
  if (( s >= 80 )); then echo "🔥"
  elif (( s >= 65 )); then echo "✨"
  elif (( s >= 50 )); then echo "⚖️"
  elif (( s >= 35 )); then echo "🌧️"
  else echo "❄️"
  fi
}

element_gift() {
  case "$1" in
    Fuego) echo "pasión, iniciativa y entusiasmo para abrir caminos";;
    Tierra) echo "estabilidad, constancia y sentido práctico para sostener lo importante";;
    Aire) echo "comunicación, ideas y perspectiva para mover la relación";;
    Agua) echo "intuición, empatía y profundidad emocional para crear intimidad";;
  esac
}

element_support() {
  case "$1" in
    Fuego) echo "motivación, coraje y vitalidad";;
    Tierra) echo "estructura, paciencia y fiabilidad";;
    Aire) echo "flexibilidad, sociabilidad y creatividad";;
    Agua) echo "sensibilidad, cuidado y conexión emocional";;
  esac
}

element_need() {
  case "$1" in
    Fuego) echo "acción, honestidad rápida y libertad";;
    Tierra) echo "seguridad, previsibilidad y hechos concretos";;
    Aire) echo "espacio mental, variedad y conversación";;
    Agua) echo "conexión emocional profunda y cuidado";;
  esac
}

element_priority() {
  case "$1" in
    Fuego) echo "la independencia y la aventura";;
    Tierra) echo "la estabilidad y lo tangible";;
    Aire) echo "la comunicación y lo social";;
    Agua) echo "la intimidad y lo intuitivo";;
  esac
}

element_challenge() {
  local e1="$1" e2="$2"
  if [[ "$e1" == "$e2" ]]; then
    echo "Al compartir ${e1}, la pareja se entiende rápido, pero también puede amplificar los excesos del mismo elemento."
  else
    echo "La diferencia ${e1}-${e2} pide traducir necesidades: no asumir que el otro procesa deseo, seguridad o conflicto igual."
  fi
}

modality_dynamic() {
  local m1="$1" m2="$2"
  if [[ "$m1" == "$m2" ]]; then
    echo "genera un ritmo reconocible para ambos, aunque conviene vigilar la competencia por dirigir, resistir o cambiar al mismo tiempo."
  else
    echo "aporta ritmos distintos: uno puede iniciar, sostener o adaptar mientras el otro ofrece una respuesta complementaria."
  fi
}

communication_text() {
  local score="$1" r1="$2" r2="$3"
  if (( score >= 65 )); then
    echo "La comunicación entre ${r1} y ${r2} tiende a resolver roces con diálogo cuando ambos nombran necesidades concretas."
  elif (( score >= 50 )); then
    echo "La comunicación entre ${r1} y ${r2} puede alternar fluidez y malentendidos; ayuda pactar tiempos para hablar sin interrumpirse."
  else
    echo "La comunicación entre ${r1} y ${r2} requiere paciencia: conviene repetir lo entendido antes de responder desde la defensiva."
  fi
}

score_guidance() {
  local score="$1" n1="$2" n2="$3"
  if (( score >= 80 )); then
    echo "Con una afinidad tan alta, ${n1} y ${n2} deben evitar dormirse en la facilidad inicial: la relación gana calidad cuando convierte la química en hábitos, acuerdos y reparación después del desacuerdo."
  elif (( score >= 65 )); then
    echo "Esta compatibilidad alta favorece confianza y atracción, pero funciona mejor si ${n1} y ${n2} reservan espacios para negociar expectativas antes de que los pequeños roces se acumulen."
  elif (( score >= 50 )); then
    echo "La afinidad media indica potencial con trabajo consciente. ${n1} y ${n2} pueden complementarse si diferencian carácter, ritmo y necesidad emocional en vez de leer cada diferencia como rechazo."
  else
    echo "Esta combinación pide madurez, acuerdos claros y voluntad de aprendizaje. ${n1} y ${n2} no tienen por qué descartarse, pero necesitan más estructura para que la relación no dependa solo de la atracción."
  fi
}

canonical_pair_slug() {
  local a="$1" b="$2"
  if (( ${SIGN_ORDER[$a]} <= ${SIGN_ORDER[$b]} )); then
    echo "${a}-${b}"
  else
    echo "${b}-${a}"
  fi
}

pair_path() {
  canonical_pair_slug "$1" "$2"
}

# ── Element pair descriptions ────────────────────────────────
element_desc() {
  local e1="$1" e2="$2"
  [[ "$e1" == "$e2" ]] && { echo "Al compartir el elemento ${e1}, existe una comprensión instintiva entre ambos. Se entienden sin palabras y comparten una misma forma de procesar la vida. El riesgo es caer en una zona de confort o potenciar los excesos del elemento."; return; }
  case "${e1}-${e2}" in
    Fuego-Aire|Aire-Fuego) echo "El Aire alimenta al Fuego, creando una conexión vibrante y estimulante. La comunicación es fluida, las ideas se encienden mutuamente y la pasión se aviva con cada conversación. Una de las combinaciones más dinámicas del zodíaco.";;
    Tierra-Agua|Agua-Tierra) echo "La Tierra contiene al Agua y el Agua nutre la Tierra. Es una combinación naturalmente fértil: estabilidad emocional, cuidado mutuo y construcción paciente de algo duradero. Ambos valoran la seguridad.";;
    Fuego-Tierra|Tierra-Fuego) echo "El Fuego quiere moverse rápido; la Tierra necesita tiempo. Esta diferencia de ritmo genera fricción, pero también complementariedad: el Fuego motiva a la Tierra y la Tierra da estructura al Fuego.";;
    Fuego-Agua|Agua-Fuego) echo "El Fuego evapora al Agua, el Agua apaga al Fuego. Esta combinación requiere esfuerzo consciente: las emociones profundas del Agua pueden sofocar al Fuego, y la intensidad del Fuego puede abrumar al Agua.";;
    Aire-Tierra|Tierra-Aire) echo "El Aire vuela libre mientras la Tierra busca raíces. Son mundos diferentes que pueden complementarse si el Aire aporta ideas frescas y la Tierra las materializa. El reto es encontrar terreno común.";;
    Aire-Agua|Agua-Aire) echo "El Aire racionaliza lo que el Agua siente. Pueden aprender mucho el uno del otro: el Aire ayuda al Agua a ganar perspectiva y el Agua enseña al Aire la profundidad emocional. Requiere paciencia mutua.";;
    *) echo "Una combinación con matices interesantes que depende de otros factores de la carta natal para desarrollar su máximo potencial.";;
  esac
}

# ── Generate common <head> ───────────────────────────────────
gen_head() {
  local title="$1" desc="$2" canonical="$3" page_type="${4:-page}" content_group="${5:-content}" entity_slug="${6:-}" robots="${7:-index, follow}"
  cat <<ENDHEAD
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <meta name="description" content="${desc}">
  <link rel="canonical" href="https://${DOMAIN}${canonical}">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${desc}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://${DOMAIN}${canonical}">
  <meta property="og:locale" content="es_ES">
  <meta name="robots" content="${robots}">
  <link rel="preconnect" href="https://fonts.googleapis.com" crossorigin>
  <link href="${BRAND_FONTS}" rel="stylesheet" media="print" onload="this.media='all'">
  <noscript><link href="${BRAND_FONTS}" rel="stylesheet"></noscript>
$(canonical_host_redirect_script "$DOMAIN")
$(ga4_head_snippet "$GA4" "$SITE_KEY" "$page_type" "$content_group" "$entity_slug")
$(adsense_head_snippet)
ENDHEAD
}

# ── Common CSS ───────────────────────────────────────────────
COMMON_CSS="
    ${CSS_VARS}
    *{margin:0;padding:0;box-sizing:border-box}
    body{font-family:'Inter',system-ui,sans-serif;background:var(--bg);color:var(--text);min-height:100vh}
    .container{max-width:820px;margin:0 auto;padding:1.5rem}
    .breadcrumb{font-size:.8rem;color:var(--muted);margin-bottom:1.5rem}
    .breadcrumb a{color:var(--accent);text-decoration:none}
    h1{font-family:'Playfair Display',serif;font-size:1.9rem;text-align:center;margin:.5rem 0 .3rem}
    h1 span{background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
    h2{font-family:'Playfair Display',serif;font-size:1.15rem;color:var(--text);margin-bottom:.7rem}
    .panel{background:var(--surface);border:1px solid var(--border);border-radius:16px;padding:1.6rem;box-shadow:var(--shadow);margin-bottom:1.2rem}
    .panel p,.panel li{line-height:1.7;color:var(--muted);font-size:.9rem}
    .panel ul{padding-left:1.2rem;margin:.5rem 0}
    .score-hero{text-align:center;padding:1.5rem 0 1rem}
    .score-hero .glyphs{font-size:2.8rem;letter-spacing:.5rem}
    .score-hero .pct{font-family:'Playfair Display',serif;font-size:3rem;font-weight:700;color:var(--accent);margin:.3rem 0}
    .score-hero .label{font-size:.9rem;color:var(--muted)}
    .meter{height:12px;background:var(--border);border-radius:6px;overflow:hidden;margin:.8rem 0}
    .meter .fill{height:100%;border-radius:6px;background:var(--gradient);transition:width .6s}
    .meta-row{display:flex;gap:.6rem;justify-content:center;flex-wrap:wrap;margin:.8rem 0}
    .tag{padding:.3rem .8rem;border-radius:20px;font-size:.75rem;font-weight:500;background:var(--surface);border:1px solid var(--border)}
    .cta-box{text-align:center;padding:1.8rem;background:linear-gradient(135deg,#f3eeff 0%,#fef9ee 100%);border-radius:16px;margin:1.5rem 0}
    .cta-box h3{font-family:'Playfair Display',serif;font-size:1.05rem;margin-bottom:.4rem}
    .cta-box p{color:var(--muted);font-size:.88rem;margin-bottom:.8rem}
    .cta-box a{display:inline-block;padding:.6rem 1.4rem;background:var(--accent);color:#fff;font-weight:600;border-radius:10px;text-decoration:none;font-size:.88rem;box-shadow:0 4px 14px rgba(124,58,237,.3);transition:all .2s}
    .cta-box a:hover{background:#6d28d9;transform:translateY(-1px)}
    .network{text-align:center;font-size:.75rem;color:var(--muted);margin-top:1rem}
    .network a{color:var(--accent);text-decoration:none}
    footer{text-align:center;padding:2rem 1rem;font-size:.75rem;color:var(--muted);border-top:1px solid var(--border);margin-top:2rem}
    footer a{color:var(--accent);text-decoration:none}
${AD_CSS}
${CLUSTER_CSS}
"

# ── Cross-links ──────────────────────────────────────────────
CROSSLINKS_HTML=$(crosslink_footer "$SITE_KEY")

# ── Generate footer ──────────────────────────────────────────
gen_footer() {
  cat <<ENDFOOTER
<footer>
  <p>© $(date +%Y) Compatibilidad Signos — Herramienta gratuita de astrología</p>
  <p><a href="/metodologia">Metodología</a> · <a href="/sobre-nosotros">Sobre nosotros</a> · <a href="/privacy">Privacidad</a> · <a href="/terms">Términos</a></p>
  $(footer_publicidad_line "$SITE_KEY")
  ${CROSSLINKS_HTML}
</footer>
ENDFOOTER
}

# ══════════════════════════════════════════════════════════════
# GENERATE PAIR PAGES
# ══════════════════════════════════════════════════════════════
echo "Generating canonical compatibility pages..."
mkdir -p "$PUBLIC"

SITEMAP_URLS=""
PAGE_COUNT=0
REDIRECT_COUNT=0
PAIR_TITLE_TEMPLATE="Compatibilidad {{name1}} y {{name2}} {{glyphs}} — {{score}}% {{label}}"
PAIR_DESC_TEMPLATE="¿Son compatibles {{name1}} y {{name2}}? Descubre su afinidad amorosa ({{score}}%), fortalezas, retos y cómo se complementan según sus elementos y planetas regentes."

for s1 in "${SLUGS[@]}"; do
  for s2 in "${SLUGS[@]}"; do
    n1="${NAME[$s1]}" n2="${NAME[$s2]}"
    g1="${GLYPH[$s1]}" g2="${GLYPH[$s2]}"
    e1="${ELEMENT[$s1]}" e2="${ELEMENT[$s2]}"
    r1="${RULER[$s1]}" r2="${RULER[$s2]}"

    score=$(calc_score "$s1" "$s2")
    label=$(score_label "$score")
    emoji=$(score_emoji "$score")
    elem_text=$(element_desc "$e1" "$e2")

    slug_page="${s1}-${s2}"
    canonical_slug="$(canonical_pair_slug "$s1" "$s2")"
    file="$PUBLIC/${slug_page}.html"
    url_path="/${slug_page}"
    canonical_path="/${canonical_slug}"
    robots_meta="index, follow"
    if [[ "$slug_page" != "$canonical_slug" ]]; then
      rm -f "$file"
      REDIRECT_COUNT=$((REDIRECT_COUNT + 1))
      continue
    fi

    gift1="$(element_gift "$e1")"
    support2="$(element_support "$e2")"
    modality_text="$(modality_dynamic "${MODALITY[$s1]}" "${MODALITY[$s2]}")"
    challenge_text="$(element_challenge "$e1" "$e2")"
    need1="$(element_need "$e1")"
    priority2="$(element_priority "$e2")"
    comm_text="$(communication_text "$score" "$r1" "$r2")"
    score_text="$(score_guidance "$score" "$n1" "$n2")"

    title="${PAIR_TITLE_TEMPLATE//\{\{name1\}\}/$n1}"
    title="${title//\{\{name2\}\}/$n2}"
    title="${title//\{\{glyphs\}\}/$g1$g2}"
    title="${title//\{\{score\}\}/$score}"
    title="${title//\{\{label\}\}/$label}"

    desc="${PAIR_DESC_TEMPLATE//\{\{name1\}\}/$n1}"
    desc="${desc//\{\{name2\}\}/$n2}"
    desc="${desc//\{\{score\}\}/$score}"

    cat > "$file" <<ENDHTML
<!DOCTYPE html>
<html lang="es">
<head>
$(gen_head "$title" "$desc" "$canonical_path" "compatibility_landing" "long_tail" "$canonical_slug" "$robots_meta")
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"Article","headline":"Compatibilidad ${n1} y ${n2}","description":"${desc}","author":{"@type":"Organization","name":"Compatibilidad Signos"},"publisher":{"@type":"Organization","name":"Compatibilidad Signos","url":"https://${DOMAIN}/"},"mainEntityOfPage":"https://${DOMAIN}${canonical_path}","inLanguage":"es"}
  </script>
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Inicio","item":"https://${DOMAIN}/"},{"@type":"ListItem","position":2,"name":"${n1} y ${n2}","item":"https://${DOMAIN}${url_path}"}]}
  </script>
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":"¿Son compatibles ${n1} y ${n2}?","acceptedAnswer":{"@type":"Answer","text":"La compatibilidad entre ${n1} y ${n2} es del ${score}% (${label}). ${n1} es ${e1} regido por ${r1}, mientras que ${n2} es ${e2} regido por ${r2}."}},{"@type":"Question","name":"¿Qué elemento comparten ${n1} y ${n2}?","acceptedAnswer":{"@type":"Answer","text":"${n1} pertenece al elemento ${e1} y ${n2} al elemento ${e2}."}}]}
  </script>
  <style>${COMMON_CSS}</style>
</head>
<body>
<div class="container">
  <nav class="breadcrumb"><a href="/">Compatibilidad Signos</a> › ${n1} y ${n2}</nav>

  <div class="score-hero">
    <div class="glyphs">${g1} ${g2}</div>
    <h1><span>Compatibilidad ${n1} y ${n2}</span></h1>
    <div class="pct">${emoji} ${score}%</div>
    <div class="label">Afinidad ${label}</div>
    <div class="meter"><div class="fill" style="width:${score}%"></div></div>
  </div>

  <div class="meta-row">
    <span class="tag">${g1} ${n1} · ${e1} · ${r1}</span>
    <span class="tag">${g2} ${n2} · ${e2} · ${r2}</span>
  </div>

$(ad_block "❤" "¿Tienes una aplicación de citas, consulta o regalo romántico?" "Aparece ante usuarios que ya están leyendo una combinación concreta y tienen intención alta de relación." "Ver espacios y tarifas →")

  <div class="panel">
    <h2>${g1}${g2} Análisis de Compatibilidad</h2>
    <p>${elem_text}</p>
    <p>Con ${r1} (regente de ${n1}) y ${r2} (regente de ${n2}) en juego, la dinámica planetaria añade matices importantes. ${r1} aporta la energía de ${n1} en la relación, mientras ${r2} trae la esencia de ${n2}.</p>
  </div>

  <div class="panel">
    <h2>💪 Fortalezas de la pareja ${n1}–${n2}</h2>
    <ul>
      <li>${n1} aporta la energía de ${e1}: ${gift1}.</li>
      <li>${n2} complementa con ${e2}: ${support2}.</li>
      <li>La combinación ${MODALITY[$s1]}–${MODALITY[$s2]} ${modality_text}</li>
    </ul>
  </div>

  <div class="panel">
    <h2>⚠️ Retos a trabajar</h2>
    <ul>
      <li>${challenge_text}</li>
      <li>${n1} suele necesitar ${need1}, mientras ${n2} prioriza ${priority2}.</li>
      <li>${comm_text}</li>
    </ul>
  </div>

  <div class="panel">
    <h2>Lectura práctica de ${n1} y ${n2}</h2>
    <p>${n1} suele vincularse desde ${REL_STYLE[$s1]}; ${n2}, desde ${REL_STYLE[$s2]}. Esta mezcla se vuelve más valiosa cuando ambos distinguen atracción, convivencia y forma de reparar después de una tensión.</p>
    <p>Para que la relación avance, ${n1} necesita ${REL_NEED[$s1]}, mientras ${n2} necesita ${REL_NEED[$s2]}. El punto débil aparece cuando ${n1} tiende a ${REL_SHADOW[$s1]} o cuando ${n2} cae en ${REL_SHADOW[$s2]}.</p>
    <p>${score_text}</p>
  </div>

  <div class="panel">
    <h2>Cómo llevar esta compatibilidad al día a día</h2>
    <p>El porcentaje no debe leerse como sentencia, sino como una brújula para entender dónde la relación fluye y dónde pide trabajo consciente. En una pareja ${n1}–${n2}, conviene observar quién toma la iniciativa, cómo se gestionan los silencios y qué necesita cada persona para sentirse segura antes de discutir un problema importante.</p>
    <p>Si la afinidad es alta, el reto suele ser no dar por hecho que todo se resolverá solo. Si la afinidad es media o baja, la relación puede funcionar cuando ambos pactan ritmos, límites y expectativas concretas. En ambos casos, el signo solar es solo una capa: Luna, Venus, Marte y Ascendente pueden cambiar mucho la lectura final.</p>
    <p>Una práctica útil es revisar la relación en tres escenas concretas: cómo decidís planes, cómo pedís espacio y cómo reparáis una discusión. Si esas tres situaciones tienen acuerdos claros, la compatibilidad se vuelve más estable que cualquier porcentaje aislado.</p>
  </div>

  <div class="panel">
    <h2>Preguntas útiles para ${n1} y ${n2}</h2>
    <ul>
      <li>¿${n1} se siente escuchado cuando expresa su energía ${e1}, o percibe que debe adaptarse demasiado?</li>
      <li>¿${n2} puede vivir su naturaleza ${e2} sin que la relación pierda equilibrio?</li>
      <li>¿La modalidad ${MODALITY[$s1]} de ${n1} y la modalidad ${MODALITY[$s2]} de ${n2} ayudan a tomar decisiones o generan bloqueo?</li>
    </ul>
  </div>

  <div class="panel">
    <h2>🌙 En la Carta Natal</h2>
    <p>La compatibilidad real va más allá del signo solar. Si tienes Luna, Venus o Marte en ${n2}, tu conexión con personas ${n2} será más intensa. Calcula tu carta astral completa para descubrir todas tus compatibilidades planetarias.</p>
  </div>

$(ad_block "✦" "Patrocina una de las combinaciones más buscadas" "Ideal para marcas de pareja, acompañamiento, joyería y bienestar emocional con mensaje contextual." "Reservar un banner destacado →")

  <div class="cta-box">
    <h3>🔮 Descubre tu carta astral completa</h3>
    <p>Calcula tu mapa natal con hora y lugar exactos. Descubre tu Luna, Venus, Marte y todos los aspectos que influyen en tus relaciones.</p>
    <a href="https://carta-astral-gratis.es/" rel="noopener">Calcular mi carta astral gratis →</a>
  </div>

  <div class="panel">
    <h2>Otras compatibilidades de ${n1}</h2>
    <p style="display:flex;flex-wrap:wrap;gap:.4rem">$(for s in "${SLUGS[@]}"; do [[ "$s" == "$s2" ]] && continue; printf '<a href="/%s" style="padding:.25rem .6rem;background:var(--bg);border:1px solid var(--border);border-radius:8px;text-decoration:none;color:var(--accent);font-size:.8rem">%s %s</a>' "$(pair_path "$s1" "$s")" "${GLYPH[$s]}" "${NAME[$s]}"; done)</p>
  </div>

$(cluster_recirculation_block "$SITE_KEY")

$(gen_footer)
</div>
</body>
</html>
ENDHTML

    if [[ "$slug_page" == "$canonical_slug" ]]; then
      SITEMAP_URLS+="  <url><loc>https://${DOMAIN}${url_path}</loc><lastmod>${TODAY}</lastmod><changefreq>monthly</changefreq><priority>0.7</priority></url>\n"
    fi
    PAGE_COUNT=$((PAGE_COUNT + 1))
  done
done
echo "  ✓ ${PAGE_COUNT} pair pages generated"
echo "  ✓ ${REDIRECT_COUNT} reverse pair redirects prepared"

# ══════════════════════════════════════════════════════════════
# INDEX PAGE
# ══════════════════════════════════════════════════════════════
echo "Generating index..."

INDEX_TITLE="Tabla de Compatibilidad de Signos Gratis — 144 Combinaciones"
INDEX_DESC="Consulta la tabla de compatibilidad de signos gratis: 144 combinaciones zodiacales con porcentaje de afinidad, amor, fortalezas y retos."

# Build the 12x12 grid rows
GRID_ROWS=""
for s1 in "${SLUGS[@]}"; do
  GRID_ROWS+="<tr id=\"tabla-${s1}\"><th class=\"row-h\">${GLYPH[$s1]}<br><span>${NAME[$s1]}</span></th>"
  for s2 in "${SLUGS[@]}"; do
    sc=$(calc_score "$s1" "$s2")
    lbl=$(score_label "$sc")
    # Color class based on score
    if (( sc >= 75 )); then cls="high"
    elif (( sc >= 55 )); then cls="mid"
    else cls="low"
    fi
    GRID_ROWS+="<td class=\"cell ${cls}\"><a href=\"/$(pair_path "$s1" "$s2")\">${sc}%</a></td>"
  done
  GRID_ROWS+="</tr>"
done

GEMINIS_LINKS=""
ARIES_LINKS=""
for s in "${SLUGS[@]}"; do
  geminis_score=$(calc_score "geminis" "$s")
  aries_score=$(calc_score "aries" "$s")
  GEMINIS_LINKS+="<a href=\"/$(pair_path "geminis" "$s")\">Géminis con ${NAME[$s]} <strong>${geminis_score}%</strong></a>"
  ARIES_LINKS+="<a href=\"/$(pair_path "aries" "$s")\">Aries con ${NAME[$s]} <strong>${aries_score}%</strong></a>"
done

cat > "$PUBLIC/index.html" <<ENDINDEX
<!DOCTYPE html>
<html lang="es">
<head>
$(gen_head "$INDEX_TITLE" "$INDEX_DESC" "/" "tool_home" "tool")
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"WebSite","name":"Compatibilidad de Signos","url":"https://${DOMAIN}/","description":"${INDEX_DESC}","inLanguage":"es"}
  </script>
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":"¿Cómo se calcula la compatibilidad entre signos?","acceptedAnswer":{"@type":"Answer","text":"La compatibilidad se basa en el elemento (Fuego, Tierra, Aire, Agua), la modalidad (Cardinal, Fijo, Mutable) y los planetas regentes de cada signo. Se analizan las sinergias y tensiones naturales entre estos factores."}},{"@type":"Question","name":"¿Qué incluye la tabla de compatibilidad zodiacal completa?","acceptedAnswer":{"@type":"Answer","text":"La tabla completa cruza los 12 signos del zodíaco entre sí y enlaza a 144 combinaciones con porcentaje de afinidad, fortalezas, retos y lectura de pareja."}},{"@type":"Question","name":"¿Qué signos son más compatibles entre sí?","acceptedAnswer":{"@type":"Answer","text":"Los signos del mismo elemento suelen tener alta compatibilidad (Fuego con Fuego, Tierra con Tierra). También los elementos complementarios: Fuego con Aire, y Tierra con Agua."}}]}
  </script>
  <style>
${COMMON_CSS}
    .intro{text-align:center;color:var(--muted);font-size:.92rem;line-height:1.6;max-width:620px;margin:0 auto 1.5rem}
    .calc{background:var(--surface);border:1px solid var(--border);border-radius:16px;padding:1.5rem;box-shadow:var(--shadow);margin-bottom:2rem;text-align:center}
    .calc select{padding:.5rem 1rem;border:1px solid var(--border);border-radius:8px;font-size:.95rem;font-family:inherit;background:var(--bg);margin:.3rem}
    .calc .btn{margin-top:.8rem;padding:.6rem 2rem;background:var(--accent);color:#fff;border:none;border-radius:10px;font-weight:600;cursor:pointer;font-size:.9rem}
    .calc .btn:hover{background:#6d28d9}
    .grid-wrap{overflow-x:auto;margin:1.5rem 0}
    table{border-collapse:collapse;font-size:.72rem;width:100%;min-width:700px}
    th,td{padding:.35rem .2rem;text-align:center;border:1px solid var(--border)}
    thead th{background:#f3eeff;color:var(--accent);font-size:.65rem;writing-mode:vertical-lr;text-orientation:mixed;height:5rem;min-width:2.5rem}
    .row-h{background:#f3eeff;color:var(--accent);font-weight:600;white-space:nowrap;padding:.3rem .5rem}
    .row-h span{display:block;font-size:.6rem;font-weight:400}
    .cell a{text-decoration:none;display:block;padding:.2rem;border-radius:4px;font-weight:600;transition:all .15s}
    .cell a:hover{transform:scale(1.1)}
    .cell.high a{color:#16a34a;background:#f0fdf4}
    .cell.mid a{color:#9a7410;background:#fef9ee}
    .cell.low a{color:#dc2626;background:#fef2f2}
    .seo-text{margin:2rem 0}
    .seo-text h2{font-size:1.2rem;margin:1.5rem 0 .6rem}
    .seo-text p,.seo-text li{line-height:1.7;color:var(--muted);font-size:.9rem;margin-bottom:.5rem}
    .seo-text ul{padding-left:1.2rem}
    .quick-nav{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:.7rem;margin:1rem 0 1.4rem}
    .quick-nav a{display:block;text-decoration:none;color:var(--accent);background:var(--bg);border:1px solid var(--border);border-radius:8px;padding:.7rem .8rem;font-size:.86rem;font-weight:600}
    .spotlight{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:1rem;margin:1.2rem 0}
    .spotlight-card{background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:1rem}
    .spotlight-card h3{font-size:.95rem;margin-bottom:.6rem}
    .spotlight-links{display:grid;gap:.45rem}
    .spotlight-links a{display:flex;justify-content:space-between;gap:.8rem;text-decoration:none;color:var(--text);font-size:.84rem;border-bottom:1px solid var(--border);padding-bottom:.35rem}
    .spotlight-links strong{color:var(--accent)}
    .editorial-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:1rem;margin:1rem 0}
    .editorial-card{background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:1rem;box-shadow:var(--shadow)}
    .editorial-card h3{font-size:.98rem;margin-bottom:.45rem;color:var(--accent)}
    .editorial-card p{color:var(--muted);font-size:.88rem;line-height:1.7}
  </style>
</head>
<body>
<div class="container">
  <header style="text-align:center;padding:1.5rem 0 .5rem">
    <div style="font-size:.75rem;letter-spacing:.15em;text-transform:uppercase;color:var(--accent);font-weight:600">Astrología</div>
    <h1><span>Tabla de Compatibilidad de Signos</span></h1>
    <p class="intro">Calcula la compatibilidad de signos gratis y consulta la tabla zodiacal completa con 144 combinaciones: Aries, Tauro, Géminis, Cáncer y el resto del zodíaco con porcentaje de afinidad, fortalezas y retos de pareja.</p>
  </header>

  <div class="calc">
    <h2 style="margin-bottom:.6rem">Calculadora Rápida</h2>
    <div>
      <select id="s1">$(for s in "${SLUGS[@]}"; do echo "<option value=\"$s\">${GLYPH[$s]} ${NAME[$s]}</option>"; done)</select>
      <span style="font-size:1.2rem;color:var(--accent)">❤️</span>
      <select id="s2">$(for s in "${SLUGS[@]}"; do echo "<option value=\"$s\">${GLYPH[$s]} ${NAME[$s]}</option>"; done)</select>
    </div>
    <button class="btn" onclick="openCompatibilityFromHome()">Ver compatibilidad →</button>
  </div>

  <nav class="quick-nav" aria-label="Accesos rápidos a la tabla de compatibilidad">
    <a href="/tabla-compatibilidad-geminis">Tabla de compatibilidad de Géminis</a>
    <a href="/tabla-compatibilidad-aries">Tabla de compatibilidad de Aries</a>
    <a href="#tabla-completa">Tabla zodiacal completa</a>
    <a href="/metodologia">Cómo calculamos la afinidad</a>
    <a href="/sobre-nosotros">Criterio editorial</a>
  </nav>

$(ad_block "❤" "Publicidad destacada en un nicho de amor y afinidad" "La ubicación más visible para captar usuarios antes de que profundicen en la tabla completa." "Informarme →")

  <h2 id="tabla-completa" style="text-align:center">Tabla completa de compatibilidad de signos zodiacales</h2>
  <div class="grid-wrap">
  <table>
    <thead><tr><th></th>$(for s in "${SLUGS[@]}"; do echo "<th>${GLYPH[$s]}<br>${NAME[$s]}</th>"; done)</tr></thead>
    <tbody>
${GRID_ROWS}
    </tbody>
  </table>
  </div>

  <section class="spotlight" aria-label="Tablas de compatibilidad destacadas">
    <div class="spotlight-card">
      <h3>Tabla de compatibilidad de Géminis</h3>
      <div class="spotlight-links">${GEMINIS_LINKS}</div>
    </div>
    <div class="spotlight-card">
      <h3>Tabla de compatibilidad de Aries</h3>
      <div class="spotlight-links">${ARIES_LINKS}</div>
    </div>
  </section>

$(ad_block "🔮" "Patrocina tráfico orgánico de alta intención" "Tu marca puede aparecer entre la herramienta de cálculo y las 144 combinaciones de signos." "Ver espacios →")

  <div class="cta-box">
    <h3>🔮 ¿Quieres ir más allá del signo solar?</h3>
    <p>La verdadera compatibilidad depende de tu carta natal completa: Luna, Venus, Marte, ascendente y más.</p>
    <a href="https://carta-astral-gratis.es/">Calcular carta astral gratis →</a>
  </div>

  <div class="seo-text panel">
    <h2>¿Cómo funciona la compatibilidad entre signos?</h2>
    <p>La compatibilidad astrológica analiza la relación entre dos signos del zodíaco basándose en tres factores clave. La calculadora gratuita resume esos factores en un porcentaje de afinidad y la tabla completa permite comparar cualquier pareja de signos en un clic, incluyendo búsquedas concretas como la compatibilidad de Géminis, Aries o cualquier combinación zodiacal.</p>
    <ul>
      <li><strong>Elemento:</strong> Los 12 signos se dividen en Fuego (Aries, Leo, Sagitario), Tierra (Tauro, Virgo, Capricornio), Aire (Géminis, Libra, Acuario) y Agua (Cáncer, Escorpio, Piscis). Los elementos del mismo grupo se entienden naturalmente.</li>
      <li><strong>Modalidad:</strong> Cardinal (iniciadores), Fijo (estables) y Mutable (adaptables). La interacción entre modalidades afecta al ritmo de la relación.</li>
      <li><strong>Planeta regente:</strong> Cada signo está gobernado por un planeta que marca su esencia. La interacción entre regentes planetarios añade la capa más profunda al análisis.</li>
    </ul>

    <h2>¿Qué signos son más compatibles?</h2>
    <p>Las combinaciones con mayor afinidad natural son entre signos del mismo elemento o elementos complementarios:</p>
    <ul>
      <li><strong>Fuego + Aire:</strong> Pasión, dinamismo y aventura. Aries con Géminis, Leo con Libra, Sagitario con Acuario.</li>
      <li><strong>Tierra + Agua:</strong> Estabilidad, nutrición y profundidad. Tauro con Cáncer, Virgo con Escorpio, Capricornio con Piscis.</li>
      <li><strong>Mismo elemento:</strong> Comprensión intuitiva y valores compartidos.</li>
    </ul>

    <h2>¿La compatibilidad de signos determina una relación?</h2>
    <p>El signo solar es solo una parte de tu carta astral. La verdadera compatibilidad amorosa depende de la interacción entre las cartas natales completas de ambas personas: la posición de Venus (cómo amas), Marte (cómo deseas), la Luna (tus emociones) y el ascendente (cómo te perciben). Nuestra herramienta gratuita de <a href="https://carta-astral-gratis.es/">carta astral</a> te permite calcular todos estos factores.</p>
  </div>

  <section class="panel">
    <h2>Cómo leer la tabla sin quedarse solo con el porcentaje</h2>
    <p>El porcentaje ayuda a ordenar una primera comparación, pero la lectura útil empieza cuando separas atracción, convivencia y reparación. Dos signos pueden tener mucha química y aun así necesitar acuerdos claros sobre tiempos, planes, dinero o forma de discutir. También puede ocurrir lo contrario: una combinación exigente puede estabilizarse si ambos entienden qué activa al otro y qué necesita para bajar la defensa.</p>
    <p>Por eso cada combinación incluye fortalezas, retos, preguntas prácticas y enlaces a cartas natales. La tabla sirve como mapa de conversación: no decide por la pareja, pero ayuda a detectar qué temas conviene hablar antes de repetir el mismo conflicto.</p>
    <div class="editorial-grid">
      <article class="editorial-card">
        <h3>1. Compara el elemento</h3>
        <p>Fuego, Tierra, Aire y Agua muestran el clima básico: impulso, seguridad, diálogo o emoción. Cuando los elementos cooperan, la relación suele sentirse natural; cuando chocan, conviene traducir necesidades antes de reaccionar.</p>
      </article>
      <article class="editorial-card">
        <h3>2. Observa el ritmo</h3>
        <p>La modalidad explica cómo cada signo inicia, sostiene o adapta. Muchas tensiones no nacen de falta de amor, sino de ritmos distintos para decidir, cambiar de plan o cerrar una conversación pendiente.</p>
      </article>
      <article class="editorial-card">
        <h3>3. Lleva la lectura a hechos</h3>
        <p>Antes de sacar conclusiones, revisa tres escenas concretas: cómo pedís espacio, cómo reparáis una discusión y cómo tomáis decisiones compartidas. Ahí se ve si la compatibilidad se convierte en cuidado real.</p>
      </article>
    </div>
  </section>

$(cluster_recirculation_block "$SITE_KEY")

$(gen_footer)
</div>
<script>
const SIGN_ORDER={aries:0,tauro:1,geminis:2,cancer:3,leo:4,virgo:5,libra:6,escorpio:7,sagitario:8,capricornio:9,acuario:10,piscis:11};
function canonicalPairPath(a,b){
  return SIGN_ORDER[a] <= SIGN_ORDER[b] ? '/' + a + '-' + b : '/' + b + '-' + a;
}
function openCompatibilityFromHome(){
  const s1=document.getElementById('s1').value;
  const s2=document.getElementById('s2').value;
  const target=canonicalPairPath(s1,s2);
  if(window.clusterTrack){
    window.clusterTrack('compatibility_view',{
      selected_sign_1:s1,
      selected_sign_2:s2,
      target_path:target
    });
  }
  setTimeout(()=>{ location.href=target; },80);
}
</script>
</body>
</html>
ENDINDEX

SITEMAP_URLS="  <url><loc>https://${DOMAIN}/</loc><lastmod>${TODAY}</lastmod><changefreq>weekly</changefreq><priority>1.0</priority></url>\n${SITEMAP_URLS}"
echo "  ✓ index.html"

# ══════════════════════════════════════════════════════════════
# SIGN TABLE LANDING PAGES
# ══════════════════════════════════════════════════════════════
echo "Generating sign table landing pages..."
SIGN_TABLE_COUNT=0
for sign in "${SLUGS[@]}"; do
  sign_name="${NAME[$sign]}"
  sign_glyph="${GLYPH[$sign]}"
  sign_element="${ELEMENT[$sign]}"
  sign_ruler="${RULER[$sign]}"
  page_slug="tabla-compatibilidad-${sign}"
  page_path="/${page_slug}"
  page_title="Tabla de Compatibilidad de ${sign_name} — Signos Compatibles"
  page_desc="Consulta la tabla de compatibilidad de ${sign_name}: porcentajes de afinidad con los 12 signos, mejores parejas, retos y enlaces a cada combinación."
  rows=""
  best_links=""
  moderate_links=""
  challenge_links=""
  for other in "${SLUGS[@]}"; do
    other_name="${NAME[$other]}"
    other_glyph="${GLYPH[$other]}"
    score=$(calc_score "$sign" "$other")
    label=$(score_label "$score")
    pair_slug="$(pair_path "$sign" "$other")"
    rows+="<tr><td><a href=\"/${pair_slug}\">${sign_glyph} ${sign_name} con ${other_glyph} ${other_name}</a></td><td><strong>${score}%</strong></td><td>${label}</td></tr>"
    if (( score >= 65 )); then
      best_links+="<li><a href=\"/${pair_slug}\">${sign_name} con ${other_name}</a>: ${score}% (${label})</li>"
    elif (( score >= 50 )); then
      moderate_links+="<li><a href=\"/${pair_slug}\">${sign_name} con ${other_name}</a>: ${score}% (${label})</li>"
    else
      challenge_links+="<li><a href=\"/${pair_slug}\">${sign_name} con ${other_name}</a>: ${score}% (${label})</li>"
    fi
  done
  [[ -z "$best_links" ]] && best_links="<li>No hay combinaciones de ${sign_name} por encima del 65% en esta tabla; revisa las compatibilidades medias para ver las mejores opciones.</li>"
  [[ -z "$moderate_links" ]] && moderate_links="<li>No hay combinaciones medias para ${sign_name}; sus resultados se concentran entre afinidades altas y relaciones con más reto.</li>"
  [[ -z "$challenge_links" ]] && challenge_links="<li>No hay combinaciones de ${sign_name} por debajo del 50% en esta tabla; aun así conviene leer cada pareja en detalle.</li>"

  cat > "$PUBLIC/${page_slug}.html" <<ENDSIGN
<!DOCTYPE html>
<html lang="es">
<head>
$(gen_head "$page_title" "$page_desc" "$page_path" "sign_table_landing" "long_tail" "$sign")
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"CollectionPage","name":"${page_title}","description":"${page_desc}","url":"https://${DOMAIN}${page_path}","inLanguage":"es"}
  </script>
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Inicio","item":"https://${DOMAIN}/"},{"@type":"ListItem","position":2,"name":"Tabla de compatibilidad de ${sign_name}","item":"https://${DOMAIN}${page_path}"}]}
  </script>
  <style>
${COMMON_CSS}
    .sign-table{width:100%;border-collapse:collapse;font-size:.88rem;margin-top:1rem}
    .sign-table th,.sign-table td{border-bottom:1px solid var(--border);padding:.7rem .4rem;text-align:left}
    .sign-table th{color:var(--accent);font-size:.78rem;text-transform:uppercase}
    .sign-table a{color:var(--accent);text-decoration:none;font-weight:600}
    .split{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:1rem}
    .split h2{font-size:1rem}
  </style>
</head>
<body>
<div class="container">
  <nav class="breadcrumb"><a href="/">Compatibilidad Signos</a> › Tabla de ${sign_name}</nav>
  <div class="score-hero">
    <div class="glyphs">${sign_glyph}</div>
    <h1><span>Tabla de compatibilidad de ${sign_name}</span></h1>
    <div class="label">${sign_name} · ${sign_element} · regente ${sign_ruler}</div>
  </div>

  <div class="panel">
    <h2>Compatibilidad de ${sign_name} con todos los signos</h2>
    <p>Esta tabla resume la afinidad de ${sign_name} con los 12 signos del zodíaco. Entra en cada combinación para ver fortalezas, retos, elementos, planetas regentes y consejos de relación.</p>
    <table class="sign-table">
      <thead><tr><th>Combinación</th><th>Afinidad</th><th>Nivel</th></tr></thead>
      <tbody>
${rows}
      </tbody>
    </table>
  </div>

  <div class="split">
    <div class="panel">
      <h2>Mejores compatibilidades de ${sign_name}</h2>
      <ul>${best_links}</ul>
    </div>
    <div class="panel">
      <h2>Compatibilidades medias</h2>
      <ul>${moderate_links}</ul>
    </div>
    <div class="panel">
      <h2>Relaciones con más reto</h2>
      <ul>${challenge_links}</ul>
    </div>
  </div>

$(ad_block "❤" "Patrocina una tabla de compatibilidad por signo" "Ubicación contextual para usuarios que comparan parejas y afinidad amorosa por signo." "Ver espacios →")

  <div class="cta-box">
    <h3>Calcula una compatibilidad concreta</h3>
    <p>Vuelve a la tabla completa para comparar cualquier pareja de signos en un clic.</p>
    <a href="/">Ver tabla zodiacal completa →</a>
  </div>

$(cluster_recirculation_block "$SITE_KEY")

$(gen_footer)
</div>
</body>
</html>
ENDSIGN

  SITEMAP_URLS+="  <url><loc>https://${DOMAIN}${page_path}</loc><lastmod>${TODAY}</lastmod><changefreq>monthly</changefreq><priority>0.8</priority></url>\n"
  SIGN_TABLE_COUNT=$((SIGN_TABLE_COUNT + 1))
done
echo "  ✓ ${SIGN_TABLE_COUNT} sign table pages generated"

echo "Generating editorial trust pages..."
cat > "$PUBLIC/metodologia.html" <<ENDMETHOD
<!DOCTYPE html>
<html lang="es">
<head>
$(gen_head "Metodología de Compatibilidad de Signos — Cómo Calculamos la Afinidad" "Explicación clara del método de compatibilidad zodiacal: elementos, modalidades, regentes, distancia entre signos y límites de la lectura." "/metodologia" "methodology_page" "trust" "metodologia")
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"Article","headline":"Metodología de Compatibilidad de Signos","author":{"@type":"Organization","name":"Compatibilidad Signos"},"publisher":{"@type":"Organization","name":"Compatibilidad Signos","url":"https://${DOMAIN}/"},"mainEntityOfPage":"https://${DOMAIN}/metodologia","inLanguage":"es"}
  </script>
  <style>
${COMMON_CSS}
    .method-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:1rem;margin:1rem 0}
    .method-card{background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:1rem;box-shadow:var(--shadow)}
    .method-card h2{font-size:1rem;color:var(--accent);margin-bottom:.4rem}
    .method-card p,.method-card li{color:var(--muted);font-size:.9rem;line-height:1.7}
  </style>
</head>
<body>
<div class="container">
  <nav class="breadcrumb"><a href="/">Compatibilidad Signos</a> › Metodología</nav>
  <h1>Metodología de <span>compatibilidad</span></h1>
  <p class="intro">El porcentaje de afinidad resume varios factores astrológicos básicos. Sirve como orientación inicial, no como diagnóstico definitivo de una relación.</p>

  <div class="method-grid">
    <section class="method-card">
      <h2>Elementos</h2>
      <p>Fuego, Tierra, Aire y Agua marcan el tono de la relación: impulso, estabilidad, comunicación o sensibilidad. Los elementos afines suman fluidez; los elementos tensos exigen acuerdos más conscientes.</p>
    </section>
    <section class="method-card">
      <h2>Modalidades</h2>
      <p>Cardinal, Fijo y Mutable describen el modo de actuar. Dos signos cardinales pueden iniciar mucho y chocar por liderazgo; dos fijos dan constancia, pero también pueden resistirse al cambio.</p>
    </section>
    <section class="method-card">
      <h2>Planetas regentes</h2>
      <p>Los regentes añaden matiz: Venus busca armonía, Marte acción, Mercurio diálogo, la Luna cuidado, Saturno compromiso y Urano independencia. La afinidad sube cuando esos estilos colaboran.</p>
    </section>
  </div>

$(ad_block "❤" "Espacio contextual de metodología" "Usuarios que comparan signos y profundizan en criterios de afinidad." "Ver espacios →")

  <section class="panel">
    <h2>Cómo se interpreta el porcentaje</h2>
    <p>Las combinaciones altas suelen tener lenguaje emocional o ritmo compatible, pero no garantizan una relación fácil. Las combinaciones medias pueden funcionar muy bien si hay comunicación y objetivos compartidos. Las combinaciones con más reto no son una condena: indican dónde conviene pactar expectativas desde el principio.</p>
    <p>Por eso cada página incluye fortalezas, retos, dinámica diaria y consejos prácticos. El número ayuda a comparar, pero el valor real está en entender qué necesita cada signo para sentirse seguro, escuchado y respetado.</p>
  </section>

  <section class="panel">
    <h2>Límites de la herramienta</h2>
    <p>Esta calculadora usa el signo solar porque es el dato que la mayoría de usuarios conoce. Una lectura completa debería considerar Luna, Venus, Marte, ascendente, casas y aspectos entre cartas natales. Para ampliar el análisis puedes calcular tu <a href="https://carta-astral-gratis.es/">carta astral gratis</a>.</p>
    <p>La astrología se presenta como herramienta cultural y de autoconocimiento. No sustituye terapia, asesoramiento legal, médico ni decisiones personales basadas en hechos.</p>
  </section>

  <section class="panel">
    <h2>Recomendación de uso</h2>
    <p>Lee primero la combinación concreta, después revisa la tabla del signo y finalmente cruza el resultado con situaciones reales: cómo habláis de límites, cómo reparáis una discusión, cómo gestionáis el tiempo y cómo decidís planes.</p>
  </section>

$(cluster_recirculation_block "$SITE_KEY")
$(gen_footer)
</div>
</body>
</html>
ENDMETHOD

cat > "$PUBLIC/sobre-nosotros.html" <<ENDABOUT
<!DOCTYPE html>
<html lang="es">
<head>
$(gen_head "Sobre Compatibilidad Signos — Criterio Editorial y Contacto" "Quién mantiene Compatibilidad Signos, cómo se genera el contenido y qué límites tiene la calculadora zodiacal gratuita." "/sobre-nosotros" "about_page" "trust" "sobre-nosotros")
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"AboutPage","name":"Sobre Compatibilidad Signos","url":"https://${DOMAIN}/sobre-nosotros","isPartOf":{"@type":"WebSite","name":"Compatibilidad Signos","url":"https://${DOMAIN}/"},"inLanguage":"es"}
  </script>
  <style>
${COMMON_CSS}
    .trust-list li{color:var(--muted);font-size:.9rem;line-height:1.7;margin-bottom:.4rem}
  </style>
</head>
<body>
<div class="container">
  <nav class="breadcrumb"><a href="/">Compatibilidad Signos</a> › Sobre nosotros</nav>
  <h1>Sobre <span>Compatibilidad Signos</span></h1>
  <section class="panel">
    <h2>Qué hacemos</h2>
    <p>Compatibilidad Signos ofrece una tabla gratuita de afinidad zodiacal con 144 combinaciones canónicas. Cada lectura explica porcentaje, elementos, regentes, fortalezas, retos y recomendaciones prácticas para relaciones.</p>
    <p>La web forma parte de una red de herramientas en español sobre astrología, tarot, numerología y bienestar. El objetivo es que cada página resuelva una búsqueda concreta sin exigir registro ni pago.</p>
  </section>

  <section class="panel">
    <h2>Criterio editorial</h2>
    <ul class="trust-list">
      <li>Las puntuaciones siguen una regla estable basada en elementos, modalidades, regentes y distancia zodiacal.</li>
      <li>Las páginas explican límites: el signo solar no sustituye una carta natal completa ni la experiencia real de la relación.</li>
      <li>Revisamos el sitio cuando detectamos contenido insuficiente, errores de indexación o señales de baja calidad.</li>
      <li>La publicidad directa se separa del contenido editorial y se revisa antes de publicarse.</li>
    </ul>
  </section>

  <section class="panel">
    <h2>Contacto</h2>
    <p>Para correcciones, sugerencias o publicidad contextual puedes escribir a <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>.</p>
  </section>

$(cluster_recirculation_block "$SITE_KEY")
$(gen_footer)
</div>
</body>
</html>
ENDABOUT

SITEMAP_URLS+="  <url><loc>https://${DOMAIN}/metodologia</loc><lastmod>${TODAY}</lastmod><changefreq>monthly</changefreq><priority>0.8</priority></url>\n"
SITEMAP_URLS+="  <url><loc>https://${DOMAIN}/sobre-nosotros</loc><lastmod>${TODAY}</lastmod><changefreq>monthly</changefreq><priority>0.6</priority></url>\n"

write_firebase_json() {
  {
    cat <<'ENDJSON'
{
  "hosting": {
    "public": "public",
    "cleanUrls": true,
    "trailingSlash": false,
    "redirects": [
ENDJSON
    local first=1
    for s1 in "${SLUGS[@]}"; do
      for s2 in "${SLUGS[@]}"; do
        local source_slug="${s1}-${s2}"
        local destination_slug
        destination_slug="$(canonical_pair_slug "$s1" "$s2")"
        if [[ "$source_slug" != "$destination_slug" ]]; then
          if (( first == 0 )); then
            printf ',\n'
          fi
          first=0
          printf '      { "source": "/%s", "destination": "/%s", "type": 301 }' "$source_slug" "$destination_slug"
        fi
      done
    done
    cat <<'ENDJSON'

    ],
    "headers": [
      {
        "source": "**",
        "headers": [
          { "key": "X-Content-Type-Options", "value": "nosniff" },
          { "key": "X-Frame-Options", "value": "DENY" },
          { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
          { "key": "Strict-Transport-Security", "value": "max-age=31536000; includeSubDomains; preload" },
          { "key": "Permissions-Policy", "value": "camera=(), microphone=(), geolocation=()" }
        ]
      },
      {
        "source": "**/*.html",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=3600, s-maxage=86400, stale-while-revalidate=3600" }
        ]
      },
      {
        "source": "**/*.@(js|css|ico|png|jpg|svg|webp|woff2)",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=604800, s-maxage=604800, stale-while-revalidate=86400" }
        ]
      },
      {
        "source": "/{robots.txt,sitemap.xml,ads.txt}",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=86400" }
        ]
      }
    ]
  }
}
ENDJSON
  } > "$SITE_DIR/firebase.json"
}

# ══════════════════════════════════════════════════════════════
# STATIC FILES: 404, ads.txt, robots.txt, sitemap.xml
# ══════════════════════════════════════════════════════════════

# ads.txt
echo "google.com, ${ADSENSE_PUB#ca-}, DIRECT, f08c47fec0942fa0" > "$PUBLIC/ads.txt"

# publicidad
gen_publicidad_page "$SITE_KEY" "$PUBLIC"

# robots.txt
cat > "$PUBLIC/robots.txt" <<ENDROBOTS
User-agent: *
Allow: /
Sitemap: https://${DOMAIN}/sitemap.xml
ENDROBOTS

# sitemap.xml
if direct_ads_enabled; then
  SITEMAP_URLS+="  <url><loc>https://${DOMAIN}/publicidad</loc><lastmod>${TODAY}</lastmod><changefreq>monthly</changefreq><priority>0.6</priority></url>\n"
fi
SITEMAP_URLS+="  <url><loc>https://${DOMAIN}/privacy</loc><lastmod>${TODAY}</lastmod><changefreq>yearly</changefreq><priority>0.3</priority></url>\n"
SITEMAP_URLS+="  <url><loc>https://${DOMAIN}/terms</loc><lastmod>${TODAY}</lastmod><changefreq>yearly</changefreq><priority>0.3</priority></url>\n"
cat > "$PUBLIC/sitemap.xml" <<ENDSITEMAP
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
$(echo -e "$SITEMAP_URLS")</urlset>
ENDSITEMAP

write_firebase_json

# 404
cat > "$PUBLIC/404.html" <<END404
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Página no encontrada — Compatibilidad Signos</title>
  <meta name="description" content="Página no encontrada en Compatibilidad Signos. Vuelve al inicio para calcular la afinidad entre signos zodiacales.">
  <meta name="robots" content="noindex">
$(canonical_host_redirect_script "$DOMAIN")
  <style>${COMMON_CSS}</style>
</head>
<body>
<div class="container" style="text-align:center;padding:4rem 1rem">
  <div style="font-size:4rem">♈♏</div>
  <h1>Página no encontrada</h1>
  <p style="color:var(--muted);margin:1rem 0">Los astros no encuentran esta ruta. Vuelve al inicio para explorar compatibilidades.</p>
  <a href="/" style="display:inline-block;padding:.6rem 1.5rem;background:var(--accent);color:#fff;border-radius:10px;text-decoration:none;font-weight:600">← Volver al inicio</a>
</div>
</body>
</html>
END404

echo "  ✓ ads.txt, robots.txt, sitemap.xml, 404.html"
bash "$REPO_ROOT/scripts/generate-legal-pages.sh" "$SITE_KEY"
HTML_COUNT=$(find "$PUBLIC" -type f -name '*.html' | wc -l | tr -d ' ')
echo "Done! ${HTML_COUNT} HTML pages + static files in $PUBLIC"
