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

## Shared Setup Guidance

This section applies regardless of flow type. Provide this guidance before delegating or generating code.

### Package selection

Install only the packages your flow needs:

```bash
# Journey
npm install @forgerock/journey-client @forgerock/oidc-client

# DaVinci
npm install @forgerock/davinci-client
# Add @forgerock/oidc-client if you need token management beyond DaVinci's built-in session

# OIDC centralized login
npm install @forgerock/oidc-client

# Optional add-ons (any flow)
npm install @forgerock/protect       # PingOne Protect / behavioral signals
npm install @forgerock/device-client # Device profile, OATH, Push, WebAuthn management
```

### Environment variables

All env vars use the `VITE_` prefix (required by Vite for client-side exposure):

```env
VITE_PING_WELLKNOWN=https://auth.example.com/am/oauth2/alpha/.well-known/openid-configuration
VITE_PING_CLIENT_ID=my-app
VITE_PING_REDIRECT_URI=http://localhost:5173/callback
VITE_PING_SCOPE=openid profile
# Journey only:
VITE_PING_JOURNEY_NAME=Login
# DaVinci/OIDC optional:
VITE_PING_ACR_VALUES=
```

Reference: `assets/.env.template`

### Common pitfalls

- **`redirectUri` mismatch**: the value must match what's registered in PingOne/AIC exactly — trailing slash, port number, and path all matter.
- **Missing `openid` scope**: `@forgerock/oidc-client` requires `openid` in scope or token exchange will fail.
- **CORS**: the well-known endpoint must include your app's origin in the server's CORS policy. Check PingOne/AIC CORS settings if you see preflight failures.
- **`wellknown` vs `serverConfig`**: the new SDK (`@forgerock/journey-client` v2+) uses `wellknown` only. The legacy `serverConfig.baseUrl` is not supported.
- **Vite env vars not available at runtime**: only vars prefixed `VITE_` are exposed to the browser bundle. Server-only secrets must stay unprefixed.

## `create-sample` command

```
/ping-sdk-js create-sample "<description>"
```

**Steps:**
1. Analyse the description to determine flow type (journey / davinci / oidc-centralized) and framework.
2. If flow type is ambiguous, ask one clarifying question.
3. If framework is not React and is not detectable from the project, ask.
4. Collect any missing required parameters from W2 that are not inferable from the description.
5. **Journey** → invoke `ping-orchestration-reactjs-js-journey-sdk` via Skill tool with pre-filled config.
6. **DaVinci** → invoke `ping-orchestration-reactjs-js-davinci-sdk` via Skill tool with pre-filled config.
7. **OIDC centralized** → read `assets/oidc-centralized-reference.md` and generate the 5 OIDC templates with substituted placeholders. See the OIDC Centralized Login section.

**Template placeholders** (OIDC centralized only):

| Placeholder | Value |
|-------------|-------|
| `PLACEHOLDER_APP_NAME` | `appName` |
| `PLACEHOLDER_WELLKNOWN` | `wellknown` |
| `PLACEHOLDER_CLIENT_ID` | `clientId` |
| `PLACEHOLDER_REDIRECT_URI` | `redirectUri` |
| `PLACEHOLDER_SCOPE` | `scope` |
| `PLACEHOLDER_ACR_VALUES` | `acrValues` — omit the line if not provided |
