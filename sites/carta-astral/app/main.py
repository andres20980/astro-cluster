"""
API web para generación de cartas astrales natales.

Endpoints:
  POST /api/parse-pdf       — Extrae datos de un certificado de nacimiento
  POST /api/calculate-chart — Calcula la carta astral
  POST /api/interpret-chart — Interpreta la carta con IA (rate limited)
  GET  /                    — Sirve el frontend
"""

import time
import tempfile
from collections import defaultdict
from pathlib import Path

from fastapi import FastAPI, File, UploadFile, HTTPException, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from app.pdf_parser import parse_birth_certificate
from app.chart_engine import calculate_chart
from app.interpreter import interpret_chart

app = FastAPI(title="Carta Astral", version="1.0.0")

STATIC_DIR = Path(__file__).parent / "static"

# --------------- rate limiter (interpret endpoint) ---------------
_RATE_WINDOW = 3600          # 1 hora
_RATE_MAX_REQUESTS = 5       # máx por IP por ventana
_rate_store: dict[str, list[float]] = defaultdict(list)

# global daily cap — hard stop to protect free tier
_DAILY_CAP = 200
_daily_count = 0
_daily_reset: float = 0.0


def _check_rate_limit(ip: str) -> None:
    """Lanza HTTPException 429 si se supera el límite por IP o el cap global diario."""
    global _daily_count, _daily_reset
    now = time.monotonic()

    # reset daily counter every 24h
    if now - _daily_reset > 86_400:
        _daily_count = 0
        _daily_reset = now

    if _daily_count >= _DAILY_CAP:
        raise HTTPException(
            429,
            "Se ha alcanzado el límite diario de interpretaciones. Vuelve mañana.",
        )

    # per-IP check
    hits = _rate_store[ip]
    _rate_store[ip] = [t for t in hits if now - t < _RATE_WINDOW]
    if len(_rate_store[ip]) >= _RATE_MAX_REQUESTS:
        raise HTTPException(
            429,
            "Has alcanzado el límite de interpretaciones por hora. Inténtalo más tarde.",
        )
    _rate_store[ip].append(now)
    _daily_count += 1


class ChartRequest(BaseModel):
    name: str
    year: int
    month: int
    day: int
    hour: int
    minute: int
    lat: float
    lng: float
    city: str = ""
    tz: str = "Europe/Madrid"
    sex: str | None = None


@app.post("/api/parse-pdf")
async def parse_pdf(file: UploadFile = File(...)):
    """Parsea un certificado de nacimiento PDF y devuelve los datos extraídos."""
    if not file.filename or not file.filename.lower().endswith(".pdf"):
        raise HTTPException(400, "Solo se aceptan archivos PDF")

    content = await file.read()
    if len(content) > 10 * 1024 * 1024:
        raise HTTPException(400, "Archivo demasiado grande (máx 10MB)")

    with tempfile.NamedTemporaryFile(suffix=".pdf", delete=True) as tmp:
        tmp.write(content)
        tmp.flush()
        try:
            result = parse_birth_certificate(tmp.name)
        except Exception as e:
            raise HTTPException(422, f"Error al procesar el PDF: {e}")

    # No devolver raw_text al cliente (salvo debug)
    raw = result.pop("raw_text", None)
    return result


@app.post("/api/calculate-chart")
async def api_calculate_chart(req: ChartRequest):
    """Calcula la carta astral a partir de los datos de nacimiento."""
    try:
        chart = calculate_chart(
            name=req.name,
            year=req.year, month=req.month, day=req.day,
            hour=req.hour, minute=req.minute,
            lat=req.lat, lng=req.lng,
            city=req.city, tz=req.tz,
        )
    except Exception as e:
        raise HTTPException(500, f"Error en el cálculo: {e}")

    return chart


@app.post("/api/interpret-chart")
async def api_interpret_chart(req: ChartRequest, request: Request):
    """Calcula la carta y devuelve una interpretación con IA."""
    client_ip = request.headers.get("x-forwarded-for", request.client.host if request.client else "unknown").split(",")[0].strip()
    _check_rate_limit(client_ip)
    try:
        chart = calculate_chart(
            name=req.name,
            year=req.year, month=req.month, day=req.day,
            hour=req.hour, minute=req.minute,
            lat=req.lat, lng=req.lng,
            city=req.city, tz=req.tz,
        )
    except Exception as e:
        raise HTTPException(500, f"Error en el cálculo: {e}")

    try:
        html = await interpret_chart(chart, sex=req.sex)
    except Exception as e:
        raise HTTPException(502, f"Error al generar interpretación: {e}")

    return {"interpretation": html}


@app.get("/")
async def index():
    """Sirve el frontend."""
    return FileResponse(STATIC_DIR / "index.html")


app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")
