#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def validate_site(site_key: str, site_cfg: dict):
    issues = []
    target_keywords = site_cfg.get("targetKeywords") or []
    rules = site_cfg.get("rulesByQuery") or {}

    if not target_keywords:
        issues.append("missing targetKeywords")

    normalized_rules = {str(k).strip().lower(): v for k, v in rules.items()}

    for kw in target_keywords:
        query = str(kw.get("query", "")).strip().lower()
        if not query:
            issues.append("empty target keyword query")
            continue
        if query not in normalized_rules:
            issues.append(f"missing rule for target keyword: {query}")
            continue

        rule = normalized_rules[query]
        file_path = str(rule.get("file", "")).strip()
        if not file_path:
            issues.append(f"rule without file for query: {query}")
        title = str(rule.get("title", "")).strip()
        desc = str(rule.get("description", "")).strip()
        shell_vars = rule.get("shellVariables")
        if not title and not shell_vars:
            issues.append(f"rule without title/shellVariables for query: {query}")
        if not desc and not shell_vars:
            issues.append(f"rule without description/shellVariables for query: {query}")

        for extra in (rule.get("extraTargets") or []):
            extra_file = str(extra.get("file", "")).strip()
            if not extra_file:
                issues.append(f"extraTarget without file for query: {query}")

    return issues


def main():
    ap = argparse.ArgumentParser(description="Validate SEO autopatch rules coverage and consistency")
    ap.add_argument("rules_path", nargs="?", default=".github/config/seo-autopatch-rules.json")
    args = ap.parse_args()

    rules_path = Path(args.rules_path)
    data = read_json(rules_path)
    if not data:
        raise SystemExit(f"Could not read rules file: {rules_path}")

    all_issues = []

    global_target = data.get("targetKeywords") or []
    global_rules = data.get("rulesByQuery") or {}
    if global_target and global_rules:
        global_cfg = {
            "targetKeywords": global_target,
            "rulesByQuery": global_rules,
        }
        issues = validate_site("global", global_cfg)
        for issue in issues:
            all_issues.append(f"global: {issue}")

    for site_key, site_cfg in (data.get("sites") or {}).items():
        issues = validate_site(site_key, site_cfg or {})
        for issue in issues:
            all_issues.append(f"{site_key}: {issue}")

    if all_issues:
        print("SEO rules coverage validation failed:")
        for issue in all_issues:
            print(f"- {issue}")
        raise SystemExit(1)

    print("OK: seo-autopatch-rules coverage is consistent")


if __name__ == "__main__":
    main()
