#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def clamp(v, lo, hi):
    return max(lo, min(hi, v))


def main():
    ap = argparse.ArgumentParser(description="Recommend SEO threshold adjustments from SLO/precision signals")
    ap.add_argument("--config", required=True)
    ap.add_argument("--precision", required=True)
    ap.add_argument("--slo", required=True)
    ap.add_argument("--json", default="")
    ap.add_argument("--report", default="")
    args = ap.parse_args()

    cfg = read_json(Path(args.config)) or {}
    precision = read_json(Path(args.precision)) or {}
    slo = read_json(Path(args.slo)) or {}

    holdout = float(cfg.get("holdoutRatio", 0.12) or 0.12)
    ctr_drop = float(cfg.get("ctrDropThreshold", 0.20) or 0.20)
    opp_min = float(cfg.get("oppGrowthMin", 0.85) or 0.85)

    cluster_light = precision.get("clusterTrafficLight", "gray")
    global_status = slo.get("globalStatus", "yellow")

    recommendation_reason = []

    if cluster_light == "red" or global_status == "yellow":
        holdout = clamp(holdout + 0.05, 0.05, 0.40)
        ctr_drop = clamp(ctr_drop - 0.03, 0.10, 0.40)
        opp_min = clamp(opp_min + 0.03, 0.70, 1.20)
        recommendation_reason.append("Modo conservador: sube holdout y endurece guard por señales de riesgo.")
    elif cluster_light == "green" and global_status == "green":
        holdout = clamp(holdout - 0.02, 0.05, 0.40)
        ctr_drop = clamp(ctr_drop + 0.02, 0.10, 0.40)
        opp_min = clamp(opp_min - 0.02, 0.70, 1.20)
        recommendation_reason.append("Modo expansión controlada: baja holdout y relaja guard levemente.")
    else:
        recommendation_reason.append("Sin cambios agresivos: mantener umbrales actuales.")

    out = {
        "current": {
            "holdoutRatio": float(cfg.get("holdoutRatio", 0.12) or 0.12),
            "ctrDropThreshold": float(cfg.get("ctrDropThreshold", 0.20) or 0.20),
            "oppGrowthMin": float(cfg.get("oppGrowthMin", 0.85) or 0.85),
        },
        "recommended": {
            "holdoutRatio": round(holdout, 3),
            "ctrDropThreshold": round(ctr_drop, 3),
            "oppGrowthMin": round(opp_min, 3),
        },
        "signals": {
            "clusterTrafficLight": cluster_light,
            "sloGlobalStatus": global_status,
        },
        "reasons": recommendation_reason,
    }

    report = "\n".join(
        [
            "## 🎛️ Recomendación de umbrales SEO",
            "",
            f"- Semáforo cluster: **{cluster_light}**",
            f"- Estado SLO global: **{global_status}**",
            "",
            "### Actual",
            f"- holdoutRatio: {out['current']['holdoutRatio']}",
            f"- ctrDropThreshold: {out['current']['ctrDropThreshold']}",
            f"- oppGrowthMin: {out['current']['oppGrowthMin']}",
            "",
            "### Recomendado",
            f"- holdoutRatio: {out['recommended']['holdoutRatio']}",
            f"- ctrDropThreshold: {out['recommended']['ctrDropThreshold']}",
            f"- oppGrowthMin: {out['recommended']['oppGrowthMin']}",
            "",
            "### Motivo",
            *[f"- {r}" for r in out["reasons"]],
        ]
    )

    if args.json:
        Path(args.json).write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if args.report:
        Path(args.report).write_text(report + "\n", encoding="utf-8")

    print(json.dumps({"status": "ok"}))


if __name__ == "__main__":
    main()
