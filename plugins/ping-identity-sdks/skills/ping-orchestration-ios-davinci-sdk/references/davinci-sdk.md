# DaVinci Module API Reference (iOS)

## Overview

`DaVinci` is the primary entry point of the DaVinci module in the Ping Orchestration iOS SDK. It manages the full
authentication flow against **PingOne DaVinci**.

> **DaVinci vs Journey:** DaVinci orchestrates flows designed in PingOne DaVinci (not PingAM/AIC).
> It uses **Collectors** instead of Callbacks. The node lifecycle is the same
> (`ContinueNode` → `SuccessNode` / `ErrorNode` / `FailureNode`).

---

## Creating a DaVinci Instance

```swift
import PingDavinci
import PingOrchestrate
import PingOidc

let davinci = DaVinci.createDaVinci { config in
    config.module(OidcModule.config) { oidcValue in
        oidcValue.clientId = "<client-id>"
        oidcValue.scopes = ["openid", "profile", "email"]
        oidcValue.redirectUri = "myapp://callback"
        oidcValue.discoveryEndpoint = "https://auth.pingone.com/<envId>/as/.well-known/openid-configuration"
    }
}
```

> **Important:** Use `PingDavinci` and `OidcModule.config`, not `PingJourney`.

---

## Starting the DaVinci Flow

```swift
let node = await davinci.start()
```

Unlike Journey, DaVinci does not accept a flow name — the flow is configured in the PingOne DaVinci admin console and triggered via the OIDC authorize endpoint.

---

## Navigating the Node Graph

```swift
switch node {
case let continueNode as ContinueNode:
    // Access node metadata
    let name = continueNode.name           // Connector name
    let desc = continueNode.description    // Connector description

    // Populate collectors, then advance
    for collector in continueNode.collectors {
        // set user input on each collector
    }
    let next = await continueNode.next()

case is SuccessNode:
    // authenticated — get user/token

case let errorNode as ErrorNode:
    let msg = errorNode.message
    // ErrorNode may expose the previous ContinueNode:
    let previous = errorNode.continueNode()

case let failureNode as FailureNode:
    let err = failureNode.cause

default:
    break
}
```

### ContinueNode Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Connector display name |
| `description` | `String` | Connector description |
| `collectors` | `[Collector]` | List of collectors for user interaction |

---

## Submittable Protocol

Some collectors conform to `Submittable`, meaning they trigger the next node advance themselves:

| Collector | Submittable | Description |
|-----------|-------------|-------------|
| `SubmitCollector` | ✅ | Form submission |
| `FlowCollector` | ✅ | Flow navigation |
| `DeviceRegistrationCollector` | ✅ | MFA device registration |
| `DeviceAuthenticationCollector` | ✅ | MFA device authentication |

When any `Submittable` collector is present, hide the fallback "Next" button.

---

## Validation

Collectors that conform to `ValidatedCollector` have a `validate()` method:

```swift
let errors: [ValidationError] = textCollector.validate()
```

Use a shared `ValidationViewModel` (injected via `@EnvironmentObject`) to coordinate form-level validation:

```swift
class ValidationViewModel: ObservableObject {
    @Published var shouldValidate = false
}
```

When a `SubmitCollector` is tapped, set `shouldValidate = true` — each collector view reads this to trigger validation display.

---

## User / Session Operations

```swift
// Get user after successful authentication
let user = await davinci.user()

// Token access
if let token = await user?.token() {
    let accessToken = token.accessToken
}

// Fetch user info
let userinfo = try await user?.userinfo()

// Logout
await user?.logout()
```

---

## ErrorNode Handling

`ErrorNode` may provide access to the previous `ContinueNode` so you can re-render the form with an error message overlay:

```swift
case let errorNode as ErrorNode:
    let previous = errorNode.continueNode()
    if let previous = previous {
        // Re-render the ContinueNode with error alert
    }
```

---

## onNext Closure Pattern

The `onNext` closure in DaVinci iOS views takes a `Bool` parameter:

```swift
onNext: (Bool) -> Void
```

- `true` — Submit action (triggers validation via `ValidationViewModel`)
- `false` — Flow navigation (skips validation)

This pattern allows `SubmitCollector` to trigger validation before advancing, while `FlowCollector` can navigate without validation.
