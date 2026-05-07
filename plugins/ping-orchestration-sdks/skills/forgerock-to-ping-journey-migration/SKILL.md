---
name: forgerock-to-ping-journey-migration
description: Use when migrating a project from the legacy ForgeRock SDK (FRAuth, FRSession, forgerock-ios-sdk, forgerock-android-sdk, @forgerock/javascript-sdk) to the new Ping Identity Journey SDK. Trigger whenever the user mentions migrating, upgrading, porting, or converting ForgeRock code to the Ping SDK — phrases like "ForgeRock to Ping migration", "upgrade FRAuth", "replace FRSession", "move off @forgerock/javascript-sdk", "migrate to @forgerock/journey-client", "upgrade to Ping Journey SDK", or even a vaguer "help me modernize our ForgeRock auth". Works on Android (Kotlin), iOS (Swift), and JavaScript/TypeScript codebases. Preserves old code as comments so rollback is trivial, verifies the app still builds, and writes a line-numbered report of every change.
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---

# ForgeRock → Ping Journey SDK Migration

Help a developer move an existing app off the legacy ForgeRock SDK and onto the new Ping Identity Journey SDK. This skill drives a careful, auditable migration: scan the codebase, preview the plan, comment-out-and-replace (never silent delete), verify the build, and leave behind a report the developer can hand to a reviewer.

## Supported platforms

| Platform | Legacy package | New package | Reference |
|----------|----------------|-------------|-----------|
| Android (Kotlin) | `org.forgerock:forgerock-auth` (FRAuth/FRSession) | `com.pingidentity.sdks:journey` | [android-migration.md](references/android-migration.md) |
| iOS (Swift) | `ForgeRock/forgerock-ios-sdk` (FRAuth/FRUser) | `ForgeRock/ping-ios-sdk` (PingJourney/PingOidc) | [ios-migration.md](references/ios-migration.md) |
| JavaScript/TypeScript | `@forgerock/javascript-sdk` | `@forgerock/journey-client` + `@forgerock/oidc-client` | [javascript-migration.md](references/javascript-migration.md) |

Each reference file is a complete before/after mapping (imports, classes, methods, parameter changes). Load only the file(s) that match the detected platform(s) — do not pre-read all three.

## When to trigger

Fire this skill whenever the user indicates they want to port ForgeRock auth code to the Ping SDK, even without using the word "migrate". Examples of triggering phrases: "we need to move off FRAuth", "convert this to journey-client", "what would it take to upgrade our ForgeRock integration", "replace `FRSession.authenticate` with the new SDK". When in doubt, offer — being slightly pushy here is correct because the user already has legacy code on disk that will break when ForgeRock is sunset.

---

## Core principles

Read these before starting. They guide every judgment call below.

1. **Never silently delete legacy code.** Comment it out with a recognizable marker so the developer can grep, diff, and roll back in one step. The marker also makes the change legible in code review.
2. **Always leave the build working.** If the build is broken *before* the migration, stop and help fix it first — otherwise you cannot tell whether a post-migration failure was caused by this skill.
3. **Pause on ambiguity.** The legacy and new SDKs are architecturally different (callbacks → coroutines/async-await, static config → factory functions, throwing → Result types). When a transformation requires a judgment call that would change behavior, leave a `TODO(ping-migration):` and ask the developer before proceeding.
4. **Preview before editing.** Show the developer the full list of sites you intend to change, grouped by file, before touching anything. It is cheap to regenerate the plan; it is expensive to undo a bad sweep.
5. **Explain in the report.** The end artifact is a report the developer will read. Treat it as first-class output, not an afterthought.

---

## Workflow

Execute these phases in order. Skip none silently — if the developer wants to skip a phase, they must say so.

### Phase 1 — Detect platform(s)

Identify which platform(s) the target project uses. Look for:

- **Android**: `build.gradle`, `build.gradle.kts`, `settings.gradle*`, `gradle.properties`, `app/src/main/AndroidManifest.xml`
- **iOS**: `Package.swift`, `*.xcodeproj`, `*.xcworkspace`, `Podfile`, `Podfile.lock`
- **JavaScript/TypeScript**: `package.json` (check `dependencies` for `@forgerock/javascript-sdk` or `@forgerock/ping-protect`)

A monorepo may contain more than one. If so, confirm with the developer which target(s) they want to migrate in this session before proceeding.

### Phase 2 — Gather context

Read `AGENTS.md` and `CLAUDE.md` at the project root (and any subproject roots relevant to the platform). These files commonly hold entry-point info, auth module location, custom build commands, and preferred conventions — all critical for a safe migration.

If **neither** file exists, offer to create `AGENTS.md` using [agents-template.md](references/agents-template.md) as a starting point. Fill it in from what you can observe: project structure, primary language, build command, location of existing auth code. Ask the developer to confirm or correct before saving. The file benefits this migration *and* future work, which is why it is worth the small detour.

If the developer declines, proceed without it but note this in the final report.

### Phase 3 — Pre-flight build check

Before changing anything, confirm the app builds in its current state. Ask the developer:

> "Want me to run the build now to confirm a clean baseline, or do you already know it builds?"

If they say yes, or are unsure, run the appropriate command (see [Build commands](#build-commands) below). If the build fails, **stop here**. Help fix the pre-existing failure first — you cannot migrate safely on top of a broken baseline. Resume when the build is green.

If the developer says "just trust me, it builds", accept and continue, but record this in the report so they know they opted out of the baseline check.

### Phase 4 — Scope the migration

Ask the developer:

> "Do you want me to scan the whole project, or migrate a specific area (e.g. a single file, a feature module, the login flow)?"

Honor partial scope. Partial scope is common and legitimate — a team may want to migrate incrementally, module by module. If partial, confirm the exact set of files/directories before scanning.

### Phase 5 — Scan for legacy usage

Using `Grep` and `Read`, build an inventory of legacy SDK usage in the chosen scope. The reference files list every legacy symbol you should search for. Key anchors to grep:

- **Android**: `FRSession`, `FRUser`, `FRAuth`, `NodeListener`, `FROptions`, `FRDeviceCollector`, `import org.forgerock.android`, `WebAuthRegistrationCallback`, `DeviceBindingCallback`, `FRListener`, `PingOneProtect*`
- **iOS**: `FRAuth`, `FRSession`, `FRUser`, `FROptions`, `import FRAuth`, `import FRCore`, `WebAuthnRegistrationCallback`, `WebAuthnAuthenticationCallback`, `SelectIdPCallback`, `FRGoogleSignIn`, `FRFacebookSignIn`, `FRCaptchaEnterprise`, `Node.next { ... }` completion-handler style
- **JavaScript**: `@forgerock/javascript-sdk`, `Config.set`, `FRAuth.start`, `FRAuth.next`, `FRUser.logout`, `UserManager.getCurrentUser`, `TokenManager.getTokens`, `TokenStorage`, `FRWebAuthn`, `CallbackType`, `FRCallback`, `FRStep`, `@forgerock/ping-protect`

Also inventory:
- **Dependency files** — `build.gradle*`, `Package.swift`, `Podfile`, `package.json` — to know which declarations will need updating.
- **Manifest/config files** — e.g. `AndroidManifest.xml` redirect URIs, iOS `Info.plist` URL schemes, JS `index.html` — in case the new SDK requires different entries.
- **Test files** — they often duplicate auth setup code and must be migrated in lockstep.

### Phase 6 — Preview plan

Present the findings to the developer **before editing**. Structure:

```
## Migration plan (preview)

Platform(s): Android
Scope: app/src/main/java/com/example/auth/**

Dependency changes (1 file):
  - app/build.gradle.kts — remove org.forgerock:forgerock-auth, add com.pingidentity.sdks:journey

Code changes (4 files, 12 sites):
  - app/src/main/java/com/example/auth/AuthManager.kt — 5 sites
      line 23: FROptionsBuilder.build { ... } → Journey { ... }
      line 41: FRSession.authenticate → journey.start
      line 56: NodeListener<FRSession> → Node sealed-class handling
      line 78: NameCallback setter → property assignment
      line 102: FRUser.getCurrentUser()?.logout() → journey.user()?.logout()
  - app/src/main/java/com/example/auth/LoginViewModel.kt — 4 sites
      ...

Manual review items (2):
  - app/src/main/java/com/example/auth/DeviceHelper.kt:87 — uses custom FRDeviceCollector
    composition; the new API uses DefaultDeviceCollector. I'll add a TODO but
    want your input on whether the custom collectors are still needed.
  - app/src/main/AndroidManifest.xml:34 — redirect URI scheme matches legacy
    sample; confirm it still applies to your new OIDC client.

Proceed? (y / partial / no)
```

Let the developer edit the plan — they may want to skip a file, defer an item, or adjust the scope. Do not start Phase 7 until they approve.

### Phase 7 — Apply changes

For each site, **comment out** the legacy code and **insert** the new code directly below. Use this marker convention so a single grep locates every change:

**Android / iOS (Kotlin/Swift line comments):**
```kotlin
// [ping-migration] BEGIN legacy — safe to delete after verifying the migration
// FRSession.authenticate(context, "Login", nodeListener)
// [ping-migration] END legacy
val node: Node = journey.start("Login")
```

**JavaScript/TypeScript (line comments):**
```typescript
// [ping-migration] BEGIN legacy — safe to delete after verifying the migration
// const step = await FRAuth.start();
// [ping-migration] END legacy
const result = await journeyClient.start({ journey: 'Login' });
```

Why begin/end markers on both sides? A single-line comment is easy to miss in a diff; the paired markers make the boundary unambiguous and let the developer remove the block with a single multi-line selection later.

**Dependency files.** Before editing, check whether the new dependency is already declared (developer may have started the migration). If yes, skip that entry and note it in the report. When modifying, comment out the legacy line with the same marker convention and add the new declaration below. For `package.json`, where JSON does not support comments, update `dependencies` in place but list both the removed and added packages in the report's "Dependencies" section.

**Ambiguous transforms.** When the mapping requires a judgment call — e.g., a legacy callback-based flow that needs to become a coroutine/async block in a different part of the file, or behavioral changes like `NodeListener.onException` splitting into `ErrorNode`/`FailureNode` — **do not guess**. Insert a `TODO(ping-migration):` comment explaining the ambiguity and ask the developer in chat before making the change:

```kotlin
// TODO(ping-migration): onException previously handled both API errors and
// unexpected exceptions. The new SDK splits these into ErrorNode (API errors,
// has .message) and FailureNode (exceptions, has .cause). Do you want to
// preserve a single error path, or branch on node type for different UX?
```

Work one file at a time so failures are isolated and the report stays coherent.

### Phase 8 — Post-flight build

Ask the developer:

> "Ready to run the build to verify? (This can take a few minutes.)"

If yes, run the appropriate build command. If the build passes, proceed to Phase 9.

If it fails:
1. Show the error.
2. Diagnose — is it a transformation error, a missing dependency, a manifest/plist change we missed, or an unrelated pre-existing issue?
3. Fix iteratively, rebuilding until green.
4. **Never declare migration complete with a failing build.** If you cannot get it green (e.g., you need cloud credentials, or there's a genuine runtime issue the developer must resolve), say so explicitly — do not close out the task with a ✅.

If the developer declines to run the build, write the report with a clear banner at the top: `⚠️ Build verification was skipped — migration is not yet confirmed to compile.`

### Phase 9 — Write the migration report

Write `MIGRATION_REPORT.md` at the project root (or at the root of the migrated subproject, if partial). Use [report-template.md](references/report-template.md) as the structure. The report must include:

1. **Summary** — platforms migrated, scope, date, build status.
2. **Dependency changes** — packages added, removed, or comment-preserved.
3. **File-by-file changes** — path, line numbers (legacy → new), brief description of each change.
4. **Manual review items** — every `TODO(ping-migration):` left behind, with file:line pointers.
5. **Skipped items** — anything the developer chose not to migrate.
6. **Rollback instructions** — the grep command to find all markers, plus the removal procedure.
7. **Next steps** — once the developer has verified behavior, run `grep -R "\[ping-migration\] BEGIN legacy"` and remove the commented blocks.

The report should be readable standalone — a reviewer who was not in the session should understand what changed and why.

---

## Build commands

Use the project's standard build command. If `AGENTS.md` specifies one, prefer that. Otherwise:

| Platform | Command (adjust to project layout) |
|----------|------------------------------------|
| Android | `./gradlew assembleDebug` (or `./gradlew :app:assembleDebug`) |
| iOS (SPM) | `xcodebuild -scheme <scheme> -destination 'generic/platform=iOS Simulator' build` |
| iOS (CocoaPods) | `pod install` then `xcodebuild -workspace <name>.xcworkspace -scheme <scheme> build` |
| JavaScript | Detect via `package.json` — `npm run build`, `pnpm build`, or `yarn build` depending on lockfile |

Always confirm the exact command with the developer if the project deviates. For iOS, the scheme and destination vary per project; ask before the first build.

---

## Things that always need manual attention

These transformations cannot be safely automated. Always flag them in the report:

- **Error handling shape changes.** Legacy SDKs throw; new SDKs return Result/sealed types. The developer often wants to rethink UX at these boundaries (retry? silent fail? logout?).
- **Token storage.** If the legacy app wrote tokens to a custom store, the new SDK's default storage behavior may differ. Confirm storage choice.
- **Redirect URIs.** New OIDC clients may require different URI schemes. Cross-check manifest/plist entries against the new OIDC client config.
- **Test fixtures.** Mock `FRListener` implementations and fake `FRStep` objects do not translate mechanically — they need rewriting against the new type system.
- **Social / IdP handlers.** Legacy `FRGoogleSignIn`, `FRFacebookSignIn`, etc. are replaced with separate `PingExternalIdP*` modules; the app-level configuration (Google Client ID, Facebook App ID) may need fresh setup in Ping.
- **Device binding and FIDO.** Class names and flows changed (`WebAuthRegistrationCallback` → `FidoRegistrationCallback`; `DeviceBindingCallback.bind(...)` signature is different). Always show the developer the diff before applying.

---

## What *not* to do

- Do not run the migration without a preview, even if the developer is in a hurry. The preview is the contract.
- Do not delete legacy code outright. The comment-and-replace pattern is the rollback plan.
- Do not silently pick a build command. Confirm with the developer, especially on iOS where scheme/destination vary.
- Do not declare success if any phase was skipped or any build failed. Say so, in plain language, in the report.
- Do not generate shell or language-specific scripts as part of the migration — the developer may not have Node, Python, or Ruby available. Perform edits directly with file tools and shell out only to the project's native build tool.

---

## Reference files

- [android-migration.md](references/android-migration.md) — Full legacy→new mapping for Android (Kotlin).
- [ios-migration.md](references/ios-migration.md) — Full legacy→new mapping for iOS (Swift).
- [javascript-migration.md](references/javascript-migration.md) — Full legacy→new mapping for JavaScript/TypeScript.
- [agents-template.md](references/agents-template.md) — Template for generating an `AGENTS.md` when the project lacks one.
- [report-template.md](references/report-template.md) — Structure for the final `MIGRATION_REPORT.md`.

Load only the reference(s) relevant to the detected platform(s). The migration mappings are long — do not preload all of them.
