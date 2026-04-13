#!/usr/bin/env python3
import json
import os
from collections import defaultdict


SITES = [
    "carta-astral",
    "compatibilidad-signos",
    "tarot-del-dia",
    "calcular-numerologia",
    "horoscopo-de-hoy",
]


def read_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return {}


def ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def classify_family(site_key, path):
    path = (path or "/").split("?", 1)[0] or "/"
    if path == "/":
        return "home"
    if site_key == "carta-astral":
        if path.startswith("/signos/") and path != "/signos/":
            return "sign_profiles"
        if path.startswith("/signos/"):
            return "sign_hub"
        return "content"
    if site_key == "compatibilidad-signos":
        return "pair_pages"
    if site_key == "tarot-del-dia":
        if path.startswith("/arcanos-mayores/") and path != "/arcanos-mayores/":
            return "major_arcana"
        if path.startswith("/arcanos-mayores/"):
            return "major_arcana_hub"
        if path.startswith("/arcanos-menores/"):
            return "minor_arcana"
        return "content"
    if site_key == "calcular-numerologia":
        if path.startswith("/numero-de-vida/") and path != "/numero-de-vida/":
            return "number_pages"
        if path.startswith("/numero-de-vida/"):
            return "number_hub"
        return "content"
    if site_key == "horoscopo-de-hoy":
        return "sign_pages"
    return "content"


def build_site_payload(site_key):
    gsc = read_json(f"sites/{site_key}/docs/SEO_GSC_QUERIES.json")
    ga4 = read_json(f"sites/{site_key}/docs/SEO_GA4_PAGES.json")
    generated_at = ga4.get("generatedAt") or gsc.get("generatedAt") or ""
    domain = ga4.get("domain") or gsc.get("domain") or ""

    families = defaultdict(
        lambda: {
            "family": "",
            "ga4Views": 0.0,
            "ga4LowEngagementViews": 0.0,
            "gscImpressions": 0.0,
            "gscOpportunity": 0.0,
            "paths": set(),
        }
    )

    for page in ga4.get("pages", []):
        family = classify_family(site_key, page.get("path", "/"))
        row = families[family]
        row["family"] = family
        row["ga4Views"] += float(page.get("views", 0) or 0)
        if float(page.get("bounceRate", 0) or 0) >= 0.65 or float(page.get("averageSessionDuration", 0) or 0) < 45:
            row["ga4LowEngagementViews"] += float(page.get("views", 0) or 0)
        row["paths"].add(page.get("path", "/"))

    for page in gsc.get("pages", []):
        family = classify_family(site_key, page.get("path", "/"))
        row = families[family]
        row["family"] = family
        row["gscImpressions"] += float(page.get("impressions", 0) or 0)
        row["gscOpportunity"] += float(page.get("opportunity", 0) or 0)
        row["paths"].add(page.get("path", "/"))

    ranked = []
    for family, row in families.items():
        score = row["gscOpportunity"] + (row["ga4LowEngagementViews"] * 25) + (row["ga4Views"] * 2)
        ranked.append(
            {
                "family": family,
                "score": score,
                "ga4Views": row["ga4Views"],
                "ga4LowEngagementViews": row["ga4LowEngagementViews"],
                "gscImpressions": row["gscImpressions"],
                "gscOpportunity": row["gscOpportunity"],
                "paths": sorted(row["paths"])[:5],
            }
        )

    ranked.sort(key=lambda item: item["score"], reverse=True)
    return {
        "generatedAt": generated_at,
        "site": site_key,
        "domain": domain,
        "families": ranked,
        "topFamily": ranked[0] if ranked else None,
    }


def main():
    for site_key in SITES:
        payload = build_site_payload(site_key)
        target_dir = os.path.join("sites", site_key, "docs")
        ensure_dir(target_dir)
        with open(os.path.join(target_dir, "SEO_TEMPLATE_FAMILIES.json"), "w") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()
