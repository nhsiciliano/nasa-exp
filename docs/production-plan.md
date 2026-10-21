# Plan de producción - NASA Exp

Última actualización: 2026-10-21.

Escala de dificultad usada en todo el documento:

| Color | Nivel | Qué implica |
|---|---|---|
| 🟢 | Bajo | Cambio acotado, menos de medio día, sin riesgo de regresión |
| 🟡 | Medio | Toca varios archivos o una capa completa, entre medio día y dos días, requiere tests |
| 🔴 | Alto | Cambia contrato de datos, migraciones o integra una fuente externa nueva, más de dos días |

Estado: `Hecho`, `Pendiente`, `En curso`.

## Diagnóstico (2026-10-21)

- Build y suite de tests en verde (`xcodebuild test`, iPhone 17, Xcode 27.1).
- Arquitectura por feature, design system y estados de pantalla sólidos para un MVP.
- Se verificó contra la API real que `api.nasa.gov/mars-photos` ya no existe (responde HTML "No such app" de Heroku).
  La migración a los feeds de `mars.nasa.gov` ya está hecha (ver P0.1).
- Hay una API key real commiteada en `Config/Base.xcconfig` desde el commit `63ebd67`.
- Deployment target en iOS 26.2, que excluye a casi toda la base instalada. (Corregido a 17.0 en P0.5.)
- `api.nasa.gov/planetary/apod` también está roto (verificado el 2026-10-21): HTTP 500 sin fecha y un placeholder "NASA Science" con el logo de NASA para cualquier fecha. APOD se mudó a `science.nasa.gov/apod`, que expone un feed RSS (`/feed/apod-basic/`, 30 días, campos `apod:*`) y la REST de WordPress (`/wp-json/wp/v2/image-article?categories=22766`, archivo completo). Ver P0.9.

## P0 · Bloqueantes de release

| # | Tarea | Dificultad | Estado | Notas |
|---|---|---|---|---|
| P0.1 | Migrar Rovers a los feeds raw de `mars.nasa.gov` (Curiosity y Perseverance), navegación por sol, filtro por cámara y paginación | 🔴 Alto | Hecho | Spirit y Opportunity quedan fuera: no tienen feed vivo. Nuevo archivo `MarsRawImagesRequest.swift`. |
| P0.2 | Rotar la NASA API key expuesta y vaciarla en `Base.xcconfig`; cargar solo desde `Secrets.xcconfig` | 🟢 Bajo | Hecho | Key nueva en `Secrets.xcconfig` (gitignored), `Base.xcconfig` vacío. La key vieja sigue viva hasta que expire: NASA no permite revocar. |
| P0.3 | Fallar el build de Release si `NASA_API_KEY` está vacía (script de build phase o `#error` en `NASAEnvironment`) | 🟢 Bajo | Hecho | Build phase "Validate NASA API Key": Release falla con key vacía o placeholder. |
| P0.4 | Quitar `api_key` de las URLs de imagen EPIC | 🟢 Bajo | Hecho | `epic.gsfc.nasa.gov/archive` sirve sin key. Hoy la key viaja en cada ShareLink de EPIC. |
| P0.5 | Bajar `IPHONEOS_DEPLOYMENT_TARGET` a 17.0 y validar build | 🟢 Bajo | Hecho | Nada requirió iOS 18+. |
| P0.6 | `TARGETED_DEVICE_FAMILY = 1` y quitar orientaciones de iPad del Info.plist | 🟢 Bajo | Hecho | La arquitectura define iPhone-first; evita review en iPad con layout no probado. |
| P0.7 | `ITSAppUsesNonExemptEncryption = false` y `PrivacyInfo.xcprivacy` sin tracking ni datos recolectados | 🟢 Bajo | Hecho | `NSPrivacyAccessedAPITypes` vacío: el único UserDefaults es el launch arg de Debug. |
| P0.8 | Manejo de errores reales de NASA: 429 (rate limit), 403 (key inválida), sin conexión, con mensajes propios | 🟡 Medio | Hecho | `rateLimited(retryAfter:)`, `invalidAPIKey` (solo en api.nasa.gov) y `offline`. Tests con URLProtocol mock. |
| P0.9 | Migrar APOD a `science.nasa.gov` (RSS `apod-basic` para los últimos 30 días, REST de WordPress para archivo, fecha y aleatorio) manteniendo `APODRepositoryProtocol` y `APODEntry` | 🔴 Alto | Hecho | Sin API key. Ids por día America/New_York. Video por iframe. Cache del RSS de 10 min. Favoritos guardan media, HD, página y thumbnail. |

## P1 · Calidad y rendimiento antes de review

| # | Tarea | Dificultad | Estado | Notas |
|---|---|---|---|---|
| P1.1 | Configurar `URLCache.shared` con tamaño razonable (memoria 50 MB, disco 300 MB) al iniciar la app | 🟢 Bajo | Hecho | `AsyncImage` usa el caché por defecto, muy chico para imágenes HD. |
| P1.2 | APOD home con `url`; reservar `hdurl` para pantalla completa | 🟢 Bajo | Hecho | Reduce descargas de 10+ MB en la primera pantalla. |
| P1.3 | Grilla EPIC con thumbnails JPG (`/thumbs/`) y PNG completo solo en detalle | 🟢 Bajo | Hecho | Thumbnails también en la fila de Favoritos. |
| P1.4 | Marcar DTOs, `NASAClient`, modelos de dominio y repositorios como `nonisolated` | 🟡 Medio | Hecho | Build sin warnings de concurrencia. El decode de JSON ya no corre en el main actor. |
| P1.5 | Favoritos: persistir fecha original, sol, coordenadas y copyright (`FavoriteItem` con campos opcionales, migración liviana) | 🔴 Alto | Hecho | Campos opcionales nuevos en `FavoriteItem` (fecha, copyright, tipo de media, sol, instrumento, cámara, crédito, coordenadas, thumbnail). Migración liviana verificada con un store viejo en disco. Favoritos viejos siguen funcionando con fallback. |
| P1.6 | Dynamic Type en `AppTypography` (`Font.custom(_:size:relativeTo:)`) | 🟢 Bajo | Hecho | Requisito de accesibilidad y motivo frecuente de rechazo en review. |
| P1.7 | Corregir tildes en todo el copy ("Descripción", "cámara", "Crédito") y pasar formateadores de `es_ES` fijo a `Locale.current` | 🟢 Bajo | Hecho | Rovers ya usa tildes. Falta APOD, EPIC, Favoritos y errores. |
| P1.8 | String Catalog con español como base e inglés como segundo idioma | 🟡 Medio | Hecho | `Localizable.xcstrings` con 172 claves y traducción al inglés completa; `InfoPlist.xcstrings`; la acción Test corre en es/ES. |
| P1.9 | Pull to refresh sin vaciar el contenido (estado `refreshing` o mantener `loaded` mientras llega la respuesta) | 🟢 Bajo | Hecho | Hoy `refresh()` pone `.loading` y la pantalla parpadea. |
| P1.10 | Aviso "App no oficial, no afiliada a NASA" en la app y en la ficha; revisar que el ícono no use insignias de NASA | 🟢 Bajo | En curso | Riesgo de rechazo por guías 5.2.5 de Apple y guías de medios de NASA. |
| P1.11 | Eliminar `ContentView.swift` (no se usa) | 🟢 Bajo | Hecho | |
| P1.13 | Contraste del `DatePicker` en EPIC y de los controles de fecha de APOD sobre fondo oscuro | 🟢 Bajo | Hecho | APOD ya lo tenía; EPIC recibió tint, color de texto y esquema oscuro. Falta mirar el calendario emergente a mano. |
| P1.14 | Tab bar en apariencia clara: las etiquetas (Hoy, Rovers, Favoritos) se ven negras sobre el cristal oscuro | 🟢 Bajo | En curso | Reportado por low-dev. Forzar `.toolbarColorScheme(.dark, for: .tabBar)` ya está; revisar `preferredColorScheme(.dark)` a nivel app, dado que todo el design system es oscuro. Sin asignar. |
| P1.15 | Favoritos: formatear la fecha visible a partir de `originalDate` al mostrar, en vez del subtítulo guardado | 🟢 Bajo | Pendiente | Hoy una fecha guardada en español sigue en español al cambiar la app a inglés. Asignada a low-dev. |
| P1.16 | Favoritos: `FavoriteStore.add` hace upsert y completa los campos nuevos de favoritos viejos al volver a guardar o ver el ítem vivo | 🟡 Medio | Pendiente | Asignada a mid-dev. |
| P1.17 | Archive de Release en seco (`xcodebuild archive`) para detectar problemas que solo aparecen en Release antes de TestFlight | 🟡 Medio | Pendiente | Asignada a mid-dev. |
| P1.12 | Smoke test de UI: abrir cada tab y un detalle | 🟡 Medio | Hecho | Requiere target `nasa.expUITests`. El launch argument `-initialTab` ya existe para QA. |

## P2 · Funcionalidad 1.0 y 1.1

| # | Tarea | Dificultad | Estado | Versión |
|---|---|---|---|---|
| P2.1 | APOD: navegar por fecha (ayer, anterior, selector) y botón "aleatorio" | 🟡 Medio | Hecho | 1.0 |
| P2.2 | APOD: compartir imagen con título y crédito, no solo la URL | 🟡 Medio | Hecho | 1.0 |
| P2.3 | EPIC: carga inicial con `/EPIC/api/natural` (última fecha disponible) en vez de "hace 2 días" | 🟢 Bajo | Hecho | 1.0 |
| P2.4 | EPIC: buscar automáticamente al cambiar la fecha | 🟢 Bajo | Hecho | 1.0 |
| P2.5 | Rovers: carga automática de la siguiente página al llegar al final de la grilla | 🟢 Bajo | Hecho | 1.0 |
| P2.6 | Rovers: pantalla completa con zoom para la foto | 🟡 Medio | Hecho | 1.0 |
| P2.7 | Favoritos: filtro por tipo | 🟢 Bajo | Hecho | 1.0 |
| P2.8 | Guardar imagen en Fotos con crédito (permiso `NSPhotoLibraryAddUsageDescription`) | 🟡 Medio | Hecho | 1.0 |
| P2.9 | Widget de APOD (WidgetKit, timeline diaria) | 🔴 Alto | En curso | 1.1 (implementación estacionada en la rama `nhsiciliano/High-Dev-widget` @ 25b55c0, base anterior a P0.9, sin integrar por decisión del 2026-10-21. Para retomarla: el widget debe bajar la URL de media en vez de `shareURL`, sumar al exception set los archivos nuevos de APOD (APODDay, APODSource, APODFeedParser, APODArchivePostDTO, APODHTMLExtractor, APODFeedCache, Core/Text/HTMLText) y ya no necesita `NASA_API_KEY` ni la fase de validación) |
| P2.10 | Visor embebido para APOD en video (YouTube/Vimeo vía WebView) | 🟡 Medio | Hecho | 1.0 (YouTube vía youtube-nocookie, Vimeo; fallback al enlace) |
| P2.11 | Soporte iPad con layout adaptativo | 🔴 Alto | Pendiente | 1.1 |

## Infraestructura

| # | Tarea | Dificultad | Estado | Notas |
|---|---|---|---|---|
| I.1 | Compartir el scheme `nasa.exp` (`xcshareddata`) | 🟢 Bajo | Hecho | Sin esto CI no puede compilar. |
| I.2 | GitHub Actions: build + test en cada PR sobre `macos-latest` | 🟡 Medio | Hecho | `.github/workflows/ci.yml` con selección automática de simulador. Todavía no corrió en GitHub: depende de que `macos-latest` traiga Xcode 27. |
| I.3 | Crash reporting sin dependencias: Xcode Organizer + MetricKit | 🟢 Bajo | Hecho | `MetricKitReporter` guarda diagnostic payloads como JSON en Application Support. Sin red. |
| I.4 | Tests de formateo de fechas por locale (es/en) en APOD, EPIC y Rovers | 🟡 Medio | Hecho | `displayDate(locale:timeZone:)` en los tres modelos, `DisplayDateLocaleTests` en es_ES y en_US. El test del deep link queda con el widget. |
| I.5 | TestFlight interno con 3 a 5 testers y checklist de QA manual por pantalla | 🟢 Bajo | Pendiente | |

## Secuencia sugerida

| Semana | Entregable |
|---|---|
| 1 | P0 completo (P0.1 ya hecho), I.1, I.2 |
| 2 | P1 completo, I.3, I.4, primer build de TestFlight |
| 3 | P2 de 1.0, metadata y capturas, envío a review |

## Asignación por sesión (2026-10-21)

Reparto por dificultad: 🟢 a `low-dev`, 🟡 a `mid-dev`, 🔴 a `high-dev`. Cada sesión trabaja sobre archivos distintos para evitar pisarse.

| Sesión | Ola 1 | Ola 2 (cuando termine la ola 1) |
|---|---|---|
| low-dev | P0.3, P0.4, P0.5, P0.6, P0.7, P1.1, P1.3, P1.6, P1.11, I.1, I.3, P2.3, P2.4, P2.5 | P1.2, P1.7, P1.9, I.5 |
| mid-dev | P0.8, P2.1, P2.2, P2.6, I.2 | P1.8, P1.12, P2.8, P2.10, I.4 |
| high-dev | P1.5, P2.7 | P0.9, luego P2.9 (P2.11 queda para después de 1.0) |

## Estado de ramas (2026-10-21)

- `main` = `22e9057`: todo lo integrado hasta la ola 2 de low-dev, suite 57/57.
- `nhsiciliano/planner` = `d11131e`: `main` + P0.9, P1.13, P1.12, P2.10, P2.8, P1.8, I.4. Suite completa verde (84 unit tests, 3 UI tests). Pendiente de llevar a `main` cuando el usuario lo decida.
- 2026-10-21, tarde: `main` avanzó a `planner` (todo integrado). Ola 3 asignada: low-dev P1.10, P1.14, P1.15; mid-dev P1.16, P1.17; high-dev P2.9 (retomar el widget sobre la fuente nueva de APOD).

## Notas de integración

- `FavoriteItemDetailView.swift` era código muerto (Favoritos navega a los detalles nativos, que ya tienen "Quitar de favoritos"). Borrado el 2026-10-21.
- El detalle APOD reconstruido desde un favorito muestra la imagen estándar, no HD. Agregar la columna `hdurl` cuando entre P1.2.
- Favoritos guarda el subtítulo ya formateado: una fecha guardada con la app en español sigue en español al cambiar a inglés. Con `originalDate` (P1.5) se puede formatear al mostrar. Pendiente sin asignar.
- Los favoritos viejos no se completan al volver a ver el ítem vivo (`add` no hace upsert). Follow-up asignado a high-dev.

## Decisiones tomadas

- 2026-10-21: Rovers se migra a `mars.nasa.gov` en vez de quitar el tab. Spirit y Opportunity salen del selector.
- 2026-10-21: APOD se migra a science.nasa.gov (RSS + REST) porque api.nasa.gov devuelve placeholders. La API key de api.nasa.gov queda solo para EPIC.
- 2026-10-21: 1.0 sale solo para iPhone (`TARGETED_DEVICE_FAMILY = 1`). P2.11 (iPad) queda para después del release.
- 2026-10-21: la navegación de Rovers pasa de fecha terrestre a sol marciano, porque los feeds filtran por sol de forma nativa y el filtro por fecha no es confiable en Mars 2020.
