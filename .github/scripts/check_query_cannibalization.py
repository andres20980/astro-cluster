#!/usr/bin/env python3
import argparse
import json
from collections import defaultdict
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


def norm_query(value: str):
    return " ".join((value or "").lower().strip().split())


def load_rows(site_key: str):
    fp = Path("sites") / site_key / "docs" / "SEO_GSC_QUERIES.json"
    payload = read_json(fp)
    if not payload:
        return []
    rows = payload.get("queries") or []
    out = []
    for row in rows:
        query = norm_query(str(row.get("query", "")))
        if not query:
            continue
        out.append(
            {
                "site": site_key,
                "domain": payload.get("domain", ""),
                "query": query,
                "clicks": float(row.get("clicks", 0) or 0),
                "impressions": float(row.get("impressions", 0) or 0),
                "ctr": float(row.get("ctr", 0) or 0),
                "position": float(row.get("position", 0) or 0),
            }
        )
    return out


def build_collisions(min_impr: float, max_position: float):
    by_query = defaultdict(list)
    for site in SITES:
        for row in load_rows(site):
            if row["impressions"] < min_impr:
                continue
            if row["position"] > max_position:
                continue
            by_query[row["query"]].append(row)

    collisions = []
    for query, rows in by_query.items():
        domains = {r["domain"] for r in rows if r["domain"]}
        if len(domains) <= 1:
            continue
        rows_sorted = sorted(rows, key=lambda r: (-r["impressions"], r["position"]))
        primary = sorted(
            rows,
            key=lambda r: (
                -((r["ctr"] * r["impressions"]) + (r["impressions"] * 0.05)),
                r["position"],
            ),
        )[0]
        secondary = [r for r in rows_sorted if r["site"] != primary["site"]]

        recommendations = [
            {
                "type": "primary_owner",
                "query": query,
                "ownerSite": primary["site"],
                "ownerDomain": primary["domain"],
                "reason": (
                    f"Mejor score combinado CTR*impr para la query '{query}' "
                    f"({primary['ctr'] * 100:.2f}% CTR, {int(primary['impressions'])} impr)."
                ),
            }
        ]
        for row in secondary[:3]:
            recommendations.append(
                {
                    "type": "deconflict",
                    "query": query,
                    "fromSite": row["site"],
                    "fromDomain": row["domain"],
                    "toSite": primary["site"],
                    "toDomain": primary["domain"],
                    "action": "ajustar title/meta para intención diferenciada o enlazar internamente a owner",
                }
            )

        collisions.append(
            {
                "query": query,
                "domains": sorted(domains),
                "rows": rows_sorted,
                "primaryOwner": primary,
                "recommendations": recommendations,
                "totalImpressions": sum(r["impressions"] for r in rows),
            }
        )

    collisions.sort(key=lambda c: c["totalImpressions"], reverse=True)
    return collisions


def markdown_report(collisions, limit: int):
    lines = []
    lines.append("## ⚔️ Canibalización inter-sitio (queries)")
    lines.append("")
    if not collisions:
        lines.append("Sin colisiones relevantes detectadas.")
        return "\n".join(lines)

    lines.append("| Query | Dominios | Impresiones agregadas |")
    lines.append("|---|---|---:|")
    for col in collisions[:limit]:
        domains = ", ".join(col["domains"])
        lines.append(f"| {col['query']} | {domains} | {int(col['totalImpressions'])} |")

    lines.append("")
    lines.append("### Detalle top colisiones")
    for col in collisions[: min(8, limit)]:
        lines.append("")
        lines.append(f"- Query: {col['query']}")
        owner = col.get("primaryOwner") or {}
        if owner:
            lines.append(
                "  - Owner sugerido: "
                f"{owner.get('domain') or owner.get('site')} "
                f"(CTR {owner.get('ctr', 0) * 100:.2f}%, impr {int(owner.get('impressions', 0))})"
            )
        for row in col["rows"][:5]:
            lines.append(
                "  - "
                f"{row['domain'] or row['site']}: "
                f"{int(row['impressions'])} impr, {int(row['clicks'])} clics, "
                f"CTR {row['ctr'] * 100:.2f}%, pos {row['position']:.1f}"
            )
        for rec in col.get("recommendations", [])[:3]:
            if rec.get("type") == "deconflict":
                lines.append(
                    "  - Acción: "
                    f"{rec['fromSite']} -> {rec['toSite']} ({rec['action']})"
                )

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Detect inter-site query cannibalization from GSC signals")
    parser.add_argument("--min-impressions", type=float, default=40.0)
    parser.add_argument("--max-position", type=float, default=30.0)
    parser.add_argument("--report", default="")
    parser.add_argument("--json", default="")
    parser.add_argument("--limit", type=int, default=25)
    parser.add_argument("--fail-threshold", type=int, default=10)
    args = parser.parse_args()

    collisions = build_collisions(args.min_impressions, args.max_position)
    payload = {
        "checkedSites": len(SITES),
        "collisionCount": len(collisions),
        "collisions": collisions,
        "minImpressions": args.min_impressions,
        "maxPosition": args.max_position,
    }

    if args.json:
        Path(args.json).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    report = markdown_report(collisions, args.limit)
    if args.report:
        Path(args.report).write_text(report + "\n", encoding="utf-8")

    print(json.dumps({"collisionCount": len(collisions), "failThreshold": args.fail_threshold}))

    if len(collisions) >= args.fail_threshold:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
