#!/usr/bin/env python3
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse
from xml.etree import ElementTree


class PageMetaParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.canonical = ""
        self.robots = ""

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "link" and "canonical" in attrs.get("rel", "").lower().split():
            self.canonical = attrs.get("href", "")
        elif tag == "meta" and attrs.get("name", "").lower() == "robots":
            self.robots = attrs.get("content", "")


def normalize_url(value):
    return value.rstrip("/")


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

    for candidate in candidates:
        if candidate.is_file():
            return candidate
    return None


def read_sitemap_locations(sitemap_path):
    root = ElementTree.parse(sitemap_path).getroot()
    namespace = ""
    if root.tag.startswith("{"):
        namespace = root.tag.split("}", 1)[0] + "}"
    return [
        (loc.text or "").strip()
        for loc in root.findall(f".//{namespace}loc")
        if (loc.text or "").strip()
    ]


def main():
    if len(sys.argv) != 3:
        print(
            "usage: check_sitemap_indexability.py <public_dir> <domain>",
            file=sys.stderr,
        )
        return 2

    public_dir = Path(sys.argv[1])
    domain = sys.argv[2]
    sitemap_path = public_dir / "sitemap.xml"
    if not sitemap_path.is_file():
        print(f"Missing sitemap: {sitemap_path}", file=sys.stderr)
        return 1

    failures = []
    locations = read_sitemap_locations(sitemap_path)
    homepage = f"https://{domain}/"
    if (public_dir / "index.html").is_file() and normalize_url(homepage) not in {
        normalize_url(location) for location in locations
    }:
        locations.insert(0, homepage)

    for location in locations:
        parsed = urlparse(location)
        if parsed.scheme != "https" or parsed.netloc != domain:
            failures.append(f"{location}: expected https://{domain}")
            continue

        html_file = html_file_for(public_dir, parsed.path)
        if not html_file:
            failures.append(f"{location}: no matching HTML file under {public_dir}")
            continue

        parser = PageMetaParser()
        parser.feed(html_file.read_text(encoding="utf-8", errors="ignore"))

        if "noindex" in parser.robots.lower():
            failures.append(f"{location}: sitemap URL points to noindex page ({html_file})")
        if not parser.canonical:
            failures.append(f"{location}: missing canonical ({html_file})")
        elif normalize_url(parser.canonical) != normalize_url(location):
            failures.append(
                f"{location}: canonical mismatch {parser.canonical} ({html_file})"
            )

    if failures:
        print("Sitemap indexability check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"OK: {len(locations)} sitemap URLs are indexable for {domain}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
