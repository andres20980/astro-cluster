# DNS — Astro Cluster

Todos los dominios están en **Piensa Solutions** (ns97/ns98.piensasolutions.com).

## Registros comunes a TODOS los dominios

| Tipo | Nombre | Valor | TTL |
|------|--------|-------|-----|
| A | @ | `199.36.158.100` | 3600 |
| MX | @ | `10 mx1.improvmx.com` | 3600 |
| MX | @ | `20 mx2.improvmx.com` | 3600 |
| TXT | @ | `v=spf1 include:spf.improvmx.com ~all` | 3600 |

> La IP `199.36.158.100` es la de Firebase Hosting global.
> ImprovMX se usa para reenvío de email del dominio.

---

## 1. carta-astral-gratis.es

Firebase project: `carta-astral-f4ab9`

| Tipo | Nombre | Valor | TTL |
|------|--------|-------|-----|
| A | @ | `199.36.158.100` | 3600 |
| CNAME | www | `carta-astral-f4ab9.web.app` | 3600 |
| MX | @ | `10 mx1.improvmx.com` | 3600 |
| MX | @ | `20 mx2.improvmx.com` | 3600 |
| TXT | @ | `v=spf1 include:spf.improvmx.com ~all` | 3600 |
| TXT | @ | `google-site-verification=x02IbSeXH-i8nm_h0nEA_iFzvdSa6jdOoILtcyXFsa8` | 3600 |
| TXT | _acme-challenge | `RPkgsG_f6LmpdscQrkyvxKY4o1eHijCDbcoWnjgdr_s` | 3600 |

**Estado: ✅ Configurado y funcionando**

---

## 2. compatibilidad-signos.es

Firebase project: `compat-signos-es`

| Tipo | Nombre | Valor | TTL |
|------|--------|-------|-----|
| A | @ | `199.36.158.100` | 3600 |
| CNAME | www | `compat-signos-es.web.app` | 3600 |
| MX | @ | `10 mx1.improvmx.com` | 3600 |
| MX | @ | `20 mx2.improvmx.com` | 3600 |
| TXT | @ | `v=spf1 include:spf.improvmx.com ~all` | 3600 |
| TXT | @ | `hosting-site=compat-signos-es` | 3600 |
| TXT | @ | *(google-site-verification — pendiente de Search Console)* | 3600 |
| TXT | _acme-challenge | `ae0XwtyMP3f8cx_unWdHbb17KLvfvzPihaZOyyA33Uk` | 3600 |

**Estado: ⏳ Pendiente de configurar DNS en Piensa Solutions**

---

## 3. tarot-del-dia.es

Firebase project: `tarot-del-dia-es`

| Tipo | Nombre | Valor | TTL |
|------|--------|-------|-----|
| A | @ | `199.36.158.100` | 3600 |
| CNAME | www | `tarot-del-dia-es.web.app` | 3600 |
| MX | @ | `10 mx1.improvmx.com` | 3600 |
| MX | @ | `20 mx2.improvmx.com` | 3600 |
| TXT | @ | `v=spf1 include:spf.improvmx.com ~all` | 3600 |
| TXT | @ | `hosting-site=tarot-del-dia-es` | 3600 |
| TXT | @ | *(google-site-verification — pendiente de Search Console)* | 3600 |
| TXT | _acme-challenge | `ULH29pUoJ6T8LCti3oCYT3zUveH6Df8Xes_vaDmtWlA` | 3600 |

**Estado: ⏳ Pendiente de configurar DNS en Piensa Solutions**

---

## 4. calcular-numerologia.es

Firebase project: `calc-numerologia-es`

| Tipo | Nombre | Valor | TTL |
|------|--------|-------|-----|
| A | @ | `199.36.158.100` | 3600 |
| CNAME | www | `calc-numerologia-es.web.app` | 3600 |
| MX | @ | `10 mx1.improvmx.com` | 3600 |
| MX | @ | `20 mx2.improvmx.com` | 3600 |
| TXT | @ | `v=spf1 include:spf.improvmx.com ~all` | 3600 |
| TXT | @ | `hosting-site=calc-numerologia-es` | 3600 |
| TXT | @ | *(google-site-verification — pendiente de Search Console)* | 3600 |
| TXT | _acme-challenge | `hY5QfB1UDJHyiHmXMyjeMtQP3BlEOxBzGTK05ijkgRQ` | 3600 |

**Estado: ⏳ Pendiente de configurar DNS en Piensa Solutions**

---

## 5. horoscopo-de-hoy.es

Firebase project: `horoscopo-hoy-es`

| Tipo | Nombre | Valor | TTL |
|------|--------|-------|-----|
| A | @ | `199.36.158.100` | 3600 |
| CNAME | www | `horoscopo-hoy-es.web.app` | 3600 |
| MX | @ | `10 mx1.improvmx.com` | 3600 |
| MX | @ | `20 mx2.improvmx.com` | 3600 |
| TXT | @ | `v=spf1 include:spf.improvmx.com ~all` | 3600 |
| TXT | @ | `hosting-site=horoscopo-hoy-es` | 3600 |
| TXT | @ | *(google-site-verification — pendiente de Search Console)* | 3600 |
| TXT | _acme-challenge | `EjFvRk9FSIxsE_6r9wgBAiiddpqZrB22AYnxkO23LuM` | 3600 |

**Estado: ⏳ Pendiente de configurar DNS en Piensa Solutions**

---

## Pasos para cada dominio nuevo

1. **Firebase Console** → Hosting → Agregar dominio personalizado → te da el valor de `_acme-challenge`
2. **Piensa Solutions** → DNS → Añadir registros (A, CNAME www, TXT _acme-challenge)
3. **ImprovMX** → Añadir dominio → Copiar registros MX + SPF
4. **Google Search Console** → Añadir propiedad → Verificación por TXT → Copiar valor `google-site-verification`
5. Esperar propagación DNS (hasta 48h, normalmente <1h)
6. Actualizar este documento con los valores reales
