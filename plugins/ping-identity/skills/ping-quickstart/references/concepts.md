# Ping Identity Concepts & Key Terms

Core Ping Identity concepts, terminology, troubleshooting guide, and security best practices for the Ping Orchestration SDKs.

---

## Ping Identity Platform

### PingOne Advanced Identity Cloud (AIC)

PingOne AIC (formerly ForgeRock Identity Cloud) is a cloud-hosted identity platform that provides:

- **Access Management (AM)** — Authentication, authorization, and session management
- **Identity Management (IDM)** — User provisioning, lifecycle management, and self-service

### Orchestration Methods

PingOne AIC supports two primary orchestration methods:

| Method | Description | Use Case |
|--------|-------------|----------|
| **Journeys (Trees)** | Visual, node-based authentication flows configured in the AIC admin console | Traditional authentication flows with fine-grained control over each step |


The Ping Orchestration SDKs support both methods through separate modules:
- `journey` module — For Journey/Tree-based authentication

---
## Key Terms

### Authentication & Identity Terms

| Term | Definition | Example |
|------|------------|---------|
| **Tenant** | Your PingOne AIC environment instance | `your-tenant.forgeblocks.com` |
| **Realm** | A logical partition within a tenant for isolating configurations | `alpha` (development), `bravo` (staging) |
| **Journey / Tree** | A server-side authentication flow composed of connected nodes | `Login`, `Registration`, `PasswordReset` |
| **Node** | A single step in a Journey that performs an action | Page Node, Data Store Decision, MFA node |
| **Callback** | Data sent from a Journey node to the client SDK — represents a field, action, or information to display | `NameCallback`, `PasswordCallback`, `ChoiceCallback` |
| **Page Node** | A Journey node that groups multiple callbacks into a single page/step | Groups username + password into one screen |

### SDK Node Types

| Node Type | Meaning | What To Do |
|-----------|---------|------------|
| `ContinueNode` | Authentication flow is in progress | Render callbacks, collect user input, call `node.next()` |
| `SuccessNode` | Authentication completed successfully | Navigate to authenticated state, access tokens |
| `ErrorNode` | Server returned an error message | Display error to user, optionally retry |
| `FailureNode` | An exception occurred (network, parsing, etc.) | Display error, check connectivity, retry |

### OAuth 2.0 / OIDC Terms

| Term | Definition |
|------|------------|
| **Client ID** | Public identifier for your application registered in AIC |
| **Discovery Endpoint** | OIDC metadata URL (`.well-known/openid-configuration`) providing all endpoint URLs |
| **Redirect URI** | URI where the OAuth 2.0 authorization response is sent (custom scheme for mobile) |
| **Scope** | Permissions requested — `openid` is required, plus `email`, `profile`, `phone`, etc. |
| **Access Token** | Short-lived token for API authorization |
| **ID Token** | JWT containing user identity claims |
| **Refresh Token** | Long-lived token used to obtain new access tokens |
| **PKCE** | Proof Key for Code Exchange — security mechanism for public clients (mobile apps) |
| **SSO Cookie** | Session cookie (e.g., `iPlanetDirectoryPro`) maintaining server-side session state |

### SDK Architecture Terms

| Term | Definition |
|------|------------|
| **Orchestrate** | Core framework module providing the `Node` types and flow orchestration |
| **Journey Module** | SDK module that drives PingOne AIC Journey/Tree-based authentication |
| **OIDC Module** | SDK module handling OAuth 2.0 / OpenID Connect token exchange |
| **Storage Module** | SDK module providing encrypted and plain storage abstractions |
| **Logger Module** | SDK module providing configurable logging (`Logger.STANDARD` for Logcat/console) |

---

## OAuth 2.0 / OIDC Flows

### Authorization Code Flow with PKCE

**Used by:** All Ping Orchestration SDKs (Android, iOS, JavaScript)

**How it works with Journeys:**
1. SDK starts a Journey and steps through callbacks with the user
2. Journey completes with a `SuccessNode` containing a session token
3. OIDC module exchanges the session token for OAuth 2.0 tokens via Authorization Code + PKCE
4. Tokens are securely stored by the SDK

**Security:** PKCE prevents authorization code interception, essential for mobile and SPA clients.

### Token Lifecycle

```
Journey Start → Callbacks → SuccessNode → OIDC Exchange → Access Token + ID Token + Refresh Token
                                                            ↓
                                                     Token Expires
                                                            ↓
                                                   Refresh Token → New Access Token
                                                            ↓
                                                    Refresh Expires
                                                            ↓
                                                   Re-authenticate (new Journey)
```

---

## Troubleshooting

### Common Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| **Invalid redirect URI** | OAuth error after Journey success | Ensure `redirectUri` in SDK config matches exactly what is registered in AIC client settings |
| **Discovery endpoint not found** | 404 or network error on start | Verify the URL format: `https://<tenant>.forgeblocks.com/am/oauth2/<realm>/.well-known/openid-configuration` |
| **Journey not found** | Error on `journey.start("TreeName")` | Verify the Journey name matches exactly (case-sensitive) in AIC admin console |
| **Callback type not handled** | App crashes or shows blank | Add a `when` branch for the unhandled callback type in your `CallbackNode` composable |
| **Token exchange fails** | `SuccessNode` reached but no tokens | Verify OAuth 2.0 client has Authorization Code grant type and correct redirect URI |
| **Network timeout** | Request hangs then fails | Check `serverUrl` is reachable, increase `timeout` in Journey config if needed |
| **Wrong realm** | Authentication endpoints return 404 | Verify realm name (`alpha`, `bravo`) matches your AIC environment setup |
| **Missing openid scope** | ID token not returned | Always include `openid` in the scopes set |

### Debugging Steps

1. **Enable SDK logging**
   ```kotlin
   // Android
   val journey = Journey {
       logger = Logger.STANDARD  // Logs to Logcat
   }
   ```

2. **Check AIC Admin Console**
   - Navigate to Journeys → Select your Journey → Verify it is published
   - Check OAuth 2.0 client settings match your SDK configuration

3. **Inspect network traffic**
   - Use Android Studio Network Inspector or Charles Proxy
   - Look for failed requests to `/json/realms/root/realms/<realm>/authenticate`

4. **Verify OIDC discovery**
   ```bash
   curl -s "https://<tenant>.forgeblocks.com/am/oauth2/<realm>/.well-known/openid-configuration" | jq .
   ```

---

## Security Best Practices

### Mobile Applications

1. **Use Public clients** — Mobile apps cannot securely store client secrets. Always use a Public OAuth 2.0 client type with no client secret.
2. **Enable PKCE** — The Ping SDKs enable PKCE by default. Do not disable it.
3. **Use encrypted storage** — Enable the `storage` block in the OIDC module to encrypt tokens at rest using AndroidKeyStore (Android) or Keychain (iOS).
4. **Never hardcode credentials** — Use build config fields, environment variables, or secure configuration files. Never commit tenant URLs, client IDs, or cookie names to source control in production.
5. **Pin certificates in production** — Consider certificate pinning for additional network security.
6. **Use `strongBoxPreferred = true`** — On devices with hardware-backed StrongBox, this provides the highest level of key protection.

### General

1. **Keep `openid` in scopes** — Required for OIDC token exchange.
2. **Validate tokens server-side** — Never rely solely on client-side token validation for authorization decisions.
3. **Implement token refresh** — Handle token expiry gracefully by using refresh tokens.
4. **Rotate secrets regularly** — If using confidential clients for backend services, rotate client secrets periodically.
