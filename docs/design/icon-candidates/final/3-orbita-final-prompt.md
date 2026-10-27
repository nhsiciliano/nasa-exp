# Órbita — fuente editable final

Herramienta: `imagegen` integrada. Imagen de entrada: [3-orbita.png](../3-orbita.png).
La edición produce el maestro RGBA; `prepare.swift` exporta el final opaco y las dos apariencias con silueta idéntica.

## Prompt de edición

Precise icon edit. This reference is 1024x1024. Keep the canvas and ALL object positions identical. Do NOT enlarge the whole icon. Do NOT zoom or change framing.
Make the cyan ribbon only 25% thicker locally, normal to its path: on horizontal row y=450, its left segment is 44px wide and should be about 55px; its right segment is 54px and should be about 67px. On row y=512 its left segment is 50px and should be about 62px. Keep the ribbon centerline and the same diagonal oval. Keep its open rounded lower-left end around x=330,y=710.
The amber sphere must stay centered at approximately x=736,y=328. Its SOLID diameter (excluding glow) is 128px in the reference. Make its SOLID diameter 151px, only 18% larger. Its center must NOT move. Keep the same lighting and colors.
The resulting orbit + sphere should still span roughly x=195 through x=815, not fill the canvas. Keep original scale and generous margins. The motif occupies roughly 60% of canvas width.
Remove the dark blue background including inside the oval. Output genuine transparent RGBA with background alpha=0 and solid ribbon/sphere alpha=255, with antialiased edges. Only a very restrained narrow glow. No noise, no navy haze, no matte, no speckled cutout, no checkerboard, no text or logos. Preserve the original polished cyan/blue sculptural ribbon and amber/white sphere, changing ONLY the modest local thickness and sphere size. Render only the one square icon, transparent background.

## Ajuste de precisión sobre el RGBA resultante

Precisely edit this transparent icon, keeping exact same canvas size, framing, orbit centerline, position, tilt, colors, shading and existing alpha background. This is a small REDUCTION pass: make the cyan ribbon 20% THINNER locally perpendicular to its curve (width multiplied by 0.80), symmetrically around the existing centerline. Make the solid amber sphere diameter 8% SMALLER (multiplied by 0.92), keeping its center fixed. Do NOT enlarge, reframe or recenter anything. Keep the overall size of the orbit and all empty margins unchanged. Maintain the open rounded tip and clean smooth edges. Preserve genuine transparency outside the shapes AND in the center of the oval; no dark background, no checkerboard, no new elements, no text or logos. The exact same existing image with only these two modest thickness/diameter reductions. Square RGBA transparent image.

## Exportación

El PNG dark conserva la transparencia del generador. El PNG final compone ese mismo arte sobre sRGB `#070D1F` sin alfa. Tinted conserva el alfa píxel a píxel y transforma el color a una luminancia entre 190 y 255 (gris claro a blanco), para evitar que el azul profundo produzca grises apagados. Las previews muestran cada apariencia a 60 × 60 y 180 × 180; dark/tinted sobre negro.
