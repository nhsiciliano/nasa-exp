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
- Deployment target en iOS 26.2, que excluye a casi toda la base instalada.

## P0 · Bloqueantes de release

| # | Tarea | Dificultad | Estado | Notas |
|---|---|---|---|---|
| P0.1 | Migrar Rovers a los feeds raw de `mars.nasa.gov` (Curiosity y Perseverance), navegación por sol, filtro por cámara y paginación | 🔴 Alto | Hecho | Spirit y Opportunity quedan fuera: no tienen feed vivo. Nuevo archivo `MarsRawImagesRequest.swift`. |
| P0.2 | Rotar la NASA API key expuesta y vaciarla en `Base.xcconfig`; cargar solo desde `Secrets.xcconfig` | 🟢 Bajo | Pendiente | La key actual está viva. Rotar en api.nasa.gov antes de cualquier build público. |
| P0.3 | Fallar el build de Release si `NASA_API_KEY` está vacía (script de build phase o `#error` en `NASAEnvironment`) | 🟢 Bajo | Pendiente | Evita publicar un binario que solo funcione con `DEMO_KEY`. |
| P0.4 | Quitar `api_key` de las URLs de imagen EPIC | 🟢 Bajo | Pendiente | `epic.gsfc.nasa.gov/archive` sirve sin key. Hoy la key viaja en cada ShareLink de EPIC. |
| P0.5 | Bajar `IPHONEOS_DEPLOYMENT_TARGET` a 17.0 y validar build | 🟢 Bajo | Pendiente | Todo lo usado (SwiftData, `safeAreaPadding`, `onChange` de dos parámetros) existe desde iOS 17. |
| P0.6 | `TARGETED_DEVICE_FAMILY = 1` y quitar orientaciones de iPad del Info.plist | 🟢 Bajo | Pendiente | La arquitectura define iPhone-first; evita review en iPad con layout no probado. |
| P0.7 | `ITSAppUsesNonExemptEncryption = false` y `PrivacyInfo.xcprivacy` sin tracking ni datos recolectados | 🟢 Bajo | Pendiente | Requisito de App Store Connect desde 2024. |
| P0.8 | Manejo de errores reales de NASA: 429 (rate limit), 403 (key inválida), sin conexión, con mensajes propios | 🟡 Medio | Pendiente | Un solo key es compartido por todos los usuarios; el 429 va a pasar. Agregar casos a `NASAAPIError` y tests. |

## P1 · Calidad y rendimiento antes de review

| # | Tarea | Dificultad | Estado | Notas |
|---|---|---|---|---|
| P1.1 | Configurar `URLCache.shared` con tamaño razonable (memoria 50 MB, disco 300 MB) al iniciar la app | 🟢 Bajo | Pendiente | `AsyncImage` usa el caché por defecto, muy chico para imágenes HD. |
| P1.2 | APOD home con `url`; reservar `hdurl` para pantalla completa | 🟢 Bajo | Pendiente | Reduce descargas de 10+ MB en la primera pantalla. |
| P1.3 | Grilla EPIC con thumbnails JPG (`/thumbs/`) y PNG completo solo en detalle | 🟢 Bajo | Pendiente | Verificado que existen. Pesan una fracción del PNG. |
| P1.4 | Marcar DTOs, `NASAClient`, modelos de dominio y repositorios como `nonisolated` | 🟡 Medio | Hecho | Build sin warnings de concurrencia. El decode de JSON ya no corre en el main actor. |
| P1.5 | Favoritos: persistir fecha original, sol, coordenadas y copyright (`FavoriteItem` con campos opcionales, migración liviana) | 🔴 Alto | Pendiente | Hoy la reconstrucción pierde fecha (rover/EPIC usan `.now`), coordenadas quedan en 0 y copyright en nil. Rovers ya guarda el sol dentro del subtítulo como paliativo. |
| P1.6 | Dynamic Type en `AppTypography` (`Font.custom(_:size:relativeTo:)`) | 🟢 Bajo | Pendiente | Requisito de accesibilidad y motivo frecuente de rechazo en review. |
| P1.7 | Corregir tildes en todo el copy ("Descripción", "cámara", "Crédito") y pasar formateadores de `es_ES` fijo a `Locale.current` | 🟢 Bajo | Pendiente | Rovers ya usa tildes. Falta APOD, EPIC, Favoritos y errores. |
| P1.8 | String Catalog con español como base e inglés como segundo idioma | 🟡 Medio | Pendiente | `LOCALIZATION_PREFERS_STRING_CATALOGS` ya está activo. Los `String` pasados a `ActionCapsule` e `InfoPill` necesitan `String(localized:)`. Los kickers "MISSION FEED" y "LIVE DATA" están hardcodeados. |
| P1.9 | Pull to refresh sin vaciar el contenido (estado `refreshing` o mantener `loaded` mientras llega la respuesta) | 🟢 Bajo | Pendiente | Hoy `refresh()` pone `.loading` y la pantalla parpadea. |
| P1.10 | Aviso "App no oficial, no afiliada a NASA" en la app y en la ficha; revisar que el ícono no use insignias de NASA | 🟢 Bajo | Pendiente | Riesgo de rechazo por guías 5.2.5 de Apple y guías de medios de NASA. |
| P1.11 | Eliminar `ContentView.swift` (no se usa) | 🟢 Bajo | Pendiente | |
| P1.12 | Smoke test de UI: abrir cada tab y un detalle | 🟡 Medio | Pendiente | Requiere target `nasa.expUITests`. El launch argument `-initialTab` ya existe para QA. |

## P2 · Funcionalidad 1.0 y 1.1

| # | Tarea | Dificultad | Estado | Versión |
|---|---|---|---|---|
| P2.1 | APOD: navegar por fecha (ayer, anterior, selector) y botón "aleatorio" | 🟡 Medio | Pendiente | 1.0 |
| P2.2 | APOD: compartir imagen con título y crédito, no solo la URL | 🟡 Medio | Pendiente | 1.0 |
| P2.3 | EPIC: carga inicial con `/EPIC/api/natural` (última fecha disponible) en vez de "hace 2 días" | 🟢 Bajo | Pendiente | 1.0 |
| P2.4 | EPIC: buscar automáticamente al cambiar la fecha | 🟢 Bajo | Pendiente | 1.0 |
| P2.5 | Rovers: carga automática de la siguiente página al llegar al final de la grilla | 🟢 Bajo | Pendiente | 1.0 |
| P2.6 | Rovers: pantalla completa con zoom para la foto | 🟡 Medio | Pendiente | 1.0 |
| P2.7 | Favoritos: filtro por tipo y borrar desde el detalle | 🟢 Bajo | Pendiente | 1.0 |
| P2.8 | Guardar imagen en Fotos con crédito (permiso `NSPhotoLibraryAddUsageDescription`) | 🟡 Medio | Pendiente | 1.0 |
| P2.9 | Widget de APOD (WidgetKit, timeline diaria) | 🔴 Alto | Pendiente | 1.1 |
| P2.10 | Visor embebido para APOD en video (YouTube/Vimeo vía WebView) | 🟡 Medio | Pendiente | 1.1 |
| P2.11 | Soporte iPad con layout adaptativo | 🔴 Alto | Pendiente | 1.1 |

## Infraestructura

| # | Tarea | Dificultad | Estado | Notas |
|---|---|---|---|---|
| I.1 | Compartir el scheme `nasa.exp` (`xcshareddata`) | 🟢 Bajo | Pendiente | Sin esto CI no puede compilar. |
| I.2 | GitHub Actions: build + test en cada PR sobre `macos-latest` | 🟡 Medio | Pendiente | Inyectar `NASA_API_KEY` como secret y generar `Secrets.xcconfig` en el job. |
| I.3 | Crash reporting sin dependencias: Xcode Organizer + MetricKit | 🟢 Bajo | Pendiente | Crashlytics o Sentry requieren decisión explícita (norma de no agregar dependencias). |
| I.4 | Tests nuevos: 429/403, migración de favoritos, formateadores por locale | 🟡 Medio | Pendiente | |
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
| low-dev | P0.3, P0.4, P0.5, P0.6, P0.7, P1.1, P1.3, P1.6, P1.11, I.1, I.3, P2.3, P2.4, P2.5 | P1.2, P1.7, P1.9, P2.7, I.5 |
| mid-dev | P0.8, P2.1, P2.2, P2.6, I.2 | P1.8, P1.12, P2.8, P2.10, I.4 |
| high-dev | P1.5 | P2.9, P2.11 |

## Decisiones tomadas

- 2026-10-21: Rovers se migra a `mars.nasa.gov` en vez de quitar el tab. Spirit y Opportunity salen del selector.
- 2026-10-21: la navegación de Rovers pasa de fecha terrestre a sol marciano, porque los feeds filtran por sol de forma nativa y el filtro por fecha no es confiable en Mars 2020.
