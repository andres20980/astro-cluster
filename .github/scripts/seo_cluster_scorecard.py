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


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def site_score(site_key: str):
    docs = Path("sites") / site_key / "docs"
    gsc = read_json(docs / "SEO_GSC_QUERIES.json") or {}
    ga4 = read_json(docs / "SEO_GA4_PAGES.json") or {}
    fam = read_json(docs / "SEO_TEMPLATE_FAMILIES.json") or {}

    top_query_opportunity = sum(float(r.get("opportunity", 0) or 0) for r in (gsc.get("topOpportunities") or [])[:5])
    top_page_opportunity = sum(float(r.get("opportunity", 0) or 0) for r in (gsc.get("topPageOpportunities") or [])[:5])
    striking_distance = len(gsc.get("strikingDistanceQueries") or [])

    homepage = ga4.get("homepage") or {}
    homepage_views = float(homepage.get("views", 0) or 0)
    weak_homepage = 1 if ga4.get("weakHomepageEngagement") else 0

    top_family = fam.get("topFamily") or {}
    family_score = float(top_family.get("score", 0) or 0)

    raw_score = (
        (top_query_opportunity * 0.35)
        + (top_page_opportunity * 0.35)
        + (striking_distance * 20)
        + (homepage_views * 2)
        + (family_score * 0.1)
        - (weak_homepage * 80)
    )

    return {
        "site": site_key,
        "domain": gsc.get("domain") or ga4.get("domain") or fam.get("domain") or "",
        "rawScore": raw_score,
        "signals": {
            "topQueryOpportunity": top_query_opportunity,
            "topPageOpportunity": top_page_opportunity,
            "strikingDistanceCount": striking_distance,
            "homepageViews": homepage_views,
            "weakHomepageEngagement": bool(weak_homepage),
            "topFamilyScore": family_score,
        },
    }


def markdown(rows):
    lines = []
    lines.append("## 📈 Scorecard SEO del cluster")
    lines.append("")
    lines.append("| Site | Dominio | Score | Query Opp | Page Opp | Striking Dist | Home Views | Weak Home |")
    lines.append("|---|---|---:|---:|---:|---:|---:|---:|")
    for r in rows:
        s = r["signals"]
        lines.append(
            f"| {r['site']} | {r['domain'] or '-'} | {r['rawScore']:.1f} | "
            f"{s['topQueryOpportunity']:.1f} | {s['topPageOpportunity']:.1f} | "
            f"{s['strikingDistanceCount']} | {s['homepageViews']:.0f} | "
            f"{'yes' if s['weakHomepageEngagement'] else 'no'} |"
        )
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="Build SEO scorecard across cluster sites")
    ap.add_argument("--json", default="")
    ap.add_argument("--report", default="")
    args = ap.parse_args()

    rows = [site_score(site) for site in SITES]
    rows.sort(key=lambda r: r["rawScore"], reverse=True)

    payload = {
        "generatedAt": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "sites": rows,
    }

    if args.json:
        Path(args.json).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    report = markdown(rows)
    if args.report:
        Path(args.report).write_text(report + "\n", encoding="utf-8")

    print(json.dumps({"sites": len(rows), "topSite": rows[0]["site"] if rows else ""}))


if __name__ == "__main__":
    main()
