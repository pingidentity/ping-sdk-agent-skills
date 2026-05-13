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

## Platform Registry

This table is the single source of truth for routing. The decision tree below references it by `Status`. To add a new platform, change its status from `placeholder` to `active`, add a probe block, and you are done.

| Platform | Target Skill | Status | Notes |
|----------|--------------|--------|-------|
| Android | `ping-sdk-android` | active | — |
| iOS | `ping-sdk-ios` | active | — |
| JavaScript (web) | `ping-sdk-js` | placeholder | Stopgap: `ping-orchestration-reactjs-js-journey-sdk`, `ping-orchestration-reactjs-js-davinci-sdk` |
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
