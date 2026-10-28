# Arquitectura inicial - NASA Exp (iPhone)

## 1) Vision del producto

Construir una app nativa iOS (SwiftUI) visualmente atractiva para explorar y compartir contenido de la NASA usando `https://api.nasa.gov/`.

Objetivo principal:
- Transformar datos cientificos en una experiencia editorial y visual de alta calidad.

Objetivos de experiencia:
- Interfaz clara, moderna y emocional.
- Navegacion simple para uso diario.
- Rendimiento fluido y tiempos de carga percibidos bajos.
- Estados de error y vacio bien resueltos.

Alcance inicial de plataforma:
- **Solo iPhone** (decidido).
- iPad quedara para una fase posterior.

## 2) Alcance funcional (MVP)

### Modulos principales

1. **Hoy en NASA (APOD)**
   - Imagen o video del dia.
   - Titulo, fecha, autor y descripcion.
   - Vista de detalle con lectura comoda.
   - Accion de compartir.

2. **Rovers de Marte**
   - Feed de imagenes crudas de Curiosity y Perseverance.
   - Navegacion por sol marciano (anterior, siguiente, ultimo sol, entrada manual).
   - Filtro por camara y paginacion ("Cargar mas").
   - Vista de detalle con instrumento, mision, fecha terrestre y credito.
   - Spirit y Opportunity quedan fuera: su API fue discontinuada y no existe reemplazo.

3. **La Tierra (EPIC)**
   - Visualizacion por fecha.
   - Lista/galeria de imagenes EPIC.
   - Detalle de imagen con contexto.

4. **Favoritos**
   - Guardar y quitar contenido favorito.
   - Persistencia local para revisita rapida.

### Fuera de MVP (por ahora)

- Login/cuentas de usuario.
- Backend propio.
- Sincronizacion en la nube.
- Notificaciones push complejas.
- Soporte offline completo.

## 3) Arquitectura tecnica

### Stack

- UI: SwiftUI + NavigationStack + TabView.
- Networking: `URLSession` + `async/await`.
- Persistencia: SwiftData (favoritos y datos ligeros).
- Concurrencia: actualizaciones de UI en MainActor.

### Enfoque arquitectonico

- Arquitectura modular por feature.
- Capa de dominio simple y explicita.
- Separacion clara entre:
  - Presentacion (Views / ViewModels)
  - Datos remotos (API client)
  - Persistencia local (repositorio favoritos)
- Modelos DTO desacoplados de modelos de UI.

### Estructura de carpetas sugerida

```text
nasa.exp/
  App/
    AppRootView.swift
    AppRouter.swift
  Core/
    Networking/
      NASAClient.swift
      APIEndpoint.swift
      APIError.swift
      RequestBuilder.swift
    Persistence/
      FavoritesStore.swift
      SwiftDataModels.swift
    DesignSystem/
      Colors.swift
      Typography.swift
      Spacing.swift
      Components/
  Features/
    APOD/
      APODView.swift
      APODViewModel.swift
      APODModels.swift
      APODRepository.swift
    Rovers/
      RoversHomeView.swift
      RoverPhotoDetailView.swift
      RoversViewModel.swift
      RoversModels.swift
      RoversRepository.swift
      MarsRawImagesRequest.swift
    EPIC/
      EPICView.swift
      EPICViewModel.swift
      EPICModels.swift
      EPICRepository.swift
    Favorites/
      FavoritesView.swift
      FavoritesViewModel.swift
```

### Widget de APOD (`nasa.expWidget`)

- Extensión de WidgetKit embebida en la app (`den-mobile.nasaexp.widget`), tamaños small y medium, solo
  iPhone. Su Info.plist es `Config/WidgetInfo.plist`.
- No tiene red propia: compila los archivos de la app que lista el exception set de la carpeta `nasa.exp`
  en `project.pbxproj` (`Exceptions for "nasa.exp" folder in "nasa.expWidget" target`): `AppTab`, el design
  system, `NASAClient` y sus tipos, `HTMLText`, la fuente de APOD (`APODRepository`, `APODSource`, `APODDay`,
  `APODFeedParser`, `APODArchivePostDTO`, `APODHTMLExtractor`, `APODFeedCache`, `APODModels`) y
  `ImageDownsampler`, `APODPublicationSchedule` y `APODWidgetContent`. Si uno de esos archivos empieza a usar
  otro tipo de la app, hay que sumarlo al exception set o el target del widget deja de compilar.
- Sin API key: APOD sale de `science.nasa.gov`, así que el widget no lleva `NASA_API_KEY` en su plist ni la
  fase "Validate NASA API Key".
- Timeline: una entrada por día. `APODWidgetContentLoader` pide `fetchToday()`, baja la copia de pantalla
  de la imagen (`w=1280`, nunca `hdURL` ni el link del artículo) y la decodifica con `ImageDownsampler`
  (ImageIO) directo al tamaño del widget. En días de video usa el poster de la misma forma
  (`stillImageURL`) con un ícono de play; solo un video sin poster queda en el degradado. El crédito
  (`shareCredit`, "NASA" si no hay) se ve siempre debajo de la fecha. El próximo
  refresh es a las 00:15 de New York del día siguiente (`APODPublicationSchedule`); si la carga falla o
  la entrada todavía es la del día anterior, reintenta en una hora.
- Tocar el widget abre `nasaexp://apod`.
- Textos: catálogo propio `nasa.expWidget/Localizable.xcstrings` (español fuente, inglés traducido). El
  target tiene `SWIFT_EMIT_LOC_STRINGS = NO` para que Xcode no copie a ese catálogo los textos de los
  archivos compartidos, que el widget no muestra; las claves nuevas se agregan a mano
  (`extractionState: manual`).

### Deep links

- Esquema `nasaexp` registrado en `Config/Info.plist`: `nasaexp://<tab>` con los mismos nombres que
  `-initialTab` (`apod`, `rovers`, `epic`, `favorites`). `AppTab(url:)` lo parsea con
  `AppTab(launchArgument:)` y `AppRootView` cambia de pestaña en `onOpenURL`.
- Prueba manual: `xcrun simctl openurl "iPhone 17" nasaexp://apod`.

## 4) Integracion con API NASA

### Endpoints en uso

- APOD (hoy y últimos 30 días): `https://science.nasa.gov/feed/apod-basic/` (RSS "APOD Basic")
- APOD (archivo completo desde 1995): `https://science.nasa.gov/wp-json/wp/v2/image-article?categories=22766`
- EPIC: `https://api.nasa.gov/EPIC/api/natural/date/{date}`
- Rovers (Curiosity / MSL): `https://mars.nasa.gov/api/v1/raw_image_items/`
- Rovers (Perseverance / Mars 2020): `https://mars.nasa.gov/rss/api/?feed=raw_images&category=mars2020`

### Endpoints discontinuados

- `https://api.nasa.gov/mars-photos/...` dejo de existir (responde una pagina de Heroku "No such app").
  Verificado el 2026-10-21. No volver a usarlo.
- `https://api.nasa.gov/planetary/apod` quedó roto cuando APOD se mudó a `science.nasa.gov/apod/`:
  sin fecha responde HTTP 500 y con cualquier fecha devuelve el placeholder "NASA Science" con el logo
  de NASA. Verificado el 2026-10-21. No volver a usarlo; `NASAEndpoint` ya no tiene el case `.apod`.
- `https://apod.nasa.gov/apod/apYYMMDD.html` redirige a la home de `science.nasa.gov/apod/`, así que
  el link de un día no se puede derivar de la fecha: se guarda el link del artículo.

### Fuente de APOD (`science.nasa.gov`)

- No requiere API key. `APODRepository` usa el RSS para hoy y para los días que todavía lista,
  y la API de WordPress para fechas anteriores. Si el RSS falla, "hoy" sale del post más nuevo de la WP.
  El RSS se cachea en memoria 10 minutos (`APODFeedCache`).
- Días: el id de un APOD (`yyyy-MM-dd`) es el día calendario de America/New_York en que se publicó
  (00:05 hora del sitio), sin importar la zona horaria del dispositivo. En el RSS se convierte
  `pubDate` (UTC, 04:05Z) a New York; en la WP el campo `date` ya está en hora del sitio.
  `APODEntry.date` es ese día a medianoche local, que es lo que `APODViewModel` compara para
  calcular el tope de "hoy" (`APODDay` documenta el criterio).
- Filtro por día en la WP: `after` es exclusivo y los posts de archivo tienen hora 00:00, así que la
  ventana es `after={día-1}T23:59:59&before={día}T23:59:59`. Un día sin post (hay huecos en junio de
  1995) devuelve `[]` y se mapea a `NASAAPIError.notFound`.
- Video: el RSS no tiene `media_type` y trae `apod:hdurl` también en los videos (es el poster). Un día
  es video si su HTML (`content:encoded` en el RSS, `content.rendered` en la WP) tiene un `<iframe>`;
  se mapea a `.video(url)` con la URL https del embed. Los `.mp4` enlazados en la explicación no
  cuentan como video. El poster se usa como thumbnail.
- Compartir y guardar (R1.1): `APODEntry.stillImageURL` es la imagen de pantalla o, en días de video,
  el poster a `w=1280` (sale del thumbnail; los posters fuera del CDN quedan como vienen). Compartir
  manda ese JPEG con título, caption y crédito embebidos con `PhotoLibrarySaver.jpegData` (los mismos
  metadatos IPTC/TIFF que la copia en Fotos), y el mensaje `shareMessage`, que en video suma el link
  del artículo. Guardar en Fotos usa el original de la imagen o el poster. Un video sin poster
  comparte solo el link y no ofrece guardar.
- Imágenes: `assets.science.nasa.gov` redimensiona con `?w=&fit=clip` sin agrandar. En pantalla se usa
  `w=1280`, en pantalla completa el original sin query y en listas `w=480`. Las imágenes de archivo
  bajo `content/dam` ignoran el query y sirven el original. Si un post no tiene imagen destacada,
  la WP pone un placeholder genérico (`.../misc/news-thumbnail.png`); solo se aceptan imágenes bajo
  `/cds/apod/`, y si no hay, se usa el `<img>` del contenido.
- Texto: explicación y crédito vienen en HTML. `HTMLText` quita tags y decodifica entidades sin WebKit;
  `APODHTMLExtractor` saca el párrafo "Explanation:" (sin el "Tomorrow's picture:" final) y la
  fila de crédito, normalizando el label ("Credit & Copyright:", "Image Credit:", ...).
- URLs y criterios viven en `Features/APOD/APODSource.swift`, `APODDay.swift`, `APODFeedParser.swift`
  y `APODArchivePostDTO.swift`. Muestras reales: `docs/fixtures/apod-basic-sample.xml` y
  `docs/fixtures/apod-wp-sample.json`.

### Feeds de Rovers (`mars.nasa.gov`)

- No requieren API key.
- Filtro por sol: `condition_2={sol}:sol:gte&condition_3={sol}:sol:lte`.
- Filtro por camara: `search=INSTRUMENT_A|INSTRUMENT_B` (nombres exactos, sin prefijos).
- Paginacion: `page` (base 0) con `per_page` (MSL) o `num` (Mars 2020).
- Sin thumbnails: MSL usa `extended=thumbnail::sample_type::noteq`; Mars 2020 usa `extended=sample_type::full,`.
- El sol mas reciente se obtiene pidiendo una sola imagen con `order=sol desc`.
- La construccion de URLs vive en `Features/Rovers/MarsRawImagesRequest.swift`.

### Autenticacion

- EPIC usa API key en query param (`api_key`). APOD (`science.nasa.gov`) y Rovers (`mars.nasa.gov`) no.
- Configuracion por Build Settings / xcconfig.
- Nunca hardcodear la clave real en codigo fuente.
- `DEMO_KEY` solo para desarrollo temprano.

### Politicas de red

- Timeout razonable para requests.
- Manejo de errores HTTP y de conectividad.
- Retries limitados solo donde aporte UX.
- Parseo estricto y mensajes de error comprensibles.

## 5) Flujo de datos

1. La vista dispara accion del usuario (ej. seleccionar fecha).
2. El ViewModel solicita datos al repositorio.
3. El repositorio decide fuente (API o local).
4. El cliente de red ejecuta request y decodifica DTO.
5. Se mapea a modelo de dominio/UI.
6. El ViewModel publica estado para renderizar.
7. Favoritos se persisten con SwiftData.

Estados de pantalla estandarizados:
- `idle`
- `loading`
- `success`
- `empty`
- `error`

## 6) Diseno visual y UX (iPhone)

### Direccion visual

- Tema: observatorio espacial moderno.
- Base oscura profunda + acentos cian/ambar.
- Contraste alto y jerarquia tipografica clara.

### Componentes UI clave

- HeroCard para contenido destacado.
- InfoPill para metadatos (fecha, camara, rover).
- SectionHeader reusable.
- MediaViewer para imagen/video en detalle.

### Motion

- Entradas suaves por seccion.
- Transiciones entre lista y detalle.
- Efecto parallax sutil en elementos hero.

### Accesibilidad

- Dynamic Type.
- Labels de accesibilidad en controles y media.
- Contraste minimo AA.
- Zonas tactiles comodas para una mano.

## 7) Persistencia y favoritos

- Entidad local de favoritos con tipo de contenido (APOD/Rover/EPIC).
- Campos minimos: id remoto, titulo, fecha, URL media, thumbnail.
- Operaciones: guardar, eliminar, listar, verificar si es favorito.

## 8) Seguridad y configuracion

- API key fuera del repositorio (xcconfig local/gitignored cuando aplique).
- Variables por configuracion (Debug/Release).
- No registrar secretos en logs.

## 9) Rendimiento

- Carga perezosa en galerias/listas.
- Caché de imagenes aprovechando politicas del sistema.
- Reducir trabajo en main thread.
- Reutilizar componentes visuales para mantener consistencia y costo bajo.

## 10) Testing y calidad

### Estrategia de pruebas

- Crear target `nasa.expTests`.
- Priorizar unit tests para:
  - Decodificacion de respuestas API.
  - Mapeo DTO -> modelo de dominio.
  - Manejo de errores (HTTP, timeout, parsing).
- Agregar smoke UI tests en una fase posterior.

### Comandos de referencia

Usar preferentemente `xcodebuildmcp` para flujos de build/test/run.

Ejemplos:

```bash
xcodebuildmcp project-discovery list-schemes --project-path ./nasa.exp.xcodeproj
xcodebuildmcp simulator build --scheme nasa.exp --project-path ./nasa.exp.xcodeproj --simulator-name "iPhone 16"
xcodebuildmcp simulator test --scheme nasa.exp --project-path ./nasa.exp.xcodeproj --simulator-name "iPhone 16"
```

Para test unico (cuando exista target de tests), se mantendra tambien la estrategia `-only-testing` en xcodebuild tradicional como referencia operativa.

## 11) Roadmap de implementacion

### Fase 0 - Fundacion

- Reestructurar shell de app (tabs + navegacion).
- Definir Design System base.
- Implementar configuracion segura de API key.
- Crear cliente de red comun y manejo de errores.

### Fase 1 - APOD

- Integrar endpoint APOD.
- Construir pantalla principal "Hoy en NASA".
- Implementar detalle y compartir.

### Fase 2 - Rovers

- Integrar feeds raw de `mars.nasa.gov` (hecho el 2026-10-21).
- Filtros por rover/camara/sol con paginacion.
- Galeria + detalle con metadata.

### Fase 3 - EPIC + Favoritos

- Integrar endpoint EPIC por fecha.
- Crear flujo completo de favoritos con SwiftData.
- Unificar tarjetas y comportamiento de guardado.

### Fase 4 - Pulido

- Mejoras de accesibilidad y rendimiento.
- Tests de regresion clave.
- Refinamiento visual final para release MVP.

### Fase 5 - Salida a produccion

- El detalle de tareas, dificultad y estado vive en `docs/production-plan.md`.

## 12) Criterios de exito del MVP

- App estable en iPhone con APOD, Rovers, EPIC y Favoritos funcionando.
- Tiempo de primera carga percibido rapido en red normal.
- Errores de API manejados sin bloquear la experiencia.
- Identidad visual consistente y atractiva en todo el recorrido.
- Base tecnica lista para escalar a iPad y nuevas features.
