---
name: ping-orchestration-reactjs-js-davinci-sdk
description: Use when building ReactJS web authentication with the Ping Orchestration JavaScript SDK (DaVinci) — scaffolds a complete React SPA authentication flow against PingOne DaVinci. Handles DaVinci client configuration, OIDC token exchange, dynamic collector rendering, protected routes, user profile, and logout.
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---

# ReactJS Authentication with Ping Orchestration JavaScript SDK (DaVinci)

Scaffold a complete authentication flow in a ReactJS single-page application using the Ping Orchestration JavaScript SDK (DaVinci).

---

## Metadata

| Field       | Value |
|-------------|-------|
| Language    | JavaScript (JSX) |
| Framework   | React 18+, React Router 6+, Vite |
| SDK         | Ping Identity DaVinci Client (`@forgerock/davinci-client`) |
| Pattern     | Functional Components, Custom Hooks, Context API |
| Node.js     | >= 18.12.0 |

---

## Overview

This skill adds a complete **authentication flow** to a ReactJS single-page application. It uses the **Ping Identity DaVinci Client** (`@forgerock/davinci-client`) to authenticate users against **PingOne DaVinci**.

> **DaVinci vs Journey:** DaVinci uses **PingOne** as the orchestration server (not PingAM/AIC). It uses the `@forgerock/davinci-client` package (not `@forgerock/journey-client`). DaVinci uses **Collectors** instead of Callbacks, and node status values (`continue`, `success`, `error`) instead of step types.

The implementation covers:
- DaVinci client initialization with OIDC configuration
- Custom React hook (`useDavinci`) for managing the step-by-step authentication flow
- Dynamic collector rendering with dedicated React components for each collector type
- Collector categories: `SingleValueCollector`, `ActionCollector`, `ObjectValueCollector`, `MultiValueCollector`, `NoValueCollector`
- Flow navigation via `FlowCollector` and form submission via `SubmitCollector`
- Protected route handling with React Router
- Context-based authentication state management
- Login and logout flows
- User profile display via OIDC userinfo
- Success, error, and failure handling

### Use Cases

1. **Sample Application** — Build a complete, themed ReactJS app from scratch to demonstrate how the DaVinci SDK works with PingOne DaVinci. This includes all SDK integration files **plus** a full UI with navigation, styled views, a user profile page, and protected content.
2. **Existing Application Integration** — Integrate the DaVinci SDK into an existing ReactJS SPA to add authentication. The agent should generate **only** the SDK integration files (constants, context, hook, form, collectors) and guide the user on wiring them into their existing router and layout.

---

## Prerequisites

### 1. npm Dependencies

Install the following packages in your React project:

```bash
npm install @forgerock/davinci-client react react-dom react-router-dom
```

Optional dependencies for additional features:

```bash
# PingOne Protect integration
npm install @forgerock/protect

# OIDC client for token management post-authentication
npm install @forgerock/oidc-client
```

See [package.json template](assets/package.json.template) for a complete example.

### 2. Vite Configuration

This skill uses [Vite](https://vitejs.dev/) as the build tool. See [vite.config.js template](assets/vite.config.js.template) for the recommended configuration.

```bash
npm install --save-dev vite @vitejs/plugin-react
```

### 3. Environment Variables

Create a `.env` file in your project root. See [.env template](assets/.env.template).

```env
VITE_CLIENT_ID=your-client-id
VITE_DISCOVERY_ENDPOINT=https://auth.pingone.com/<envId>/as/.well-known/openid-configuration
VITE_REDIRECT_URI=http://localhost:5173/callback
VITE_SCOPE=openid email profile
```

---

## Required Configuration

> **Agent instruction:** Before generating any file, collect the values below from the user.
> Ask for all `required` parameters up front in a single prompt. For optional parameters, show the
> default and ask whether the user wants to override it. Do **not** proceed to Step 1 until every
> required parameter has a non-empty value.

### Parameters to collect

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `clientId` | Yes | — | OAuth 2.0 Client ID registered in PingOne for this web app |
| `serverConfig.wellknown` | Yes | — | Full OIDC discovery endpoint URL from PingOne |
| `scope` | Yes | `openid email profile` | Space-separated OAuth 2.0 scopes |
| `redirectUri` | Yes | `http://localhost:5173/callback` | OAuth 2.0 redirect URI |

### Suggested prompts

```
Before I generate the files, I need a few details about your PingOne DaVinci setup:

1. Client ID           — What is the OAuth 2.0 Client ID for this web app?
                         (From your PingOne OIDC Web App configuration)
2. Well-Known URL      — What is the OIDC discovery endpoint?
                         e.g. https://auth.pingone.com/<envId>/as/.well-known/openid-configuration
3. Scopes              — Which OAuth 2.0 scopes? (default: openid email profile)
4. Redirect URI        — What is the redirect URI? (default: http://localhost:5173/callback)
```

### Validation rules

- `serverConfig.wellknown` must end with `/.well-known/openid-configuration`.
- `clientId` must be non-empty.
- `redirectUri` must be a valid URL.
- If `scope` does not include `openid`, prepend it automatically and warn the user.

---

## Implementation Steps

### Step 1 — Create Constants

Create `constants.js`. See [constants.js template](assets/constants.js.template).

```javascript
export const DAVINCI_CONFIG = {
  clientId: import.meta.env.VITE_CLIENT_ID,
  serverConfig: {
    wellknown: import.meta.env.VITE_DISCOVERY_ENDPOINT,
  },
  scope: import.meta.env.VITE_SCOPE,
  redirectUri: import.meta.env.VITE_REDIRECT_URI,
};
```

See [DaVinci SDK API Reference](references/davinci-sdk.md) for all configuration options.

---

### Step 2 — Create the DaVinci Hook

Create `use-davinci.hook.js`. See [use-davinci.hook.js template](assets/use-davinci.hook.js.template).

Key responsibilities:
- Initialize the DaVinci client via `davinci({ config })`
- Manage node state (`continue`, `success`, `error`, `start`)
- Expose `getClient()`, `getCollectors()`, `update()`, `flow()`, `next()` methods
- Handle flow navigation and form submission

---

### Step 3 — Create the Form Component

Create `form.jsx`. See [form.jsx template](assets/form.jsx.template).

The form component dispatches each collector to its dedicated React component:

```jsx
function mapCollectorsToComponents(davinciClient, collectors, submitForm) {
    return collectors.map((collector) => {
        switch (collector.type) {
            case 'TextCollector': return <TextCollector key={collector.id} collector={collector} updater={davinciClient.update(collector)} />;
            case 'PasswordCollector': return <PasswordCollector key={collector.id} collector={collector} updater={davinciClient.update(collector)} />;
            case 'SubmitCollector': return <SubmitButton key={collector.id} collector={collector} submitForm={submitForm} />;
            case 'FlowCollector': return <FlowButton key={collector.id} collector={collector} startFlow={davinciClient.flow({ action: collector.output.key })} />;
            // ... more collectors
        }
    });
}
```

See [Collector Types Reference](references/collectors.md) for the full list of supported collectors.

---

### Step 4 — Create Collector Components

Create individual React component files for each collector type. See the `assets/` directory for all templates.

All collector types supported by the Ping JavaScript DaVinci SDK:

**Single Value Collectors:**

| Collector Type | Component | Category | Description |
|----------------|-----------|----------|-------------|
| `TextCollector` | `TextCollector` | `SingleValueCollector` | Text input (username, email) |
| `PasswordCollector` | `PasswordCollector` | `SingleValueCollector` | Secure password input |
| `SingleSelectCollector` | `SingleSelectCollector` | `SingleValueCollector` | Dropdown/radio selection |

**Validated Collectors:**

| Collector Type | Component | Category | Description |
|----------------|-----------|----------|-------------|
| `ValidatedTextCollector` | `TextCollector` | `ValidatedSingleValueCollector` | Text input with validation rules |

**Action Collectors:**

| Collector Type | Component | Category | Description |
|----------------|-----------|----------|-------------|
| `SubmitCollector` | `SubmitButton` | `ActionCollector` | Form submission button |
| `FlowCollector` | `FlowButton` | `ActionCollector` | Flow navigation button/link |
| `IdpCollector` | `SocialLoginButton` | `ActionCollector` | Social login (Google, Facebook, Apple) |

**Multi-Value Collectors:**

| Collector Type | Component | Category | Description |
|----------------|-----------|----------|-------------|
| `MultiSelectCollector` | `MultiSelectCollector` | `MultiValueCollector` | Multi-select checkboxes |

**Object Value Collectors:**

| Collector Type | Component | Category | Description |
|----------------|-----------|----------|-------------|
| `DeviceRegistrationCollector` | `DeviceRegistration` | `ObjectValueCollector` | MFA device registration |
| `DeviceAuthenticationCollector` | `DeviceAuthentication` | `ObjectValueCollector` | MFA device authentication |
| `PhoneNumberCollector` | `PhoneNumber` | `ObjectValueCollector` | Phone number input |

**No-Value / Read-Only Collectors:**

| Collector Type | Component | Category | Description |
|----------------|-----------|----------|-------------|
| `ReadOnlyCollector` | `ReadOnly` | `NoValueCollector` | Static text/label display |

**Auto-Advancing Collectors:**

| Collector Type | Component | Category | Description |
|----------------|-----------|----------|-------------|
| `ProtectCollector` | `Protect` | `SingleValueAutoCollector` | PingOne Protect risk signals |
| `FidoRegistrationCollector` | `FidoRegistration` | `ObjectValueAutoCollector` | FIDO2 passkey / security-key registration |
| `FidoAuthenticationCollector` | `FidoAuthentication` | `ObjectValueAutoCollector` | FIDO2 passkey / security-key authentication |

Each collector component follows this pattern:
1. **Receive** the collector object and an updater/flow function as props
2. **Render** an appropriate HTML/React control
3. **Call** the updater with user input: `updater(value)` for value collectors
4. **Call** the flow function for `FlowCollector`: `startFlow()` navigates to new flow
5. **Call** `submitForm()` for `SubmitCollector`: advances to next node

> **Key API Methods:**
> - `davinciClient.update(collector)` — Returns an updater function for value collectors
> - `davinciClient.flow({ action: collector.output.key })` — Returns a function to start a new flow
> - `davinciClient.next()` — Submits the current node and advances to the next
> - `davinciClient.validate(collector)` — Returns a validator function for validated collectors

---

### Step 5 — Create the Login Page

Create `login.jsx`. See [login.jsx template](assets/login.jsx.template).

```jsx
export default function Login() {
    const { davinciClient, clientInfo, collectors, submitForm, startFlow, error } = useDavinci();

    if (!clientInfo || clientInfo.status === 'start') return <p>Loading...</p>;
    if (clientInfo.status === 'success') return <Navigate to="/home" />;

    return (
        <form onSubmit={(e) => { e.preventDefault(); submitForm(); }}>
            <h2>{clientInfo.name}</h2>
            {error && <div className="error">{error.message}</div>}
            <DaVinciForm davinciClient={davinciClient} collectors={collectors} submitForm={submitForm} />
        </form>
    );
}
```

---

### Step 6 — Create the OAuth Callback Page

Create `callback.jsx`. See [callback.jsx template](assets/callback.jsx.template).

---

### Step 7 — Wire Navigation

```jsx
<BrowserRouter>
    <Routes>
        <Route path="/" element={<Login />} />
        <Route path="/callback" element={<Callback />} />
        <Route path="/home" element={<ProtectedRoute><Home /></ProtectedRoute>} />
    </Routes>
</BrowserRouter>
```

---

## Scaffolding Script

For quick setup, use the scaffolding script to copy all template files into your project:

```bash
chmod +x scripts/scaffold_auth.sh
./scripts/scaffold_auth.sh \
    --target-dir src
```

See [scaffold_auth.sh](scripts/scaffold_auth.sh) for details.

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `@forgerock/journey-client` instead of `@forgerock/davinci-client` | DaVinci uses a separate package — install `@forgerock/davinci-client` |
| Missing `openid` scope | Always include `openid` — required for OIDC token exchange |
| Wrong discovery endpoint | Must end with `/.well-known/openid-configuration` and point to your PingOne environment |
| Calling `update()` without the collector | `davinciClient.update(collector)` requires the collector object as argument |
| Not calling `flow()` for FlowCollector | Flow navigation requires `davinciClient.flow({ action: collector.output.key })`, not `next()` |
| Hardcoding credentials | Use environment variables — never commit secrets |
| Not handling `error` status | Check `clientInfo.status === 'error'` and display error messages from `davinciClient.getError()` |
| Confusing collector categories | Check `collector.category` (`SingleValueCollector`, `ActionCollector`, etc.) to determine how to handle each collector |

---

## Reference Documentation

- [DaVinci SDK API Reference](references/davinci-sdk.md) — DaVinci client, node types, collector API
- [Collector Types Reference](references/collectors.md) — All supported collector types and their properties
- [OIDC Configuration Reference](references/oidc-config.md) — OIDC client setup, discovery endpoint

---

## Related Skills

- `ping-quickstart` — Platform detection and Ping Identity orientation
- `ping-orchestration-reactjs-js-journey-sdk` — ReactJS authentication using the Journey module (for PingOne AIC/PingAM)
