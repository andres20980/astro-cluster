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

## Guardrails

- `ads.txt` debe contener `pub-9368517395014039`.
- `/publicidad` debe estar indexable y enlazada.
- Auto Ads se despliega por defecto para verificacion/revision de AdSense; se desactiva con `ADSENSE_AUTO_ADS_ENABLED=0`.
- Los CTAs de venta directa y la indexacion de `/publicidad` se activan solo con `DIRECT_ADS_ENABLED=1`.
- Los CTAs de venta directa se miden como `advertiser_cta_click`.

## Siguiente criterio de venta

- Priorizar banners directos cuando GSC/GA4 muestren impresiones organicas recurrentes por sitio.
- Mantener formatos estaticos y contextuales antes que integraciones complejas.
- No activar nuevos scripts de terceros sin una razon comercial clara.
