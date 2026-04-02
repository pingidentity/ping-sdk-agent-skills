# OIDC Configuration Reference — iOS SDK

The `PingJourney.OidcModule` provides OpenID Connect token management on top of the Journey module.

---

## OIDC Module Configuration

Register the OIDC module when creating a Journey:

```swift
let journey = Journey.createJourney { config in
    config.httpClient = HttpClient()

    // Journey server configuration
    config.serverUrl = "https://openam-example.forgeblocks.com/am"
    config.realm = "alpha"
    config.cookieName = "ipsToken"

    // OIDC module
    config.module(PingJourney.OidcModule.config) { oidcConfig in
        oidcConfig.clientId = "ios-sdk-client"
        oidcConfig.scopes = ["openid", "profile", "email", "address"]
        oidcConfig.redirectUri = "org.forgerock.demo://oauth2redirect"
        oidcConfig.discoveryEndpoint = "https://openam-example.forgeblocks.com/am/oauth2/realms/root/realms/alpha/.well-known/openid-configuration"
    }
}
```

---

## OidcModule Configuration Properties

| Property | Type | Description |
|----------|------|-------------|
| `clientId` | `String` | OAuth 2.0 client ID registered in PingAM |
| `scopes` | `Set<String>` | OAuth 2.0 scopes to request (e.g., `openid`, `profile`, `email`) |
| `redirectUri` | `String` | Redirect URI registered in the OAuth 2.0 client configuration |
| `discoveryEndpoint` | `String` | OIDC well-known endpoint URL |

---

## Redirect URI Scheme

Register a custom URL scheme in `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>org.forgerock.demo</string>
        </array>
    </dict>
</array>
```

The `redirectUri` must use this scheme (e.g., `org.forgerock.demo://oauth2redirect`).

---

## Token Access

After a successful Journey, retrieve tokens from the `SuccessNode`:

```swift
switch node {
case let successNode as SuccessNode:
    // A session token is available on the success node
    let sessionToken = successNode.session?.value
    // Token management is handled by the OidcModule
```

To access OAuth tokens directly:

```swift
// Retrieve the current access token
let tokenResponse = try await journey.user()?.token()
let accessToken = tokenResponse?.accessToken
let idToken = tokenResponse?.idToken
let refreshToken = tokenResponse?.refreshToken
```

---

## User Info

Retrieve the authenticated user's profile from the UserInfo endpoint:

```swift
let userInfo = try await journey.user()?.userinfo()
// userInfo is a [String: Any] dictionary
```

Returns a dictionary with claims based on the requested scopes (e.g., `sub`, `name`, `email`, `address`).

---

## Token Refresh

The SDK automatically refreshes expired access tokens using the stored refresh token. To force a token refresh:

```swift
let freshToken = try await journey.user()?.token(forceRenew: true)
```

---

## Revoke Tokens / Logout

Revoke all tokens and clear the session:

```swift
try await journey.user()?.revoke()
```

This calls the token revocation endpoint and clears stored tokens from the Keychain.

---

## End Session (Centralized Logout)

Use the OIDC end-session endpoint for centralized logout:

```swift
try await journey.user()?.endSession()
```

This revokes tokens and performs a redirect to the OIDC end-session endpoint to invalidate the server-side session.

---

## Multi-User Support

When multiple users authenticate on the same device, use `Journey.user(name:)`:

```swift
// Access a specific user's tokens
let user = journey.user(name: "user1@example.com")
let token = try await user?.token()

// Revoke a specific user's tokens
try await journey.user(name: "user1@example.com")?.revoke()
```
