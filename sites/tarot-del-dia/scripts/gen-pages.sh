#!/usr/bin/env bash
set -euo pipefail
# Generate tarot-del-dia.es: index (interactive spread) + 22 major arcana pages + 56 minor arcana pages

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBLIC="$SITE_DIR/public"
REPO_ROOT="$(cd "$SITE_DIR/../.." && pwd)"

source "$REPO_ROOT/shared/config.sh"

SITE_KEY="tarot-del-dia"
DOMAIN="${DOMAINS[$SITE_KEY]}"
GA4="${GA4_IDS[$SITE_KEY]}"
TODAY=$(date +%Y-%m-%d)
AD_CSS="$(ad_css)"
CLUSTER_CSS="$(cluster_css)"

mkdir -p "$PUBLIC/arcanos-mayores" "$PUBLIC/arcanos-menores"

CROSSLINKS_HTML=$(crosslink_footer "$SITE_KEY")

# ── Common head ──────────────────────────────────────────────
gen_head() {
  local title="$1" desc="$2" canonical="$3" page_type="${4:-page}" content_group="${5:-content}" entity_slug="${6:-}"
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
  <meta name="robots" content="index, follow">
  <link rel="preconnect" href="https://fonts.googleapis.com" crossorigin>
  <link href="${BRAND_FONTS}" rel="stylesheet" media="print" onload="this.media='all'">
  <noscript><link href="${BRAND_FONTS}" rel="stylesheet"></noscript>
$(canonical_host_redirect_script "$DOMAIN")
$(ga4_head_snippet "$GA4" "$SITE_KEY" "$page_type" "$content_group" "$entity_slug")
$(adsense_head_snippet)
ENDHEAD
}

COMMON_CSS="
    ${CSS_VARS}
    *{margin:0;padding:0;box-sizing:border-box}
    body{font-family:'Inter',system-ui,sans-serif;background:var(--bg);color:var(--text);min-height:100vh}
    .container{max-width:820px;margin:0 auto;padding:1.5rem}
    .breadcrumb{font-size:.8rem;color:var(--muted);margin-bottom:1.5rem}
    .breadcrumb a{color:var(--accent);text-decoration:none}
    h1{font-family:'Playfair Display',serif;font-size:1.9rem;text-align:center;margin:.5rem 0}
    h1 span{background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
    h2{font-family:'Playfair Display',serif;font-size:1.15rem;color:var(--text);margin-bottom:.7rem}
    .panel{background:var(--surface);border:1px solid var(--border);border-radius:16px;padding:1.6rem;box-shadow:var(--shadow);margin-bottom:1.2rem}
    .panel p,.panel li{line-height:1.7;color:var(--muted);font-size:.9rem}
    .panel ul{padding-left:1.2rem;margin:.5rem 0}
    .cta-box{text-align:center;padding:1.8rem;background:linear-gradient(135deg,#f3eeff 0%,#fef9ee 100%);border-radius:16px;margin:1.5rem 0}
    .cta-box h3{font-family:'Playfair Display',serif;font-size:1.05rem;margin-bottom:.4rem}
    .cta-box p{color:var(--muted);font-size:.88rem;margin-bottom:.8rem}
    .cta-box a{display:inline-block;padding:.6rem 1.4rem;background:var(--accent);color:#fff;font-weight:600;border-radius:10px;text-decoration:none;font-size:.88rem;box-shadow:0 4px 14px rgba(124,58,237,.3)}
    .cta-box a:hover{background:#6d28d9;transform:translateY(-1px)}
    .network{text-align:center;font-size:.75rem;color:var(--muted);margin-top:1rem}
    .network a{color:var(--accent);text-decoration:none}
    footer{text-align:center;padding:2rem 1rem;font-size:.75rem;color:var(--muted);border-top:1px solid var(--border);margin-top:2rem}
    footer a{color:var(--accent);text-decoration:none}
${AD_CSS}
${CLUSTER_CSS}
"

gen_footer() {
  cat <<ENDFOOTER
<footer>
  <p>© $(date +%Y) Tarot del Día — Herramienta gratuita de tarot</p>
  <p><a href="/guia-tarot">Guía de lectura</a> · <a href="/sobre-nosotros">Sobre nosotros</a> · <a href="/privacy">Privacidad</a> · <a href="/terms">Términos</a></p>
  $(footer_publicidad_line "$SITE_KEY")
  ${CROSSLINKS_HTML}
</footer>
ENDFOOTER
}

# ══════════════════════════════════════════════════════════════
# MAJOR ARCANA DATA (22 cards)
# ══════════════════════════════════════════════════════════════
declare -a MAJOR_SLUGS MAJOR_NAMES MAJOR_NUMS MAJOR_KEYS MAJOR_UPRIGHT MAJOR_REVERSED MAJOR_DESC

MAJOR_SLUGS=(el-loco el-mago la-sacerdotisa la-emperatriz el-emperador el-sumo-sacerdote los-enamorados el-carro la-fuerza el-ermitano la-rueda-de-la-fortuna la-justicia el-colgado la-muerte la-templanza el-diablo la-torre la-estrella la-luna el-sol el-juicio el-mundo)
MAJOR_NAMES=("El Loco" "El Mago" "La Sacerdotisa" "La Emperatriz" "El Emperador" "El Sumo Sacerdote" "Los Enamorados" "El Carro" "La Fuerza" "El Ermitaño" "La Rueda de la Fortuna" "La Justicia" "El Colgado" "La Muerte" "La Templanza" "El Diablo" "La Torre" "La Estrella" "La Luna" "El Sol" "El Juicio" "El Mundo")
MAJOR_NUMS=("0" "I" "II" "III" "IV" "V" "VI" "VII" "VIII" "IX" "X" "XI" "XII" "XIII" "XIV" "XV" "XVI" "XVII" "XVIII" "XIX" "XX" "XXI")
MAJOR_KEYS=("libertad, espontaneidad, nuevos comienzos" "manifestación, poder, creatividad" "intuición, misterio, sabiduría interior" "abundancia, fertilidad, creatividad" "autoridad, estructura, estabilidad" "tradición, fe, conformidad" "amor, elección, unión" "determinación, victoria, voluntad" "coraje, paciencia, dominio interior" "introspección, búsqueda, soledad" "destino, ciclos, cambio inevitable" "equilibrio, verdad, causa y efecto" "sacrificio, nueva perspectiva, rendición" "transformación, fin de un ciclo, renacimiento" "equilibrio, moderación, paciencia" "atadura, materialismo, sombra" "destrucción repentina, revelación, liberación" "esperanza, inspiración, serenidad" "ilusión, miedo, subconsciente" "alegría, éxito, vitalidad" "renovación, despertar, evaluación" "completitud, logro, integración")
MAJOR_UPRIGHT=("aventura, libertad, inocencia" "habilidad, concentración, recursos" "intuición, silencio, conocimiento oculto" "naturaleza, nutrición, abundancia" "control, liderazgo, disciplina" "enseñanza, guía espiritual, tradición" "relaciones, armonía, elecciones importantes" "ambición, triunfo, autocontrol" "valor interior, compasión, resistencia" "sabiduría, retiro, guía interior" "oportunidad, karma, destino" "honestidad, ley, imparcialidad" "pausa, entrega, iluminación" "cambio profundo, transición, soltar" "armonía, salud, propósito" "esclavitud, adicción, exceso" "cambio abrupto, crisis, verdad oculta" "fe, calma, conexión cósmica" "ansiedad, confusión, engaño" "felicidad, éxito, optimismo" "juicio, redención, llamada interior" "realización, viaje completo, celebración")
MAJOR_REVERSED=("imprudencia, riesgo innecesario, caos" "engaño, manipulación, talentos desperdiciados" "secretos, desconexión, silencio excesivo" "dependencia, bloqueo creativo, abandono" "tiranía, rigidez, abuso de poder" "dogmatismo, rebeldía, restricción" "desequilibrio, desalineación, indecisión" "agresividad, falta de dirección, derrota" "debilidad, inseguridad, falta de disciplina" "aislamiento, paranoia, reclusión" "mala suerte, resistencia al cambio, estancamiento" "injusticia, deshonestidad, falta de responsabilidad" "retraso, resistencia, indecisión" "miedo al cambio, estancamiento, decadencia" "desequilibrio, exceso, falta de visión" "liberación, independencia, enfrentar miedos" "resistencia al cambio, repetir errores, dolor evitable" "desesperanza, pesimismo, desconexión" "claridad, superación de miedos, comprensión" "tristeza, pesimismo, falta de éxito temporal" "autocrítica excesiva, duda, miedo al cambio" "incompleto, atajos, falta de cierre")
MAJOR_DESC=("El Loco representa el espíritu libre que da el salto al vacío con confianza. Es el inicio del viaje, la inocencia ante lo desconocido y la valentía de empezar sin garantías. Conecta con la energía de Urano y el elemento Aire." "El Mago canaliza los cuatro elementos hacia la manifestación concreta. Tiene todos los recursos a su disposición y el poder de transformar ideas en realidad. Conecta con Mercurio y la comunicación creativa." "La Sacerdotisa guarda los misterios del subconsciente. Invita a mirar hacia dentro, a confiar en la intuición y a escuchar lo que no se dice con palabras. Conecta con la Luna y el elemento Agua." "La Emperatriz encarna la Madre Tierra: creatividad, sensualidad y abundancia natural. Todo lo que toca florece. Conecta con Venus y la fertilidad de la naturaleza." "El Emperador construye imperios con disciplina y visión a largo plazo. Representa la estructura, el orden y la autoridad responsable. Conecta con Aries y Marte." "El Sumo Sacerdote transmite la sabiduría ancestral y las tradiciones. Es el puente entre lo terrenal y lo espiritual, el maestro que guía con experiencia. Conecta con Tauro y Venus." "Los Enamorados presentan una encrucijada fundamental: elegir con el corazón alineado con la mente. Representan la unión, el amor verdadero y las decisiones que definen el camino. Conecta con Géminis y Mercurio." "El Carro avanza con determinación imparable. La voluntad domina a las emociones y la meta está clara. Conecta con Cáncer y la protección emocional canalizada en acción." "La Fuerza no es la del músculo sino la del espíritu. Paciencia, compasión y dominio de los instintos. Es el león domesticado por el amor. Conecta con Leo y el corazón." "El Ermitaño se retira del ruido para encontrar su verdad interior. La soledad elegida es su herramienta de sabiduría. Conecta con Virgo y Mercurio en su faceta más analítica." "La Rueda de la Fortuna gira sin cesar: lo que sube baja y lo que baja vuelve a subir. Recuerda que todo es cíclico y que el cambio es la única constante. Conecta con Júpiter y la expansión." "La Justicia pesa cada acción con precisión. Lo que siembras cosechas, sin excepciones. Invita a la honestidad radical y a asumir consecuencias. Conecta con Libra y Venus." "El Colgado ve el mundo desde un ángulo diferente. Al rendirse, gana una perspectiva que no tenía. El sacrificio voluntario puede ser la mayor liberación. Conecta con Neptuno y el Agua." "La Muerte no es un final sino una metamorfosis profunda. Lo viejo debe morir para que nazca lo nuevo. Es la transformación más poderosa del tarot. Conecta con Escorpio y Plutón." "La Templanza mezcla opuestos con maestría alquímica. Paciencia, moderación y fe en el proceso. Todo llega a su tiempo justo. Conecta con Sagitario y Júpiter." "El Diablo refleja nuestras cadenas autoimpuestas: adicciones, miedos, apegos materiales. Reconocer la sombra es el primer paso para liberarse. Conecta con Capricornio y Saturno." "La Torre destruye en un instante lo que estaba construido sobre cimientos falsos. Aunque dolorosa, la revelación libera. Conecta con Marte y la energía de ruptura." "La Estrella brilla después de la tormenta. Es la esperanza serena, la fe renovada y la conexión con el universo. Conecta con Acuario y Urano en su faceta más luminosa." "La Luna ilumina el mundo de los sueños, las sombras y los miedos inconscientes. Nada es lo que parece bajo su luz. Invita a explorar el subconsciente con valentía. Conecta con Piscis y Neptuno." "El Sol irradia alegría pura, éxito y vitalidad. Es la carta más positiva del tarot: claridad, confianza y energía vital al máximo. Conecta con el Sol y Leo." "El Juicio llama al despertar final. Es hora de evaluar el camino recorrido, perdonar y responder a una vocación más alta. Conecta con Plutón y la renovación total." "El Mundo es la culminación del viaje. Todo se integra, se completa y se celebra. Es el logro máximo antes de que un nuevo ciclo comience. Conecta con Saturno y la maestría.")

SITEMAP_URLS=""
PAGE_COUNT=0
MAJOR_TITLE_TEMPLATE="{{name}} ({{num}}) — Significado en el Tarot | Tarot del Día"
MAJOR_DESC_TEMPLATE="Significado de {{name}} (Arcano Mayor {{num}}): interpretación al derecho e invertida, amor, trabajo y consejo práctico para tu tirada diaria."

# ── Generate Major Arcana pages ──────────────────────────────
echo "Generating 22 major arcana pages..."
for i in "${!MAJOR_SLUGS[@]}"; do
  slug="${MAJOR_SLUGS[$i]}"
  name="${MAJOR_NAMES[$i]}"
  num="${MAJOR_NUMS[$i]}"
  keys="${MAJOR_KEYS[$i]}"
  upright="${MAJOR_UPRIGHT[$i]}"
  reversed="${MAJOR_REVERSED[$i]}"
  desc="${MAJOR_DESC[$i]}"

  url_path="/arcanos-mayores/${slug}"
  title="${MAJOR_TITLE_TEMPLATE//\{\{name\}\}/$name}"
  title="${title//\{\{num\}\}/$num}"

  meta_desc="${MAJOR_DESC_TEMPLATE//\{\{name\}\}/$name}"
  meta_desc="${meta_desc//\{\{num\}\}/$num}"
  meta_desc="${meta_desc//\{\{upright\}\}/$upright}"
  meta_desc="${meta_desc//\{\{reversed\}\}/$reversed}"

  # Prev/next navigation
  prev_idx=$(( (i - 1 + 22) % 22 ))
  next_idx=$(( (i + 1) % 22 ))

  cat > "$PUBLIC/arcanos-mayores/${slug}.html" <<ENDCARD
<!DOCTYPE html>
<html lang="es">
<head>
$(gen_head "$title" "$meta_desc" "$url_path" "arcana_profile" "evergreen" "$slug")
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"Article","headline":"${name} — Significado en el Tarot","description":"${meta_desc}","author":{"@type":"Organization","name":"Tarot del Día"},"publisher":{"@type":"Organization","name":"Tarot del Día","url":"https://${DOMAIN}/"},"mainEntityOfPage":"https://${DOMAIN}${url_path}","inLanguage":"es"}
  </script>
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Inicio","item":"https://${DOMAIN}/"},{"@type":"ListItem","position":2,"name":"Arcanos Mayores","item":"https://${DOMAIN}/arcanos-mayores"},{"@type":"ListItem","position":3,"name":"${name}","item":"https://${DOMAIN}${url_path}"}]}
  </script>
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":"¿Qué significa ${name} en el tarot?","acceptedAnswer":{"@type":"Answer","text":"${name} (Arcano ${num}) representa: ${keys}. Al derecho indica ${upright}. Invertida señala ${reversed}."}},{"@type":"Question","name":"¿${name} es una carta positiva o negativa?","acceptedAnswer":{"@type":"Answer","text":"Ninguna carta del tarot es intrínsecamente positiva o negativa. ${name} tiene un mensaje que depende del contexto de la tirada y las cartas que le acompañan."}}]}
  </script>
  <style>
${COMMON_CSS}
    .card-hero{text-align:center;padding:2rem 0 1rem}
    .card-hero .card-face{width:140px;height:240px;margin:0 auto 1rem;background:linear-gradient(135deg,#2d1b69,#4a2c8a,#1a0f3c);border-radius:12px;display:flex;flex-direction:column;align-items:center;justify-content:center;color:#e8dff5;box-shadow:0 8px 32px rgba(45,27,105,.4);border:2px solid #7c3aed}
    .card-hero .card-face .num{font-size:.8rem;letter-spacing:.1em;opacity:.7;font-weight:300}
    .card-hero .card-face .symbol{font-size:3rem;margin:.5rem 0}
    .card-hero .card-face .cname{font-size:.85rem;font-weight:600}
    .keywords{display:flex;flex-wrap:wrap;gap:.4rem;justify-content:center;margin:1rem 0}
    .keywords .kw{padding:.25rem .7rem;border-radius:20px;font-size:.75rem;font-weight:500;background:#f3eeff;color:var(--accent);border:1px solid rgba(124,58,237,.15)}
    .meaning-grid{display:grid;grid-template-columns:1fr 1fr;gap:1rem;margin:1rem 0}
    @media(max-width:500px){.meaning-grid{grid-template-columns:1fr}}
    .meaning-card{padding:1.2rem;border-radius:12px;border:1px solid var(--border)}
    .meaning-card.upright{background:#f0fdf4;border-color:#bbf7d0}
    .meaning-card.reversed{background:#fef2f2;border-color:#fecaca}
    .meaning-card h3{font-size:.85rem;font-weight:600;margin-bottom:.4rem}
    .meaning-card.upright h3{color:#16a34a}
    .meaning-card.reversed h3{color:#dc2626}
    .meaning-card p{font-size:.85rem;line-height:1.6;color:var(--muted)}
    .nav-cards{display:flex;justify-content:space-between;margin:1.5rem 0}
    .nav-cards a{color:var(--accent);text-decoration:none;font-size:.85rem;font-weight:500}
  </style>
</head>
<body>
<div class="container">
  <nav class="breadcrumb"><a href="/">Tarot del Día</a> › <a href="/arcanos-mayores">Arcanos Mayores</a> › ${name}</nav>

  <div class="card-hero">
    <div class="card-face">
      <div class="num">ARCANO ${num}</div>
      <div class="symbol">🃏</div>
      <div class="cname">${name}</div>
    </div>
    <h1><span>${name}</span></h1>
    <p style="color:var(--muted);font-size:.9rem">Arcano Mayor ${num}</p>
  </div>

  <div class="keywords">$(IFS=','; for kw in ${keys}; do echo "<span class=\"kw\">${kw## }</span>"; done)</div>

$(ad_block "🔮" "¿Ofreces consultas, cursos o productos esotéricos?" "Tu marca puede aparecer junto a lectores que ya están inmersos en una interpretación de tarot." "Ver espacios y tarifas →")

  <div class="panel">
    <h2>🔮 Descripción de ${name}</h2>
    <p>${desc}</p>
  </div>

  <div class="meaning-grid">
    <div class="meaning-card upright">
      <h3>☀️ Al Derecho</h3>
      <p>${upright}</p>
    </div>
    <div class="meaning-card reversed">
      <h3>🌙 Invertida</h3>
      <p>${reversed}</p>
    </div>
  </div>

  <div class="panel">
    <h2>💕 ${name} en el Amor</h2>
    <p>Cuando ${name} aparece en una tirada sobre relaciones, su mensaje se centra en ${keys}. Al derecho invita a vivir estos aspectos con apertura; invertida sugiere revisar si hay bloqueos en esta área de tu vida. Para un análisis más profundo de tu vida amorosa, consulta la <a href="https://compatibilidad-signos.es/">compatibilidad entre signos</a>.</p>
  </div>

  <div class="panel">
    <h2>💼 ${name} en el Trabajo</h2>
    <p>En el ámbito laboral, ${name} al derecho señala ${upright}. Es un momento para aplicar estas energías en tu carrera. Invertida puede indicar ${reversed}, invitándote a reflexionar sobre tu dirección profesional.</p>
  </div>

  <div class="panel">
    <h2>Cómo integrar el mensaje de ${name}</h2>
    <p>Para interpretar ${name} fuera de una tirada completa, empieza por la pregunta y el contexto. Si ya forma parte de una tirada de tres cartas, léela junto a su posición, su orientación y las cartas vecinas: en pasado puede señalar una experiencia que todavía condiciona; en presente muestra una energía activa; en futuro habla de una tendencia si mantienes el mismo camino.</p>
    <p>Si aparece al derecho, trabaja las claves de ${upright} de forma consciente. Si aparece invertida, no la leas como castigo: suele indicar una energía bloqueada, exagerada o vivida hacia dentro. La utilidad del tarot está en convertir el símbolo en una acción concreta.</p>
    <p>Antes de cerrar la lectura, formula una acción pequeña: una conversación que debes tener, un límite que conviene marcar, una decisión que necesita más información o un descanso que estás posponiendo. El símbolo gana valor cuando se traduce en una conducta observable durante el día.</p>
    <p>También es importante mirar las cartas vecinas. ${name} puede suavizarse, intensificarse o cambiar de matiz según el arcano que aparezca antes y después. Una lectura completa no suma significados sueltos: busca una historia coherente entre pregunta, posición, carta y contexto personal.</p>
    <p>Si la carta se repite en varias tiradas, trátala como un tema abierto. No hace falta repetir la misma pregunta: conviene revisar qué decisión, emoción o patrón sigue pendiente y qué cambio pequeño puedes hacer para mover la situación.</p>
  </div>

  <div class="panel">
    <h2>Preguntas para tu diario de tarot</h2>
    <ul>
      <li>¿Dónde estás viviendo ahora las claves de ${keys}?</li>
      <li>¿Qué decisión cambia si aplicas el mensaje de ${name} con honestidad?</li>
      <li>¿Qué otra carta de la tirada confirma, matiza o contradice esta lectura?</li>
    </ul>
  </div>

$(ad_block "🃏" "Patrocina una lectura de alta atención" "Ubicación destacada entre la interpretación y la llamada a la acción del usuario." "Reservar un banner destacado →")

  <div class="nav-cards">
    <a href="/arcanos-mayores/${MAJOR_SLUGS[$prev_idx]}">← ${MAJOR_NAMES[$prev_idx]}</a>
    <a href="/arcanos-mayores">Todos los Arcanos</a>
    <a href="/arcanos-mayores/${MAJOR_SLUGS[$next_idx]}">${MAJOR_NAMES[$next_idx]} →</a>
  </div>

  <div class="cta-box">
    <h3>🃏 Haz tu tirada de tarot gratis</h3>
    <p>Descubre qué te deparan las cartas hoy con nuestra tirada interactiva de 3 cartas.</p>
    <a href="/">Tirada gratis →</a>
  </div>

$(cluster_recirculation_block "$SITE_KEY")

$(gen_footer)
</div>
</body>
</html>
ENDCARD

  SITEMAP_URLS+="  <url><loc>https://${DOMAIN}${url_path}</loc><lastmod>${TODAY}</lastmod><changefreq>monthly</changefreq><priority>0.7</priority></url>\n"
  PAGE_COUNT=$((PAGE_COUNT + 1))
done
echo "  ✓ ${PAGE_COUNT} major arcana pages"

# ── Arcanos Mayores index ────────────────────────────────────
echo "Generating arcanos-mayores index..."
CARDS_GRID=""
for i in "${!MAJOR_SLUGS[@]}"; do
  CARDS_GRID+="<a class=\"tarot-card\" href=\"/arcanos-mayores/${MAJOR_SLUGS[$i]}\"><span class=\"tnum\">${MAJOR_NUMS[$i]}</span><span class=\"tname\">${MAJOR_NAMES[$i]}</span><span class=\"tkeys\">${MAJOR_KEYS[$i]}</span></a>"
done

cat > "$PUBLIC/arcanos-mayores/index.html" <<ENDMAJOR
<!DOCTYPE html>
<html lang="es">
<head>
$(gen_head "Los 22 Arcanos Mayores del Tarot — Significado Completo" "Guía completa de los 22 Arcanos Mayores del tarot. Significado, interpretación al derecho e invertida de cada carta. De El Loco a El Mundo." "/arcanos-mayores" "content_hub" "hub" "arcanos-mayores")
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Inicio","item":"https://${DOMAIN}/"},{"@type":"ListItem","position":2,"name":"Arcanos Mayores","item":"https://${DOMAIN}/arcanos-mayores"}]}
  </script>
  <style>
${COMMON_CSS}
    .intro{text-align:center;color:var(--muted);font-size:.92rem;line-height:1.6;max-width:620px;margin:0 auto 1.5rem}
    .tarot-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:1rem;margin:1.5rem 0}
    .tarot-card{background:linear-gradient(135deg,#2d1b69,#4a2c8a);border-radius:12px;padding:1.2rem;text-align:center;text-decoration:none;color:#e8dff5;transition:all .2s;box-shadow:0 4px 16px rgba(45,27,105,.3)}
    .tarot-card:hover{transform:translateY(-3px);box-shadow:0 8px 24px rgba(45,27,105,.4)}
    .tarot-card .tnum{font-size:.7rem;letter-spacing:.1em;opacity:.6;display:block}
    .tarot-card .tname{font-family:'Playfair Display',serif;font-weight:700;font-size:.95rem;display:block;margin:.4rem 0}
    .tarot-card .tkeys{font-size:.7rem;opacity:.7;line-height:1.4;display:block}
  </style>
</head>
<body>
<div class="container">
  <nav class="breadcrumb"><a href="/">Tarot del Día</a> › Arcanos Mayores</nav>
  <h1>Los 22 <span>Arcanos Mayores</span></h1>
  <p class="intro">Los Arcanos Mayores representan los grandes arquetipos y lecciones de vida. Cada carta contiene un mensaje profundo sobre tu camino. Pulsa en cualquiera para leer su significado completo.</p>
  <div class="panel">
    <h2>Cómo estudiar los Arcanos Mayores</h2>
    <p>Los Arcanos Mayores forman una secuencia simbólica: empiezan con El Loco, que inicia el viaje sin certezas, y terminan con El Mundo, que integra la experiencia. Leerlos como un recorrido ayuda a entender por qué una carta no es buena o mala por sí misma, sino una etapa concreta de aprendizaje.</p>
    <p>En cada ficha encontrarás significado general, lectura al derecho, lectura invertida, amor, trabajo y preguntas para aplicar el mensaje. Si estás haciendo una tirada, lee primero la carta individual y después vuelve al conjunto para comprobar cómo dialoga con las demás.</p>
    <p>Un buen método de estudio es elegir una carta por semana y observar dónde aparece su energía en decisiones reales. Por ejemplo, El Emperador puede verse en límites y estructura, La Luna en dudas o proyecciones, y La Templanza en procesos que requieren paciencia. Este enfoque evita memorizar listas sin conexión con la experiencia.</p>
    <p>También puedes comparar cartas que parecen opuestas. La Fuerza y El Carro hablan de voluntad, pero una lo hace desde la calma interior y otra desde la dirección externa. La Muerte y La Torre implican cambios, aunque una describe transformación profunda y la otra ruptura repentina. Estas diferencias son las que hacen que una tirada sea rica.</p>
    <p>Si acabas de empezar, trabaja primero con tres posiciones: situación, consejo y tendencia. Cuando ya reconozcas bien los arquetipos, añade cartas de bloqueo, recurso y resultado probable. Así mantienes la lectura clara sin perder profundidad.</p>
    <p>La clave está en observar diferencias concretas. Dos cartas pueden hablar de cambio, pero no del mismo tipo de cambio; dos pueden hablar de amor, pero una señalar deseo y otra compromiso. Cuanto más precisa sea esa distinción, más útil será la lectura.</p>
  </div>

$(ad_block "🃏" "Publicidad destacada para un público espiritual" "Ideal para marcas de tarot, rituales, formación y productos con afinidad esotérica." "Informarme →")

  <div class="tarot-grid">${CARDS_GRID}</div>

  <div class="cta-box">
    <h3>🃏 Haz tu tirada de tarot gratis</h3>
    <p>Descubre qué te dicen los Arcanos Mayores hoy.</p>
    <a href="/">Tirada gratis →</a>
  </div>

$(cluster_recirculation_block "$SITE_KEY")

$(gen_footer)
</div>
</body>
</html>
ENDMAJOR

SITEMAP_URLS+="  <url><loc>https://${DOMAIN}/arcanos-mayores</loc><lastmod>${TODAY}</lastmod><changefreq>monthly</changefreq><priority>0.8</priority></url>\n"
echo "  ✓ arcanos-mayores/index.html"

# ── Minor Arcana pages ───────────────────────────────────────
declare -a SUIT_SLUGS SUIT_NAMES SUIT_ELEMENTS SUIT_AREAS SUIT_SYMBOLS SUIT_THEMES SUIT_SHADOWS SUIT_ACTIONS
SUIT_SLUGS=(bastos copas espadas oros)
SUIT_NAMES=("Bastos" "Copas" "Espadas" "Oros")
SUIT_ELEMENTS=("Fuego" "Agua" "Aire" "Tierra")
SUIT_AREAS=("deseo, iniciativa y energia vital" "emociones, vinculos y sensibilidad" "mente, comunicacion y decisiones" "cuerpo, recursos y resultados concretos")
SUIT_SYMBOLS=("🔥" "💧" "⚔️" "🪙")
SUIT_THEMES=("movimiento, valor, creatividad y accion visible" "afecto, intuicion, memoria emocional y reciprocidad" "claridad mental, conflicto, palabra y verdad" "trabajo, dinero, salud, paciencia y estabilidad")
SUIT_SHADOWS=("impulsividad, prisa o desgaste por actuar sin pausa" "dependencia emocional, idealizacion o exceso de nostalgia" "rumiacion, dureza verbal o necesidad de tener razon" "apego a la seguridad, lentitud o miedo a perder recursos")
SUIT_ACTIONS=("elige una accion pequena y hazla antes de buscar mas senales" "nombra lo que sientes sin convertirlo en exigencia" "escribe la decision con pros, limites y una pregunta honesta" "baja la lectura a tiempo, dinero, energia y compromiso real")

declare -a RANK_SLUGS RANK_NAMES RANK_ARCS RANK_LIGHTS RANK_SHADOWS RANK_QUESTIONS
RANK_SLUGS=(as dos tres cuatro cinco seis siete ocho nueve diez sota caballo reina rey)
RANK_NAMES=("As" "Dos" "Tres" "Cuatro" "Cinco" "Seis" "Siete" "Ocho" "Nueve" "Diez" "Sota" "Caballo" "Reina" "Rey")
RANK_ARCS=("inicio disponible" "decision o equilibrio" "crecimiento compartido" "estructura y pausa" "tension que pide ajuste" "intercambio y reparacion" "eleccion entre opciones" "avance rapido" "madurez interior" "culminacion del ciclo" "aprendizaje y mensaje" "movimiento y busqueda" "dominio receptivo" "dominio activo")
RANK_LIGHTS=("abre una puerta nueva y pide atencion al primer impulso" "ayuda a comparar sin paralizarte" "muestra apoyo, colaboracion y senales externas" "ordena la energia para conservar lo importante" "senala una friccion util si se mira de frente" "recupera confianza mediante un gesto concreto" "obliga a priorizar y descartar fantasia" "acelera procesos que ya estaban preparados" "confirma autonomia, criterio y paciencia" "cierra una etapa para mostrar el resultado acumulado" "trae curiosidad, noticia o practica inicial" "empuja a explorar con deseo de experiencia" "cuida, integra y sostiene el aprendizaje" "decide, protege y dirige la energia del palo")
RANK_SHADOWS=("quedarse solo en la promesa sin iniciar nada" "sostener dos caminos para evitar elegir" "depender demasiado de aprobacion externa" "confundir descanso con cierre emocional" "convertir una dificultad en identidad" "dar o recibir sin equilibrio" "dispersarse entre posibilidades poco reales" "ir tan deprisa que no escuchas el contexto" "aislarse por orgullo o autosuficiencia" "cargar con mas de lo necesario" "actuar desde ingenuidad o reaccion" "confundir intensidad con direccion" "proteger tanto que no dejas fluir" "controlar por miedo a perder autoridad")
RANK_QUESTIONS=("Que oportunidad esta naciendo aqui" "Que necesito elegir con mas honestidad" "Con quien conviene compartir o contrastar esto" "Que debo estabilizar antes de avanzar" "Que conflicto muestra una necesidad ignorada" "Que gesto repara o equilibra la situacion" "Que opcion tiene hechos y cual solo deseo" "Que debe moverse ahora y que puede esperar" "Que aprendizaje ya puedo sostener sin ayuda" "Que ciclo pide cierre o descanso" "Que mensaje pequeno no debo ignorar" "Hacia donde se mueve mi energia realmente" "Que debo cuidar sin absorberlo todo" "Que decision madura me toca asumir")

echo "Generating 56 minor arcana pages..."
MINOR_GRID=""
MINOR_COUNT=0
for s in "${!SUIT_SLUGS[@]}"; do
  suit_slug="${SUIT_SLUGS[$s]}"
  suit_name="${SUIT_NAMES[$s]}"
  suit_element="${SUIT_ELEMENTS[$s]}"
  suit_area="${SUIT_AREAS[$s]}"
  suit_symbol="${SUIT_SYMBOLS[$s]}"
  suit_theme="${SUIT_THEMES[$s]}"
  suit_shadow="${SUIT_SHADOWS[$s]}"
  suit_action="${SUIT_ACTIONS[$s]}"
  suit_links=""

  for r in "${!RANK_SLUGS[@]}"; do
    rank_slug="${RANK_SLUGS[$r]}"
    rank_name="${RANK_NAMES[$r]}"
    rank_arc="${RANK_ARCS[$r]}"
    rank_light="${RANK_LIGHTS[$r]}"
    rank_shadow="${RANK_SHADOWS[$r]}"
    rank_question="${RANK_QUESTIONS[$r]}"
    slug="${rank_slug}-de-${suit_slug}"
    name="${rank_name} de ${suit_name}"
    path="/arcanos-menores/${slug}"
    title="${name} — Significado en el Tarot | Tarot del Día"
    desc="Significado de ${name}: interpretacion al derecho e invertida, consejo practico, amor, trabajo y pregunta de diario para tu tirada."
    suit_links+="<a class=\"tarot-card\" href=\"${path}\"><span class=\"tnum\">${suit_symbol}</span><span class=\"tname\">${name}</span><span class=\"tkeys\">${rank_arc} · ${suit_name}</span></a>"

    cat > "$PUBLIC/arcanos-menores/${slug}.html" <<ENDMINOR
<!DOCTYPE html>
<html lang="es">
<head>
$(gen_head "$title" "$desc" "$path" "minor_arcana_profile" "evergreen" "$slug")
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"Article","headline":"${name} — Significado en el Tarot","description":"${desc}","author":{"@type":"Organization","name":"Tarot del Día"},"publisher":{"@type":"Organization","name":"Tarot del Día","url":"https://${DOMAIN}/"},"mainEntityOfPage":"https://${DOMAIN}${path}","inLanguage":"es"}
  </script>
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Inicio","item":"https://${DOMAIN}/"},{"@type":"ListItem","position":2,"name":"Arcanos Menores","item":"https://${DOMAIN}/arcanos-menores"},{"@type":"ListItem","position":3,"name":"${name}","item":"https://${DOMAIN}${path}"}]}
  </script>
  <style>
${COMMON_CSS}
    .minor-hero{text-align:center;padding:1.6rem 0 1rem}
    .minor-hero .symbol{font-size:3rem;margin-bottom:.5rem}
    .meaning-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:1rem;margin:1rem 0}
    .meaning-card{background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:1rem;box-shadow:var(--shadow)}
    .meaning-card h2{font-size:1rem;color:var(--accent);margin-bottom:.4rem}
    .meaning-card p,.meaning-card li{color:var(--muted);font-size:.9rem;line-height:1.7}
    .next-links{display:flex;flex-wrap:wrap;gap:.55rem;justify-content:center;margin-top:1rem}
    .next-links a{display:inline-block;padding:.5rem .75rem;border:1px solid var(--border);border-radius:8px;background:var(--bg);color:var(--accent);text-decoration:none;font-size:.82rem;font-weight:700}
  </style>
</head>
<body>
<div class="container">
  <nav class="breadcrumb"><a href="/">Tarot del Día</a> › <a href="/arcanos-menores">Arcanos Menores</a> › ${name}</nav>
  <header class="minor-hero">
    <div class="symbol">${suit_symbol}</div>
    <h1><span>${name}</span></h1>
    <p style="color:var(--muted);font-size:.9rem">${suit_name} · elemento ${suit_element} · ${rank_arc}</p>
  </header>

  <section class="panel">
    <h2>Significado general</h2>
    <p>${name} combina el ${rank_arc} con el palo de ${suit_name}, asociado a ${suit_area}. En una tirada diaria, esta carta no se lee como sentencia: muestra una energia concreta que puedes observar en decisiones, vinculos, conversaciones o recursos durante las proximas horas.</p>
    <p>Su tema principal es ${suit_theme}. La lectura gana precision cuando preguntas donde aparece esta energia hoy y que accion pequena puedes tomar para responder con mas claridad.</p>
  </section>

  <div class="meaning-grid">
    <section class="meaning-card">
      <h2>Al derecho</h2>
      <p>${rank_light}. En el palo de ${suit_name}, esta energia se expresa a traves de ${suit_area}. Es una invitacion a actuar con presencia y comprobar los hechos antes de cerrar una conclusion.</p>
    </section>
    <section class="meaning-card">
      <h2>Invertida</h2>
      <p>${rank_shadow}. Tambien puede reflejar ${suit_shadow}. No indica fracaso: pide revisar si la energia esta bloqueada, exagerada o dirigida hacia un lugar que no responde a tu pregunta real.</p>
    </section>
  </div>

$(ad_block "🃏" "Espacio junto a Arcanos Menores" "Contexto evergreen para usuarios que estudian significados concretos del tarot." "Ver espacios →")

  <section class="panel">
    <h2>${name} en amor y vinculos</h2>
    <p>En preguntas afectivas, ${name} habla de como se mueve ${suit_area} dentro del vinculo. Si sale al derecho, observa que gesto confirma disponibilidad. Si aparece invertida, pregunta que expectativa o patron esta pesando mas que la realidad visible.</p>
  </section>

  <section class="panel">
    <h2>${name} en trabajo y decisiones</h2>
    <p>En trabajo, proyectos o dinero, esta carta pide traducir la intuicion a una accion verificable: ${suit_action}. Si la pregunta implica otras personas, separa hechos, interpretaciones y acuerdos pendientes antes de decidir.</p>
  </section>

  <section class="panel">
    <h2>Pregunta para tu diario</h2>
    <p><strong>${rank_question}?</strong></p>
    <p>Anota la pregunta, la orientacion de la carta y una accion concreta para hoy. Revisa al final del dia que ocurrio realmente; ese contraste mejora tus lecturas futuras mas que repetir la tirada.</p>
  </section>

  <div class="next-links">
    <a href="/arcanos-menores">Todos los Arcanos Menores</a>
    <a href="/arcanos-mayores">Arcanos Mayores</a>
    <a href="/">Tirada gratis</a>
  </div>

$(cluster_recirculation_block "$SITE_KEY")

$(gen_footer)
</div>
</body>
</html>
ENDMINOR

    SITEMAP_URLS+="  <url><loc>https://${DOMAIN}${path}</loc><lastmod>${TODAY}</lastmod><changefreq>monthly</changefreq><priority>0.7</priority></url>\n"
    MINOR_COUNT=$((MINOR_COUNT + 1))
  done

  MINOR_GRID+="<section class=\"panel\"><h2>${suit_symbol} ${suit_name}</h2><p>El palo de ${suit_name} trabaja ${suit_area}. Su sombra habitual es ${suit_shadow}.</p><div class=\"tarot-grid\">${suit_links}</div></section>"
done

cat > "$PUBLIC/arcanos-menores/index.html" <<ENDMINORHUB
<!DOCTYPE html>
<html lang="es">
<head>
$(gen_head "Los 56 Arcanos Menores del Tarot — Significados por Palo" "Guia completa de los 56 Arcanos Menores del tarot: Bastos, Copas, Espadas y Oros con interpretacion al derecho, invertida y consejo practico." "/arcanos-menores" "content_hub" "hub" "arcanos-menores")
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"CollectionPage","name":"Los 56 Arcanos Menores del Tarot","description":"Guia de significados de Bastos, Copas, Espadas y Oros.","url":"https://${DOMAIN}/arcanos-menores","inLanguage":"es"}
  </script>
  <style>
${COMMON_CSS}
    .intro{text-align:center;color:var(--muted);font-size:.92rem;line-height:1.6;max-width:680px;margin:0 auto 1.5rem}
    .tarot-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:1rem;margin:1rem 0}
    .tarot-card{background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:1rem;text-align:center;text-decoration:none;color:var(--text);box-shadow:var(--shadow)}
    .tarot-card:hover{transform:translateY(-2px)}
    .tarot-card .tnum{font-size:1.3rem;display:block}
    .tarot-card .tname{font-family:'Playfair Display',serif;font-weight:700;font-size:.95rem;display:block;margin:.35rem 0;color:var(--accent)}
    .tarot-card .tkeys{font-size:.72rem;color:var(--muted);line-height:1.4;display:block}
  </style>
</head>
<body>
<div class="container">
  <nav class="breadcrumb"><a href="/">Tarot del Día</a> › Arcanos Menores</nav>
  <h1>Los 56 <span>Arcanos Menores</span></h1>
  <p class="intro">Los Arcanos Menores aterrizan la lectura en escenas concretas: deseo, vinculos, conversaciones, recursos, trabajo y acciones del dia. Usa este indice para encontrar cada carta por palo y numero.</p>
  <section class="panel">
    <h2>Cómo leer los Arcanos Menores</h2>
    <p>Los palos muestran el area de experiencia y los numeros describen el momento del proceso. Un As inicia, un Cinco tensiona, un Diez culmina; las figuras muestran formas de aprender, moverse, cuidar o dirigir esa energia.</p>
    <p>En una tirada diaria, los Arcanos Menores suelen responder mejor a preguntas practicas: que conversacion preparar, que recurso revisar, donde poner energia o que limite cuidar. Por eso cada ficha incluye una pregunta de diario y una accion concreta.</p>
  </section>
  ${MINOR_GRID}
$(cluster_recirculation_block "$SITE_KEY")
$(gen_footer)
</div>
</body>
</html>
ENDMINORHUB

SITEMAP_URLS+="  <url><loc>https://${DOMAIN}/arcanos-menores</loc><lastmod>${TODAY}</lastmod><changefreq>monthly</changefreq><priority>0.8</priority></url>\n"
echo "  ✓ ${MINOR_COUNT} minor arcana pages and hub"

# ── Intent landing pages ─────────────────────────────────────
gen_intent_page() {
  local slug="$1" title="$2" desc="$3" h1="$4" intro="$5" focus="$6" spread="$7" reading="$8" caution="$9" faq_question="${10}" faq_answer="${11}"
  local path="/${slug}"

  cat > "$PUBLIC/${slug}.html" <<ENDINTENT
<!DOCTYPE html>
<html lang="es">
<head>
$(gen_head "$title" "$desc" "$path" "intent_landing" "evergreen" "$slug")
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"Article","headline":"${h1}","description":"${desc}","author":{"@type":"Organization","name":"Tarot del Día"},"publisher":{"@type":"Organization","name":"Tarot del Día","url":"https://${DOMAIN}/"},"mainEntityOfPage":"https://${DOMAIN}${path}","inLanguage":"es"}
  </script>
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":"${faq_question}","acceptedAnswer":{"@type":"Answer","text":"${faq_answer}"}},{"@type":"Question","name":"¿Puedo repetir la tirada varias veces?","acceptedAnswer":{"@type":"Answer","text":"Conviene hacer una sola tirada por pregunta. Si necesitas más claridad, cambia el enfoque hacia una acción concreta o una conversación pendiente."}}]}
  </script>
  <style>
${COMMON_CSS}
    .intent-hero{text-align:center;padding:1.5rem 0 1rem}
    .intent-hero p{max-width:680px;margin:.75rem auto 0;color:var(--muted);line-height:1.7;font-size:.94rem}
    .intent-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:1rem;margin:1.4rem 0}
    .intent-card{background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:1rem;box-shadow:var(--shadow)}
    .intent-card h2{font-size:1rem;margin-bottom:.45rem;color:var(--accent)}
    .intent-card p,.intent-card li{color:var(--muted);font-size:.9rem;line-height:1.7}
    .intent-card ul{padding-left:1.15rem}
    .intent-links{display:flex;flex-wrap:wrap;gap:.55rem;margin-top:.9rem}
    .intent-links a{display:inline-block;padding:.5rem .7rem;border-radius:8px;border:1px solid var(--border);background:var(--bg);color:var(--accent);text-decoration:none;font-size:.82rem;font-weight:700}
  </style>
</head>
<body>
<div class="container">
  <nav class="breadcrumb"><a href="/">Tarot del Día</a> › ${h1}</nav>
  <header class="intent-hero">
    <div style="font-size:.75rem;letter-spacing:.15em;text-transform:uppercase;color:var(--accent);font-weight:600">Guía de tirada</div>
    <h1><span>${h1}</span></h1>
    <p>${intro}</p>
  </header>

  <div class="intent-grid">
    <section class="intent-card">
      <h2>Antes de preguntar</h2>
      <p>${focus}</p>
    </section>
    <section class="intent-card">
      <h2>Tirada recomendada</h2>
      <p>${spread}</p>
    </section>
    <section class="intent-card">
      <h2>Cómo interpretar la respuesta</h2>
      <p>${reading}</p>
    </section>
  </div>

$(ad_block "🔮" "Espacio contextual en guías de tarot" "Usuarios con intención concreta antes de hacer una tirada diaria." "Ver espacios →")

  <section class="panel">
    <h2>Lectura responsable</h2>
    <p>${caution}</p>
    <p>El tarot funciona mejor como herramienta de reflexión: ayuda a nombrar patrones, preparar decisiones y detectar qué parte de una situación pide más atención. No sustituye asesoramiento profesional, legal, médico o financiero.</p>
  </section>

  <section class="panel">
    <h2>Continúa tu lectura</h2>
    <p>Después de leer esta guía, puedes hacer la tirada interactiva del día o revisar el significado de cada carta para interpretar mejor el mensaje.</p>
    <div class="intent-links">
      <a href="/">Hacer tirada de 3 cartas</a>
      <a href="/arcanos-mayores">Ver Arcanos Mayores</a>
      <a href="https://carta-astral-gratis.es/">Calcular carta astral</a>
    </div>
  </section>

$(cluster_recirculation_block "$SITE_KEY")

$(gen_footer)
</div>
</body>
</html>
ENDINTENT

  SITEMAP_URLS+="  <url><loc>https://${DOMAIN}${path}</loc><lastmod>${TODAY}</lastmod><changefreq>monthly</changefreq><priority>0.8</priority></url>\n"
  PAGE_COUNT=$((PAGE_COUNT + 1))
}

echo "Generating intent landing pages..."
gen_intent_page "tarot-amor" \
  "Tarot del Amor Gratis — Tirada y Consejos para Relaciones" \
  "Guía de tarot del amor gratis: cómo preguntar por una relación, qué cartas observar y cómo interpretar una tirada afectiva sin caer en dependencia." \
  "Tarot del Amor" \
  "El tarot del amor sirve para ordenar emociones, revisar expectativas y entender qué dinámica está activa en una relación, una ruptura o una atracción nueva." \
  "Formula una pregunta que dependa de tu claridad, no del control sobre otra persona. Mejor que preguntar si alguien volverá, pregunta qué necesitas comprender, qué límite cuidar o qué conversación preparar." \
  "Usa tres cartas: situación emocional, necesidad real y siguiente paso. Si sale una carta invertida, léela como una energía bloqueada o una señal de que conviene ir más despacio." \
  "Las cartas de Copas suelen hablar de vínculo y sensibilidad; Bastos, de deseo e impulso; Espadas, de conversación y conflicto mental; Oros, de estabilidad y hechos concretos. En Arcanos Mayores, presta atención a Enamorados, Emperatriz, Diablo, Templanza y Torre." \
  "En temas afectivos evita usar el tarot para vigilar, insistir o justificar una relación que te daña. Si la tirada marca tensión, conviértela en una acción observable: pedir claridad, bajar expectativas o proteger tu descanso." \
  "¿Qué carta del tarot habla más de amor?" \
  "Los Enamorados es la carta más directa para decisiones afectivas, pero la Emperatriz, el Sol, la Templanza y el Dos de Copas también pueden señalar apertura, cuidado y reciprocidad."

gen_intent_page "tarot-trabajo" \
  "Tarot del Trabajo Gratis — Tirada para Decisiones Laborales" \
  "Guía de tarot del trabajo gratis: preguntas útiles para empleo, proyectos, entrevistas y cambios profesionales con una lectura práctica de 3 cartas." \
  "Tarot del Trabajo" \
  "El tarot aplicado al trabajo ayuda a mirar decisiones profesionales con más distancia: entrevistas, cambios de puesto, proyectos, conflictos de equipo o dudas sobre continuidad." \
  "Haz preguntas que terminen en una acción: qué debo preparar para esta entrevista, qué riesgo no estoy viendo, qué recurso profesional puedo usar mejor o qué conversación conviene tener." \
  "Prueba una tirada de tres cartas: contexto actual, obstáculo principal y movimiento recomendable. Si la tercera carta es de Espadas, prioriza comunicación; si es de Oros, baja la decisión a números, tiempos y condiciones." \
  "El Mago favorece iniciativa y habilidades; la Justicia pide contratos claros; el Carro marca avance con disciplina; el Ermitaño sugiere análisis; la Rueda habla de cambio de ciclo. Ninguna carta reemplaza revisar datos, plazos y compromisos reales." \
  "No uses una tirada para delegar decisiones importantes. Cruza el mensaje con información verificable: salario, condiciones, carga de trabajo, salud, responsabilidades y alternativas disponibles." \
  "¿Sirve el tarot para decidir si cambiar de trabajo?" \
  "Puede servir como herramienta de reflexión, siempre que la lectura se combine con datos concretos: condiciones, estabilidad, objetivos, salud y oportunidades reales."

gen_intent_page "tarot-si-o-no" \
  "Tarot Sí o No Gratis — Cómo Interpretar una Respuesta Clara" \
  "Aprende a hacer una tirada de tarot sí o no: cómo formular la pregunta, cuándo evitarla y cómo leer cartas afirmativas, negativas o condicionales." \
  "Tarot Sí o No" \
  "El tarot sí o no es útil para preguntas simples, pero gana valor cuando la respuesta incluye una condición: qué favorece el sí, qué activa el no y qué puedes hacer ahora." \
  "Evita preguntas ambiguas o cargadas de ansiedad. Una buena pregunta tiene una acción y un marco temporal: ¿me conviene enviar este mensaje esta semana?, ¿es buen momento para aceptar esta propuesta?" \
  "Para una respuesta rápida, saca una carta: al derecho indica energía favorable y al revés pide cautela. Para más matiz, usa tres cartas: sí, no y condición. La carta de condición es la más importante." \
  "Sol, Mundo, Estrella, Carro y As de Bastos suelen inclinar hacia un sí. Torre, Diablo, Cinco de Espadas o Luna pueden pedir pausa, revisión o un no temporal. Cartas como Templanza o Colgado responden: todavía no, ajusta el enfoque." \
  "Si repites la misma pregunta hasta conseguir la respuesta que quieres, la tirada pierde utilidad. Anota la primera respuesta y tradúcela a una decisión pequeña, concreta y reversible." \
  "¿El tarot sí o no siempre responde de forma cerrada?" \
  "No siempre. Muchas cartas responden con condiciones: sí si actúas con claridad, no si mantienes el mismo patrón, o espera hasta tener más información."
echo "  ✓ intent landing pages generated"

# ══════════════════════════════════════════════════════════════
# INDEX — Interactive 3-card spread
# ══════════════════════════════════════════════════════════════
echo "Generating index with interactive spread..."

# Build JS card data (major arcana only for the spread)
JS_CARDS="["
for i in "${!MAJOR_SLUGS[@]}"; do
  (( i > 0 )) && JS_CARDS+=","
  JS_CARDS+="{n:\"${MAJOR_NAMES[$i]}\",num:\"${MAJOR_NUMS[$i]}\",slug:\"${MAJOR_SLUGS[$i]}\",keys:\"${MAJOR_KEYS[$i]}\",up:\"${MAJOR_UPRIGHT[$i]}\",rev:\"${MAJOR_REVERSED[$i]}\"}"
done
JS_CARDS+="]"

INDEX_TITLE="Tarot del Día Gratis — Tirada de 3 Cartas"
INDEX_DESC="Haz tu tarot del día gratis con una tirada de 3 cartas. Descubre el mensaje del pasado, presente y futuro con interpretación inmediata."

cat > "$PUBLIC/index.html" <<'ENDINDEX_START'
<!DOCTYPE html>
<html lang="es">
<head>
ENDINDEX_START

gen_head "$INDEX_TITLE" "$INDEX_DESC" "/" "tool_home" "tool" >> "$PUBLIC/index.html"

cat >> "$PUBLIC/index.html" <<ENDINDEX
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"WebSite","name":"Tarot del Día","url":"https://${DOMAIN}/","description":"Tirada de tarot gratis del día con los 22 Arcanos Mayores.","inLanguage":"es"}
  </script>
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":"¿Cómo funciona la tirada de tarot gratis?","acceptedAnswer":{"@type":"Answer","text":"Concéntrate en tu pregunta, pulsa en 3 cartas del mazo y recibe una lectura integrada que relaciona pasado, presente, futuro, orientación de cada carta y tendencia general."}},{"@type":"Question","name":"¿Cuántas veces puedo tirar las cartas?","acceptedAnswer":{"@type":"Answer","text":"Puedes hacer una tirada al día para obtener la mejor guía. Repetir la misma pregunta diluye la energía de la lectura."}},{"@type":"Question","name":"¿Es fiable el tarot por internet?","acceptedAnswer":{"@type":"Answer","text":"El tarot es una herramienta de reflexión e introspección. La selección aleatoria de cartas funciona como espejo de tu subconsciente, igual que en una tirada presencial."}}]}
  </script>
  <style>
${COMMON_CSS}
    .intro{text-align:center;color:var(--muted);font-size:.92rem;line-height:1.6;max-width:620px;margin:0 auto 1.5rem}
    .spread-area{text-align:center;margin:1.5rem 0}
    .ritual-panel{background:linear-gradient(135deg,#fff 0%,#f3eeff 56%,#fef9ee 100%);border:1px solid var(--border);border-radius:18px;padding:1.25rem;box-shadow:var(--shadow);margin:0 auto 1.2rem;max-width:720px}
    .ritual-panel h2{font-size:1.05rem;margin-bottom:.35rem}
    .ritual-panel p{color:var(--muted);font-size:.88rem;line-height:1.65;margin:0 auto .9rem;max-width:560px}
    .intention-row{display:grid;grid-template-columns:1fr auto;gap:.7rem;align-items:center;margin:.8rem auto 0;max-width:620px}
    .intention-row input{width:100%;min-height:44px;border:1px solid var(--border);border-radius:10px;background:#fff;color:var(--text);font:inherit;font-size:.9rem;padding:.7rem .85rem;box-shadow:inset 0 1px 0 rgba(255,255,255,.8)}
    .intention-row input:focus{outline:2px solid rgba(124,58,237,.22);border-color:rgba(124,58,237,.48)}
    .shuffle-btn{min-height:44px;border:0;border-radius:10px;background:var(--accent);color:#fff;font:inherit;font-size:.88rem;font-weight:700;padding:.72rem 1rem;cursor:pointer;box-shadow:0 8px 20px rgba(124,58,237,.22);transition:transform .18s,box-shadow .18s,background .18s}
    .shuffle-btn:hover{transform:translateY(-1px);box-shadow:0 12px 26px rgba(124,58,237,.28);background:#6d28d9}
    .shuffle-btn:disabled{opacity:.7;cursor:default;transform:none}
    .draw-status{font-size:.84rem;color:var(--accent);font-weight:700;margin:.95rem 0 .4rem;min-height:1.4rem}
    .deck-wrap{margin:1rem auto 1.4rem;max-width:760px;min-height:178px;padding:1rem .75rem;border:1px solid var(--border);border-radius:18px;background:radial-gradient(ellipse at center,rgba(245,217,139,.22),transparent 58%),linear-gradient(135deg,#fff 0%,#f8f4ff 100%);box-shadow:var(--shadow);overflow:hidden}
    .deck{--gap:26px;position:relative;height:150px;max-width:680px;margin:0 auto}
    .deck.locked{opacity:.46;filter:saturate(.75)}
    .deck.locked .card-back{pointer-events:none}
    .deck .card-back{position:absolute;left:50%;bottom:8px;width:72px;height:118px;background:radial-gradient(circle at 50% 26%,rgba(245,217,139,.24),transparent 30%),linear-gradient(145deg,#17213f 0%,#2c1b56 58%,#101624 100%);border-radius:12px;cursor:pointer;display:flex;align-items:center;justify-content:center;color:#f5d98b;font-size:1.5rem;transition:transform .22s,border-color .22s,box-shadow .22s,opacity .22s;border:1px solid rgba(245,217,139,.5);box-shadow:0 8px 18px rgba(17,24,39,.25);transform:translateX(calc(-50% + (var(--offset) * var(--gap)))) translateY(calc(var(--arc) * 1px)) rotate(calc(var(--offset) * 2.15deg));z-index:var(--z)}
    .deck .card-back::before{content:"";position:absolute;inset:9px;border:1px solid rgba(245,217,139,.45);border-radius:8px}
    .deck .card-back::after{content:"";width:18px;height:30px;border:1px solid rgba(245,217,139,.75);border-radius:2px;background:repeating-linear-gradient(90deg,transparent 0 3px,rgba(245,217,139,.55) 3px 4px),repeating-linear-gradient(0deg,transparent 0 3px,rgba(245,217,139,.55) 3px 4px)}
    .deck .card-back span{display:none}
    .deck.ready .card-back:hover{transform:translateX(calc(-50% + (var(--offset) * var(--gap)))) translateY(calc((var(--arc) * 1px) - 12px)) rotate(calc(var(--offset) * 2.15deg));border-color:#f5d98b;box-shadow:0 14px 28px rgba(17,24,39,.32)}
    .deck .card-back.picked{opacity:.18;pointer-events:none;transform:translateX(calc(-50% + (var(--offset) * var(--gap)))) translateY(18px) rotate(calc(var(--offset) * 2.15deg))}
    .chosen{display:flex;gap:1rem;justify-content:center;margin:1.4rem 0 1.1rem;flex-wrap:wrap}
    .chosen .slot{width:146px;min-height:192px;border:2px dashed var(--border);border-radius:14px;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:.85rem;transition:all .3s;background:rgba(255,255,255,.72)}
    .chosen .slot.filled{border:1px solid rgba(245,217,139,.65);background:linear-gradient(145deg,#17213f 0%,#35215e 62%,#111827 100%);color:#f8edd0;box-shadow:0 12px 26px rgba(17,24,39,.22)}
    .chosen .slot .pos{font-size:.7rem;text-transform:uppercase;letter-spacing:.08em;color:var(--muted);margin-bottom:.3rem}
    .chosen .slot.filled .pos{color:#c084fc}
    .chosen .slot .cname{font-family:'Playfair Display',serif;font-size:.85rem;font-weight:700;margin:.3rem 0}
    .chosen .slot .cnum{font-size:.7rem;opacity:.7}
    .chosen .slot .reversed-tag{font-size:.65rem;color:#f97316;margin-top:.2rem}
    .result{display:none;margin:1.5rem 0}
    .result.show{display:block}
    .result .reading{background:var(--surface);border:1px solid var(--border);border-radius:16px;padding:1.5rem;margin:.8rem 0;box-shadow:var(--shadow)}
    .result .reading h3{font-family:'Playfair Display',serif;font-size:1rem;margin-bottom:.5rem;color:var(--accent)}
    .result .reading p{line-height:1.7;color:var(--muted);font-size:.9rem}
    .result .reading .link{display:inline-block;margin-top:.5rem;color:var(--accent);text-decoration:none;font-size:.85rem;font-weight:500}
    .result .reading-main{background:linear-gradient(135deg,#fff 0%,#f8f4ff 62%,#fff8e7 100%)}
    .result .reading-main h2{font-family:'Playfair Display',serif;font-size:1.35rem;margin-bottom:.75rem;color:var(--text)}
    .result .reading-main h3{margin-top:1rem}
    .question-pill{display:inline-block;margin-bottom:.85rem;padding:.45rem .7rem;border-radius:999px;background:#f3eeff;color:var(--accent);font-size:.82rem;font-weight:700}
    .reading-summary{font-size:1rem!important;color:var(--text)!important}
    .card-strip{display:grid;grid-template-columns:repeat(3,1fr);gap:.65rem;margin:1rem 0}
    .mini-card{border:1px solid var(--border);border-radius:12px;padding:.75rem;background:rgba(255,255,255,.78)}
    .mini-card strong{display:block;font-family:'Playfair Display',serif;font-size:.95rem;color:var(--text)}
    .mini-card span{display:block;margin-top:.25rem;color:var(--muted);font-size:.78rem}
    .reading-actions{margin:.95rem 0 0;padding-left:1.1rem;color:var(--muted);font-size:.9rem;line-height:1.65}
    .reading-actions li{margin:.35rem 0}
    .arcana-links{display:flex;gap:.5rem;flex-wrap:wrap;margin-top:1rem}
    .arcana-links a{display:inline-block;padding:.45rem .65rem;border-radius:999px;background:#f8f4ff;color:var(--accent);text-decoration:none;font-size:.78rem;font-weight:700}
    .btn-reset{margin-top:1rem;padding:.5rem 1.5rem;background:var(--bg);color:var(--accent);border:1px solid var(--border);border-radius:10px;font-weight:600;cursor:pointer;font-family:inherit;font-size:.85rem}
    .result-deeper{margin:1rem 0 0;padding:1.15rem;border-radius:14px;border:1px solid var(--border);background:linear-gradient(135deg,#fff 0%,#fef9ee 100%);text-align:center}
    .result-deeper h3{font-family:'Playfair Display',serif;font-size:1.02rem;margin-bottom:.35rem}
    .result-deeper p{color:var(--muted);font-size:.88rem;line-height:1.6;margin-bottom:.75rem}
    .result-deeper a{display:inline-block;padding:.58rem 1rem;border-radius:10px;background:var(--accent);color:#fff;text-decoration:none;font-size:.84rem;font-weight:700}
    .intent-nav{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:.75rem;margin:1.2rem 0}
    .intent-nav a{display:block;text-decoration:none;color:var(--text);background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:.9rem;box-shadow:var(--shadow)}
    .intent-nav strong{display:block;color:var(--accent);font-size:.9rem;margin-bottom:.25rem}
    .intent-nav span{display:block;color:var(--muted);font-size:.78rem;line-height:1.45}
    .seo-text{margin:2rem 0}
    .seo-text h2{font-size:1.1rem;margin:1.2rem 0 .5rem}
    .seo-text p{line-height:1.7;color:var(--muted);font-size:.9rem;margin-bottom:.5rem}
    @media(max-width:640px){
      .intention-row{grid-template-columns:1fr}
      .chosen{gap:.7rem}
      .chosen .slot{width:31%;min-width:96px;min-height:154px;padding:.65rem}
      .deck-wrap{min-height:152px;padding:.75rem .45rem}
      .deck{--gap:13px;height:128px}
      .deck .card-back{width:58px;height:96px;border-radius:10px}
      .deck .card-back::after{width:14px;height:24px}
      .card-strip{grid-template-columns:1fr}
    }
  </style>
</head>
<body>
<div class="container">
  <header style="text-align:center;padding:1.5rem 0 .5rem">
    <div style="font-size:.75rem;letter-spacing:.15em;text-transform:uppercase;color:var(--accent);font-weight:600">Tarot</div>
    <h1><span>Tarot del Día</span></h1>
    <p class="intro">Respira, formula una intención para el día y elige tus cartas cuando el mazo ya esté barajado. La lectura combina símbolo, posición y una acción concreta para hoy.</p>
  </header>

  <div class="spread-area">
    <section class="ritual-panel" aria-labelledby="ritual-title">
      <h2 id="ritual-title">Relájate antes de elegir</h2>
      <p>Piensa en una situación concreta de hoy. Baraja el mazo y elige las tres cartas que te llamen sin buscar una respuesta perfecta.</p>
      <div class="intention-row">
        <input id="intention" type="text" maxlength="120" placeholder="Intención opcional: qué necesito ver hoy">
        <button class="shuffle-btn" id="shuffleBtn" type="button">Barajar cartas</button>
      </div>
    </section>
    <p class="draw-status" id="instruction">Baraja para activar la tirada</p>
    <div class="chosen">
      <div class="slot" id="slot0"><span class="pos">Pasado</span><span style="font-size:1.5rem;color:var(--border)">?</span></div>
      <div class="slot" id="slot1"><span class="pos">Presente</span><span style="font-size:1.5rem;color:var(--border)">?</span></div>
      <div class="slot" id="slot2"><span class="pos">Futuro</span><span style="font-size:1.5rem;color:var(--border)">?</span></div>
    </div>
    <div class="deck-wrap" aria-label="Mazo de tarot barajado">
      <div class="deck locked" id="deck"></div>
    </div>
  </div>

$(ad_block "🔮" "¿Quieres llegar a usuarios que consultan tarot hoy?" "Espacio visible entre la tirada interactiva y la lectura, con contexto perfecto para conversión." "Ver espacios y tarifas →")

  <div class="result" id="result"></div>

  <div class="cta-box">
    <h3>🌟 Profundiza con tu carta astral</h3>
    <p>Descubre cómo los planetas de tu carta natal están influenciando estos mensajes del tarot.</p>
    <a href="https://carta-astral-gratis.es/">Calcular mi carta astral gratis →</a>
  </div>

  <div class="panel" style="text-align:center">
    <h2>Explora los Arcanos</h2>
    <p><a href="/arcanos-mayores" style="color:var(--accent);font-weight:600;text-decoration:none">Ver los 22 Arcanos Mayores →</a></p>
    <p style="margin-top:.45rem"><a href="/arcanos-menores" style="color:var(--accent);font-weight:600;text-decoration:none">Ver los 56 Arcanos Menores →</a></p>
  </div>

  <section class="panel">
    <h2>Lecturas de tarot por intención</h2>
    <div class="intent-nav">
      <a href="/tarot-amor"><strong>Tarot del amor</strong><span>Preguntas para relaciones, rupturas y vínculos nuevos.</span></a>
      <a href="/tarot-trabajo"><strong>Tarot del trabajo</strong><span>Guía para entrevistas, proyectos y cambios profesionales.</span></a>
      <a href="/tarot-si-o-no"><strong>Tarot sí o no</strong><span>Cómo formular preguntas cerradas sin perder matiz.</span></a>
      <a href="/guia-tarot"><strong>Guía de lectura</strong><span>Método responsable para formular preguntas e interpretar resultados.</span></a>
    </div>
  </section>

  <div class="seo-text panel">
    <h2>¿Qué es el Tarot del Día?</h2>
    <p>El tarot del día es una tirada rápida de 3 cartas que te ofrece una guía para las próximas horas. Las tres posiciones (Pasado, Presente y Futuro) te ayudan a comprender de dónde vienes, dónde estás y hacia dónde te diriges.</p>
    <p>No está pensado para tomar decisiones por ti, sino para ordenar la intuición. Si una carta señala tensión, úsala para detectar dónde necesitas más claridad; si señala apertura, pregúntate qué oportunidad concreta puedes aprovechar hoy.</p>
    <p>La lectura funciona mejor si partes de una pregunta sencilla y verificable. En vez de preguntar qué ocurrirá en general, prueba con qué necesito ver hoy, qué actitud me ayuda o qué bloqueo conviene reconocer.</p>

    <h2>¿Cómo hacer una tirada de tarot gratis?</h2>
    <p>Relájate, formula mentalmente tu pregunta o intención. Baraja y pulsa en 3 cartas del mazo para revelarlas. Cada carta puede salir al derecho (energía fluida) o invertida (energía bloqueada o interiorizada). La lectura integra posición, orientación y relación entre cartas para darte un mensaje completo.</p>

    <h2>Los 22 Arcanos Mayores</h2>
    <p>Los Arcanos Mayores son las 22 cartas más poderosas del tarot. Representan arquetipos universales que reflejan las grandes lecciones y transiciones de la vida. Desde El Loco (el inicio del viaje) hasta El Mundo (la completud), cada arcano contiene una sabiduría ancestral que trasciende culturas y épocas.</p>
    <p>En una lectura diaria, los Arcanos Mayores suelen señalar temas de fondo más que detalles menores. Hablan de decisiones, cierres, aprendizajes, deseos, bloqueos y cambios de perspectiva. Por eso conviene leerlos despacio y relacionarlos con una situación concreta, no como frases aisladas.</p>

    <h2>Tarot y astrología</h2>
    <p>Cada Arcano Mayor está conectado con un signo zodiacal o planeta. Por eso, combinar tu <a href="https://carta-astral-gratis.es/">carta astral</a> con el tarot te da una perspectiva mucho más rica. La <a href="https://compatibilidad-signos.es/">compatibilidad de signos</a> también puede enriquecer las lecturas sobre relaciones.</p>
    <p>Si conoces tu carta natal, compara la carta que sale con los temas activos de tu Sol, Luna y Ascendente. Esa lectura cruzada permite distinguir si el mensaje habla de identidad, emoción, vínculo, acción o comunicación.</p>
    <p>Después de la tirada, guarda una nota breve con la pregunta, las cartas y lo que ocurrió durante el día. Con el tiempo podrás distinguir mejor cuándo una carta habla de un hecho externo y cuándo refleja un estado interno que conviene ordenar.</p>
    <p>La tirada gana precisión cuando no repites la misma pregunta varias veces. Si necesitas más claridad, cambia el enfoque: pregunta qué puedes observar, qué recurso tienes disponible o qué conversación conviene preparar.</p>
  </div>

$(ad_block "✨" "Patrocina espacios de alta afinidad" "Venta directa: más control, más recuerdo de marca y mayor contexto editorial." "Ver espacios →")

$(cluster_recirculation_block "$SITE_KEY")

$(gen_footer)
</div>

<script>
(function(){
  const CARDS=${JS_CARDS};
  const POS=['Pasado','Presente','Futuro'];
  let chosen=[];
  let started=false;
  let isShuffled=false;
  let shuffled=[];
  const deck=document.getElementById('deck');
  const instruction=document.getElementById('instruction');
  const shuffleBtn=document.getElementById('shuffleBtn');
  const intention=document.getElementById('intention');

  function shuffleIndexes(){
    return [...Array(CARDS.length).keys()].sort(()=>Math.random()-.5);
  }

  function renderDeck(){
    deck.innerHTML='';
    const middle=(shuffled.length-1)/2;
    shuffled.forEach((ci,i)=>{
      const offset=i-middle;
      const el=document.createElement('button');
      el.type='button';
      el.setAttribute('aria-label','Carta boca abajo');
      el.className='card-back';
      el.innerHTML='<span>🂠</span>';
      el.dataset.idx=ci;
      el.style.setProperty('--offset',offset.toFixed(2));
      el.style.setProperty('--arc',Math.abs(offset*.95).toFixed(1));
      el.style.setProperty('--z',String(i+1));
      el.addEventListener('click',()=>pickCard(el,ci));
      deck.appendChild(el);
    });
  }

  function activateDeck(){
    if(chosen.length)return;
    shuffled=shuffleIndexes();
    isShuffled=true;
    renderDeck();
    deck.classList.remove('locked');
    deck.classList.add('ready');
    shuffleBtn.textContent='Mazo barajado';
    shuffleBtn.disabled=true;
    instruction.textContent='Elige 3 cartas escuchando tu intuición';
    if(window.clusterTrack)window.clusterTrack('tarot_deck_shuffle',{tool_action:'shuffle'});
  }

  shuffled=shuffleIndexes();
  renderDeck();
  shuffleBtn.addEventListener('click',activateDeck);

  function pickCard(el,ci){
    if(!isShuffled){
      instruction.textContent='Primero baraja el mazo';
      return;
    }
    if(chosen.length>=3)return;
    if(!started){
      started=true;
      if(window.clusterTrack)window.clusterTrack('tool_start',{tool_action:'tarot_draw_start'});
    }
    el.classList.add('picked');
    const isReversed=Math.random()<.35;
    const card={...CARDS[ci],reversed:isReversed};
    chosen.push(card);
    const remaining=3-chosen.length;
    const slot=document.getElementById('slot'+chosen.length-1+'')||document.getElementById('slot'+(chosen.length-1));
    slot.classList.add('filled');
    slot.innerHTML='<span class="pos">'+POS[chosen.length-1]+'</span><span class="cnum">'+card.num+'</span><span class="cname">'+card.n+'</span>'+(isReversed?'<span class="reversed-tag">↕ Invertida</span>':'');
    instruction.textContent=remaining>0?'Faltan '+remaining+' carta'+(remaining===1?'':'s'):'Tu lectura está lista';
    if(chosen.length===3)showResult();
  }

  function escapeHtml(value){
    return String(value||'').replace(/[<>&"]/g,(ch)=>({'<':'&lt;','>':'&gt;','&':'&amp;','"':'&quot;'}[ch]));
  }

  function cardLabel(c){
    return c.n+' ('+c.num+')'+(c.reversed?' invertida':'');
  }

  function cardEnergy(c){
    return c.reversed?c.rev:c.up;
  }

  function detectContext(question){
    const q=question.toLowerCase();
    if(/pareja|amor|relaci[oó]n|ex|matrimonio|crisis|ruptura|volver|sentimientos/.test(q))return 'amor';
    if(/trabajo|empleo|dinero|proyecto|negocio|cliente|carrera|empresa/.test(q))return 'trabajo';
    return 'general';
  }

  function contextName(ctx){
    return ctx==='amor'?'este vínculo':ctx==='trabajo'?'esta situación profesional':'esta situación';
  }

  function contextLens(ctx){
    if(ctx==='amor')return 'En una lectura afectiva, no conviene mirar solo si una carta es positiva o difícil: importa si abre diálogo, si muestra bloqueo, si habla de confianza o si señala una salida realista.';
    if(ctx==='trabajo')return 'En una lectura profesional, las cartas señalan el clima de decisión: qué patrón viene de antes, qué recurso está activo ahora y hacia dónde puede moverse el asunto si actúas con claridad.';
    return 'La tirada no describe un destino cerrado: muestra un patrón, una energía activa y una tendencia probable si sigues moviéndote desde el mismo lugar.';
  }

  function orientationTone(c){
    return c.reversed?'aparece invertida, así que su energía no fluye limpia: puede vivirse como bloqueo, exceso, miedo o resistencia':'aparece al derecho, así que su energía está disponible de forma más clara y aprovechable';
  }

  function positionReading(c,i,ctx){
    const subject=contextName(ctx);
    if(i===0){
      return 'En el pasado, '+cardLabel(c)+' indica que '+subject+' viene condicionado por '+cardEnergy(c)+'. Al estar en la raíz de la tirada, no habla solo de algo que ocurrió: muestra el patrón que todavía pesa en la forma de mirar el presente. La carta '+orientationTone(c)+'.';
    }
    if(i===1){
      return 'En el presente, '+cardLabel(c)+' describe la energía que está actuando ahora mismo: '+cardEnergy(c)+'. Esta es la carta central de la lectura, por eso conviene leerla como el punto de decisión. Lo que hagas ahora debe responder a esta carta, no a la ansiedad del pasado ni a una promesa futura.';
    }
    return 'En el futuro, '+cardLabel(c)+' marca la tendencia si integras el aprendizaje de las dos primeras cartas. Su mensaje principal es '+cardEnergy(c)+'. No lo leas como sentencia: es la dirección probable cuando el patrón del pasado se reconoce y la energía del presente se maneja con conciencia.';
  }

  function flowReading(cards,ctx){
    const revCount=cards.filter(c=>c.reversed).length;
    const names=cards.map(cardLabel);
    let tone='La secuencia '+names[0]+' → '+names[1]+' → '+names[2]+' cuenta una evolución, no tres respuestas separadas. ';
    if(revCount===0){
      tone+='Las tres cartas salen al derecho, así que la tirada tiene continuidad: hay margen para actuar sin sentir que todo está bloqueado.';
    }else if(revCount===1){
      tone+='Solo una carta sale invertida: ese es el nudo de la lectura. Las otras dos muestran desde dónde puedes compensarlo y hacia dónde puede abrirse la situación.';
    }else if(revCount===2){
      tone+='Dos cartas invertidas señalan tensión interna o resistencia: la salida existe, pero requiere cambiar la forma de responder, no solo esperar un resultado externo.';
    }else{
      tone+='Las tres cartas invertidas piden pausa y honestidad. Antes de empujar una respuesta, conviene detectar qué miedo, apego o patrón repetido está mandando.';
    }
    if(ctx==='amor'){
      tone+=' En pareja, esto suele hablar de dinámica entre dos personas: lo que se arrastra, lo que se calla o se expresa ahora, y la posibilidad real de recomponer o cerrar con más claridad.';
    }
    return tone;
  }

  function practicalActions(cards,ctx){
    const center=cards[1];
    const future=cards[2];
    const subject=contextName(ctx);
    const first=ctx==='amor'?'Ten una conversación breve y concreta: habla de lo que necesitas, no de lo que la otra persona "debería" adivinar.':'Elige una acción pequeña que puedas hacer hoy sin esperar a tener certeza total.';
    return [
      first,
      'Usa la carta del presente, '+cardLabel(center)+', como brújula: trabaja '+cardEnergy(center)+' de forma consciente.',
      'No fuerces el resultado de '+subject+'; orienta tus decisiones hacia '+cardEnergy(future)+', que es la tendencia que la tirada muestra como salida.'
    ];
  }

  function showResult(){
    instruction.textContent='Tu lectura está lista';
    const res=document.getElementById('result');
    let html='';
    const intentionValue=(intention.value||'').trim();
    const ctx=detectContext(intentionValue);
    if(window.clusterTrack){
      window.clusterTrack('tarot_reading_complete',{
        cards_chosen:String(chosen.length),
        first_card:chosen[0]?.slug||'',
        second_card:chosen[1]?.slug||'',
        third_card:chosen[2]?.slug||''
      });
    }
    html+='<div class="reading reading-main">';
    if(intentionValue){
      html+='<span class="question-pill">Intención: '+escapeHtml(intentionValue)+'</span>';
    }
    html+='<h2>Lectura completa de tu tirada</h2>';
    html+='<p class="reading-summary">'+contextLens(ctx)+'</p>';
    html+='<div class="card-strip">';
    chosen.forEach((c,i)=>{
      html+='<div class="mini-card"><strong>'+POS[i]+': '+escapeHtml(c.n)+'</strong><span>'+(c.reversed?'Invertida':'Al derecho')+' · '+escapeHtml(cardEnergy(c))+'</span></div>';
    });
    html+='</div>';
    html+='<h3>La historia de las tres cartas</h3><p>'+escapeHtml(flowReading(chosen,ctx))+'</p>';
    chosen.forEach((c,i)=>{
      html+='<h3>'+POS[i]+': '+escapeHtml(cardLabel(c))+'</h3><p>'+escapeHtml(positionReading(c,i,ctx))+'</p>';
    });
    html+='<h3>Consejo para actuar</h3><ul class="reading-actions">';
    practicalActions(chosen,ctx).forEach((action)=>{html+='<li>'+escapeHtml(action)+'</li>';});
    html+='</ul>';
    html+='<div class="arcana-links">';
    chosen.forEach((c)=>{html+='<a href="/arcanos-mayores/'+c.slug+'">'+escapeHtml(c.n)+'</a>';});
    html+='</div></div>';
    html+='<div class="result-deeper"><h3>¿Quieres profundizar más?</h3><p>Completa la lectura diaria con tu carta astral para entender qué área de tu vida está activando estas cartas.</p><a href="https://carta-astral-gratis.es/">Calcular mi carta astral gratis →</a></div>';
    html+='<div style="text-align:center"><button class="btn-reset" onclick="location.reload()">🔄 Nueva tirada</button></div>';
    res.innerHTML=html;
    res.classList.add('show');
  }
})();
</script>
</body>
</html>
ENDINDEX

echo "Generating editorial trust pages..."
cat > "$PUBLIC/guia-tarot.html" <<ENDGUIDE
<!DOCTYPE html>
<html lang="es">
<head>
$(gen_head "Guía de Tarot — Cómo Hacer Lecturas Responsables" "Método práctico para formular preguntas de tarot, interpretar cartas al derecho e invertidas y convertir una tirada en decisiones observables." "/guia-tarot" "editorial_guide" "trust" "guia-tarot")
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"Article","headline":"Guía de Tarot — Cómo Hacer Lecturas Responsables","author":{"@type":"Organization","name":"Tarot del Día"},"publisher":{"@type":"Organization","name":"Tarot del Día","url":"https://${DOMAIN}/"},"mainEntityOfPage":"https://${DOMAIN}/guia-tarot","inLanguage":"es"}
  </script>
  <style>
${COMMON_CSS}
    .guide-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:1rem;margin:1rem 0}
    .guide-card{background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:1rem;box-shadow:var(--shadow)}
    .guide-card h2{font-size:1rem;color:var(--accent);margin-bottom:.4rem}
    .guide-card p,.guide-card li{color:var(--muted);font-size:.9rem;line-height:1.7}
  </style>
</head>
<body>
<div class="container">
  <nav class="breadcrumb"><a href="/">Tarot del Día</a> › Guía de lectura</nav>
  <h1>Guía de <span>tarot responsable</span></h1>
  <p class="intro">Una tirada útil no consiste en buscar una predicción cerrada, sino en ordenar una pregunta, detectar patrones y decidir el siguiente paso con más calma.</p>

  <div class="guide-grid">
    <section class="guide-card">
      <h2>Formula mejor la pregunta</h2>
      <p>Evita preguntas que intentan controlar a otra persona. Cambia “qué hará” por “qué necesito comprender”, “qué límite cuidar” o “qué acción está en mi mano esta semana”.</p>
    </section>
    <section class="guide-card">
      <h2>Lee posición y contexto</h2>
      <p>Una misma carta no significa lo mismo en pasado, presente, futuro, bloqueo o consejo. Primero interpreta la posición, después la carta y al final la historia completa.</p>
    </section>
    <section class="guide-card">
      <h2>Usa cartas invertidas sin miedo</h2>
      <p>Una carta invertida suele señalar energía bloqueada, exagerada o interiorizada. No la leas como castigo: úsala para revisar dónde falta claridad o movimiento.</p>
    </section>
  </div>

$(ad_block "🔮" "Patrocinio en guía de lectura" "Audiencia interesada en aprender tarot con intención y lectura responsable." "Ver espacios →")

  <section class="panel">
    <h2>Método de 5 pasos</h2>
    <ol>
      <li>Escribe una pregunta concreta y con marco temporal.</li>
      <li>Elige una tirada sencilla: una carta, tres cartas o situación-obstáculo-consejo.</li>
      <li>Anota orientación, primera impresión y palabras clave.</li>
      <li>Contrasta la carta con hechos observables, no solo con deseo o miedo.</li>
      <li>Cierra con una acción pequeña: hablar, esperar, revisar datos, descansar o poner un límite.</li>
    </ol>
  </section>

  <section class="panel">
    <h2>Cuándo no conviene tirar cartas</h2>
    <p>No uses el tarot para sustituir ayuda médica, legal, psicológica o financiera. Tampoco conviene repetir la misma pregunta varias veces en momentos de ansiedad; en ese caso es más útil pausar, escribir lo que temes y volver con una pregunta distinta.</p>
    <p>La lectura responsable separa símbolo y realidad: una carta puede iluminar un patrón, pero las decisiones importantes necesitan datos, conversación y responsabilidad personal.</p>
  </section>

  <section class="panel">
    <h2>Continúa estudiando</h2>
    <p><a href="/arcanos-mayores">Arcanos Mayores</a> · <a href="/arcanos-menores">Arcanos Menores</a> · <a href="/tarot-amor">Tarot del amor</a> · <a href="/tarot-trabajo">Tarot del trabajo</a></p>
  </section>

$(cluster_recirculation_block "$SITE_KEY")
$(gen_footer)
</div>
</body>
</html>
ENDGUIDE

cat > "$PUBLIC/sobre-nosotros.html" <<ENDABOUT
<!DOCTYPE html>
<html lang="es">
<head>
$(gen_head "Sobre Tarot del Día — Criterio Editorial y Contacto" "Quién mantiene Tarot del Día, cómo se revisa el contenido y qué límites aplica esta herramienta gratuita de lectura de tarot." "/sobre-nosotros" "about_page" "trust" "sobre-nosotros")
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"AboutPage","name":"Sobre Tarot del Día","url":"https://${DOMAIN}/sobre-nosotros","isPartOf":{"@type":"WebSite","name":"Tarot del Día","url":"https://${DOMAIN}/"},"inLanguage":"es"}
  </script>
  <style>
${COMMON_CSS}
    .trust-list li{color:var(--muted);font-size:.9rem;line-height:1.7;margin-bottom:.4rem}
  </style>
</head>
<body>
<div class="container">
  <nav class="breadcrumb"><a href="/">Tarot del Día</a> › Sobre nosotros</nav>
  <h1>Sobre <span>Tarot del Día</span></h1>
  <section class="panel">
    <h2>Qué hacemos</h2>
    <p>Tarot del Día es una herramienta gratuita para hacer tiradas sencillas y consultar significados de cartas. El contenido está pensado para autoconocimiento, escritura personal y reflexión diaria, no para reemplazar asesoramiento profesional.</p>
    <p>La web forma parte de una red de herramientas en español sobre astrología, tarot, numerología y bienestar. Priorizamos páginas claras, navegación estable, contenido evergreen y enlaces internos que ayuden a profundizar sin forzar registros ni pagos.</p>
  </section>

  <section class="panel">
    <h2>Criterio editorial</h2>
    <ul class="trust-list">
      <li>Las fichas explican significado general, lectura al derecho, lectura invertida y aplicación práctica.</li>
      <li>Las guías evitan promesas absolutas y recomiendan convertir cada lectura en una acción verificable.</li>
      <li>Actualizamos páginas cuando detectamos errores, contenido insuficiente o cambios técnicos que afecten a la experiencia.</li>
      <li>La publicidad directa se revisa para que no se confunda con interpretación editorial.</li>
    </ul>
  </section>

  <section class="panel">
    <h2>Contacto</h2>
    <p>Para correcciones, propuestas editoriales o publicidad contextual puedes escribir a <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>.</p>
  </section>

$(cluster_recirculation_block "$SITE_KEY")
$(gen_footer)
</div>
</body>
</html>
ENDABOUT

SITEMAP_URLS+="  <url><loc>https://${DOMAIN}/guia-tarot</loc><lastmod>${TODAY}</lastmod><changefreq>monthly</changefreq><priority>0.8</priority></url>\n"
SITEMAP_URLS+="  <url><loc>https://${DOMAIN}/sobre-nosotros</loc><lastmod>${TODAY}</lastmod><changefreq>monthly</changefreq><priority>0.6</priority></url>\n"
SITEMAP_URLS="  <url><loc>https://${DOMAIN}/</loc><lastmod>${TODAY}</lastmod><changefreq>daily</changefreq><priority>1.0</priority></url>\n${SITEMAP_URLS}"

# ══════════════════════════════════════════════════════════════
# STATIC FILES
# ══════════════════════════════════════════════════════════════
echo "google.com, ${ADSENSE_PUB#ca-}, DIRECT, f08c47fec0942fa0" > "$PUBLIC/ads.txt"
gen_publicidad_page "$SITE_KEY" "$PUBLIC"

cat > "$PUBLIC/robots.txt" <<ENDROBOTS
User-agent: *
Allow: /
Sitemap: https://${DOMAIN}/sitemap.xml
ENDROBOTS

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

cat > "$PUBLIC/404.html" <<END404
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Página no encontrada — Tarot del Día</title>
  <meta name="description" content="Página no encontrada en Tarot del Día. Vuelve al inicio para hacer una tirada gratis o consultar los Arcanos Mayores.">
  <meta name="robots" content="noindex">
$(canonical_host_redirect_script "$DOMAIN")
  <style>${COMMON_CSS}</style>
</head>
<body>
<div class="container" style="text-align:center;padding:4rem 1rem">
  <div style="font-size:4rem">🃏</div>
  <h1>Las cartas no encuentran esta página</h1>
  <p style="color:var(--muted);margin:1rem 0">Vuelve al inicio para hacer tu tirada del día.</p>
  <a href="/" style="display:inline-block;padding:.6rem 1.5rem;background:var(--accent);color:#fff;border-radius:10px;text-decoration:none;font-weight:600">← Tirada de tarot gratis</a>
</div>
</body>
</html>
END404

echo "  ✓ Static files"
bash "$REPO_ROOT/scripts/generate-legal-pages.sh" "$SITE_KEY"
HTML_COUNT=$(find "$PUBLIC" -type f -name '*.html' | wc -l | tr -d ' ')
echo "Done! ${HTML_COUNT} HTML pages in $PUBLIC"
