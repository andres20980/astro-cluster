## ── Stage 1: build wheels ──────────────────────────
FROM python:3.12-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

## ── Stage 2: runtime ──────────────────────────────
FROM python:3.12-slim

WORKDIR /app

# Copy pre-built Python packages (no build-essential needed here)
COPY --from=builder /install /usr/local

COPY app/ ./app/

EXPOSE 8080

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
