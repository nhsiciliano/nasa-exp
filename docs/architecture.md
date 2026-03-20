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
   - Feed de fotos por rover.
   - Filtros por rover, camara y fecha.
   - Vista de detalle con metadata tecnica.

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
      RoversView.swift
      RoversViewModel.swift
      RoversModels.swift
      RoversRepository.swift
    EPIC/
      EPICView.swift
      EPICViewModel.swift
      EPICModels.swift
      EPICRepository.swift
    Favorites/
      FavoritesView.swift
      FavoritesViewModel.swift
```

## 4) Integracion con API NASA

### Endpoints iniciales

- APOD: `/planetary/apod`
- Mars Rover Photos: `/mars-photos/api/v1/rovers/{rover}/photos`
- EPIC: `/EPIC/api/natural/date/{date}`

### Autenticacion

- Se usara API key en query param (`api_key`).
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

- Integrar endpoint de rovers.
- Filtros por rover/camara/fecha.
- Galeria + detalle con metadata.

### Fase 3 - EPIC + Favoritos

- Integrar endpoint EPIC por fecha.
- Crear flujo completo de favoritos con SwiftData.
- Unificar tarjetas y comportamiento de guardado.

### Fase 4 - Pulido

- Mejoras de accesibilidad y rendimiento.
- Tests de regresion clave.
- Refinamiento visual final para release MVP.

## 12) Criterios de exito del MVP

- App estable en iPhone con APOD, Rovers, EPIC y Favoritos funcionando.
- Tiempo de primera carga percibido rapido en red normal.
- Errores de API manejados sin bloquear la experiencia.
- Identidad visual consistente y atractiva en todo el recorrido.
- Base tecnica lista para escalar a iPad y nuevas features.
