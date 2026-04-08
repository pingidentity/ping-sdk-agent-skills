# DaVinci Module API Reference

## Overview

`DaVinci` is the primary entry point of the DaVinci module in the Ping Orchestration Android SDK. It manages the full
authentication flow against **PingOne DaVinci**.

> **DaVinci vs Journey:** DaVinci orchestrates flows designed in PingOne DaVinci (not PingAM/AIC).
> It uses **Collectors** instead of Callbacks. The node lifecycle is the same
> (`ContinueNode` → `SuccessNode` / `ErrorNode` / `FailureNode`).

---

## Creating a DaVinci Instance

```kotlin
import com.pingidentity.davinci.DaVinci
import com.pingidentity.davinci.module.Oidc
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD

val daVinci = DaVinci {
    logger            = Logger.STANDARD  // Outputs to Android Logcat
    timeout           = 30               // Network timeout in seconds (default: 30)

    module(Oidc) {
        clientId          = "<client-id>"
        discoveryEndpoint = "https://auth.pingone.com/<envId>/as/.well-known/openid-configuration"
        scopes            = mutableSetOf("openid", "email", "profile")
        redirectUri       = "org.forgerock.demo:/oauth2redirect"

        // Optional: override token storage
        // storage = { MemoryStorage<Token>() }  // Default: DataStoreStorage
    }
}
```

> **Important:** Use `com.pingidentity.davinci.module.Oidc`, not `com.pingidentity.journey.module.Oidc`.

---

## Starting the DaVinci Flow

```kotlin
// Start the DaVinci flow (the flow is determined server-side by your DaVinci policy)
var node = daVinci.start()
```

Unlike Journey, DaVinci does not accept a flow name — the flow is configured in the PingOne DaVinci admin console and triggered via the OIDC authorize endpoint.

---

## Navigating the Node Graph

```kotlin
when (node) {
    is ContinueNode -> {
        // Access node metadata
        val name = node.name           // Connector name
        val desc = node.description    // Connector description

        // Populate collectors, then advance
        node.collectors.forEach { /* set user input */ }
        node = node.next()
    }
    is SuccessNode  -> { /* authenticated — get user/token */ }
    is ErrorNode    -> {
        val msg = node.message
        // ErrorNode may expose the previous ContinueNode for re-render:
        // val previous = node.continueNode()
    }
    is FailureNode  -> { val err = node.cause }
}
```

### Node Extension Properties

| Property | Type | Description |
|----------|------|-------------|
| `node.name` | `String` | Connector display name |
| `node.description` | `String` | Connector description |
| `node.id` | `String` | Connector unique identifier |
| `node.category` | `String` | Connector category |
| `node.collectors` | `List<Collector<*>>` | List of collectors for user interaction |

Import these extensions from:
```kotlin
import com.pingidentity.davinci.module.name
import com.pingidentity.davinci.module.description
import com.pingidentity.davinci.module.id
import com.pingidentity.davinci.module.category
import com.pingidentity.davinci.plugin.collectors
```

---

## Submittable Collectors

Some collectors implement `Submittable`, meaning they trigger the next node advance themselves:

| Collector | Submittable | eventType |
|-----------|-------------|-----------|
| `SubmitCollector` | ✅ | `"submit"` |
| `FlowCollector` | ✅ | `"action"` |
| `DeviceRegistrationCollector` | ✅ | `"submit"` |
| `DeviceAuthenticationCollector` | ✅ | `"submit"` |

When any `Submittable` collector is present, hide the fallback "Next" button — the collector provides its own action trigger.

```kotlin
import com.pingidentity.davinci.plugin.Submittable

val hasAction = continueNode.collectors.any { it is Submittable }
```

---

## User / Session Operations

```kotlin
import com.pingidentity.utils.Result

val user = daVinci.user()          // Returns User? — null if not authenticated

// Token access
when (val result = user?.token()) {
    is Result.Failure -> { /* handle error */ }
    is Result.Success -> {
        val accessToken = result.value.accessToken
    }
}

// Fetch user info (OIDC userinfo endpoint)
when (val result = user?.userinfo(false)) {
    is Result.Failure -> { /* handle error */ }
    is Result.Success -> {
        val info = result.value  // JsonObject
    }
}

// Logout (revokes tokens)
user?.logout()
```

---

## Collector Validation

Collectors that extend `ValidatedCollector` have a `validate()` method:

```kotlin
val errors: List<ValidationError> = textCollector.validate()
```

| ValidationError | Description |
|-----------------|-------------|
| `Required` | Field is required but empty |
| `InvalidLength` | Value length outside min/max range |
| `UniqueCharacter` | Insufficient unique characters (password policy) |
| `MaxRepeat` | Too many repeated characters |
| `MinCharacters` | Minimum character class requirement not met |
| `RegexError` | Value does not match the regex pattern |

---

## ErrorNode Handling

`ErrorNode` may provide access to the previous `ContinueNode` so you can re-render the form with an error message overlay:

```kotlin
is ErrorNode -> {
    // Show error alert, then re-render previous form
    val previous = node.continueNode()
    if (previous != null) {
        // Re-render the ContinueNode with error message
    }
}
```

Import:
```kotlin
import com.pingidentity.davinci.module.continueNode
```
