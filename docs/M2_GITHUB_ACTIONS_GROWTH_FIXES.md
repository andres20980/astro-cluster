# M2 GitHub Actions Growth Fixes

Objetivo: convertir el primer crecimiento organico en crecimiento total sostenido usando los runs existentes, sin anadir crons caros ni duplicar analitica.

## Fixes aplicados

1. Reutilizar `weekly-google-report.yml` como run de captura de senales.
   - El informe semanal ya consulta GA4, GSC y AdSense.
   - Tambien genera `SEO_GSC_QUERIES.json`, `SEO_GA4_PAGES.json` y `SEO_TEMPLATE_FAMILIES.json` por site.
   - Estos ficheros son la fuente unica para decidir que site merece el siguiente autoparche.

2. Encadenar `seo-auto-pr.yml` despues del informe semanal.
   - `seo-auto-pr.yml` mantiene su ejecucion manual y su cron laboral.
   - Ademas se activa con `workflow_run` cuando `weekly-google-report.yml` termina correctamente.
   - Asi el autoparche usa las senales frescas del informe semanal sin crear otro workflow de crecimiento.

3. Evitar autoparches automaticos si la senal semanal no es accionable.
   - El selector de site acepta `--require-fresh-signal`.
   - En el disparo automatico semanal solo selecciona site si hay score positivo con senales frescas.
   - Si no hay senal, el run termina sin cambios y sin push.

4. Mantener el fallback rotatorio solo para runs manuales o cron laboral.
   - El calendario normal puede seguir tocando el cluster aunque falten datos.
   - El encadenamiento semanal queda mas estricto porque representa una decision basada en GA4/GSC.

5. Conservar el limite free-tier.
   - `SEO_AUTO_PR_MAX_CHANGES=1` sigue igual.
   - No se anade un nuevo cron.
   - El workflow de uso de Actions sigue vigilando picos semanales.

## Serie de fixes siguiente

1. Confirmar en el proximo informe semanal que `WEEKLY_DATA_QUALITY=complete`.
2. Verificar que el run encadenado de `seo-auto-pr.yml` se salta si el informe semanal falla.
3. Revisar que el autoparche elige el site con mayor score, no solo el siguiente del calendario.
4. Si el site elegido no cambia nada, ampliar reglas SEO solo para queries con `topOpportunities`.
5. Priorizar titles/descriptions con CTR bajo y posicion 4-20 antes de crear nuevas paginas.
6. Anadir reglas de copy para reforzar enlaces internos desde la home del site ganador.
7. Medir si `internal_tool_click` sube de 2 a 6+ por semana tras cada autoparche.
8. Medir si organico sube de 12 a 120 sesiones/semana antes de aumentar frecuencia.
9. Mantener deploy selectivo: solo publicar sites tocados por el autoparche.
10. No automatizar outreach ni monetizacion directa hasta ver traccion organica recurrente por dominio.

## Criterio de avance

- Si el informe semanal trae datos completos y el autoparche cambia 1 site con senal fresca, el loop automatico queda operativo.
- Si no hay cambios, el siguiente fix no es mas CI: es enriquecer reglas para la query o familia con oportunidad real.
- Si sube `internal_tool_click` pero no organico, el siguiente bloque es SEO de entrada.
- Si sube organico pero no recirculacion, el siguiente bloque es CTA inter-site y eventos `result_to_next_tool_click`.
