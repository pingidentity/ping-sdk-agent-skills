# ping-sdk-js Umbrella Skill — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `ping-orchestration-javascript-sdk` umbrella skill that acts as the single web/JS entry point, collecting shared config, delegating Journey/DaVinci to existing ReactJS skills, handling OIDC centralized login inline, and updating the router to activate the JS platform slot.

**Architecture:** A layered umbrella — the skill's own SKILL.md handles wizard mode (W1→W2→W3), shared Vite/env-var guidance, and inline OIDC centralized login; Journey and DaVinci flows are delegated to `ping-orchestration-reactjs-js-journey-sdk` and `ping-orchestration-reactjs-js-davinci-sdk` via Skill tool invocation. A framework registry (React active, Angular/Vue/vanilla placeholder) enables future expansion with no decision-tree rewrites.

**Tech Stack:** Markdown (SKILL.md, reference docs, templates), `@forgerock/oidc-client` API patterns for OIDC section, `npx skills-ref validate` + `claudelint` for validation.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/SKILL.md` | Wizard, shared guidance, framework registry, delegation rules, inline OIDC |
| Create | `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/oidc-centralized-reference.md` | Full `@forgerock/oidc-client` API reference for OIDC flow |
| Create | `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/.env.template` | Shared VITE_ env vars |
| Create | `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/callback.html.template` | Static OAuth callback page |
| Create | `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/oidc-app.jsx.template` | React OIDC app shell with context + protected route |
| Create | `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/oidc-login.jsx.template` | Login trigger component (`authorize.url()`) |
| Create | `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/oidc-callback.jsx.template` | Callback handler (code exchange → redirect home) |
| Create | `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/references/sdk-packages.md` | `@forgerock/*` package selection guide |
| Modify | `plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md` | Activate JS row, add JS probe block, update JS fallback prompt, update routing matrix + no-detection prompt, update frontmatter description |
| Modify | `README.md` | Add `ping-orchestration-javascript-sdk` row to SDK Integration Skills table; update `ping-orchestration-sdk-router` description |
| Modify | `plugins/ping-orchestration-sdks/README.md` | Same — add `ping-orchestration-javascript-sdk` row; update `ping-orchestration-sdk-router` description |

---

## Task 1: Scaffold skill directory and SKILL.md frontmatter + overview

**Files:**
- Create: `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/SKILL.md`

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets
mkdir -p plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/references
```

- [ ] **Step 2: Create SKILL.md with frontmatter and overview section**

Create `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/SKILL.md` with this exact content:

```markdown
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

First point of contact for building web apps with the Ping Orchestration JavaScript SDK (`@forgerock/*` packages). Handles three authentication flows:

- **Journey** — callback-based auth against PingAM or PingOne AIC → delegates to `ping-orchestration-reactjs-js-journey-sdk`
- **DaVinci** — collector-based auth against PingOne DaVinci → delegates to `ping-orchestration-reactjs-js-davinci-sdk`
- **OIDC centralized login** — OAuth2 authorization code flow (browser redirect) → handled inline

Runs a three-step wizard (W1 → W2 → W3) to determine flow type, detect framework, collect shared config, then hands off or generates code.
```

- [ ] **Step 3: Validate the file is well-formed**

```bash
npx skills-ref validate ./plugins/ping-orchestration-sdks/skills/ping-sdk-js
```

Expected: schema/structure pass (may warn about missing assets — that's fine at this stage).

- [ ] **Step 4: Commit**

```bash
git add plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/SKILL.md
git commit -S -m "feat(ping-sdk-js): scaffold skill with frontmatter and overview"
```

---

## Task 2: Framework registry and wizard flow (W1, W1b, W2, W3)

**Files:**
- Modify: `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/SKILL.md` (append after overview)

- [ ] **Step 1: Append the Framework Registry section to SKILL.md**

Add after the overview paragraph (after the bullet list ending "…handled inline"):

```markdown

## Framework Registry

This table is the single source of truth for framework routing. The decision tree references it by `Status`. To add a new framework, change its status from `placeholder` to `active`, add delegate skill names, and fill in probe instructions — no other changes needed.

| Framework | Journey Delegate | DaVinci Delegate | Status |
|-----------|-----------------|-----------------|--------|
| React | `ping-orchestration-reactjs-js-journey-sdk` | `ping-orchestration-reactjs-js-davinci-sdk` | active |
| Angular | — | — | placeholder |
| Vue | — | — | placeholder |
| Vanilla JS | — | — | placeholder |
```

- [ ] **Step 2: Append the Wizard section (W1, W1b, W2, W3)**

Add after the Framework Registry section:

```markdown

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
```

- [ ] **Step 3: Commit**

```bash
git add plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/SKILL.md
git commit -S -m "feat(ping-sdk-js): add framework registry and wizard flow W1-W3"
```

---

## Task 3: Shared setup guidance and `create-sample` command

**Files:**
- Modify: `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/SKILL.md` (append)

- [ ] **Step 1: Append the Shared Setup Guidance section**

Add after the Wizard section:

```markdown

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
```

- [ ] **Step 2: Append the `create-sample` command section**

Add after the Shared Setup Guidance section:

```markdown

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
```

- [ ] **Step 3: Commit**

```bash
git add plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/SKILL.md
git commit -S -m "feat(ping-sdk-js): add shared setup guidance and create-sample command"
```

---

## Task 4: OIDC centralized login section in SKILL.md

**Files:**
- Modify: `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/SKILL.md` (append)

- [ ] **Step 1: Append the OIDC Centralized Login section**

Add after the `create-sample` section:

```markdown

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

### Protected route pattern (React)

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

### Templates

Generate these 5 files when flow type is `oidc-centralized`. Read the templates from `assets/`, substitute placeholders, and write to the user's project directory.

| Template file | Output path | Purpose |
|--------------|------------|---------|
| `assets/.env.template` | `.env` | Environment variables |
| `assets/callback.html.template` | `public/callback.html` | Static OAuth callback page |
| `assets/oidc-app.jsx.template` | `src/App.jsx` | App shell with OIDC context + protected route |
| `assets/oidc-login.jsx.template` | `src/pages/Login.jsx` | Login trigger (`authorize.url()` → redirect) |
| `assets/oidc-callback.jsx.template` | `src/pages/Callback.jsx` | Code exchange handler |

### Common pitfalls (OIDC)

- **`state` mismatch**: never construct the authorization URL manually. Always use `client.authorize.url()` — it generates and stores the `state` and `code_verifier` (PKCE) automatically. Calling `token.exchange` with a `state` that doesn't match stored state throws `state_mismatch`.
- **Callback page as SPA route vs static HTML**: for Vite SPAs without SSR, the callback route must be a real file (`public/callback.html`) or the dev server will return `index.html` which re-triggers routing before the exchange runs. Use `assets/callback.html.template` as a standalone page.
- **Background renewal requires iframe allowance**: `backgroundRenew: true` opens a hidden iframe to the authorization endpoint. If your CSP blocks `frame-src`, renewal will silently fail. Add your PingOne/AIC domain to `frame-src`.
- **PKCE is always on**: `@forgerock/oidc-client` uses PKCE by default and does not expose a toggle. Your OAuth client registration must have PKCE enabled (or set to optional).
```

- [ ] **Step 2: Commit**

```bash
git add plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/SKILL.md
git commit -S -m "feat(ping-sdk-js): add OIDC centralized login section"
```

---

## Task 5: Asset files — env template, OIDC templates (5 files)

**Files:**
- Create: `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/.env.template`
- Create: `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/callback.html.template`
- Create: `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/oidc-app.jsx.template`
- Create: `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/oidc-login.jsx.template`
- Create: `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/oidc-callback.jsx.template`

- [ ] **Step 1: Create `.env.template`**

```
VITE_PING_WELLKNOWN=PLACEHOLDER_WELLKNOWN
VITE_PING_CLIENT_ID=PLACEHOLDER_CLIENT_ID
VITE_PING_REDIRECT_URI=PLACEHOLDER_REDIRECT_URI
VITE_PING_SCOPE=PLACEHOLDER_SCOPE
# VITE_PING_ACR_VALUES=PLACEHOLDER_ACR_VALUES
```

- [ ] **Step 2: Create `callback.html.template`**

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>PLACEHOLDER_APP_NAME — Authenticating…</title>
  </head>
  <body>
    <script type="module">
      import { oidc } from '@forgerock/oidc-client';

      const client = await oidc({
        serverConfig: { wellknown: 'PLACEHOLDER_WELLKNOWN' },
        clientId: 'PLACEHOLDER_CLIENT_ID',
        redirectUri: 'PLACEHOLDER_REDIRECT_URI',
        scope: 'PLACEHOLDER_SCOPE',
      });

      const params = new URLSearchParams(window.location.search);
      const code = params.get('code');
      const state = params.get('state');

      if (code && state) {
        try {
          await client.token.exchange(code, state);
          window.location.replace('/');
        } catch (err) {
          document.body.textContent = 'Authentication failed: ' + err.message;
        }
      } else {
        document.body.textContent = 'No authorization code found.';
      }
    </script>
  </body>
</html>
```

- [ ] **Step 3: Create `oidc-app.jsx.template`**

```jsx
import { createContext, useContext, useEffect, useState } from 'react';
import { oidc } from '@forgerock/oidc-client';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Callback from './pages/Callback';
import Home from './pages/Home';

const OidcContext = createContext(null);

export function useOidc() {
  return useContext(OidcContext);
}

let clientInstance = null;
async function getClient() {
  if (!clientInstance) {
    clientInstance = await oidc({
      serverConfig: { wellknown: import.meta.env.VITE_PING_WELLKNOWN },
      clientId: import.meta.env.VITE_PING_CLIENT_ID,
      redirectUri: import.meta.env.VITE_PING_REDIRECT_URI,
      scope: import.meta.env.VITE_PING_SCOPE,
    });
  }
  return clientInstance;
}

function ProtectedRoute({ children }) {
  const { isAuthenticated } = useOidc();
  if (isAuthenticated === null) return <div>Loading…</div>;
  return isAuthenticated ? children : <Navigate to="/login" replace />;
}

export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(null);
  const [client, setClient] = useState(null);

  useEffect(() => {
    getClient().then((c) => {
      setClient(c);
      c.token.get().then((tokens) => setIsAuthenticated(!!tokens)).catch(() => setIsAuthenticated(false));
    });
  }, []);

  return (
    <OidcContext.Provider value={{ client, isAuthenticated, setIsAuthenticated }}>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/callback" element={<Callback />} />
          <Route path="/" element={<ProtectedRoute><Home /></ProtectedRoute>} />
        </Routes>
      </BrowserRouter>
    </OidcContext.Provider>
  );
}
```

- [ ] **Step 4: Create `oidc-login.jsx.template`**

```jsx
import { useEffect } from 'react';
import { useOidc } from '../App';

export default function Login() {
  const { client } = useOidc();

  async function handleSignIn() {
    if (!client) return;
    const url = await client.authorize.url();
    window.location.href = url;
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '2rem' }}>
      <h1>PLACEHOLDER_APP_NAME</h1>
      <button onClick={handleSignIn} style={{ marginTop: '1rem', padding: '0.75rem 2rem' }}>
        Sign In
      </button>
    </div>
  );
}
```

- [ ] **Step 5: Create `oidc-callback.jsx.template`**

```jsx
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useOidc } from '../App';

export default function Callback() {
  const { client, setIsAuthenticated } = useOidc();
  const navigate = useNavigate();
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!client) return;

    const params = new URLSearchParams(window.location.search);
    const code = params.get('code');
    const state = params.get('state');

    if (!code || !state) {
      setError('No authorization code found in the URL.');
      return;
    }

    client.token
      .exchange(code, state)
      .then(() => {
        setIsAuthenticated(true);
        navigate('/', { replace: true });
      })
      .catch((err) => setError(err.message));
  }, [client]);

  if (error) return <div>Authentication failed: {error}</div>;
  return <div>Completing sign-in…</div>;
}
```

- [ ] **Step 6: Commit**

```bash
git add plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/
git commit -S -m "feat(ping-sdk-js): add OIDC templates and env template"
```

---

## Task 6: Reference docs — `oidc-centralized-reference.md` and `sdk-packages.md`

**Files:**
- Create: `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/oidc-centralized-reference.md`
- Create: `plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/references/sdk-packages.md`

- [ ] **Step 1: Create `oidc-centralized-reference.md`**

```markdown
# OIDC Centralized Login — Full Reference

## `oidc()` factory

```js
import { oidc } from '@forgerock/oidc-client';

const client = await oidc({
  serverConfig: {
    wellknown: 'https://auth.example.com/am/oauth2/alpha/.well-known/openid-configuration',
  },
  clientId: 'my-app',
  redirectUri: 'https://app.example.com/callback',
  scope: 'openid profile email',
  // acrValues: 'urn:acr:level1',  // optional
});
```

`oidc()` is an async factory that validates the config and pre-fetches the well-known metadata. Call it once at app startup and reuse the returned client instance.

## `client.authorize`

### `client.authorize.url(options?)`

Returns the full authorization URL as a string. The client automatically generates and stores `state` and `code_verifier` (PKCE). Redirect the browser to this URL.

```js
const url = await client.authorize.url();
window.location.href = url;
```

Optional `options` object:
- `acrValues` — override ACR values for this request
- `loginHint` — prefill the username field on the PingOne/AIC login page
- `prompt` — `'login'` to force re-authentication even if a session exists

### `client.authorize.background(options?)`

Performs authorization via a hidden iframe (silent renewal). Returns `{ code, state }` or throws if the user is not already authenticated. Do not call on the initial login — this is for session renewal only.

```js
try {
  const { code, state } = await client.authorize.background();
  await client.token.exchange(code, state);
} catch {
  // User not authenticated — redirect to login
}
```

## `client.token`

### `client.token.exchange(code, state)`

Exchanges the authorization code for tokens. Always call this in the callback page/route immediately after the browser returns from PingOne/AIC. Tokens are stored automatically (default: `localStorage`).

```js
const params = new URLSearchParams(window.location.search);
await client.token.exchange(params.get('code'), params.get('state'));
```

Throws `state_mismatch` if the `state` in the URL does not match what was stored before the redirect. This means the authorization URL was not generated by this client instance — check for page refreshes between `authorize.url()` and `exchange()`.

### `client.token.get(options?)`

Returns the stored tokens or `null` if the user is not authenticated.

```js
const tokens = await client.token.get();
if (tokens) {
  console.log(tokens.accessToken, tokens.idToken);
}
```

With background renewal:
```js
const tokens = await client.token.get({ backgroundRenew: true });
```

When `backgroundRenew: true`, the client automatically attempts a silent iframe renewal when the access token is near expiry. Requires `frame-src` CSP to allow your PingOne/AIC domain.

### `client.token.revoke()`

Revokes the access token and removes tokens from storage.

```js
await client.token.revoke();
```

## `client.user`

### `client.user.info()`

Fetches the user profile from the `/userinfo` endpoint using the stored access token.

```js
const userInfo = await client.user.info();
console.log(userInfo.sub, userInfo.email, userInfo.name);
```

### `client.user.logout()`

Revokes the access token and ends the server-side session (calls the `end_session_endpoint` from the well-known metadata).

```js
await client.user.logout();
// Redirect to login or home
window.location.replace('/login');
```

## Error handling

All methods return errors as thrown exceptions (not as `Result` types). Wrap in `try/catch`:

```js
try {
  await client.token.exchange(code, state);
} catch (err) {
  if (err.message === 'state_mismatch') {
    // stale or replayed request
  } else {
    console.error('Token exchange failed:', err.message);
  }
}
```

## Storage

Default storage is `localStorage`. To switch to `sessionStorage`:

```js
import { oidc } from '@forgerock/oidc-client';
import { sessionStorage } from '@forgerock/storage';

const client = await oidc({ ..., storage: sessionStorage() });
```

## PKCE

PKCE (Proof Key for Code Exchange) is always enabled. You cannot disable it. Your OAuth client registration in PingOne/AIC must have PKCE set to **Required** or **Optional** — if it is set to **Disabled**, token exchange will fail with an `invalid_grant` error.
```

- [ ] **Step 2: Create `references/sdk-packages.md`**

```markdown
# `@forgerock/*` Package Selection Guide

## Which packages do I need?

| Scenario | Required packages |
|----------|-----------------|
| Journey (PingAM / PingOne AIC) | `@forgerock/journey-client` + `@forgerock/oidc-client` |
| DaVinci (PingOne) | `@forgerock/davinci-client` |
| DaVinci + token management | `@forgerock/davinci-client` + `@forgerock/oidc-client` |
| OIDC centralized login | `@forgerock/oidc-client` |
| PingOne Protect / behavioral signals | `@forgerock/protect` |
| Device profile, OATH, Push, WebAuthn management | `@forgerock/device-client` |

## Package summaries

### `@forgerock/journey-client`

Callback-based authentication against PingAM or PingOne AIC (formerly AIC). Supports all Journey callback types: Name, Password, Choice, Confirmation, TextInput, TextOutput, KbaCreate, TermsAndConditions, WebAuthn, DeviceProfile, SelectIdp, PingProtect, PollingWait, Redirect, SuspendedTextOutput, and more.

Key API: `journey({ config })` → `client.start()` → `client.next(step)` → check `step.type` for `SuccessStep | FailureStep | Step`.

### `@forgerock/davinci-client`

Collector-based authentication against PingOne DaVinci. Collectors are plain objects (not class instances). Supports TextCollector, PasswordCollector, SubmitCollector, FlowCollector, IdpCollector, SingleSelectCollector, MultiSelectCollector, DeviceRegistrationCollector, DeviceAuthenticationCollector, PhoneNumberCollector, ReadOnlyCollector, ProtectCollector, FidoRegistrationCollector, FidoAuthenticationCollector.

Key API: `davinci({ config })` → `client.start()` → `client.next()` → check `client.getNode().status` for `'continue' | 'success' | 'error'`.

### `@forgerock/oidc-client`

OAuth2/OIDC authorization code flow with PKCE. Handles authorization URL generation, code exchange, token storage, background (silent) renewal via hidden iframe, userinfo fetching, and logout.

Key API: `oidc({ config })` → `client.authorize.url()` → redirect → `client.token.exchange(code, state)` → `client.token.get()`.

### `@forgerock/protect`

PingOne Protect behavioral risk signals. Collects device fingerprint and behavioural data.

Key API: `protect({ envId })` → `signals.start()` → `signals.getData()`.

### `@forgerock/device-client`

Device profile collection and device management (OATH TOTP, Push notifications, WebAuthn registration/authentication, Bound Device). Used alongside Journey or DaVinci for MFA flows requiring device registration.

## Version requirements

All packages are at version **2.0.0** (released 2026-03-19). Requires **Node.js ^20 || ^22 || ^24**.

## Installation

```bash
# Journey + OIDC tokens
npm install @forgerock/journey-client @forgerock/oidc-client

# DaVinci only
npm install @forgerock/davinci-client

# OIDC centralized login
npm install @forgerock/oidc-client

# Optional add-ons
npm install @forgerock/protect
npm install @forgerock/device-client
```
```

- [ ] **Step 3: Commit**

```bash
git add plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/oidc-centralized-reference.md
git add plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/references/sdk-packages.md
git commit -S -m "feat(ping-sdk-js): add OIDC reference doc and SDK packages guide"
```

---

## Task 7: Update `ping-orchestration-sdk-router` SKILL.md — activate JS platform

**Files:**
- Modify: `plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md`

The current file is 218 lines. The changes are:

1. **Frontmatter description** (lines 3–10): remove "planned: ping-sdk-js" — it's now active.
2. **Platform Registry table** (line 29): change `placeholder` → `active` and clear the Notes stopgap text.
3. **Probe Blocks section** (after line 84): convert the JavaScript placeholder probe into a full active probe block.
4. **Decision Tree Phase 2, rule 4** (line 104–106): remove the JS placeholder handling — JS is now active and hits rule 3.
5. **Routing Matrix** (line 133): update JS row from "Stopgap suggestion" to route to `ping-orchestration-javascript-sdk`.
6. **Fallback Prompts — Placeholder-detected prompt (JavaScript)** (lines 174–181): replace the "coming soon" message with a direct routing message.
7. **No-detection prompt** (lines 187–195): change "coming soon" for JS to direct routing.
8. **Adding a New Platform** (line 200): update example from `ping-orchestration-javascript-sdk` to `ping-sdk-react-native`.

- [ ] **Step 1: Update frontmatter description (lines 3–10)**

Find:
```
  specifying a platform — phrases like "help me add Ping auth", "I want to use
  PingOne", "get started with the Ping SDK". Probes the project to detect
  Android, iOS, JavaScript, or React Native, asks if ambiguous, and routes to
  the matching umbrella skill (ping-sdk-android, ping-sdk-ios, planned: ping-sdk-js,
  ping-sdk-react-native) or to forgerock-to-ping-journey-migration when ForgeRock
  SDK references are present.
```

Replace with:
```
  specifying a platform — phrases like "help me add Ping auth", "I want to use
  PingOne", "get started with the Ping SDK". Probes the project to detect
  Android, iOS, JavaScript, or React Native, asks if ambiguous, and routes to
  the matching umbrella skill (ping-sdk-android, ping-sdk-ios, ping-sdk-js;
  ping-sdk-react-native on the roadmap) or to forgerock-to-ping-journey-migration
  when ForgeRock SDK references are present.
```

- [ ] **Step 2: Update Platform Registry table (line 29)**

Find:
```
| JavaScript (web) | `ping-orchestration-javascript-sdk` | placeholder | Stopgap: `ping-orchestration-reactjs-js-journey-sdk`, `ping-orchestration-reactjs-js-davinci-sdk` |
```

Replace with:
```
| JavaScript (web) | `ping-orchestration-javascript-sdk` | active | — |
```

- [ ] **Step 3: Convert JavaScript placeholder probe to an active probe block**

Find the entire "Placeholder probes" section:
```
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
```

Replace with:
```
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
```

- [ ] **Step 4: Update Decision Tree Phase 2, rule 4 (lines 104–107)**

Find:
```
4. **Placeholder platform detected** — no active probe hit, but a placeholder probe hit:
   - **JavaScript (web):** announce that `ping-orchestration-javascript-sdk` is on the way. Offer the existing ReactJS specialized skills (`ping-orchestration-reactjs-js-journey-sdk`, `ping-orchestration-reactjs-js-davinci-sdk`) as a stopgap.
   - **React Native:** announce that `ping-sdk-react-native` is on the way. No stopgap exists; ask the user how they would like to proceed.
```

Replace with:
```
4. **Placeholder platform detected** — no active probe hit, but a placeholder probe hit:
   - **React Native:** announce that `ping-sdk-react-native` is on the way. No stopgap exists; ask the user how they would like to proceed.
```

- [ ] **Step 5: Update Routing Matrix (line 133)**

Find:
```
| JavaScript placeholder hit | Stopgap suggestion (ReactJS specialized skills) |
```

Replace with:
```
| JavaScript (web) only | `ping-orchestration-javascript-sdk` |
| ForgeRock + JavaScript | Ask fork prompt → `forgerock-to-ping-journey-migration` OR `ping-orchestration-javascript-sdk` |
```

- [ ] **Step 6: Update Placeholder-detected prompt for JavaScript (lines 174–181)**

Find:
```
### Placeholder-detected prompt (JavaScript)

> This looks like a `<framework>` project. The umbrella skill `ping-orchestration-javascript-sdk` is on the way but isn't ready yet. In the meantime you can use one of the existing ReactJS specialized skills:
>
> - `ping-orchestration-reactjs-js-journey-sdk` — Journey-based authentication
> - `ping-orchestration-reactjs-js-davinci-sdk` — DaVinci-based authentication
>
> Want me to route to one of those?
```

Replace with:
```
### Active route for JavaScript

JavaScript is now an active platform. When the JavaScript probe hits, print the handoff line and invoke `ping-orchestration-javascript-sdk` via the Skill tool — no prompt needed unless ambiguity requires it (e.g., ForgeRock refs also present).
```

- [ ] **Step 7: Update no-detection prompt (lines 187–195)**

Find:
```
> - **JavaScript / Web** — coming soon (`ping-orchestration-javascript-sdk`)
```

Replace with:
```
> - **JavaScript / Web** (`ping-orchestration-javascript-sdk`)
```

- [ ] **Step 8: Update the "Adding a New Platform" example (line 200)**

Find:
```
When a new umbrella skill ships (e.g., `ping-orchestration-javascript-sdk`), a single contributor edit enables routing for it. Steps:
```

Replace with:
```
When a new umbrella skill ships (e.g., `ping-sdk-react-native`), a single contributor edit enables routing for it. Steps:
```

- [ ] **Step 9: Also update the ForgeRock fork prompt to include JS**

Find:
```
If build new → route to the platform's umbrella skill (`ping-orchestration-android-sdk` or `ping-orchestration-ios-sdk`).
```

Replace with:
```
If build new → route to the platform's umbrella skill (`ping-orchestration-android-sdk`, `ping-orchestration-ios-sdk`, or `ping-orchestration-javascript-sdk`).
```

- [ ] **Step 10: Validate and commit**

```bash
npx skills-ref validate ./plugins/ping-orchestration-sdks/skills/ping-sdk-router
git add plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md
git commit -S -m "feat(ping-sdk-router): activate JavaScript platform, add JS probe block"
```

---

## Task 8: Update README tables in both root and plugin READMEs

**Files:**
- Modify: `README.md` (root) — line 105 area
- Modify: `plugins/ping-orchestration-sdks/README.md` — line 75 area

- [ ] **Step 1: Add `ping-orchestration-javascript-sdk` row to root `README.md` SDK Integration Skills table**

Find (line 105):
```
| [ping-sdk-android](./plugins/ping-orchestration-sdks/skills/ping-orchestration-android-sdk/SKILL.md) | Android apps with the Ping Orchestration Android SDK — Jetpack Compose + MVVM, Journey callbacks, DaVinci collectors, OIDC centralized login, FIDO, Protect, and project scaffolding |
```

Replace with:
```
| [ping-sdk-android](./plugins/ping-orchestration-sdks/skills/ping-orchestration-android-sdk/SKILL.md) | Android apps with the Ping Orchestration Android SDK — Jetpack Compose + MVVM, Journey callbacks, DaVinci collectors, OIDC centralized login, FIDO, Protect, and project scaffolding |
| [ping-sdk-js](./plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/SKILL.md) | Web apps with the Ping Orchestration JavaScript SDK — React + Vite, Journey callbacks (via delegate), DaVinci collectors (via delegate), and OIDC centralized login |
```

- [ ] **Step 2: Update `ping-orchestration-sdk-router` description in root `README.md` Routing Skills table (line 111)**

Find:
```
| [ping-sdk-router](./plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md) | First point of contact for vague Ping SDK requests — probes the working directory, detects platform (Android, iOS; JavaScript and React Native on the roadmap) and ForgeRock SDK references, then routes to the matching umbrella skill or to `forgerock-to-ping-journey-migration` |
```

Replace with:
```
| [ping-sdk-router](./plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router/SKILL.md) | First point of contact for vague Ping SDK requests — probes the working directory, detects platform (Android, iOS, JavaScript; React Native on the roadmap) and ForgeRock SDK references, then routes to the matching umbrella skill or to `forgerock-to-ping-journey-migration` |
```

- [ ] **Step 3: Add `ping-orchestration-javascript-sdk` row to plugin `README.md` SDK Integration Skills table**

Find (line 75):
```
| [ping-sdk-android](skills/ping-sdk-android) | Implements authentication in Android apps using the Ping Orchestration Android SDK — Jetpack Compose + MVVM, Journey callbacks, DaVinci collectors, OIDC centralized login, FIDO, Protect, EncryptedDataStore, and full project scaffolding. Covers both new project creation and existing app integration. | [SKILL.md](skills/ping-orchestration-android-sdk/SKILL.md) |
```

Replace with:
```
| [ping-sdk-android](skills/ping-sdk-android) | Implements authentication in Android apps using the Ping Orchestration Android SDK — Jetpack Compose + MVVM, Journey callbacks, DaVinci collectors, OIDC centralized login, FIDO, Protect, EncryptedDataStore, and full project scaffolding. Covers both new project creation and existing app integration. | [SKILL.md](skills/ping-orchestration-android-sdk/SKILL.md) |
| [ping-sdk-js](skills/ping-sdk-js) | Implements authentication in web apps using the Ping Orchestration JavaScript SDK — React + Vite, Journey callbacks, DaVinci collectors, OIDC centralized login. Delegates Journey and DaVinci to specialized skills; handles OIDC centralized login inline. Covers both sample app creation and existing app integration. | [SKILL.md](skills/ping-orchestration-javascript-sdk/SKILL.md) |
```

- [ ] **Step 4: Update `ping-orchestration-sdk-router` description in plugin `README.md` Routing Skills table (line 81)**

Find:
```
| [ping-sdk-router](skills/ping-sdk-router) | First point of contact for vague Ping SDK requests. Probes the user's working directory for Android, iOS, JavaScript, or React Native projects (and ForgeRock SDK references), asks if ambiguous, and routes to the matching umbrella skill (`ping-orchestration-android-sdk`, `ping-orchestration-ios-sdk`; `ping-orchestration-javascript-sdk` and `ping-sdk-react-native` on the roadmap) or to `forgerock-to-ping-journey-migration`. Designed for easy expansion via a platform registry. | [SKILL.md](skills/ping-orchestration-sdk-router/SKILL.md) |
```

Replace with:
```
| [ping-sdk-router](skills/ping-sdk-router) | First point of contact for vague Ping SDK requests. Probes the user's working directory for Android, iOS, JavaScript, or React Native projects (and ForgeRock SDK references), asks if ambiguous, and routes to the matching umbrella skill (`ping-orchestration-android-sdk`, `ping-orchestration-ios-sdk`, `ping-orchestration-javascript-sdk`; `ping-sdk-react-native` on the roadmap) or to `forgerock-to-ping-journey-migration`. Designed for easy expansion via a platform registry. | [SKILL.md](skills/ping-orchestration-sdk-router/SKILL.md) |
```

- [ ] **Step 5: Run lint and commit**

```bash
claudelint .
git add README.md plugins/ping-orchestration-sdks/README.md
git commit -S -m "docs(ping-sdk-js): add ping-sdk-js to README tables, update router descriptions"
```

---

## Task 9: Final validation

- [ ] **Step 1: Validate the new skill**

```bash
npx skills-ref validate ./plugins/ping-orchestration-sdks/skills/ping-sdk-js
```

Expected: PASS with no errors.

- [ ] **Step 2: Validate the updated router skill**

```bash
npx skills-ref validate ./plugins/ping-orchestration-sdks/skills/ping-sdk-router
```

Expected: PASS with no errors.

- [ ] **Step 3: Run full repo lint**

```bash
claudelint .
```

Expected: no `skill-readme-documentation` or `skill-directory-structure` errors.

- [ ] **Step 4: Smoke test — verify the skill directory structure is correct**

```bash
find plugins/ping-orchestration-sdks/skills/ping-sdk-js -type f | sort
```

Expected output (7 files):
```
plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/SKILL.md
plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/.env.template
plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/callback.html.template
plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/oidc-app.jsx.template
plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/oidc-callback.jsx.template
plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/oidc-centralized-reference.md
plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/assets/oidc-login.jsx.template
plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/references/sdk-packages.md
```

- [ ] **Step 5: Verify SKILL.md frontmatter `name` matches directory name**

```bash
head -3 plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk/SKILL.md
```

Expected:
```
---
name: ping-sdk-js
```

- [ ] **Step 6: Commit if any lint fixes were needed; otherwise note clean**

```bash
git status
# If clean:
echo "All validation passed — no additional commits needed."
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Covered by task |
|-----------------|----------------|
| Wizard W1/W1b/W2/W3 | Task 2 |
| Framework registry with placeholder expansion | Task 2 |
| Shared setup guidance (packages, env vars, pitfalls) | Task 3 |
| `create-sample` command | Task 3 |
| OIDC centralized login section | Task 4 |
| 5 OIDC templates | Task 5 |
| `oidc-centralized-reference.md` | Task 6 |
| `sdk-packages.md` | Task 6 |
| Frontmatter (name, description, license, metadata) | Task 1 |
| Router JS row → active | Task 7 |
| Router JS probe block | Task 7 |
| Router JS fallback prompt updated | Task 7 |
| Router no-detection prompt updated | Task 7 |
| Root README table updated | Task 8 |
| Plugin README table updated | Task 8 |
| Router description updated in both READMEs | Task 8 |
| Final validation | Task 9 |

All spec requirements are covered. No gaps found.
