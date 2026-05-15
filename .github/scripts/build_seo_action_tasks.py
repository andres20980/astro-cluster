#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def main():
    ap = argparse.ArgumentParser(description="Build actionable SEO tasks markdown from generated reports")
    ap.add_argument("--backlog", required=True)
    ap.add_argument("--cannibal", required=True)
    ap.add_argument("--interlink", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    backlog = read_json(Path(args.backlog))
    cannibal = read_json(Path(args.cannibal))
    interlink = read_json(Path(args.interlink))

    lines = ["# SEO Action Tasks", "", "Generado automáticamente.", ""]

    lines.append("## Top backlog")
    items = backlog.get("items") or []
    if items:
        for i, item in enumerate(items[:15], start=1):
            lines.append(f"{i}. {item.get('title','(sin titulo)')}")
            reason = item.get("reason", "")
            if reason:
                lines.append(f"   - Motivo: {reason}")
            lines.append(f"   - Impacto: {item.get('impact','-')} | Esfuerzo: {item.get('effort','-')} | Fuente: {item.get('source','-')}")
    else:
        lines.append("- Sin items")

    lines.append("")
    lines.append("## Canibalización (acciones sugeridas)")
    collisions = cannibal.get("collisions") or []
    if collisions:
        for col in collisions[:10]:
            lines.append(f"- Query: {col.get('query','-')}")
            for rec in (col.get("recommendations") or [])[:3]:
                if rec.get("type") == "deconflict":
                    lines.append(
                        f"  - {rec.get('fromSite','-')} -> {rec.get('toSite','-')}: {rec.get('action','-')}"
                    )
    else:
        lines.append("- Sin colisiones")

    lines.append("")
    lines.append("## Interlinking sugerido")
    intra = interlink.get("intraSite") or []
    cross = interlink.get("crossSite") or []
    if intra:
        lines.append("### Intra-site")
        for rec in intra[:20]:
            lines.append(
                f"- [{rec.get('site','-')}] {rec.get('sourcePath','/')} -> {rec.get('targetPath','/')} | anchor: {rec.get('anchorSuggestion','-')}"
            )
    if cross:
        lines.append("### Cross-site")
        for rec in cross[:10]:
            lines.append(f"- {rec.get('fromSite','-')} -> {rec.get('toSite','-')}: {rec.get('suggestion','-')}")
    if not intra and not cross:
        lines.append("- Sin recomendaciones")

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps({"status": "ok", "output": str(out)}))


if __name__ == "__main__":
    main()
