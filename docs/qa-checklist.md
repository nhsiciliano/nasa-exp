# Checklist de QA manual para TestFlight

Pasos para probar a mano cada build antes de enviarlo a testers. Probá en un iPhone real o en el simulador "iPhone 17", con conexión a internet salvo en la sección de red.

Registrá para cada ítem: ✅ ok, ❌ falla (con captura y pasos) o ➖ no aplica.

## 0. Antes de empezar

- [ ] Instalación limpia: borrá la app y volvé a instalar el build.
- [ ] La app abre sin crash y muestra la pestaña "Hoy".
- [ ] Hay 4 pestañas: Hoy, Rovers, Tierra y Favoritos.
- [ ] La app solo se usa en vertical (rotar el teléfono no cambia el layout).
- [ ] Idioma del dispositivo en español: los textos tienen tildes y las fechas se ven en español.
- [ ] Idioma del dispositivo en otro idioma: las fechas siguen el formato del dispositivo y nada se corta ni se rompe.

## 1. APOD (pestaña Hoy)

- [ ] Carga la imagen del día con título, fecha, créditos y descripción resumida.
- [ ] La imagen de la portada carga rápido (versión estándar, no la HD).
- [ ] "Día anterior" y "Día siguiente" cambian la fecha; "Día siguiente" se deshabilita en el último día.
- [ ] El selector de fecha permite elegir un día entre el 16-jun-1995 y hoy.
- [ ] "Fecha aleatoria" carga un APOD de otro día.
- [ ] Pull to refresh: el contenido actual queda visible mientras recarga y no parpadea.
- [ ] "Ver detalle completo" abre el detalle con la imagen, el crédito y la descripción completa.
- [ ] Tocar la imagen en el detalle abre la pantalla completa con la versión HD y se puede cerrar.
- [ ] Un día cuyo APOD es video muestra la tarjeta "Contenido en video" y el botón abre el navegador.
- [ ] Compartir desde la portada y desde el detalle abre la hoja de compartir con título, fecha y crédito.
- [ ] Guardar y quitar de favoritos desde el detalle actualiza el botón.

## 2. Rovers

- [ ] Carga Curiosity en el último sol disponible con fotos en la grilla.
- [ ] Cambiar a Perseverance carga su último sol y reinicia el filtro de cámara si no existe para ese rover.
- [ ] Los botones de sol anterior y siguiente cambian el sol; el siguiente se deshabilita en el último.
- [ ] El filtro por cámara muestra solo fotos de esa cámara.
- [ ] Al llegar a la última foto de la grilla se carga la siguiente página sola.
- [ ] El botón "Cargar más fotos" funciona como alternativa y desaparece cuando no hay más páginas.
- [ ] Pull to refresh mantiene las fotos visibles mientras recarga.
- [ ] Un sol sin fotos muestra el estado vacío con un mensaje claro.
- [ ] El detalle de una foto muestra imagen, cámara, sol, fecha y crédito; se puede compartir y guardar en favoritos.

## 3. EPIC (pestaña Tierra)

- [ ] Al abrir, carga la última fecha con imágenes disponible y el selector muestra esa fecha.
- [ ] La grilla muestra miniaturas livianas.
- [ ] Cambiar la fecha busca sola tras una breve pausa; "Buscar imágenes" sigue funcionando.
- [ ] Cambiar la fecha varias veces seguidas termina mostrando solo el resultado de la última.
- [ ] No se puede elegir una fecha futura.
- [ ] Una fecha sin imágenes muestra el estado vacío.
- [ ] Pull to refresh mantiene la grilla visible mientras recarga.
- [ ] El detalle muestra la imagen completa con fecha y coordenadas; se puede compartir y guardar en favoritos.
- [ ] La URL compartida no contiene ninguna API key.

## 4. Favoritos

- [ ] Sin favoritos se ve el estado vacío.
- [ ] Los favoritos de APOD, Rovers y EPIC aparecen con su miniatura, título y fecha original.
- [ ] El filtro por tipo muestra solo ese tipo; un tipo sin favoritos muestra su estado vacío.
- [ ] Abrir un favorito muestra el detalle nativo con la metadata guardada.
- [ ] Quitar un favorito lo saca de la lista.
- [ ] Los favoritos persisten al cerrar la app y volver a abrirla.
- [ ] Actualizar desde un build anterior conserva los favoritos ya guardados.

## 5. Errores de red

- [ ] Modo avión en cada pestaña: aparece un mensaje de falta de conexión y un botón "Reintentar" que funciona al volver la red.
- [ ] Con contenido ya cargado, recargar sin red muestra el error y se recupera al reintentar.
- [ ] Rate limit de NASA (429): el mensaje pide esperar y no deja la pantalla trabada.
- [ ] Una imagen que no carga muestra el estado de error de la tarjeta, sin pantalla en blanco.
- [ ] Cambiar de pestaña con una carga en curso no deja spinners colgados.

## 6. Dynamic Type

Ajustes › Accesibilidad › Pantalla y tamaño del texto › Texto más grande.

- [ ] Tamaño por defecto: todo se ve como en el diseño, sin cortes.
- [ ] Tamaño más grande y tamaños de accesibilidad: títulos, botones, pills y tarjetas crecen sin truncarse ni superponerse en las 4 pestañas.
- [ ] Los controles (selector de fecha, botones de sol, filtros) siguen siendo tocables.
- [ ] El texto en negrita y el contraste elevado no rompen ninguna pantalla.

## 7. VoiceOver básico

Ajustes › Accesibilidad › VoiceOver.

- [ ] Las 4 pestañas se anuncian con su nombre.
- [ ] Las imágenes y tarjetas tienen una etiqueta descriptiva y una pista de qué hacen al abrirse.
- [ ] Los botones de compartir, favoritos, anterior/siguiente y fecha aleatoria se anuncian con una acción clara.
- [ ] El orden de lectura va de arriba hacia abajo en cada pantalla.
- [ ] Se puede cerrar la pantalla completa con VoiceOver.

## 8. Cierre

- [ ] Sin crashes durante la sesión.
- [ ] Adjuntá capturas y pasos de cada ❌ al reporte del build.
