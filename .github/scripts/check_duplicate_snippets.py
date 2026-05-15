#!/usr/bin/env python3
import argparse
from collections import defaultdict
from html.parser import HTMLParser
from pathlib import Path


class SnippetParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_title = False
        self.title_parts = []
        self.description = ""

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "title":
            self.in_title = True
        elif tag == "meta" and attrs.get("name", "").lower() == "description":
            self.description = (attrs.get("content", "") or "").strip()

    def handle_endtag(self, tag):
        if tag == "title":
            self.in_title = False

    def handle_data(self, data):
        if self.in_title and data.strip():
            self.title_parts.append(data.strip())

    @property
    def title(self):
        return " ".join(self.title_parts).strip()


def html_files(public_dir: Path):
    return sorted([p for p in public_dir.rglob("*.html") if p.is_file()])


def parse_snippets(fp: Path):
    parser = SnippetParser()
    parser.feed(fp.read_text(encoding="utf-8", errors="ignore"))
    return parser.title, parser.description


def normalize(value: str):
    return " ".join((value or "").lower().split())


def main():
    ap = argparse.ArgumentParser(description="Fail if duplicate title/meta snippets are found")
    ap.add_argument("public_dir")
    ap.add_argument("--allow-title", action="append", default=[])
    ap.add_argument("--allow-description", action="append", default=[])
    args = ap.parse_args()

    public_dir = Path(args.public_dir)
    if not public_dir.is_dir():
        raise SystemExit(f"Missing public dir: {public_dir}")

    allow_titles = {normalize(v) for v in args.allow_title}
    allow_desc = {normalize(v) for v in args.allow_description}

    by_title = defaultdict(list)
    by_desc = defaultdict(list)

    for fp in html_files(public_dir):
        rel = str(fp.relative_to(public_dir))
        title, desc = parse_snippets(fp)
        nt = normalize(title)
        nd = normalize(desc)
        if nt:
            by_title[nt].append(rel)
        if nd:
            by_desc[nd].append(rel)

    failures = []

    for title, paths in by_title.items():
        if len(paths) > 1 and title not in allow_titles:
            failures.append(f"Duplicate <title> ({len(paths)}): {title} -> {', '.join(paths[:8])}")

    for desc, paths in by_desc.items():
        if len(paths) > 2 and desc not in allow_desc:
            failures.append(
                f"Duplicate meta description ({len(paths)}): {desc} -> {', '.join(paths[:8])}"
            )

    if failures:
        print("Duplicate snippet check failed:")
        for item in failures:
            print(f"- {item}")
        raise SystemExit(1)

    print(
        f"OK: no problematic duplicate snippets in {public_dir} "
        f"({len(by_title)} unique titles, {len(by_desc)} unique descriptions)"
    )


if __name__ == "__main__":
    main()
