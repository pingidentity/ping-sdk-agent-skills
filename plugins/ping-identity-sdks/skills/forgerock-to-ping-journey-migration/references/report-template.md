# Migration report template

Write the final report as `MIGRATION_REPORT.md` at the root of the migrated project (or the migrated subproject, if scope was partial). This is the artifact the developer hands to a reviewer — treat it as the primary deliverable, not an afterthought.

Fill in every placeholder below. If a section has nothing to report, keep the heading and write `None.` so the reader knows you checked.

---

```markdown
# ForgeRock → Ping Journey SDK migration report

**Date**: <YYYY-MM-DD>
**Platform(s)**: <Android / iOS / JavaScript / combination>
**Scope**: <whole project | list of paths | specific feature>
**Build status**:
  - Pre-migration build: <✅ passed | ⚠️ skipped — developer opted out | ❌ fixed before starting: "<one-line description">
  - Post-migration build: <✅ passed | ⚠️ skipped — developer opted out | ❌ failing (see "Open issues")>

<If the post-migration build did not pass or was skipped, add a prominent
banner at the top:>

> ⚠️ This migration has **not** been verified to compile. Do not merge until
> the build is green.

---

## Summary

<2–4 sentences. What was migrated, at what level, and any high-level caveats.
Example: "Migrated the login flow (AuthManager + LoginViewModel) from
FRSession/NodeListener to the new Journey API. OAuth redirect URI and
realm configuration preserved. Device binding code deferred — see Open
issues.">

## Dependency changes

<One sub-bullet per manifest/lockfile touched.>

- **`app/build.gradle.kts`**
  - Removed (commented out): `org.forgerock:forgerock-auth:4.6.0`
  - Added: `com.pingidentity.sdks:journey:2.0.0-beta1`
  - Added: `com.pingidentity.sdks:oidc:2.0.0-beta1`
- **`package.json`**
  - Removed: `@forgerock/javascript-sdk@^4.6.0`
  - Added: `@forgerock/journey-client@^1.0.0`
  - Added: `@forgerock/oidc-client@^1.0.0`

<If the developer had already updated a dependency file before running the
skill, note it explicitly:>

- **`Package.swift`** — already updated to `ping-ios-sdk 2.0.0` before the
  migration started; no changes made by this run.

## Code changes

<One sub-section per file. Use legacy→new line references where possible.
Keep descriptions short — the reviewer can `git diff` for the exact bytes.>

### `app/src/main/java/com/example/auth/AuthManager.kt`

- **L23–L38** — `FROptionsBuilder.build { ... }` → `Journey { ... }` (DSL config).
- **L41** — `FRSession.authenticate(context, "Login", nodeListener)` → `journey.start("Login")`.
- **L56–L72** — `NodeListener<FRSession>` anonymous object replaced with
  `when (node) { is ContinueNode -> ... is SuccessNode -> ... }` sealed-class handling.
- **L78** — `nameCallback.setName("u")` → `nameCallback.name = "u"`.
- **L102** — `FRUser.getCurrentUser()?.logout()` → `journey.user()?.logout()`.

### `app/src/main/java/com/example/auth/LoginViewModel.kt`

- **L15, L33** — imports updated.
- **L47** — token retrieval now goes through `journey.user()?.token()` returning `Result<Token, OidcError>`.

## Manual review items

<List every `TODO(ping-migration):` left in the code, with file:line. These
are the items the developer explicitly needs to make a decision on.>

- `app/src/main/java/com/example/auth/AuthManager.kt:56` — legacy `onException`
  handled both API errors and exceptions in one path; new SDK splits into
  `ErrorNode` and `FailureNode`. I left a single error path; confirm if
  separate UX is needed.
- `app/src/main/java/com/example/auth/DeviceHelper.kt:87` — custom
  `FRDeviceCollector` composition. New default is `DefaultDeviceCollector()`.
  Confirm the custom collectors (metadata, location) are still required.
- `app/src/main/AndroidManifest.xml:34` — OIDC redirect URI scheme
  `org.forgerock.demo`. Confirm this matches the new OIDC client's
  registered redirect URI.

## Skipped items

<Things in the scan the developer chose to defer. Empty = None.>

- `app/src/main/java/com/example/auth/WebAuthnModule.kt` — FIDO migration
  deferred to a follow-up PR (per developer request).

## Test changes

<Tests often duplicate auth setup. List any test file that was touched.>

- `app/src/test/java/com/example/auth/AuthManagerTest.kt` — `FRListener`
  mocks replaced with direct `suspend` assertions on `Node` sealed class.

## Open issues

<If the post-migration build did not pass, or anything else is blocking
merge, list it here with enough detail to act on.>

None.

## Rollback

Every legacy line was preserved as a comment. To find every change:

```bash
grep -Rn "\[ping-migration\] BEGIN legacy" .
```

To roll back a single file, delete the inserted new code and uncomment the
legacy block between `[ping-migration] BEGIN legacy` and `[ping-migration] END legacy`.

To roll back the entire migration, run `git checkout -- <file>` for each
touched file (see "Code changes" above), then restore the original
dependency declarations.

## Next steps

Once the developer has exercised the app end-to-end and is confident the
migration is correct:

1. Remove the commented legacy blocks:
   ```bash
   # Preview first
   grep -Rn "\[ping-migration\]" .
   ```
   Then delete each `BEGIN legacy ... END legacy` block manually or with an
   editor macro.
2. Remove any remaining `TODO(ping-migration):` comments once the
   corresponding decisions are made.
3. Remove `MIGRATION_REPORT.md` from the working tree (keep it in PR
   history instead).
```
