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

### `FavoriteStoreUpsertTests` (SwiftData en memoria)

- `test_upsert_legacyFavorite_fillsMissingMetadataWithoutDuplicating` (mantiene `createdAt`)
- `test_upsert_draftWithoutMetadata_keepsStoredValues`
- `test_upsert_legacyEPICFavoriteWithAPIKey_storesLiveURLWithoutKey`
- `test_upsert_draftURLsWithAPIKey_dropOnlyTheKey`
- `test_refreshIfFavorite_whenNotFavorite_returnsFalseAndStoresNothing`
- `test_refreshIfFavorite_whenFavorite_returnsTrueAndFillsMetadata`

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
- `test_videoEntry_usesScreenWidthPosterForShareAndSave`, `test_videoEntry_shareMessageAddsArticleLinkToCaption`,
  `test_videoEntryWithoutPoster_hasNothingToShareOrSave`, `test_imageEntry_sharesScreenImageAndSavesOriginal` (R1.1)

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

### `DisplayDateLocaleTests`

- `test_apodDisplayDate_usesLongStyleForLocale`
- `test_epicDisplayDate_includesTimeForLocale`
- `test_roverDisplayDate_prefixesSolForLocale`
- `test_roverDisplayDate_withoutEarthDate_showsOnlySol`

Fijan la salida en `es_ES` y `en_US` con zona UTC usando `displayDate(locale:timeZone:)` de cada modelo; la app sigue usando `displayDate`, que toma el locale del dispositivo.

### `AppTabDeepLinkTests`

- `test_appTabFromURL_whenNASAExpDeepLink_selectsMatchingTab`
- `test_appTabFromURL_whenOtherSchemeOrUnknownTab_returnsNil`
- `test_appTabDeepLinkURL_roundTripsForEveryTab`
- `test_appTabFromLaunchArgument_matchesDeepLinkNames`

### `NASAExpWidgetTests` (lógica del widget de APOD, que vive en el target de la app)

- `APODPublicationSchedule`: `test_nextRefresh_whenShowingTodaysEntry_waitsForNextPublication`,
  `test_nextRefresh_lateInTheEasternDay_comparesAgainstTheEasternDate`,
  `test_nextRefresh_whenEntryIsStaleOrMissing_retriesAfterRetryInterval`,
  `test_nextPublication_acrossDaylightSavingEnd_staysAtSameEasternTime`
- `ImageDownsampler`: `test_maxPixelSize_coversTargetWithoutUpscaling`, `test_downsample_cropsToTargetAspectAtTargetSize`,
  `test_downsample_whenTargetIsLarger_keepsResolutionAndCropsAspect`, `test_downsample_whenDataIsNotAnImage_returnsNil`
- `APODWidgetContentLoader`: `test_widgetLoader_withImageEntry_downsamplesScreenSizedImage`,
  `test_widgetLoader_withRecordFromSource_requestsScreenWidthCopyOfOriginal`,
  `test_widgetLoader_withVideoEntry_showsScreenWidthPosterAndCredit`,
  `test_widgetLoader_withImageEntryWithoutCredit_creditsNASA`,
  `test_widgetLoader_withVideoEntryWithoutPoster_opensInAppWithoutDownloading`,
  `test_widgetLoader_whenFetchOrImageFails_returnsNoContentAndRetries`

### `PhotoWidgetLoaderTests` (loaders de los widgets de Rovers y EPIC, R1.2)

Usan las respuestas reales de `docs/fixtures` y un servidor stub que registra cada URL pedida.

- `test_roversLoader_requestsOnePhotoPerRoverAndShowsTheNewest` (`num=1` / `per_page=1`, gana la foto más reciente)
- `test_roversLoader_whenOneFeedTimesOut_showsTheOtherRover` (y usa el `large` de 1200 px de Mars 2020)
- `test_roversLoader_whenBothFeedsOrTheImageFail_returnsNoContentAndRetries`
- `test_epicLoader_requestsKeylessFeedAndJPEGOfLatestImage` (sin `api.nasa.gov` ni `api_key`)
- `test_epicLoader_whenFeedIsEmptyOrFails_returnsNoContentAndRetries`
- `test_epicEntry_jpegURL_pointsToTheJPGFolderOfTheSameFrame`

### `APODDailyReminderTests` (notificación diaria del APOD, R1.3)

- Contenido: `test_requests_fillTheWindowFromTodayAtTheChosenLocalTime`, `test_requests_whenTodaysTimeHasPassed_startTomorrow`,
  `test_requests_acrossDaylightSavingEnd_keepTheLocalTime` (Madrid), `test_requests_titleOnlyTheDayWhoseEntryIsAlreadyOut`
  (01:00 en Buenos Aires todavía es el APOD de ayer), `test_requests_beforeTheEntryOfThatDayIsOut_keepTheGenericText`,
  `test_latestEntryID_switchesAfterThePublicationDelay`, `test_requests_whenDisabled_isEmpty`
- Reprogramación: `test_reschedule_replacesOnlyTheReminderRequests`, `test_reschedule_whenDisabled_removesTheWindowWithoutAddingRequests`,
  `test_refresh_whenEnabled_titlesTheNextReminderAndAsksForTheNextBackgroundRefresh`,
  `test_refresh_whenFetchFails_stillSchedulesTheGenericWindow`, `test_refresh_whenDisabled_doesNothing`
- Opt-in: `test_enable_whenPermissionIsDenied_staysOffAndPointsToSettings`,
  `test_enableThenChangeTime_savesAndReschedulesAtTheNewTime`, `test_store_withoutSavedSettings_returnsDefaultOff`

Usan un `UNUserNotificationCenter` falso (`APODReminderNotificationCenter`) y `UserDefaults` en un suite propio por test.

### `NASAExpDeepLinkUITests` (target `nasa.expUITests`)

- `test_openURL_selectsTabOfDeepLink`: arranca en Rovers y abre `nasaexp://favorites` y `nasaexp://apod`
  con `XCUIApplication.open(_:)`, como lo hace el widget. No depende de la red.

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
- `docs/fixtures/epic-gsfc-natural-sample.json` (`epic.gsfc.nasa.gov/api/natural` del 2026-10-26: primera y
  última imagen del día, sin los bloques de posiciones J2000)
- `docs/fixtures/rovers-msl-sample.json` (Curiosity, `raw_image_items`)
- `docs/fixtures/rovers-mars2020-sample.json` (Perseverance, `rss/api`)

## QA manual en simulador

Los builds Debug aceptan `-initialTab` para abrir una pestaña directamente:

```bash
xcrun simctl launch "iPhone 17" den-mobile.nasaexp -initialTab rovers
xcrun simctl io "iPhone 17" screenshot rovers.png
```

Con la app instalada, los deep links del widget se prueban con `openurl` (en cualquier build):

```bash
xcrun simctl openurl "iPhone 17" nasaexp://apod
```

La notificación diaria se activa en Favoritos → Acerca de; la primera vez aparece el pedido de permiso del
sistema. Para probar el toque sin esperar a la hora elegida, se puede mandar una notificación con el mismo
`userInfo` (`"url": "nasaexp://apod"`) con `xcrun simctl push "iPhone 17" den-mobile.nasaexp payload.json`.

Los widgets (APOD, Rovers y EPIC) se agregan desde la home del simulador: mantener presionado el fondo,
"Editar" → "Agregar widget", buscar "NASA Exp" y elegir el widget y el tamaño. Con ui-automation es más
fiable mantener presionado el ícono de NASA Exp, que ofrece los tamaños del widget directamente.

## CI

`.github/workflows/ci.yml` corre en cada pull request y en cada push a `main`, sobre `macos-latest`:

1. Selecciona la versión estable más nueva de Xcode instalada en el runner (`xcode-select`).
2. Genera `Config/Secrets.xcconfig` con el secret `NASA_API_KEY` del repositorio. Si el secret no existe, usa `DEMO_KEY` y deja un warning en el job.
3. Elige simulador con `.github/scripts/select-simulator.py`: `iPhone 17` si existe, si no el iPhone de número más alto en el runtime de iOS más nuevo.
4. Corre `xcodebuild build test` en Debug con `CODE_SIGNING_ALLOWED=NO`.
5. Si algo falla, sube `build/TestResults.xcresult` como artifact (14 días). Se abre con `open TestResults.xcresult` en Xcode.

Requisitos: el scheme `nasa.exp` tiene que estar compartido (`xcshareddata`, item I.1) y el runner tiene que tener una versión de Xcode que soporte el formato del proyecto y el deployment target.
Para configurar el secret: Settings → Secrets and variables → Actions → `NASA_API_KEY`.

## Release archive

Archive en seco antes de subir a TestFlight, para encontrar problemas que solo aparecen en Release. Necesita `Config/Secrets.xcconfig` con la key real (la fase "Validate NASA API Key" corta el build Release si la key está vacía o es el placeholder):

```bash
xcodebuild -project "nasa.exp.xcodeproj" \
  -scheme "nasa.exp" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$TMPDIR/nasa.exp.xcarchive" \
  archive
```

El archive queda fuera del repo (`build/` no está en `.gitignore`); `open "$TMPDIR/nasa.exp.xcarchive"` lo abre en Organizer.

Resultado del 2026-10-21 (Xcode 27.1, SDK iphoneos27.1), `** ARCHIVE SUCCEEDED **` en unos 6 minutos:

- Firma automática con el equipo `C9SN4BNWU9` y el perfil "iOS Team Provisioning Profile" (Apple Development); no hizo falta `CODE_SIGNING_ALLOWED=NO`. Al subir, Organizer → Distribute App → App Store Connect vuelve a firmar con el certificado de distribución.
- Sin warnings del compilador en Release; el único warning del log es el de `appintentsmetadataprocessor` (la app no usa App Intents).
- La fase "Validate NASA API Key" corrió, y el `Info.plist` del `.app` lleva una key de 40 caracteres.
- `Info.plist`: `UIDeviceFamily` = [1] (solo iPhone), solo orientación vertical, `MinimumOSVersion` 17.0, `arm64`, `ITSAppUsesNonExemptEncryption` = false, versión 1.0 (1). Sin `UISupportedInterfaceOrientations~ipad` ni otras claves de iPad, salvo `CFBundleIcons~ipad` y `AppIcon76x76@2x~ipad.png`, que agrega `actool` a partir del ícono universal de 1024 aunque el target es solo iPhone. App Store Connect no las rechaza.
- Dentro del `.app`: `PrivacyInfo.xcprivacy` (sin tracking, sin datos recolectados, sin APIs con motivo requerido), `en.lproj/Localizable.strings` (173 textos), `InfoPlist.strings` en `es.lproj` y `en.lproj`. El español no tiene `Localizable.strings` porque es el idioma fuente: las claves ya son el texto.
- `UserDefaults` solo se usa para `-initialTab` dentro de `#if DEBUG` y no aparece en el binario Release, así que el manifiesto no necesita declararlo.
  Desde R1.3 (1.1) la preferencia de la notificación diaria también vive en `UserDefaults`, y el manifiesto declara
  `NSPrivacyAccessedAPICategoryUserDefaults` con el motivo `CA92.1`.
- Tamaño: `.app` 1,5 MB (binario 1,0 MB, `Assets.car` 436 KB); el `.xcarchive` completo con dSYM, 7,5 MB.

## Ciclo de cambios y TestFlight

El bundle de producción es `den-mobile.nasaexp` (widget `den-mobile.nasaexp.widget`). Los cambios se hacen en una rama de trabajo (`nhsiciliano/lead-dev`) y se llevan a `main` cuando la suite está verde. Para cada build que se sube a TestFlight:

1. Suite completa verde en la rama (comando en "Test (full suite)").
2. Subir `CURRENT_PROJECT_VERSION` en `Config/Base.xcconfig`. Es el único lugar: todos los targets lo heredan, así que la app y el widget quedan con el mismo número. App Store Connect rechaza un número de build ya usado para la misma `MARKETING_VERSION`.
3. Commit, por ejemplo `Build 2`.
4. En Xcode, destino "Any iOS Device (arm64)" → Product → Archive → Distribute App → App Store Connect → Upload. Con "Automatically manage signing" Xcode firma la app y el widget con los perfiles de distribución.
5. Esperar el mail de "build is ready" (10 a 30 minutos). Si el grupo interno de TestFlight tiene distribución automática, los testers reciben el build sin más pasos; si no, asignarlo en TestFlight → grupo → Builds.
6. "What to Test": resumen de los cambios, con la checklist de `docs/qa-checklist.md` como guía.

`MARKETING_VERSION` recién cambia (1.1, 1.2, …) cuando se publica una versión nueva en el App Store; mientras tanto solo sube el número de build.

## Pendientes

Ver `docs/production-plan.md`, items P1.12 (smoke test de UI) e I.4 (tests de errores 429/403, migracion de favoritos y formateadores por locale).
