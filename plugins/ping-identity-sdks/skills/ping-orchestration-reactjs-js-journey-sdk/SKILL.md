---
name: ping-orchestration-reactjs-js-journey-sdk
description: Use when building ReactJS web authentication with Ping Identity — scaffolds a complete React SPA authentication flow using the Ping Orchestration JavaScript SDK against PingOne Advanced Identity Cloud (AIC) or PingAM. Handles Journey client configuration, OIDC token exchange, dynamic callback rendering, protected routes, user profile, and logout.
license: MIT
metadata:
  author: Ping Identity
  version: "1.1.0"
---

# ReactJS Authentication with Ping Orchestration JavaScript SDK

Scaffold a complete authentication flow in a ReactJS single-page application using the Ping Identity Journey SDK.

---

## Metadata

| Field       | Value |
|-------------|-------|
| Language    | JavaScript (JSX) |
| Framework   | React 18+, React Router 6+, Vite |
| SDK         | Ping Identity Orchestration JavaScript SDK (`@forgerock/journey-client`, `@forgerock/oidc-client`) |
| Pattern     | Functional Components, Custom Hooks, Context API |
| Node.js     | >= 18.12.0 |

---

## Overview

This skill adds a complete **authentication flow** to a ReactJS single-page application. It uses the **Ping Identity Orchestration JavaScript SDK** (Journey client) to authenticate users against **PingOne Advanced Identity Cloud (AIC)** or **PingAM**.

The implementation covers:
- Journey client configuration via OIDC well-known endpoint discovery
- OIDC client setup for OAuth 2.0 token exchange, renewal, and revocation
- Custom React hook (`useJourney`) for managing the step-by-step authentication flow
- Dynamic callback rendering with dedicated React components for each callback type
- Protected route handling with React Router
- Context-based authentication state management
- Login, registration, and logout flows
- User profile display via `oidcClient.user.info()` with optional edit UI
- Success, error, and failure handling

### Use Cases

1. **Sample Application** — Build a complete, themed ReactJS app from scratch to demonstrate how the Ping Orchestration JavaScript SDK works with PingAM and AIC. This includes all SDK integration files **plus** a full UI with navigation, styled views, a user profile page, and protected content. The agent should generate `package.json`, `vite.config.js`, `index.html`, a CSS stylesheet, and all views/components.
2. **Existing Application Integration** — Integrate the Ping Orchestration JavaScript SDK into an existing ReactJS SPA to add authentication, step-up authentication, or any Journey/Tree-based flow supported by the SDK. The agent should generate **only** the SDK integration files (constants, context, hook, form, callbacks, protected route) and guide the user on wiring them into their existing router and layout.

---

## Prerequisites

### 1. npm Dependencies

Install the following packages in your React project:

```bash
npm install @forgerock/journey-client @forgerock/oidc-client react react-dom react-router-dom
```

Optional dependencies for additional features:

```bash
# PingOne Protect integration (threat signals / risk evaluation)
npm install @forgerock/protect
```

See [package.json template](assets/package.json.template) for a complete example.

### 2. Vite Configuration

This skill uses [Vite](https://vitejs.dev/) as the build tool. See [vite.config.js template](assets/vite.config.js.template) for the recommended configuration.

```bash
npm install --save-dev vite @vitejs/plugin-react
```

### 3. CORS Configuration (PingAM / AIC)

Configure CORS in your PingAM or AIC tenant:

| Setting | Value |
|---------|-------|
| Allowed Origins | `https://localhost:8443` (or your app URL) |
| Allowed Methods | `GET`, `POST` |
| Allowed Headers | `Content-Type`, `X-Requested-With`, `X-Requested-Platform`, `Accept-API-Version`, `Authorization` |
| Allow Credentials | Enabled |

### 4. OAuth 2.0 Client Registration

Create a **public (SPA)** OAuth client in PingAM / AIC:

| Setting | Value |
|---------|-------|
| Client Type | Public |
| Grant Types | Authorization Code |
| Token Endpoint Auth Method | `none` |
| Scopes | `openid profile email` (minimum) |
| Redirect URIs | Your app's callback URL (e.g., `https://localhost:8443/callback.html`) |
| Implicit Consent | Enabled |

---

## Required Configuration

> **Agent instruction:** Before generating any file, collect the values below from the user.
>
> **Step 0 — Determine use case:** Ask the user whether they want a **sample app** (full scaffold
> including `package.json`, `vite.config.js`, `index.html`, CSS, navigation, and styled views) or
> **existing app integration** (only SDK integration files: constants, context, hook, form, callbacks,
> protected route). This affects what files are generated in later steps.
>
> Ask for all `required` parameters up front in a single prompt. For optional parameters, show the
> default and ask whether the user wants to override it. Do **not** proceed to Step 1 until every
> required parameter has a non-empty value.

### Parameters to collect

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `wellknownUrl` | Yes | — | Full OIDC well-known endpoint URL (e.g., `https://your-tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration`) |
| `clientId` | Yes | — | OAuth 2.0 Client ID registered in PingAM / AIC for this web app |
| `scope` | Yes | `openid profile email` | Space-separated OAuth 2.0 scopes to request |
| `redirectUri` | No | `http://localhost:<appPort>/callback.html` | OAuth 2.0 redirect URI registered in PingAM / AIC |
| `journeyLogin` | No | `Login` | Name of the login Journey/Tree to invoke |
| `journeyRegister` | No | `Registration` | Name of the registration Journey/Tree to invoke |
| `appPort` | No | `8443` | Local development server port |

### Suggested prompts

```
Before I get started, I want to confirm — are you wanting me to help you create a sample app or
integrate with your existing single-page app?

Before I generate the files, I need a few details about your PingAM / AIC setup:

1. Well-known URL     — What is your OIDC well-known endpoint URL?
                        e.g. https://your-tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration
2. Client ID          — What is the OAuth 2.0 Client ID for this web app?
3. Scopes             — Which OAuth 2.0 scopes? (default: openid profile email)
4. Redirect URI       — What is the redirect URI? (default: http://localhost:8443/callback.html)
5. Login Journey      — Which Journey/Tree for login? (default: Login)
6. Register Journey   — Which Journey/Tree for registration? (default: Registration)
7. App Port           — Which port for local dev? (default: 8443)
```

### Validation rules

- `wellknownUrl` must start with `https://` and end with `/.well-known/openid-configuration`.
- `clientId` must be non-empty.
- If `scope` does not include `openid`, prepend it automatically and warn the user.
- `redirectUri` must be a valid URL starting with `https://` or `http://localhost`.
- If the user provides `redirectUri` with a port that differs from `appPort`, warn the user — they likely need to match.

### Well-known URL construction guidance

> **Agent instruction:** Users often provide a **base AM URL** (e.g., `https://your-tenant.forgeblocks.com/am`)
> instead of the full well-known URL. If the provided URL does **not** end with
> `/.well-known/openid-configuration`:
>
> 1. **Ask the user which realm** they are using (commonly `alpha` or `bravo` for AIC).
> 2. **Construct the well-known URL** as:
>    `<baseUrl>/oauth2/<realm>/.well-known/openid-configuration`
> 3. Strip any trailing `/` from the base URL before construction.
> 4. Confirm the constructed URL with the user before proceeding.
>
> Example:
> - User provides: `https://openam-myco.forgeblocks.com/am`
> - Agent asks: "Which realm? (commonly `alpha` or `bravo`)"
> - User says: `alpha`
> - Agent constructs: `https://openam-myco.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration`
> - Agent confirms: "I'll use this as your well-known URL — does that look correct?"

---

## Implementation Steps

### Step 1 — Configure Environment Variables

Create a `.env` file in the project root. See [.env template](assets/.env.template).

> **Agent instruction:** Substitute all `<parameter>` placeholders with values collected above.

```env
VITE_WELLKNOWN_URL=<wellknownUrl>
VITE_WEB_OAUTH_CLIENT=<clientId>
VITE_SCOPE=<scope>
VITE_PORT=<appPort>
VITE_JOURNEY_LOGIN=<journeyLogin>
VITE_JOURNEY_REGISTER=<journeyRegister>
VITE_REDIRECT_URI=<redirectUri>
VITE_DEBUGGER_OFF=true
```

---

### Step 2 — Create the Configuration Constants

Create `constants.js` to centralize SDK configuration. See [constants.js template](assets/constants.js.template).

The SDK configuration requires only the `wellknown` URL — the Journey client automatically derives the `baseUrl`, `authenticate`, and `sessions` endpoints from the well-known document.

```javascript
export const WELLKNOWN_URL = import.meta.env.VITE_WELLKNOWN_URL;
export const WEB_OAUTH_CLIENT = import.meta.env.VITE_WEB_OAUTH_CLIENT;
export const SCOPE = import.meta.env.VITE_SCOPE;
export const REDIRECT_URI = import.meta.env.VITE_REDIRECT_URI || `${window.location.origin}/callback.html`;

export const CONFIG = {
  clientId: WEB_OAUTH_CLIENT,
  redirectUri: REDIRECT_URI,
  scope: SCOPE,
  serverConfig: {
    wellknown: WELLKNOWN_URL,
  },
};
```

> **Note:** `VITE_REDIRECT_URI` allows the redirect URI to be configured via environment variable.
> If omitted, it defaults to `${window.location.origin}/callback.html`. This is important because
> local development may use `http://` while production uses `https://`, and the redirect URI must
> **exactly match** what is registered in PingAM / AIC.

See [Journey Client Reference](references/journey-client.md) for all configuration options.

---

### Step 3 — Create the OIDC Context Provider

Create `oidc.context.js` to manage authentication state across the application. See [oidc.context.js template](assets/oidc.context.js.template).

The OIDC context:
- Initializes the OIDC client on app mount
- Checks for existing tokens (session persistence)
- Provides `isAuthenticated`, `oidcClient`, and user info to all components
- Handles logout by revoking tokens and clearing state

```javascript
import { createContext } from 'react';
import { oidc } from '@forgerock/oidc-client';

export const OidcContext = createContext();

export function useInitOidcState(config) {
  // Initialize OIDC client and check for existing session
  // Returns [state, methods] for context consumption
}
```

See [OIDC Client Reference](references/oidc-client.md) for full API documentation.

---

### Step 4 — Create the Journey Hook

Create `journey.hook.js` — the core custom hook that manages the Journey authentication flow. See [journey.hook.js template](assets/journey.hook.js.template).

Key responsibilities:
- Initializes the Journey client with the shared `CONFIG`
- Starts a new Journey (or resumes after redirect)
- Handles step submission and advances to the next node
- On `LoginSuccess`, exchanges the session for OAuth tokens via the OIDC client
- On `LoginFailure`, extracts the error message and restarts the Journey
- Returns the current step for rendering and methods for form submission

```javascript
import { journey, callbackType } from '@forgerock/journey-client';

export default function useJourney({ formMetadata, resumeUrl }) {
  // Returns [state, methods]
  // state: { formFailureMessage, renderStep, submittingForm, user }
  // methods: { setSubmissionStep, setSubmittingForm, redirect }
}
```

See [Journey Client Reference](references/journey-client.md) for client API details.

---

### Step 5 — Create the Journey Form Component

Create `form.jsx` — the main form component that renders the current Journey step's callbacks. See [form.jsx template](assets/form.jsx.template).

The form:
- Uses `useJourney` to obtain the current step and submission methods
- Maps each callback in the step to its corresponding React component
- Handles form submission by setting the submission step
- Navigates away on `LoginSuccess`

```jsx
import { callbackType } from '@forgerock/journey-client';

export default function Form({ action, followUp, topMessage }) {
  // Maps callbacks to components and handles form lifecycle
}
```

See [Callback Types Reference](references/callbacks.md) for the full list of supported callbacks.

---

### Step 6 — Create Callback Components

Create individual React components for each callback type. See [callback component templates](assets/).

All callback types supported by `@forgerock/journey-client`:

| Callback Type | Component | Description |
|---------------|-----------|-------------|
| `NameCallback` | `Text` | Text input for username |
| `ValidatedCreateUsernameCallback` | `Text` | Validated username input with policy enforcement |
| `StringAttributeInputCallback` | `Text` | Generic string attribute (email, name, etc.) |
| `TextInputCallback` | `TextInput` | Generic text input field |
| `PasswordCallback` | `Password` | Password input with visibility toggle |
| `ValidatedCreatePasswordCallback` | `Password` | Validated password input with policy enforcement |
| `BooleanAttributeInputCallback` | `Boolean` | Checkbox toggle for boolean attributes |
| `NumberAttributeInputCallback` | `NumberInput` | Numeric input for number attributes |
| `ChoiceCallback` | `Choice` | Single-selection dropdown |
| `ConfirmationCallback` | `Confirmation` | Action options (Submit / Cancel) |
| `SelectIdPCallback` | `SelectIdP` | Social / external Identity Provider selection |
| `KbaCreateCallback` | `Kba` | Security question & answer |
| `TermsAndConditionsCallback` | `TermsConditions` | Terms acceptance checkbox |
| `TextOutputCallback` | `TextOutput` | Display server messages (info, warning, error) |
| `SuspendedTextOutputCallback` | `SuspendedTextOutput` | Suspended journey message (magic link / email verification) |
| `PollingWaitCallback` | `PollingWait` | Auto-advancing wait step (no user interaction) |
| `RedirectCallback` | `Redirect` | Browser redirect for external auth (social login, SAML) |
| `DeviceProfileCallback` | `DeviceProfile` | Auto-collects device metadata and submits |
| `HiddenValueCallback` | `HiddenValue` | Non-visual — carries internal state between client/server |
| `MetadataCallback` | `Metadata` | Non-visual — carries server metadata to client |
| `ReCaptchaCallback` | `ReCaptcha` | Google reCAPTCHA v2 widget |
| `ReCaptchaEnterpriseCallback` | `ReCaptchaEnterprise` | Google reCAPTCHA Enterprise widget |
| `PingOneProtectInitializeCallback` | `ProtectInitialize` | Initializes PingOne Protect threat signal collection |
| `PingOneProtectEvaluationCallback` | `ProtectEvaluation` | Collects and submits PingOne Protect threat signals |
| WebAuthn (FIDO2) | `WebAuthnComponent` | FIDO2/Passkey registration & authentication |

Each component follows this pattern:
1. **Get** display values from the callback (e.g., `callback.getPrompt()`)
2. **Render** an appropriate form element
3. **Set** user input back on the callback (e.g., `callback.setInputValue(value)`)

> **Note:** Auto-advancing callbacks (`PollingWaitCallback`, `DeviceProfileCallback`, `RedirectCallback`, `ReCaptchaCallback`, `ReCaptchaEnterpriseCallback`, `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback`) do not require user interaction — they automatically submit the step after completing their operation.

---

### Step 7 — Create the Login and Register Views

Create `login.jsx` and `register.jsx` views. See [login.jsx template](assets/login.jsx.template) and [register.jsx template](assets/register.jsx.template).

```jsx
// login.jsx — Renders the Form component with the login journey
export default function Login() {
  return <Form action={{ type: 'login' }} />;
}

// register.jsx — Renders the Form component with the registration journey
export default function Register() {
  return <Form action={{ type: 'register' }} />;
}
```

---

### Step 8 — Create the Logout View

Create `logout.jsx`. See [logout.jsx template](assets/logout.jsx.template).

Logout uses the OIDC context to revoke tokens and clear the session:

```jsx
import { useContext, useEffect } from 'react';
import { OidcContext } from '../context/oidc.context';

export default function Logout() {
  const [, { setAuthentication }] = useContext(OidcContext);
  useEffect(() => { setAuthentication(false); }, []);
  return <p>Logging out...</p>;
}
```

---

### Step 9 — Create Protected Route and Router

Create a `ProtectedRoute` component and the app router. See [route.jsx template](assets/route.jsx.template) and [router.jsx template](assets/router.jsx.template).

```jsx
// Protected route — redirects to /login if not authenticated
export function ProtectedRoute({ children }) {
  const [{ isAuthenticated }] = useContext(OidcContext);
  return isAuthenticated ? children : <Navigate to="/login" />;
}
```

---

### Step 10 — Create the Application Entry Point

Create `index.jsx` to bootstrap the app with context providers. See [index.jsx template](assets/index.jsx.template).

```jsx
import { OidcContext, useInitOidcState } from './context/oidc.context';
import { CONFIG } from './constants';

function App() {
  const oidcState = useInitOidcState(CONFIG);
  return (
    <OidcContext.Provider value={oidcState}>
      <Router />
    </OidcContext.Provider>
  );
}
```

---

### Step 11 — Create the OAuth Callback Page

Create `callback.html` in the `public/` directory to handle OAuth redirect responses. See [callback.html template](assets/callback.html.template).

This static HTML page captures the `code` and `state` parameters from the OAuth redirect and passes them back to the SPA.

---

### Step 12 — (Sample App Only) Create a User Profile View

> **Agent instruction:** Only generate this step if the user chose **Sample Application** mode,
> or if they explicitly request a profile page.

Create `profile.jsx` — a protected view that fetches and displays user information from the OIDC `userinfo` endpoint. Optionally includes an edit modal with Save/Cancel.

Key implementation:
- Use `oidcClient.user.info()` to fetch the full user profile from AIC
- Display all returned claims (sub, name, email, phone, address, etc.)
- Provide an "Edit Profile" button that opens a modal with form fields
- The modal should have **Save** and **Cancel** buttons
- Save updates the local display state (for server-side persistence, connect to the AIC IDM managed objects API)

```jsx
import { useContext, useState, useEffect } from 'react';
import { OidcContext } from '../context/oidc.context';

export default function Profile() {
  const [{ oidcClient }] = useContext(OidcContext);
  const [profile, setProfile] = useState(null);
  const [showEditModal, setShowEditModal] = useState(false);

  useEffect(() => {
    async function fetchProfile() {
      const userInfo = await oidcClient.user.info();
      if (!('error' in userInfo)) setProfile(userInfo);
    }
    fetchProfile();
  }, [oidcClient]);

  // Render profile fields and edit modal...
}
```

**Common userinfo claims from AIC:**

| Claim | Description |
|-------|-------------|
| `sub` | Subject identifier (user ID) |
| `name` | Full display name |
| `given_name` | First name |
| `family_name` | Last name |
| `email` | Email address |
| `email_verified` | Whether email has been verified |
| `phone_number` | Phone number |
| `address` | Address object (`formatted`, `street_address`, etc.) |
| `updated_at` | Unix timestamp of last profile update |

> **Note on server-side profile updates:** To persist profile edits to AIC, you need to call the
> AIC IDM managed objects REST API (`/openidm/managed/alpha_user/<userId>`) with the user's access
> token. This requires the OAuth client to have appropriate scopes and the access token to include
> the `fr:idm:*` scope or equivalent. For a sample app, updating local display state is sufficient
> to demonstrate the pattern.

---

### Step 13 — (Sample App Only) Add Navigation and Styling

> **Agent instruction:** Only generate this step if the user chose **Sample Application** mode.

For a complete sample app, create:

1. **A Navbar component** (`client/components/navbar.jsx`) — Sticky top navigation with links to the main views (Home/Gallery, Profile) and a logout button. Show the authenticated user's name.

2. **A CSS stylesheet** (`client/styles.css`) — Import in `index.jsx`. Should include at minimum:
   - Global reset and base typography
   - Form field styling (inputs, labels, selects, buttons)
   - Glass-morphism or card-based layout for auth forms
   - Navigation bar styles
   - Image grid / card grid for content pages
   - Modal/overlay styles for edit dialogs
   - Responsive breakpoints for mobile
   - Loading spinners and status indicators

3. **A themed Home view** — Replace the basic home template with content relevant to the user's request. The home view should show different content for authenticated vs unauthenticated users.

```jsx
// Example Navbar pattern
import { useContext } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { OidcContext } from '../context/oidc.context';

export default function Navbar() {
  const [{ username }] = useContext(OidcContext);
  return (
    <nav className="navbar">
      <Link to="/">Home</Link>
      <Link to="/profile">My Profile</Link>
      <span>{username}</span>
      <Link to="/logout">Logout</Link>
    </nav>
  );
}
```

> **Agent instruction for sample apps:** When the user describes a theme or purpose for their sample
> app (e.g., "space images", "recipe app", "fitness tracker"), create the Home view content, styling,
> and any additional views to match that theme. The goal is a polished, visually appealing demo that
> showcases both the Ping SDK integration and the user's desired experience. Always include:
> - A visually distinct login/register page
> - A navbar with logout and profile links (when authenticated)
> - A home page with themed content (when authenticated) and a call-to-action (when not)
> - A profile page behind a protected route

---

### Step 14 — (Sample App Only) Wire the Router with All Views

> **Agent instruction:** Only generate this step if the user chose **Sample Application** mode.

Update `router.jsx` to include routes for all views including the profile page:

```jsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { ProtectedRoute } from './components/utilities/route';
import Home from './views/home';
import Login from './views/login';
import Logout from './views/logout';
import Register from './views/register';
import Profile from './views/profile';

export default function Router() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/logout" element={<Logout />} />
        <Route
          path="/profile"
          element={
            <ProtectedRoute>
              <Profile />
            </ProtectedRoute>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}
```

---

## Scaffolding Script

For quick setup, use the scaffolding script to copy all template files into your project:

```bash
chmod +x scripts/scaffold_auth.sh
./scripts/scaffold_auth.sh \
    --project-dir ./my-react-app \
    --journey Login
```

See [scaffold_auth.sh](scripts/scaffold_auth.sh) for details.

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| CORS not configured | Ensure your PingAM / AIC tenant allows your app origin, methods, and headers |
| Missing `openid` scope | Always include `openid` — required for OIDC token exchange |
| Wrong well-known URL | Must end with `/.well-known/openid-configuration` and include the correct realm. Users often provide just the base AM URL — ask for the realm and construct the full URL. |
| Using base AM URL instead of well-known URL | If the user provides `https://tenant.forgeblocks.com/am`, ask which realm (`alpha`/`bravo`) and construct: `<baseUrl>/oauth2/<realm>/.well-known/openid-configuration` |
| Unhandled callback type | Add a case in the `mapCallbacksToComponents` function for every callback your Journey uses |
| Not calling `callback.setInputValue()` | Always set callback values before submitting the step — the SDK sends the values you set |
| Redirect URI mismatch | The `redirectUri` in your config must exactly match the one registered in PingAM / AIC — including protocol (`http` vs `https`) and port number |
| Redirect URI port vs app port mismatch | If the user specifies `redirectUri` on port 8443 but `appPort` on 8444 (or vice versa), warn them — these must match for the OAuth flow to work |
| Mixed HTTP/HTTPS | The SDK requires HTTPS in production; for local dev, `http://localhost` is acceptable if the OAuth client in AIC is configured with an `http://localhost` redirect URI |
| Token exchange before `LoginSuccess` | Only call `oidcClient.authorize.background()` after the Journey returns a `LoginSuccess` step |
| Not handling `LoginFailure` | Always check for `LoginFailure` after `client.next()` — restart the journey and display the error |
| Calling `client.next()` without setting callbacks | Always populate callback values before advancing to the next step |
| Importing `oidc` in constants.js | The constants file only exports configuration — it does not import or use `@forgerock/oidc-client` directly. The OIDC client is initialized in `oidc.context.js`. |
| Not generating `styles.css` for sample apps | Sample apps need a stylesheet for form fields, buttons, layouts, and modals. Always create `client/styles.css` and import it in `index.jsx`. |
| Forgetting `callback.html` in `public/` | The OAuth callback page must be a static HTML file in the `public/` directory, not a React route. Without it, the OAuth redirect will fail with a blank page. |

---

## Reference Documentation

- [Journey Client Reference](references/journey-client.md) — Journey client configuration, methods, step types, callback access
- [Callback Types Reference](references/callbacks.md) — All supported callback types and their getter/setter methods
- [OIDC Client Reference](references/oidc-client.md) — OIDC client setup, token management, user operations

---

## Related Skills

- `ping-quickstart` — Platform detection and Ping Identity orientation
- `ping-orchestration-android-journey-sdk` — Android (Kotlin/Jetpack Compose) implementation of the same pattern
