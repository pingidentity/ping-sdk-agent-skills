# DaVinci SDK API Reference (JavaScript)

## Overview

The `@forgerock/davinci-client` package provides a client for interacting with PingOne DaVinci flows
from JavaScript/TypeScript applications.

> **DaVinci vs Journey:** DaVinci uses `@forgerock/davinci-client` (not `@forgerock/journey-client`).
> It uses **Collectors** instead of Callbacks. Node status values are `start`, `continue`, `success`, `error`.

---

## Initializing the Client

```javascript
import { davinci } from '@forgerock/davinci-client';

const davinciClient = await davinci({
    config: {
        clientId: 'your-client-id',
        serverConfig: {
            wellknown: 'https://auth.pingone.com/<envId>/as/.well-known/openid-configuration',
        },
        scope: 'openid email profile',
        redirectUri: 'http://localhost:5173/callback',
    },
});
```

---

## Client API Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `davinciClient.getClient()` | `{ status, name, action, ... }` | Get current node state |
| `davinciClient.getCollectors()` | `Collector[]` | Get collectors for the current node |
| `davinciClient.getError()` | `Error \| null` | Get error from current node (if status is `error`) |
| `davinciClient.update(collector)` | `Updater` | Returns an updater function for a value collector |
| `davinciClient.validate(collector)` | `Validator` | Returns a validator function for a validated collector |
| `davinciClient.flow({ action })` | `() => Promise` | Returns a function to navigate to a different flow |
| `davinciClient.next()` | `Promise<NodeStates>` | Submits the current node and advances |
| `davinciClient.getNode()` | `NodeStates` | Get the full node state object |

---

## Node Status Values

| Status | Description |
|--------|-------------|
| `start` | Initial state before any flow has started |
| `continue` | Flow is in progress, collectors are available for user interaction |
| `success` | Authentication completed successfully |
| `error` | An error occurred (may include collectors for re-rendering) |

```javascript
const clientInfo = davinciClient.getClient();

switch (clientInfo?.status) {
    case 'continue':
        // Render form with collectors
        const collectors = davinciClient.getCollectors();
        break;
    case 'success':
        // Authentication succeeded — redirect to protected content
        break;
    case 'error':
        // Show error — may have collectors for re-rendering
        const error = davinciClient.getError();
        break;
}
```

---

## Collector Categories

Collectors are plain objects with a `category` and `type` property:

| Category | Description | Has `input` | Has Updater |
|----------|-------------|-------------|-------------|
| `SingleValueCollector` | Collects a single string value | ✅ | ✅ |
| `ValidatedSingleValueCollector` | Single value with validation rules | ✅ | ✅ |
| `ActionCollector` | Triggers an action (submit, flow) | ❌ | ❌ |
| `MultiValueCollector` | Collects multiple values | ✅ | ✅ |
| `ObjectValueCollector` | Collects object/structured values | ✅ | ✅ |
| `NoValueCollector` | Display-only, no user input | ❌ | ❌ |
| `SingleValueAutoCollector` | Auto-collecting (PingOne Protect) | ✅ | ✅ |

### Updating Collector Values

```javascript
// For SingleValueCollector (TextCollector, PasswordCollector, SingleSelectCollector)
const updater = davinciClient.update(collector);
updater('user input value');

// For MultiValueCollector (MultiSelectCollector)
const updater = davinciClient.update(collector);
updater(['option1', 'option2']);

// For ObjectValueCollector (PhoneNumberCollector, DeviceRegistration, DeviceAuthentication)
const updater = davinciClient.update(collector);
updater({ id: 'device-id', type: 'EMAIL' });
```

### Flow Navigation

```javascript
// For FlowCollector — start a different flow branch
const startFlow = davinciClient.flow({ action: collector.output.key });
await startFlow();
// After calling startFlow(), call getClient()/getCollectors() to get new state
```

### Validation

```javascript
// For ValidatedTextCollector
const validator = davinciClient.validate(collector);
const errors = validator('user input');
// Returns string[] of error messages, or empty array if valid
```

---

## Collector Object Structure

### SingleValueCollector (TextCollector, PasswordCollector)

```javascript
{
    category: 'SingleValueCollector',
    type: 'TextCollector',           // or 'PasswordCollector'
    id: 'username-0',
    name: 'username',
    error: null,
    input: {
        key: 'username',
        value: '',                   // Current value
        type: 'TEXT',
    },
    output: {
        key: 'username',
        label: 'Username',
        type: 'TEXT',
        value: '',                   // Default/prefill value
    },
}
```

### ActionCollector (SubmitCollector, FlowCollector, IdpCollector)

```javascript
{
    category: 'ActionCollector',
    type: 'SubmitCollector',         // or 'FlowCollector', 'IdpCollector'
    id: 'submit-0',
    name: 'submit',
    error: null,
    output: {
        key: 'submit',
        label: 'Sign On',
        type: 'SUBMIT_BUTTON',
        url: null,                   // IdpCollector has an auth URL here
    },
}
```

---

## PingOne OIDC Web App Setup

DaVinci requires a **PingOne OIDC Web App**:

1. In the PingOne admin console, go to **Applications** → **Applications**
2. Create a new **OIDC Web App** application
3. Set the **Redirect URIs** to match your `redirectUri` (e.g., `http://localhost:5173/callback`)
4. Set the **Grant Types** to include `Authorization Code`
5. Enable **PKCE**
6. Note the **Client ID** and **Environment ID**
7. The discovery endpoint: `https://auth.pingone.com/<environmentId>/as/.well-known/openid-configuration`
