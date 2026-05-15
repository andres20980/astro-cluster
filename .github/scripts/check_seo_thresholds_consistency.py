#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def fail(msg: str):
    raise SystemExit(msg)


def main():
    ap = argparse.ArgumentParser(description="Validate SEO thresholds configuration consistency")
    ap.add_argument("config_path", help="Path to seo-thresholds.json")
    args = ap.parse_args()

    cfg_path = Path(args.config_path)
    if not cfg_path.is_file():
        fail(f"Missing config file: {cfg_path}")

    cfg = json.loads(cfg_path.read_text(encoding="utf-8"))

    holdout = float(cfg.get("holdoutRatio", 0.12))
    cooldown = float(cfg.get("minHoursBetweenPatches", 18))
    ctr_drop = float(cfg.get("ctrDropThreshold", 0.20))
    opp_min = float(cfg.get("oppGrowthMin", 0.85))

    snippet = cfg.get("snippet") or {}
    title_min = int(snippet.get("titleMin", 35))
    title_max = int(snippet.get("titleMax", 70))
    desc_min = int(snippet.get("descriptionMin", 70))
    desc_max = int(snippet.get("descriptionMax", 165))
    stuffing = int(snippet.get("stuffingThreshold", 4))

    links = cfg.get("internalLinks") or {}
    min_links = int(links.get("minPerPage", 2))

    cannibal = cfg.get("cannibalization") or {}
    min_impr = float(cannibal.get("minImpressions", 40))
    max_pos = float(cannibal.get("maxPosition", 30))
    alert_thr = int(cannibal.get("alertThreshold", 20))

    errors = []

    if not (0.0 <= holdout <= 0.6):
        errors.append(f"holdoutRatio out of range [0, 0.6]: {holdout}")
    if not (1 <= cooldown <= 168):
        errors.append(f"minHoursBetweenPatches out of range [1, 168]: {cooldown}")
    if not (0.05 <= ctr_drop <= 0.5):
        errors.append(f"ctrDropThreshold out of range [0.05, 0.5]: {ctr_drop}")
    if not (0.6 <= opp_min <= 1.4):
        errors.append(f"oppGrowthMin out of range [0.6, 1.4]: {opp_min}")

    if not (20 <= title_min <= 80):
        errors.append(f"snippet.titleMin out of range [20, 80]: {title_min}")
    if not (30 <= title_max <= 90):
        errors.append(f"snippet.titleMax out of range [30, 90]: {title_max}")
    if title_min >= title_max:
        errors.append(f"snippet.titleMin must be lower than titleMax: {title_min} >= {title_max}")

    if not (40 <= desc_min <= 200):
        errors.append(f"snippet.descriptionMin out of range [40, 200]: {desc_min}")
    if not (60 <= desc_max <= 220):
        errors.append(f"snippet.descriptionMax out of range [60, 220]: {desc_max}")
    if desc_min >= desc_max:
        errors.append(
            f"snippet.descriptionMin must be lower than descriptionMax: {desc_min} >= {desc_max}"
        )

    if not (2 <= stuffing <= 8):
        errors.append(f"snippet.stuffingThreshold out of range [2, 8]: {stuffing}")
    if not (1 <= min_links <= 8):
        errors.append(f"internalLinks.minPerPage out of range [1, 8]: {min_links}")

    if not (5 <= min_impr <= 2000):
        errors.append(f"cannibalization.minImpressions out of range [5, 2000]: {min_impr}")
    if not (3 <= max_pos <= 100):
        errors.append(f"cannibalization.maxPosition out of range [3, 100]: {max_pos}")
    if not (1 <= alert_thr <= 200):
        errors.append(f"cannibalization.alertThreshold out of range [1, 200]: {alert_thr}")

    if errors:
        print("SEO threshold consistency check failed:")
        for err in errors:
            print(f"- {err}")
        raise SystemExit(1)

    print("OK: seo-thresholds configuration is consistent")


if __name__ == "__main__":
    main()
