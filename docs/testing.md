# Testing

El target `nasa.expTests` (XCTest) existe y corre en simulador.

## Comando

```bash
xcodebuild -project "nasa.exp.xcodeproj" \
  -scheme "nasa.exp" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
```

## Cobertura actual

### `NASAExpDecodingTests`

- `test_apodDecoding_mapsImageMediaCorrectly`
- `test_roversDecoding_mapsCuriosityRawImage` (feed MSL de `mars.nasa.gov`)
- `test_roversDecoding_mapsPerseveranceRawImage` (feed Mars 2020)
- `test_marsRawImagesRequest_buildsCuriosityURLWithSolAndCameraFilters`
- `test_marsRawImagesRequest_buildsPerseveranceURLWithoutCameraFilter`
- `test_epicDecoding_buildsArchiveImageURL`

### `NASAExpStoreAndViewModelTests`

- `test_favoriteStore_addContainsRemove_roundTrip` (SwiftData en memoria)
- `test_favoriteModels_reconstructNativeDetailsFromStoredFavorite`
- `test_apodViewModel_refresh_setsLoadedStateOnSuccess`
- `test_apodViewModel_refresh_setsFailedStateOnError`
- `test_roversViewModel_loadIfNeeded_jumpsToLatestSolAndLoadsFirstPage` (incluye `loadMore`)
- `test_roversViewModel_stepSol_clampsToLatestSol`
- `test_roversViewModel_search_setsFailedStateOnError`
- `test_epicViewModel_search_setsFailedStateOnError`

## Fixtures

Respuestas reales recortadas, utiles para tests y para documentar el contrato de cada feed:

- `docs/fixtures/apod-sample.json`
- `docs/fixtures/epic-sample.json`
- `docs/fixtures/rovers-msl-sample.json` (Curiosity, `raw_image_items`)
- `docs/fixtures/rovers-mars2020-sample.json` (Perseverance, `rss/api`)

## QA manual en simulador

Los builds Debug aceptan `-initialTab` para abrir una pestaña directamente:

```bash
xcrun simctl launch "iPhone 17" den-mobile.nasa-exp -initialTab rovers
xcrun simctl io "iPhone 17" screenshot rovers.png
```

## Pendientes

Ver `docs/production-plan.md`, items P1.12 (smoke test de UI) e I.4 (tests de errores 429/403, migracion de favoritos y formateadores por locale).
