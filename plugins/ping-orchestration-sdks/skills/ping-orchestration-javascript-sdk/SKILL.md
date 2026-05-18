---
name: ping-orchestration-javascript-sdk
description: >-
  Guide for building web apps with the Ping Orchestration JavaScript SDK
  (also referred to as the Ping Identity JavaScript SDK, formerly the
  ForgeRock JavaScript SDK / @forgerock/javascript-sdk; npm packages:
  `@forgerock/journey-client`, `@forgerock/davinci-client`,
  `@forgerock/oidc-client`). Use when the user wants to add Ping
  authentication to a web app — phrases like "add Ping auth to my web app",
  "use PingOne in React", "set up Journey in JavaScript", "build a Ping
  login page", "use DaVinci in my SPA", "integrate @forgerock/journey-client",
  "set up @forgerock/davinci-client", "migrate from @forgerock/javascript-sdk
  to the new SDK", or "add OIDC login to my React app". Detects framework
  (React active; Angular, Vue, vanilla JS on the roadmap), collects shared
  config, delegates Journey to ping-orchestration-reactjs-js-journey-sdk and
  DaVinci to ping-orchestration-reactjs-js-davinci-sdk, and handles OIDC
  centralized login inline. Covers both new sample app creation and
  integrating into an existing project.
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

This table is the single source of truth for framework routing. The decision tree references it by `Status`. To add a new framework: change its status from `placeholder` to `active`, add delegate skill names, fill in the OIDC templates directory, and add any build-tool-specific guidance to the "Build Tool Configuration" subsection.

| Framework | Journey Delegate | DaVinci Delegate | OIDC Templates | Status |
|-----------|-----------------|-----------------|----------------|--------|
| React | `ping-orchestration-reactjs-js-journey-sdk` | `ping-orchestration-reactjs-js-davinci-sdk` | `assets/react/` | active |
| Angular | — | — | `assets/angular/` | placeholder |
| Vue | — | — | `assets/vue/` | placeholder |
| Vanilla JS | — | — | `assets/vanilla/` | placeholder |

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
- `vue` or `@angular/core` found → announce placeholder and offer choices:
  > "A dedicated `ping-orchestration-vue-sdk` / `ping-orchestration-angular-sdk` skill is on the way. I can:
  > 1. **Generate framework-neutral SDK wiring** — client init, token exchange, and route guard pseudocode you can adapt to your framework's patterns.
  > 2. **Route to the React skill** (`ping-orchestration-reactjs-js-journey-sdk` / `ping-orchestration-reactjs-js-davinci-sdk`) as a reference implementation you can port.
  >
  > Which would you prefer?"
  - If the user chooses option 1 → proceed to W2 and then use the **Generic (Placeholder Framework) Path** below.
  - If the user chooses option 2 → proceed to W2 and delegate to the React skill.
- `react-native` found (check separately) → announce that `ping-orchestration-react-native-sdk` is on the way; no stopgap exists.
- Nothing found, or no `package.json` → ask: "Which JavaScript framework are you using?" List active frameworks from the Framework Registry. If the user names a placeholder framework, offer the same two options above.

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
- **Journey (active framework)** → invoke the Journey delegate from the Framework Registry via the Skill tool. Pass the collected config in your invocation context. Do not inline that skill's content. Note: the Journey delegate uses its own env var naming (`VITE_WELLKNOWN_URL`, `VITE_WEB_OAUTH_CLIENT`, etc.) — the delegate will handle this; pass the logical values from W2.
- **DaVinci (active framework)** → invoke the DaVinci delegate from the Framework Registry via the Skill tool. Pass the collected config. Do not inline that skill's content. Note: the DaVinci delegate uses its own env var naming (`VITE_CLIENT_ID`, `VITE_DISCOVERY_ENDPOINT`, etc.) — pass the logical values from W2.
- **OIDC centralized (active framework)** → read `assets/oidc-centralized-reference.md` and continue to the OIDC Centralized Login section below. Use templates from the framework's `OIDC Templates` directory.
- **Any flow (placeholder framework, generic path)** → continue to the Generic (Placeholder Framework) Path section below.

## Generic (Placeholder Framework) Path

Use this path when the user's framework is `placeholder` in the Framework Registry and they chose framework-neutral SDK wiring in W1b. The SDK packages are pure JavaScript with no framework dependency — this path provides the integration wiring without framework-specific component rendering.

### What to generate

For each flow type, produce a single integration module the user can adapt to their framework:

**Journey:**
```js
import { journey, callbackType } from '@forgerock/journey-client';
import { oidc } from '@forgerock/oidc-client';

// 1. Initialise OIDC client (for token management after Journey completes)
const oidcClient = await oidc({
  serverConfig: { wellknown: '<wellknown>' },
  clientId: '<clientId>',
  redirectUri: '<redirectUri>',
  scope: '<scope>',
});

// 2. Start Journey
const client = await journey({
  serverConfig: { wellknown: '<wellknown>' },
  journeyName: '<journeyName>',
});

let step = await client.start();

// 3. Loop: render callbacks, collect input, submit
while (step.type === 'Step') {
  for (const cb of step.callbacks) {
    // Inspect cb.type (callbackType.NameCallback, callbackType.PasswordCallback, etc.)
    // Collect user input and call cb.setInput(value) or equivalent setter
  }
  step = await client.next(step);
}

// 4. Handle outcome
if (step.type === 'SuccessStep') {
  // Journey complete — tokens available via oidcClient.token.get()
} else {
  // step.type === 'FailureStep' — display error
}
```

**DaVinci:**
```js
import { davinci } from '@forgerock/davinci-client';

const client = await davinci({
  serverConfig: { wellknown: '<wellknown>' },
  clientId: '<clientId>',
  redirectUri: '<redirectUri>',
  scope: '<scope>',
});

let node = await client.start();

// Loop: render collectors, collect input, submit
while (node.status === 'continue') {
  const collectors = node.client.collectors;
  for (const collector of collectors) {
    // Inspect collector.type (TextCollector, PasswordCollector, SubmitCollector, etc.)
    // Set value: collector.value = userInput;
  }
  node = await client.next();
}

if (node.status === 'success') {
  // Auth complete — session established
} else {
  // node.status === 'error' — display node.error
}
```

**OIDC centralized:**
```js
import { oidc } from '@forgerock/oidc-client';

const client = await oidc({
  serverConfig: { wellknown: '<wellknown>' },
  clientId: '<clientId>',
  redirectUri: '<redirectUri>',
  scope: '<scope>',
});

// Login: redirect to authorization endpoint
const url = await client.authorize.url();
window.location.href = url;

// Callback page: exchange code for tokens
const params = new URLSearchParams(window.location.search);
const code = params.get('code');
const state = params.get('state');
if (code && state) {
  await client.token.exchange(code, state);
  window.location.replace('/');
}

// Check auth state
const tokens = await client.token.get();

// Logout
await client.user.logout();
```

### Guidance to include

After generating the integration module:
1. Explain which parts map to framework concerns (the render loop → component tree; the auth check → route guard; the callback page → dedicated route).
2. Point to the React delegate skill as a full reference implementation they can study.
3. Offer to help wire the module into their specific framework's patterns if they share their app structure.

## Shared Setup Guidance

This section applies regardless of flow type or framework. Provide this guidance before delegating or generating code.

### SDK setup (all frameworks)

Full package reference: [references/sdk-packages.md](references/sdk-packages.md)

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

### Common pitfalls (SDK-level)

- **`redirectUri` mismatch**: the value must match what's registered in PingOne/AIC exactly — trailing slash, port number, and path all matter.
- **Missing `openid` scope**: `@forgerock/oidc-client` requires `openid` in scope or token exchange will fail.
- **CORS**: the well-known endpoint must include your app's origin in the server's CORS policy. Check PingOne/AIC CORS settings if you see preflight failures.
- **`wellknown` vs `serverConfig`**: the new SDK (`@forgerock/journey-client` v2+) uses `wellknown` only. The legacy `serverConfig.baseUrl` is not supported.

### Build tool configuration

Apply the section below that matches the detected framework. Only one applies per project.

> **Note for placeholder frameworks (Angular, Vue, Vanilla JS):** Full skill support for these frameworks is not yet active. The sections below document the correct build tool conventions so you can configure your environment correctly when using the [Generic Placeholder Framework Path](#generic-placeholder-framework-path). No OIDC templates are generated for placeholder frameworks — adapt the patterns manually.

#### React + Vite

Env vars use the `VITE_` prefix (required by Vite for client-side exposure):

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

Reference: `assets/react/.env.template`

Vite-specific pitfalls:
- Only vars prefixed `VITE_` are exposed to the browser bundle. Server-only secrets must stay unprefixed.
- For SPAs without SSR, the OAuth callback route must be a real file (`public/callback.html`) or the dev server returns `index.html` which re-triggers routing before the exchange runs.

#### Angular CLI

Env vars go in `src/environments/environment.ts`:

```ts
export const environment = {
  pingWellknown: 'https://auth.example.com/am/oauth2/alpha/.well-known/openid-configuration',
  pingClientId: 'my-app',
  pingRedirectUri: 'http://localhost:4200/callback',
  pingScope: 'openid profile',
  // Journey only:
  pingJourneyName: 'Login',
};
```

Angular-specific notes:
- Use `environment.ts` / `environment.prod.ts` for config — Angular does not expose `process.env` to the browser.
- The callback route is a normal Angular route component — no static HTML workaround needed since Angular's router handles it.

#### Vue CLI / Vite

Env vars use the prefix matching your build tool:
- **Vite** → `VITE_` prefix (same as React + Vite above)
- **Vue CLI (webpack)** → `VUE_APP_` prefix

```env
VUE_APP_PING_WELLKNOWN=https://auth.example.com/am/oauth2/alpha/.well-known/openid-configuration
VUE_APP_PING_CLIENT_ID=my-app
VUE_APP_PING_REDIRECT_URI=http://localhost:8080/callback
VUE_APP_PING_SCOPE=openid profile
```

Access with `process.env.VUE_APP_*` (Vue CLI) or `import.meta.env.VITE_*` (Vite).

#### Vanilla JS / Other

No framework-specific env conventions. Use any approach that suits the project:
- A `config.js` file exporting constants
- `.env` loaded via `dotenv` at build time
- Inline `<script>` variables for zero-build setups

## `create-sample` command

```
/ping-orchestration-javascript-sdk create-sample "<description>"
```

**Steps:**
1. Analyse the description to determine flow type (journey / davinci / oidc-centralized) and framework.
2. If flow type is ambiguous, ask one clarifying question.
3. If framework is not React and is not detectable from the project, ask.
4. Collect any missing required parameters from W2 that are not inferable from the description.
5. If framework is `active` in the Framework Registry:
   - **Journey** → invoke the Journey delegate via Skill tool with pre-filled config.
   - **DaVinci** → invoke the DaVinci delegate via Skill tool with pre-filled config.
   - **OIDC centralized** → read `assets/oidc-centralized-reference.md` and generate templates from the framework's `OIDC Templates` directory with substituted placeholders.
6. If framework is `placeholder` → use the Generic (Placeholder Framework) Path.

**Template placeholders** (OIDC centralized only):

| Placeholder | Value |
|-------------|-------|
| `PLACEHOLDER_APP_NAME` | `appName` |
| `PLACEHOLDER_WELLKNOWN` | `wellknown` |
| `PLACEHOLDER_CLIENT_ID` | `clientId` |
| `PLACEHOLDER_REDIRECT_URI` | `redirectUri` |
| `PLACEHOLDER_SCOPE` | `scope` |
| `PLACEHOLDER_ACR_VALUES` | `acrValues` — omit the line if not provided |

## OIDC Centralized Login

Handled inline — no delegation. Uses `@forgerock/oidc-client` directly. Full API reference: `assets/oidc-centralized-reference.md`.

### Flow

1. User lands on login page → call `client.authorize.url()` to generate the authorization URL → redirect the browser.
2. User authenticates on PingOne/AIC → browser redirected back to `redirectUri`.
3. Callback page reads `code` and `state` from the URL → calls `client.token.exchange(code, state)` → tokens stored.
4. App calls `client.token.get()` to read tokens → user is authenticated, render protected content.
5. Background renewal: call `client.token.get({ backgroundRenew: true })` to keep the session alive via a hidden iframe.
6. Logout: call `client.user.logout()` → revokes the access token and ends the session on the server.

### Client initialisation

```js
import { oidc } from '@forgerock/oidc-client';

const client = await oidc({
  serverConfig: {
    wellknown: import.meta.env.VITE_PING_WELLKNOWN,
  },
  clientId: import.meta.env.VITE_PING_CLIENT_ID,
  redirectUri: import.meta.env.VITE_PING_REDIRECT_URI,
  scope: import.meta.env.VITE_PING_SCOPE,
  // acrValues: import.meta.env.VITE_PING_ACR_VALUES, // uncomment if needed
});
```

### Token exchange (callback page)

```js
const params = new URLSearchParams(window.location.search);
const code = params.get('code');
const state = params.get('state');

if (code && state) {
  await client.token.exchange(code, state);
  window.location.replace('/');  // redirect to home after successful exchange
}
```

### Route guard pattern

The route guard logic is the same for all frameworks — only the component wrapper changes.

**Core logic (framework-agnostic):**
```js
async function checkAuth(client) {
  const tokens = await client.token.get();
  if (!tokens) {
    const url = await client.authorize.url();
    window.location.href = url;
    return null;
  }
  return tokens;
}
```

**React wrapper:**
```jsx
import { useEffect, useState } from 'react';

export function ProtectedRoute({ children }) {
  const [isAuthenticated, setIsAuthenticated] = useState(null);

  useEffect(() => {
    client.token.get().then((tokens) => {
      setIsAuthenticated(!!tokens);
    });
  }, []);

  if (isAuthenticated === null) return <div>Loading…</div>;
  if (!isAuthenticated) {
    client.authorize.url().then((url) => { window.location.href = url; });
    return null;
  }
  return children;
}
```

For other frameworks, adapt the wrapper to the framework's guard mechanism (Angular `CanActivate`, Vue `beforeEach` navigation guard, etc.) using the same `checkAuth` logic.

### Templates

Generate these files when flow type is `oidc-centralized`. Read templates from the active framework's subdirectory in the Framework Registry's `OIDC Templates` column (e.g., `assets/react/` for React). Substitute placeholders and write to the user's project directory.

**React (`assets/react/`):**

| Template file | Output path | Purpose |
|--------------|------------|---------|
| `assets/react/.env.template` | `.env` | Environment variables (Vite `VITE_` prefix) |
| `assets/react/callback.html.template` | `public/callback.html` | Static OAuth callback page |
| `assets/react/oidc-app.jsx.template` | `src/App.jsx` | App shell with OIDC context + protected route |
| `assets/react/oidc-login.jsx.template` | `src/pages/Login.jsx` | Login trigger (`authorize.url()` → redirect) |
| `assets/react/oidc-callback.jsx.template` | `src/pages/Callback.jsx` | Code exchange handler |
| `assets/react/oidc-home.jsx.template` | `src/pages/Home.jsx` | Protected home page with user info + sign-out |

**Other frameworks:** When their `OIDC Templates` directory is populated, follow the same pattern — read from the framework's `assets/<framework>/` directory.

### Common pitfalls (OIDC)

- **`state` mismatch**: never construct the authorization URL manually. Always use `client.authorize.url()` — it generates and stores the `state` and `code_verifier` (PKCE) automatically. Calling `token.exchange` with a `state` that doesn't match stored state throws `state_mismatch`.
- **Background renewal requires iframe allowance**: `backgroundRenew: true` opens a hidden iframe to the authorization endpoint. If your CSP blocks `frame-src`, renewal will silently fail. Add your PingOne/AIC domain to `frame-src`.
- **PKCE is always on**: `@forgerock/oidc-client` uses PKCE by default and does not expose a toggle. Your OAuth client registration must have PKCE enabled (or set to optional).
