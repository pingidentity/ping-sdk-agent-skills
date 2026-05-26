# ping-sdk-router Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `ping-orchestration-sdk-router` skill at `plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/` that probes the user's project, picks the right umbrella skill (Android/iOS today; JS/React Native via placeholders), and hands off — provisioned for easy expansion via a platform registry.

**Architecture:** Pure-markdown skill (single `SKILL.md`, no `assets/`/`references/`/`scripts/`). The body contains a platform registry table, per-platform probe blocks (shell `find`/`grep` commands), a deterministic decision tree, and a 3-step recipe for adding new platforms. Validation is via `npx skills-ref validate` plus the repo's `claudelint` rules. Behavioral verification uses three fixture project directories (empty / Android Gradle / Swift Package) that the implementer creates locally and discards (not committed).

**Tech Stack:** Markdown (Agent Skills v1 spec), YAML frontmatter, shell commands (`find`, `grep`, `test`) embedded in skill body.

---

## File Structure

Files this plan creates or modifies:

- **Create:** `plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md` — the entire router skill.
- **Modify:** `README.md` — add a new "Routing Skills" section to the Available Skills area.
- **Modify:** `plugins/ping-orchestration-sdks/README.md` — add a parallel "Routing Skills" section.

No other files. The spec called for no `assets/`, `references/`, or `scripts/` directories.

The spec (`docs/superpowers/specs/2026-05-13-ping-sdk-router-design.md`) governs every decision in this plan; if a task seems to drift from the spec, re-read the spec.

---

## Task 1: Scaffold the skill directory and write the frontmatter

**Files:**
- Create: `plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md`

This task creates the skill directory and writes a SKILL.md containing only the frontmatter and a one-paragraph overview. Subsequent tasks fill in the body. The skill must validate at this stage so we catch frontmatter mistakes before piling on content.

- [ ] **Step 1: Create the skill directory**

Run:
```bash
mkdir -p plugins/ping-orchestration-sdks/skills/ping-sdk-router
```

- [ ] **Step 2: Write the initial SKILL.md (frontmatter + overview)**

Create `plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md` with this exact content:

````markdown
---
name: ping-sdk-router
description: >-
  Use when a user asks for help with Ping Identity SDK integration without
  specifying a platform — phrases like "help me add Ping auth", "I want to use
  PingOne", "get started with the Ping SDK". Probes the project to detect
  Android, iOS, JavaScript, or React Native, asks if ambiguous, and routes to
  the matching umbrella skill (ping-sdk-android, ping-sdk-ios, planned: ping-sdk-js,
  ping-sdk-react-native) or to forgerock-to-ping-journey-migration when ForgeRock
  SDK references are present.
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---

# Ping SDK Router

First point of contact for vague Ping Identity SDK requests. Probes the working directory to detect platform (Android, iOS, JavaScript, React Native) and ForgeRock SDK references, then hands off to the most suitable umbrella skill in this plugin. New platforms are added by editing one row in the platform registry below — the decision tree picks them up automatically.
````

- [ ] **Step 3: Validate the skill structure**

Run:
```bash
npx skills-ref validate ./plugins/ping-orchestration-sdks/skills/ping-sdk-router
```
Expected: passes with no errors. If `skills-ref` is not installed, install on demand with `npx --yes skills-ref ...`.

- [ ] **Step 4: Run the repo lint rules**

Run:
```bash
claudelint .
```
Expected: no new errors introduced by the new skill. The `skill-readme-documentation` rule **will** flag the new skill as missing from README tables — that is expected and gets fixed in Task 6. All other custom rules (`skill-directory-structure`, `skill-required-metadata`, `skill-markdown-naming`) must pass.

If `claudelint` is not installed locally, skip this step and note it for the final check in Task 7.

- [ ] **Step 5: Commit**

```bash
git add plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md
git commit -m "feat(ping-sdk-router): scaffold skill with frontmatter and overview"
```

---

## Task 2: Add the platform registry and probe blocks

**Files:**
- Modify: `plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md` — append registry + probe sections after the overview.

The registry is the heart of the expansion mechanism. The decision tree (Task 3) reads "active rows" from this table, so adding a new platform later is just a one-row edit + a new probe block.

- [ ] **Step 1: Append the platform registry section**

Append the following to `plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md`:

````markdown

## Platform Registry

This table is the single source of truth for routing. The decision tree below references it by `Status`. To add a new platform, change its status from `placeholder` to `active`, add a probe block, and you are done.

| Platform | Target Skill | Status | Notes |
|----------|--------------|--------|-------|
| Android | `ping-orchestration-android-sdk` | active | — |
| iOS | `ping-orchestration-ios-sdk` | active | — |
| JavaScript (web) | `ping-orchestration-javascript-sdk` | placeholder | Stopgap: `ping-orchestration-reactjs-js-journey-sdk`, `ping-orchestration-reactjs-js-davinci-sdk` |
| React Native | `ping-sdk-react-native` | placeholder | No stopgap available |
| ForgeRock migration | `forgerock-to-ping-journey-migration` | active | Cross-cutting; takes precedence over platform routing when ForgeRock refs are present |
````

- [ ] **Step 2: Append the probe blocks section**

Append the following to the same file:

````markdown

## Probe Blocks

For every active row in the registry, run that platform's probe. Probes are bounded — depth-limited and ignore generated/dependency directories.

**Common ignore globs (apply to every probe):** `node_modules`, `.git`, `build`, `dist`, `Pods`, `.gradle`, `DerivedData`, `.next`, `out`, `target`.

### Android probe

File markers (any one is sufficient):
```bash
find . -maxdepth 4 \
  \( -name node_modules -o -name .git -o -name build -o -name .gradle -o -name dist -o -name DerivedData -o -name Pods \) -prune -o \
  \( -name "build.gradle" -o -name "build.gradle.kts" -o -name "settings.gradle" -o -name "settings.gradle.kts" -o -name "AndroidManifest.xml" \) -print
```

A non-empty result means Android is detected.

### iOS probe

File markers (any one is sufficient):
```bash
find . -maxdepth 4 \
  \( -name node_modules -o -name .git -o -name build -o -name .gradle -o -name dist -o -name DerivedData -o -name Pods \) -prune -o \
  \( -name "Package.swift" -o -name "*.xcodeproj" -o -name "*.xcworkspace" -o -name "Podfile" \) -print
```

A non-empty result means iOS is detected.

### ForgeRock probe (cross-cutting)

Content markers (any one match in source/build files signals ForgeRock):
```bash
grep -RIl --max-count=1 \
  --exclude-dir={node_modules,.git,build,dist,.gradle,Pods,DerivedData,.next,out,target} \
  -E "forgerock-android-sdk|forgerock-ios-sdk|@forgerock/javascript-sdk|FRAuth|FRSession" .
```

A non-empty result means ForgeRock SDK references exist and the migration path applies.

### Placeholder probes (informational only — do NOT route to these targets)

These probes exist so the router can recognize a JavaScript or React Native project and tell the user that an umbrella skill is on the way. They do not currently route.

**JavaScript (web):** detect a `package.json` with a `react`, `vue`, `angular`, or `vite` dependency.
```bash
test -f package.json && grep -E '"(react|vue|@angular/core|vite)"' package.json
```

**React Native:** detect a `package.json` with `react-native`.
```bash
test -f package.json && grep -E '"react-native"' package.json
```
````

- [ ] **Step 3: Validate the skill still passes structure checks**

Run:
```bash
npx skills-ref validate ./plugins/ping-orchestration-sdks/skills/ping-sdk-router
```
Expected: passes. The skill body grew but structure is unchanged.

- [ ] **Step 4: Commit**

```bash
git add plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md
git commit -m "feat(ping-sdk-router): add platform registry and probe blocks"
```

---

## Task 3: Add the decision tree, routing matrix, and handoff template

**Files:**
- Modify: `plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md` — append the decision logic.

This is the procedural core: the agent reads it top-to-bottom when the skill is invoked. The classify rules use the order from the spec (ForgeRock first, multi-platform second, single platform third, placeholder fourth, nothing fifth).

- [ ] **Step 1: Append the decision tree section**

Append to `plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md`:

````markdown

## Decision Tree

Run these phases in order when this skill is invoked.

### Phase 1: Probe

1. Run the **ForgeRock probe** (always — it's cross-cutting).
2. For each row in the **Platform Registry** with `Status: active` (excluding ForgeRock migration), run that platform's probe.
3. Run the **placeholder probes** for any platform with `Status: placeholder`.
4. Record which probes hit (non-empty output) and which did not.

### Phase 2: Classify

Apply rules in order. **First match wins.**

1. **ForgeRock present + a platform detected** — ForgeRock probe hit AND at least one active platform probe hit. Ask the user the **ForgeRock fork prompt** (see Fallback Prompts). Route to `forgerock-to-ping-journey-migration` if they choose migrate; otherwise route to that platform's umbrella skill. Takes precedence over multi-platform detection because migration is almost always the intent when ForgeRock refs exist.
2. **Multi-platform monorepo** — two or more active platform probes hit (and rule 1 did not fire). Ask the **multi-platform prompt**. Route to the chosen platform's umbrella skill.
3. **Single active platform detected** — exactly one active platform probe hit. Route to that platform's umbrella skill.
4. **Placeholder platform detected** — no active probe hit, but a placeholder probe hit:
   - **JavaScript (web):** announce that `ping-orchestration-javascript-sdk` is on the way. Offer the existing ReactJS specialized skills (`ping-orchestration-reactjs-js-journey-sdk`, `ping-orchestration-reactjs-js-davinci-sdk`) as a stopgap.
   - **React Native:** announce that `ping-sdk-react-native` is on the way. No stopgap exists; ask the user how they would like to proceed.
5. **Nothing detected** — no probes hit. Ask the **no-detection prompt**, listing only platforms with `Status: active`. Mention placeholder platforms as "coming soon".

### Phase 3: Handoff

Print a **single-line summary** in this exact format:
```
Detected <signals> → routing to <skill-name>.
```

Where:
- `<signals>` is a short comma-separated list of what the probes found, e.g. `Android (build.gradle.kts), no ForgeRock refs`.
- `<skill-name>` is the target skill's `name` field exactly as it appears in its frontmatter.

Then **invoke the target skill via the Skill tool**. Do not inline the target skill's content. Do not paraphrase its instructions. Hand off cleanly.
````

- [ ] **Step 2: Append the routing matrix section**

Append to the same file:

````markdown

## Routing Matrix

A compact lookup the agent can match against after Phase 2 classification.

| Probe outcome | Route to |
|---------------|----------|
| ForgeRock + Android | Ask fork prompt → `forgerock-to-ping-journey-migration` OR `ping-orchestration-android-sdk` |
| ForgeRock + iOS | Ask fork prompt → `forgerock-to-ping-journey-migration` OR `ping-orchestration-ios-sdk` |
| Android only | `ping-orchestration-android-sdk` |
| iOS only | `ping-orchestration-ios-sdk` |
| Android + iOS (no ForgeRock) | Ask multi-platform prompt → chosen umbrella |
| JavaScript placeholder hit | Stopgap suggestion (ReactJS specialized skills) |
| React Native placeholder hit | Inform user; no route |
| No probes hit | Ask no-detection prompt → chosen umbrella |
````

- [ ] **Step 3: Append the handoff template section**

Append to the same file:

````markdown

## Handoff Template

Use this exact format for the announcement before invoking the target skill:

```
Detected <signals> → routing to <skill-name>.
```

Examples:
- `Detected Android (build.gradle.kts), no ForgeRock refs → routing to ping-sdk-android.`
- `Detected iOS (Package.swift) + ForgeRock refs (forgerock-ios-sdk in Podfile) → routing to forgerock-to-ping-journey-migration.`
- `Detected Vite/React project, no umbrella skill yet → suggesting ping-orchestration-reactjs-js-journey-sdk as a stopgap.`

After the announcement, invoke the chosen skill via the Skill tool. Do not start doing the work yourself.
````

- [ ] **Step 4: Validate**

Run:
```bash
npx skills-ref validate ./plugins/ping-orchestration-sdks/skills/ping-sdk-router
```
Expected: passes.

- [ ] **Step 5: Commit**

```bash
git add plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md
git commit -m "feat(ping-sdk-router): add decision tree, routing matrix, handoff template"
```

---

## Task 4: Add fallback prompts and the "adding a new platform" recipe

**Files:**
- Modify: `plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md` — append fallback wording and the expansion recipe.

Per the spec self-review there are **four** ask-the-user cases. They each get exact wording so the agent says the same thing every time.

- [ ] **Step 1: Append the fallback prompts section**

Append to `plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md`:

````markdown

## Fallback Prompts

Use these literal prompts when classification calls for a question. Adapt only the bracketed `<…>` placeholders.

### ForgeRock fork prompt

> I see ForgeRock SDK references in this `<platform>` project. Two paths:
>
> 1. **Migrate** the existing ForgeRock code to the Ping Identity Journey SDK (preserves old code as comments, generates a migration report).
> 2. **Build new** Ping SDK functionality alongside the existing code (no migration).
>
> Which would you like to do?

If migrate → route to `forgerock-to-ping-journey-migration`.
If build new → route to the platform's umbrella skill (`ping-orchestration-android-sdk` or `ping-orchestration-ios-sdk`).

### Multi-platform prompt

> I detected more than one platform in this directory (`<list of detected platforms>`). Which one would you like to work on?

Route to the umbrella skill for the chosen platform.

### Placeholder-detected prompt (JavaScript)

> This looks like a `<framework>` project. The umbrella skill `ping-orchestration-javascript-sdk` is on the way but isn't ready yet. In the meantime you can use one of the existing ReactJS specialized skills:
>
> - `ping-orchestration-reactjs-js-journey-sdk` — Journey-based authentication
> - `ping-orchestration-reactjs-js-davinci-sdk` — DaVinci-based authentication
>
> Want me to route to one of those?

### Placeholder-detected prompt (React Native)

> This looks like a React Native project. The umbrella skill `ping-sdk-react-native` is on the way but isn't ready yet, and there is no specialized React Native skill in this repo today. Would you like to wait, or shall I help you with something else?

### No-detection prompt

> I couldn't detect a supported project type in this directory. Which platform are you building for?
>
> - **Android** (`ping-orchestration-android-sdk`)
> - **iOS** (`ping-orchestration-ios-sdk`)
> - **JavaScript / Web** — coming soon (`ping-orchestration-javascript-sdk`)
> - **React Native** — coming soon (`ping-sdk-react-native`)

Route to the chosen umbrella skill (or apply the placeholder prompt for JS / RN).
````

- [ ] **Step 2: Append the "adding a new platform" recipe section**

Append to the same file:

````markdown

## Adding a New Platform

When a new umbrella skill ships (e.g., `ping-orchestration-javascript-sdk`), a single contributor edit enables routing for it. Steps:

1. **Update the registry row** in the **Platform Registry** table: change `Status` from `placeholder` to `active`. If the target skill name changed, update that too.
2. **Add or fill in the probe block** in the **Probe Blocks** section. Provide either file markers (a `find` command) or content markers (a `grep` command) that uniquely identify projects of this type. Apply the common ignore globs.
3. **(Optional) Update fallback prompts** if the platform's user-visible name should change.

The decision tree, routing matrix, and handoff template do **not** need to be edited. They reference the registry by `Status`, so they pick up the new platform automatically.

To **remove** a platform: change its row's `Status` to `placeholder` (keeps the row visible but disables routing).

## Non-Goals

This skill does NOT do any of the following — those are the responsibility of the target skills:

- Scaffold projects, generate code, or write SDK configuration.
- Cache detection results between runs.
- Detect framework variants beyond what's in the registry (KMP, Flutter, Tauri, Electron, etc.).
- Modify any file in the user's project.
- Route to the 6 platform×SDK skills (`ping-orchestration-{android,ios,reactjs-js}-{journey,davinci}-sdk`) — they are reachable as stopgaps for the JavaScript placeholder, but the router treats them as out-of-scope routing targets otherwise.
````

- [ ] **Step 3: Validate**

Run:
```bash
npx skills-ref validate ./plugins/ping-orchestration-sdks/skills/ping-sdk-router
```
Expected: passes.

- [ ] **Step 4: Verify SKILL.md is under the 500-line guideline**

Run:
```bash
wc -l plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md
```
Expected: under 500 lines (target was under 200; allow some slack but flag if it exceeds 500).

- [ ] **Step 5: Commit**

```bash
git add plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md
git commit -m "feat(ping-sdk-router): add fallback prompts and expansion recipe"
```

---

## Task 5: Smoke-test the probe commands against fixture directories

**Files:**
- No files modified or committed. This task verifies the probe commands work in three project shapes. Fixtures are created in `/tmp/` and discarded.

The router's probes are shell commands embedded in markdown. They have to actually work. This task runs each probe against three throwaway fixture directories and confirms the expected outcomes.

- [ ] **Step 1: Create the empty fixture**

Run:
```bash
mkdir -p /tmp/ping-router-fixture-empty
cd /tmp/ping-router-fixture-empty
```

- [ ] **Step 2: Run the Android probe in the empty fixture**

Run:
```bash
cd /tmp/ping-router-fixture-empty && find . -maxdepth 4 \
  \( -name node_modules -o -name .git -o -name build -o -name .gradle -o -name dist -o -name DerivedData -o -name Pods \) -prune -o \
  \( -name "build.gradle" -o -name "build.gradle.kts" -o -name "settings.gradle" -o -name "settings.gradle.kts" -o -name "AndroidManifest.xml" \) -print
```
Expected: empty output (no Android markers).

- [ ] **Step 3: Run the iOS probe in the empty fixture**

Run:
```bash
cd /tmp/ping-router-fixture-empty && find . -maxdepth 4 \
  \( -name node_modules -o -name .git -o -name build -o -name .gradle -o -name dist -o -name DerivedData -o -name Pods \) -prune -o \
  \( -name "Package.swift" -o -name "*.xcodeproj" -o -name "*.xcworkspace" -o -name "Podfile" \) -print
```
Expected: empty output.

- [ ] **Step 4: Run the ForgeRock probe in the empty fixture**

Run:
```bash
cd /tmp/ping-router-fixture-empty && grep -RIl --max-count=1 \
  --exclude-dir={node_modules,.git,build,dist,.gradle,Pods,DerivedData,.next,out,target} \
  -E "forgerock-android-sdk|forgerock-ios-sdk|@forgerock/javascript-sdk|FRAuth|FRSession" .
```
Expected: empty output. (Classification: rule 5 "Nothing detected" → no-detection prompt.)

- [ ] **Step 5: Create the Android fixture**

Run:
```bash
mkdir -p /tmp/ping-router-fixture-android/app
cd /tmp/ping-router-fixture-android
printf 'plugins {\n    id("com.android.application")\n}\n' > build.gradle.kts
printf 'rootProject.name = "demo"\n' > settings.gradle.kts
printf '<manifest package="com.demo"/>\n' > app/AndroidManifest.xml
```

- [ ] **Step 6: Run the Android probe in the Android fixture**

Run:
```bash
cd /tmp/ping-router-fixture-android && find . -maxdepth 4 \
  \( -name node_modules -o -name .git -o -name build -o -name .gradle -o -name dist -o -name DerivedData -o -name Pods \) -prune -o \
  \( -name "build.gradle" -o -name "build.gradle.kts" -o -name "settings.gradle" -o -name "settings.gradle.kts" -o -name "AndroidManifest.xml" \) -print
```
Expected: lists `./build.gradle.kts`, `./settings.gradle.kts`, `./app/AndroidManifest.xml`.

- [ ] **Step 7: Run the iOS probe in the Android fixture**

Run:
```bash
cd /tmp/ping-router-fixture-android && find . -maxdepth 4 \
  \( -name node_modules -o -name .git -o -name build -o -name .gradle -o -name dist -o -name DerivedData -o -name Pods \) -prune -o \
  \( -name "Package.swift" -o -name "*.xcodeproj" -o -name "*.xcworkspace" -o -name "Podfile" \) -print
```
Expected: empty output. (Classification: rule 3 "Single active platform detected" → route to `ping-orchestration-android-sdk`.)

- [ ] **Step 8: Create the Swift Package fixture with ForgeRock refs**

Run:
```bash
mkdir -p /tmp/ping-router-fixture-ios-fr/Sources/Demo
cd /tmp/ping-router-fixture-ios-fr
printf '// swift-tools-version:5.9\nimport PackageDescription\nlet package = Package(name: "Demo")\n' > Package.swift
printf 'import Foundation\nimport FRAuth\nfunc demo() { _ = FRSession.currentSession }\n' > Sources/Demo/Demo.swift
```

- [ ] **Step 9: Run the iOS probe in the iOS+ForgeRock fixture**

Run:
```bash
cd /tmp/ping-router-fixture-ios-fr && find . -maxdepth 4 \
  \( -name node_modules -o -name .git -o -name build -o -name .gradle -o -name dist -o -name DerivedData -o -name Pods \) -prune -o \
  \( -name "Package.swift" -o -name "*.xcodeproj" -o -name "*.xcworkspace" -o -name "Podfile" \) -print
```
Expected: lists `./Package.swift`.

- [ ] **Step 10: Run the ForgeRock probe in the iOS+ForgeRock fixture**

Run:
```bash
cd /tmp/ping-router-fixture-ios-fr && grep -RIl --max-count=1 \
  --exclude-dir={node_modules,.git,build,dist,.gradle,Pods,DerivedData,.next,out,target} \
  -E "forgerock-android-sdk|forgerock-ios-sdk|@forgerock/javascript-sdk|FRAuth|FRSession" .
```
Expected: lists `./Sources/Demo/Demo.swift`. (Classification: rule 1 "ForgeRock + platform" → ForgeRock fork prompt.)

- [ ] **Step 11: Clean up fixtures**

Run:
```bash
rm -rf /tmp/ping-router-fixture-empty /tmp/ping-router-fixture-android /tmp/ping-router-fixture-ios-fr
```

If any probe in steps 2–10 produced an outcome different from expected, **stop and fix the probe command in `SKILL.md` (Task 2)** before continuing. Each probe must classify cleanly. Re-run steps 5–10 after any fix.

- [ ] **Step 12: No commit**

This task validates behavior; no files changed. Do not run `git commit`.

---

## Task 6: Update README tables in both root and plugin

**Files:**
- Modify: `README.md` — add a new "Routing Skills" subsection under "Available Skills".
- Modify: `plugins/ping-orchestration-sdks/README.md` — add a parallel "Routing Skills" section.

The repo's `skill-readme-documentation` lint rule requires every skill to appear in both README tables. The existing tables have "SDK Integration Skills" and "Migration Skills" sections — the router fits neither, so we add a third.

- [ ] **Step 1: Add the Routing Skills section to the root README**

Open `README.md` and find this line near line 105:

```markdown
### Migration Skills ([ping-orchestration-sdks](./plugins/ping-orchestration-sdks/) plugin)
```

Insert this block **immediately before** that line (so the order is: SDK Integration → Routing → Migration):

```markdown
### Routing Skills ([ping-orchestration-sdks](./plugins/ping-orchestration-sdks/) plugin)

| Skill | Description |
|-------|-------------|
| [ping-sdk-router](./plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md) | First point of contact for vague Ping SDK requests — probes the working directory, detects platform (Android, iOS; JavaScript and React Native on the roadmap) and ForgeRock SDK references, then routes to the matching umbrella skill or to `forgerock-to-ping-journey-migration` |

```

- [ ] **Step 2: Add the Routing Skills section to the plugin README**

Open `plugins/ping-orchestration-sdks/README.md` and find this line near line 75:

```markdown
### Migration Skills
```

Insert this block **immediately before** that line:

```markdown
### Routing Skills

| Skill | Description | Documentation |
|-------|-------------|---------------|
| [ping-sdk-router](skills/ping-sdk-router) | First point of contact for vague Ping SDK requests. Probes the user's working directory for Android, iOS, JavaScript, or React Native projects (and ForgeRock SDK references), asks if ambiguous, and routes to the matching umbrella skill (`ping-orchestration-android-sdk`, `ping-orchestration-ios-sdk`; `ping-orchestration-javascript-sdk` and `ping-sdk-react-native` on the roadmap) or to `forgerock-to-ping-journey-migration`. Designed for easy expansion via a platform registry. | [SKILL.md](skills/ping-orchestration-sdk-router/SKILL.md) |

```

- [ ] **Step 3: Verify both READMEs render correctly**

Run:
```bash
grep -n "ping-sdk-router" README.md plugins/ping-orchestration-sdks/README.md
```
Expected: both files contain at least one `ping-orchestration-sdk-router` reference.

- [ ] **Step 4: Run the full lint suite**

Run:
```bash
claudelint .
```
Expected: passes. The `skill-readme-documentation` rule should now be satisfied for `ping-orchestration-sdk-router`. If `claudelint` is unavailable, skip and rely on Task 7 manual review.

- [ ] **Step 5: Commit**

```bash
git add README.md plugins/ping-orchestration-sdks/README.md
git commit -m "docs(ping-sdk-router): add Routing Skills sections to root and plugin READMEs"
```

---

## Task 7: Final validation pass

**Files:**
- No files modified.

A last pre-PR check that everything ties together: validator, lint, frontmatter sanity, file structure.

- [ ] **Step 1: Run the validator one last time**

Run:
```bash
npx skills-ref validate ./plugins/ping-orchestration-sdks/skills/ping-sdk-router
```
Expected: passes.

- [ ] **Step 2: Run claudelint across the repo**

Run:
```bash
claudelint .
```
Expected: no errors related to `ping-orchestration-sdk-router`. If any pre-existing errors exist for unrelated skills, leave them alone — they are out of scope for this plan.

- [ ] **Step 3: Confirm the skill directory contains only SKILL.md**

Run:
```bash
ls -la plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/
```
Expected: only `SKILL.md` (and `.` / `..`). No `assets/`, `references/`, `scripts/`, or stray files.

- [ ] **Step 4: Confirm the frontmatter `name` matches the directory**

Run:
```bash
head -3 plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md
```
Expected: line 2 is `name: ping-sdk-router` (matches the directory name exactly).

- [ ] **Step 5: Confirm both READMEs were updated**

Run:
```bash
grep -c "ping-sdk-router" README.md plugins/ping-orchestration-sdks/README.md
```
Expected: each file returns at least 1.

- [ ] **Step 6: Review the git log for this feature branch**

Run:
```bash
git log --oneline focused-repo-skills..HEAD
```
Expected: a clean series of commits scoped to `ping-orchestration-sdk-router` and the README updates. Each commit message should make sense on its own.

If everything passes, the implementation is complete and ready for the user to review.

- [ ] **Step 7: No commit**

Final-check task; nothing to commit.

---

## Self-Review Notes

After writing this plan I reviewed it against the spec. Findings:

**Spec coverage check:**
- ✅ Frontmatter / triggering model → Task 1
- ✅ Routing scope (umbrellas + migration) → Task 2 registry
- ✅ Decision flow (probe → classify → handoff) → Tasks 2 + 3
- ✅ Platform registry + expansion mechanism → Task 2 + Task 4 recipe
- ✅ File layout (single SKILL.md) → Task 1, verified Task 7
- ✅ SKILL.md body outline (9 sections) → Tasks 1–4 cover all 9
- ✅ Validation (`skills-ref validate`, `claudelint`) → Tasks 1, 3, 6, 7
- ✅ README updates → Task 6
- ✅ Out-of-scope items → "Non-Goals" section in Task 4
- ✅ Provisioning for `ping-orchestration-javascript-sdk` and `ping-sdk-react-native` → registry rows + placeholder probes + fallback prompts (Tasks 2 + 4)

**Placeholder scan:** none.

**Type/name consistency:** target skill names (`ping-orchestration-android-sdk`, `ping-orchestration-ios-sdk`, `ping-orchestration-javascript-sdk`, `ping-sdk-react-native`, `forgerock-to-ping-journey-migration`) appear identically across registry, decision tree, routing matrix, fallback prompts, and READMEs.

**Gaps / deferred:**
- Behavioral testing relies on manual smoke tests (Task 5) since the artifact is markdown — no automated test framework applies. This matches the spec's validation strategy.
- A future improvement (out of scope) would be a JSON-driven registry + a `scripts/probe.sh` helper if the registry grows beyond ~6 platforms; the spec explicitly chose Approach A (pure markdown).
