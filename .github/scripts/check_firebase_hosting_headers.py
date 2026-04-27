#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


REQUIRED_GLOBAL_HEADERS = {
    "X-Content-Type-Options",
    "X-Frame-Options",
    "Referrer-Policy",
    "Strict-Transport-Security",
    "Permissions-Policy",
}


def header_keys(rule):
    return {header.get("key", "") for header in rule.get("headers", [])}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("firebase_json")
    args = parser.parse_args()

    path = Path(args.firebase_json)
    data = json.loads(path.read_text(encoding="utf-8"))
    hosting = data.get("hosting", {})
    headers = hosting.get("headers", [])
    failures = []

    global_rule = next((rule for rule in headers if rule.get("source") == "**"), None)
    if not global_rule:
        failures.append("missing global ** security header rule")
    else:
        missing = REQUIRED_GLOBAL_HEADERS - header_keys(global_rule)
        if missing:
            failures.append(f"global ** rule missing: {', '.join(sorted(missing))}")

    if not any(rule.get("source") == "**/*.html" for rule in headers):
        failures.append("missing HTML Cache-Control rule")
    if not any("@(js|css|ico|png|jpg|svg|webp|woff2)" in rule.get("source", "") for rule in headers):
        failures.append("missing static asset Cache-Control rule")
    if not any("sitemap.xml" in rule.get("source", "") and "robots.txt" in rule.get("source", "") for rule in headers):
        failures.append("missing robots/sitemap Cache-Control rule")

    if failures:
        print(f"Firebase hosting header check failed for {path}:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"OK: Firebase hosting headers pass for {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
