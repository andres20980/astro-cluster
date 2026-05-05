#!/usr/bin/env python3
"""Build static ES-ES chakra site from extracted quiz data."""

from __future__ import annotations

import argparse
import json
from datetime import date
from pathlib import Path


def _render_step_card(step: dict) -> str:
    question = step.get("question", "").strip() or f"Paso {step.get('step')}"
    answers = step.get("answers", [])
    answer_html = "".join(f"<li>{a}</li>" for a in answers[:8])
    return f"""
      <article class=\"step-card\">
        <p class=\"step-kicker\">Paso {step.get('step')} de 23</p>
        <h2>{question}</h2>
        <ul>{answer_html}</ul>
      </article>
    """


def build(public_dir: Path, quiz_data_path: Path, domain: str, ga4: str, adsense_pub: str) -> None:
    payload = json.loads(quiz_data_path.read_text(encoding="utf-8"))
    steps = payload.get("steps", [])

    public_dir.mkdir(parents=True, exist_ok=True)
    chakra_dir = public_dir / "chakras"
    chakra_dir.mkdir(parents=True, exist_ok=True)

    today = date.today().isoformat()

    steps_cards = "\n".join(_render_step_card(step) for step in steps)

    index_html = f"""<!DOCTYPE html>
<html lang=\"es\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>Meditación de Chakras | Test de 23 Preguntas en Español</title>
  <meta name=\"description\" content=\"Descubre tu estado energético con un test de 23 preguntas sobre chakras y recibe una ruta guiada de meditación en español de España.\">
  <link rel=\"canonical\" href=\"https://{domain}/\">
  <meta property=\"og:title\" content=\"Meditación de Chakras | Test de 23 Preguntas\">
  <meta property=\"og:description\" content=\"Funnel completo de 23 pasos sobre chakras adaptado a español de España.\">
  <meta property=\"og:type\" content=\"website\">
  <meta property=\"og:url\" content=\"https://{domain}/\">
  <meta name=\"robots\" content=\"index,follow\">
  <script async src=\"https://www.googletagmanager.com/gtag/js?id={ga4}\"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){{dataLayer.push(arguments);}}
    gtag('js', new Date());
    gtag('config', '{ga4}', {{ send_page_view: true }});
  </script>
  <script async src=\"https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client={adsense_pub}\" crossorigin=\"anonymous\"></script>
  <style>
    :root{{--bg:#030712;--ink:#e5e7eb;--muted:#9ca3af;--card:#0b1220;--line:#1f2937;--accent:#22d3ee;--accent2:#f59e0b}}
    *{{box-sizing:border-box}}
    body{{margin:0;font-family:Inter,system-ui,sans-serif;background:radial-gradient(circle at 20% 10%,#0f1b34 0%,#030712 42%,#02050a 100%);color:var(--ink)}}
    .wrap{{max-width:980px;margin:0 auto;padding:2rem 1rem 3rem}}
    .hero{{text-align:center;margin-bottom:1.5rem}}
    .hero h1{{margin:.2rem 0 0;font-size:clamp(1.7rem,4.5vw,2.6rem);line-height:1.15}}
    .hero p{{color:var(--muted);max-width:760px;margin:.9rem auto 0;line-height:1.7}}
    .cta{{display:flex;gap:.8rem;justify-content:center;flex-wrap:wrap;margin:1rem 0 1.4rem}}
    .btn{{background:linear-gradient(135deg,var(--accent),#38bdf8);border:0;color:#04111f;padding:.8rem 1.2rem;border-radius:999px;text-decoration:none;font-weight:700}}
    .btn.alt{{background:#111827;color:var(--ink);border:1px solid var(--line)}}
    .grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:.9rem}}
    .step-card{{background:linear-gradient(160deg,#081226 0%,#0b1220 60%,#0a1020 100%);border:1px solid var(--line);border-radius:14px;padding:1rem;box-shadow:0 10px 30px rgba(0,0,0,.25)}}
    .step-card h2{{font-size:1rem;margin:.35rem 0 .65rem}}
    .step-kicker{{font-size:.73rem;color:var(--accent2);font-weight:700;letter-spacing:.04em;text-transform:uppercase}}
    .step-card ul{{margin:0;padding-left:1rem;color:var(--muted);line-height:1.6}}
    .foot{{margin-top:2rem;color:var(--muted);font-size:.82rem;text-align:center}}
    .foot a{{color:var(--accent)}}
  </style>
</head>
<body>
  <main class=\"wrap\">
    <section class=\"hero\">
      <p style=\"color:var(--accent2);font-weight:700;letter-spacing:.05em;text-transform:uppercase\">Meditación y Mindfulness</p>
      <h1>Test de Chakras en 23 Preguntas</h1>
      <p>
        Versión en español de España basada en el flujo de referencia de Slowdive,
        reconstruida en estático para SEO y rendimiento en el cluster.
      </p>
      <div class=\"cta\">
        <a class=\"btn\" href=\"/chakras/1\">Empezar ahora</a>
        <a class=\"btn alt\" href=\"#pasos\">Ver los 23 pasos</a>
      </div>
    </section>

    <section id=\"pasos\" class=\"grid\">{steps_cards}</section>

    <section class=\"foot\">
      <p>Última generación: {today}</p>
      <p><a href=\"/privacy\">Privacidad</a> · <a href=\"/terms\">Términos</a> · <a href=\"/publicidad\">Publicidad</a></p>
    </section>
  </main>
</body>
</html>
"""

    (public_dir / "index.html").write_text(index_html, encoding="utf-8")

    for idx, step in enumerate(steps, start=1):
        next_href = f"/chakras/{idx + 1}" if idx < len(steps) else "/"
        prev_href = f"/chakras/{idx - 1}" if idx > 1 else "/"
        answers = "".join(f"<li>{a}</li>" for a in step.get("answers", []))
        question = step.get("question", "").strip() or f"Paso {idx}"

        page = f"""<!DOCTYPE html>
<html lang=\"es\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>Paso {idx} de 23 | Test de Chakras</title>
  <meta name=\"description\" content=\"Paso {idx} del test de chakras en español de España.\">
  <link rel=\"canonical\" href=\"https://{domain}/chakras/{idx}\">
  <meta name=\"robots\" content=\"index,follow\">
  <style>
    body{{margin:0;font-family:Inter,system-ui,sans-serif;background:#050912;color:#e5e7eb}}
    .wrap{{max-width:760px;margin:0 auto;padding:2rem 1rem}}
    .k{{color:#f59e0b;font-size:.8rem;font-weight:700;text-transform:uppercase}}
    h1{{font-size:1.45rem}}
    .card{{background:#0b1220;border:1px solid #1f2937;border-radius:14px;padding:1rem}}
    ul{{line-height:1.7;color:#9ca3af}}
    .nav{{display:flex;justify-content:space-between;margin-top:1rem}}
    a{{color:#22d3ee;text-decoration:none}}
  </style>
</head>
<body>
  <main class=\"wrap\">
    <p class=\"k\">Paso {idx} de 23</p>
    <div class=\"card\">
      <h1>{question}</h1>
      <ul>{answers}</ul>
    </div>
    <div class=\"nav\">
      <a href=\"{prev_href}\">← Paso anterior</a>
      <a href=\"{next_href}\">Siguiente paso →</a>
    </div>
  </main>
</body>
</html>
"""
        (chakra_dir / f"{idx}.html").write_text(page, encoding="utf-8")

    (public_dir / "404.html").write_text(
        "<html><head><meta charset='utf-8'><title>404</title></head><body><h1>404</h1><p>Página no encontrada.</p><p><a href='/'>Volver</a></p></body></html>",
        encoding="utf-8",
    )

    (public_dir / "ads.txt").write_text(f"google.com, {adsense_pub.replace('ca-pub-', 'pub-')}, DIRECT, f08c47fec0942fa0\n", encoding="utf-8")
    (public_dir / "robots.txt").write_text(
        f"User-agent: *\nAllow: /\n\nSitemap: https://{domain}/sitemap.xml\n", encoding="utf-8"
    )

    sitemap_urls = [f"  <url><loc>https://{domain}/</loc><lastmod>{today}</lastmod><changefreq>weekly</changefreq><priority>1.0</priority></url>"]
    for idx in range(1, len(steps) + 1):
        sitemap_urls.append(
            f"  <url><loc>https://{domain}/chakras/{idx}</loc><lastmod>{today}</lastmod><changefreq>monthly</changefreq><priority>0.7</priority></url>"
        )
    sitemap_urls.extend(
        [
            f"  <url><loc>https://{domain}/privacy</loc><lastmod>{today}</lastmod><changefreq>yearly</changefreq><priority>0.4</priority></url>",
            f"  <url><loc>https://{domain}/terms</loc><lastmod>{today}</lastmod><changefreq>yearly</changefreq><priority>0.4</priority></url>",
            f"  <url><loc>https://{domain}/publicidad</loc><lastmod>{today}</lastmod><changefreq>monthly</changefreq><priority>0.5</priority></url>",
        ]
    )
    (public_dir / "sitemap.xml").write_text(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
        + "\n".join(sitemap_urls)
        + "\n</urlset>\n",
        encoding="utf-8",
    )

    legal_common = """
    <style>body{font-family:Inter,system-ui,sans-serif;margin:0;background:#f8fafc;color:#0f172a}.wrap{max-width:760px;margin:0 auto;padding:2rem 1rem}h1{margin:0 0 1rem}p,li{line-height:1.7;color:#334155}a{color:#0369a1}</style>
    """

    (public_dir / "privacy.html").write_text(
        f"""<!DOCTYPE html><html lang=\"es\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>Privacidad</title>{legal_common}</head><body><main class=\"wrap\"><h1>Política de privacidad</h1><p>Este sitio muestra un test informativo de chakras en español de España. No solicita registro ni procesa datos personales más allá de métricas agregadas de analítica.</p><p>Contacto: publicidad@carta-astral-gratis.es</p><p><a href=\"/\">Volver al inicio</a></p></main></body></html>""",
        encoding="utf-8",
    )

    (public_dir / "terms.html").write_text(
        f"""<!DOCTYPE html><html lang=\"es\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>Términos</title>{legal_common}</head><body><main class=\"wrap\"><h1>Términos de uso</h1><p>El contenido es informativo y de entretenimiento. No constituye asesoramiento médico, psicológico, legal ni financiero.</p><ul><li>No usar con fines ilícitos.</li><li>No realizar scraping agresivo del servicio público.</li></ul><p><a href=\"/\">Volver al inicio</a></p></main></body></html>""",
        encoding="utf-8",
    )

    (public_dir / "publicidad.html").write_text(
        f"""<!DOCTYPE html><html lang=\"es\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>Publicidad</title>{legal_common}</head><body><main class=\"wrap\"><h1>Publicidad en meditacion-chakras.es</h1><p>Ofrecemos posiciones directas para marcas de bienestar, mindfulness y formación.</p><p>Contacto comercial: <a href=\"mailto:publicidad@carta-astral-gratis.es\">publicidad@carta-astral-gratis.es</a></p><p><a href=\"/\">Volver al inicio</a></p></main></body></html>""",
        encoding="utf-8",
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build static chakra site")
    parser.add_argument("--public-dir", required=True)
    parser.add_argument("--quiz-data", required=True)
    parser.add_argument("--domain", required=True)
    parser.add_argument("--ga4", required=True)
    parser.add_argument("--adsense-pub", required=True)
    args = parser.parse_args()

    build(
        public_dir=Path(args.public_dir),
        quiz_data_path=Path(args.quiz_data),
        domain=args.domain,
        ga4=args.ga4,
        adsense_pub=args.adsense_pub,
    )
