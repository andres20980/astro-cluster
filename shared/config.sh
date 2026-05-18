#!/usr/bin/env bash
# Shared configuration for all esoteric cluster sites
# Source this file from any site generator script

# — AdSense (same account for all sites)
ADSENSE_PUB="ca-pub-9368517395014039"
ADSENSE_AUTO_ADS_ENABLED="${ADSENSE_AUTO_ADS_ENABLED:-1}"
DIRECT_ADS_ENABLED="${DIRECT_ADS_ENABLED:-0}"

# — GA4 (single cluster-wide property + cross-domain linker)
CLUSTER_GA4_ID="G-DEWMQ73FH5"
declare -A GA4_IDS=(
  [carta-astral]="$CLUSTER_GA4_ID"
  [compatibilidad-signos]="$CLUSTER_GA4_ID"
  [tarot-del-dia]="$CLUSTER_GA4_ID"
  [calcular-numerologia]="$CLUSTER_GA4_ID"
  [horoscopo-de-hoy]="$CLUSTER_GA4_ID"
  [meditacion-chakras]="$CLUSTER_GA4_ID"
)

# — Domains
declare -A DOMAINS=(
  [carta-astral]="carta-astral-gratis.es"
  [compatibilidad-signos]="compatibilidad-signos.es"
  [tarot-del-dia]="tarot-del-dia.es"
  [calcular-numerologia]="calcular-numerologia.es"
  [horoscopo-de-hoy]="horoscopo-de-hoy.es"
  [meditacion-chakras]="meditacion-chakras.es"
)

declare -A TOOL_TYPES=(
  [carta-astral]="astrology_chart"
  [compatibilidad-signos]="compatibility"
  [tarot-del-dia]="tarot"
  [calcular-numerologia]="numerology"
  [horoscopo-de-hoy]="daily_horoscope"
  [meditacion-chakras]="mindfulness_quiz"
)

declare -a CLUSTER_SITE_KEYS=(
  "carta-astral"
  "compatibilidad-signos"
  "tarot-del-dia"
  "calcular-numerologia"
  "horoscopo-de-hoy"
  "meditacion-chakras"
)

declare -a TRACKING_DOMAINS=(
  "carta-astral-gratis.es"
  "compatibilidad-signos.es"
  "tarot-del-dia.es"
  "calcular-numerologia.es"
  "horoscopo-de-hoy.es"
  "meditacion-chakras.es"
)

declare -A GSC_SITE_URLS=(
  [carta-astral]="sc-domain:carta-astral-gratis.es"
  [compatibilidad-signos]="sc-domain:compatibilidad-signos.es"
  [tarot-del-dia]="sc-domain:tarot-del-dia.es"
  [calcular-numerologia]="sc-domain:calcular-numerologia.es"
  [horoscopo-de-hoy]="sc-domain:horoscopo-de-hoy.es"
  [meditacion-chakras]="sc-domain:meditacion-chakras.es"
)

gsc_site_url_for() {
  local site_key="$1"
  echo "${GSC_SITE_URLS[$site_key]}"
}

sitemap_url_for() {
  local site_key="$1"
  echo "https://${DOMAINS[$site_key]}/sitemap.xml"
}

canonical_host_redirect_script() {
  local domain="$1"
  cat <<EOF
  <script>if(location.protocol!=='https:'||location.hostname==='www.${domain}'||location.hostname.endsWith('.web.app'))location.replace('https://${domain}'+location.pathname+location.search);</script>
EOF
}

# — Shared brand
BRAND_FONTS="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700&family=Inter:wght@300;400;500;600&display=swap"
CONTACT_EMAIL="publicidad@carta-astral-gratis.es"

# — CSS Variables (same palette across all sites)
CSS_VARS=':root{--bg:#faf8f5;--surface:#fff;--border:#e8e0d8;--text:#2d2a26;--muted:#7a7268;--accent:#7c3aed;--accent2:#c084fc;--gold:#d4a017;--gradient:linear-gradient(135deg,#7c3aed 0%,#c084fc 50%,#d4a017 100%);--shadow:0 2px 12px rgba(124,58,237,.08)}'

# — Cross-link network (all sites link to each other)
declare -A CROSSLINKS=(
  [carta-astral]="Carta Astral Gratis"
  [compatibilidad-signos]="Compatibilidad de Signos"
  [tarot-del-dia]="Tarot del Día"
  [calcular-numerologia]="Calcular Numerología"
  [horoscopo-de-hoy]="Horóscopo de Hoy"
  [meditacion-chakras]="Meditación de Chakras"
)

# — Commercial / direct advertising copy
declare -A SITE_COMMERCIAL_HOOK=(
  [carta-astral]="Una audiencia de alta intención interesada en astrología, autoconocimiento y bienestar."
  [compatibilidad-signos]="Una audiencia que llega con intención clara de resolver dudas sobre amor, pareja y afinidad."
  [tarot-del-dia]="Una audiencia que busca guía inmediata, lectura espiritual y productos del nicho esotérico."
  [calcular-numerologia]="Una audiencia que quiere respuestas personales, formación y herramientas de crecimiento interior."
  [horoscopo-de-hoy]="Una audiencia recurrente que vuelve a diario para consultar amor, trabajo y salud."
  [meditacion-chakras]="Una audiencia interesada en mindfulness, chakras, meditación guiada y bienestar emocional."
)

declare -A SITE_COMMERCIAL_BRANDS=(
  [carta-astral]="consultas astrológicas, tarot profesional, tiendas esotéricas, cursos y bienestar"
  [compatibilidad-signos]="aplicaciones de citas, acompañamiento de pareja, joyería, regalos personalizados y bienestar emocional"
  [tarot-del-dia]="consultas de tarot, cursos, mazos, velas, incienso, rituales y membresías espirituales"
  [calcular-numerologia]="escuelas holísticas, libros, consultoría espiritual, membresías de pago y herramientas formativas"
  [horoscopo-de-hoy]="tarot, astrología, bienestar, tiendas espirituales, suscripciones y recomendaciones afiliadas"
  [meditacion-chakras]="apps de mindfulness, cursos de meditación, respiración, sound healing, yoga y bienestar"
)

declare -A SITE_COMMERCIAL_CONTEXT=(
  [carta-astral]="aparece a lo largo del flujo de cálculo y en puntos de máxima atención de la carta natal"
  [compatibilidad-signos]="aparece junto a comparativas de signos y combinaciones muy buscadas por tráfico orgánico"
  [tarot-del-dia]="aparece junto a la tirada interactiva y al contenido estable de arcanos"
  [calcular-numerologia]="aparece junto al cálculo del número de vida y a fichas de fuerte intención educativa"
  [horoscopo-de-hoy]="aparece junto a predicciones diarias y fichas de signos con consumo recurrente"
  [meditacion-chakras]="aparece en un funnel de 23 pasos de alta atención sobre bienestar y equilibrio energético"
)

declare -A CLUSTER_JOURNEY_NAME=(
  [carta-astral]="Perfil personal"
  [compatibilidad-signos]="Amor y pareja"
  [tarot-del-dia]="Decision puntual"
  [calcular-numerologia]="Autoconocimiento profundo"
  [horoscopo-de-hoy]="Energia del dia"
  [meditacion-chakras]="Integracion emocional"
)

# Helper: generate cross-link footer HTML for a given site key
crosslink_footer() {
  local current="$1"
  local html='<div class="network">Nuestras herramientas: '
  local first=true
  for key in carta-astral compatibilidad-signos tarot-del-dia calcular-numerologia horoscopo-de-hoy meditacion-chakras; do
    [[ "$key" == "$current" ]] && continue
    local domain="${DOMAINS[$key]}"
    local name="${CROSSLINKS[$key]}"
    $first || html+=" · "
    html+="<a href=\"https://${domain}/\" rel=\"noopener\" data-link-context=\"network_footer\" data-destination-site=\"${key}\" data-destination-domain=\"${domain}\">${name}</a>"
    first=false
  done
  html+='</div>'
  echo "$html"
}

ga4_head_snippet() {
  local measurement_id="$1"
  local site_key="${2:-cluster}"
  local page_type="${3:-page}"
  local content_group="${4:-content}"
  local entity_slug="${5:-}"
  local domains_js=""
  local site_map_js=""
  local domain
  local key
  for domain in "${TRACKING_DOMAINS[@]}"; do
    domains_js+="'${domain}',"
  done
  domains_js="${domains_js%,}"
  for key in "${CLUSTER_SITE_KEYS[@]}"; do
    site_map_js+="'${DOMAINS[$key]}':'${key}',"
  done
  site_map_js="${site_map_js%,}"

  cat <<EOF
  <script>
    (function(){
      const measurementId='${measurement_id}';
      const storageKey='astro_cluster_analytics_optout';
      let optedOut=false;
      try{
        const params=new URLSearchParams(location.search);
        const value=params.get('analytics_optout');
        if(value==='1'||value==='true')localStorage.setItem(storageKey,'1');
        if(value==='0'||value==='false')localStorage.removeItem(storageKey);
        optedOut=localStorage.getItem(storageKey)==='1';
      }catch(e){}
      window.clusterAnalyticsOptedOut=optedOut;
      window['ga-disable-'+measurementId]=window.clusterAnalyticsOptedOut;
    })();
  </script>
  <script async src="https://www.googletagmanager.com/gtag/js?id=${measurement_id}"></script>
  <script>
    window.dataLayer=window.dataLayer||[];
    function gtag(){dataLayer.push(arguments);}
    window.clusterSitesByDomain={${site_map_js}};
    window.clusterAnalyticsState=(function(){
      const prefix='astro_cluster_';
      const randomId=function(){
        return Date.now().toString(36)+'-'+Math.random().toString(36).slice(2,10);
      };
      const read=function(key,fallback){
        try{return localStorage.getItem(prefix+key)||fallback;}catch(e){return fallback;}
      };
      const write=function(key,value){
        try{localStorage.setItem(prefix+key,String(value));}catch(e){}
      };
      const metaSite='${site_key}';
      let sessionId=read('session_id','');
      if(!sessionId){
        sessionId=randomId();
        write('session_id',sessionId);
      }
      let firstSite=read('first_site_seen','');
      if(!firstSite){
        firstSite=metaSite;
        write('first_site_seen',firstSite);
      }
      let toolsSeen=parseInt(read('tools_seen_count','0'),10)||0;
      const seenKey='tool_seen_'+metaSite;
      if(read(seenKey,'0')!=='1'){
        toolsSeen+=1;
        write(seenKey,'1');
        write('tools_seen_count',toolsSeen);
      }
      return {
        sessionId:sessionId,
        firstSiteSeen:firstSite,
        toolsSeenCount:toolsSeen,
        completedToolsCount:parseInt(read('completed_tools_count','0'),10)||0,
        lastToolCompleted:read('last_tool_completed',''),
        markComplete:function(tool){
          const completionKey='tool_completed_'+(tool||metaSite);
          if(read(completionKey,'0')==='1'){
            this.completedToolsCount=parseInt(read('completed_tools_count','0'),10)||0;
            this.lastToolCompleted=read('last_tool_completed','')||this.lastToolCompleted;
            return;
          }
          const current=parseInt(read('completed_tools_count','0'),10)||0;
          const next=current+1;
          write(completionKey,'1');
          write('completed_tools_count',next);
          write('last_tool_completed',tool||metaSite);
          this.completedToolsCount=next;
          this.lastToolCompleted=tool||metaSite;
        }
      };
    })();
    window.clusterAnalyticsMeta={
      cluster_name:'astro-cluster',
      site_key:'${site_key}',
      site_domain:'${DOMAINS[$site_key]}',
      tool_type:'${TOOL_TYPES[$site_key]}',
      page_type:'${page_type}',
      content_group:'${content_group}',
      entity_slug:'${entity_slug}',
      origin_site:window.clusterAnalyticsState.firstSiteSeen,
      cluster_session_id:window.clusterAnalyticsState.sessionId,
      tools_seen_count:window.clusterAnalyticsState.toolsSeenCount,
      completed_tools_count:window.clusterAnalyticsState.completedToolsCount,
      last_tool_completed:window.clusterAnalyticsState.lastToolCompleted
    };
    window.clusterTrack=function(eventName,params){
      if(window.clusterAnalyticsOptedOut)return;
      if(eventName==='tool_complete'||eventName==='chart_calculated'||eventName==='compatibility_view'||eventName==='tarot_reading_complete'||eventName==='numerology_calculated'||eventName==='interpretation_generated'){
        window.clusterAnalyticsState.markComplete(window.clusterAnalyticsMeta.site_key);
      }
      const payload=Object.assign({},window.clusterAnalyticsMeta,params||{});
      payload.tools_seen_count=window.clusterAnalyticsState.toolsSeenCount;
      payload.completed_tools_count=window.clusterAnalyticsState.completedToolsCount;
      payload.last_tool_completed=window.clusterAnalyticsState.lastToolCompleted;
      Object.keys(payload).forEach(key=>{
        if(payload[key]===''||payload[key]===null||payload[key]===undefined)delete payload[key];
      });
      payload.transport_type='beacon';
      gtag('event',eventName,payload);
    };
    gtag('js',new Date());
    gtag('config','${measurement_id}',{
      send_page_view:false,
      linker:{domains:[${domains_js}]}
    });
    window.clusterTrack('page_view',{
      page_title:document.title,
      page_location:location.href,
      page_path:location.pathname,
      page_hostname:location.hostname,
      page_referrer:document.referrer||undefined
    });
    document.addEventListener('click',function(event){
      const anchor=event.target.closest('a[href]');
      if(!anchor||anchor.dataset.analyticsIgnore==='1')return;
      const rawHref=anchor.getAttribute('href')||'';
      if(!rawHref||rawHref.startsWith('#')||rawHref.startsWith('mailto:')||rawHref.startsWith('tel:'))return;
      let url;
      try{url=new URL(anchor.href,location.href);}catch{return;}
      const normalizeHost=host=>(host||'').replace(/^www\./,'');
      const destinationDomain=normalizeHost(url.hostname);
      const currentDomain=normalizeHost(location.hostname);
      const destinationSite=anchor.dataset.destinationSite||window.clusterSitesByDomain[destinationDomain]||'';
      const linkText=(anchor.textContent||'').replace(/\s+/g,' ').trim().slice(0,120);
      const linkContext=anchor.dataset.linkContext||'';
      const adSlot=anchor.dataset.adSlot||'';
      if(anchor.matches('.ad-ph,.ad-link,[data-ad-slot]')||url.pathname==='/publicidad'){
        window.clusterTrack('advertiser_cta_click',{
          link_url:url.href,
          link_text:linkText,
          link_context:linkContext||'advertiser_cta',
          ad_slot:adSlot||'direct_advertiser_cta',
          journey_stage:'commercial'
        });
        return;
      }
      if(destinationSite&&destinationDomain!==currentDomain){
        const isResultContext=(linkContext||'').indexOf('result')!==-1||(linkContext||'').indexOf('recirculation')!==-1;
        window.clusterTrack(isResultContext?'result_to_next_tool_click':'internal_tool_click',{
          link_url:url.href,
          link_text:linkText,
          link_context:linkContext||'cluster_crosslink',
          destination_site:destinationSite,
          destination_domain:destinationDomain,
          journey_stage:isResultContext?'recirculation':'navigation',
          recirculation_variant:anchor.dataset.recirculationVariant||''
        });
      }
    },{capture:true});
    document.addEventListener('DOMContentLoaded',function(){
      const seen=new WeakSet();
      const trackBlock=function(block){
        if(!block||seen.has(block))return;
        seen.add(block);
        window.clusterTrack(block.dataset.analyticsEvent||'cluster_recirculation_impression',{
          journey_stage:block.dataset.journeyStage||'recirculation',
          link_context:block.dataset.linkContext||'cluster_recirculation',
          recirculation_variant:block.dataset.recirculationVariant||'default',
          destination_site:block.dataset.primaryDestinationSite||''
        });
      };
      document.querySelectorAll('[data-track-impression="cluster_recirculation"]').forEach(function(block){
        if('IntersectionObserver' in window){
          const observer=new IntersectionObserver(function(entries){
            entries.forEach(function(entry){
              if(entry.isIntersecting){
                trackBlock(entry.target);
                observer.unobserve(entry.target);
              }
            });
          },{threshold:.35});
          observer.observe(block);
        }else{
          trackBlock(block);
        }
      });
      document.querySelectorAll('[data-track-impression="advertiser_cta"]').forEach(function(block){
        window.clusterTrack('advertiser_cta_impression',{
          journey_stage:'commercial',
          link_context:block.dataset.linkContext||'advertiser_cta',
          ad_slot:block.dataset.adSlot||'direct_advertiser_cta'
        });
      });
    });
  </script>
EOF
}

adsense_head_snippet() {
  case "${ADSENSE_AUTO_ADS_ENABLED:-0}" in
    1|true|TRUE|yes|YES)
      cat <<EOF
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${ADSENSE_PUB}" crossorigin="anonymous"></script>
EOF
      ;;
  esac
}

direct_ads_enabled() {
  case "${DIRECT_ADS_ENABLED:-0}" in
    1|true|TRUE|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

adsense_apply_head_snippet_to_file() {
  local file="$1"
  local snippet
  snippet="$(adsense_head_snippet)"

  if [[ -z "$snippet" || ! -f "$file" ]]; then
    return 0
  fi

  if grep -q 'pagead2.googlesyndication.com/pagead/js/adsbygoogle.js' "$file"; then
    return 0
  fi

  local tmp="${file}.adsense.tmp"
  awk -v snippet="$snippet" '
    !inserted && /<\/head>/ {
      print snippet
      inserted=1
    }
    { print }
    END {
      if (!inserted) {
        exit 2
      }
    }
  ' "$file" > "$tmp" || {
    rm -f "$tmp"
    return 1
  }
  mv "$tmp" "$file"
}

ad_css() {
  cat <<'EOF'
    .ad-h{margin:1.25rem 0}
    .ad-ph{display:flex;align-items:center;justify-content:center;text-decoration:none;border:1px solid var(--border);border-radius:16px;background:linear-gradient(135deg,#f9f5ff 0%,#fef9ee 100%);box-shadow:var(--shadow);padding:1rem;transition:transform .2s,box-shadow .2s,border-color .2s;text-align:center;color:var(--text)}
    .ad-ph:hover{transform:translateY(-2px);box-shadow:0 10px 26px rgba(124,58,237,.14);border-color:rgba(124,58,237,.28)}
    .ad-ph-h{min-height:122px;flex-direction:column;gap:.32rem}
    .ad-kicker{font-size:.63rem;letter-spacing:.08em;text-transform:uppercase;font-weight:700;color:var(--accent)}
    .ad-icon{font-size:1.5rem;line-height:1}
    .ad-label{font-family:'Playfair Display',serif;font-size:1.08rem;font-weight:700;line-height:1.25}
    .ad-copy{font-size:.82rem;line-height:1.6;color:var(--muted);max-width:560px}
    .ad-cta{display:inline-flex;align-items:center;justify-content:center;margin-top:.2rem;padding:.45rem .95rem;border-radius:999px;background:var(--accent);color:#fff;font-size:.76rem;font-weight:700}
    .ad-link{color:var(--accent);text-decoration:none;font-weight:600}
    .ad-link:hover{text-decoration:underline}
    @media(max-width:600px){
      .ad-ph-h{min-height:110px;padding:.9rem}
      .ad-label{font-size:.98rem}
      .ad-copy{font-size:.78rem}
    }
EOF
}

ad_block() {
  direct_ads_enabled || return 0
  local icon="$1"
  local label="$2"
  local copy="$3"
  local cta="${4:-Ver espacios y tarifas →}"
  cat <<EOF
<div class="ad-h" data-track-impression="advertiser_cta" data-ad-slot="premium_direct_cta" data-link-context="ad_block">
  <a class="ad-ph ad-ph-h" href="/publicidad" title="Anúnciate aquí" data-ad-slot="premium_direct_cta" data-link-context="ad_block">
    <span class="ad-kicker">Espacio publicitario destacado</span>
    <span class="ad-icon">${icon}</span>
    <span class="ad-label">${label}</span>
    <span class="ad-copy">${copy}</span>
    <span class="ad-cta">${cta}</span>
  </a>
</div>
EOF
}

footer_publicidad_line() {
  direct_ads_enabled || return 0
  local current="$1"
  local name="${CROSSLINKS[$current]}"
  echo "<p style=\"margin-top:.6rem\"><a href=\"/publicidad\" class=\"ad-link\" data-ad-slot=\"footer_publicidad_cta\" data-link-context=\"footer_publicidad\">✦ Quiero anunciarme en ${name}: ver espacios y tarifas</a></p>"
}

cluster_css() {
  cat <<'EOF'
    .cluster-journey{margin:1.6rem 0;padding:1.35rem;border:1px solid var(--border);border-radius:18px;background:linear-gradient(135deg,#fff 0%,#f9f5ff 52%,#fef9ee 100%);box-shadow:var(--shadow)}
    .cluster-journey .cluster-kicker{display:inline-flex;align-items:center;gap:.45rem;font-size:.66rem;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--accent);margin-bottom:.5rem}
    .cluster-journey h2{margin-bottom:.45rem}
    .cluster-journey p{color:var(--muted);font-size:.9rem;line-height:1.7}
    .cluster-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:.9rem;margin-top:1rem}
    .cluster-card{display:block;padding:1rem 1rem 1.05rem;border-radius:14px;border:1px solid var(--border);background:rgba(255,255,255,.92);text-decoration:none;color:var(--text);box-shadow:0 8px 20px rgba(124,58,237,.08);transition:transform .18s,border-color .18s,box-shadow .18s}
    .cluster-card:hover{transform:translateY(-2px);border-color:rgba(124,58,237,.28);box-shadow:0 14px 28px rgba(124,58,237,.13)}
    .cluster-card .cluster-label{display:block;font-size:.7rem;font-weight:700;letter-spacing:.05em;text-transform:uppercase;color:var(--accent);margin-bottom:.2rem}
    .cluster-card .cluster-title{display:block;font-family:'Playfair Display',serif;font-size:1rem;margin-bottom:.28rem}
    .cluster-card .cluster-copy{display:block;font-size:.82rem;line-height:1.58;color:var(--muted)}
    .cluster-card .cluster-cta{display:inline-block;margin-top:.65rem;font-size:.8rem;font-weight:700;color:var(--accent)}
    .cluster-journey .cluster-note{margin-top:.8rem;font-size:.78rem;color:var(--muted)}
    @media(max-width:600px){
      .cluster-journey{padding:1.1rem}
      .cluster-grid{grid-template-columns:1fr}
    }
EOF
}

cluster_card() {
  local site_key="$1"
  local label="$2"
  local title="$3"
  local copy="$4"
  local cta="$5"
  local variant="${6:-default}"
  local domain="${DOMAINS[$site_key]}"
cat <<EOF
<a class="cluster-card" href="https://${domain}/" rel="noopener" data-link-context="result_recirculation" data-destination-site="${site_key}" data-destination-domain="${domain}" data-recirculation-variant="${variant}">
  <span class="cluster-label">${label}</span>
  <span class="cluster-title">${title}</span>
  <span class="cluster-copy">${copy}</span>
  <span class="cluster-cta">${cta}</span>
</a>
EOF
}

cluster_recirculation_block() {
  local current="$1"
  local heading="Completa tu lectura"
  local intro="Siguiente capa recomendada segun lo que estas consultando ahora."
  local cards=""
  local primary=""
  local journey="${CLUSTER_JOURNEY_NAME[$current]:-Cluster astro}"

  case "$current" in
    carta-astral)
      primary="compatibilidad-signos"
      intro="Tu carta es el mapa base. Ahora puedes llevarla a relaciones, identidad simbolica o practica interior."
      cards+=$(cluster_card "compatibilidad-signos" "Paso principal" "Compatibilidad de Signos" "Cruza la lectura personal con la afinidad de pareja, amistad o convivencia." "Ver compatibilidad" "primary")
      cards+=$(cluster_card "calcular-numerologia" "Capa simbolica" "Calcular Numerología" "Contrasta tu carta con tu numero de vida y patrones personales." "Calcular mi numero" "secondary")
      cards+=$(cluster_card "meditacion-chakras" "Integracion" "Meditación de Chakras" "Convierte lo que muestra la carta en una practica breve de equilibrio." "Empezar practica" "secondary")
      ;;
    compatibilidad-signos)
      primary="carta-astral"
      intro="La compatibilidad por signo es una primera capa. Para afinar, conviene mirar carta natal, una consulta puntual o integracion emocional."
      cards+=$(cluster_card "carta-astral" "Paso principal" "Carta Astral Gratis" "Personaliza la afinidad con Luna, Venus, Marte y ascendente." "Calcular carta" "primary")
      cards+=$(cluster_card "tarot-del-dia" "Duda concreta" "Tarot del Día" "Haz una tirada breve si necesitas orientar una decision sentimental." "Hacer tirada" "secondary")
      cards+=$(cluster_card "meditacion-chakras" "Equilibrio" "Meditación de Chakras" "Trabaja el chakra del corazon antes de sacar conclusiones." "Abrir practica" "secondary")
      ;;
    tarot-del-dia)
      primary="meditacion-chakras"
      intro="El tarot da una senal inmediata. El siguiente paso es integrarla, contrastarla con el dia o llevarla a una lectura personal."
      cards+=$(cluster_card "meditacion-chakras" "Paso principal" "Meditación de Chakras" "Aterriza el mensaje de la tirada con una practica guiada." "Integrar ahora" "primary")
      cards+=$(cluster_card "horoscopo-de-hoy" "Contexto diario" "Horóscopo de Hoy" "Consulta la energia de tu signo para completar la lectura del dia." "Ver mi signo" "secondary")
      cards+=$(cluster_card "carta-astral" "Capa profunda" "Carta Astral Gratis" "Amplia la tirada con personalidad, ciclos y relaciones." "Calcular carta" "secondary")
      ;;
    calcular-numerologia)
      primary="carta-astral"
      intro="Tu numero describe un patron. Puedes completarlo con carta natal, practica energetica o seguimiento diario."
      cards+=$(cluster_card "carta-astral" "Paso principal" "Carta Astral Gratis" "Combina numero de vida con planetas, casas y ascendente." "Completar perfil" "primary")
      cards+=$(cluster_card "meditacion-chakras" "Activacion" "Meditación de Chakras" "Lleva el patron numerologico a una practica corporal sencilla." "Activar energia" "secondary")
      cards+=$(cluster_card "horoscopo-de-hoy" "Seguimiento" "Horóscopo de Hoy" "Anade una lectura ligera del dia para observar tendencias." "Ver hoy" "secondary")
      ;;
    horoscopo-de-hoy)
      primary="tarot-del-dia"
      intro="El horoscopo marca el clima general del dia. Si quieres una senal concreta, una practica o personalizacion, continua aqui."
      cards+=$(cluster_card "tarot-del-dia" "Paso principal" "Tarot del Día" "Haz una tirada rapida si buscas una senal adicional para decidir hoy." "Abrir tirada" "primary")
      cards+=$(cluster_card "meditacion-chakras" "Energia del dia" "Meditación de Chakras" "Complementa tu signo con una practica en el centro que mas necesita atencion." "Meditar ahora" "secondary")
      cards+=$(cluster_card "carta-astral" "Personalizacion" "Carta Astral Gratis" "Pasa de prediccion general a lectura con fecha, hora y lugar." "Calcular carta" "secondary")
      ;;
    meditacion-chakras)
      primary="carta-astral"
      intro="Tu practica muestra un estado actual. Puedes cruzarlo con energia natal, clima del dia o una senal intuitiva."
      cards+=$(cluster_card "carta-astral" "Paso principal" "Carta Astral Gratis" "Descubre los planetas que rigen tu energia y como influyen en tu bienestar." "Ver carta" "primary")
      cards+=$(cluster_card "horoscopo-de-hoy" "Energia diaria" "Horóscopo de Hoy" "Consulta que energia domina hoy segun tu signo para orientar la practica." "Leer horoscopo" "secondary")
      cards+=$(cluster_card "tarot-del-dia" "Mensaje interior" "Tarot del Día" "Haz una tirada breve antes o despues de meditar." "Tirar cartas" "secondary")
      ;;
    *)
      cards+=$(cluster_card "carta-astral" "Astrología" "Carta Astral Gratis" "Descubre tu carta natal completa con una interpretación personalizada." "Abrir →")
      cards+=$(cluster_card "meditacion-chakras" "Bienestar" "Meditación de Chakras" "Equilibra tus centros de energía con una meditación guiada paso a paso." "Abrir →")
      cards+=$(cluster_card "horoscopo-de-hoy" "Predicción diaria" "Horóscopo de Hoy" "Lee tu horóscopo del día y consulta la energía de tu signo." "Abrir →")
      ;;
  esac

  cat <<EOF
<section class="cluster-journey" data-track-impression="cluster_recirculation" data-analytics-event="cluster_recirculation_impression" data-journey-stage="recirculation" data-link-context="result_recirculation" data-recirculation-variant="default" data-primary-destination-site="${primary}">
  <div class="cluster-kicker">Mas herramientas para ti · ${journey}</div>
  <h2>${heading}</h2>
  <p>${intro}</p>
  <div class="cluster-grid">
    ${cards}
  </div>
  <p class="cluster-note">Usa otra herramienta solo si quieres ampliar esta lectura desde otro angulo.</p>
</section>
EOF
}

gen_publicidad_page() {
  local current="$1"
  local public_dir="$2"
  local name="${CROSSLINKS[$current]}"
  local domain="${DOMAINS[$current]}"
  local hook="${SITE_COMMERCIAL_HOOK[$current]}"
  local brands="${SITE_COMMERCIAL_BRANDS[$current]}"
  local context="${SITE_COMMERCIAL_CONTEXT[$current]}"
  local robots="noindex, follow"
  if direct_ads_enabled; then
    robots="index, follow"
  fi

  cat > "${public_dir}/publicidad.html" <<EOF
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Publicidad en ${name} - Dosier para anunciantes</title>
  <meta name="description" content="Anuncia tu marca en ${domain}. Dosier comercial con espacios destacados, patrocinios directos y formatos flexibles.">
  <link rel="canonical" href="https://${domain}/publicidad">
  <meta property="og:title" content="Publicidad en ${name}">
  <meta property="og:description" content="${hook}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://${domain}/publicidad">
  <meta property="og:locale" content="es_ES">
  <meta name="robots" content="${robots}">
  <link rel="preconnect" href="https://fonts.googleapis.com" crossorigin>
  <link href="${BRAND_FONTS}" rel="stylesheet" media="print" onload="this.media='all'">
  <noscript><link href="${BRAND_FONTS}" rel="stylesheet"></noscript>
$(canonical_host_redirect_script "$domain")
$(ga4_head_snippet "${GA4_IDS[$current]}" "$current" "commercial_landing" "advertising" "publicidad")
  <script type="application/ld+json">
  {"@context":"https://schema.org","@type":"WebPage","name":"Publicidad en ${name}","url":"https://${domain}/publicidad","description":"Dosier comercial y espacios destacados para anunciantes en ${domain}","inLanguage":"es"}
  </script>
  <style>
    ${CSS_VARS}
    *{margin:0;padding:0;box-sizing:border-box}
    body{font-family:'Inter',system-ui,sans-serif;background:var(--bg);color:var(--text);line-height:1.6}
    .wrap{max-width:840px;margin:0 auto;padding:0 1.5rem 3rem}
    nav{text-align:center;padding:1.1rem 1rem;border-bottom:1px solid var(--border)}
    nav a{color:var(--accent);text-decoration:none;font-weight:600;font-size:.88rem}
    .hero{text-align:center;padding:2.8rem 0 1.6rem}
    .hero h1{font-family:'Playfair Display',serif;font-size:2rem;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
    .hero p{max-width:620px;margin:.8rem auto 0;color:var(--muted);font-size:.98rem}
    section{margin:2rem 0}
    section h2{font-family:'Playfair Display',serif;font-size:1.35rem;margin-bottom:.8rem}
    section p,section li{color:var(--muted);font-size:.92rem;line-height:1.7}
    .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:1rem;margin-top:1rem}
    .card{background:var(--surface);border:1px solid var(--border);border-radius:14px;padding:1.2rem;box-shadow:var(--shadow)}
    .card h3{font-size:.95rem;margin-bottom:.25rem}
    .card .icon{font-size:1.5rem;margin-bottom:.45rem}
    .slots{display:grid;gap:1rem;margin-top:1rem}
    .slot{background:var(--surface);border:1px solid var(--border);border-radius:14px;padding:1.2rem;box-shadow:var(--shadow)}
    .slot h3{font-family:'Playfair Display',serif;font-size:1rem;margin-bottom:.25rem}
    .slot .price{margin-top:.45rem;font-weight:700;color:var(--accent)}
    table{width:100%;border-collapse:collapse;background:var(--surface);border:1px solid var(--border);border-radius:14px;overflow:hidden;box-shadow:var(--shadow);font-size:.88rem}
    th,td{padding:.8rem 1rem;border-top:1px solid var(--border);text-align:left}
    thead th{border-top:none;background:#f9f5ff;color:var(--accent);font-size:.76rem;text-transform:uppercase;letter-spacing:.05em}
    .cta{margin-top:2rem;padding:2rem 1.2rem;border:1px solid var(--border);border-radius:16px;background:linear-gradient(135deg,#f9f5ff 0%,#fef9ee 100%);text-align:center}
    .cta h2{margin-bottom:.5rem}
    .btn{display:inline-block;margin-top:.9rem;padding:.8rem 1.6rem;border-radius:999px;background:var(--accent);color:#fff;text-decoration:none;font-weight:700}
    footer{text-align:center;padding:2rem 0 0;color:var(--muted);font-size:.78rem}
    footer a{color:var(--accent);text-decoration:none}
    @media(max-width:600px){
      .hero h1{font-size:1.6rem}
      table{font-size:.82rem}
      th,td{padding:.7rem}
    }
  </style>
</head>
<body>
<nav><a href="/">← Volver a ${name}</a></nav>
<div class="wrap">
  <div class="hero">
    <h1>Dosier comercial - Publicidad</h1>
    <p>${hook} Si vendes ${brands}, estos espacios te ponen delante de una audiencia contextual. Puedes reservar una posición en este sitio o comprar presencia estática en toda la red.</p>
  </div>

  <section>
    <h2>Qué tipo de campañas encajan</h2>
    <p>Estos espacios están pensados para marcas que quieren aparecer en páginas con intención clara: usuarios que calculan una carta, consultan una compatibilidad, revisan su horóscopo, hacen una tirada o buscan su número de vida. La visibilidad no depende de una subasta automática: se pacta ubicación, duración y mensaje antes de publicar.</p>
    <p>Priorizamos anunciantes que aporten algo razonable al contexto del sitio: consultas, formación, libros, herramientas, bienestar, productos digitales o servicios relacionados. No aceptamos creatividades engañosas, promesas garantizadas ni mensajes que puedan confundirse con el contenido editorial.</p>
  </section>

  <section>
    <h2>Por qué anunciarte aquí</h2>
    <div class="grid">
      <div class="card">
        <div class="icon">🎯</div>
        <h3>Intención alta</h3>
        <p>El usuario no llega por curiosidad genérica: entra buscando una respuesta concreta y consume contenido con foco.</p>
      </div>
      <div class="card">
        <div class="icon">🧩</div>
        <h3>Contexto relevante</h3>
        <p>Tu marca ${context}, lo que mejora recuerdo, afinidad y clics frente a espacios publicitarios genéricos.</p>
      </div>
      <div class="card">
        <div class="icon">💸</div>
        <h3>Venta directa</h3>
        <p>El patrocinio directo tiene prioridad comercial: texto aprobado, ubicación fija y presencia contextual sin depender de subastas automáticas.</p>
      </div>
      <div class="card">
        <div class="icon">📦</div>
        <h3>Compra por red</h3>
        <p>Una misma creatividad puede aparecer en las 6 herramientas para cubrir astrologia, tarot, numerologia, horoscopo, compatibilidad y bienestar energetico.</p>
      </div>
    </div>
  </section>

  <section>
    <h2>Paquetes por intencion</h2>
    <p>La red se vende tambien por recorridos de usuario, no solo por dominios. Esto permite que una marca aparezca donde el contexto tiene mas sentido y evita impactos automaticos poco relevantes.</p>
    <div class="grid">
      <div class="card">
        <h3>Amor y pareja</h3>
        <p>Compatibilidad, carta astral y tarot para marcas de citas, regalos, joyeria, terapia de pareja o consultas sentimentales.</p>
      </div>
      <div class="card">
        <h3>Energia del dia</h3>
        <p>Horoscopo, tarot y chakras para campañas de consumo recurrente, bienestar, rituales o productos espirituales.</p>
      </div>
      <div class="card">
        <h3>Autoconocimiento</h3>
        <p>Carta astral, numerologia y chakras para formacion, membresias, libros, cursos y herramientas de crecimiento personal.</p>
      </div>
    </div>
  </section>

  <section>
    <h2>Espacios disponibles</h2>
    <div class="slots">
      <div class="slot">
        <h3>Banner superior</h3>
        <p>Primera impresión bajo la cabecera. Ideal para notoriedad de marca y campañas tácticas.</p>
        <div class="price">25 EUR / mes</div>
      </div>
      <div class="slot">
        <h3>Banner en contenido</h3>
        <p>Ubicación destacada en el punto de mayor atención. Buen equilibrio entre visibilidad e interacción.</p>
        <div class="price">30 EUR / mes</div>
      </div>
      <div class="slot">
        <h3>Banner previo al pie de página</h3>
        <p>Impacto adicional para usuarios que terminan la lectura y ya han mostrado interés real.</p>
        <div class="price">15 EUR / mes</div>
      </div>
      <div class="slot">
        <h3>Patrocinio destacado</h3>
        <p>Texto comercial adaptado al nicho, recomendación editorial o integración de afiliación bajo solicitud.</p>
        <div class="price">Desde 35 EUR / mes</div>
      </div>
    </div>
  </section>

  <section>
    <h2>Tarifas orientativas</h2>
    <table>
      <thead>
        <tr><th>Formato</th><th>Objetivo</th><th>Precio</th></tr>
      </thead>
      <tbody>
        <tr><td>Banner superior</td><td>Máxima visibilidad</td><td>25 EUR / mes</td></tr>
        <tr><td>Banner en contenido</td><td>Clics y afinidad</td><td>30 EUR / mes</td></tr>
        <tr><td>Banner previo al pie</td><td>Frecuencia extra</td><td>15 EUR / mes</td></tr>
        <tr><td>Paquete del sitio</td><td>Superior + contenido</td><td>45 EUR / mes</td></tr>
        <tr><td>Exclusividad del sitio</td><td>3 espacios + exclusividad del dominio</td><td>75 EUR / mes</td></tr>
        <tr><td>Paquete de la red</td><td>Presencia estatica en 6 dominios</td><td>120 EUR / mes</td></tr>
        <tr><td>Exclusividad de la red</td><td>Espacios destacados + exclusividad de categoría</td><td>250 EUR / mes</td></tr>
      </tbody>
    </table>
    <p style="margin-top:.75rem">Datos de tráfico, capturas de GA4, creatividades admitidas, paquetes trimestrales y opciones de patrocinio ampliado disponibles bajo solicitud.</p>
    <p style="margin-top:.75rem">Los formatos se venden como espacios estáticos: texto, imagen ligera o enlace patrocinado integrado con el contexto de la página. Antes de publicar revisamos que la página de destino, el mensaje y la categoría encajen con la audiencia para proteger tanto al anunciante como la experiencia del usuario.</p>
    <p style="margin-top:.75rem">La venta directa nos permite evitar anuncios automáticos poco relevantes y priorizar marcas que aporten valor real: consultas profesionales, formación seria, productos de bienestar, herramientas de autoconocimiento y servicios afines. Si una campaña no encaja con la temática o puede generar desconfianza, no la publicamos.</p>
    <p style="margin-top:.75rem">Tratamos la red como un único cluster comercial: se puede reservar un dominio concreto, combinar varias webs o plantear presencia en las cinco propiedades con un mismo mensaje adaptado a cada intención de búsqueda.</p>
  </section>

  <section>
    <h2>Qué necesitamos para publicar</h2>
    <ul>
      <li>Marca, web de destino y objetivo de la campaña.</li>
      <li>Texto breve, imagen ligera o propuesta de patrocinio contextual.</li>
      <li>Duración prevista, dominio preferido y categoría que quieres ocupar.</li>
      <li>Confirmación de que la página de destino es clara, segura y coherente con el mensaje anunciado.</li>
    </ul>
    <p style="margin-top:.75rem">Una vez acordado el espacio, revisamos la creatividad, la publicamos de forma estática y podemos preparar una propuesta para ampliar presencia en otros dominios de la red si los datos acompañan.</p>
  </section>

  <div class="cta">
    <h2>Reservar un espacio</h2>
    <p>Escribe con tu marca, objetivo, creatividad o página de destino y te devolvemos propuesta, disponibilidad, paquetes del sitio y opciones para la red sin intermediarios.</p>
    <a class="btn" href="mailto:${CONTACT_EMAIL}?subject=Publicidad%20${domain}%20o%20red&body=Hola%2C%0A%0AMe%20interesa%20anunciarme%20en%20${domain}%20o%20en%20la%20red.%0A%0APaquete%20que%20me%20interesa%3A%0APeriodo%3A%0AWeb%2Fmarca%3A%0A%0AGracias">Contactar por correo</a>
  </div>

  <footer>
    <p>© $(date +%Y) ${name}</p>
    <p style="margin-top:.4rem"><a href="/">Inicio</a> · <a href="/privacy">Privacidad</a> · <a href="/terms">Términos</a></p>
  </footer>
</div>
</body>
</html>
EOF
}
