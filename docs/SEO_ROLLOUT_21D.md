# SEO Rollout 21D

Plan operativo para estabilizar el sistema automático SEO tras los cambios de hardening.

## Objetivo

- Mantener seguridad de despliegue (PR + gates + rollback guard).
- Reducir regresiones.
- Aumentar precisión neta del motor antes de acelerar volumen.

## Día 1 (Activación)

1. Ejecutar manualmente:
   - `.github/workflows/seo-auto-pr.yml`
   - `.github/workflows/seo-pr-gates.yml`
   - `.github/workflows/seo-outcome-guard.yml`
   - `.github/workflows/seo-slo-dashboard.yml`
2. Verificar issues canónicos sin duplicados.
3. Confirmar que `.github/config/seo-thresholds.json` pasa validación.

Criterio go/no-go:
- GO si no hay fallos de sintaxis/workflow y los checks críticos pasan.
- NO-GO si falla cualquier gate de calidad o rollback guard detecta regresión fuerte.

## Semana 1 (Modo conservador)

Configuración recomendada:
- holdoutRatio: 0.12 a 0.15
- ctrDropThreshold: 0.18 a 0.22
- oppGrowthMin: 0.85 a 0.90

Objetivos:
- Cero regresiones críticas en producción.
- Baseline de precisión por tipo de cambio.

Criterio go/no-go:
- GO si semáforo cluster no está en rojo.
- NO-GO si cluster en rojo dos runs consecutivos.

## Semana 2 (Calibración)

Acciones:
1. Usar `seo-rollout-governor.yml` para propuesta de tuning.
2. Revisar PR de `seo-threshold-tuning-pr.yml` y aprobar solo si consistente.
3. Corregir deuda detectada por:
   - `check_snippet_quality.py`
   - `check_internal_link_coverage.py`
   - `check_duplicate_snippets.py`

Criterio go/no-go:
- GO si mejora precisión global y baja ruido de alertas.
- NO-GO si suben rollbacks o fallos en gates.

## Semana 3 (Escalado controlado)

Acciones:
1. Si estabilidad buena, bajar holdout ligeramente (por ejemplo -0.02).
2. Mantener PR-only para autoparches.
3. Priorizar ejecución por impacto negocio (`seo-business-impact.yml`) + backlog (`seo-backlog-prioritizer.yml`).

Criterio go/no-go:
- GO si precisión cluster estable en verde/amarillo y sin regresiones críticas.
- NO-GO si reaparecen regresiones de snippets/indexabilidad.

## KPIs de seguimiento

- % autoparches con impacto positivo neto.
- % PRs SEO bloqueadas por gates.
- Nº rollbacks automáticos por semana.
- Semáforo cluster (`seo-engine-precision.yml`).
- Ingreso proxy semanal (`seo-business-impact.yml`).

## Principios de operación

- No desactivar gates para “pasar rápido”.
- No bajar holdout mientras semáforo sea rojo.
- Hacer cambios de thresholds por PR, nunca directo en master.
- Favorecer cambios pequeños y reversibles.
