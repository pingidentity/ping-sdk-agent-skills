# OIDC Module Configuration Reference

The `Oidc` module is a required addition to the `DaVinci` instance. It enables
OpenID Connect token exchange after a successful DaVinci authentication flow.

> **Important:** Use `com.pingidentity.davinci.module.Oidc`, not `com.pingidentity.journey.module.Oidc`.

---

## Basic Configuration

```kotlin
import com.pingidentity.davinci.module.Oidc

module(Oidc) {
    clientId          = "your-client-id"
    discoveryEndpoint = "https://auth.pingone.com/<envId>/as/.well-known/openid-configuration"
    scopes            = mutableSetOf("openid", "email", "profile")
    redirectUri       = "org.forgerock.demo:/oauth2redirect"
}
```

---

## All Configuration Properties

| Property              | Type                | Required | Description                                                         |
|-----------------------|---------------------|----------|---------------------------------------------------------------------|
| `clientId`            | `String`            | Yes      | OAuth 2.0 client ID registered in PingOne                          |
| `discoveryEndpoint`   | `String`            | Yes      | OIDC discovery URL (`.well-known/openid-configuration`)            |
| `scopes`              | `MutableSet<String>`| Yes      | Requested OAuth 2.0 scopes (always include `openid`)               |
| `redirectUri`         | `String`            | Yes      | Custom scheme URI matching your `AndroidManifest.xml` intent filter |
| `loginHint`           | `String`            | No       | Pre-fill the username hint in the authorization request            |
| `nonce`               | `String`            | No       | Override automatic nonce generation                                 |
| `display`             | `String`            | No       | Display name for the configuration                                  |

---

## Storage Configuration

The `storage` block inside `module(Oidc)` controls how tokens are persisted.

```kotlin
module(Oidc) {
    // ... required fields ...
    storage = { DataStoreStorage<Token>(fileName = "oidc_tokens") }  // Default
    // Or use MemoryStorage for testing:
    // storage = { MemoryStorage<Token>() }
}
```

---

## DaVinci-Specific Configuration

The DaVinci SDK automatically adds several modules when you create a `DaVinci { }` instance:

| Module | Purpose |
|--------|---------|
| `CustomHeader` | Adds `Accept-Language` header from device locale |
| `CustomParameter` | Adds `response_mode=pi.flow` to the authorize request |
| `NodeTransform` | Transforms DaVinci JSON responses into SDK node objects |
| `ContinueNode` | Handles form parsing and collector creation |
| `Oidc` | Your OIDC configuration (added by you) |
| `Cookie` | Optional: SSO cookie persistence |

You do **not** need to configure `CustomHeader`, `CustomParameter`, `NodeTransform`, or `ContinueNode` — they are added automatically.

---

## Redirect URI Setup

### AndroidManifest.xml
```xml
<activity android:name=".MainActivity"
    android:launchMode="singleTop">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="${appRedirectUriScheme}" />
    </intent-filter>
</activity>
```

### build.gradle.kts
```kotlin
android {
    defaultConfig {
        manifestPlaceholders["appRedirectUriScheme"] = "org.forgerock.demo"
    }
}
```

---

## PingOne OIDC Web App Setup

DaVinci requires a **PingOne OIDC Native App**:

1. In the PingOne admin console, go to **Applications** → **Applications**
2. Create a new **OIDC Native App** application
3. Set the **Redirect URIs** to match your `redirectUri`
4. Set the **Grant Types** to include `Authorization Code`
5. Enable **PKCE** (Proof Key for Code Exchange)
6. Note the **Client ID** and **Environment ID**
7. The discovery endpoint follows this pattern:
   ```
   https://auth.pingone.com/<environmentId>/as/.well-known/openid-configuration
   ```
