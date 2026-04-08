# carta-astral

Generador de cartas astrales natales con cálculos astronómicos de precisión (Swiss Ephemeris).

## App Web

Aplicación web que permite subir un certificado de nacimiento (PDF del Registro Civil español),
marcar el punto exacto de nacimiento en un mapa, y generar la carta astral natal completa.

### Ejecutar

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Abrir http://localhost:8000

### Flujo

1. **Subir certificado PDF** — extrae automáticamente nombre, fecha y hora de nacimiento
2. **Marcar lugar en mapa** — clic en el punto exacto (hospital, clínica, domicilio)
3. **Generar carta** — calcula posiciones, casas, aspectos, elementos y modalidades

## CLI

```bash
python scripts/calcular_carta.py \
  --name "Ejemplo" \
  --date 1990-06-15 \
  --time 10:30 \
  --lat 40.4168 \
  --lng -3.7038
```

## Estructura

```
carta-astral/
├── app/
│   ├── main.py              # API FastAPI
│   ├── pdf_parser.py        # Parser de certificados de nacimiento
│   ├── chart_engine.py      # Motor de cálculo (Kerykeion/Swiss Ephemeris)
│   └── static/
│       └── index.html       # Frontend (Leaflet maps + UI)
├── scripts/
│   └── calcular_carta.py    # CLI standalone
├── requirements.txt
└── README.md
```

## Metodología

- **Motor**: Swiss Ephemeris (alta precisión)
- **Sistema de casas**: Placidus
- **Zodíaco**: Tropical
- **Orbes**: Conjunción/Oposición 8°, Trígono/Cuadratura 7-8°, Sextil 6°, Quincuncio 3°
- **Puntos calculados**: 10 planetas + Quirón + Nodo Norte + 12 casas + aspectos mayores

## Cartas generadas

Las cartas se generan bajo demanda a través de la web o el CLI. Los archivos de salida no se incluyen en el repositorio.
