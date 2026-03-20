# AGENTS Guide for `nasa.exp`

This guide is for coding agents working in this repository.
It reflects what is currently present in source control.

## Project Overview

- iOS SwiftUI app in `nasa.exp.xcodeproj`.
- Main target/scheme: `nasa.exp`.
- Configurations: `Debug`, `Release`.
- Entry point: `nasa.exp/nasa_expApp.swift`.
- Root view: `nasa.exp/ContentView.swift`.

## Rule Files Check

- Cursor rules in `.cursor/rules/`: not found.
- Workspace `.cursorrules`: not found.
- Copilot rules in `.github/copilot-instructions.md`: not found.
- If these files appear later, treat them as higher-priority instructions.

## Build / Lint / Test Commands

Run commands from repo root:

```bash
cd "/Users/nhsiciliano/Desktop/Coding Apps/nasa.exp"
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
  -destination 'platform=iOS Simulator,name=iPhone 16' \
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
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  analyze
```

### Test (full suite)

There is currently no XCTest target. After adding one, run:

```bash
xcodebuild -project "nasa.exp.xcodeproj" \
  -scheme "nasa.exp" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

### Test (single test class)

```bash
xcodebuild -project "nasa.exp.xcodeproj" \
  -scheme "nasa.exp" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TARGET_NAME/TEST_CASE_CLASS \
  test
```

### Test (single test method)

```bash
xcodebuild -project "nasa.exp.xcodeproj" \
  -scheme "nasa.exp" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TARGET_NAME/TEST_CASE_CLASS/testMethodName \
  test
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

## Agent Working Norms

- Make focused changes; avoid broad refactors unless requested.
- Do not add dependencies or new tools without explicit user ask.
- Preserve existing structure and naming unless there is strong reason.
- Validate with build/analyze; run tests if a test target exists.
- Include the exact command(s) you used in your handoff.
