# Testing Roadmap

This repository does not have an XCTest target yet. These fixtures and cases are ready to plug into `nasa.expTests` as soon as the target is created.

## Suggested Test Target

- Target name: `nasa.expTests`
- Platform: iOS
- Test type: Unit Testing Bundle

## Priority Unit Tests

1. APOD decoding and mapping
   - Decode `docs/fixtures/apod-sample.json` into `APODResponseDTO`.
   - Map DTO to `APODEntry`.
   - Assert media detection (image/video/unsupported).

2. Rover decoding and mapping
   - Decode `docs/fixtures/rovers-sample.json` into `RoverPhotosResponseDTO`.
   - Map to `[RoverPhoto]`.
   - Assert rover/camera/date values.

3. EPIC decoding and mapping
   - Decode `docs/fixtures/epic-sample.json` into `[EPICEntryDTO]`.
   - Map to `[EPICEntry]`.
   - Assert image URL construction and coordinates.

4. Favorite draft integrity
   - Verify APOD/Rover/EPIC models generate stable favorite keys.
   - Verify favorite remove/add roundtrip behavior with in-memory `ModelContainer`.

## Suggested Test Names

- `test_apodDecoding_mapsImageMediaCorrectly`
- `test_apodDecoding_mapsVideoMediaCorrectly`
- `test_roversDecoding_mapsCameraAndDate`
- `test_epicDecoding_buildsArchiveImageURL`
- `test_favoriteDraft_generatesStableKeys`
