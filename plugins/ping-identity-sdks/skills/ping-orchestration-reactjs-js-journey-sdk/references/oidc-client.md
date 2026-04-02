# OIDC Client Reference

## Overview

`@forgerock/oidc-client` is the OIDC/OAuth 2.0 client for the Ping Identity Orchestration JavaScript SDK. It handles token exchange, renewal, revocation, user info retrieval, and session management.

In a typical ReactJS Journey flow, the OIDC client is used **after** a successful Journey authentication (`LoginSuccess`) to exchange the session for OAuth 2.0 tokens.

**Repository:** [ping-javascript-sdk](https://github.com/ForgeRock/ping-javascript-sdk/)

---

## Installation

```bash
npm install @forgerock/oidc-client
```

---

## Creating an OIDC Client

```javascript
import { oidc } from '@forgerock/oidc-client';

const oidcClient = await oidc({
  config: {
    serverConfig: {
      wellknown: 'https://<tenant>.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration',
    },
    clientId: '<your-client-id>',
    redirectUri: 'https://localhost:8443/callback.html',
    scope: 'openid profile email',
  },
});
```

---

## All Configuration Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `serverConfig.wellknown` | `string` | Yes | OIDC discovery URL (`.well-known/openid-configuration`) |
| `clientId` | `string` | Yes | OAuth 2.0 client ID registered in PingAM / AIC |
| `redirectUri` | `string` | Yes | OAuth 2.0 redirect URI for authorization code flow |
| `scope` | `string` | Yes | Space-separated OAuth 2.0 scopes (always include `openid`) |
| `storage` | `object` | No | Custom token storage configuration |
| `timeout` | `number` | No | Network timeout in milliseconds |
| `additionalParameters` | `object` | No | Extra parameters for authorization requests |

---

## API Methods

### Authorization

#### `oidcClient.authorize.url(options?)`

Creates an authorization URL for redirect-based login (centralized login).

```javascript
const authUrl = await oidcClient.authorize.url();
// Redirect the browser to authUrl
window.location.assign(authUrl);
```

#### `oidcClient.authorize.background(options?)`

Performs background authorization without user interaction — uses the existing SSO session (after a successful Journey `LoginSuccess`).

```javascript
const response = await oidcClient.authorize.background();

if ('code' in response && 'state' in response) {
  // Exchange code for tokens
  await oidcClient.token.exchange(response.code, response.state);
} else if ('error' in response) {
  console.error('Authorization failed:', response.error);
}
```

**This is the primary method used after Journey authentication** to silently obtain an authorization code using the session cookie, then exchange it for tokens.

---

### Token Management

#### `oidcClient.token.exchange(code, state, options?)`

Exchanges an authorization code for access, ID, and refresh tokens. Tokens are automatically stored.

```javascript
const tokenResponse = await oidcClient.token.exchange(code, state);

if ('error' in tokenResponse) {
  console.error('Token exchange failed:', tokenResponse.error);
} else {
  // Tokens are stored automatically
}
```

#### `oidcClient.token.get(options?)`

Retrieves stored tokens. Optionally refreshes expired tokens.

```javascript
const tokens = await oidcClient.token.get();

if ('error' in tokens) {
  // No valid tokens — user is not authenticated
} else {
  const { accessToken, idToken, refreshToken } = tokens;
}
```

**Options:**

| Option | Type | Description |
|--------|------|-------------|
| `forceRenew` | `boolean` | Force token refresh even if not expired |
| `backgroundRenew` | `boolean` | Attempt silent token renewal via iframe |

#### `oidcClient.token.revoke()`

Revokes the current access token.

```javascript
await oidcClient.token.revoke();
```

---

### User Operations

#### `oidcClient.user.info()`

Retrieves user information from the OIDC `userinfo` endpoint.

```javascript
const userInfo = await oidcClient.user.info();

if ('error' in userInfo) {
  console.error('Failed to get user info:', userInfo.error);
} else {
  const { sub, name, email } = userInfo;
}
```

**Common claims returned by AIC:**

| Claim | Type | Description |
|-------|------|-------------|
| `sub` | `string` | Subject identifier (unique user ID) |
| `name` | `string` | Full display name |
| `given_name` | `string` | First name |
| `family_name` | `string` | Last name |
| `email` | `string` | Email address |
| `email_verified` | `boolean` | Whether the email has been verified |
| `phone_number` | `string` | Phone number (requires `phone` scope) |
| `address` | `object` | Address object with `formatted`, `street_address`, etc. (requires `address` scope) |
| `updated_at` | `number` | Unix timestamp of last profile update |

> **Note:** The claims returned depend on the OAuth 2.0 scopes requested. To get phone and address
> information, include `phone` and `address` in your scopes respectively.

**React profile display pattern:**

```jsx
import { useContext, useState, useEffect } from 'react';
import { OidcContext } from '../context/oidc.context';

export default function Profile() {
  const [{ oidcClient }] = useContext(OidcContext);
  const [profile, setProfile] = useState(null);

  useEffect(() => {
    async function fetchProfile() {
      const userInfo = await oidcClient.user.info();
      if (!('error' in userInfo)) setProfile(userInfo);
    }
    fetchProfile();
  }, [oidcClient]);

  if (!profile) return <p>Loading profile...</p>;

  return (
    <div>
      <h1>{profile.name}</h1>
      <p>Email: {profile.email}</p>
      <p>Phone: {profile.phone_number}</p>
      {/* Render all claims dynamically */}
      {Object.entries(profile).map(([key, value]) => (
        <div key={key}>
          <strong>{key}:</strong> {typeof value === 'object' ? JSON.stringify(value) : String(value)}
        </div>
      ))}
    </div>
  );
}
```

#### `oidcClient.user.logout()`

Full logout — revokes tokens, clears stored token data, and ends the SSO session.

```javascript
await oidcClient.user.logout();
// User is fully logged out
```

---

## Error Handling

All OIDC client methods return objects that may contain an `error` property. Always check for errors:

```javascript
const result = await oidcClient.token.get();

if ('error' in result) {
  // Handle error
  console.error(result.error);
  console.error(result.error_description);
} else {
  // Use result
}
```

---

## Integration with Journey Client

The OIDC client and Journey client share the same `CONFIG` object. The typical flow is:

```javascript
import { journey } from '@forgerock/journey-client';
import { oidc } from '@forgerock/oidc-client';

const CONFIG = {
  clientId: 'my-client-id',
  redirectUri: 'https://localhost:8443/callback.html',
  scope: 'openid profile email',
  serverConfig: {
    wellknown: 'https://tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration',
  },
};

// 1. Create both clients
const journeyClient = await journey({ config: CONFIG });
const oidcClient = await oidc({ config: CONFIG });

// 2. Authenticate via Journey
let step = await journeyClient.start({ journey: 'Login' });
// ... handle callbacks ...

// 3. On LoginSuccess, exchange for tokens
if (step.type === 'LoginSuccess') {
  const response = await oidcClient.authorize.background();
  if ('code' in response) {
    await oidcClient.token.exchange(response.code, response.state);
  }

  // 4. Get user info
  const user = await oidcClient.user.info();
}
```

---

## Session Persistence

The OIDC client automatically stores tokens using the configured storage mechanism. On app reload:

```javascript
// Check for existing session
const tokens = await oidcClient.token.get();
const isAuthenticated = !('error' in tokens);
```

This enables your app to restore the authenticated state without requiring the user to log in again.

---

## PingAM / AIC Client Registration

Ensure your OAuth 2.0 client in PingAM / AIC is configured as:

| Setting | Value |
|---------|-------|
| Client Type | Public (for SPA apps) |
| Grant Types | Authorization Code |
| Token Endpoint Auth Method | `none` |
| Redirect URIs | Must include your redirect URI (e.g., `https://localhost:8443/callback.html`) |
| Scopes | Must include all scopes requested in the SDK config |
| Implicit Consent | Enabled (recommended for SPAs) |

---

## Imports Cheatsheet

```javascript
import { oidc } from '@forgerock/oidc-client';
```
