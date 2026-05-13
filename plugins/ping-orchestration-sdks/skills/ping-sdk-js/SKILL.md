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

# Ping JavaScript SDK

First point of contact for building web apps with the Ping Orchestration JavaScript SDK (`@forgerock/journey-client`, `@forgerock/davinci-client`, `@forgerock/oidc-client`). Handles three authentication flows:

- **Journey** — callback-based auth against PingAM or PingOne AIC → delegates to `ping-orchestration-reactjs-js-journey-sdk`
- **DaVinci** — collector-based auth against PingOne DaVinci → delegates to `ping-orchestration-reactjs-js-davinci-sdk`
- **OIDC centralized login** — OAuth2 authorization code flow (browser redirect) → handled inline

Runs a three-step wizard (W1 → W2 → W3) to determine flow type, detect framework, collect shared config, then hands off or generates code.

## Framework Registry

This table is the single source of truth for framework routing. The decision tree references it by `Status`. To add a new framework, change its status from `placeholder` to `active`, add delegate skill names, and fill in probe instructions — no other changes needed.

| Framework | Journey Delegate | DaVinci Delegate | Status |
|-----------|-----------------|-----------------|--------|
| React | `ping-orchestration-reactjs-js-journey-sdk` | `ping-orchestration-reactjs-js-davinci-sdk` | active |
| Angular | — | — | placeholder |
| Vue | — | — | placeholder |
| Vanilla JS | — | — | placeholder |

## Wizard

Run these three steps every time the skill is invoked without a `create-sample` argument.

### W1 — Flow type

Ask:

> Which flow are you building?
>
> 1. **Journey** — callback-based auth against PingAM or PingOne AIC
> 2. **DaVinci** — collector-based auth against PingOne DaVinci
> 3. **OIDC centralized login** — OAuth2/OIDC authorization code flow (browser redirect, no custom UI required)

### W1b — Framework detection

Before collecting config, detect or ask about the user's framework.

If a `package.json` is present, run:
```bash
grep -E '"(react|vue|@angular/core|vite)"' package.json
```

- `react` found → React detected → proceed to W2.
- `vue` or `@angular/core` found → announce placeholder:
  > "A dedicated `ping-sdk-vue` / `ping-sdk-angular` skill is on the way. The closest available skills today are `ping-orchestration-reactjs-js-journey-sdk` / `ping-orchestration-reactjs-js-davinci-sdk` (React + Vite). Want me to route to one of those instead?"
- `react-native` found (check separately) → announce that `ping-sdk-react-native` is on the way; no stopgap exists.
- Nothing found, or no `package.json` → ask: "Which JavaScript framework are you using?" List only active frameworks from the Framework Registry.

### W2 — Shared configuration

Collect the following parameters. Skip any the user has already provided in their message.

| Parameter | Required for | Notes |
|-----------|-------------|-------|
| `wellknown` | All flows | Full OIDC discovery URL ending in `.well-known/openid-configuration` |
| `clientId` | All flows | OAuth client ID registered in PingOne/AIC |
| `redirectUri` | All flows | Must match the registered value exactly — include `/callback` path suffix |
| `scope` | All flows | Space-separated; must include `openid` |
| `appName` | All flows | Used for project/directory naming |
| `journeyName` | Journey only | Authentication tree name (e.g., `Login`) |
| `acrValues` | DaVinci/OIDC only | Optional ACR values string |

**Validation before proceeding to W3:**
- `wellknown` must end with `.well-known/openid-configuration`
- `scope` must include `openid` — if missing, add it and tell the user
- `redirectUri` must be an absolute URL starting with `http://` or `https://`

### W3 — Confirm and handoff

Display a summary table:

| Parameter | Value |
|-----------|-------|
| Flow | `<journey \| davinci \| oidc-centralized>` |
| Framework | `<React>` |
| Well-known URL | `<wellknown>` |
| Client ID | `<clientId>` |
| Redirect URI | `<redirectUri>` |
| Scope | `<scope>` |
| App name | `<appName>` |
| Journey name *(Journey only)* | `<journeyName>` |
| ACR values *(DaVinci/OIDC, if provided)* | `<acrValues>` |

Ask: "Does this look right? Shall I proceed?"

On confirmation:
- **Journey** → invoke `ping-orchestration-reactjs-js-journey-sdk` via the Skill tool. Pass the collected config in your invocation context. Do not inline that skill's content.
- **DaVinci** → invoke `ping-orchestration-reactjs-js-davinci-sdk` via the Skill tool. Pass the collected config. Do not inline that skill's content.
- **OIDC centralized** → read `assets/oidc-centralized-reference.md` and continue to the OIDC Centralized Login section below.
