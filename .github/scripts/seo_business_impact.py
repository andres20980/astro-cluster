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


def estimate_site(site_key: str, rpm_eur: float):
    docs = Path("sites") / site_key / "docs"
    gsc = read_json(docs / "SEO_GSC_QUERIES.json") or {}
    ga4 = read_json(docs / "SEO_GA4_PAGES.json") or {}

    domain = gsc.get("domain") or ga4.get("domain") or ""
    clicks = sum(float(r.get("clicks", 0) or 0) for r in (gsc.get("topOpportunities") or []))
    impressions = sum(float(r.get("impressions", 0) or 0) for r in (gsc.get("topOpportunities") or []))
    page_opp = sum(float(r.get("opportunity", 0) or 0) for r in (gsc.get("topPageOpportunities") or []))
    ga4_views = sum(float(r.get("views", 0) or 0) for r in (ga4.get("pages") or [])[:10])

    projected_extra_clicks = page_opp * 0.08
    projected_extra_pageviews = max(projected_extra_clicks * 1.15, projected_extra_clicks)
    projected_revenue = (projected_extra_pageviews / 1000.0) * rpm_eur

    return {
        "site": site_key,
        "domain": domain,
        "inputs": {
            "topOpportunityClicks": clicks,
            "topOpportunityImpressions": impressions,
            "topPageOpportunity": page_opp,
            "ga4TopViews": ga4_views,
        },
        "projection": {
            "extraClicks": projected_extra_clicks,
            "extraPageviews": projected_extra_pageviews,
            "extraRevenueEur": projected_revenue,
        },
    }


def markdown(rows, rpm_eur):
    lines = ["## 💶 Impacto negocio estimado SEO (proxy)", ""]
    lines.append(f"RPM de referencia usado: **€{rpm_eur:.2f}**")
    lines.append("")
    lines.append("| Site | Dominio | Opp páginas | Clicks extra est. | PV extra est. | Ingreso extra est. €/semana |")
    lines.append("|---|---|---:|---:|---:|---:|")
    for r in rows:
        p = r["projection"]
        i = r["inputs"]
        lines.append(
            f"| {r['site']} | {r['domain'] or '-'} | {i['topPageOpportunity']:.1f} | "
            f"{p['extraClicks']:.1f} | {p['extraPageviews']:.1f} | {p['extraRevenueEur']:.2f} |"
        )

    total_rev = sum(r["projection"]["extraRevenueEur"] for r in rows)
    lines.append("")
    lines.append(f"Total estimado cluster: **€{total_rev:.2f}/semana**")
    lines.append("")
    lines.append("Nota: estimación proxy, no revenue real atribuido.")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="Estimate weekly business impact from SEO opportunities")
    ap.add_argument("--rpm-eur", type=float, default=5.0)
    ap.add_argument("--json", default="")
    ap.add_argument("--report", default="")
    args = ap.parse_args()

    rows = [estimate_site(site, args.rpm_eur) for site in SITES]
    rows.sort(key=lambda r: r["projection"]["extraRevenueEur"], reverse=True)

    payload = {
        "generatedAt": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "rpmEur": args.rpm_eur,
        "sites": rows,
        "clusterProjectedRevenueEur": sum(r["projection"]["extraRevenueEur"] for r in rows),
    }

    if args.json:
        Path(args.json).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    report = markdown(rows, args.rpm_eur)
    if args.report:
        Path(args.report).write_text(report + "\n", encoding="utf-8")

    print(json.dumps({"status": "ok", "sites": len(rows)}))


if __name__ == "__main__":
    main()
