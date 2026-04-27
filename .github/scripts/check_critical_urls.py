#!/usr/bin/env python3
import argparse
import json
from html.parser import HTMLParser
from pathlib import Path


class HtmlMetaParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.canonical = ""
        self.robots = ""
        self.title = []
        self.h1 = []
        self.in_title = False
        self.in_h1 = False
        self.ldjson_chunks = []
        self.in_ldjson = False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "title":
            self.in_title = True
        elif tag == "h1":
            self.in_h1 = True
        elif tag == "link" and "canonical" in attrs.get("rel", "").lower().split():
            self.canonical = attrs.get("href", "")
        elif tag == "meta" and attrs.get("name", "").lower() == "robots":
            self.robots = attrs.get("content", "")
        elif tag == "script" and attrs.get("type", "").lower() == "application/ld+json":
            self.in_ldjson = True

    def handle_endtag(self, tag):
        if tag == "title":
            self.in_title = False
        elif tag == "h1":
            self.in_h1 = False
        elif tag == "script":
            self.in_ldjson = False

    def handle_data(self, data):
        if self.in_title:
            self.title.append(data.strip())
        elif self.in_h1:
            self.h1.append(data.strip())
        elif self.in_ldjson and data.strip():
            self.ldjson_chunks.append(data)


def html_file_for(public_dir, path):
    clean_path = path.strip("/")
    if not clean_path:
        candidates = [public_dir / "index.html"]
    else:
        candidates = [
            public_dir / f"{clean_path}.html",
            public_dir / clean_path / "index.html",
            public_dir / clean_path,
        ]
    return next((candidate for candidate in candidates if candidate.is_file()), None)


def expected_canonical(domain, path):
    clean_path = path.strip("/")
    if not clean_path:
        return f"https://{domain}"
    return f"https://{domain}/{clean_path}"


def read_manifest(path):
    urls = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line and not line.startswith("#"):
            urls.append(line)
    return urls


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("site_dir")
    parser.add_argument("domain")
    args = parser.parse_args()

    site_dir = Path(args.site_dir)
    public_dir = site_dir / "public"
    manifest = site_dir / "docs" / "CRITICAL_URLS.txt"
    if not manifest.is_file():
        print(f"Missing critical URL manifest: {manifest}")
        return 1

    failures = []
    for path in read_manifest(manifest):
        if path in {"/sitemap.xml", "/robots.txt", "/ads.txt"}:
            asset = public_dir / path.strip("/")
            if not asset.is_file():
                failures.append(f"{path}: missing required public asset")
            continue

        html_file = html_file_for(public_dir, path)
        if not html_file:
            failures.append(f"{path}: missing matching HTML file")
            continue

        html = html_file.read_text(encoding="utf-8", errors="ignore")
        page = HtmlMetaParser()
        page.feed(html)
        canonical = page.canonical.rstrip("/")

        if "noindex" in page.robots.lower():
            failures.append(f"{path}: contains noindex ({html_file})")
        if canonical != expected_canonical(args.domain, path):
            failures.append(
                f"{path}: canonical mismatch {page.canonical!r}, expected {expected_canonical(args.domain, path)!r}"
            )
        if not any(page.title):
            failures.append(f"{path}: missing title")
        if not any(page.h1):
            failures.append(f"{path}: missing h1")
        for chunk in page.ldjson_chunks:
            try:
                json.loads(chunk)
            except json.JSONDecodeError as exc:
                failures.append(f"{path}: invalid JSON-LD ({exc})")

    if failures:
        print("Critical URL check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"OK: critical URLs pass for {args.domain}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
