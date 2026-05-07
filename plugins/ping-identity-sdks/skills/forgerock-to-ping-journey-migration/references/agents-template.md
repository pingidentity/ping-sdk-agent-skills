# AGENTS.md template

Use this template when the target project has no `AGENTS.md` or `CLAUDE.md`. Fill in each section from what you can observe in the repo — do not leave placeholders. Confirm with the developer before saving.

The goal is a short, high-signal document that future agent sessions (and humans) can read in under a minute to understand how to work in this project. Aim for under 100 lines.

---

```markdown
# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this project is

<1-2 sentences: product name, what it does, primary users. Derive from README or package metadata.>

## Stack

- **Language**: <Kotlin / Swift / TypeScript / ...>
- **Framework**: <Android Compose / SwiftUI / React / Next.js / ...>
- **Identity SDK**: <ForgeRock legacy / Ping Journey / mixed during migration>
- **Package manager**: <Gradle / SPM / CocoaPods / npm / pnpm / yarn>
- **Minimum platform**: <Android SDK 29 / iOS 16 / Node 20 / ...>

## Layout

<A handful of lines describing where the important code lives. Examples:>

- `app/src/main/java/com/example/auth/` — authentication module (currently using FRAuth)
- `app/src/main/java/com/example/ui/` — Jetpack Compose screens
- `app/src/test/` — unit tests
- `app/src/androidTest/` — instrumented tests

## Build & run

- **Build**: `<exact command — e.g. ./gradlew assembleDebug>`
- **Test**: `<exact command — e.g. ./gradlew testDebugUnitTest>`
- **Run locally**: `<exact command or steps>`
- **Lint / format**: `<exact command, if configured>`

## Auth integration

<Where the app talks to the identity provider. This section is especially
useful during a migration. Fill in:>

- **Entry point**: <file:line where the auth flow starts — e.g. `AuthManager.kt:23`>
- **Config location**: <where server URL, realm, client ID, redirect URI are set>
- **Callback handlers**: <which callbacks the app implements today>
- **Token storage**: <default SDK storage / custom implementation>

## Conventions

<Short list of things the team cares about. Examples:>

- Prefer `StateFlow` over `LiveData` for new ViewModels.
- Error messages must go through `ErrorReporter.report(...)`, not `Log.e`.
- No new `GlobalScope.launch` — use `viewModelScope` or `lifecycleScope`.

## What to be careful with

<Short list of surprises. Examples:>

- `AuthManager` is a singleton — do not instantiate elsewhere.
- Do not call `FRSession.authenticate` outside `AuthManager` (historical reasons).
- Tests use MockWebServer on port 8080 — that port must be free.
```

---

## How to fill this in

Read a handful of anchors to populate the template:

- **README** (project root) — product description, stack summary
- **Dependency file** (`build.gradle*`, `Package.swift`, `package.json`) — stack confirmation, build commands via scripts
- **CI config** (`.github/workflows/*.yml`, `.gitlab-ci.yml`) — canonical build/test commands
- **Directory tree** at depth 2–3 — layout section
- **Existing auth code** — entry point and config location (this skill already scanned for these in Phase 5; reuse those findings)

If a section genuinely has nothing to say, remove it rather than leaving it empty.
