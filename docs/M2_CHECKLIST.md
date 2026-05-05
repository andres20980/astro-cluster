# M2 Checklist

Checklist operativo para decidir si el cluster esta listo para empujar M2 sin gastar mas de lo necesario.

Estado actual: M2 esta en progreso. La base tecnica queda preparada para mejorar SEO organico, pero la mejora real se confirma con datos frescos de GSC/GA4 tras el deploy completo, no solo con checks HTTP.

GA4 local validado el 2026-05-05 con `sites/carta-astral/scripts/manage-google.sh ga4-m2-status 7`:

- Sesiones: 63 / 1500 objetivo M2 (4.2%).
- Organico: 12 sesiones / 120 tramo tactico (10.0%), organic share 19.0%.
- Recirculacion: 2 `internal_tool_click` / 6 tramo tactico.
- `meditacion-chakras.es` ya aparece en GA4 con 11 sesiones.

Conclusion: el plan inmediato es suficiente como foco operativo, pero no cierra M2. Hay que ejecutar hasta superar 120 sesiones organicas/semana, 6+ clicks internos/semana y despues acercar el cluster a 1500 sesiones/semana.

## Cambio operativo reciente

- [x] `meditacion-chakras.es` responde `200` en produccion.
- [x] `www.meditacion-chakras.es` redirige `301` al apex.
- [x] Firebase Hosting asociado al site real usado por DNS: `meditacion-chakras-a9565`.
- [x] Las 6 homes canonicas del cluster responden `200`.

## Indexacion

- [ ] GSC no muestra nuevos motivos de exclusion para URLs criticas.
- [x] `calcular-numerologia.es` no tiene URLs indexables con `noindex`.
- [x] Sitemaps frescos y con canonical correcto.
- [x] Homes con title, description, H1, canonical y JSON-LD.

## Operacion

- [x] Deploy de sitios modificados en verde.
- [x] SEO smoke en verde o con issue abierto y accionable.
- [x] Lighthouse solo ejecutado manualmente cuando haga falta.
- [x] Acciones semanales sin pico anormal de runs.
- [x] `seo-auto-pr.yml` reutiliza el run semanal de Google con `workflow_run` y solo autoparchea si hay senales frescas.

## Monetizacion

- [ ] `ads.txt` correcto en dominio raiz y `www`.
- [ ] `/publicidad` accesible, indexable y enlazada.
- [ ] Evento `advertiser_cta_click` visible en GA4.
- [ ] Lista corta de prospects preparada antes de activar nuevo outreach.

## Decision

- [ ] Si indexacion y operacion estan en verde, pasar a crecimiento/contenido.
- [ ] Si hay warning GSC activo, inspeccionar URL manualmente antes de tocar generadores.
- [ ] Si hay costes/CI al alza, reducir cron antes de anadir nuevos checks.

## Plan por fases (free-tier)

### Fase 0 - Observabilidad

- [x] GA4 local consulta Analytics Data sin `403 ACCESS_TOKEN_SCOPE_INSUFFICIENT`.
- [ ] OAuth de usuario (GSC/AdSense) vigente en el informe semanal.
- [ ] El informe semanal marca dataset `completo` (no `parcial`) dos ejecuciones seguidas.
- [ ] Si OAuth falla, hay issue canonico de degradacion y se cierra al recuperar.

### Fase 1 - Traccion organica

- [ ] `organic_share` semanal >= 25% como tramo intermedio hacia M2.
- [ ] Subir sesiones semanales a >= 120 antes de ampliar automatizaciones.
- [x] Confirmar que `meditacion-chakras.es` aparece en GA4 tras el deploy.
- [x] Encadenar el informe semanal GA4/GSC con el autoparche SEO sin anadir un cron nuevo.
- [ ] Priorizar autoparche SEO en queries/paginas con oportunidad real (CTR bajo + impresiones).
- [ ] Confirmar en el siguiente informe semanal que el trafico organico entra por varios dominios, no solo por una home aislada.
- [ ] Comparar clicks e impresiones de las 6 home canonicas antes/despues del deploy de recirculacion.

### Fase 2 - Recirculacion

- [ ] `internal_tool_click` semanal >= 6.
- [ ] Bloques de recirculacion con CTA explicito por intencion en home + long-tail principal.
- [ ] Medicion por evento revisada en GA4 antes de tocar mas UX.
- [ ] Medir `result_to_next_tool_click` por dominio de entrada SEO.
- [ ] Revisar `tools_seen_count` para saber si el usuario organico ve 2+ herramientas por sesion de cluster.

### Fase 3 - Monetizacion validada

- [ ] `advertiser_cta_click` semanal >= 2.
- [ ] Estado de AdSense por dominio visible en informe (cuando OAuth este operativo).
- [ ] Outreach activo solo con lista corta curada y limite de envio diario.

### Fase 4 - Gobernanza y FinOps

- [ ] No hacer push automatico cuando el dataset semanal sea parcial.
- [ ] Mantener deploy selectivo y checks de alto valor (evitar cron redundante).
- [ ] Revisar trimestralmente workflows para podar ejecuciones de bajo impacto.
