# App Metadata Draft

## Product Identity

- App Name: NASA Exp
- Internal theme: futuristic sci-fi observatory
- Positioning: science-first NASA explorer for astronomy imagery, Mars rover observations, and Earth monitoring data

## App Store Metadata

### Subtitle

NASA imagery and mission data

### Promotional Text

Study NASA's daily astronomy image, review Mars rover photography, and examine Earth observations from orbit in a focused, science-driven mobile experience.

### Keywords

NASA,space,astronomy,Mars,rover,APOD,EPIC,Earth,cosmos,science

### Description

NASA Exp brings together public NASA imagery and observation data in a focused iPhone experience designed for scientific curiosity and visual exploration.

The app organizes several NASA data sources into clear, research-friendly sections:

- APOD: review NASA's Astronomy Picture of the Day with context, credits, and sharing
- Rovers: browse raw images from Curiosity and Perseverance by sol and camera, straight from NASA's mission feeds
- EPIC: examine Earth imagery captured from orbital observation platforms
- Favorites: save noteworthy images and revisit them later

NASA Exp is intended for users interested in astronomy, planetary science, and space exploration. Its visual language is futuristic, but the product emphasis remains on clarity, attribution, and reliable access to NASA imagery.

NASA Exp is not an official NASA app and is not affiliated with or endorsed by NASA. Images and data come from public NASA services (science.nasa.gov, mars.nasa.gov, api.nasa.gov) and keep their original credits.

## Visual Identity

### Icon direction

- Orbit design (chosen 2026-10-27 among three candidates, see `docs/design/icon-candidates/`)
- thick tilted cyan orbital stroke with an open end
- warm amber luminous body at the upper-right end of the orbit
- deep navy background (#070D1F); dark and tinted variants share the same alpha mask
- reads clearly at 60 pt and still feels premium at 1024x1024

### Launch screen direction

- deep space background, the same #070D1F as the icon so the glyph blends in
- centered Orbit glyph (`LaunchOrbit` imageset, opaque 1x/2x/3x from `docs/design/icon-candidates/final/3-orbita-final.png`)
- minimal text lockup: NASA EXP
- no busy UI or fake loading indicators
- the storyboard image must be opaque: a transparent PNG rendered blank in the launch screen (iOS 27 simulator, 2026-10-28)
- iOS caches the rendered launch screen per asset name; rename the imageset when the art changes, or users who update keep the old one

## Review Notes

- Uses NASA public services (science.nasa.gov for APOD, api.nasa.gov for EPIC, mars.nasa.gov raw image feeds for rovers)
- Not an official NASA app. The disclaimer is in the App Store description (last paragraph) and in the app under Favorites > info button (About screen, with version, sources and links)
- The app icon is original artwork (cyan orbital stroke with an amber body); it does not use the NASA "meatball" or "worm" logos, so no NASA branding permission is needed
- Favorites are stored locally on device
- No account required
- No user-generated content
- Educational/scientific reference content only
