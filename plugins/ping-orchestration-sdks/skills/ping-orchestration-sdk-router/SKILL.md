---
name: ping-orchestration-sdk-router
description: >-
  Use when a user asks for help with Ping Identity SDK, ForgeRock SDK, or Ping
  Orchestration SDK integration without specifying a platform — phrases like
  "help me add Ping auth", "I want to use PingOne", "get started with the Ping
  Orchestration SDK", "add Ping login to my app", "integrate the ForgeRock
  SDK", "use the pingidentity SDK". Probes the project to detect Android, iOS,
  JavaScript, or React Native, asks if ambiguous, and routes to the matching
  umbrella skill
  (ping-orchestration-android-sdk, ping-orchestration-ios-sdk,
  ping-orchestration-javascript-sdk, ping-orchestration-react-native-sdk) or to
  forgerock-to-ping-journey-migration when ForgeRock SDK references are
  present (forgerock-android-sdk, forgerock-ios-sdk, @forgerock/javascript-sdk).
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---

# Ping SDK Router

First point of contact for vague Ping Identity SDK requests. Probes the working directory to detect platform (Android, iOS, JavaScript, React Native) and ForgeRock SDK references, then hands off to the most suitable umbrella skill in this plugin. New platforms are added by editing one row in the platform registry below — the decision tree picks them up automatically.

## Platform Registry

This table is the single source of truth for routing. The decision tree below references it by `Status`. To add a new platform, change its status from `placeholder` to `active`, add a probe block, and you are done.

| Platform | Target Skill | Status | Notes |
|----------|--------------|--------|-------|
| Android | `ping-orchestration-android-sdk` | active | — |
| iOS | `ping-orchestration-ios-sdk` | active | — |
| JavaScript (web) | `ping-orchestration-javascript-sdk` | active | — |
| React Native | `ping-orchestration-react-native-sdk` | active | — |
| ForgeRock migration | `forgerock-to-ping-journey-migration` | active | Cross-cutting; takes precedence over platform routing when ForgeRock refs are present |

## Probe Blocks

For every active row in the registry, run that platform's probe. Probes are bounded — depth-limited and ignore generated/dependency directories.

**Common ignore globs (apply to every probe):** `node_modules`, `.git`, `build`, `dist`, `Pods`, `.gradle`, `DerivedData`, `.next`, `out`, `target`.

### Android probe

File markers (any one is sufficient):
```bash
find . -maxdepth 4 \
  \( -name node_modules -o -name .git -o -name build -o -name dist -o -name Pods -o -name .gradle -o -name DerivedData -o -name .next -o -name out -o -name target \) -prune -o \
  \( -name "build.gradle" -o -name "build.gradle.kts" -o -name "settings.gradle" -o -name "settings.gradle.kts" -o -name "AndroidManifest.xml" \) -print
```

A non-empty result means Android is detected.

### iOS probe

File markers (any one is sufficient):
```bash
find . -maxdepth 4 \
  \( -name node_modules -o -name .git -o -name build -o -name dist -o -name Pods -o -name .gradle -o -name DerivedData -o -name .next -o -name out -o -name target \) -prune -o \
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

### JavaScript (web) probe

File/content markers (any one is sufficient):
```bash
find . -maxdepth 4 \
  \( -name node_modules -o -name .git -o -name build -o -name dist -o -name Pods -o -name .gradle -o -name DerivedData -o -name .next -o -name out -o -name target \) -prune -o \
  -name "package.json" -exec grep -l '"react"\|"vue"\|"@angular/core"\|"vite"' {} \; 2>/dev/null
```

A non-empty result means a JavaScript (web) project is detected.

### React Native probe

File/content markers (any one is sufficient):
```bash
test -f package.json && grep -qE '"react-native"[[:space:]]*:' package.json && echo "react-native detected"
```

A non-empty result means a React Native project is detected.

## Decision Tree

Run these phases in order when this skill is invoked.

### Phase 1: Probe

1. Run the **ForgeRock probe** (always — it's cross-cutting).
2. For each row in the **Platform Registry** with `Status: active` (excluding ForgeRock migration), run that platform's probe.
3. Record which probes hit (non-empty output) and which did not.

### Phase 2: Classify

Apply rules in order. **First match wins.**

1. **ForgeRock present + a platform detected** — ForgeRock probe hit AND at least one active platform probe hit.
   - If **exactly one** platform probe hit: ask the **ForgeRock fork prompt** (see Fallback Prompts) using that platform name. Route to `forgerock-to-ping-journey-migration` if they choose migrate; otherwise route to that platform's umbrella skill.
   - If **two or more** platform probes hit: ask the **multi-platform prompt** first (listing only the detected platforms), then ask the **ForgeRock fork prompt** for the chosen platform. This ensures the migration targets the right codebase.
   - Takes precedence over plain multi-platform detection because migration is almost always the intent when ForgeRock refs exist.
2. **Multi-platform monorepo** — two or more active platform probes hit (and rule 1 did not fire). Ask the **multi-platform prompt**. Route to the chosen platform's umbrella skill.
3. **Single active platform detected** — exactly one active platform probe hit. Route to that platform's umbrella skill.
4. **React Native detected (single platform)** — React Native probe hit and no other active platform probe hit. Route to `ping-orchestration-react-native-sdk`.
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

## Routing Matrix

A compact lookup the agent can match against after Phase 2 classification.

| Probe outcome | Route to |
|---------------|----------|
| ForgeRock + Android only | Ask fork prompt → `forgerock-to-ping-journey-migration` OR `ping-orchestration-android-sdk` |
| ForgeRock + iOS only | Ask fork prompt → `forgerock-to-ping-journey-migration` OR `ping-orchestration-ios-sdk` |
| ForgeRock + JavaScript only | Ask fork prompt → `forgerock-to-ping-journey-migration` OR `ping-orchestration-javascript-sdk` |
| ForgeRock + Android + iOS | Ask multi-platform prompt → then fork prompt for chosen platform |
| ForgeRock + Android + JavaScript | Ask multi-platform prompt → then fork prompt for chosen platform |
| ForgeRock + iOS + JavaScript | Ask multi-platform prompt → then fork prompt for chosen platform |
| ForgeRock + Android + iOS + JavaScript | Ask multi-platform prompt → then fork prompt for chosen platform |
| Android only | `ping-orchestration-android-sdk` |
| iOS only | `ping-orchestration-ios-sdk` |
| JavaScript (web) only | `ping-orchestration-javascript-sdk` |
| Android + iOS (no ForgeRock) | Ask multi-platform prompt → chosen umbrella |
| Android + JavaScript (no ForgeRock) | Ask multi-platform prompt → chosen umbrella |
| iOS + JavaScript (no ForgeRock) | Ask multi-platform prompt → chosen umbrella |
| React Native only | `ping-orchestration-react-native-sdk` |
| React Native + JavaScript (no ForgeRock) | Ask multi-platform prompt → chosen umbrella |
| No probes hit | Ask no-detection prompt → chosen umbrella |

## Handoff Template

Use this exact format for the announcement before invoking the target skill:

```
Detected <signals> → routing to <skill-name>.
```

Examples:
- `Detected Android (build.gradle.kts), no ForgeRock refs → routing to ping-orchestration-android-sdk.`
- `Detected iOS (Package.swift) + ForgeRock refs (forgerock-ios-sdk in Podfile) → routing to forgerock-to-ping-journey-migration.`
- `Detected React/Vite project (package.json), no ForgeRock refs → routing to ping-orchestration-javascript-sdk.`

After the announcement, invoke the chosen skill via the Skill tool. Do not start doing the work yourself.

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
If build new → route to the platform's umbrella skill (`ping-orchestration-android-sdk`, `ping-orchestration-ios-sdk`, or `ping-orchestration-javascript-sdk`).

### Multi-platform prompt

> I detected more than one platform in this directory (`<list of detected platforms>`). Which one would you like to work on?

Route to the umbrella skill for the chosen platform.

### Active route for JavaScript

JavaScript is now an active platform. When the JavaScript probe hits, print the handoff line and invoke `ping-orchestration-javascript-sdk` via the Skill tool — no prompt needed unless ambiguity requires it (e.g., ForgeRock refs also present).

### No-detection prompt

> I couldn't detect a supported project type in this directory. Which platform are you building for?
>
> - **Android** (`ping-orchestration-android-sdk`)
> - **iOS** (`ping-orchestration-ios-sdk`)
> - **JavaScript / Web** (`ping-orchestration-javascript-sdk`)
> - **React Native** (`ping-orchestration-react-native-sdk`)

Route to the chosen umbrella skill.

## Adding a New Platform

When a new umbrella skill ships (e.g., `ping-orchestration-react-native-sdk`), a single contributor edit enables routing for it. Steps:

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
- Route to the 6 platform×SDK skills (`ping-orchestration-{android,ios,reactjs}-{journey,davinci}-sdk`) — they are reachable as stopgaps for the JavaScript placeholder, but the router treats them as out-of-scope routing targets otherwise.
