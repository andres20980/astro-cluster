#!/usr/bin/env python3
import argparse
import json
from datetime import datetime, timezone
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


def normalize(value: str):
    return " ".join((value or "").lower().strip().split())


def gsc_rows(site_key: str):
    payload = read_json(Path("sites") / site_key / "docs" / "SEO_GSC_QUERIES.json") or {}
    rows = []
    for row in (payload.get("queries") or []):
        rows.append(
            {
                "query": normalize(str(row.get("query", ""))),
                "impressions": float(row.get("impressions", 0) or 0),
                "ctr": float(row.get("ctr", 0) or 0),
                "position": float(row.get("position", 0) or 0),
                "opportunity": float(row.get("opportunity", 0) or 0),
            }
        )
    return [r for r in rows if r["query"]]


def site_rules(site_key: str, rules_data: dict):
    site_cfg = (rules_data.get("sites") or {}).get(site_key) or {}
    by_query = site_cfg.get("rulesByQuery") or {}
    target_keywords = site_cfg.get("targetKeywords") or []
    return by_query, target_keywords


def score_candidate(keyword_row, gsc_match):
    base = 100.0 - float(keyword_row.get("priority", 99) or 99)
    if not gsc_match:
        return base

    impressions = gsc_match["impressions"]
    ctr = gsc_match["ctr"]
    position = gsc_match["position"]
    opportunity = gsc_match["opportunity"]

    score = base
    score += min(80.0, opportunity / 10.0)
    if impressions >= 40 and ctr < 0.02:
        score += 20.0
    if 4 <= position <= 20:
        score += 15.0
    if ctr == 0 and impressions >= 10:
        score += 10.0
    return score


def recommendation_for_site(site_key: str, rules_data: dict, max_items: int):
    by_query, target_keywords = site_rules(site_key, rules_data)
    gsc = gsc_rows(site_key)
    gsc_map = {normalize(r["query"]): r for r in gsc}

    candidates = []
    for kw in target_keywords:
        q = normalize(str(kw.get("query", "")))
        if not q or q not in by_query:
            continue
        score = score_candidate(kw, gsc_map.get(q))
        candidates.append(
            {
                "query": q,
                "score": round(score, 3),
                "reason": "gsc_signal" if q in gsc_map else "priority_fallback",
                "matchedSignals": [
                    "recommendation_seed",
                    "gsc_query_match" if q in gsc_map else "keyword_priority",
                ],
            }
        )

    if not candidates:
        return {
            "generatedAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "site": site_key,
            "topRecommendations": [],
            "notes": "no_rules_or_keywords",
        }

    candidates.sort(key=lambda c: c["score"], reverse=True)
    return {
        "generatedAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "site": site_key,
        "topRecommendations": candidates[:max_items],
        "notes": "seeded_from_rules_and_gsc",
    }


def main():
    parser = argparse.ArgumentParser(description="Generate SEO recommendation seed files per site")
    parser.add_argument("--max-items", type=int, default=3)
    parser.add_argument("--rules", default=".github/config/seo-autopatch-rules.json")
    args = parser.parse_args()

    rules_data = read_json(Path(args.rules)) or {}

    generated = []
    for site in SITES:
        payload = recommendation_for_site(site, rules_data, max_items=max(1, args.max_items))
        target = Path("sites") / site / "docs" / "SEO_AGENT_RECOMMENDATIONS.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        generated.append({"site": site, "count": len(payload.get("topRecommendations") or [])})

    print(json.dumps({"generated": generated}, ensure_ascii=False))


if __name__ == "__main__":
    main()
