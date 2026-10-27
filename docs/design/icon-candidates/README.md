# NASA Exp — candidatos de ícono

**1. Horizonte:** disco planetario con luz rasante cian y un pequeño amanecer ámbar; evoca exploración y escala cósmica.
Impacto: una curva luminosa amplia define una silueta única incluso a 60 px, con contraste blanco/cian sobre azul profundo.

**2. Ocular:** lente frontal de telescopio, vidrio cian y destello blanco integrado; representa el observatorio como instrumento.
Impacto: el volumen del aro y los reflejos grandes aportan brillo y profundidad; la óptica circular conserva su identidad al reducirse.

**3. Órbita:** trayectoria gruesa inclinada con un cuerpo luminoso ámbar; una marca de navegación espacial en movimiento.
Impacto: la diagonal y el contraste cálido/frío generan la silueta más directa de las tres; el trazo abierto se reconoce a 60 px.

## Archivos

| Concepto | PNG 1024 × 1024 | Preview | Fuente editable |
| --- | --- | --- | --- |
| Horizonte | [1-horizonte.png](1-horizonte.png) | [1-horizonte-preview.png](1-horizonte-preview.png) | [1-horizonte-prompt.md](1-horizonte-prompt.md) |
| Ocular | [2-ocular.png](2-ocular.png) | [2-ocular-preview.png](2-ocular-preview.png) | [2-ocular-prompt.md](2-ocular-prompt.md) |
| Órbita | [3-orbita.png](3-orbita.png) | [3-orbita-preview.png](3-orbita-preview.png) | [3-orbita-prompt.md](3-orbita-prompt.md) |

Cada preview mide 440 × 300 píxeles: ícono de **60 × 60 a la izquierda** y **180 × 180 a la derecha**, ambos a escala 1:1, sobre el mismo fondo oscuro. Abrir al 100 % para comparar tamaños reales. La superelipse de las previews aproxima la máscara de iOS; los PNG de producción tienen esquinas rectas.

Generados con la herramienta integrada `imagegen`, con un prompt independiente por concepto y un ajuste posterior de encuadre. Los prompts incluyen las dos instrucciones para poder modificar el elegido; al ser generación estocástica, no reproducen píxeles idénticos. No contienen texto, logos, banderas ni fotografías de NASA. Las versiones dark/tinted quedan para derivar tras elegir el concepto.

## Exportación y verificación

[prepare.swift](prepare.swift) usa únicamente frameworks incluidos en macOS. Normaliza la salida del generador a sRGB de 8 bits sin alfa y produce las previews; no redibuja el arte. Para una nueva generación, ejecutar desde la raíz del repositorio, sustituyendo las rutas entre comillas:

```sh
swift docs/design/icon-candidates/prepare.swift export "/ruta/imagen-generada.png" "docs/design/icon-candidates/1-horizonte.png"
```

Comandos ejecutados para generar y validar las previews finales:

```sh
swift docs/design/icon-candidates/prepare.swift preview
swift docs/design/icon-candidates/prepare.swift verify
```

Resultado: los seis PNG pasan la comprobación de dimensiones, profundidad de 8 bits y tipo RGB sin alfa en el encabezado IHDR. Las tres previews se inspeccionaron visualmente a 60 y 180 px. La entrega solo agrega documentos y arte; no requiere compilar la app.
