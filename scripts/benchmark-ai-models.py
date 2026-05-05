#!/usr/bin/env python3
"""
Benchmark pequeno de modelos para la interpretacion IA de astro-cluster.

Lee claves desde .env sin imprimirlas. Por defecto hace una unica llamada corta
por modelo y guarda resultados en .local/ai-benchmark/.
"""

from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import os
import statistics
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENV_FILE = ROOT / ".env"
OUT_DIR = ROOT / ".local" / "ai-benchmark"

DEFAULT_OPENAI_MODELS = ["gpt-4.1-nano", "gpt-4.1-mini"]
DEFAULT_NVIDIA_MODELS = [
    "meta/llama-3.1-8b-instruct",
    "openai/gpt-oss-20b",
]
DEFAULT_GEMINI_MODELS = ["gemini-2.5-flash"]
DEFAULT_NEARAI_MODELS = ["Qwen/Qwen3-30B-A3B-Instruct-2507"]

SYSTEM_PROMPT = """\
Eres un astrologo profesional que redacta interpretaciones de cartas natales para carta-astral-gratis.es.
Responde en espanol, con tono cercano y util. Devuelve solo HTML limpio con <h3>, <p>, <ul> y <li>.
Evita frases genericas. Menciona signos, casas, grados y aspectos concretos cuando existan en los datos.
"""

USER_PROMPT = """\
Interpreta esta carta astral natal en una version compacta de benchmark.

Nacimiento: 14/5/1992 a las 09:35, Madrid (40.4168, -3.7038)
Sexo: Femenino
Ascendente: Cancer 18°42'
Medio Cielo: Aries 27°10'

Planetas:
  Sol: Tauro 23°51' - Casa 11
  Luna: Libra 08°14' - Casa 4
  Mercurio: Tauro 12°33' - Casa 10
  Venus: Geminis 02°18' - Casa 11
  Marte: Aries 19°05' - Casa 10
  Jupiter: Virgo 04°47' - Casa 3
  Saturno: Acuario 18°21' - Casa 8
  Urano: Capricornio 17°40' - Casa 7
  Neptuno: Capricornio 18°43' - Casa 7
  Pluton: Escorpio 21°22' - Casa 5
  Nodo Norte: Capricornio 02°11'

Casas destacadas: Casa 10, Casa 11 y Casa 7.
Aspectos principales:
  Sol oposicion Pluton (orbe 2.5°)
  Marte cuadratura Urano (orbe 1.4°)
  Marte cuadratura Neptuno (orbe 0.4°)
  Saturno cuadratura Sol (orbe 5.5°)
  Luna trigono Venus (orbe 6.0°)

Distribucion elementos: Tierra 4, Aire 3, Fuego 1, Agua 1.
Distribucion modalidades: Fija 3, Cardinal 4, Mutable 2.

Incluye exactamente estas secciones:
<h3>Sintesis natal</h3>
<h3>Fortalezas</h3>
<h3>Retos</h3>
<h3>Consejo practico</h3>

Extension objetivo: 450-700 palabras.
"""

REQUIRED_MARKERS = [
    "<h3>",
    "Sintesis natal",
    "Fortalezas",
    "Retos",
    "Consejo practico",
    "Tauro",
    "Casa 10",
    "Pluton",
]


def load_dotenv(path: Path) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def env_list(name: str, default: list[str]) -> list[str]:
    value = os.environ.get(name, "").strip()
    if not value:
        return default
    return [item.strip() for item in value.split(",") if item.strip()]


def request_json(method: str, url: str, headers: dict[str, str], payload: dict | None = None, timeout: int = 90) -> dict:
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {body[:500]}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(str(exc)) from exc


def list_openai_models() -> list[str]:
    key = os.environ.get("OPENAI_API_KEY", "")
    if not key:
        return []
    data = request_json("GET", "https://api.openai.com/v1/models", {"Authorization": f"Bearer {key}"})
    return sorted(item["id"] for item in data.get("data", []) if isinstance(item, dict) and item.get("id"))


def list_nvidia_models() -> list[str]:
    key = os.environ.get("NVIDIA_AI_API_KEY", "")
    if not key:
        return []
    data = request_json("GET", "https://integrate.api.nvidia.com/v1/models", {"Authorization": f"Bearer {key}"})
    return sorted(item["id"] for item in data.get("data", []) if isinstance(item, dict) and item.get("id"))


def list_gemini_models() -> list[str]:
    key = os.environ.get("GEMINI_API_KEY", "")
    if not key:
        return []
    query = urllib.parse.urlencode({"key": key})
    data = request_json("GET", f"https://generativelanguage.googleapis.com/v1beta/models?{query}", {})
    models = []
    for item in data.get("models", []):
        name = item.get("name", "").removeprefix("models/")
        methods = item.get("supportedGenerationMethods", [])
        if name and "generateContent" in methods:
            models.append(name)
    return sorted(models)


def list_nearai_models() -> list[str]:
    key = os.environ.get("NEARAI_API_KEY", "")
    if not key:
        return []
    base_url = os.environ.get("NEARAI_BASE_URL", "https://cloud-api.near.ai/v1")
    data = request_json("GET", f"{base_url.rstrip('/')}/models", {"Authorization": f"Bearer {key}"})
    return sorted(item["id"] for item in data.get("data", []) if isinstance(item, dict) and item.get("id"))


def call_openai(model: str, max_tokens: int) -> tuple[str, dict]:
    key = os.environ["OPENAI_API_KEY"]
    payload = {
        "model": model,
        "input": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": USER_PROMPT},
        ],
        "temperature": 0.4,
        "max_output_tokens": max_tokens,
    }
    data = request_json(
        "POST",
        "https://api.openai.com/v1/responses",
        {"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
        payload,
    )
    chunks = []
    for item in data.get("output", []):
        for content in item.get("content", []):
            if content.get("type") in {"output_text", "text"}:
                chunks.append(content.get("text", ""))
    return "".join(chunks), data.get("usage", {})


def call_openai_compatible(provider: str, base_url: str, key_name: str, model: str, max_tokens: int) -> tuple[str, dict]:
    key = os.environ[key_name]
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": USER_PROMPT},
        ],
        "temperature": 0.4,
        "max_tokens": max_tokens,
    }
    data = request_json(
        "POST",
        f"{base_url.rstrip('/')}/chat/completions",
        {"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
        payload,
    )
    text = data.get("choices", [{}])[0].get("message", {}).get("content") or ""
    return text, data.get("usage", {})


def call_gemini(model: str, max_tokens: int) -> tuple[str, dict]:
    key = os.environ["GEMINI_API_KEY"]
    query = urllib.parse.urlencode({"key": key})
    payload = {
        "system_instruction": {"parts": [{"text": SYSTEM_PROMPT}]},
        "contents": [{"role": "user", "parts": [{"text": USER_PROMPT}]}],
        "generationConfig": {
            "temperature": 0.4,
            "maxOutputTokens": max_tokens,
            "thinkingConfig": {"thinkingBudget": 0},
        },
    }
    data = request_json(
        "POST",
        f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?{query}",
        {"Content-Type": "application/json"},
        payload,
    )
    candidate = data.get("candidates", [{}])[0]
    parts = candidate.get("content", {}).get("parts", [])
    text = "".join(part.get("text", "") for part in parts)
    return text, data.get("usageMetadata", {})


def score_text(text: str, latency_seconds: float) -> dict:
    escaped = html.unescape(text)
    words = len(escaped.split())
    marker_hits = sum(1 for marker in REQUIRED_MARKERS if marker.lower() in escaped.lower())
    has_markdown_fence = "```" in escaped
    has_html_shape = escaped.strip().startswith("<") and escaped.count("<h3>") >= 4
    length_score = 1.0 if 450 <= words <= 750 else max(0.0, 1.0 - abs(words - 575) / 575)
    marker_score = marker_hits / len(REQUIRED_MARKERS)
    html_score = 1.0 if has_html_shape and not has_markdown_fence else 0.4 if "<h3>" in escaped else 0.0
    latency_score = max(0.0, min(1.0, 1.0 - latency_seconds / 45.0))
    total = (marker_score * 0.45) + (html_score * 0.25) + (length_score * 0.20) + (latency_score * 0.10)
    return {
        "score": round(total * 100, 1),
        "words": words,
        "marker_hits": marker_hits,
        "html_score": html_score,
        "length_score": round(length_score, 3),
        "latency_score": round(latency_score, 3),
        "has_markdown_fence": has_markdown_fence,
    }


def bench_one(provider: str, model: str, max_tokens: int) -> dict:
    started = time.perf_counter()
    if provider == "openai":
        text, usage = call_openai(model, max_tokens)
    elif provider == "nvidia":
        text, usage = call_openai_compatible(
            provider,
            "https://integrate.api.nvidia.com/v1",
            "NVIDIA_AI_API_KEY",
            model,
            max_tokens,
        )
    elif provider == "gemini":
        text, usage = call_gemini(model, max_tokens)
    elif provider == "nearai":
        text, usage = call_openai_compatible(
            provider,
            os.environ.get("NEARAI_BASE_URL", "https://cloud-api.near.ai/v1"),
            "NEARAI_API_KEY",
            model,
            max_tokens,
        )
    else:
        raise ValueError(provider)
    latency = time.perf_counter() - started
    metrics = score_text(text, latency)
    return {
        "provider": provider,
        "model": model,
        "ok": True,
        "latency_seconds": round(latency, 3),
        "metrics": metrics,
        "usage": usage,
        "sample": text,
    }


def summarize(results: list[dict]) -> str:
    rows = []
    for result in results:
        if result.get("ok"):
            metrics = result["metrics"]
            rows.append(
                "| {provider} | {model} | {score} | {latency:.2f}s | {words} | {markers}/{total} | ok |".format(
                    provider=result["provider"],
                    model=result["model"],
                    score=metrics["score"],
                    latency=result["latency_seconds"],
                    words=metrics["words"],
                    markers=metrics["marker_hits"],
                    total=len(REQUIRED_MARKERS),
                )
            )
        else:
            rows.append(f"| {result['provider']} | {result['model']} | - | - | - | - | error |")
    scores = [r["metrics"]["score"] for r in results if r.get("ok")]
    avg = round(statistics.mean(scores), 1) if scores else None
    best = max((r for r in results if r.get("ok")), key=lambda r: r["metrics"]["score"], default=None)
    lines = [
        "# AI benchmark",
        "",
        f"Fecha: {dt.datetime.now().isoformat(timespec='seconds')}",
        f"Media score: {avg if avg is not None else 'n/a'}",
        f"Mejor modelo: {best['provider']} / {best['model']}" if best else "Mejor modelo: n/a",
        "",
        "| Provider | Modelo | Score | Latencia | Palabras | Marcadores | Estado |",
        "|---|---:|---:|---:|---:|---:|---|",
        *rows,
        "",
        "Scoring local: marcadores astrológicos/estructura HTML/longitud/latencia. Revisa siempre las muestras antes de decidir.",
    ]
    return "\n".join(lines) + "\n"


def print_models() -> None:
    for provider, loader in [
        ("openai", list_openai_models),
        ("nvidia", list_nvidia_models),
        ("gemini", list_gemini_models),
        ("nearai", list_nearai_models),
    ]:
        try:
            models = loader()
        except Exception as exc:
            print(f"{provider}: ERROR {exc}", file=sys.stderr)
            continue
        if not models:
            print(f"{provider}: sin clave o sin modelos visibles")
            continue
        print(f"{provider}:")
        for model in models:
            print(f"  {model}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Benchmark de modelos IA para astro-cluster")
    parser.add_argument("--list-models", action="store_true", help="lista modelos visibles por API y no ejecuta benchmark")
    parser.add_argument("--provider", choices=["openai", "nvidia", "gemini", "nearai"], action="append", help="proveedor a probar")
    parser.add_argument("--max-tokens", type=int, default=int(os.environ.get("AI_BENCH_MAX_TOKENS", "900")))
    args = parser.parse_args()

    load_dotenv(ENV_FILE)

    if args.list_models:
        print_models()
        return 0

    providers = args.provider or []
    if not providers:
        if os.environ.get("OPENAI_API_KEY"):
            providers.append("openai")
        if os.environ.get("NVIDIA_AI_API_KEY"):
            providers.append("nvidia")
        if os.environ.get("GEMINI_API_KEY"):
            providers.append("gemini")
        if os.environ.get("NEARAI_API_KEY"):
            providers.append("nearai")
    if not providers:
        print("No hay claves disponibles en .env para OpenAI, NVIDIA o Gemini.", file=sys.stderr)
        return 2

    plan: list[tuple[str, str]] = []
    if "openai" in providers:
        plan.extend(("openai", model) for model in env_list("OPENAI_BENCH_MODELS", DEFAULT_OPENAI_MODELS))
    if "nvidia" in providers:
        plan.extend(("nvidia", model) for model in env_list("NVIDIA_BENCH_MODELS", DEFAULT_NVIDIA_MODELS))
    if "gemini" in providers:
        plan.extend(("gemini", model) for model in env_list("GEMINI_BENCH_MODELS", DEFAULT_GEMINI_MODELS))
    if "nearai" in providers:
        plan.extend(("nearai", model) for model in env_list("NEARAI_BENCH_MODELS", env_list("NEARAI_MODEL", DEFAULT_NEARAI_MODELS)))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    results = []
    for provider, model in plan:
        print(f"Probando {provider}/{model}...", flush=True)
        try:
            results.append(bench_one(provider, model, args.max_tokens))
        except Exception as exc:
            results.append({"provider": provider, "model": model, "ok": False, "error": str(exc)})

    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    raw_path = OUT_DIR / f"results-{stamp}.json"
    report_path = OUT_DIR / f"report-{stamp}.md"
    raw_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    report_path.write_text(summarize(results), encoding="utf-8")
    print(f"\nReporte: {report_path}")
    print(f"Resultados raw: {raw_path}")
    print(report_path.read_text(encoding="utf-8"))
    return 0 if any(r.get("ok") for r in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
