#!/usr/bin/env python3
import argparse
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("public_dir")
    parser.add_argument("--max-kb", type=int, default=180)
    args = parser.parse_args()

    public_dir = Path(args.public_dir)
    limit = args.max_kb * 1024
    failures = []
    for html_file in sorted(public_dir.rglob("*.html")):
        size = html_file.stat().st_size
        if size > limit:
            failures.append((html_file.relative_to(public_dir), size))

    if failures:
        print(f"HTML size budget exceeded ({args.max_kb} KiB):")
        for path, size in failures:
            print(f"- {path}: {size / 1024:.1f} KiB")
        return 1

    print(f"OK: HTML files under {args.max_kb} KiB in {public_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
