#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def status_icon(ok: bool):
    return "✅" if ok else "❌"


def main():
    ap = argparse.ArgumentParser(description="Create SEO automation SLO dashboard from generated reports")
    ap.add_argument("--precision", default="/tmp/seo-engine-precision.json")
    ap.add_argument("--scorecard", default="/tmp/seo-scorecard.json")
    ap.add_argument("--cannibal", default="/tmp/seo-cannibalization.json")
    ap.add_argument("--json", default="")
    ap.add_argument("--report", default="")
    args = ap.parse_args()

    precision = read_json(Path(args.precision)) or {}
    scorecard = read_json(Path(args.scorecard)) or {}
    cannibal = read_json(Path(args.cannibal)) or {}

    cluster_light = precision.get("clusterTrafficLight", "gray")
    top_site = (scorecard.get("sites") or [{}])[0].get("site", "n/a")
    collision_count = int(cannibal.get("collisionCount", 0) or 0)

    slo = {
        "clusterPrecisionNotRed": cluster_light != "red",
        "topSiteAvailable": top_site != "n/a",
        "cannibalizationUnderThreshold": collision_count < 20,
    }

    ok_count = sum(1 for v in slo.values() if v)
    total = len(slo)
    global_ok = ok_count == total

    payload = {
        "generatedAt": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "globalStatus": "green" if global_ok else "yellow",
        "checks": slo,
        "summary": {
            "clusterTrafficLight": cluster_light,
            "topSite": top_site,
            "collisionCount": collision_count,
            "passed": ok_count,
            "total": total,
        },
    }

    lines = ["## 🧭 SLO dashboard de automatización SEO", ""]
    lines.append(f"Estado global: **{payload['globalStatus']}**")
    lines.append("")
    lines.append("| Control | Estado |")
    lines.append("|---|---|")
    lines.append(f"| Precisión cluster no roja | {status_icon(slo['clusterPrecisionNotRed'])} |")
    lines.append(f"| Top site disponible en scorecard | {status_icon(slo['topSiteAvailable'])} |")
    lines.append(f"| Canibalización bajo umbral | {status_icon(slo['cannibalizationUnderThreshold'])} |")
    lines.append("")
    lines.append(
        f"Resumen: semáforo={cluster_light}, topSite={top_site}, colisiones={collision_count}, checks={ok_count}/{total}."
    )

    report = "\n".join(lines)

    if args.json:
        Path(args.json).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if args.report:
        Path(args.report).write_text(report + "\n", encoding="utf-8")

    print(json.dumps({"status": payload["globalStatus"], "checks": total}))


if __name__ == "__main__":
    main()
