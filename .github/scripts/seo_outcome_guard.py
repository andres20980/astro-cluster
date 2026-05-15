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


def read_json(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception:
        return None


def weighted_ctr(rows):
    total_impr = 0.0
    total_clicks = 0.0
    for row in rows or []:
        i = float(row.get("impressions", 0) or 0)
        c = float(row.get("clicks", 0) or 0)
        total_impr += i
        total_clicks += c
    if total_impr <= 0:
        return 0.0
    return total_clicks / total_impr


def top_page_opportunity(rows):
    return float(sum(float(r.get("opportunity", 0) or 0) for r in (rows or [])[:5]))


def evaluate_site(site_key, ctr_drop_threshold, opp_growth_min):
    docs = Path("sites") / site_key / "docs"
    current = read_json(docs / "SEO_GSC_QUERIES.json")
    baseline = read_json(docs / "SEO_GSC_QUERIES.pre_patch.json")

    if not current or not baseline:
        return {
            "site": site_key,
            "status": "skipped",
            "reason": "missing_baseline_or_current",
            "shouldRollback": False,
        }

    current_queries = current.get("topOpportunities") or []
    baseline_queries = baseline.get("topOpportunities") or []
    current_pages = current.get("topPageOpportunities") or []
    baseline_pages = baseline.get("topPageOpportunities") or []

    current_ctr = weighted_ctr(current_queries)
    baseline_ctr = weighted_ctr(baseline_queries)
    current_opp = top_page_opportunity(current_pages)
    baseline_opp = top_page_opportunity(baseline_pages)

    ctr_ratio = (current_ctr / baseline_ctr) if baseline_ctr > 0 else 1.0
    opp_ratio = (current_opp / baseline_opp) if baseline_opp > 0 else 1.0

    should_rollback = False
    reasons = []
    if baseline_ctr > 0 and ctr_ratio < (1 - ctr_drop_threshold):
        should_rollback = True
        reasons.append(
            f"CTR cayó {((1 - ctr_ratio) * 100):.1f}% (base={baseline_ctr:.4f}, now={current_ctr:.4f})"
        )

    if baseline_opp > 0 and opp_ratio < opp_growth_min:
        should_rollback = True
        reasons.append(
            f"Oportunidad de páginas bajó a {opp_ratio:.2f}x (base={baseline_opp:.2f}, now={current_opp:.2f})"
        )

    return {
        "site": site_key,
        "status": "ok",
        "baselineCtr": baseline_ctr,
        "currentCtr": current_ctr,
        "ctrRatio": ctr_ratio,
        "baselinePageOpportunity": baseline_opp,
        "currentPageOpportunity": current_opp,
        "pageOpportunityRatio": opp_ratio,
        "shouldRollback": should_rollback,
        "reasons": reasons,
    }


def main():
    parser = argparse.ArgumentParser(description="Detect post-patch SEO regressions and signal rollback")
    parser.add_argument("--site", default="all", help="site key or all")
    parser.add_argument("--ctr-drop-threshold", type=float, default=0.2, help="CTR drop ratio to trigger rollback")
    parser.add_argument("--opp-growth-min", type=float, default=0.85, help="Min ratio for top-page opportunity")
    args = parser.parse_args()

    sites = SITES if args.site == "all" else [args.site]
    results = [evaluate_site(site, args.ctr_drop_threshold, args.opp_growth_min) for site in sites]
    regressions = [r for r in results if r.get("shouldRollback")]

    print(
        json.dumps(
            {
                "checked": len(results),
                "regressions": regressions,
                "results": results,
                "shouldRollback": len(regressions) > 0,
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
