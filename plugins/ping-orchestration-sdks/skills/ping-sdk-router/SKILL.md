---
name: ping-sdk-router
description: >-
  Use when a user asks for help with Ping Identity SDK integration without
  specifying a platform — phrases like "help me add Ping auth", "I want to use
  PingOne", "get started with the Ping SDK". Probes the project to detect
  Android, iOS, JavaScript, or React Native, asks if ambiguous, and routes to
  the matching umbrella skill (ping-sdk-android, ping-sdk-ios, ping-sdk-js;
  ping-sdk-react-native on the roadmap) or to forgerock-to-ping-journey-migration
  when ForgeRock SDK references are present.
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
| Android | `ping-sdk-android` | active | — |
| iOS | `ping-sdk-ios` | active | — |
| JavaScript (web) | `ping-sdk-js` | active | — |
| React Native | `ping-sdk-react-native` | placeholder | No stopgap available |
| ForgeRock migration | `forgerock-to-ping-journey-migration` | active | Cross-cutting; takes precedence over platform routing when ForgeRock refs are present |

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

### JavaScript (web) probe

File/content markers (any one is sufficient):
```bash
find . -maxdepth 4 \
  \( -name node_modules -o -name .git -o -name build -o -name dist -o -name .next -o -name out \) -prune -o \
  -name "package.json" -print | head -5 | xargs grep -l '"react"\|"vue"\|"@angular/core"\|"vite"' 2>/dev/null
```

A non-empty result means a JavaScript (web) project is detected.

### Placeholder probes (informational only — do NOT route to these targets)

These probes exist so the router can recognize a React Native project and tell the user that an umbrella skill is on the way. They do not currently route.

**React Native:** detect a `package.json` with `react-native`.
```bash
test -f package.json && grep -E '"react-native"' package.json
```

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

## Routing Matrix

A compact lookup the agent can match against after Phase 2 classification.

| Probe outcome | Route to |
|---------------|----------|
| ForgeRock + Android | Ask fork prompt → `forgerock-to-ping-journey-migration` OR `ping-sdk-android` |
| ForgeRock + iOS | Ask fork prompt → `forgerock-to-ping-journey-migration` OR `ping-sdk-ios` |
| Android only | `ping-sdk-android` |
| iOS only | `ping-sdk-ios` |
| Android + iOS (no ForgeRock) | Ask multi-platform prompt → chosen umbrella |
| JavaScript (web) only | `ping-sdk-js` |
| ForgeRock + JavaScript | Ask fork prompt → `forgerock-to-ping-journey-migration` OR `ping-sdk-js` |
| React Native placeholder hit | Inform user; no route |
| No probes hit | Ask no-detection prompt → chosen umbrella |

## Handoff Template

Use this exact format for the announcement before invoking the target skill:

```
Detected <signals> → routing to <skill-name>.
```

Examples:
- `Detected Android (build.gradle.kts), no ForgeRock refs → routing to ping-sdk-android.`
- `Detected iOS (Package.swift) + ForgeRock refs (forgerock-ios-sdk in Podfile) → routing to forgerock-to-ping-journey-migration.`
- `Detected React/Vite project (package.json), no ForgeRock refs → routing to ping-sdk-js.`

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
If build new → route to the platform's umbrella skill (`ping-sdk-android`, `ping-sdk-ios`, or `ping-sdk-js`).

### Multi-platform prompt

> I detected more than one platform in this directory (`<list of detected platforms>`). Which one would you like to work on?

Route to the umbrella skill for the chosen platform.

### Active route for JavaScript

JavaScript is now an active platform. When the JavaScript probe hits, print the handoff line and invoke `ping-sdk-js` via the Skill tool — no prompt needed unless ambiguity requires it (e.g., ForgeRock refs also present).

### Placeholder-detected prompt (React Native)

> This looks like a React Native project. The umbrella skill `ping-sdk-react-native` is on the way but isn't ready yet, and there is no specialized React Native skill in this repo today. Would you like to wait, or shall I help you with something else?

### No-detection prompt

> I couldn't detect a supported project type in this directory. Which platform are you building for?
>
> - **Android** (`ping-sdk-android`)
> - **iOS** (`ping-sdk-ios`)
> - **JavaScript / Web** (`ping-sdk-js`)
> - **React Native** — coming soon (`ping-sdk-react-native`)

Route to the chosen umbrella skill (or apply the placeholder prompt for JS / RN).

## Adding a New Platform

When a new umbrella skill ships (e.g., `ping-sdk-react-native`), a single contributor edit enables routing for it. Steps:

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
