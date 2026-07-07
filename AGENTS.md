# Repository Guidelines

## Project Structure & Module Organization
`BeuriDolei/BeuriDolei.xcodeproj` is the Xcode project. App source lives in `BeuriDolei/BeuriDolei/`, which currently contains `BeuriDoleiApp.swift` (entry point), `ContentView.swift` (main screen), `Assets.xcassets/` (icons and colors), and `Preview Content/` for SwiftUI previews. The codebase is intentionally small; when adding features, keep the MVVM direction from `README.md` by grouping new files into folders such as `Views/`, `ViewModels/`, `Models/`, and `Services/` inside the app target.

## Build, Test, and Development Commands
Open the project in Xcode with `open BeuriDolei/BeuriDolei.xcodeproj`.
Build from the command line with `xcodebuild -project BeuriDolei/BeuriDolei.xcodeproj -scheme BeuriDolei -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build`.
List schemes and build settings with `xcodebuild -project BeuriDolei/BeuriDolei.xcodeproj -list`.
Run unit tests with `xcodebuild test -project BeuriDolei/BeuriDolei.xcodeproj -scheme BeuriDolei -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17'`.

## Feature Implementation Loop
Use `docs/IMPLEMENTATION_LOOP.md` as the execution workflow for non-trivial feature work. Use `PRD.md` for product intent, `docs/FEATURE_BACKLOG.md` for feature status and acceptance criteria, and `docs/HANDOVER.md` for current session state between Human, Claude Code, and Codex.

Before implementing a feature, confirm the active backlog item and record the slice in `docs/HANDOVER.md`. After implementation, update the handoff with changed files, verification commands, failures or skipped checks, decisions, and the next recommended action.

## Coding Style & Naming Conventions
Use Swift 6 and SwiftUI conventions. Follow Xcode’s default formatting: 4-space indentation, one top-level type per file, and trailing commas only where Swift style makes diffs cleaner. Name views and app types in `UpperCamelCase` (`ContentView`), properties and methods in `lowerCamelCase`, and asset catalogs with descriptive names. Prefer small SwiftUI views and move stateful or persistence logic out of views into view models or services.

## Testing Guidelines
Add unit tests with XCTest as features become non-trivial. Name test files after the type under test, for example `PlankSessionViewModelTests.swift`, and name methods with `test...` prefixes such as `testStartsThirtyDayChallenge()`. Start with focused unit tests for view models, persistence wrappers, and date or streak logic before adding UI tests.

## Commit & Pull Request Guidelines
The existing history uses Conventional Commit style, for example `feat: init BeuriDolei`. Keep that format: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`. Pull requests should include a short summary, linked issue if one exists, testing notes, and screenshots for visible UI changes.

## Security & Configuration Tips
Do not commit personal signing assets, derived data, or user-specific Xcode settings. Keep bundle identifiers and provisioning changes intentional, and avoid storing secrets in source; use Xcode build settings or local configuration when credentials are introduced.
