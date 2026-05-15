#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main():
    ap = argparse.ArgumentParser(description="Apply recommended SEO thresholds into config file")
    ap.add_argument("--config", required=True)
    ap.add_argument("--recommendation", required=True)
    args = ap.parse_args()

    cfg_path = Path(args.config)
    rec_path = Path(args.recommendation)

    cfg = read_json(cfg_path)
    rec = read_json(rec_path)
    recommended = rec.get("recommended") or {}

    if not recommended:
        print("No recommended thresholds found; skipping")
        return

    changed = False

    for key in ("holdoutRatio", "ctrDropThreshold", "oppGrowthMin"):
        if key in recommended:
            old = cfg.get(key)
            new = recommended[key]
            if old != new:
                cfg[key] = new
                changed = True

    if not changed:
        print("No threshold changes required")
        return

    cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Updated thresholds:")
    for key in ("holdoutRatio", "ctrDropThreshold", "oppGrowthMin"):
        print(f"- {key}: {cfg.get(key)}")


if __name__ == "__main__":
    main()
