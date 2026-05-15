# SEO Rollout 21D

Plan operativo **100% automático** para estabilizar el sistema SEO. Sin intervención manual. Solo criterios de go/no-go validados por bots.

## Objetivo

- Mantener seguridad de despliegue (PR + gates + rollback guard).
- Reducir regresiones.
- Aumentar precisión neta del motor antes de acelerar volumen.

## Día 1 (Activación automática)

**Workflow**: `seo-bootstrap-protection.yml` + `seo-weekly-ops.yml` (manual trigger)

Acciones automáticas:
1. ✅ Reactivar branch protection con checks requeridos
2. ✅ Ejecutar validación de config (seo-config-guard, seo-rules-guard)
3. ✅ Generar baseline de precisión (`seo-engine-precision.yml`)
4. ✅ Crear scorecard inicial (`seo-scorecard.yml`)

**Criterio go/no-go (automático):**
```
GO si:
  - Cero errores de sintaxis en workflows
  - Todos los scripts Python compilan
  - Branch protection activo con 4 checks requeridos
  - Primer scorecard generado sin errores
  
NO-GO si:
  - Cualquier check requerido está en ERROR
  - Hay conflictos no resueltos en config
```

## Semana 1 (Modo conservador - automático)

**Configuración en `seo-thresholds.json`:**
```json
{
  "holdoutRatio": 0.15,
  "ctrDropThreshold": 0.20,
  "minHoursBetweenPatches": 18,
  "oppGrowthMin": 0.88
}
```

**Workflows automáticos cada 24h:**
- `seo-auto-pr.yml` → genera PRs automáticos
- `seo-outcome-guard.yml` → detecta regresiones automáticamente
- `seo-weekly-ops.yml` → genera reporte de progreso
- `seo-engine-precision.yml` → calcula precisión neta

**Criterio go/no-go (automático):**
```
GO (continúa rollout) si:
  - Rollbacks detectados ≤ 1 por semana
  - Semáforo cluster NO está en rojo
  - Auto-merge de PRs de bot ≥ 80%
  
NO-GO (pausa automática) si:
  - Rollbacks > 2 en semana 1
  - Cluster en rojo 2+ runs consecutivos
  - Más del 20% de PRs rechazadas por gates
  
→ Acción auto: Crear issue "⚠️ Rollout paused: investigate"
```

## Semana 2 (Calibración automática)

**Workflows automáticos:**
- `seo-threshold-tuning-pr.yml` (jueves 11:00 UTC) → abre PR de tuning automático
- `seo-backlog-prioritizer.yml` (viernes) → prioriza por impacto
- `seo-slo-dashboard.yml` (lunes) → valida SLOs

**Tuning automático de thresholds:**
El PR de tuning es auto-aprobado y auto-mergeado si:
```
- Mejora precisión neta (Δ > +0.5%)
- Baja tasa de regresiones (Δ < -10%)
- No crea anomalías nuevas (gates ≥ 85% pass rate)
```

**Criterio go/no-go (automático):**
```
GO (acelera un poco) si:
  - Precisión mejora semana a semana
  - Rollbacks ≤ 1
  - Deuda de calidad → PRs abiertos y tracked
  
NO-GO (mantiene conservador) si:
  - Precisión plana o empeora
  - Rollbacks > 1
  - Deuda detectada pero no resuelta
  
→ Acción auto: `seo-weekly-ops.yml` crea issue de estado
```

## Semana 3 (Escalado controlado automático)

**Cambio automático de configuración:**
Si en semana 2 se cumple go/no-go, `seo-threshold-tuning-pr.yml` automáticamente:
- Baja `holdoutRatio` de 0.15 → 0.12
- Baja `minHoursBetweenPatches` de 18 → 16
- Abre PR, se valida, auto-merge si cumple gates

**Workflows intensificados:**
- `seo-auto-pr.yml` más agresivo (sin holdout si precisión > 90%)
- `seo-interlink-recommendations.yml` (lunes) → nuevas recs de interlinking
- `seo-business-impact.yml` (miércoles) → impacto económico

**Criterio go/no-go (automático):**
```
GO (cero throttle, full speed) si:
  - Precisión verde (≥ 92%)
  - Rollbacks cero en semana 3
  - No hay gates bloqueados 2+ horas
  - SLO de uptime ≥ 99%
  
NO-GO (vuelve a throttle) si:
  - Precisión baja (< 88%)
  - Rollbacks > 0 en semana 3
  - Gates bloqueados > 4 horas
  
→ Acción auto: `seo-threshold-tuning-pr.yml` revierte config automáticamente
```



## KPIs de seguimiento (automáticos)

Generados por `seo-weekly-ops.yml` cada lunes:

| KPI | Fuente | Criterio GO | Criterio NO-GO |
|-----|--------|-------------|---|
| % Autoparches exitosos | `seo-engine-precision.yml` | ≥ 85% | < 75% |
| Rollbacks por semana | `seo-outcome-guard.yml` | ≤ 1 | > 2 |
| PRs bloqueadas por gates | `seo-required-gate.yml` | ≤ 10% | > 20% |
| Semáforo cluster | `seo-engine-precision.yml` | Verde/Amarillo | Rojo 2+x |
| Auto-merge rate (bots) | `seo-automerge-bot-prs.yml` | ≥ 90% | < 70% |
| SLO uptime | `seo-slo-dashboard.yml` | ≥ 99% | < 95% |

**Reporte automático:**
→ `seo-weekly-ops.yml` crea issue si hay NO-GO en cualquier métrica

## Reglas automáticas (sin intervención)

1. **Auto-merge habilitado**: PRs etiquetadas `seo,automated` se mergean sin revisor si pasan checks
2. **Rollback automático**: Si `seo-outcome-guard.yml` detecta regresión (CTR drop > threshold), revierte automáticamente
3. **Tuning automático**: PR de threshold tuning se auto-mergea si mejora precisión + baja regresiones
4. **Throttle automático**: Si precisión baja, `seo-auto-pr.yml` baja `holdoutRatio` automáticamente
5. **Escalado automático**: Si criterio go/no-go se cumple 2 semanas, workflow baja throttles

## Dashboard de estado

Accesible en GitHub Actions:

```
Semana N: [criterios automáticos]
├── Status: GO / NO-GO / PAUSED
├── KPIs: OK / WARN / ALERT
├── Acciones tomadas: [lista de PRs auto-merged, rollbacks, tuning]
└── Siguiente paso: [acción automática programada]
```

## Principios de operación (automatizados)

✅ **Hacer automáticamente:**
- Gates + rollback guard sin excepción
- Tuning de thresholds vía PR automático
- Escalado/throttle por métricas objetivas
- Reportes de estado cada semana
- Rollback automático en caso de regresión

❌ **Nunca hacer manualmente:**
- Desactivar gates "para pasar rápido"
- Cambiar thresholds directo en master
- Ignorar alertas de rollbacks
- Hacer merge sin checks requeridos

## Escalera de decisión (automática)

```
semana_actual <= 1:
  holdoutRatio = 0.15, conservador
  minHoursBetweenPatches = 18
  criterio_go = no rollbacks + cluster_ok

semana_actual == 2:
  IF criterio_go_semana1:
    holdoutRatio -= 0.02
    tuning_pr = auto-open (auto-merge si OK)
  ELSE:
    holdoutRatio = 0.15 (pausa)

semana_actual >= 3:
  IF criterio_go_semana2 AND precision >= 90%:
    holdoutRatio = 0.10
    minHoursBetweenPatches = 14
  ELSE:
    holdoutRatio = 0.12
```

## Trigger manual (único punto de intervención)

Único caso donde un humano hace algo:
```bash
# Solo después de semana 3 si todo está rojo
gh workflow run seo-bootstrap-protection.yml  # Reactivar si fue desactivado por error
```

Todo lo demás es 100% bot.

---

**Versión automática**: v1.0 (21D operativo sin intervención)
**Última actualización**: 2026-05-15
**Mantenedor**: SEO automation suite
