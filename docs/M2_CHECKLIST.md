# M2 Checklist

Checklist operativo para decidir si el cluster esta listo para empujar M2 sin gastar mas de lo necesario.

## Indexacion

- [ ] GSC no muestra nuevos motivos de exclusion para URLs criticas.
- [ ] `calcular-numerologia.es` no tiene URLs indexables con `noindex`.
- [ ] Sitemaps frescos y con canonical correcto.
- [ ] Homes con title, description, H1, canonical y JSON-LD.

## Operacion

- [ ] Deploy de sitios modificados en verde.
- [ ] SEO smoke en verde o con issue abierto y accionable.
- [ ] Lighthouse solo ejecutado manualmente cuando haga falta.
- [ ] Acciones semanales sin pico anormal de runs.

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

- [ ] OAuth de usuario (GSC/AdSense) vigente en el informe semanal.
- [ ] El informe semanal marca dataset `completo` (no `parcial`) dos ejecuciones seguidas.
- [ ] Si OAuth falla, hay issue canonico de degradacion y se cierra al recuperar.

### Fase 1 - Traccion organica

- [ ] `organic_share` semanal >= 25% como tramo intermedio hacia M2.
- [ ] Subir sesiones semanales a >= 120 antes de ampliar automatizaciones.
- [ ] Priorizar autoparche SEO en queries/paginas con oportunidad real (CTR bajo + impresiones).

### Fase 2 - Recirculacion

- [ ] `internal_tool_click` semanal >= 6.
- [ ] Bloques de recirculacion con CTA explicito por intencion en home + long-tail principal.
- [ ] Medicion por evento revisada en GA4 antes de tocar mas UX.

### Fase 3 - Monetizacion validada

- [ ] `advertiser_cta_click` semanal >= 2.
- [ ] Estado de AdSense por dominio visible en informe (cuando OAuth este operativo).
- [ ] Outreach activo solo con lista corta curada y limite de envio diario.

### Fase 4 - Gobernanza y FinOps

- [ ] No hacer push automatico cuando el dataset semanal sea parcial.
- [ ] Mantener deploy selectivo y checks de alto valor (evitar cron redundante).
- [ ] Revisar trimestralmente workflows para podar ejecuciones de bajo impacto.
