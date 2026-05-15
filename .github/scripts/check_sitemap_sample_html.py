#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path
from urllib.parse import urlparse
from xml.etree import ElementTree

from seo_smoke_html_checks import PageParser


def read_locations(sitemap_path: Path):
    root = ElementTree.parse(sitemap_path).getroot()
    ns = ""
    if root.tag.startswith("{"):
        ns = root.tag.split("}", 1)[0] + "}"
    return [(loc.text or "").strip() for loc in root.findall(f".//{ns}loc") if (loc.text or "").strip()]


def local_path_for_url(public_dir: Path, url: str):
    parsed = urlparse(url)
    path = parsed.path.strip("/")
    candidates = []
    if not path:
        candidates.append(public_dir / "index.html")
    else:
        candidates.append(public_dir / f"{path}.html")
        candidates.append(public_dir / path / "index.html")
        candidates.append(public_dir / path)
    for c in candidates:
        if c.is_file():
            return c
    return None


def check_html(domain: str, fp: Path):
    html = fp.read_text(encoding="utf-8", errors="ignore")
    parser = PageParser()
    parser.feed(html)

    title_text = " ".join(chunk.strip() for chunk in parser.title_chunks if chunk.strip()).strip()
    h1_text = " ".join(chunk.strip() for chunk in parser.h1_chunks if chunk.strip()).strip()
    canonical = parser.canonical.rstrip("/")
    meta_robots = parser.meta_robots.lower()

    return {
        "title_present": bool(title_text),
        "meta_description_present": bool(parser.meta_description.strip()),
        "canonical_ok": canonical == f"https://{domain}" or canonical.startswith(f"https://{domain}/"),
        "structured_data_present": parser.has_ldjson,
        "homepage_not_noindex": "noindex" not in meta_robots,
        "h1_present": bool(h1_text),
    }


def main():
    ap = argparse.ArgumentParser(description="Sample sitemap URLs and validate core SEO tags on generated HTML")
    ap.add_argument("public_dir")
    ap.add_argument("domain")
    ap.add_argument("--sample-size", type=int, default=10)
    args = ap.parse_args()

    public_dir = Path(args.public_dir)
    sitemap = public_dir / "sitemap.xml"
    if not sitemap.is_file():
        raise SystemExit(f"Missing sitemap: {sitemap}")

    locations = read_locations(sitemap)
    if not locations:
        raise SystemExit("Sitemap has no URLs")

    sample_size = max(1, args.sample_size)
    sampled = locations[:sample_size]
    failures = []
    checked = 0

    for url in sampled:
        fp = local_path_for_url(public_dir, url)
        if not fp:
            failures.append(f"{url}: no local HTML mapping")
            continue
        checks = check_html(args.domain, fp)
        checked += 1
        for key, ok in checks.items():
            if not ok:
                failures.append(f"{url}: {key}=false")

    if failures:
        print("Sitemap sample SEO check failed:")
        for fail in failures[:50]:
            print(f"- {fail}")
        raise SystemExit(1)

    print(json.dumps({
        "checked": checked,
        "sampled": len(sampled),
        "status": "ok",
    }))


if __name__ == "__main__":
    main()
