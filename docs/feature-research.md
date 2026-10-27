# Investigación de funciones para después de 1.0

Fecha: 2026-10-27. Base: `nhsiciliano/lead-dev` @ `4e6058a` (1.0 en TestFlight).

Objetivo: relevar integraciones de datos y funciones de plataforma iOS para 1.1 y siguientes, con cada fuente
verificada contra el servidor hoy y no de memoria.

## Método

- Todas las llamadas se hicieron con `curl` el 2026-10-27 entre las 23:11 y las 23:20 UTC, desde la red local de
  desarrollo. Los comandos están al final del documento.
- Para `api.nasa.gov` se usó `DEMO_KEY`, no la key de la app. Las cuotas reales con key se citan de la
  documentación y se marcan como tales.
- "Límites" distingue lo **observado hoy** (headers, endpoint de throttle) de lo **documentado** por el proveedor.
- La dificultad usa la escala de `docs/production-plan.md`: 🟢 Bajo, 🟡 Medio, 🔴 Alto. Según esa escala, integrar
  una fuente externa nueva es 🔴 por definición. Solo bajo a 🟡 una fuente nueva cuando entra en una pantalla
  existente, sin modelo persistido ni navegación nueva.
- Valor para el usuario: alto, medio o bajo, estimado por el encaje con lo que la app ya muestra (imágenes del
  espacio, día a día) y por la frecuencia de uso esperable.

## Resumen de la verificación

| Fuente | URL probada | Key | HTTP | Tamaño | Estado hoy |
|---|---|---|---|---|---|
| NASA Image and Video Library | `images-api.nasa.gov/search` | No | 200 | 11 006 B | Viva |
| NeoWs (asteroides) | `api.nasa.gov/neo/rest/v1/feed` | Sí | 200 | 13 084 B | Viva |
| DONKI (clima espacial) | `api.nasa.gov/DONKI/*` y `kauai.ccmc.gsfc.nasa.gov/DONKI/WS/get/*` | Sí / No | 503 / sin conexión | 91–114 B / 0 | **Caída** (4 intentos en api.nasa.gov, el origen no acepta conexiones) |
| NOAA SWPC (alternativa a DONKI) | `services.swpc.noaa.gov/products/*` | No | 200 | 4 871 B | Viva |
| EONET (eventos naturales) | `eonet.gsfc.nasa.gov/api/v3/events` | No | 200 | 8 367 B | Viva |
| GIBS (tiles de la Tierra) | `gibs.earthdata.nasa.gov/wmts/...` y `wvs.earthdata.nasa.gov/api/v1/snapshot` | No | 200 | 24 494 B / 79 663 B | Viva |
| Exoplanet Archive (IPAC) | `exoplanetarchive.ipac.caltech.edu/TAP/sync` | No | 200 | 56 216 B | Viva |
| NASA TechTransfer | `technology.nasa.gov/api/api/patent/{q}` | No | 200 | 43 763 B | Viva (el alias de `api.nasa.gov` redirige a una página HTML) |
| ISS, open-notify | `api.open-notify.org/iss-now.json` | No | 200 (solo HTTP) | 112 B | Responde, **pero desactualizada** (ver A7) |
| ISS, wheretheiss.at | `api.wheretheiss.at/v1/satellites/25544` | No | 200 | 309 B | Viva, TLE del 2026-10-26 |
| Webb y Hubble en NASA | `science.nasa.gov/mission/webb/feed/`, `webbtelescope.org/news/...`, `hubblesite.org/api/v3/images` | No | 200 tras redirigir a HTML | — | **Sin feed**: las tres terminan en páginas de `science.nasa.gov` |
| ESA/Webb y ESA/Hubble | `esawebb.org/images/feed/`, `esahubble.org/images/feed/` | No | 200 | 69 576 B / 74 146 B | Vivas, CC BY 4.0 |
| Mars 2020, otras cámaras | `mars.nasa.gov/rss/api/?feed=raw_images&category=mars2020` | No | 200 | 2–216 KB | Viva |
| Ingenuity | `mars.nasa.gov/rss/api/?feed=raw_images&category=ingenuity` | No | 200 | 2 279 B | Viva, archivo cerrado (última foto 2024-02-22) |
| Clima Perseverance (MEDA) | `mars.nasa.gov/rss/api/?feed=weather&category=mars2020` | No | 200 | 1 368 B | **Congelada** en el sol 1133 (2024-04-27) |
| Clima Curiosity (REMS) | `mars.nasa.gov/rss/api/?feed=weather&category=msl` | No | 200 | 1 730 689 B | Viva con atraso (último sol 4995, 2026-08-25) |
| InSight | `api.nasa.gov/insight_weather/` | Sí | 200 | 36 505 B | **Congelada** (soles 675–681, misión terminada) |
| Launch Library 2 (The Space Devs) | `ll.thespacedevs.com/2.3.0/launches/upcoming/` | No (tier gratis) | 200 | 3 535 B | Viva, 15 pedidos/hora |
| NASA breaking news RSS | `www.nasa.gov/news-release/feed/` y `www.nasa.gov/feed/` | No | 200 | 248 939 B | Viva |
| Feed general de NASA Science | `science.nasa.gov/feed/` | No | 200 | 165 921 B | **XML mal formado** (ver A12) |
| Re-chequeo de servicios muertos | `api.nasa.gov/mars-photos/...` y `api.nasa.gov/planetary/apod` | Sí | 404 / 500 | 555 B / 67 B | Siguen caídos: "No such app" y `{"code":500,"msg":"Internal Service Error"}` |

Dos datos transversales importan para casi todas las propuestas:

- **La key de `api.nasa.gov` es una sola para toda la base instalada.** Hoy la usa solo EPIC. La documentación de
  api.nasa.gov da 1 000 pedidos por hora por key. Cada fuente nueva sobre `api.nasa.gov` (NeoWs, DONKI) consume de
  esa misma cuota compartida y acerca el 429 que ya maneja P0.8. Las fuentes sin key no tienen este problema.
- **App Transport Security:** cualquier fuente que solo hable HTTP necesita una excepción de ATS en el Info.plist,
  y App Review pide justificarla. Hoy la app no tiene ninguna.

## Propuestas con fuente de datos nueva

### A1. Buscador de la NASA Image and Video Library

- **Qué vería el usuario:** una búsqueda ("Webb", "Artemis", "Saturno") con grilla de resultados, detalle con
  título, fecha, centro de NASA y descripción, y las mismas acciones que APOD: favorito, compartir y guardar en
  Fotos. Puede vivir como una sección de Favoritos/Explorar o como una pestaña nueva.
- **Fuente:** `https://images-api.nasa.gov/search?q=webb&media_type=image&page_size=5`. Los archivos de cada ítem
  están en `https://images-api.nasa.gov/asset/{nasa_id}` (`~orig`, `~large`, `~medium`, `~small`).
- **Key:** no.
- **Llamada de hoy:** 200, 11 006 B, `application/json`, 0,32 s. `collection.metadata.total_hits = 814`. Primer
  resultado: `nasa_id = PIA26703`, "Dark Matter Revealed in Webb, Hubble Observations", `date_created`
  2026-01-26. `asset/PIA26703` respondió 200 con 4 tamaños.
- **Límites:** no se observaron headers de rate limit y NASA no publica cuota para este servicio. Los links de
  `asset` vienen en `http://`, así que hay que reescribirlos a `https://` para no pedir excepción de ATS. El host
  lo soporta: `https://images-assets.nasa.gov/image/PIA26703/PIA26703~small.jpg` respondió 200, 14 732 B, JPEG.
- **Dificultad:** 🔴 Alto. Hay que crear el modelo y el repositorio, la búsqueda con paginación, un tipo nuevo de
  favorito (migración liviana, como P1.5) y estados vacío y error.
- **Valor:** alto. Es el catálogo de imágenes más grande de NASA y extiende la app más allá de "la foto del día".
- **Riesgos:** algunos ítems traen crédito de terceros en `photographer` o `secondary_creator`, que hay que mostrar
  como en APOD. Las pautas de medios de NASA prohíben sugerir respaldo de NASA, cosa que la app ya cumple
  (aviso de P1.10). No hay riesgo de discontinuación conocido: es el servicio que reemplazó a `images.nasa.gov`.

### A2. Asteroides cercanos (NeoWs)

- **Qué vería el usuario:** una tarjeta o lista "Pasan cerca hoy" con nombre, tamaño estimado, distancia en
  distancias lunares, velocidad y la marca de "potencialmente peligroso".
- **Fuente:** `https://api.nasa.gov/neo/rest/v1/feed?start_date=2026-10-27&end_date=2026-10-28&api_key=…`
- **Key:** sí, la de `api.nasa.gov`.
- **Llamada de hoy:** 200, 13 084 B, 1,14 s. `element_count = 11` para el 27 y el 28 de octubre. Primer objeto:
  `(2010 AL30)`, `is_potentially_hazardous_asteroid = false`, máximo acercamiento `2026-Oct-27 17:32` a
  147,96 distancias lunares.
- **Límites:** con `DEMO_KEY` el header informó `x-ratelimit-limit: 10`. Documentado: 1 000/h por key
  registrada, compartida por todos los usuarios.
- **Dificultad:** 🔴 Alto como pestaña o sección propia. Una tarjeta dentro de Hoy, sin favoritos, sería 🟡.
- **Valor:** medio. Es un dato curioso de consulta diaria, pero no tiene imágenes.
- **Riesgos:** consume la cuota compartida de la key. Hay que redactar "potencialmente peligroso" con cuidado para
  no alarmar, porque es una categoría orbital y no un riesgo de impacto.

### A3. Clima espacial (DONKI, con NOAA SWPC como alternativa)

- **Qué vería el usuario:** un estado del Sol del día (llamaradas, eyecciones de masa coronal, tormenta
  geomagnética) y, con SWPC, el índice Kp y la probabilidad de auroras.
- **Fuente DONKI:** `https://api.nasa.gov/DONKI/{FLR|CME|GST|notifications}?startDate=…&endDate=…&api_key=…` y su
  origen `https://kauai.ccmc.gsfc.nasa.gov/DONKI/WS/get/…`.
- **Llamada de hoy (DONKI):** 4 intentos sobre `api.nasa.gov` (FLR, notifications, CME, GST): todos **503**, con
  cuerpo `upstream connect error or disconnect/reset before headers … connection timeout`. El origen
  `kauai.ccmc.gsfc.nasa.gov` resuelve a `169.154.198.44` y rechaza la conexión en los puertos 443 y 80. La portada
  `ccmc.gsfc.nasa.gov` sí responde (200).
- **Fuente alternativa:** NOAA SWPC, `https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json`,
  `…/products/noaa-scales.json` y `…/json/ovation_aurora_latest.json`. No requiere key.
- **Llamada de hoy (SWPC):** Kp 200, 4 871 B, último registro `2026-10-27T18:00:00` con `Kp 2.0`. Escalas: 200,
  1 096 B, R/S/G en `0` ("none"). Aurora OVATION: 200, 919 070 B, `Observation Time 2026-10-27T23:02:00Z`,
  65 160 puntos.
- **Key:** DONKI sí (por `api.nasa.gov`), SWPC no.
- **Límites:** SWPC no publica cuota; sus productos se regeneran cada pocos minutos, así que alcanza con cachear.
- **Dificultad:** 🔴 Alto.
- **Valor:** medio. El pico de interés aparece cuando hay auroras, y se potenciaría con una notificación.
- **Riesgos:** DONKI está caído hoy en ambos hosts, así que no conviene construir sobre él hasta que vuelva y pase
  un tiempo estable. SWPC es NOAA y no NASA, lo que cambia el encuadre de "NASA Exp" (aunque es dominio público
  del gobierno de EE.UU.).

### A4. Eventos naturales en la Tierra (EONET + GIBS)

- **Qué vería el usuario:** un mapa o lista "La Tierra hoy" con incendios, tormentas, volcanes e icebergs activos.
  Cada evento abriría el tile satelital de ese día y ese lugar. Complementa EPIC.
- **Fuente EONET:** `https://eonet.gsfc.nasa.gov/api/v3/events?status=open&limit=5`
- **Fuente GIBS:**
  - tiles: `https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/MODIS_Terra_CorrectedReflectance_TrueColor/default/2026-10-26/GoogleMapsCompatible_Level9/2/1/1.jpg`
  - imagen recortada por bounding box: `https://wvs.earthdata.nasa.gov/api/v1/snapshot?REQUEST=GetSnapshot&TIME=2026-10-26&BBOX=-60,-80,-20,-30&CRS=EPSG:4326&LAYERS=VIIRS_SNPP_CorrectedReflectance_TrueColor&FORMAT=image/jpeg&WIDTH=512&HEIGHT=512`
- **Key:** no.
- **Llamada de hoy:**
  - EONET: 200, 8 367 B, 0,71 s. Primer evento: `EONET_25729` "Tropical Cyclone Arnab", categoría `severeStorms`,
    geometría desde `2026-10-25T18:00:00Z` con `magnitudeValue 35.00 kts`. EONET sirve JSON con
    `Content-Type: application/rss+xml`, así que no hay que validar el content type.
  - GIBS: tile 200, 24 494 B, JPEG. Snapshot 200, 79 663 B, JPEG. El capabilities WMTS respondió 200 (5,8 MB) e
    incluye las capas `MODIS_Terra|Aqua_CorrectedReflectance_TrueColor` y `VIIRS_SNPP_CorrectedReflectance_TrueColor`.
- **Límites:** EONET informó `X-RateLimit-Limit: 60` (sin ventana declarada). GIBS no publica cuota por usuario y
  sus tiles son cacheables.
- **Dificultad:** 🔴 Alto. Son dos fuentes nuevas, y el mapa con MapKit más un overlay de tiles se suma a la lista.
- **Valor:** medio a alto. Es visual y cambia todos los días.
- **Riesgos:** las imágenes del día actual pueden no estar completas en GIBS (por eso probé el día anterior), y los
  eventos sin coordenadas recientes requieren reglas para elegir la fecha del tile.

### A5. Exoplanetas (NASA Exoplanet Archive, IPAC)

- **Qué vería el usuario:** el contador de planetas confirmados, los descubiertos este año, y una ficha por planeta
  con estrella, distancia, método y telescopio.
- **Fuente:** `https://exoplanetarchive.ipac.caltech.edu/TAP/sync?query=select+pl_name,hostname,disc_year,disc_facility,sy_dist+from+ps+where+default_flag=1+and+disc_year=2026&format=json`
- **Key:** no.
- **Llamada de hoy:** 200, 56 216 B, 2,37 s, 361 planetas descubiertos en 2026. Primero: `HIP 54515 b`, Subaru
  Telescope, 82,81 pc. El conteo total con `default_flag=1` dio `6451`.
- **Límites:** IPAC no publica cuota. Las consultas TAP tardan de 2 a 3 s, así que conviene una consulta acotada y
  cacheada.
- **Dificultad:** 🔴 Alto.
- **Valor:** medio. El público es entusiasta, pero el contenido es sin imágenes salvo ilustraciones.
- **Riesgos:** ADQL armado en la URL (hay que escaparlo bien). Las columnas del archivo cambian de vez en cuando.

### A6. NASA TechTransfer (patentes y software)

- **Qué vería el usuario:** una búsqueda de patentes y software de NASA con resumen y centro.
- **Fuente:** `https://technology.nasa.gov/api/api/patent/engine`. El alias documentado
  `https://api.nasa.gov/techtransfer/patent/?engine&api_key=…` redirige hoy a `https://technology.nasa.gov/api/`, una
  página HTML.
- **Key:** no, sobre el host directo.
- **Llamada de hoy:** 200, 43 763 B, `count = 33`. Primer resultado: `LEW-TOPS-168`, "Next Generation "Closed
  Strayton" Engine Design". El título trae HTML embebido (`<span class="highlight">`).
- **Límites:** no publicados.
- **Dificultad:** 🔴 Alto.
- **Valor:** bajo para esta audiencia.
- **Riesgos:** el endpoint es un array posicional sin nombres de campo y con HTML. El alias de api.nasa.gov ya no
  funciona.

### A7. Posición de la ISS

- **Qué vería el usuario:** un mapa con la ISS en tiempo real (latitud, longitud, altura, velocidad, día/noche) y
  quién está a bordo.
- **Fuentes:**
  - `http://api.open-notify.org/iss-now.json` y `http://api.open-notify.org/astros.json`
  - `https://api.wheretheiss.at/v1/satellites/25544` y `…/25544/tles`
- **Key:** no.
- **Llamada de hoy:**
  - wheretheiss.at: 200, 309 B, `latitude 51.78`, `longitude 66.95`, `altitude 428.57 km`, `visibility eclipsed`,
    `timestamp 1793142733` (2026-10-27 23:12 UTC). Su TLE tiene época `26299.59614366` (2026-10-26), así que es
    actual.
  - open-notify: 200, 112 B, pero **solo por HTTP**: por HTTPS rechaza la conexión. Un segundo después informó
    `46.49, 33.40`, y en una segunda tanda `50.61, 50.76` contra `50.30, 86.31` de wheretheiss.at, unos 35° de
    longitud de diferencia. Además, `astros.json` lista una tripulación de 2024 (Kononenko, Chub, Dominick,
    Barratt, Epps, Wilmore…).
- **Límites:** hoy no se observaron headers de rate limit. Según su documentación, wheretheiss.at admite alrededor de
  1 pedido por segundo; no lo verifiqué hoy.
- **Dificultad:** 🔴 Alto con mapa en vivo; una tarjeta con la posición sería 🟡. Calcular **pasos visibles** sobre el
  usuario requiere propagar el TLE con SGP4 a mano, porque no se suman dependencias (AGENTS.md), y pedir la
  ubicación del usuario.
- **Valor:** medio. Es muy visual, aunque el "dónde está ahora" se mira una sola vez. Los pasos visibles valen más,
  pero cuestan mucho más.
- **Riesgos:** open-notify no sirve: está desactualizado y exige una excepción de ATS. wheretheiss.at es un servicio
  de terceros mantenido por una sola persona, sin SLA. Pedir la ubicación implica permiso nuevo y actualizar el
  manifiesto de privacidad.

### A8. Webb y Hubble

- **Qué vería el usuario:** una sección "Telescopios" con las últimas imágenes de Webb y Hubble y su descripción, al
  estilo de APOD.
- **Fuentes NASA probadas, todas sin feed hoy:**
  - `https://science.nasa.gov/mission/webb/feed/` → redirige a `https://science.nasa.gov/mission/webb/` (HTML).
  - `https://webbtelescope.org/news/news-releases` → redirige a `https://science.nasa.gov/mission/webb/latestnews/`
    (HTML).
  - `https://hubblesite.org/api/v3/images?page=1` → redirige a `https://science.nasa.gov/mission/hubble/` (HTML).
    La API v3 de HubbleSite está discontinuada.
  - La REST de WordPress de science.nasa.gov (`/wp-json/wp/v2/image-article?search=webb`) devolvió `[]`, y
    `search=hubble` solo devolvió un APOD.
- **Fuentes que sí funcionan:** `https://esawebb.org/images/feed/` y `https://esahubble.org/images/feed/` (RSS de la
  ESA), y la NASA Image Library de A1 con `q=webb` o `q=hubble`.
- **Key:** no.
- **Llamada de hoy:** ESA/Webb 200, 69 576 B, 25 ítems, último "Stars brewing in a nebulous cauldron"
  (`potm2610a`, 2026-10-22). ESA/Hubble 200, 74 146 B, 25 ítems, último "IRS 3 Field (NIRCam and MIRI image)"
  (`sci26006a`, 2026-10-12).
- **Límites:** no publicados.
- **Dificultad:** 🔴 Alto.
- **Valor:** alto. Son las imágenes más espectaculares disponibles hoy.
- **Riesgos:**
  - Licencia: las páginas `/copyright/` de ambos sitios dicen "Creative Commons Attribution 4.0 International
    license". El crédito ("ESA/Webb, NASA & CSA, …") es obligatorio en pantalla y al compartir o guardar.
  - La fuente es de la ESA y no de NASA; hay que mencionarla en "Acerca de".
  - Conviene evaluarla junto con A1: la Image Library ya trae Webb con fuente NASA y sin parser nuevo.

### A9. Mars 2020: más cámaras e Ingenuity

- **Qué vería el usuario:** en Rovers, más filtros de cámara para Perseverance (SHERLOC ACI, CacheCam, cámaras de
  EDL) y una galería del helicóptero Ingenuity como "rover" de archivo.
- **Fuente:**
  - `https://mars.nasa.gov/rss/api/?feed=raw_images&category=mars2020&feedtype=json&num=1&order=sol+desc&search=SHERLOC_ACI`
  - `…&category=ingenuity&feedtype=json&num=1`
- **Key:** no.
- **Llamada de hoy:**
  - SHERLOC_ACI: 10 190 fotos, la última del sol 2015 (2026-10-21).
  - CACHECAM: 4 249, sol 2018 (2026-10-24).
  - EDL_RUCAM: 4 122, sol 1950.
  - LCAM: 87, solo sol 0 (aterrizaje).
  - `category=ingenuity`: 200, 2 279 B, `total_results 14553`, última del sol 1069 (`HELI_NAV`, 2024-02-22).
  - `HELI_NAV` y `HELI_RTE` dentro de `category=mars2020` dan 0: Ingenuity solo existe en su propia categoría.
  - El feed general de Mars 2020 (100 fotos) respondió en 14,9 s.
  - El `|` del filtro de cámaras tiene que ir codificado (`%7C`); sin codificar, el servidor responde 400 HTML.
    `URLComponents` ya lo codifica.
- **Límites:** no publicados. El feed es lento con páginas grandes.
- **Dificultad:** 🟢 Bajo para sumar cámaras (son casos nuevos de `RoverCamera`). 🟡 Medio para Ingenuity (un
  `RoverName` nuevo sin sol vivo, decoder compartido con Mars 2020 y nuevo tipo de favorito).
- **Valor:** medio para las cámaras y medio para Ingenuity, que tiene una historia atractiva aunque el archivo esté
  cerrado.
- **Riesgos:** son pocos, porque es la misma fuente que ya usa la app. Ingenuity no recibe fotos nuevas desde
  2024-02-22 y hay que presentarlo como archivo.

### A10. Clima marciano

- **Qué vería el usuario:** una tarjeta "Hoy en Marte" con temperatura mínima y máxima, presión, estación, salida y
  puesta del sol.
- **Fuente:**
  - `https://mars.nasa.gov/rss/api/?feed=weather&category=mars2020&feedtype=json` (MEDA)
  - `https://mars.nasa.gov/rss/api/?feed=weather&category=msl&feedtype=json` (REMS de Curiosity)
  - `https://api.nasa.gov/insight_weather/?api_key=…&feedtype=json&ver=1.0`
- **Key:** MEDA y REMS no; InSight sí.
- **Llamada de hoy:**
  - MEDA: 200, 1 368 B, 7 soles, el último `sol 1133` del **2024-04-27** (min −79,3 °C, máx −24,7 °C). **No
    publica hace 2,5 años.**
  - REMS: 200, 1,73 MB (todo el historial: 4 745 soles), el más nuevo `sol 4995` del **2026-08-25** (min −71,
    máx −5, `atmo_opacity Sunny`). Lleva unos dos meses de atraso.
  - InSight: 200, 36 505 B, `sol_keys` 675–681. La misión terminó en 2022.
- **Límites:** no publicados. REMS siempre devuelve el historial completo (1,7 MB).
- **Dificultad:** 🟡 Medio, como tarjeta en Rovers con REMS.
- **Valor:** bajo con dos meses de atraso: el usuario espera "el clima de hoy".
- **Riesgos:** MEDA está congelado. REMS publica con un atraso variable y podría dejar de hacerlo.

### A11. Próximos lanzamientos (Launch Library 2, The Space Devs)

- **Qué vería el usuario:** una lista de próximos lanzamientos con cohete, misión, sitio, cuenta regresiva y estado
  (Go, TBD, demorado). Es la base natural para la Live Activity de B1.
- **Fuente:** `https://ll.thespacedevs.com/2.3.0/launches/upcoming/?limit=3&mode=list`. Para desarrollo existe
  `https://lldev.thespacedevs.com/…` (datos de prueba, sin límite estricto).
- **Key:** no para el tier gratis; hay token pago para más cuota.
- **Llamada de hoy:** 200, 3 535 B, `count = 475` lanzamientos próximos. Primeros: "Falcon 9 Block 5 | Starlink
  Group 15-16" (`net 2026-10-27T07:25:51Z`, estado `Success` aunque ya pasó), "Starlink Group 15-18"
  (2026-10-30T04:02Z, `Go`) y "GSLV Mk II | IRNSS-1L (NVS-03)" (2026-10-30T18:21Z, `Go`).
- **Límites, observados:** `https://ll.thespacedevs.com/2.3.0/api-throttle/` devolvió
  `{"your_request_limit":15,"limit_frequency_secs":3600,…}`, es decir 15 pedidos por hora por IP. Cada dispositivo
  tiene la suya, pero la app tiene que cachear.
- **Dificultad:** 🔴 Alto.
- **Valor:** alto. Es la consulta más pedida en apps espaciales y se presta a widget, notificación y Live Activity.
- **Riesgos:**
  - No es NASA: incluye SpaceX, ISRO y otros. Para mantener el foco habría que filtrar por agencia o aceptar el
    alcance.
  - Los términos de uso y la atribución que piden no se verificaron hoy; revisarlos antes de publicar.
  - `upcoming` incluye lanzamientos recién terminados, así que hay que filtrar por estado.

### A12. Noticias de NASA (RSS)

- **Qué vería el usuario:** una lista de últimas noticias de NASA con título, fecha e imagen, que abre el artículo
  en Safari View Controller.
- **Fuente:** `https://www.nasa.gov/news-release/feed/` (comunicados) y `https://www.nasa.gov/feed/` (todo).
- **Key:** no.
- **Llamada de hoy:** 200, 248 939 B, 10 ítems, `lastBuildDate` martes 27 oct 2026 21:01 UTC. Primero: "NASA
  Invites Media to Crew Completion of Yearlong Mars Simulation" (19:27 UTC).
- **Límites:** no publicados. El feed trae solo 10 ítems y no pagina.
- **Dificultad:** 🔴 Alto por la escala (fuente nueva), aunque es de las más chicas: parser RSS parecido al de APOD
  y sin favoritos.
- **Valor:** medio.
- **Riesgos:**
  - `https://science.nasa.gov/feed/` (el feed general de NASA Science) está **mal formado hoy**: en la línea 8 falta
    un espacio entre atributos (`xmlns:apod="https://science.nasa.gov/apod/"xmlns:media=…`), y un parser
    estricto como `XMLParser` lo rechaza. El feed `apod-basic` que usa la app sí es XML válido hoy.
  - Una app que solo muestra noticias enlazadas roza la guideline 4.2 (funcionalidad mínima), pero acá sería una
    sección más.
  - Alternativa no NASA: `https://api.spaceflightnewsapi.net/v4/articles/` (200, 36 676 artículos), con el mismo
    problema de foco que A11.

## Funciones de plataforma iOS sin fuente nueva

### B1. Live Activity de lanzamientos o de paso de la ISS

- **Qué vería el usuario:** en la pantalla bloqueada y la Dynamic Island, la cuenta regresiva del lanzamiento que
  sigue, o la del próximo paso de la ISS.
- **Fuente:** A11 (lanzamientos) o A7 con SGP4 (ISS). Sin servidor propio, ActivityKit solo actualiza desde la app.
  La cuenta regresiva corre sola con `Text(timerInterval:)`, pero una demora del lanzamiento no se reflejaría hasta
  que el usuario abra la app. Para actualizaciones push hace falta un backend con APNs, que hoy no existe.
- **Key:** la de la fuente.
- **Dificultad:** 🔴 Alto: target de extensión, `NSSupportsLiveActivities`, depende de A11 y, para actualizar en
  segundo plano, de un servidor.
- **Valor:** alto para quien sigue lanzamientos.
- **Riesgos:** App Review exige que las Live Activities sigan un evento en curso con fin definido, y un
  lanzamiento encaja. Sin push, el dato puede quedar viejo; `staleDate` lo mitiga.

### B2. App Intents y Siri Shortcuts

- **Qué vería el usuario:**
  - "Oye Siri, foto astronómica de hoy", con un snippet con imagen y título.
  - Acciones en Atajos: abrir una pestaña, obtener el APOD de una fecha, foto al azar.
  - El botón de acción y Spotlight muestran estas acciones.
- **Fuente:** las existentes (`APODRepository`, deep links `nasaexp://`).
- **Dificultad:** 🟡 Medio. `AppIntent` y `AppShortcutsProvider` en el target de la app (iOS 16+, compatible con el
  deployment target 17.0), frases localizadas en es/en y tests del intent con el repositorio stub.
- **Valor:** medio.
- **Riesgos:** son bajos. Las frases de Siri entran en el String Catalog y requieren revisión en los dos idiomas.

### B3. Spotlight de favoritos

- **Qué vería el usuario:** al buscar "Pilares" en Spotlight aparece el favorito con miniatura, y al tocarlo se
  abre en la app.
- **Fuente:** `FavoriteStore` (local).
- **Dificultad:** 🟡 Medio. Implica indexar con `CSSearchableItem` al agregar, quitar o migrar favoritos (toca el
  flujo de `Core/Persistence`), manejar `NSUserActivity`/`CSSearchableItemActionType` en `AppRootView` y abrir el
  detalle, lo que hoy necesita ruteo nuevo más allá de la pestaña.
- **Valor:** medio para quien guarda muchos favoritos.
- **Riesgos:** índice desincronizado si falla una escritura. Hay que borrar el índice al quitar el favorito.

### B4. Widgets de Rovers y EPIC

- **Qué vería el usuario:**
  - Rovers: la última foto de Perseverance o Curiosity con sol y cámara.
  - EPIC: la última Tierra completa, en small y medium.
  - Ambos con deep link a su pestaña.
- **Fuente:** las existentes. Rovers no requiere key. EPIC sí, y para el widget conviene `epic.gsfc.nasa.gov`, que
  sirve el JSON y las imágenes sin key, para no meter `NASA_API_KEY` en el widget (P2.9 lo evitó a propósito).
  `epic.gsfc.nasa.gov/archive/natural/...` ya funciona sin key (P0.4).
- **Llamada de hoy:** `https://epic.gsfc.nasa.gov/api/natural` respondió 200, 12 687 B, con 13 imágenes; la
  primera es `epic_1b_20261025010436`, del 2026-10-25 00:59:48.
- **Dificultad:** 🟡 Medio. La infraestructura de P2.9 se reutiliza: `ImageDownsampler`, timeline, catálogo propio
  y deep links. Hay que sumar archivos al exception set del widget, una timeline por fuente y tests del loader.
- **Valor:** alto. El widget de APOD ya existe y estos lo convierten en una familia; es una de las funciones más
  visibles en la home.
- **Riesgos:** el feed de Mars 2020 puede tardar 10–15 s con páginas grandes (A9), así que el widget debe pedir
  `num=1` y tolerar el timeout. Fijar una política de refresco (cada pocas horas) para no gastar presupuesto de
  WidgetKit.

### B5. Notificación diaria del APOD

- **Qué vería el usuario:** opt-in en Ajustes o Acerca de, y una notificación diaria a la hora local elegida
  ("Nueva foto astronómica: <título>") que abre `nasaexp://apod`.
- **Fuente:** la existente (RSS de `science.nasa.gov`). Sin servidor push, las opciones son:
  - Una notificación local repetida con texto genérico (fiable, sin título).
  - Un `BGAppRefreshTask` que trae el APOD y programa la notificación con título e imagen adjunta. iOS decide
    cuándo corre, así que puede llegar tarde o no llegar; conviene combinarlo con la notificación genérica como
    fallback.
- **Dificultad:** 🟡 Medio. Permiso contextual, preferencias, background task registrada en el Info.plist y tests
  del armado del contenido y de la reprogramación (`APODPublicationSchedule` ya calcula la publicación de las
  00:05 ET).
- **Valor:** alto. Es el hábito diario que sostiene la retención de una app de "foto del día".
- **Riesgos:** la guideline 4.5.4 prohíbe usar las notificaciones para marketing (esta no lo es) y exige que sean
  opt-in. Hay que actualizar `PrivacyInfo.xcprivacy` solo si se agregan APIs con motivo requerido (no es el caso).

### B6. Modo sin conexión con caché de imágenes

- **Qué vería el usuario:** los favoritos se ven completos sin red (imagen y texto) y la última pantalla de cada
  pestaña se muestra con un aviso "Sin conexión".
- **Fuente:** local. `URLCache` (P1.1, 300 MB en disco) ya cubre parte del caso, pero no garantiza que una imagen
  siga en caché.
- **Dificultad:** 🔴 Alto. Requiere guardar archivos de imagen por favorito (toca `Core/Persistence` y la
  migración), una política de limpieza y el estado offline en cada view model.
- **Valor:** medio. Sirve en viajes y en el subte, pero la app es mayormente de consumo en línea.
- **Riesgos:** espacio en disco (los HD de APOD pesan varios MB) y archivos huérfanos. Excluir esos archivos del
  backup de iCloud (`isExcludedFromBackup`).

### B7. Compartir con póster en días de video

- **Qué vería el usuario:** cuando el APOD es un video, compartir y guardar usan el póster (thumbnail) con título
  y crédito en vez de solo el enlace, y el widget muestra el póster en vez del degradado. Es el follow-up anotado
  en P2.9.
- **Fuente:** la existente. El RSS y WordPress ya entregan el poster (`APODSourceTests`
  `…_mapsIframeEntryToVideoWithPoster`) y los favoritos lo guardan como thumbnail.
- **Dificultad:** 🟢 Bajo a 🟡 Medio. El reparto propuesto es:
  - Compartir: 🟢, reusa `PhotoLibrarySaver` y el armado del texto.
  - Widget: 🟢, usa `.image` con el poster en vez de `.openInApp`, más un test del loader.
- **Valor:** medio. Hoy un día de video deja el widget sin imagen.
- **Riesgos:** los pósters de YouTube son de terceros, igual que el video, así que el crédito tiene que seguir
  visible.

### B8. Apple Watch

- **Qué vería el usuario:** el APOD del día en el reloj y una complicación con la foto.
- **Fuente:** la existente.
- **Dificultad:** 🔴 Alto. Implica un target watchOS nuevo, compartir el código de red y APOD (otro exception
  set), un design system para pantallas chicas y QA en un simulador más, con el protocolo del lock.
- **Valor:** bajo. Una foto astronómica en 45 mm luce poco.
- **Riesgos:** duplica el costo de QA y de review, y suma un segundo bundle a firmar en P1.17.

### B9. iPad (P2.11)

- **Qué vería el usuario:** layout adaptativo con sidebar y split view, grillas más anchas y detalle al costado.
- **Fuente:** la existente.
- **Dificultad:** 🔴 Alto, como ya figura en el plan.
- **Valor:** medio. Las imágenes lucen mucho mejor en pantalla grande, aunque la base iPad es menor.
- **Riesgos:** volver a `TARGETED_DEVICE_FAMILY = 1,2` expone la app a review en iPad (P0.6), con capturas
  obligatorias de iPad en App Store Connect.

## Ranking recomendado para 1.1

P2.11 (iPad) ya figura en el plan como 1.1, así que este ranking es de lo que se suma además de P2.11.

| # | Propuesta | Dificultad | Valor | Por qué ahora |
|---|---|---|---|---|
| 1 | B5. Notificación diaria del APOD | 🟡 | Alto | Crea el hábito diario, sin fuente ni servidor nuevo; reusa `APODPublicationSchedule`. |
| 2 | B4. Widgets de Rovers y EPIC | 🟡 | Alto | Reusa casi toda la infraestructura de P2.9; fuentes sin key; muy visible. |
| 3 | B7. Póster en días de video (compartir + widget) | 🟢 | Medio | Cierra el follow-up de P2.9; el dato ya está en el modelo. |
| 4 | A1. Buscador de la NASA Image and Video Library | 🔴 | Alto | La única fuente nueva NASA, sin key, viva y estable que amplía mucho el contenido; también cubre Webb y Hubble con fuente NASA. |
| 5 | B2. App Intents y Siri Shortcuts | 🟡 | Medio | Bajo riesgo, reusa repositorio y deep links; además aparece en Spotlight y el botón de acción. |

Siguen en la cola, para 1.2:

- A11 + B1: lanzamientos con Live Activity. Conviene primero decidir el foco no-NASA y, si se quiere actualizar
  la Live Activity en vivo, el backend de push.
- A4: EONET + GIBS ("La Tierra hoy").
- A9: más cámaras de Mars 2020 (🟢, se puede colar en 1.1 si sobra tiempo) e Ingenuity como archivo.
- B3: Spotlight de favoritos.
- A8: ESA/Webb y ESA/Hubble, solo si A1 no alcanza.
- A2: NeoWs, que cuesta cuota de la key compartida.
- B6: modo sin conexión.

## Descartadas o en pausa

| Propuesta / fuente | Motivo |
|---|---|
| open-notify (ISS) | Solo HTTP (exige excepción de ATS). La posición no coincide con wheretheiss.at (~35° de longitud) y `astros.json` lista la tripulación de 2024. Si se hace la ISS, va con wheretheiss.at. |
| DONKI (A3 con NASA) | Caído hoy en `api.nasa.gov` (503 en 4 endpoints) y en su origen CCMC (rechaza la conexión). Volver a probar más adelante; mientras tanto, NOAA SWPC si se quiere clima espacial. |
| Clima de Perseverance (MEDA) | Sin datos desde el 2024-04-27. |
| InSight weather | Misión terminada; devuelve siempre los soles 675–681. |
| Clima de Curiosity (REMS) como "clima de hoy" | Unos dos meses de atraso y respuesta de 1,7 MB; queda en pausa hasta que el atraso sea estable. |
| HubbleSite API v3, feed de Webb en science.nasa.gov, webbtelescope.org | Redirigen a páginas HTML de `science.nasa.gov`; no hay feed. |
| NASA TechTransfer (A6) | Valor bajo para la audiencia, formato posicional con HTML embebido, y el alias de api.nasa.gov ya no funciona. |
| Feed general `science.nasa.gov/feed/` | XML mal formado hoy; usar los feeds de `www.nasa.gov` si se hace A12. |
| Apple Watch (B8) | Costo alto (target, QA, firma) contra valor bajo. |
| `api.nasa.gov/mars-photos` y `api.nasa.gov/planetary/apod` | Siguen muertos (404 "No such app" y 500); no reintroducir. |

## Comandos usados

Helper del scratchpad, que guarda el cuerpo y los headers e imprime status, tamaño, content type, tiempo y URL
final:

```bash
curl -sS -L --max-time 40 -A "NASAExp-research/1.0 (curl)" -o "$name.body" -D "$name.headers" \
  -w '%{http_code} %{size_download} %{content_type} %{time_total}s %{url_effective}' "$url"
```

URLs probadas con ese helper:

```text
https://images-api.nasa.gov/search?q=webb&media_type=image&page_size=5
https://images-api.nasa.gov/asset/PIA26703
https://images-assets.nasa.gov/image/PIA26703/PIA26703~small.jpg
https://epic.gsfc.nasa.gov/api/natural
https://api.nasa.gov/neo/rest/v1/feed?start_date=2026-10-27&end_date=2026-10-28&api_key=DEMO_KEY
https://api.nasa.gov/DONKI/FLR?startDate=2026-10-01&endDate=2026-10-27&api_key=DEMO_KEY
https://api.nasa.gov/DONKI/notifications?startDate=2026-10-20&endDate=2026-10-27&type=all&api_key=DEMO_KEY
https://api.nasa.gov/DONKI/CME?startDate=2026-10-20&endDate=2026-10-27&api_key=DEMO_KEY
https://api.nasa.gov/DONKI/GST?startDate=2026-10-01&endDate=2026-10-27&api_key=DEMO_KEY
https://kauai.ccmc.gsfc.nasa.gov/DONKI/WS/get/FLR?startDate=2026-10-01&endDate=2026-10-27
https://kauai.ccmc.gsfc.nasa.gov/DONKI/WS/get/notifications?startDate=2026-10-20&endDate=2026-10-27&type=all
https://ccmc.gsfc.nasa.gov/
https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json
https://services.swpc.noaa.gov/products/noaa-scales.json
https://services.swpc.noaa.gov/json/ovation_aurora_latest.json
https://eonet.gsfc.nasa.gov/api/v3/events?status=open&limit=5
https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/MODIS_Terra_CorrectedReflectance_TrueColor/default/2026-10-26/GoogleMapsCompatible_Level9/2/1/1.jpg
https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/1.0.0/WMTSCapabilities.xml
https://wvs.earthdata.nasa.gov/api/v1/snapshot?REQUEST=GetSnapshot&TIME=2026-10-26&BBOX=-60,-80,-20,-30&CRS=EPSG:4326&LAYERS=VIIRS_SNPP_CorrectedReflectance_TrueColor&FORMAT=image/jpeg&WIDTH=512&HEIGHT=512
https://exoplanetarchive.ipac.caltech.edu/TAP/sync?query=select+pl_name,hostname,disc_year,disc_facility,sy_dist+from+ps+where+default_flag=1+and+disc_year=2026&format=json
https://exoplanetarchive.ipac.caltech.edu/TAP/sync?query=select+count(*)+as+n+from+ps+where+default_flag=1&format=json
https://api.nasa.gov/techtransfer/patent/?engine&api_key=DEMO_KEY
https://technology.nasa.gov/api/api/patent/engine
http://api.open-notify.org/iss-now.json
https://api.open-notify.org/iss-now.json
http://api.open-notify.org/astros.json
https://api.wheretheiss.at/v1/satellites/25544
https://api.wheretheiss.at/v1/satellites/25544/tles
https://science.nasa.gov/mission/webb/feed/
https://webbtelescope.org/news/news-releases
https://hubblesite.org/api/v3/images?page=1
https://science.nasa.gov/wp-json/wp/v2/image-article?search=webb&per_page=3&_fields=id,date,link,title
https://science.nasa.gov/wp-json/wp/v2/image-article?search=hubble&per_page=3&_fields=id,date,link,title
https://esawebb.org/images/feed/
https://esahubble.org/images/feed/
https://esawebb.org/copyright/
https://esahubble.org/copyright/
https://mars.nasa.gov/rss/api/?feed=raw_images&category=mars2020&feedtype=json&num=100&page=0&order=sol+desc&extended=sample_type::full,
https://mars.nasa.gov/rss/api/?feed=raw_images&category=mars2020&feedtype=json&num=1&page=0&order=sol+desc&search={SHERLOC_ACI|CACHECAM|EDL_RUCAM|LCAM|HELI_NAV|HELI_RTE}
https://mars.nasa.gov/rss/api/?feed=raw_images&category=mars2020&feedtype=json&num=5&page=0&order=sol+desc&search=%7CNAVCAM_LEFT%7CFRONT_HAZCAM_LEFT_A
https://mars.nasa.gov/rss/api/?feed=raw_images&category=ingenuity&feedtype=json&num=1
https://mars.nasa.gov/rss/api/?feed=weather&category=mars2020&feedtype=json
https://mars.nasa.gov/rss/api/?feed=weather&category=msl&feedtype=json
https://api.nasa.gov/insight_weather/?api_key=DEMO_KEY&feedtype=json&ver=1.0
https://ll.thespacedevs.com/2.3.0/launches/upcoming/?limit=3&mode=list
https://lldev.thespacedevs.com/2.3.0/launches/upcoming/?limit=3&mode=list
https://ll.thespacedevs.com/2.3.0/api-throttle/
https://api.spaceflightnewsapi.net/v4/articles/?limit=2
https://www.nasa.gov/news-release/feed/
https://www.nasa.gov/feed/
https://science.nasa.gov/feed/
https://science.nasa.gov/feed/apod-basic/
https://api.nasa.gov/mars-photos/api/v1/rovers/curiosity/latest_photos?api_key=DEMO_KEY
https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY
```

Además:

- `dig +short kauai.ccmc.gsfc.nasa.gov`.
- Dos tandas de `iss-now.json` y wheretheiss.at seguidas, para comparar las posiciones.
- Los campos de muestra se extrajeron de los cuerpos guardados con `python3 -I` (`json` y `xml.etree`).
