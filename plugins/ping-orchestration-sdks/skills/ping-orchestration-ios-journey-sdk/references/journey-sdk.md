# Journey Module Reference — iOS SDK

API reference for the `PingJourney` module of the Ping Orchestration iOS SDK.

---

## Creating a Journey Instance

```swift
import PingJourney
import PingOrchestrate
import PingOidc

let journey = Journey.createJourney { config in
    config.serverUrl = "https://your-tenant.forgeblocks.com/am"
    config.realm = "alpha"
    config.cookie = "iPlanetDirectoryPro"

    // OIDC module — required for token exchange after SuccessNode
    config.module(PingJourney.OidcModule.config) { oidcConfig in
        oidcConfig.clientId = "your-client-id"
        oidcConfig.scopes = ["openid", "profile", "email"]
        oidcConfig.redirectUri = "myapp://callback"
        oidcConfig.discoveryEndpoint = "https://your-tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration"
    }
}
```

### JourneyConfig Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `serverUrl` | `String?` | `nil` | Base URL of the PingAM/AIC server |
| `realm` | `String` | `"root"` | Authentication realm |
| `cookie` | `String` | `"iPlanetDirectoryPro"` | Session cookie name |

### OidcModule Configuration

| Property | Type | Description |
|----------|------|-------------|
| `clientId` | `String` | OAuth 2.0 client ID |
| `scopes` | `[String]` | OAuth 2.0 scopes to request |
| `redirectUri` | `String` | OAuth 2.0 redirect URI (custom URL scheme) |
| `discoveryEndpoint` | `String` | OIDC well-known discovery endpoint URL |
| `storage` | `Storage<Token>?` | Optional custom token storage (default: Keychain) |

---

## Starting a Journey

```swift
let node = await journey.start("Login") { options in
    options.forceAuth = false
    options.noSession = false
}
```

### Start Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `forceAuth` | `Bool` | `false` | Force re-authentication even if a session exists |
| `noSession` | `Bool` | `false` | Do not create a server-side session |

---

## Node Types

The `start()` and `next()` methods return a `Node`. Check the concrete type:

### ContinueNode

The journey requires more input. Contains a list of callbacks.

```swift
if let continueNode = node as? ContinueNode {
    // Access callbacks
    let callbacks = continueNode.callbacks

    // Access page metadata — non-optional Strings, check .isEmpty
    let header = continueNode.pageHeader        // Page header text
    let description = continueNode.pageDescription  // Page description text

    // Fill in callback values, then advance
    let nextNode = await continueNode.next()
}
```

> **Important:** `pageHeader` and `pageDescription` are non-optional `String` values — use
> `.isEmpty` checks, not optional binding. Do **not** use `continueNode.header` or
> `continueNode.nodeDescription`; those property names do not exist and will cause compile errors.

### SuccessNode

Authentication succeeded. The session token is available.

```swift
if let successNode = node as? SuccessNode {
    let sessionToken = successNode.session.value
    // The OIDC module automatically exchanges for OAuth tokens
}
```

### FailureNode

An SDK-side failure occurred (e.g., network error).

```swift
if let failureNode = node as? FailureNode {
    let error = failureNode.cause
    print("Failure: \(error.localizedDescription)")
}
```

### ErrorNode

A server-side error occurred (e.g., invalid credentials, locked account).

```swift
if let errorNode = node as? ErrorNode {
    let message = errorNode.message
    print("Error: \(message)")
}
```

---

## Advancing the Journey

After populating callback values on a `ContinueNode`, call `next()` to advance:

```swift
// Set callback values
for callback in continueNode.callbacks {
    switch callback {
    case let nameCallback as NameCallback:
        nameCallback.name = "username"
    case let passwordCallback as PasswordCallback:
        passwordCallback.password = "password"
    default:
        break
    }
}

// Advance to the next node
let nextNode = await continueNode.next()
```

---

## Session Management

After a `SuccessNode`, the OIDC module handles token exchange automatically. Access the OIDC module from the Journey's shared context:

```swift
// Get the OIDC module from the journey context
if let oidcClient = await journey.module(OidcModule.config)?.client {
    // Get access token
    let token = await oidcClient.accessToken()

    // Get user info
    let userInfo = await oidcClient.userinfo()

    // Revoke tokens and end session
    await oidcClient.endSession()
}
```

See [OIDC Configuration Reference](oidc-config.md) for full OIDC API documentation.

---

## Session State Pattern (Home / Root View)

After a successful Journey, the app pops back to a root view that checks session state via
`journey.user()`. The `onChange(of: path)` observer is what makes `path = []` from `JourneyView`'s
`SuccessNode` handler immediately re-trigger the session check.

```swift
struct HomeView: View {
    @Binding var path: [MenuItem]
    @State private var isLoggedIn = false
    @State private var isCheckingSession = true

    var body: some View {
        // ... render based on isLoggedIn / isCheckingSession ...
        .task { await checkSession() }
        .onChange(of: path) { _ in
            // Fires when JourneyView sets path = [] on SuccessNode
            Task { await checkSession() }
        }
    }

    private func checkSession() async {
        isCheckingSession = true
        guard let user = await journey.user() else {
            isLoggedIn = false
            isCheckingSession = false
            return
        }
        switch await user.token() {
        case .success:
            isLoggedIn = true
        case .failure:
            isLoggedIn = false
        }
        isCheckingSession = false
    }
}
```

> **Why `path = []` and not `path.append(.home)` or `path = [.home]`:**
> - `path.append(.home)` pushes a *new* `HomeView` as a navigation destination — it never pops
>   to the existing root.
> - `path = [.home]` also creates a new instance which re-runs `checkSession()`. If `journey.user()`
>   returns nil due to timing (token exchange still in flight), it shows logged-out state.
> - `path = []` pops to the *existing* root `HomeView`. Its `onChange(of: path)` fires,
>   re-runs `checkSession()`, and the already-stored token is found immediately.

---

## Optional Module Registration

Advanced callback modules register themselves automatically when imported. Simply import the module and the SDK handles callback registration via runtime discovery:

```swift
// These imports trigger automatic callback registration
import PingBinding           // DeviceBindingCallback, DeviceSigningVerifierCallback
import PingFido              // FidoRegistrationCallback, FidoAuthenticationCallback
import PingProtect           // PingOneProtectInitializeCallback, PingOneProtectEvaluationCallback
import PingExternalIdP       // SelectIdpCallback, IdpCallback
import PingDeviceProfile     // DeviceProfileCallback
import PingReCaptchaEnterprise  // ReCaptchaEnterpriseCallback
```

The SDK uses `NSClassFromString` and Objective-C runtime to discover and register callbacks from optional modules. No manual registration code is needed — just import the module.

---

## Multi-User Support

The iOS SDK supports multiple Journey instances with isolated storage for multi-user scenarios:

```swift
let userAJourney = Journey.createJourney { config in
    config.serverUrl = "https://your-server.example.com/am"
    config.realm = "alpha"
    config.cookie = "iPlanetDirectoryPro"
    config.module(PingJourney.OidcModule.config) { oidcConfig in
        oidcConfig.clientId = "your-client-id"
        oidcConfig.scopes = ["openid", "profile"]
        oidcConfig.redirectUri = "myapp://callback"
        oidcConfig.discoveryEndpoint = "https://..."
        // Separate storage for this user
        oidcConfig.storage = KeychainStorage<Token>(account: "user_a_tokens")
    }
}
```
