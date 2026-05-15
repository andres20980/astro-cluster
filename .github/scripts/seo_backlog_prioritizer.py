#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def safe(path_str, default):
    payload = read_json(Path(path_str))
    return payload if payload else default


def build_items(scorecard, cannibal, precision, interlink):
    items = []

    for row in (scorecard.get("sites") or [])[:3]:
        items.append(
            {
                "title": f"Impulsar site prioritario: {row.get('site')}",
                "reason": f"Score SEO alto ({row.get('rawScore', 0):.1f}) con señal de oportunidad activa.",
                "impact": "high",
                "effort": "medium",
                "source": "scorecard",
            }
        )

    collisions = cannibal.get("collisions") or []
    for col in collisions[:5]:
        owner = (col.get("primaryOwner") or {}).get("site", "n/a")
        items.append(
            {
                "title": f"Resolver canibalización: {col.get('query')}",
                "reason": f"Query con {int(col.get('totalImpressions', 0))} impr y owner sugerido {owner}.",
                "impact": "high",
                "effort": "medium",
                "source": "cannibalization",
            }
        )

    cluster_light = precision.get("clusterTrafficLight", "gray")
    if cluster_light in {"red", "yellow"}:
        items.append(
            {
                "title": "Recalibrar umbrales del motor SEO",
                "reason": f"Semáforo cluster en {cluster_light}. Ajustar holdout y guard thresholds.",
                "impact": "high",
                "effort": "low",
                "source": "precision",
            }
        )

    for rec in (interlink.get("crossSite") or [])[:3]:
        items.append(
            {
                "title": f"Recirculación cross-site: {rec.get('fromSite')} -> {rec.get('toSite')}",
                "reason": rec.get("suggestion", ""),
                "impact": "medium",
                "effort": "low",
                "source": "interlink",
            }
        )

    return items


def markdown(items):
    lines = ["## 🗂️ Backlog SEO priorizado (automático)", ""]
    if not items:
        lines.append("Sin ítems priorizados.")
        return "\n".join(lines)

    lines.append("| Prioridad | Acción | Impacto | Esfuerzo | Fuente |")
    lines.append("|---:|---|---|---|---|")
    for idx, item in enumerate(items, start=1):
        lines.append(
            f"| {idx} | {item['title']} | {item['impact']} | {item['effort']} | {item['source']} |"
        )
        lines.append(f"|  | ↳ {item['reason']} |  |  |  |")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="Create prioritized SEO backlog from generated signals")
    ap.add_argument("--scorecard", default="/tmp/seo-scorecard.json")
    ap.add_argument("--cannibal", default="/tmp/seo-cannibalization.json")
    ap.add_argument("--precision", default="/tmp/seo-engine-precision.json")
    ap.add_argument("--interlink", default="/tmp/seo-interlink.json")
    ap.add_argument("--json", default="")
    ap.add_argument("--report", default="")
    args = ap.parse_args()

    scorecard = safe(args.scorecard, {})
    cannibal = safe(args.cannibal, {})
    precision = safe(args.precision, {})
    interlink = safe(args.interlink, {})

    items = build_items(scorecard, cannibal, precision, interlink)
    payload = {
        "generatedAt": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "items": items,
    }

    if args.json:
        Path(args.json).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    rep = markdown(items)
    if args.report:
        Path(args.report).write_text(rep + "\n", encoding="utf-8")

    print(json.dumps({"items": len(items)}))


if __name__ == "__main__":
    main()
