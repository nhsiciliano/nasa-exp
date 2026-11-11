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

## App Store Connect state (2026-10-30, updated 2026-11-11)

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
