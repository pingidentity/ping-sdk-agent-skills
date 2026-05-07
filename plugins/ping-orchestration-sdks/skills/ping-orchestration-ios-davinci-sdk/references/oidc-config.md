# OIDC Module Configuration Reference (iOS DaVinci)

The `OidcModule` is a required addition to the `DaVinci` instance. It enables
OpenID Connect token exchange after a successful DaVinci authentication flow.

> **Important:** Use `PingDavinci`'s `OidcModule.config`, not `PingJourney`'s `OidcModule.config`.

---

## Basic Configuration

```swift
import PingDavinci

config.module(OidcModule.config) { oidcValue in
    oidcValue.clientId          = "your-client-id"
    oidcValue.scopes            = ["openid", "profile", "email"]
    oidcValue.redirectUri       = "myapp://callback"
    oidcValue.discoveryEndpoint = "https://auth.pingone.com/<envId>/as/.well-known/openid-configuration"
}
```

---

## All Configuration Properties

| Property              | Type          | Required | Description                                                    |
|-----------------------|---------------|----------|----------------------------------------------------------------|
| `clientId`            | `String`      | Yes      | OAuth 2.0 client ID registered in PingOne                     |
| `discoveryEndpoint`   | `String`      | Yes      | OIDC discovery URL (`.well-known/openid-configuration`)       |
| `scopes`              | `[String]`    | Yes      | Requested OAuth 2.0 scopes (always include `openid`)          |
| `redirectUri`         | `String`      | Yes      | Custom scheme URI matching your `Info.plist` URL scheme        |

---

## URL Scheme Setup

### Info.plist

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

The scheme (e.g., `myapp`) must match the scheme in `redirectUri` (e.g., `myapp://callback`).

---

## PingOne OIDC Web App Setup

DaVinci requires a **PingOne OIDC Web App** (not a PingAM OAuth 2.0 client):

1. In the PingOne admin console, go to **Applications** → **Applications**
2. Create a new **OIDC Web App** application
3. Set the **Redirect URIs** to match your `redirectUri`
4. Set the **Grant Types** to include `Authorization Code`
5. Enable **PKCE** (Proof Key for Code Exchange)
6. Note the **Client ID** and **Environment ID**
7. The discovery endpoint follows this pattern:
   ```
   https://auth.pingone.com/<environmentId>/as/.well-known/openid-configuration
   ```
