#!/usr/bin/env python3
import argparse
import json
import sys
from datetime import datetime, timezone


SITES = [
    "carta-astral",
    "compatibilidad-signos",
    "tarot-del-dia",
    "calcular-numerologia",
    "horoscopo-de-hoy",
    "meditacion-chakras",
]
MAX_AGE_DAYS = 21


def read_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return None


def is_fresh(payload):
    if not payload or not payload.get("generatedAt"):
        return False
    try:
        ts = datetime.fromisoformat(payload["generatedAt"].replace("Z", "+00:00"))
    except Exception:
        return False
    return (datetime.now(timezone.utc) - ts).days <= MAX_AGE_DAYS


def score_site(site_key):
    score = 0.0
    gsc = read_json(f"sites/{site_key}/docs/SEO_GSC_QUERIES.json")
    ga4 = read_json(f"sites/{site_key}/docs/SEO_GA4_PAGES.json")
    families = read_json(f"sites/{site_key}/docs/SEO_TEMPLATE_FAMILIES.json")

    if is_fresh(gsc):
        for row in (gsc.get("topOpportunities") or [])[:3]:
            score += float(row.get("opportunity", 0) or 0)

    if is_fresh(ga4) and ga4.get("weakHomepageEngagement"):
        home = ga4.get("homepage") or {}
        score += float(home.get("views", 0) or 0) * 20

    if is_fresh(families) and families.get("topFamily"):
        score += float(families["topFamily"].get("score", 0) or 0)

    return score


def fallback_site():
    day_idx = (int(datetime.now(timezone.utc).strftime("%j")) - 1) % len(SITES)
    return SITES[day_idx]


def main():
    parser = argparse.ArgumentParser(description="Select the next SEO site to patch.")
    parser.add_argument(
        "--require-fresh-signal",
        action="store_true",
        help="Only select a site when fresh GA4/GSC/template signals produce a positive score.",
    )
    parser.add_argument(
        "--min-score",
        type=float,
        default=0.0,
        help="Minimum signal score required before selecting a site.",
    )
    parser.add_argument(
        "--empty-ok",
        action="store_true",
        help="Print an empty value instead of failing when no site qualifies.",
    )
    args = parser.parse_args()

    scores = sorted(((score_site(site), site) for site in SITES), reverse=True)
    if scores and scores[0][0] > args.min_score:
        print(scores[0][1])
        return

    if args.require_fresh_signal:
        if args.empty_ok:
            print("")
            return
        print("No site has fresh enough SEO signals.", file=sys.stderr)
        sys.exit(2)

    print(fallback_site())


if __name__ == "__main__":
    main()
