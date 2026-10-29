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

The 6.9" set also covers the 6.5"/6.7" slots (App Store Connect scales it down). No iPad set:
the app ships iPhone-only.

To regenerate: build Debug for a 6.9" simulator, launch with `-initialTab <tab>`, use
`xcrun simctl status_bar <udid> override --time 9:41 --batteryLevel 100 --batteryState charged --cellularBars 4 --wifiBars 3`
and `xcrun simctl io <udid> screenshot <file>`.

## App Store Connect checklist (1.0, build 2)

- App Information: name `NASA Exp`, subtitle from `docs/app-metadata.md`, primary category
  Education, secondary Reference. Content rights: does not contain third-party content that
  needs licensing (NASA imagery is public domain; credits are kept in-app).
- Age Rating: answer "None" to every item → 4+.
- Pricing: Free, all territories.
- App Privacy: "Data Not Collected" (favorites and settings stay on the device, no analytics,
  no third-party SDKs). Privacy Policy URL from the table above.
- Version page: promotional text, description and keywords from `docs/app-metadata.md`;
  support URL; copyright `2026 nhsiciliano`; the eight screenshots; build 1.0 (2).
- App Review Information: contact details, no sign-in required, notes from the "Review Notes"
  section of `docs/app-metadata.md` (not an official NASA app, public NASA services, original
  icon, favorites local, no accounts).
- Version Release: manual release is the safer default for a first submission.
- Export compliance is already answered by `ITSAppUsesNonExemptEncryption = false` in Info.plist.
