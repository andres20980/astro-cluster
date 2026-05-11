# Cluster Recirculation Plan

Objetivo: tratar `astro-cluster` como un unico producto distribuido. Cada dominio captura una intencion SEO distinta, pero la experiencia, la medicion, la monetizacion y las decisiones operativas se evaluan como cluster.

## Principios

- Entregar primero el valor prometido por la pagina antes de empujar a otra herramienta.
- Recomendar la siguiente herramienta por intencion, no por rotacion generica.
- Medir impresiones, clics y finalizaciones para distinguir problema de copy, posicion o encaje.
- Mantener una sola propiedad GA4 cluster-wide y un publisher AdSense comun.
- Usar GSC por dominio, pero decidir prioridades con metricas agregadas de cluster.
- Mantener todo estatico y free-tier friendly: sin backend, sin base de datos, sin CMS y sin experimentos de terceros.
- Usar AdSense como remanente; venta directa y afiliacion contextual como inventario premium.
- No enviar datos personales a analytics. Los parametros deben ser slugs, categorias o contadores no sensibles.

## Journeys

| Journey | Entrada natural | Siguiente paso primario | Secundarios | Intencion |
| --- | --- | --- | --- | --- |
| Energia del dia | `horoscopo-de-hoy` | `tarot-del-dia` | `meditacion-chakras`, `carta-astral` | Pasar de prediccion diaria a decision e integracion |
| Autoconocimiento profundo | `calcular-numerologia` | `carta-astral` | `meditacion-chakras`, `horoscopo-de-hoy` | Completar identidad simbolica con mapa personal |
| Amor y pareja | `compatibilidad-signos` | `carta-astral` | `tarot-del-dia`, `meditacion-chakras` | Pasar de afinidad general a lectura relacional profunda |
| Decision puntual | `tarot-del-dia` | `meditacion-chakras` | `horoscopo-de-hoy`, `carta-astral` | Convertir una lectura inmediata en accion o calma |
| Perfil personal | `carta-astral` | `compatibilidad-signos` | `calcular-numerologia`, `meditacion-chakras` | Usar la carta como base para capas concretas |
| Integracion emocional | `meditacion-chakras` | `carta-astral` | `horoscopo-de-hoy`, `tarot-del-dia` | Cruzar practica interior con simbolos personales |

## Fixes Aplicados Como Politica

1. Medicion cluster-first con eventos comunes: `page_view`, `cluster_recirculation_impression`, `internal_tool_click`, `result_to_next_tool_click`, `advertiser_cta_impression`, `advertiser_cta_click`, `tool_start`, `tool_complete` y eventos especificos existentes.
2. Parametros estables: `site_key`, `site_domain`, `tool_type`, `page_type`, `content_group`, `entity_slug`, `journey_stage`, `origin_site`, `destination_site`, `destination_domain`, `link_context`, `recirculation_variant`, `cluster_session_id`, `first_site_seen`, `tools_seen_count`, `completed_tools_count`, `last_tool_completed`.
3. Persistencia ligera en `localStorage`, sin servidor y sin datos personales.
4. Bloques de recirculacion generados desde configuracion compartida.
5. Recomendaciones con un camino primario y dos secundarios por site.
6. Impresiones medidas con `IntersectionObserver` y fallback inmediato.
7. Clicks desde bloques de resultado separados con `result_to_next_tool_click`.
8. CTAs comerciales separados de recirculacion editorial.
9. Paginas `/publicidad` vendiendo dominios individuales y paquetes de cluster.
10. Auto Ads se emite por defecto para verificacion/revision, salvo `ADSENSE_AUTO_ADS_ENABLED=0`.
11. SEO mantiene canonical por dominio y evita canonicals cruzados.
12. Reporting recomendado semanal, no runtime.
13. Checks estaticos para atributos de recirculacion y manifiestos GA4.

## Serie Exhaustiva 1-275

1. Definir `astro-cluster` como producto unico distribuido.
2. Mantener un mapa canonico de sites, dominios y herramientas.
3. Usar una sola propiedad GA4 para el cluster.
4. Usar un unico publisher AdSense compartido.
5. Medir cada page view con `site_key`.
6. Medir cada page view con `site_domain`.
7. Medir cada page view con `tool_type`.
8. Medir cada page view con `page_type`.
9. Medir cada page view con `content_group`.
10. Medir slugs con `entity_slug`.
11. Evitar PII en eventos analytics.
12. Crear `cluster_session_id` local no personal.
13. Persistir `first_site_seen`.
14. Persistir contador de herramientas vistas.
15. Persistir contador de herramientas completadas.
16. Persistir ultima herramienta completada.
17. Deduplicar completions por herramienta.
18. Separar navegacion interna de recirculacion de resultado.
19. Crear evento `result_to_next_tool_click`.
20. Crear evento `cluster_recirculation_impression`.
21. Crear evento `advertiser_cta_impression`.
22. Mantener `advertiser_cta_click` separado.
23. Anadir `journey_stage` a eventos clave.
24. Anadir `origin_site` a eventos clave.
25. Anadir `destination_site` a clics cross-domain.
26. Anadir `destination_domain` a clics cross-domain.
27. Anadir `link_context` a clics.
28. Anadir `recirculation_variant` a cards.
29. Anadir `ad_slot` a CTAs comerciales.
30. Activar linker cross-domain en GA4.
31. Incluir los seis dominios en el linker.
32. Marcar blocks de recirculacion con data attributes.
33. Marcar CTAs comerciales con data attributes.
34. Medir impresiones con `IntersectionObserver`.
35. Mantener fallback sin `IntersectionObserver`.
36. No introducir servidor para recomendaciones.
37. No introducir base de datos para sesiones.
38. No introducir login para continuidad.
39. No introducir cookies nuevas.
40. Usar `localStorage` con datos no sensibles.
41. Mantener opt-out analytics por querystring.
42. Mantener `send_page_view:false` para control manual.
43. Centralizar GA4 en `shared/config.sh`.
44. Centralizar AdSense en `shared/config.sh`.
45. Centralizar dominios en `shared/config.sh`.
46. Centralizar nombres de herramientas en `shared/config.sh`.
47. Centralizar tipos de herramienta en `shared/config.sh`.
48. Centralizar copy comercial por site.
49. Centralizar journeys por site.
50. Centralizar cards de recirculacion.
51. Crear matriz primaria/secundaria por site.
52. Carta astral recomienda compatibilidad como primario.
53. Carta astral recomienda numerologia como secundario.
54. Carta astral recomienda chakras como secundario.
55. Compatibilidad recomienda carta astral como primario.
56. Compatibilidad recomienda tarot como secundario.
57. Compatibilidad recomienda chakras como secundario.
58. Tarot recomienda chakras como primario.
59. Tarot recomienda horoscopo como secundario.
60. Tarot recomienda carta astral como secundario.
61. Numerologia recomienda carta astral como primario.
62. Numerologia recomienda chakras como secundario.
63. Numerologia recomienda horoscopo como secundario.
64. Horoscopo recomienda tarot como primario.
65. Horoscopo recomienda chakras como secundario.
66. Horoscopo recomienda carta astral como secundario.
67. Chakras recomienda carta astral como primario.
68. Chakras recomienda horoscopo como secundario.
69. Chakras recomienda tarot como secundario.
70. Evitar rotacion aleatoria de enlaces.
71. Evitar recomendaciones genericas sin intencion.
72. Mantener un bloque principal de recirculacion por landing.
73. Situar recirculacion despues del valor principal.
74. No interrumpir el uso de la herramienta.
75. No tapar resultado con interstitials.
76. No crear popups de salida.
77. Usar copy de continuidad contextual.
78. Usar CTA especifico por siguiente paso.
79. Diferenciar card primaria de secundarias.
80. Usar `rel="noopener"` en enlaces externos.
81. Mantener enlaces absolutizados por dominio.
82. Mantener `data-destination-site` en cards.
83. Mantener `data-destination-domain` en cards.
84. Mantener `data-link-context="result_recirculation"`.
85. Mantener `data-recirculation-variant="primary"`.
86. Mantener `data-recirculation-variant="secondary"`.
87. Mantener nofollow fuera de enlaces editoriales internos.
88. Mantener canonicals propios por dominio.
89. Evitar canonical cross-domain.
90. Mantener sitemap por dominio.
91. Mantener robots por dominio.
92. Mantener ads.txt por dominio.
93. Mantener privacy por dominio.
94. Mantener terms por dominio.
95. Mantener `inLanguage` coherente en schema.
96. Mantener WebApplication schema en herramientas.
97. Mantener Organization schema por dominio.
98. No duplicar H1 para recirculacion.
99. Usar H2 contextual en bloques.
100. Evitar keyword stuffing en recirculacion.
101. Mantener copy natural orientado a usuario.
102. Mantener anchor text descriptivo.
103. Mantener el footer con todos los sites.
104. Incluir meditacion-chakras en el cluster visible.
105. Actualizar publicidad de cinco a seis herramientas.
106. Vender inventario por dominio.
107. Vender inventario por paquete de cluster.
108. Crear paquetes por intencion.
109. Crear paquete amor y pareja.
110. Crear paquete energia del dia.
111. Crear paquete autoconocimiento.
112. Crear paquete bienestar e integracion.
113. Separar inventario premium de AdSense.
114. Mantener AdSense como remanente.
115. Mantener Auto Ads activo por defecto durante revision de AdSense.
116. No activar scripts comerciales nuevos.
117. Medir impresiones de CTAs comerciales.
118. Medir clics de CTAs comerciales.
119. Pasar `journey_stage="commercial"` en CTAs.
120. Pasar `ad_slot` especifico en CTAs.
121. No mezclar eventos comerciales con recirculacion editorial.
122. Mantener paginas `/publicidad` en todos los dominios.
123. Incluir dominio actual en cada pagina comercial.
124. Incluir cobertura completa del cluster.
125. Incluir oferta de paquetes cross-site.
126. Incluir propuesta para anunciantes contextuales.
127. Evitar formularios pesados.
128. Mantener contacto por email o enlace simple.
129. Mantener assets estaticos.
130. Mantener despliegue compatible con Firebase Hosting.
131. Regenerar paginas de signos de carta astral.
132. Regenerar paginas de horoscopo.
133. Regenerar paginas de compatibilidad cuando cambie shared.
134. Regenerar paginas de tarot cuando cambie shared.
135. Regenerar paginas de numerologia cuando cambie shared.
136. Validar chakras aunque sea estatico.
137. Parchear chakras manualmente cuando el generador no escriba.
138. Parchear carta home manualmente cuando no use generator comun.
139. Evitar refactor amplio de la home de carta.
140. Evitar reescribir herramientas interactivas completas.
141. Preservar calculadora de carta.
142. Preservar flujo de PDF/manual.
143. Preservar interpretacion de carta.
144. Preservar quiz de chakras.
145. Preservar visual y copy existente salvo recirculacion.
146. Anadir recirculacion a carta home.
147. Anadir tracking compartido a carta home.
148. Anadir meditacion-chakras al mapa de carta home.
149. Anadir linker completo a carta home.
150. Anadir impresiones comerciales a carta home.
151. Anadir click result-aware a carta home.
152. Anadir contador local a carta home.
153. Anadir deduplicacion de completions a carta home.
154. Anadir recirculacion a chakras home.
155. Anadir tracking compartido equivalente a chakras.
156. Anadir eventos de resultado en chakras.
157. Anadir `tool_complete` en final de chakras.
158. Anadir `tool_complete` en inicio de plan chakras.
159. Anadir impresiones comerciales en chakras.
160. Anadir click result-aware en chakras.
161. Corregir slot de impresion comercial en chakras.
162. Mantener eventos especificos existentes.
163. Mantener `chart_calculated`.
164. Mantener `interpretation_generated`.
165. Mantener `compatibility_view`.
166. Mantener `tarot_reading_complete`.
167. Mantener `numerology_calculated`.
168. Usar `tool_complete` como evento agregable.
169. No eliminar eventos historicos.
170. Crear dimensiones GA4 para campos nuevos.
171. Crear key event para `tool_complete`.
172. Crear key event para `result_to_next_tool_click`.
173. Crear key event para `cluster_recirculation_impression`.
174. Crear key event para `advertiser_cta_impression`.
175. Mantener key event para `advertiser_cta_click`.
176. Documentar KPIs cluster.
177. Documentar `cluster_recirc_rate`.
178. Documentar `cluster_depth`.
179. Documentar `tool_completion_rate`.
180. Documentar `result_to_next_tool_ctr`.
181. Documentar `dead_end_pages`.
182. Documentar `commercial_cta_ctr`.
183. Documentar `seo_entry_to_cluster_depth`.
184. Documentar `revenue_per_cluster_session`.
185. Usar GSC por dominio.
186. Evaluar GSC como portfolio.
187. Priorizar landings con trafico y baja recirculacion.
188. Priorizar queries con intencion compatible con otra herramienta.
189. No forzar enlaces donde rompen intencion.
190. No canibalizar keywords entre dominios.
191. Mantener cluster como red de herramientas complementarias.
192. Distinguir landing SEO de herramienta principal.
193. Distinguir contenido evergreen de resultados.
194. Distinguir publicidad de contenido editorial.
195. Medir entrada SEO por hostname.
196. Medir salida a destino por hostname.
197. Medir profundidad sin user ID.
198. Evitar fingerprints.
199. Evitar parametros personales.
200. Evitar guardar fecha de nacimiento o nombres.
201. Evitar enviar ciudad exacta salvo evento existente controlado.
202. Preferir categorias o slugs.
203. Mantener coste runtime cero.
204. Mantener dependencias nuevas en cero.
205. Mantener checks shell simples.
206. Crear `scripts/check-cluster-recirculation.sh`.
207. Verificar index por site.
208. Verificar publicidad por site.
209. Verificar sitemap por site.
210. Verificar ads.txt por site.
211. Verificar linker GA4 por site.
212. Verificar `cluster_session_id` por site.
213. Verificar `data-destination-site` por site.
214. Verificar evento de impresion por site.
215. Verificar evento de click de resultado por site.
216. Verificar copy de paquetes comerciales.
217. Verificar publisher AdSense.
218. Verificar dimensiones GA4.
219. Verificar key events GA4.
220. Validar JSON de manifests.
221. Ejecutar `git diff --check`.
222. Mantener script sin llamadas de red.
223. Mantener script apto para CI free-tier.
224. Mantener checks deterministas.
225. Evitar Lighthouse en cada push.
226. Evitar Playwright obligatorio para este cambio estatico.
227. Evitar cron pesado.
228. Recomendar reporting semanal.
229. Mantener deploy manual/simple.
230. Mantener cambios reversibles.
231. Evitar migraciones de datos.
232. Evitar cambios DNS.
233. Evitar cambios en Firebase projects.
234. Evitar cambios en Cloud Functions.
235. Evitar tocar APIs de carta.
236. Evitar tocar scraping o jobs externos.
237. Mantener visual cards con radio moderado.
238. Mantener layouts responsive.
239. Mantener textos compactos en cards.
240. Mantener CTA visible sin desplazar herramienta.
241. Mantener footer como navegacion secundaria.
242. Evitar cards dentro de cards nuevas.
243. No crear landing marketing nueva en home.
244. Mantener primera pantalla enfocada en herramienta.
245. Dejar recirculacion para despues del uso.
246. Usar copy post-resultado cuando aplique.
247. Usar copy de entrada cuando sea landing informativa.
248. Mantener `cluster-journey` como bloque reutilizable.
249. Mantener `suite-card` existente en carta para no refactorizar CSS.
250. Mantener compatibilidad con paginas ya indexadas.
251. No cambiar URLs existentes.
252. No cambiar slugs existentes.
253. No romper sitemaps existentes.
254. No cambiar estructura de assets.
255. No cambiar favicons.
256. No cambiar fuentes.
257. Mantener monetizacion Auto Ads activa por defecto y venta directa como opt-in.
258. No cambiar consent/opt-out.
259. Documentar guardrails free-tier.
260. Documentar matriz por site.
261. Documentar journeys.
262. Documentar KPIs.
263. Documentar orden operativo.
264. Tratar GA4 como analitica cluster-wide.
265. Tratar AdSense como monetizacion cluster-wide.
266. Tratar SEO como portfolio de intenciones.
267. Tratar publicidad directa como inventario agrupado.
268. Tratar checks como contrato de cluster.
269. Tratar generadores como fuente preferente.
270. Tratar paginas estaticas especiales como excepciones controladas.
271. Regenerar artefactos despues de tocar shared.
272. Validar antes de commit.
273. Hacer commit atomico.
274. Push a remoto.
275. Deploy a produccion.

## Matriz Por Site

| Site | Rol en cluster | Primario | Secundario 1 | Secundario 2 |
| --- | --- | --- | --- | --- |
| `carta-astral` | Profundidad personal | `compatibilidad-signos` | `calcular-numerologia` | `meditacion-chakras` |
| `compatibilidad-signos` | Amor y pareja | `carta-astral` | `tarot-del-dia` | `meditacion-chakras` |
| `tarot-del-dia` | Inmediatez y decision | `meditacion-chakras` | `horoscopo-de-hoy` | `carta-astral` |
| `calcular-numerologia` | Identidad simbolica | `carta-astral` | `meditacion-chakras` | `horoscopo-de-hoy` |
| `horoscopo-de-hoy` | Recurrencia diaria | `tarot-del-dia` | `meditacion-chakras` | `carta-astral` |
| `meditacion-chakras` | Integracion practica | `carta-astral` | `horoscopo-de-hoy` | `tarot-del-dia` |

## KPIs

- `cluster_recirc_rate`: sesiones con salto entre dominios del cluster.
- `cluster_depth`: herramientas vistas por sesion.
- `tool_completion_rate`: finalizaciones por herramienta.
- `result_to_next_tool_ctr`: clicks desde resultado hacia otra herramienta.
- `dead_end_pages`: landings con trafico y sin clics internos.
- `commercial_cta_ctr`: clicks comerciales por impresion.
- `seo_entry_to_cluster_depth`: profundidad de cluster por landing SEO.
- `revenue_per_cluster_session`: ingresos estimados por sesion de cluster.

## Guardrails Free-Tier

- No introducir backend para recomendaciones.
- No introducir base de datos ni login.
- No usar A/B testing de terceros.
- No activar scripts comerciales nuevos sin motivo medible.
- No ejecutar Lighthouse en cada push.
- Mantener deploy selectivo por site y smoke checks baratos.
- Preferir informes semanales en GitHub Actions a dashboards pesados.

## Orden Operativo

1. Instrumentacion comun.
2. Bloques contextuales.
3. Regeneracion estatica.
4. Smoke SEO y checks de analytics.
5. Reporte semanal agregado.
6. Optimizacion de copy por datos.
7. Monetizacion directa por paquetes de cluster.

Este documento es la referencia para aplicar los 275 fixes: los fixes individuales se agrupan en medicion, UX de recirculacion, SEO, monetizacion, checks free-tier y gobernanza.
