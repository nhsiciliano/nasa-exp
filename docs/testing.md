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

- `test_roversDecoding_mapsCuriosityRawImage` (feed MSL de `mars.nasa.gov`)
- `test_roversDecoding_mapsPerseveranceRawImage` (feed Mars 2020)
- `test_marsRawImagesRequest_buildsCuriosityURLWithSolAndCameraFilters`
- `test_marsRawImagesRequest_buildsPerseveranceURLWithoutCameraFilter`
- `test_epicDecoding_buildsArchiveImageURL`

### `NASAExpStoreAndViewModelTests`

- `test_favoriteStore_addContainsRemove_roundTrip` (SwiftData en memoria)
- `test_favoriteModels_legacyFavoritesWithoutMetadata_fallBackToStoredFields`
- `test_favoriteStore_roundTrip_preservesAPODMetadata` (incluye link del artículo, HD y thumbnail)
- `test_favoriteStore_roundTrip_apodPrefersStoredMediaKindOverURLHeuristic` (video con poster como thumbnail)
- `test_favoriteStore_roundTrip_preservesCuriosityMetadata`, `..._preservesPerseveranceMetadata`, `..._preservesEPICMetadata`
- `test_favoriteStore_lightweightMigration_opensStoreCreatedWithLegacySchema` (store en disco con el esquema viejo)
- `test_apodViewModel_refresh_setsLoadedStateOnSuccess`
- `test_apodViewModel_refresh_setsFailedStateOnError`
- `test_roversViewModel_loadIfNeeded_jumpsToLatestSolAndLoadsFirstPage` (incluye `loadMore`)
- `test_roversViewModel_stepSol_clampsToLatestSol`
- `test_roversViewModel_search_setsFailedStateOnError`
- `test_epicViewModel_search_setsFailedStateOnError`

### `NASAClientErrorTests` (`URLProtocol` mock)

- `test_fetch_whenStatusIs429WithRetryAfterSeconds_throwsRateLimitedWithDelay`
- `test_fetch_whenStatusIs429WithoutRetryAfter_throwsRateLimitedWithGenericMessage`
- `test_fetch_whenAPIKeyEndpointReturns403_throwsInvalidAPIKey`
- `test_fetch_whenKeylessFeedReturns403_throwsServerError`
- `test_fetch_whenNotConnectedToInternet_throwsOffline` (también `networkConnectionLost` y `timedOut`)
- `test_fetch_whenOtherURLError_throwsTransportError`
- `test_fetch_whenStatusIs500_throwsServerError`
- `test_retryAfterInterval_parsesSecondsAndHTTPDate`

### `APODViewModelTests`

- `test_loadIfNeeded_requestsTodayAndShowsLatest`
- `test_loadIfNeeded_whenNASATodayIsBehindLocalToday_usesNASADateAsLatest`
- `test_goToPreviousDay_thenNextDay_walksBackToLatest`
- `test_goToNextDay_whenShowingLatest_doesNothing`
- `test_load_clampsDatesOutsideTheArchive`
- `test_goToRandomDate_loadsDayAtInjectedOffsetWithinArchive`
- `test_load_whenRequestFails_showsErrorAndKeepsSelectedDate`

### `APODShareTextTests`

- `test_shareText_includesTitleDateAndCleanedCopyright`
- `test_shareText_whenCopyrightIsMissing_creditsNASA`

### `APODSourceTests` (APOD desde `science.nasa.gov`, fixtures reales + `URLProtocol` mock)

- RSS: `test_feedParser_readsRecordsNewestFirstWithEasternDayIDs`, `..._mapsImageEntryToPlainTextAndOriginalImage`,
  `..._dropsRepeatedExplanationLabelAndIgnoresLinkedVideoFiles`, `..._mapsIframeEntryToVideoWithPoster`
- WordPress: `test_archivePost_videoDay_mapsEmbedPosterAndCredit`, `..._oldEntry_stripsCreditLabelAndCleansText`,
  `..._withPlaceholderFeaturedImage_usesPageImage`
- Texto, días y URLs: `test_htmlText_dropsTagsDecodesEntitiesAndCollapsesWhitespace`,
  `test_extractor_stripsCreditLabelsAndTitlePrefix`, `test_apodDay_usesNewYorkCalendarDay`,
  `test_archivePostURL_coversWholeDayWithExclusiveAfterBound`, `test_imageURL_resizesOnlyCDNImages`
- Repositorio: `test_repositoryFetchToday_readsNewestFeedEntry`, `test_repositoryFetchDate_withinFeedWindow_reusesCachedFeed`,
  `test_repositoryFetchDate_olderThanFeed_queriesArchiveForThatDay`, `test_repositoryFetchDate_whenArchiveHasNoPost_throwsNotFound`,
  `test_repositoryFetchToday_whenFeedFails_fallsBackToNewestArchivePost`

### `APODVideoEmbedTests`

- `test_embedURL_keepsYouTubeEmbedQueryAndForcesInlinePlayback`
- `test_embedURL_convertsYouTubeWatchAndShortLinks`
- `test_embedURL_handlesVimeoPlayerAndPageLinks`
- `test_embedURL_whenHostIsNotSupported_returnsNil`

### `PhotoLibrarySaverTests`

- `test_jpegData_embedsTitleCaptionAndCreditMetadata` (IPTC título, caption y copyright; TIFF copyright)

### `NASAAPIErrorMessageTests`

- `test_rateLimitedMessage_switchesToHoursForLongWaits`

### `NASAExpSmokeUITests` (target `nasa.expUITests`, XCUITest)

- `test_eachTab_opensItsScreen`
- `test_roversTab_opensPhotoDetail`
- `test_epicTab_opensImageDetail`

Corren contra los feeds reales con el idioma fijado en español (`-AppleLanguages (es)`). Si un feed muestra su estado de error (por ejemplo el 429 de `DEMO_KEY`), el test de detalle se marca como skipped en vez de fallar. Para correr solo los unit tests, que son más rápidos: `-only-testing:nasa.expTests`.

## Idioma de los tests

La acción Test del scheme corre con idioma `es` y región `ES`, el idioma fuente de `Localizable.xcstrings`, así que los tests pueden comparar contra el texto en español. Para revisar la app en inglés: `xcrun simctl launch "iPhone 17" den-mobile.nasa-exp -AppleLanguages "(en)"`.

## Fixtures

Respuestas reales recortadas, utiles para tests y para documentar el contrato de cada feed.
`APODSourceTests` lee las de APOD desde `docs/fixtures` (ruta relativa a `#filePath`):

- `docs/fixtures/apod-basic-sample.xml` (RSS: imagen, imagen con `.mp4` enlazados en el texto y video con `<iframe>`;
  `content:encoded` recortado al `<title>` y al `<iframe>`)
- `docs/fixtures/apod-wp-sample.json` (WordPress: video de 2026, archivo de 2004 y 1995 con imagen destacada placeholder)
- `docs/fixtures/epic-sample.json`
- `docs/fixtures/rovers-msl-sample.json` (Curiosity, `raw_image_items`)
- `docs/fixtures/rovers-mars2020-sample.json` (Perseverance, `rss/api`)

## QA manual en simulador

Los builds Debug aceptan `-initialTab` para abrir una pestaña directamente:

```bash
xcrun simctl launch "iPhone 17" den-mobile.nasa-exp -initialTab rovers
xcrun simctl io "iPhone 17" screenshot rovers.png
```

## CI

`.github/workflows/ci.yml` corre en cada pull request y en cada push a `main`, sobre `macos-latest`:

1. Selecciona la versión estable más nueva de Xcode instalada en el runner (`xcode-select`).
2. Genera `Config/Secrets.xcconfig` con el secret `NASA_API_KEY` del repositorio. Si el secret no existe, usa `DEMO_KEY` y deja un warning en el job.
3. Elige simulador con `.github/scripts/select-simulator.py`: `iPhone 17` si existe, si no el iPhone de número más alto en el runtime de iOS más nuevo.
4. Corre `xcodebuild build test` en Debug con `CODE_SIGNING_ALLOWED=NO`.
5. Si algo falla, sube `build/TestResults.xcresult` como artifact (14 días). Se abre con `open TestResults.xcresult` en Xcode.

Requisitos: el scheme `nasa.exp` tiene que estar compartido (`xcshareddata`, item I.1) y el runner tiene que tener una versión de Xcode que soporte el formato del proyecto y el deployment target.
Para configurar el secret: Settings → Secrets and variables → Actions → `NASA_API_KEY`.

## Pendientes

Ver `docs/production-plan.md`, items P1.12 (smoke test de UI) e I.4 (tests de errores 429/403, migracion de favoritos y formateadores por locale).
