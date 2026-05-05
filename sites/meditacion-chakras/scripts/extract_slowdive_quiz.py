#!/usr/bin/env python3
"""Extract Slowdive chakra funnel content in ES using Scrapling fetchers."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any
from urllib.parse import urljoin

from scrapling.fetchers import Fetcher


SOURCE_URL = "https://meditation.slowdive.app/chakras/1"


def _resp_text(response: Any) -> str:
    for attr in ("text", "content", "body", "raw_content", "html_content", "html"):
        if hasattr(response, attr):
            value = getattr(response, attr)
            if callable(value):
                try:
                    value = value()
                except TypeError:
                    continue
            if isinstance(value, bytes):
                decoded = value.decode("utf-8", errors="ignore")
                if decoded.strip():
                    return decoded
                continue
            if isinstance(value, str):
                if value.strip():
                    return value
                continue
    try:
        return str(response)
    except Exception:
        return ""


def _unescape(value: str) -> str:
    cleaned = value.replace("\\n", " ").replace("\\r", " ").replace("\\t", " ")
    cleaned = cleaned.replace("\\/", "/")
    return bytes(cleaned, "utf-8").decode("unicode_escape").strip()


def _extract_block(blob: str, start_marker: str, next_markers: list[str]) -> str:
    start = blob.find(start_marker)
    if start == -1:
        return ""
    end = len(blob)
    for marker in next_markers:
        pos = blob.find(marker, start + len(start_marker))
        if pos != -1:
            end = min(end, pos)
    return blob[start:end]


def _extract_locale_chunk(main_js: str) -> str:
    pattern = re.compile(r'es:\[\{key:[^\]]+?import\("(\./[A-Za-z0-9_-]+\.js)"\)', re.S)
    match = pattern.search(main_js)
    if not match:
        raise RuntimeError("No se encontro el chunk locale de es en el bundle principal")
    return match.group(1).replace("./", "")


def _extract_step_data(locale_js: str) -> list[dict[str, Any]]:
    data: list[dict[str, Any]] = []
    for idx in range(23):
        block = _extract_block(
            locale_js,
            f"QUIZ{idx}:{{",
            [f"}},QUIZ{idx + 1}:", "},PLAN:{", "},PAYWALL:{", "},FINAL:{", "},CANCEL_FLOW:{"],
        )
        if not block:
            data.append({"step": idx + 1, "question": "", "answers": []})
            continue

        question_match = re.search(r"QUESTION(?:_[A-Z]+)?:\{.*?s:\"((?:[^\"\\]|\\.)*)\"", block, re.S)
        if not question_match:
            question_match = re.search(r"TITLE:\{.*?s:\"((?:[^\"\\]|\\.)*)\"", block, re.S)
        if not question_match:
            question_match = re.search(r"HTML:\{.*?s:\"((?:[^\"\\]|\\.)*)\"", block, re.S)

        answers = [
            _unescape(value)
            for value in re.findall(r"ANSWER\d+:\{.*?s:\"((?:[^\"\\]|\\.)*)\"", block, re.S)
        ]

        if idx == 0 and not answers:
            answers = [
                _unescape(value)
                for value in re.findall(r"(?:MALE|FEMALE|OTHER):\{.*?s:\"((?:[^\"\\]|\\.)*)\"", block, re.S)
            ]

        question = _unescape(question_match.group(1)) if question_match else ""

        data.append(
            {
                "step": idx + 1,
                "question": question,
                "answers": [a for a in answers if a],
            }
        )

    return data


def extract(source_url: str, output_json: Path, output_raw: Path) -> None:
    page = Fetcher.get(source_url, stealthy_headers=True)
    html = _resp_text(page)
    output_raw.parent.mkdir(parents=True, exist_ok=True)

    main_bundle_match = re.search(r'src="(/_nuxt/[^"]+\.js)"', html)
    if not main_bundle_match:
        raise RuntimeError("No se pudo detectar el bundle principal de Nuxt")

    main_url = urljoin(source_url, main_bundle_match.group(1))
    main_bundle = _resp_text(Fetcher.get(main_url, stealthy_headers=True))

    locale_chunk = _extract_locale_chunk(main_bundle)
    locale_url = urljoin(source_url, f"/_nuxt/{locale_chunk}")
    locale_js = _resp_text(Fetcher.get(locale_url, stealthy_headers=True))
    output_raw.write_text(locale_js, encoding="utf-8")

    steps = _extract_step_data(locale_js)

    payload = {
        "source": source_url,
        "locale_chunk": locale_chunk,
        "steps": steps,
    }
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract chakra quiz content from Slowdive")
    parser.add_argument("--source", default=SOURCE_URL)
    parser.add_argument("--output", default="sites/meditacion-chakras/docs/QUIZ_DATA_ES.json")
    parser.add_argument("--raw", default="sites/meditacion-chakras/docs/SLOWDIVE_ES_RAW.js")
    args = parser.parse_args()

    extract(args.source, Path(args.output), Path(args.raw))
