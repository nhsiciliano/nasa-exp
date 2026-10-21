# AGENTS Guide for `nasa.exp`

This guide is for coding agents working in this repository.
It reflects what is currently present in source control.

## Project Overview

- iOS SwiftUI app in `nasa.exp.xcodeproj`.
- Main target/scheme: `nasa.exp`.
- Configurations: `Debug`, `Release`.
- Entry point: `nasa.exp/nasa_expApp.swift`.
- Root view: `nasa.exp/App/AppRootView.swift` (tab shell).
- Unit test target: `nasa.expTests` (XCTest).
- Production roadmap with difficulty ratings: `docs/production-plan.md`.

## Rule Files Check

- Cursor rules in `.cursor/rules/`: not found.
- Workspace `.cursorrules`: not found.
- Copilot rules in `.github/copilot-instructions.md`: not found.
- If these files appear later, treat them as higher-priority instructions.

## Build / Lint / Test Commands

Run commands from repo root:

```bash
cd "/Users/nhsiciliano/orca/nasa-exp"
```

### Discover targets and schemes

```bash
xcodebuild -list -project "nasa.exp.xcodeproj"
```

### Build (Debug, simulator)

```bash
xcodebuild -project "nasa.exp.xcodeproj" \
  -scheme "nasa.exp" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

### Build (Release)

```bash
xcodebuild -project "nasa.exp.xcodeproj" \
  -scheme "nasa.exp" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  build
```

### Lint / static analysis

There is no separate linter configured (no SwiftLint/SwiftFormat config in repo).
Use compiler warnings plus analyzer:

```bash
xcodebuild -project "nasa.exp.xcodeproj" \
  -scheme "nasa.exp" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  analyze
```

### Test (full suite)

The `nasa.expTests` target covers decoding, request building, favorites persistence and view models:

```bash
xcodebuild -project "nasa.exp.xcodeproj" \
  -scheme "nasa.exp" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
```

### Test (single test class)

```bash
xcodebuild -project "nasa.exp.xcodeproj" \
  -scheme "nasa.exp" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:TARGET_NAME/TEST_CASE_CLASS \
  test
```

### Test (single test method)

```bash
xcodebuild -project "nasa.exp.xcodeproj" \
  -scheme "nasa.exp" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:TARGET_NAME/TEST_CASE_CLASS/testMethodName \
  test
```

### Run on simulator and open a specific tab

Debug builds accept `-initialTab apod|rovers|epic|favorites` as a launch argument:

```bash
xcrun simctl launch "iPhone 17" den-mobile.nasa-exp -initialTab rovers
```

Single-test notes:
- Replace `TARGET_NAME` with the test bundle target (for example `nasa.expTests`).
- Prefer `-only-testing` for fast iteration; run full tests before final handoff.

## Code Style Guidelines

Use Swift + SwiftUI conventions aligned with existing files.

### Imports

- Import only required modules.
- Keep one import per line.
- Remove unused imports.
- Use `SwiftUI` for UI files unless UIKit/AppKit is truly needed.

### Formatting

- Follow Xcode default formatting.
- Use 4 spaces for indentation; no tabs.
- Keep line length readable; wrap long modifier chains.
- Prefer one primary type per file.

### Types and declarations

- Prefer `struct` for SwiftUI views and value models.
- Prefer `let` over `var` unless mutation is required.
- Add explicit access control when useful (`private`, `fileprivate`, `internal`).
- Keep `body` declarative; extract subviews/helpers when complexity grows.

### Naming

- Types/protocols/enums: `UpperCamelCase`.
- Variables/functions/properties: `lowerCamelCase`.
- Boolean names should read as predicates (`isLoading`, `hasError`).
- Use clear, domain-oriented names over abbreviations.

### Error handling

- Prefer typed errors (`enum ...: Error`) over stringly-typed failures.
- Do not silently swallow errors.
- Use `do/catch` for throwing async/sync operations.
- Reserve `assert`/`precondition` for programmer errors, not runtime conditions.

### Concurrency and state

- Respect project actor/concurrency settings.
- Keep UI state updates on main actor.
- Use the narrowest SwiftUI state wrapper that fits (`@State`, `@Binding`, etc.).
- Avoid duplicated state; derive values when possible.
- Pass dependencies explicitly instead of hidden globals.

### Testing conventions (when tests exist)

- Add unit tests for logic-heavy behavior.
- Use deterministic tests; avoid flaky time-based checks.
- Name tests clearly (for example `test_whenCondition_expectedResult`).
- Add regression tests for bug fixes when practical.

### Comments and docs

- Prefer self-documenting names first.
- Add comments only for non-obvious intent or invariants.

## Data Sources

- EPIC uses `api.nasa.gov` with `NASA_API_KEY` from `Config/Secrets.xcconfig` (gitignored;
  `Base.xcconfig` keeps it empty and a Release build phase fails without it).
- APOD uses `science.nasa.gov` (the `apod-basic` RSS feed for the last 30 days and the WordPress
  REST API for the archive). No key. `api.nasa.gov/planetary/apod` returns placeholders; do not use it.
- Rovers use the public raw-image feeds on `mars.nasa.gov` (no key). The old
  `api.nasa.gov/mars-photos` service is discontinued; do not reintroduce it.
- Simulator and `xcodebuild` runs are serialized across agent sessions with the lock directory
  `/tmp/nasa-exp-sim.lock` (take it with `mkdir`, release it with `rm -rf`). Use only the
  "iPhone 17" simulator.
- Keep `docs/` in sync when endpoints, modules or the production plan change.

## Agent Working Norms

- Make focused changes; avoid broad refactors unless requested.
- Do not add dependencies or new tools without explicit user ask.
- Preserve existing structure and naming unless there is strong reason.
- Validate with build/analyze; run tests if a test target exists.
- Include the exact command(s) you used in your handoff.
