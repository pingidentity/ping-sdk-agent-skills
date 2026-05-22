# ping-sdk-js — Design

**Status:** Draft
**Date:** 2026-05-13
**Skill path:** `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/`

## Goal

A JavaScript umbrella skill that acts as the single entry point for building web apps with the Ping Orchestration JavaScript SDK (`@forgerock/*` packages). It collects shared configuration, provides common setup guidance, delegates Journey and DaVinci flows to existing specialized ReactJS skills, and handles OIDC centralized login inline.

## Why

The repo already has two React-specific skills (`ping-orchestration-reactjs-js-journey-sdk`, `ping-orchestration-reactjs-js-davinci-sdk`) but no umbrella that:
- Unifies the entry point for vague JS/web requests
- Covers OIDC centralized login (not in either specialized skill)
- Provisions the `ping-orchestration-sdk-router` JS platform slot (currently `placeholder`)
- Provides the shared layer (project setup, env vars, package selection, common pitfalls) so delegates can focus on flow-specific work

This mirrors the role `ping-orchestration-ios-sdk` plays for iOS — one skill to start from, regardless of which flow you need.

## Triggering model

The frontmatter `description` is tuned for **vague JS/web Ping queries**. Examples that should match:

- "Add Ping authentication to my web app"
- "Use PingOne in React"
- "Set up Journey in JavaScript"
- "Build a Ping login page"
- "How do I integrate the Ping JS SDK?"

Examples that should NOT match (specialized skill wins):

- "Add Journey callbacks to my React app" → `ping-orchestration-reactjs-js-journey-sdk`
- "Set up DaVinci collectors in React" → `ping-orchestration-reactjs-js-davinci-sdk`
- "Migrate my ForgeRock JS SDK to Ping" → `forgerock-to-ping-journey-migration`

## Architecture

### Relationship to existing skills

The umbrella **wraps and delegates** — it does not replace the existing specialized ReactJS skills:

| Flow | Handling |
|------|----------|
| Journey (PingAM/AIC) | Shared config → delegate to `ping-orchestration-reactjs-js-journey-sdk` |
| DaVinci (PingOne) | Shared config → delegate to `ping-orchestration-reactjs-js-davinci-sdk` |
| OIDC centralized login | Handled inline by umbrella (own reference doc + templates) |

The two existing specialized skills remain independently invocable. The umbrella adds a unified entry point on top of them.

### Framework registry

Same expansion pattern as `ping-orchestration-sdk-router`'s platform registry. One row per framework; `status` drives the decision tree.

| Framework | Journey delegate | DaVinci delegate | Status | Notes |
|-----------|-----------------|-----------------|--------|-------|
| React | `ping-orchestration-reactjs-js-journey-sdk` | `ping-orchestration-reactjs-js-davinci-sdk` | active | — |
| Angular | — | — | placeholder | No delegate skills yet |
| Vue | — | — | placeholder | No delegate skills yet |
| Vanilla JS | — | — | placeholder | No delegate skills yet |

To add a new framework: change its row to `active`, add delegate skill names, and fill in probe instructions. No other changes needed.

## Wizard flow

The skill runs a three-step wizard before delegating or generating.

### W1 — Intent (flow type)

Ask:
> Which flow are you building?
> 1. **Journey** — callback-based auth against PingAM or PingOne AIC
> 2. **DaVinci** — collector-based auth against PingOne DaVinci
> 3. **OIDC centralized login** — OAuth2/OIDC authorization code flow (browser redirect)

### W1b — Framework detection

Before collecting config, detect or ask about the user's framework.

- If a `package.json` is present, probe for `react`, `vue`, `@angular/core`, or `vite` keys.
- If React detected → proceed to W2.
- If Angular/Vue/vanilla detected → announce placeholder:
  > "A dedicated `ping-sdk-{framework}` skill is on the way. The closest available skills today are `ping-orchestration-reactjs-js-journey-sdk` / `ping-orchestration-reactjs-js-davinci-sdk` (React + Vite). Want me to route to one of those instead?"
- If ambiguous → ask which framework.

### W2 — Shared configuration

Collect parameters common to all three flow types:

| Parameter | Required | Notes |
|-----------|----------|-------|
| `wellknown` | Yes | Full OIDC discovery URL — all endpoints derived from this |
| `clientId` | Yes | OAuth client ID registered in PingOne/AIC |
| `redirectUri` | Yes | Must match exactly what's registered; include `/callback` suffix pattern |
| `scope` | Yes | Space-separated; `openid` is mandatory |
| `appName` | Yes | Used for project/directory naming |
| `journeyName` | Journey only | Authentication tree name |
| `acrValues` | DaVinci/OIDC only | Optional ACR values string |

Validation:
- `wellknown` must end with `.well-known/openid-configuration`
- `scope` must include `openid`
- `redirectUri` must be a valid absolute URL

### W3 — Confirm and handoff

Display a summary table of collected config. Ask user to confirm, then:

- **Journey** → invoke `ping-orchestration-reactjs-js-journey-sdk` via Skill tool, passing collected config
- **DaVinci** → invoke `ping-orchestration-reactjs-js-davinci-sdk` via Skill tool, passing collected config
- **OIDC centralized** → continue to Section 5 (inline OIDC guidance)

## `create-sample` command

```
/ping-sdk-js create-sample "<description>"
```

Steps:
1. Analyse description to determine flow type and framework
2. Ask one clarifying question if flow type is ambiguous
3. Collect missing required config (skip params already inferable from description)
4. For Journey/DaVinci: delegate to appropriate specialized skill with config pre-filled
5. For OIDC: generate inline using the 5 OIDC templates

## Shared setup guidance (inline, before delegation)

Covers content that applies regardless of flow type, so delegates don't need to repeat it:

### Package selection

| Flow | Required packages |
|------|-----------------|
| Journey | `@forgerock/journey-client` `@forgerock/oidc-client` |
| DaVinci | `@forgerock/davinci-client` `@forgerock/oidc-client` (optional) |
| OIDC centralized | `@forgerock/oidc-client` |
| Protect (any) | `@forgerock/protect` |
| Device management | `@forgerock/device-client` |

### Environment variables

All env vars use `VITE_` prefix (Vite convention):

```env
VITE_PING_WELLKNOWN=https://auth.example.com/am/.well-known/openid-configuration
VITE_PING_CLIENT_ID=my-app
VITE_PING_REDIRECT_URI=http://localhost:5173/callback
VITE_PING_SCOPE=openid profile
```

### Common pitfalls

- `redirectUri` must match the registered value **exactly** — trailing slash matters
- `scope` must include `openid` or the OIDC client will throw
- CORS: the well-known endpoint must include your app's origin in the CORS policy
- `wellknown` vs `serverConfig`: the new SDK uses `wellknown` only; legacy `serverConfig.baseUrl` is not used

## OIDC centralized login (inline)

Handled entirely within the umbrella — no delegation. Uses `@forgerock/oidc-client`.

### Flow

1. User lands on login page → call `client.authorize.url()` → redirect browser
2. User authenticates on PingOne/AIC → redirected back to `redirectUri`
3. Callback page calls `client.token.exchange(code, state)` → stores tokens
4. App reads tokens via `client.token.get()` → user is authenticated
5. Background renewal: `client.token.get({ backgroundRenew: true })` keeps session alive
6. Logout: `client.user.logout()` → revokes token + ends session

### Templates (5 files)

| Template | Purpose |
|----------|---------|
| `.env.template` | Shared env vars (reused from shared layer) |
| `callback.html.template` | Static HTML fallback callback page for SPAs without SSR |
| `oidc-app.jsx.template` | React app shell with OIDC context + protected route |
| `oidc-login.jsx.template` | Login trigger component (calls `authorize.url()`) |
| `oidc-callback.jsx.template` | Callback handler (exchanges code for tokens, redirects to home) |

Reference doc: `assets/oidc-centralized-reference.md` — covers full API, config options, error cases, background renewal, and logout patterns.

## File layout

```
plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/
├── SKILL.md                              (~350-400 lines)
├── assets/
│   ├── oidc-centralized-reference.md     OIDC flow reference (authorize, exchange, renew, logout)
│   ├── .env.template                     Shared env vars
│   ├── callback.html.template            OAuth callback page
│   ├── oidc-app.jsx.template             React OIDC app shell
│   ├── oidc-login.jsx.template           Login trigger component
│   └── oidc-callback.jsx.template        Callback handler component
└── references/
    └── sdk-packages.md                   @forgerock/* package selection guide
```

No `scripts/` directory — scaffolding is delegated to the specialized skills for Journey/DaVinci, and OIDC templates are simple enough to generate without a scaffold script.

## Changes to existing files

### `ping-orchestration-sdk-router` SKILL.md

Flip the JavaScript row in the Platform Registry from `placeholder` to `active`:

```markdown
| JavaScript (web) | `ping-orchestration-javascript-sdk` | active | — |
```

Fill in the JavaScript probe block (already partially defined as the placeholder probe):

```bash
find . -maxdepth 4 \
  \( -name node_modules -o -name .git -o -name build -o -name dist \) -prune -o \
  \( -name "package.json" \) -print | head -5 | xargs grep -l '"react"\|"vue"\|"@angular/core"\|"vite"' 2>/dev/null
```

Update the placeholder-detected fallback prompt for JavaScript — it currently says "ping-sdk-js is on the way"; update to route directly to `ping-orchestration-javascript-sdk`.

### README.md (root) and plugins/ping-orchestration-sdks/README.md

Add `ping-orchestration-javascript-sdk` row to the SDK Integration Skills table in both files.

Update the `ping-orchestration-sdk-router` row description: remove "JavaScript and React Native on the roadmap" — JavaScript is now active.

## Frontmatter

```yaml
---
name: ping-sdk-js
description: >-
  Use when building web apps with the Ping Orchestration JavaScript SDK —
  phrases like "add Ping auth to my web app", "use PingOne in React",
  "set up Journey in JavaScript", "build a Ping login page". Detects
  framework (React active; Angular, Vue, vanilla JS on the roadmap),
  collects shared config, delegates Journey to
  ping-orchestration-reactjs-js-journey-sdk and DaVinci to
  ping-orchestration-reactjs-js-davinci-sdk, handles OIDC centralized
  login inline.
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---
```

## Validation

- `npx skills-ref validate ./plugins/ping-orchestration-sdks/skills/ping-sdk-js` — schema/structure check
- `claudelint .` — lint rules including `skill-readme-documentation`
- Manual smoke test: verify router now routes JS projects to `ping-orchestration-javascript-sdk` instead of showing the placeholder message

## Out of scope

- Callback/collector rendering — owned by the delegate specialized skills
- Native mobile (Android, iOS) — separate umbrella skills
- Angular/Vue/vanilla JS templates — placeholders only; no delegate skills exist yet
- Migration from `@forgerock/javascript-sdk` legacy SDK — owned by `forgerock-to-ping-journey-migration`
- React Native — separate `ping-sdk-react-native` skill (not yet built)
