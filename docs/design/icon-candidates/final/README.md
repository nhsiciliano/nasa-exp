# Órbita — entrega final

Concepto 3 seleccionado: trazo cian con cuerpo ámbar, reforzado para lectura a 60 px. La edición parte del candidato original y conserva el óvalo inclinado, el extremo abierto y la esfera en el sector superior derecho. Objetivos del ajuste: trazo +25 % y diámetro de esfera +18 %; se realizó una pasada de precisión para controlar el aumento del generador.

Los porcentajes son objetivos aproximados de una edición generativa, no transformaciones vectoriales exactas. La inspección visual de las previews es la referencia para aprobar el peso final.

| Archivo | Formato y uso |
| --- | --- |
| [3-orbita-final.png](3-orbita-final.png) | 1024 × 1024, RGB de 8 bits, sin alfa, fondo sRGB `#070D1F`. |
| [3-orbita-dark.png](3-orbita-dark.png) | 1024 × 1024, RGBA de 8 bits, solo trazo y esfera; exterior y centro del óvalo transparentes. |
| [3-orbita-tinted.png](3-orbita-tinted.png) | 1024 × 1024, RGBA de 8 bits, grises claros/blanco sobre transparente; mismo alfa que dark. |
| [3-orbita-final-preview.png](3-orbita-final-preview.png) | 440 × 300, final a 60 × 60 y 180 × 180 sobre fondo oscuro. |
| [3-orbita-dark-tinted-preview.png](3-orbita-dark-tinted-preview.png) | 880 × 300, dark a la izquierda y tinted a la derecha; cada uno a 60 × 60 y 180 × 180 sobre negro. |
| [3-orbita-final-prompt.md](3-orbita-final-prompt.md) | Prompts editables y proceso de derivación. |
| [prepare.swift](prepare.swift) | Utilidad nativa de exportación, previews y verificación, sin dependencias externas. |

Abrir las previews al 100 % para evaluar el tamaño real. La máscara de las previews aproxima la superelipse de iOS; los entregables de 1024 conservan el lienzo cuadrado completo. Arte sin texto ni logos, producido con la herramienta integrada `imagegen`.

Las tres apariencias se derivan del mismo maestro transparente: la versión final se compone sobre azul profundo; tinted convierte su color a gris claro/blanco (190–255) conservando exactamente el alfa. Esto evita cambios de posición y silueta entre apariencias.

Comandos ejecutados desde la raíz del repositorio:

```sh
swift docs/design/icon-candidates/final/prepare.swift preview
swift docs/design/icon-candidates/final/prepare.swift verify
sips -g pixelWidth -g pixelHeight -g hasAlpha docs/design/icon-candidates/final/3-orbita-final.png docs/design/icon-candidates/final/3-orbita-dark.png docs/design/icon-candidates/final/3-orbita-tinted.png
```

Para reexportar el conjunto desde el propio dark versionado o desde un nuevo maestro transparente:

```sh
swift docs/design/icon-candidates/final/prepare.swift export docs/design/icon-candidates/final/3-orbita-dark.png
```

La verificación comprueba dimensiones, tipo RGB/RGBA en IHDR, transparencia efectiva fuera y dentro de la órbita, ausencia de color en tinted y coincidencia exacta de alfa entre dark/tinted. No modifica el proyecto Xcode ni los catálogos de assets.
