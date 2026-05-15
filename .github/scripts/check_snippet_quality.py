#!/usr/bin/env python3
import argparse
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
            self.description = attrs.get("content", "")

    def handle_endtag(self, tag):
        if tag == "title":
            self.in_title = False

    def handle_data(self, data):
        if self.in_title and data.strip():
            self.title_parts.append(data.strip())

    @property
    def title(self):
        return " ".join(self.title_parts).strip()


def normalize_tokens(value: str):
    import re

    return [t for t in re.split(r"[^a-z0-9áéíóúñü]+", value.lower()) if len(t) > 2]


def stuffing_risk(text: str, threshold: int):
    tokens = normalize_tokens(text)
    if not tokens:
        return False
    counts = {}
    for t in tokens:
        counts[t] = counts.get(t, 0) + 1
    return max(counts.values()) >= threshold


def parse_html(path: Path):
    parser = SnippetParser()
    parser.feed(path.read_text(encoding="utf-8", errors="ignore"))
    return parser.title, parser.description.strip()


def html_files(public_dir: Path):
    return sorted([p for p in public_dir.rglob("*.html") if p.is_file()])


def main():
    ap = argparse.ArgumentParser(description="Validate snippet quality budgets across generated HTML")
    ap.add_argument("public_dir")
    ap.add_argument("--title-min", type=int, default=35)
    ap.add_argument("--title-max", type=int, default=70)
    ap.add_argument("--description-min", type=int, default=70)
    ap.add_argument("--description-max", type=int, default=165)
    ap.add_argument("--stuffing-threshold", type=int, default=4)
    ap.add_argument("--sample-limit", type=int, default=120)
    args = ap.parse_args()

    public_dir = Path(args.public_dir)
    if not public_dir.is_dir():
        raise SystemExit(f"Missing public dir: {public_dir}")

    failures = []
    files = html_files(public_dir)[: max(1, args.sample_limit)]

    for fp in files:
        rel = str(fp.relative_to(public_dir))
        title, description = parse_html(fp)

        if not title:
            failures.append(f"{rel}: missing title")
        else:
            if len(title) < args.title_min or len(title) > args.title_max:
                failures.append(f"{rel}: title length {len(title)} out of [{args.title_min},{args.title_max}]")
            if stuffing_risk(title, args.stuffing_threshold):
                failures.append(f"{rel}: title stuffing risk")

        if not description:
            failures.append(f"{rel}: missing meta description")
        else:
            if len(description) < args.description_min or len(description) > args.description_max:
                failures.append(
                    f"{rel}: description length {len(description)} out of [{args.description_min},{args.description_max}]"
                )
            if stuffing_risk(description, args.stuffing_threshold):
                failures.append(f"{rel}: description stuffing risk")

    if failures:
        print("Snippet quality check failed:")
        for item in failures[:120]:
            print(f"- {item}")
        raise SystemExit(1)

    print(f"OK: snippet quality validated on {len(files)} HTML files in {public_dir}")


if __name__ == "__main__":
    main()
