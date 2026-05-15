#!/usr/bin/env python3
import argparse
from html.parser import HTMLParser
from pathlib import Path


class LinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.internal = 0

    def handle_starttag(self, tag, attrs):
        if tag != "a":
            return
        attrs = dict(attrs)
        href = (attrs.get("href") or "").strip()
        if not href:
            return
        if href.startswith("/") and not href.startswith("//"):
            self.internal += 1


def html_files(public_dir: Path):
    return sorted([p for p in public_dir.rglob("*.html") if p.is_file()])


def main():
    ap = argparse.ArgumentParser(description="Check minimum internal-link coverage in generated pages")
    ap.add_argument("public_dir")
    ap.add_argument("--min-internal-links", type=int, default=2)
    ap.add_argument("--sample-limit", type=int, default=120)
    ap.add_argument("--skip", action="append", default=[])
    args = ap.parse_args()

    public_dir = Path(args.public_dir)
    if not public_dir.is_dir():
        raise SystemExit(f"Missing public dir: {public_dir}")

    skip = set(args.skip)
    failures = []

    files = html_files(public_dir)[: max(1, args.sample_limit)]
    for fp in files:
        rel = str(fp.relative_to(public_dir))
        if rel in skip:
            continue
        parser = LinkParser()
        parser.feed(fp.read_text(encoding="utf-8", errors="ignore"))
        if parser.internal < args.min_internal_links:
            failures.append(f"{rel}: only {parser.internal} internal links")

    if failures:
        print("Internal-link coverage check failed:")
        for item in failures[:120]:
            print(f"- {item}")
        raise SystemExit(1)

    print(f"OK: internal-link coverage validated on {len(files)} files in {public_dir}")


if __name__ == "__main__":
    main()
