"""
Interpretación de carta astral con Gemini (free tier).

Usa la API REST directamente con httpx — sin SDK pesado.
Incluye caché en memoria (24 h) para evitar llamadas repetidas.
"""

import hashlib
import os
import json
import time
import httpx

GEMINI_KEY = os.environ.get("GEMINI_API_KEY", "")
GEMINI_MODEL = "gemini-2.5-flash"
GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"
MAX_OUTPUT_TOKENS = int(os.environ.get("GEMINI_MAX_OUTPUT_TOKENS", "16000"))
MAX_CONTINUATIONS = int(os.environ.get("GEMINI_MAX_CONTINUATIONS", "2"))

# --------------- caché en memoria ---------------
_CACHE: dict[str, tuple[float, str]] = {}   # key → (timestamp, html)
_CACHE_TTL = 86_400  # 24 horas
_CACHE_MAX = 200     # entradas máximo (evita memory leak)

SYSTEM_PROMPT = """\
Eres un astrólogo profesional de primer nivel que redacta interpretaciones de cartas astrales natales.
Tu interpretación debe ser EXHAUSTIVA, PROFUNDA y PERSONALIZADA. Escribe en español, con tono cercano (tutea al lector).

Estructura tu respuesta en HTML (usa <h3>, <p>, <ul>, <li>). Incluye TODAS estas secciones, \
desarrollando cada una con al menos 2-3 párrafos sustanciales:

<h3>☉ Tu esencia: Sol en {signo} {grados} — Casa {n}</h3>
Explica el signo solar, su grado exacto, y la casa donde cae. Cómo afecta a la identidad, \
propósito de vida, ego y vitalidad. Relaciona el signo con la casa para dar contexto práctico.

<h3>☽ Tu mundo emocional: Luna en {signo} {grados} — Casa {n}</h3>
La Luna rige las emociones, instintos, necesidades inconscientes y relación con la madre. \
Explica cómo el signo lunar moldea la vida emocional y cómo la casa matiza su expresión.

<h3>↑ Tu máscara social: Ascendente en {signo} {grados}</h3>
Primera impresión que causa, apariencia física, forma de abordar la vida, estilo personal.

<h3>♀ Venus en {signo} — Casa {n}: Tu forma de amar</h3>
Valores, estética, forma de atraer y relacionarse en pareja. Qué busca en el amor.

<h3>♂ Marte en {signo} — Casa {n}: Tu motor de acción</h3>
Energía, impulso sexual, forma de afirmar la voluntad, gestión de la ira y los conflictos.

<h3>☿ Mercurio en {signo} — Casa {n}: Tu mente</h3>
Estilo de comunicación, forma de pensar, aprendizaje, humor intelectual.

<h3>♃ Júpiter en {signo} — Casa {n}: Tu expansión</h3>
Dónde y cómo se expande, crece, tiene suerte. Filosofía de vida, viajes, estudios superiores.

<h3>♄ Saturno en {signo} — Casa {n}: Tus lecciones</h3>
Disciplina, responsabilidades, karmas, miedos, lo que cuesta pero da los mayores frutos.

<h3>⚡ Planetas generacionales</h3>
Analiza Urano, Neptuno y Plutón: signo, casa, y cómo afectan a nivel personal (no solo generacional). \
Incluye el Nodo Norte si está disponible — señala el propósito kármico.

<h3>🏠 Análisis de Casas destacadas</h3>
Identifica las casas con más planetas (stelliums) o con planetas importantes. \
Explica qué área de la vida está más activada y cómo los planetas interactúan ahí.

<h3>🔗 Aspectos clave</h3>
Analiza las conjunciones, oposiciones, trígonos y cuadraturas más importantes. \
Explica cómo interactúan los planetas entre sí y qué tensiones o talentos crean. \
No te limites a listar — interpreta cada aspecto significativo.

<h3>⚖️ Equilibrio elemental y modal</h3>
Analiza la distribución de elementos (fuego, tierra, aire, agua) y modalidades (cardinal, fijo, mutable). \
¿Qué predomina, qué falta? Cómo afecta al carácter global.

<h3>🔮 Síntesis y misión de vida</h3>
Haz una síntesis global de 3-4 párrafos integrando todo lo anterior. \
Define el propósito vital, fortalezas principales, desafíos a trabajar y consejos prácticos.

REGLAS:
- Sé ESPECÍFICO: siempre menciona grados, signos y casas concretas.
- Cada sección debe tener SUSTANCIA real, no frases genéricas que apliquen a cualquiera.
- Relaciona los planetas entre sí (aspectos) al describir cada uno.
- Si se indica el sexo, adapta el lenguaje y las referencias.
- Extensión MÍNIMA: 3000 palabras. Máxima: 5000 palabras. Sé generoso en el contenido.
- Solo devuelve HTML limpio. Sin markdown, sin bloques de código, sin preámbulos.\
"""


def _build_chart_summary(chart: dict) -> str:
    """Convierte el dict de la carta en un prompt textual para Gemini."""
    lines = []
    b = chart.get("birth", {})
    lines.append(f"Nacimiento: {b.get('day')}/{b.get('month')}/{b.get('year')} "
                 f"a las {b.get('hour')}:{b.get('minute'):02d}, "
                 f"{b.get('city', 'ubicación desconocida')} "
                 f"({b.get('lat')}, {b.get('lng')})")

    sex = chart.get("sex")
    if sex:
        label = "Masculino" if sex == "M" else "Femenino"
        lines.append(f"Sexo: {label}")

    asc = chart.get("ascendant", {})
    lines.append(f"Ascendente: {asc.get('sign')} {asc.get('degree_dms', '')}")

    mc = chart.get("midheaven", {})
    lines.append(f"Medio Cielo (MC): {mc.get('sign')} {mc.get('degree_dms', '')}")

    lines.append("\nPlanetas:")
    for p in chart.get("planets", []):
        lines.append(f"  {p['glyph']} {p['name']}: {p['sign']} {p['degree_dms']} — Casa {p['house']}")

    nn = chart.get("north_node")
    if nn:
        lines.append(f"  Nodo Norte: {nn['sign']} {nn.get('degree_dms', '')}")

    lines.append("\nCasas:")
    for h in chart.get("houses", []):
        lines.append(f"  Casa {h['number']}: {h['sign']} {h['degree_dms']}")

    lines.append("\nAspectos principales:")
    for a in chart.get("aspects", []):
        if a.get("orb", 99) <= 8:
            lines.append(f"  {a['p1']} {a['glyph']} {a['aspect']} {a['p2']} (orbe {a['orb']}°)")

    elem = chart.get("elements", {})
    lines.append(f"\nDistribución elementos: {json.dumps(elem, ensure_ascii=False)}")
    mod = chart.get("modalities", {})
    lines.append(f"Distribución modalidades: {json.dumps(mod, ensure_ascii=False)}")

    return "\n".join(lines)


def _clean_model_text(text: str) -> str:
    """Elimina envoltorios markdown habituales sin tocar el HTML interno."""
    text = text.strip()
    if text.startswith("```html"):
        text = text[7:]
    if text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    return text.strip()


def _extract_text_and_finish_reason(data: dict) -> tuple[str, str]:
    """Extrae texto y motivo de finalización de la respuesta de Gemini."""
    candidate = data["candidates"][0]
    parts = candidate.get("content", {}).get("parts", [])
    text = "".join(part.get("text", "") for part in parts)
    return text, candidate.get("finishReason", "")


def _looks_incomplete(text: str) -> bool:
    """Detecta respuestas que no llegaron a la síntesis o terminan cortadas."""
    clean = _clean_model_text(text)
    if "Síntesis y misión de vida" not in clean and "Sintesis y misión de vida" not in clean:
        return True
    return bool(clean) and clean[-1] not in ".!?»”'>"


async def _generate_content(client: httpx.AsyncClient, contents: list[dict]) -> tuple[str, str]:
    payload = {
        "system_instruction": {"parts": [{"text": SYSTEM_PROMPT}]},
        "contents": contents,
        "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": MAX_OUTPUT_TOKENS,
        },
    }
    resp = await client.post(
        GEMINI_URL,
        params={"key": GEMINI_KEY},
        json=payload,
    )
    resp.raise_for_status()
    return _extract_text_and_finish_reason(resp.json())


async def interpret_chart(chart: dict, sex: str | None = None) -> str:
    """Envía la carta a Gemini y devuelve HTML con la interpretación."""
    if sex:
        chart["sex"] = sex
    if not GEMINI_KEY:
        raise RuntimeError("GEMINI_API_KEY no configurada")

    # --- cache lookup ---
    b = chart.get("birth", {})
    cache_key = hashlib.sha256(json.dumps(
        [b.get("year"), b.get("month"), b.get("day"),
         b.get("hour"), b.get("minute"),
         round(b.get("lat", 0), 2), round(b.get("lng", 0), 2),
         chart.get("sex")],
        sort_keys=True,
    ).encode()).hexdigest()

    now = time.monotonic()
    if cache_key in _CACHE:
        ts, html = _CACHE[cache_key]
        if now - ts < _CACHE_TTL:
            return html
        del _CACHE[cache_key]

    # evict oldest if full
    if len(_CACHE) >= _CACHE_MAX:
        oldest = min(_CACHE, key=lambda k: _CACHE[k][0])
        del _CACHE[oldest]

    chart_text = _build_chart_summary(chart)

    async with httpx.AsyncClient(timeout=120) as client:
        initial_prompt = f"Interpreta esta carta astral natal:\n\n{chart_text}"
        contents = [{"role": "user", "parts": [{"text": initial_prompt}]}]
        text, finish_reason = await _generate_content(client, contents)

        continuations = 0
        while (finish_reason == "MAX_TOKENS" or _looks_incomplete(text)) and continuations < MAX_CONTINUATIONS:
            contents = [
                {"role": "user", "parts": [{"text": initial_prompt}]},
                {"role": "model", "parts": [{"text": text}]},
                {
                    "role": "user",
                    "parts": [{
                        "text": (
                            "La respuesta anterior quedó incompleta. "
                            "Continúa exactamente desde donde se interrumpió si estaba cortada; "
                            "si faltan secciones, añade solo las secciones pendientes, sin repetir contenido, "
                            "manteniendo HTML limpio y cerrando la interpretación con la sección "
                            "'Síntesis y misión de vida'."
                        )
                    }],
                },
            ]
            more_text, finish_reason = await _generate_content(client, contents)
            text += more_text
            continuations += 1

        if finish_reason == "MAX_TOKENS" or _looks_incomplete(text):
            raise RuntimeError("La interpretación quedó incompleta. Inténtalo de nuevo.")

    result = _clean_model_text(text)
    _CACHE[cache_key] = (time.monotonic(), result)
    return result
