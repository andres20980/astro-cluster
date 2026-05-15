#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


SITES = [
    "carta-astral",
    "compatibilidad-signos",
    "tarot-del-dia",
    "calcular-numerologia",
    "horoscopo-de-hoy",
    "meditacion-chakras",
]

DOMAINS = {
    "carta-astral": "carta-astral-gratis.es",
    "compatibilidad-signos": "compatibilidad-signos.es",
    "tarot-del-dia": "tarot-del-dia.es",
    "calcular-numerologia": "calcular-numerologia.es",
    "horoscopo-de-hoy": "horoscopo-de-hoy.es",
    "meditacion-chakras": "meditacion-chakras.es",
}

FAMILY_INTENT = {
    "home": "entry",
    "content": "informational",
    "sign_profiles": "profile",
    "sign_hub": "hub",
    "pair_pages": "comparison",
    "major_arcana": "profile",
    "major_arcana_hub": "hub",
    "minor_arcana": "informational",
    "number_pages": "profile",
    "number_hub": "hub",
    "sign_pages": "daily",
    "chakra_steps": "funnel",
}


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def classify_family(site_key: str, path: str):
    p = (path or "/").split("?", 1)[0] or "/"
    if p == "/":
        return "home"
    if site_key == "carta-astral":
        if p.startswith("/signos/") and p != "/signos/":
            return "sign_profiles"
        if p.startswith("/signos/"):
            return "sign_hub"
        return "content"
    if site_key == "compatibilidad-signos":
        return "pair_pages"
    if site_key == "tarot-del-dia":
        if p.startswith("/arcanos-mayores/") and p != "/arcanos-mayores/":
            return "major_arcana"
        if p.startswith("/arcanos-mayores/"):
            return "major_arcana_hub"
        if p.startswith("/arcanos-menores/"):
            return "minor_arcana"
        return "content"
    if site_key == "calcular-numerologia":
        if p.startswith("/numero-de-vida/") and p != "/numero-de-vida/":
            return "number_pages"
        if p.startswith("/numero-de-vida/"):
            return "number_hub"
        return "content"
    if site_key == "horoscopo-de-hoy":
        return "sign_pages"
    if site_key == "meditacion-chakras":
        if p.startswith("/chakras/") and p != "/chakras/":
            return "chakra_steps"
        return "home"
    return "content"


def site_candidates(site_key: str):
    docs = Path("sites") / site_key / "docs"
    gsc = read_json(docs / "SEO_GSC_QUERIES.json") or {}
    ga4 = read_json(docs / "SEO_GA4_PAGES.json") or {}

    source_pages = sorted(
        (ga4.get("pages") or []),
        key=lambda p: (
            -float(p.get("views", 0) or 0),
            float(p.get("bounceRate", 0) or 0),
        ),
    )[:6]

    dest_pages = sorted(
        (gsc.get("topPageOpportunities") or gsc.get("pages") or []),
        key=lambda p: -float(p.get("opportunity", 0) or 0),
    )[:8]

    recs = []
    for src in source_pages:
        src_path = src.get("path", "/")
        src_family = classify_family(site_key, src_path)
        src_intent = FAMILY_INTENT.get(src_family, "informational")

        candidates = [
            d
            for d in dest_pages
            if d.get("path") and d.get("path") != src_path
        ]
        if not candidates:
            continue

        target = candidates[0]
        tgt_path = target.get("path", "/")
        tgt_family = classify_family(site_key, tgt_path)
        tgt_intent = FAMILY_INTENT.get(tgt_family, "informational")

        anchor = f"Descubre también: {tgt_path.strip('/').replace('-', ' ') or 'herramienta completa'}"
        recs.append(
            {
                "site": site_key,
                "type": "intra_site",
                "sourcePath": src_path,
                "sourceIntent": src_intent,
                "targetPath": tgt_path,
                "targetIntent": tgt_intent,
                "targetOpportunity": float(target.get("opportunity", 0) or 0),
                "anchorSuggestion": anchor,
            }
        )

    return recs


def cross_site_recs(cluster_scores):
    rows = sorted(cluster_scores, key=lambda r: -float(r.get("rawScore", 0) or 0))
    if len(rows) < 2:
        return []
    primary = rows[0]
    out = []
    for row in rows[1:4]:
        out.append(
            {
                "type": "cross_site",
                "fromSite": row.get("site"),
                "fromDomain": DOMAINS.get(row.get("site"), ""),
                "toSite": primary.get("site"),
                "toDomain": DOMAINS.get(primary.get("site"), ""),
                "suggestion": "Añadir bloque de recirculación hacia el site con mayor score SEO semanal.",
            }
        )
    return out


def markdown(intra, cross):
    lines = ["## 🔗 Recomendaciones automáticas de interlinking", ""]
    if intra:
        lines.append("### Intra-site")
        lines.append("| Site | Source | Target | Opp target | Anchor sugerido |")
        lines.append("|---|---|---|---:|---|")
        for r in intra[:40]:
            lines.append(
                f"| {r['site']} | {r['sourcePath']} | {r['targetPath']} | "
                f"{r['targetOpportunity']:.1f} | {r['anchorSuggestion']} |"
            )
    else:
        lines.append("Sin recomendaciones intra-site disponibles.")

    lines.append("")
    lines.append("### Cross-site")
    if cross:
        lines.append("| From | To | Acción |")
        lines.append("|---|---|---|")
        for r in cross:
            lines.append(f"| {r['fromSite']} | {r['toSite']} | {r['suggestion']} |")
    else:
        lines.append("Sin recomendaciones cross-site disponibles.")

    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="Build SEO interlink recommendations from GA4+GSC signals")
    ap.add_argument("--json", default="")
    ap.add_argument("--report", default="")
    args = ap.parse_args()

    intra = []
    for site in SITES:
        intra.extend(site_candidates(site))

    scorecard = read_json(Path("/tmp/seo-scorecard.json")) or {}
    cross = cross_site_recs(scorecard.get("sites") or [])

    payload = {
        "generatedAt": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "intraSite": intra,
        "crossSite": cross,
    }

    if args.json:
        Path(args.json).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    rep = markdown(intra, cross)
    if args.report:
        Path(args.report).write_text(rep + "\n", encoding="utf-8")

    print(json.dumps({"intra": len(intra), "cross": len(cross)}))


if __name__ == "__main__":
    main()
