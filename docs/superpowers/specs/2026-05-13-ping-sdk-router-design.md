# ping-sdk-router — Design

**Status:** Draft
**Date:** 2026-05-13
**Skill path:** `plugins/ping-orchestration-sdks/skills/ping-sdk-router/`

## Goal

A router skill that acts as the first point of contact for vague Ping Identity SDK requests. It probes the user's project, picks the most suitable specialized skill in this repo, and hands off to it. Designed for expansion: new platform umbrella skills (JS, React Native) drop in as registry rows without rewriting the router.

## Why

Today the repo has multiple skills that overlap on intent ("add Ping auth"). When a user says "help me add PingOne login", the agent has to disambiguate between Android, iOS, ReactJS, and migration variants. The router moves that disambiguation into one well-documented place that uses the project's actual file layout to make the call, rather than asking the user to know which skill to invoke.

## Triggering model

The frontmatter `description` is tuned for **vague Ping queries only**. Examples that should match:

- "Help me add Ping authentication"
- "I want to use PingOne in my app"
- "Add Ping login"
- "How do I get started with the Ping SDK?"

Examples that should NOT match (specialized skill wins):

- "Add Ping auth to my iOS app" → `ping-sdk-ios`
- "Set up DaVinci in Android with Compose" → `ping-orchestration-android-davinci-sdk`
- "Migrate FRAuth to Ping" → `forgerock-to-ping-journey-migration`

The router gets primacy only when the user's prompt does not name a platform or SDK. Specialized skill descriptions are more specific and outrank it when the choice is obvious.

## Routing scope

The router selects among the **umbrella skills + migration** only:

| Platform | Target skill | Status |
|----------|--------------|--------|
| Android | `ping-sdk-android` | active |
| iOS | `ping-sdk-ios` | active |
| JavaScript (web) | `ping-sdk-js` *(planned)* | placeholder |
| React Native | `ping-sdk-react-native` *(planned)* | placeholder |
| ForgeRock migration | `forgerock-to-ping-journey-migration` | active (cross-cutting) |

The 6 platform×SDK skills (`ping-orchestration-{android,ios,reactjs-js}-{journey,davinci}-sdk`) are **not** routing targets. The umbrella skills cover the same ground at a higher level.

## Decision flow

The router runs three phases: **probe → classify → handoff.**

### 1. Probe

Run a bounded scan of the working directory. The router reads from a **platform registry** (defined in the SKILL.md body) and runs the marker checks for every row whose `status` is `active`. Probes use tools the agent already has — `find`, `grep`, `test`, `Read`. Depth-limited; ignores `node_modules`, `.git`, `build/`, `dist/`, `Pods/`, `.gradle/`.

Marker shape per platform (in registry):

- **File markers:** filename globs that signal the platform (e.g., `build.gradle*`, `*.xcodeproj`)
- **Content markers:** grep patterns for ForgeRock SDK refs and platform-specific imports
- **Status:** `active` (probe runs, routing enabled) or `placeholder` (router knows the platform exists, names it in fallback messages, but doesn't probe or route)

### 2. Classify

Apply rules in order. First match wins:

1. **ForgeRock present + platform detected** — ask the user: "build new on the Ping SDK or migrate the existing ForgeRock code?" Route to the platform umbrella or to `forgerock-to-ping-journey-migration`. Takes precedence over multi-platform detection because migration is almost always the user's intent when ForgeRock SDK refs exist.
2. **Multi-platform monorepo** — if probes for two or more `active` platforms hit (and rule 1 didn't fire), ask the user which to target.
3. **Single active platform detected** — route to that platform's umbrella skill.
4. **Placeholder platform detected** — handle per-platform:
   - **JavaScript (web)**: say `ping-sdk-js` is on the way; offer the two existing ReactJS specialized skills (`ping-orchestration-reactjs-js-journey-sdk`, `ping-orchestration-reactjs-js-davinci-sdk`) as a stopgap.
   - **React Native**: say `ping-sdk-react-native` is on the way; no stopgap exists.
5. **Nothing detected** — ask "Which platform are you building for?" listing only `active` platforms; mention placeholders as "coming soon".

### 3. Handoff

Print a single-line summary: `Detected <signals> → routing to <skill>.` Then invoke the target skill via the Skill tool. The target skill takes over in the same turn.

## Platform registry — expansion mechanism

The registry is the only thing that changes when a new umbrella skill is added. It lives near the top of the SKILL.md body as a markdown table plus per-platform "probe block" snippets below it.

**To add a new platform** (e.g., when `ping-sdk-js` ships):

1. Update the registry row: change `status: placeholder` → `status: active`.
2. Add or fill in the probe block (file markers + grep patterns).
3. (Optional) Update the fallback wording if the platform's name should appear differently to users.

No changes to the decision tree or handoff logic. The decision tree is written in terms of "active rows in the registry", so it picks up new platforms automatically.

## File layout

```
plugins/ping-orchestration-sdks/skills/ping-sdk-router/
└── SKILL.md
```

No `assets/`, `references/`, or `scripts/`. Detection logic is short enough to live inline. Aligns with Approach A (pure-markdown router) and the repo's "keep SKILL.md under 500 lines" guideline — target length is under 200 lines.

## SKILL.md body outline

In order:

1. **One-paragraph overview** — what the router does, what it routes among.
2. **Platform registry** — the table from above, with `Status` column driving the decision tree.
3. **Probe blocks** — per `active` platform: exact `find`/`grep` commands, depth limits, ignore globs.
4. **Decision tree** — numbered, top-to-bottom; references the registry by status.
5. **Routing matrix** — explicit "if X then Y" rules so the agent can match detection results to a skill.
6. **Handoff template** — literal one-line announcement format.
7. **Fallback prompts** — exact wording for the four ask-the-user cases (ForgeRock + platform, multi-platform, placeholder detected, no detection).
8. **Adding a new platform** — 3-step recipe for future contributors.
9. **What this skill does NOT do** — explicit non-goals: no scaffolding, no SDK config, no code generation, no caching, no framework auto-detection beyond the registry.

## Frontmatter

```yaml
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
```

## Validation

- `npx skills-ref validate ./plugins/ping-orchestration-sdks/skills/ping-sdk-router` for schema/structure.
- `claudelint .` for the repo's custom rules (`skill-directory-structure`, `skill-readme-documentation`, `skill-required-metadata`).
- Manual smoke test in three project shapes: empty dir, Android Gradle project, Swift Package — verify detection and handoff.

## README updates

Add the router to a new "Routing Skills" section in both:

- `README.md` (root)
- `plugins/ping-orchestration-sdks/README.md`

Required by the `skill-readme-documentation` lint rule.

## Out of scope

- Routing for the 6 platform×SDK skills (router only targets umbrellas + migration).
- Caching detection results between runs.
- Detecting framework variants beyond what's in the registry (KMP, Flutter, etc.).
- Modifying any existing skill.
- Building the `ping-sdk-js` or `ping-sdk-react-native` skills themselves — the router only provisions for them.
