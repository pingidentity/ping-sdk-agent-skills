# Journey Client Reference

## Overview

`@forgerock/journey-client` is the primary package for Journey/Tree-based authentication in the Ping Identity Orchestration JavaScript SDK. It provides a stateful client that manages the full authentication flow against **PingOne Advanced Identity Cloud (AIC)** or **PingAM**.

> **Note:** For PingOne DaVinci flows, use `@forgerock/davinci-client` instead. This client is specifically for Journey/Tree-based authentication.

**Repository:** [ping-javascript-sdk](https://github.com/ForgeRock/ping-javascript-sdk/)

---

## Installation

```bash
npm install @forgerock/journey-client
```

---

## Creating a Journey Client

The Journey client requires only a `wellknown` URL. It automatically derives all other endpoints from the OIDC discovery document.

```javascript
import { journey, callbackType } from '@forgerock/journey-client';

const client = await journey({
  config: {
    serverConfig: {
      wellknown: 'https://<tenant>.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration',
    },
  },
});
```

### Automatic Endpoint Derivation

The client parses the well-known document and derives:

| Field | Derived From |
|-------|-------------|
| `baseUrl` | `authorization_endpoint` origin |
| `authenticate` | Issuer path with `/oauth2` replaced by `/json` + `/authenticate` appended |
| `sessions` | Issuer path with `/oauth2` replaced by `/json` + `/sessions/` appended |

This means you do **not** need to manually construct API paths — the well-known URL is the single source of truth.

### Full Configuration Options

```javascript
const client = await journey({
  config: {
    serverConfig: {
      wellknown: 'https://<tenant>.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration',
      timeout: 30000, // Optional: network timeout in ms
    },
  },
  requestMiddleware: [loggingMiddleware], // Optional: request interceptors
});
```

---

## Client Methods

### `client.start(options)`

Initiates a new Journey (authentication tree).

```javascript
const step = await client.start({ journey: 'Login' });
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `journey` | `string` | Yes | Name of the Journey/Tree configured in PingAM / AIC |
| `query` | `object` | No | Additional query parameters to pass |

**Returns:** `JourneyStep | JourneyLoginSuccess | JourneyLoginFailure`

---

### `client.next(step, options)`

Submits the current step and retrieves the next step in the Journey.

```javascript
// Set callback values first
const nameCallback = step.getCallbackOfType(callbackType.NameCallback);
nameCallback.setName('johndoe');

// Then advance
const nextStep = await client.next(step);
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `step` | `JourneyStep` | Yes | The current step with populated callback values |
| `query` | `object` | No | Additional query parameters |

**Returns:** `JourneyStep | JourneyLoginSuccess | JourneyLoginFailure`

---

### `client.redirect(step)`

Handles a `RedirectCallback` by redirecting the browser to the external provider (e.g., social login).

```javascript
// When the step contains a RedirectCallback
client.redirect(step);
// The browser navigates away — execution does not continue past this point
```

---

### `client.resume(url, options)`

Resumes a Journey after the browser returns from an external redirect (e.g., social login callback, magic link).

```javascript
const resumeStep = await client.resume(window.location.href, {
  journey: 'Login', // Optional: specify the journey name
});
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | `string` | Yes | The current page URL containing the redirect parameters |
| `journey` | `string` | No | Journey name to resume (if known) |

**Returns:** `JourneyStep | JourneyLoginSuccess | JourneyLoginFailure`

---

### `client.terminate()`

Ends the current session.

```javascript
await client.terminate();
```

---

## Step Types

After calling `client.start()` or `client.next()`, the returned object has a `type` property:

| Type | Description | Key Properties |
|------|-------------|----------------|
| `Step` | The Journey requires more input — contains callbacks to render | `callbacks`, `getCallbacksOfType()`, `getCallbackOfType()`, `stage`, `header`, `description` |
| `LoginSuccess` | Authentication succeeded | `tokenId` (SSO session token), `successUrl` |
| `LoginFailure` | Authentication failed | `code`, `reason`, `message`, `detail` |

### Working with Steps

```javascript
switch (step.type) {
  case 'Step':
    // Render callbacks and collect user input
    break;
  case 'LoginSuccess':
    // Exchange session for OAuth tokens via OIDC client
    break;
  case 'LoginFailure':
    // Display error and optionally restart the journey
    break;
}
```

---

## Working with Callbacks

### Accessing Callbacks

```javascript
// Get all callbacks of a specific type
const nameCallbacks = step.getCallbacksOfType(callbackType.NameCallback);

// Get exactly one callback of a type (throws if not exactly one)
const nameCallback = step.getCallbackOfType(callbackType.NameCallback);

// Iterate over all callbacks
step.callbacks.forEach((callback) => {
  // Process each callback
});
```

### Available Callback Types

Import callback types from the SDK:

```javascript
import { callbackType } from '@forgerock/journey-client';

// Usage:
callbackType.NameCallback
callbackType.PasswordCallback
callbackType.ChoiceCallback
callbackType.ConfirmationCallback
callbackType.TextOutputCallback
callbackType.BooleanAttributeInputCallback
callbackType.StringAttributeInputCallback
callbackType.ValidatedCreateUsernameCallback
callbackType.ValidatedCreatePasswordCallback
callbackType.KbaCreateCallback
callbackType.TermsAndConditionsCallback
callbackType.SelectIdPCallback
callbackType.RedirectCallback
callbackType.PingOneProtectInitializeCallback
callbackType.PingOneProtectEvaluationCallback
// ... and more
```

### Getting Callback Input Names

Each callback has a unique input name used for form field identification:

```javascript
const inputName = callback.payload?.input?.[0]?.name;
```

---

## Request Middleware

You can intercept and modify requests using middleware:

```javascript
const loggingMiddleware = (req, action, next) => {
  console.log(`${action.type}: ${req.url}`);
  next();
};

const authHeaderMiddleware = (req, action, next) => {
  req.init.headers = {
    ...req.init.headers,
    'X-Custom-Header': 'value',
  };
  next();
};

const client = await journey({
  config: { serverConfig: { wellknown: '...' } },
  requestMiddleware: [loggingMiddleware, authHeaderMiddleware],
});
```

### Middleware Actions

| Action Type | Triggered By |
|-------------|-------------|
| `JOURNEY_START` | `client.start()` |
| `JOURNEY_NEXT` | `client.next()` |
| `JOURNEY_TERMINATE` | `client.terminate()` |

---

## WebAuthn Support

The Journey client includes WebAuthn (FIDO2) support for passkey registration and authentication:

```javascript
import { WebAuthn, WebAuthnStepType } from '@forgerock/journey-client/webauthn';

// Check if the step is a WebAuthn step
const webAuthnType = WebAuthn.getWebAuthnStepType(step);

if (webAuthnType === WebAuthnStepType.Registration) {
  // Handle WebAuthn registration
  await WebAuthn.register(step);
} else if (webAuthnType === WebAuthnStepType.Authentication) {
  // Handle WebAuthn authentication
  await WebAuthn.authenticate(step);
}
```

---

## Common Authentication Flow Pattern

```javascript
import { journey, callbackType } from '@forgerock/journey-client';

// 1. Create the client
const client = await journey({
  config: {
    serverConfig: {
      wellknown: 'https://tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration',
    },
  },
});

// 2. Start the journey
let step = await client.start({ journey: 'Login' });

// 3. Process steps in a loop
while (step.type === 'Step') {
  // Populate callbacks with user input
  step.callbacks.forEach((callback) => {
    if (callback.getType() === callbackType.NameCallback) {
      callback.setName(username);
    }
    if (callback.getType() === callbackType.PasswordCallback) {
      callback.setPassword(password);
    }
  });

  // Submit and get next step
  step = await client.next(step);
}

// 4. Handle result
if (step.type === 'LoginSuccess') {
  console.log('Authenticated!');
} else if (step.type === 'LoginFailure') {
  console.error('Failed:', step.message);
}
```

---

## Imports Cheatsheet

```javascript
// Journey client
import { journey, callbackType } from '@forgerock/journey-client';

// WebAuthn support
import { WebAuthn, WebAuthnStepType } from '@forgerock/journey-client/webauthn';

// OIDC client (used after LoginSuccess for token exchange)
import { oidc } from '@forgerock/oidc-client';

// PingOne Protect (optional)
import { protect } from '@forgerock/protect';
```
