#!/usr/bin/env python3
import argparse
from datetime import date, datetime
from pathlib import Path
from xml.etree import ElementTree


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("sitemap")
    parser.add_argument("--max-age-days", type=int, default=45)
    args = parser.parse_args()

    sitemap = Path(args.sitemap)
    if not sitemap.is_file():
        print(f"Missing sitemap: {sitemap}")
        return 1

    root = ElementTree.parse(sitemap).getroot()
    namespace = ""
    if root.tag.startswith("{"):
        namespace = root.tag.split("}", 1)[0] + "}"

    today = date.today()
    failures = []
    urls = root.findall(f".//{namespace}url")
    for url in urls:
        loc = url.find(f"{namespace}loc")
        lastmod = url.find(f"{namespace}lastmod")
        location = (loc.text or "").strip() if loc is not None else "(missing loc)"
        value = (lastmod.text or "").strip() if lastmod is not None else ""
        if not value:
            failures.append(f"{location}: missing lastmod")
            continue
        try:
            lastmod_date = datetime.fromisoformat(value.replace("Z", "+00:00")).date()
        except ValueError:
            failures.append(f"{location}: invalid lastmod {value!r}")
            continue
        age = (today - lastmod_date).days
        if age < 0:
            failures.append(f"{location}: future lastmod {value!r}")
        elif age > args.max_age_days:
            failures.append(f"{location}: lastmod is {age} days old")

    if failures:
        print("Sitemap freshness check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"OK: {len(urls)} sitemap entries are fresh in {sitemap}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
