# PR Description

## Summary

- turn the starter SwiftUI project into an iPhone-first NASA content explorer with a polished tab-based app shell
- add NASA API integration for APOD, Mars Rovers, and EPIC, plus local favorites persistence with SwiftData
- establish a futuristic visual system, agent guidance docs, and initial unit test coverage for decoding, persistence, and view-model behavior

## What Changed

### Product and app structure

- replaced the starter `ContentView` flow with a multi-tab root app experience
- added dedicated feature areas for:
  - APOD
  - Rovers
  - EPIC
  - Favorites
- added reusable app-level navigation and iPhone-first screen structure

### NASA data integration

- added a shared networking layer for NASA API requests
- introduced endpoint modeling, request building, error handling, and async fetching
- implemented feature-specific repositories and view models for:
  - APOD daily content
  - Mars Rover image search
  - EPIC Earth imagery by date

### Favorites and persistence

- added SwiftData-backed favorites storage
- enabled saving and removing APOD, Rover, and EPIC items from native detail screens
- routed favorites back into native detail experiences by content type

### Visual design and UX

- created a new design system with color tokens, typography, spacing, layered surfaces, and reusable components
- applied a cinematic/futuristic "mission control" look across the app
- improved safe-area behavior so content fills the device correctly without clipping under system UI or the tab bar
- refined loading, empty, and error states for a better first-run experience

### Accessibility and polish

- added accessibility labels/hints to primary actions, media, and cards
- improved microcopy for loading, retry, and empty states
- reduced harsh API failure exposure by treating some no-content responses as empty states instead of hard errors

### Configuration and docs

- added `.xcconfig`-based configuration for `NASA_API_KEY`
- added explicit `Info.plist` handling for launch/screen configuration
- documented architecture, testing strategy, and agent instructions in:
  - `AGENTS.md`
  - `docs/architecture.md`
  - `docs/testing.md`
  - `.interface-design/system.md`

### Tests

- added a new `nasa.expTests` target
- added unit tests for:
  - APOD decoding/mapping
  - Rover decoding/mapping
  - EPIC decoding/mapping
  - favorites persistence round-trip
  - favorite model reconstruction
  - view-model success/failure behavior

## Validation

### Build

```bash
xcodebuildmcp simulator build --project-path ./nasa.exp.xcodeproj --scheme nasa.exp --simulator-name "iPhone 17"
```

### Run

```bash
xcodebuildmcp simulator build-and-run --project-path ./nasa.exp.xcodeproj --scheme nasa.exp --simulator-name "iPhone 17"
```

### Tests

```bash
xcodebuild -project "nasa.exp.xcodeproj" -scheme "nasa.exp" -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:nasa.expTests/NASAExpDecodingTests test

xcodebuild -project "nasa.exp.xcodeproj" -scheme "nasa.exp" -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:nasa.expTests/NASAExpStoreAndViewModelTests test
```

## Notes for Reviewers

- `Config/Secrets.xcconfig` remains local and gitignored; reviewers should copy from `Config/Secrets.example.xcconfig`
- the app is currently optimized for iPhone first
- UI styling, architecture, and tests are intentionally set up to support fast follow-on work rather than a one-off prototype
