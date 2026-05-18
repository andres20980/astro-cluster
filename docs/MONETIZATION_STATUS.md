# Monetization Status

Estado operativo para venta directa y AdSense. Mantener este archivo simple: sirve para decidir el siguiente fix sin abrir dashboards.

| Sitio | ads.txt | Pagina publicidad | CTA directo | Auto Ads |
| --- | --- | --- | --- | --- |
| carta-astral-gratis.es | OK | OK | OK | Variable `ADSENSE_AUTO_ADS_ENABLED` |
| compatibilidad-signos.es | OK | OK | OK | Variable `ADSENSE_AUTO_ADS_ENABLED` |
| tarot-del-dia.es | OK | OK | OK | Variable `ADSENSE_AUTO_ADS_ENABLED` |
| calcular-numerologia.es | OK | OK | OK | Variable `ADSENSE_AUTO_ADS_ENABLED` |
| horoscopo-de-hoy.es | OK | OK | OK | Variable `ADSENSE_AUTO_ADS_ENABLED` |
| meditacion-chakras.es | OK | OK | OK | Variable `ADSENSE_AUTO_ADS_ENABLED` |

## Estado de revision en AdSense

Captura manual del panel de AdSense de `poorku@gmail.com`, 2026-05-18:

| Sitio | Estado | Motivo | Deteccion |
| --- | --- | --- | --- |
| compatibilidad-signos.es | Requiere su atencion | Contenido de poco valor | No se encuentra |
| tarot-del-dia.es | Requiere su atencion | Contenido de poco valor | Autorizado |
| carta-astral-gratis.es | Preparando | - | No se encuentra |
| horoscopo-de-hoy.es | Preparando | - | No se encuentra |
| meditacion-chakras.es | Preparando | - | No se encuentra |
| calcular-numerologia.es | Preparando | - | Autorizado |

## Guardrails

- `ads.txt` debe contener `pub-9368517395014039`.
- `/publicidad` debe existir; queda `noindex, follow` y fuera del sitemap salvo que `DIRECT_ADS_ENABLED=1`.
- Auto Ads se despliega por defecto para verificacion/revision de AdSense; se desactiva con `ADSENSE_AUTO_ADS_ENABLED=0`.
- Los CTAs de venta directa y la indexacion de `/publicidad` se activan solo con `DIRECT_ADS_ENABLED=1`.
- Los CTAs de venta directa se miden como `advertiser_cta_click`.

## Siguiente criterio de revision AdSense

- No reenviar sitios con "Contenido de poco valor" sin ampliar valor editorial visible y diferenciado.
- Priorizar `tarot-del-dia.es`: ya aparece como autorizado, asi que el bloqueo principal es calidad/contenido.
- Revisar deteccion de `compatibilidad-signos.es`, `carta-astral-gratis.es`, `horoscopo-de-hoy.es` y `meditacion-chakras.es` antes de insistir en revision, aunque las homes y `ads.txt` respondan por HTTPS.
- En `compatibilidad-signos.es`, valorar redirigir las parejas invertidas a su canonical para reducir ruido de URLs `noindex`.

## Siguiente criterio de venta

- Priorizar banners directos cuando GSC/GA4 muestren impresiones organicas recurrentes por sitio.
- Mantener formatos estaticos y contextuales antes que integraciones complejas.
- No activar nuevos scripts de terceros sin una razon comercial clara.
