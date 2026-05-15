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


def weighted_ctr(rows):
    impr = 0.0
    clicks = 0.0
    for row in rows or []:
        i = float(row.get("impressions", 0) or 0)
        c = float(row.get("clicks", 0) or 0)
        impr += i
        clicks += c
    if impr <= 0:
        return 0.0
    return clicks / impr


def top_opp(rows):
    return sum(float(r.get("opportunity", 0) or 0) for r in (rows or [])[:5])


def classify(delta_ctr, delta_opp):
    if delta_ctr >= 0.08 and delta_opp >= -0.05:
        return "green"
    if delta_ctr <= -0.12 or delta_opp <= -0.20:
        return "red"
    return "yellow"


def site_precision(site_key: str):
    docs = Path("sites") / site_key / "docs"
    state = read_json(docs / "SEO_AGENT_STATE.json") or {}
    current = read_json(docs / "SEO_GSC_QUERIES.json") or {}
    baseline = read_json(docs / "SEO_GSC_QUERIES.pre_patch.json")

    changed = sum(1 for r in (state.get("results") or []) if r.get("changed"))
    last_run = state.get("lastRun")

    if not baseline:
        return {
            "site": site_key,
            "status": "insufficient_data",
            "lastRun": last_run,
            "changed": changed,
        }

    c_ctr = weighted_ctr(current.get("topOpportunities") or [])
    b_ctr = weighted_ctr(baseline.get("topOpportunities") or [])
    c_opp = top_opp(current.get("topPageOpportunities") or [])
    b_opp = top_opp(baseline.get("topPageOpportunities") or [])

    delta_ctr = ((c_ctr / b_ctr) - 1) if b_ctr > 0 else 0.0
    delta_opp = ((c_opp / b_opp) - 1) if b_opp > 0 else 0.0
    color = classify(delta_ctr, delta_opp)

    return {
        "site": site_key,
        "status": "ok",
        "lastRun": last_run,
        "changed": changed,
        "baselineCtr": b_ctr,
        "currentCtr": c_ctr,
        "deltaCtr": delta_ctr,
        "baselineOpp": b_opp,
        "currentOpp": c_opp,
        "deltaOpp": delta_opp,
        "trafficLight": color,
    }


def cluster_light(rows):
    lights = [r.get("trafficLight") for r in rows if r.get("status") == "ok"]
    if not lights:
        return "gray"
    if lights.count("red") >= 2:
        return "red"
    if lights.count("green") >= max(2, len(lights) // 2):
        return "green"
    return "yellow"


def markdown(rows, cluster):
    lines = ["## 🎯 Precisión del motor SEO", ""]
    lines.append(f"Semáforo cluster: **{cluster}**")
    lines.append("")
    lines.append("| Site | Estado | Cambios | ΔCTR | ΔOpportunity | Semáforo |")
    lines.append("|---|---|---:|---:|---:|---|")
    for r in rows:
        if r.get("status") != "ok":
            lines.append(f"| {r['site']} | insuficiente | {r.get('changed', 0)} | - | - | gray |")
            continue
        lines.append(
            f"| {r['site']} | ok | {r.get('changed', 0)} | "
            f"{r.get('deltaCtr', 0) * 100:.2f}% | {r.get('deltaOpp', 0) * 100:.2f}% | {r.get('trafficLight')} |"
        )
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="Weekly precision report for SEO engine")
    ap.add_argument("--json", default="")
    ap.add_argument("--report", default="")
    args = ap.parse_args()

    rows = [site_precision(site) for site in SITES]
    c_light = cluster_light(rows)
    payload = {
        "generatedAt": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "clusterTrafficLight": c_light,
        "sites": rows,
    }

    if args.json:
        Path(args.json).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    rep = markdown(rows, c_light)
    if args.report:
        Path(args.report).write_text(rep + "\n", encoding="utf-8")

    print(json.dumps({"clusterTrafficLight": c_light, "sites": len(rows)}))


if __name__ == "__main__":
    main()
