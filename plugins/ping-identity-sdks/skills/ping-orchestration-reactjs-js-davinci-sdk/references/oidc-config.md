# OIDC Configuration Reference (JavaScript DaVinci)

The DaVinci JavaScript SDK uses OIDC (OpenID Connect) to communicate with PingOne.
All configuration is provided at client initialisation via `davinci()`.

---

## Configuration Object

```js
import { davinci } from '@forgerock/davinci-client';

const davinciClient = await davinci({
  config: {
    clientId: '<YOUR_CLIENT_ID>',
    serverConfig: {
      wellknown:
        'https://auth.pingone.com/<ENV_ID>/as/.well-known/openid-configuration',
    },
    scope: 'openid profile email',
    redirectUri: window.location.origin + '/callback',
  },
});
```

### Required Properties

| Property | Type | Description |
|----------|------|-------------|
| `clientId` | `string` | The OAuth 2.0 client ID from PingOne |
| `serverConfig.wellknown` | `string` | The OIDC well-known endpoint URL |
| `redirectUri` | `string` | The URI PingOne redirects to after authentication |

### Optional Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `scope` | `string` | `'openid'` | Space-separated list of OAuth 2.0 scopes |
| `responseType` | `string` | `'code'` | OAuth 2.0 response type |

---

## PingOne Web Application Setup

Before configuring the SDK, create a **Web App** connection in PingOne:

1. Navigate to **Applications → Applications** in the PingOne admin console.
2. Click **+ Add Application** and select **Web App → OIDC**.
3. Configure the application:
   - **Redirect URI**: `http://localhost:5173/callback` (Vite dev) or your production URI.
   - **Allowed Scopes**: Enable `openid`, `profile`, and `email` at a minimum.
   - **Token Endpoint Auth Method**: `none` (for SPA / public clients).
   - **Grant Type**: `Authorization Code`.
   - **Response Type**: `Code`.
4. Copy the **Client ID** and **Environment ID** for your `.env` file.

---

## Well-Known Endpoint

The well-known URL follows this pattern:

```
https://auth.pingone.com/<ENVIRONMENT_ID>/as/.well-known/openid-configuration
```

Replace `<ENVIRONMENT_ID>` with your PingOne environment ID (a UUID).

> **Important:** The DaVinci SDK resolves all necessary OAuth 2.0 endpoints from the well-known URL automatically.

---

## Environment Variables

Store configuration in a `.env` file at the project root (Vite will expose variables prefixed with `VITE_`):

```env
VITE_CLIENT_ID=your-client-id
VITE_DISCOVERY_ENDPOINT=https://auth.pingone.com/<ENV_ID>/as/.well-known/openid-configuration
VITE_REDIRECT_URI=http://localhost:5173/callback
VITE_SCOPE=openid profile email
```

Reference them in code:

```js
const config = {
  clientId: import.meta.env.VITE_CLIENT_ID,
  serverConfig: {
    wellknown: import.meta.env.VITE_DISCOVERY_ENDPOINT,
  },
  scope: import.meta.env.VITE_SCOPE,
  redirectUri: import.meta.env.VITE_REDIRECT_URI,
};
```

---

## CORS Configuration

For local development the PingOne application must allow the origin of the SPA:

- Add `http://localhost:5173` (or the port your dev server uses) to the **Allowed Origins** list in PingOne.
- In production, replace with the deployed origin.

---

## Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Wrong `wellknown` URL | Network error on init | Verify the environment ID and region (`pingone.com`, `pingone.eu`, `pingone.ca`, `pingone.asia`) |
| Missing `redirectUri` | OAuth error after authentication | Ensure the URI matches exactly (protocol, host, port, path) |
| Scopes not enabled in PingOne | `invalid_scope` error | Enable each requested scope in the PingOne application settings |
| Non-public client | `invalid_client` error | Set Token Endpoint Auth Method to `none` for SPAs |
