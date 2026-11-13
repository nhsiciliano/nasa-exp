# App Store submission kit

Everything App Store Connect asks for that is not in the build itself. Texts live in
`docs/app-metadata.md`; this folder holds the assets and the field-by-field checklist.

## URLs (GitHub Pages from `docs/` on `main`)

| Field | Value |
|---|---|
| Privacy Policy URL | https://nhsiciliano.github.io/nasa-exp/privacy-policy.html |
| Support URL | https://github.com/nhsiciliano/nasa-exp |
| Marketing URL (optional) | https://nhsiciliano.github.io/nasa-exp/ |

Pages is enabled on the repo (branch `main`, folder `/docs`, no Jekyll). Any change to
`docs/privacy-policy.html` goes live a minute after pushing `main`.

## Screenshots (`screenshots-6.9/`)

iPhone 6.9" display set, 1320 x 2868, captured on the iPhone 17 Pro Max simulator (iOS 27.0)
in dark mode with the status bar overridden to 9:41. Upload in this order:

1. `01-apod-home.jpg` — Hoy en NASA with the day's APOD
2. `02-apod-detail.jpg` — APOD detail with credit and explanation
3. `03-rover-detail.jpg` — Perseverance Mastcam-Z photo detail
4. `04-epic.jpg` — EPIC Earth images for a date
5. `05-widget.jpg` — APOD widget (medium) on the home screen
6. `06-favorites.jpg` — Favorites with an APOD and a rover photo
7. `07-rovers-grid.jpg` — Perseverance photo grid, sol 2023
8. `08-about.jpg` — About sheet: disclaimer, daily notification, sources

Since late 2026 App Store Connect's primary iPhone slot is "iPhone with Dynamic Island (medium
display)", which accepts 1206 x 2622 (6.1"/6.3") and is reused for every other iPhone size and
language. The 6.9" files were resized to 1206 x 2622 with `sips -z 2622 1206` and uploaded there
on 2026-10-30 (the aspect ratio differs by 0.1%, no visible distortion). No iPad set: the app
ships iPhone-only.

To regenerate: build Debug for a 6.9" simulator, launch with `-initialTab <tab>`, use
`xcrun simctl status_bar <udid> override --time 9:41 --batteryLevel 100 --batteryState charged --cellularBars 4 --wifiBars 3`
and `xcrun simctl io <udid> screenshot <file>`.

## Landing page (Marketing URL)

`docs/index.html` (English, x-default) and `docs/es/index.html` (Spanish) share
`docs/assets/site.css` and `docs/assets/site.js`; `docs/privacy-policy.html` loads the same
stylesheet. Hand-written HTML, no build step, relative paths only (Pages serves the site under
`/nasa-exp/`). Preview locally with `python3 -m http.server 8000 --directory docs`. Before
pushing, `grep -nE '(href|src)="/' docs/*.html docs/es/*.html` must print nothing.

Images in `docs/assets/img/`:

- `es/` from the 6.9" set above, except `rovers-grid`: the 6.9" one opens with two almost black
  thumbnails, so it was recaptured on the iPhone 17 (Perseverance, sol 2023, Mastcam-Z, scrolled
  to the colour row). `en/` recaptured in English on the iPhone 17 simulator (Debug build,
  `-AppleLanguages "(en)" -AppleLocale en_US -initialTab <tab>`, dark appearance, status bar at 9:41).
- The widget shot only exists in `es/` and both pages use it. Widgets follow the system language,
  not the app's launch arguments, so an English one needs the simulator itself in English
  (`simctl spawn <udid> defaults write -g AppleLanguages -array en-US` plus `AppleLocale en_US`,
  then reboot; restore `es-AR` / `es_AR` afterwards). On the iPhone 17 the widget renders in English,
  but its home page also shows other personal apps, so that capture was not used.
- Three widths per shot, always with `--out` and even heights (an AVIF with an odd height decodes as
  transparent in Chrome):

  ```bash
  # es: source 1320 x 2868. en: convert the simulator PNG to JPEG first (its alpha channel
  # also breaks the AVIF), then use the same loop.
  for wh in 440:956 660:1434 880:1912; do
    w=${wh%%:*}; h=${wh##*:}
    sips -s format jpeg -s formatOptions 72 -z $h $w SRC.jpg --out docs/assets/img/es/NAME-$w.jpg
    sips -s format avif -s formatOptions 60 -z $h $w SRC.jpg --out docs/assets/img/es/NAME-$w.avif
  done
  ```

- Icons from `docs/design/icon-candidates/final/3-orbita-final.png`: `sips -s format png -z N N`
  for `apple-touch-icon.png` (180), `favicon-32.png` (32) and `icon-128.png` (header and footer).
- `og-card-en.jpg` and `og-card-es.jpg` (1200 x 630) were made separately; do not regenerate them
  with `sips`.
- The hero is a plain `<img>` with AVIF only and an inline `onerror` that swaps in the 880 px JPEG.
  Inside `<picture>`, Safari on iOS also downloaded the `<img>` JPEG of the eager hero (199 KB extra).
  The other images stay in `<picture>` with JPEG fallback; they are lazy and are not fetched twice.

The App Store buttons (hero and closing band of both pages) are plain links to
`https://apps.apple.com/app/id6827700435`, which redirects to the visitor's storefront, and both
`<head>`s carry the Smart App Banner (`<meta name="apple-itunes-app" content="app-id=6827700435">`).
They went in on 2026-11-13, when the app was released; before that the buttons read "Coming soon".

## App Store Connect state (2026-10-30, updated 2026-11-13)

Filled in and saved: screenshots (8), promotional text, description, keywords, support and
marketing URLs, copyright, review contact, review notes, build 1.0 (3); App Privacy published as
"Data Not Collected" with the policy URL; price $0.00 in 175 countries, available everywhere;
name, subtitle, categories Education + Reference, age rating 4+, content rights.

Left for the user on 2026-10-30: the release option (then "automatic"; "manual" is the safer
default for a first launch), the Digital Services Act trader declaration under App Information >
"Reglamento de Servicios Digitales" (needed for EU availability), and the "Añadir a revisión" button.

Submitted by the user on 2026-10-30 at 14:26 with build 3 and automatic release. It stayed in
"Pendiente de revisión" for 12 days with no message from Apple.

2026-11-11: build 3 crashes when the daily notification is tapped with the app in the background
or not running (S.5 in `docs/production-plan.md`) and shows "Formato no soportado" for that day's
APOD (S.6). That submission was removed from review ("Eliminado"), build 4 was uploaded from Xcode
and selected in its place, the release option was changed to manual, and version 1.0 (4) was
submitted again at 16:30. Current state: "Pendiente de revisión". Once Apple approves it, the
version has to be released by hand from the version page.

Not checked on 2026-11-11: whether the Digital Services Act trader declaration has been completed.

2026-11-13: Apple approved version 1.0 (4) and the user released it by hand. The listing answers
at `https://apps.apple.com/app/id6827700435` (checked from the US storefront).

Pages: version `https://appstoreconnect.apple.com/apps/6827700435/distribution/ios/version/inflight`,
submissions and messages from Apple `.../apps/6827700435/distribution/reviewsubmissions`. To change
the build of a version that is waiting for review, remove it from review first (link in the banner
of the version page), swap the build under "Compilación", save, then "Añadir a revisión" and
"Enviar a revisión" in the draft panel; "Añadir a revisión" alone only creates a draft.

## App Store Connect checklist (1.0, build 4)

- App Information: name `NASA Exp`, subtitle from `docs/app-metadata.md`, primary category
  Education, secondary Reference. Content rights: does not contain third-party content that
  needs licensing (NASA imagery is public domain; credits are kept in-app).
- Age Rating: answer "None" to every item → 4+.
- Pricing: Free, all territories.
- App Privacy: "Data Not Collected" (favorites and settings stay on the device, no analytics,
  no third-party SDKs). Privacy Policy URL from the table above.
- Version page: promotional text, description and keywords from `docs/app-metadata.md`;
  support URL; copyright `2026 nhsiciliano`; the eight screenshots; build 1.0 (4).
- App Review Information: contact details, no sign-in required, notes from the "Review Notes"
  section of `docs/app-metadata.md` (not an official NASA app, public NASA services, original
  icon, favorites local, no accounts).
- Version Release: manual release is the safer default for a first submission.
- Export compliance is already answered by `ITSAppUsesNonExemptEncryption = false` in Info.plist.
