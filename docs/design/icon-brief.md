# Brief: tres candidatos de ícono para NASA Exp

Objetivo: un ícono con más impacto que el actual. El actual (`nasa.exp/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`) tiene un disco oscuro, un anillo cian fino, una cruz blanca y cian pequeña en el centro y un destello ámbar; a tamaño de home screen se ve vacío y apagado: elementos chicos, mucho fondo, poco contraste.

## Qué entregar

Tres conceptos distintos, no tres variantes del mismo. Para cada uno:

- `docs/design/icon-candidates/<n>-<nombre>.png`: 1024x1024, PNG, sin canal alfa, esquinas rectas (iOS aplica la máscara).
- `docs/design/icon-candidates/<n>-<nombre>-dark.png` y `-tinted.png` solo si el concepto lo necesita; si no, el planner las deriva.
- Una vista previa `docs/design/icon-candidates/<n>-<nombre>-preview.png` con el ícono a 60x60 y 180x180 sobre un fondo de home screen oscuro, para juzgar legibilidad a tamaño real.
- Dos líneas en `docs/design/icon-candidates/README.md` por concepto: idea y por qué tendría impacto.

## Dirección

- Identidad: observatorio sci-fi futurista. Paleta de la app: fondo azul muy oscuro (#070D1F aprox.), acento cian (#2EE6FF aprox.), blanco, ámbar cálido para detalles.
- Un solo motivo protagonista que ocupe el 60 a 75 % del lienzo. Sin texto.
- Legible a 60x60: siluetas grandes, pocos elementos, alto contraste contra el fondo.
- Ideas de partida, una por concepto: (1) un planeta o disco con luz rasante y un horizonte iluminado; (2) una lente u ocular de telescopio con destello; (3) un trazo orbital grueso con un cuerpo luminoso, estilo instrumento.
- Prohibido: el logo "meatball" o "worm" de la NASA, la bandera de EE. UU., fotos de la NASA, tipografía. Es una app no oficial.

## Cómo trabajar

- No tocar `nasa.exp.xcodeproj`, `Assets.xcassets` ni ninguna rama. Solo escribir en `docs/design/icon-candidates/`.
- Generar con la herramienta que tengas (SwiftUI render, Python/Pillow, SVG rasterizado, generador de imágenes). Dejar la fuente (SVG, script o prompt) junto al PNG para poder ajustar el elegido.
- Cuando estén los tres, avisar al planner con el nombre de cada archivo.
