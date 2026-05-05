# AI benchmark

Benchmark local para comparar modelos de IA candidatos para `sites/carta-astral/app/interpreter.py`.

## Uso

```bash
python3 scripts/benchmark-ai-models.py --list-models
python3 scripts/benchmark-ai-models.py
```

El script lee `.env` y no imprime claves. Guarda reportes en `.local/ai-benchmark/`, carpeta ignorada por git.

Variables soportadas:

- `OPENAI_API_KEY`
- `NVIDIA_AI_API_KEY`
- `GEMINI_API_KEY`
- `NEARAI_API_KEY`
- `NEARAI_BASE_URL`
- `OPENAI_BENCH_MODELS`
- `NVIDIA_BENCH_MODELS`
- `GEMINI_BENCH_MODELS`
- `NEARAI_BENCH_MODELS`

Ejemplo de tanda ampliada:

```bash
OPENAI_BENCH_MODELS=gpt-4.1-nano,gpt-5.4-nano \
NVIDIA_BENCH_MODELS=openai/gpt-oss-20b,deepseek-ai/deepseek-v4-flash \
NEARAI_BENCH_MODELS=Qwen/Qwen3-30B-A3B-Instruct-2507,google/gemini-3-pro \
python3 scripts/benchmark-ai-models.py
```

## Criterio

El score local combina:

- Marcadores astrologicos y datos concretos de la carta.
- Estructura HTML esperada.
- Longitud objetivo para una respuesta compacta.
- Latencia.

El resultado es orientativo. Antes de cambiar produccion hay que revisar muestras, confirmar limites/coste real en el dashboard de cada proveedor y repetir con el prompt largo de produccion.

## Resultado inicial

Con la tanda corta del 2026-04-27:

- Mejor calidad local: `openai/gpt-4.1-nano`.
- Mejor balance rapido en NVIDIA: `nvidia/openai/gpt-oss-20b`.
- Gemini directo necesita `thinkingBudget: 0` para no consumir la salida en razonamiento invisible.
- `NEARAI_MODEL=Qwen/Qwen3-30B-A3B-Instruct-2507` queda como candidato, no como decision cerrada.
