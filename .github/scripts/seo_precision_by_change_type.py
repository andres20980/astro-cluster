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


def classify_change(file_path: str):
    p = (file_path or "").lower()
    if p.endswith(".html"):
        return "snippet_html"
    if p.endswith(".sh"):
        return "generator_template"
    return "other"


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


def site_delta(site_key: str):
    docs = Path("sites") / site_key / "docs"
    state = read_json(docs / "SEO_AGENT_STATE.json") or {}
    baseline = read_json(docs / "SEO_GSC_QUERIES.pre_patch.json")
    current = read_json(docs / "SEO_GSC_QUERIES.json")

    by_type = {}
    for row in state.get("results") or []:
        if not row.get("changed"):
            continue
        t = classify_change(str(row.get("file", "")))
        by_type[t] = by_type.get(t, 0) + 1

    if not baseline or not current:
        return {
            "site": site_key,
            "status": "insufficient_data",
            "changesByType": by_type,
            "deltaCtr": None,
        }

    b_ctr = weighted_ctr((baseline.get("topOpportunities") or []))
    c_ctr = weighted_ctr((current.get("topOpportunities") or []))
    delta = ((c_ctr / b_ctr) - 1) if b_ctr > 0 else 0.0
    return {
        "site": site_key,
        "status": "ok",
        "changesByType": by_type,
        "deltaCtr": delta,
    }


def aggregate(rows):
    totals = {
        "snippet_html": {"sites": 0, "changes": 0, "ctrDeltaSum": 0.0, "ctrDeltaCount": 0},
        "generator_template": {"sites": 0, "changes": 0, "ctrDeltaSum": 0.0, "ctrDeltaCount": 0},
        "other": {"sites": 0, "changes": 0, "ctrDeltaSum": 0.0, "ctrDeltaCount": 0},
    }

    for row in rows:
        for key, count in (row.get("changesByType") or {}).items():
            if key not in totals:
                totals[key] = {"sites": 0, "changes": 0, "ctrDeltaSum": 0.0, "ctrDeltaCount": 0}
            totals[key]["sites"] += 1
            totals[key]["changes"] += int(count)
            if row.get("status") == "ok" and row.get("deltaCtr") is not None:
                totals[key]["ctrDeltaSum"] += float(row.get("deltaCtr") or 0)
                totals[key]["ctrDeltaCount"] += 1

    for key, item in totals.items():
        item["avgCtrDelta"] = (
            item["ctrDeltaSum"] / item["ctrDeltaCount"] if item["ctrDeltaCount"] > 0 else None
        )

    return totals


def markdown(totals):
    lines = ["## 🧪 Precisión por tipo de cambio SEO", ""]
    lines.append("| Tipo de cambio | Sites con cambios | Nº cambios | ΔCTR medio |")
    lines.append("|---|---:|---:|---:|")
    for key, item in totals.items():
        avg = "-" if item["avgCtrDelta"] is None else f"{item['avgCtrDelta'] * 100:.2f}%"
        lines.append(f"| {key} | {item['sites']} | {item['changes']} | {avg} |")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="Measure SEO engine precision by change type")
    ap.add_argument("--json", default="")
    ap.add_argument("--report", default="")
    args = ap.parse_args()

    rows = [site_delta(s) for s in SITES]
    totals = aggregate(rows)

    payload = {
        "generatedAt": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "sites": rows,
        "totals": totals,
    }

    if args.json:
        Path(args.json).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    rep = markdown(totals)
    if args.report:
        Path(args.report).write_text(rep + "\n", encoding="utf-8")

    print(json.dumps({"status": "ok", "types": len(totals)}))


if __name__ == "__main__":
    main()
