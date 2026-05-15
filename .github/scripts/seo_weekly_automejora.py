#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def pct(value):
    try:
        return f"{float(value) * 100:.2f}%"
    except Exception:
        return "0.00%"


def main():
    ap = argparse.ArgumentParser(description="Build weekly SEO self-improvement plan from generated reports")
    ap.add_argument("--precision", required=True)
    ap.add_argument("--slo", required=True)
    ap.add_argument("--threshold-rec", required=True)
    ap.add_argument("--cannibal", required=True)
    ap.add_argument("--scorecard", required=True)
    ap.add_argument("--json", required=True)
    ap.add_argument("--report", required=True)
    args = ap.parse_args()

    precision = read_json(Path(args.precision))
    slo = read_json(Path(args.slo))
    rec = read_json(Path(args.threshold_rec))
    cannibal = read_json(Path(args.cannibal))
    scorecard = read_json(Path(args.scorecard))

    cluster = precision.get("clusterTrafficLight", "gray")
    global_status = slo.get("globalStatus", "yellow")
    collisions = int(cannibal.get("collisionCount", 0) or 0)
    top_sites = (scorecard.get("sites") or [])[:3]

    actions = []
    if cluster == "red":
        actions.append("Reducir ritmo de autoparches (holdout más conservador) hasta recuperar precisión.")
    elif cluster == "yellow":
        actions.append("Mantener ritmo actual y priorizar correcciones de snippets/cobertura interna.")
    else:
        actions.append("Escalar gradualmente el volumen de cambios si se mantiene estabilidad 2 semanas.")

    if collisions >= 20:
        actions.append("Priorizar resolución de canibalización entre sitios con mayor solapamiento.")
    elif collisions > 0:
        actions.append("Aplicar deconflict en queries con impacto medio y monitorizar una semana.")

    recommended = rec.get("recommended", {})
    if recommended:
        actions.append(
            "Aplicar tuning semanal recomendado de umbrales (holdout/guard) vía PR automático."
        )

    if global_status != "green":
        actions.append("No ampliar agresividad hasta que el SLO global vuelva a verde.")

    if not actions:
        actions.append("Sin cambios urgentes: mantener configuración actual y observar tendencia.")

    summary = {
        "clusterTrafficLight": cluster,
        "sloGlobalStatus": global_status,
        "collisionCount": collisions,
        "thresholdRecommendation": recommended,
        "topSites": top_sites,
        "actions": actions,
    }

    report_lines = [
        "## 🧠 Automejora SEO semanal",
        "",
        f"- Semáforo cluster: **{cluster}**",
        f"- Estado SLO global: **{global_status}**",
        f"- Colisiones de canibalización: **{collisions}**",
        "",
        "### Top sitios por score",
    ]

    if top_sites:
        for item in top_sites:
            site = item.get("site", "n/a")
            score = item.get("score", item.get("rawScore", 0))
            delta = pct(item.get("deltaScore", 0))
            report_lines.append(f"- {site}: score={score}, delta={delta}")
    else:
        report_lines.append("- Sin datos")

    report_lines.extend(
        [
            "",
            "### Tuning recomendado",
            f"- holdoutRatio: {recommended.get('holdoutRatio', 'n/a')}",
            f"- ctrDropThreshold: {recommended.get('ctrDropThreshold', 'n/a')}",
            f"- oppGrowthMin: {recommended.get('oppGrowthMin', 'n/a')}",
            "",
            "### Plan de automejora",
        ]
    )

    for action in actions:
        report_lines.append(f"- {action}")

    report_lines.append("")
    report_lines.append("Generado automáticamente por pipeline de automejora.")

    Path(args.json).write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    Path(args.report).write_text("\n".join(report_lines) + "\n", encoding="utf-8")
    print(json.dumps({"status": "ok", "actions": len(actions)}))


if __name__ == "__main__":
    main()
