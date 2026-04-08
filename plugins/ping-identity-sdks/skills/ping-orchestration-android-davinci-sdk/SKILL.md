---
name: ping-orchestration-android-davinci-sdk
description: Use when building Android authentication with PingOne DaVinci — scaffolds a complete Jetpack Compose + MVVM authentication flow using the Ping Orchestration Android SDK against PingOne DaVinci. Handles DaVinci configuration, OIDC token exchange, dynamic collector rendering, device registration/authentication, social login, PingOne Protect, and logout.
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---

# Android Authentication with Ping Orchestration Android SDK (DaVinci)

Scaffold a complete authentication flow in an Android app using Jetpack Compose, MVVM, and the Ping Orchestration Android SDK's DaVinci module.

---

## Metadata

| Field       | Value |
|-------------|-------|
| Language    | Kotlin |
| Framework   | Android, Jetpack Compose, AndroidX ViewModel |
| SDK         | Ping Orchestration Android SDK — DaVinci module (`com.pingidentity.sdks:davinci`) |
| Pattern     | MVVM (Model-View-ViewModel) |
| Min SDK     | 28 |
| Compile SDK | 36 |

---

## Overview

This skill adds a complete **authentication flow** to an Android application using Jetpack Compose and the MVVM pattern. It uses the **DaVinci module** of the Ping Orchestration Android SDK to authenticate users against **PingOne DaVinci**.

> **DaVinci vs Journey:** DaVinci uses **PingOne** as the orchestration server (not PingAM/AIC). It uses **Collectors** instead of Callbacks, and a `DaVinci` class instead of `Journey`. The concepts are similar but the API surface is different.

The implementation covers:
- DaVinci instance configuration (OIDC module with discovery endpoint)
- MVVM state management with `StateFlow`
- Composable UI that renders dynamic collector nodes
- Handling all core collector types (text, password, submit, flow, label, select, etc.)
- Optional collectors (Device Registration/Authentication, Social Login, PingOne Protect)
- Success, error, and failure node handling
- Logout support

---

## Prerequisites

### 1. Gradle Dependencies

Add the following to the **app-level** `build.gradle.kts`. See [build.gradle.kts template](assets/build.gradle.kts.template) for a complete example.

```kotlin
dependencies {
    // DaVinci module
    implementation("com.pingidentity.sdks:davinci:<version>")

    // Optional modules (add only if your DaVinci flow uses them)
    implementation("com.pingidentity.sdks:external-idp:<version>")   // Social login (IdpCollector)
    implementation("com.pingidentity.sdks:fido:<version>")           // FIDO2 / Passkeys (FidoRegistration/AuthenticationCollector)
    implementation("com.pingidentity.sdks:protect:<version>")        // PingOne Protect (ProtectCollector)

    // Jetpack Compose BOM
    val composeBom = platform("androidx.compose:compose-bom:<bom_version>")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.activity:activity-compose")
    implementation("androidx.navigation:navigation-compose")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose")

    // DataStore (for token/session persistence)
    implementation("androidx.datastore:datastore-preferences")
}
```

### 2. AndroidManifest.xml

Add the redirect URI scheme as an intent filter (required for OAuth 2.0 redirect):

```xml
<activity android:name=".MainActivity" ...>
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="${appRedirectUriScheme}" />
    </intent-filter>
</activity>
```

In `build.gradle.kts` `defaultConfig`:

```kotlin
manifestPlaceholders["appRedirectUriScheme"] = "org.forgerock.demo"
```

See [OIDC Configuration Reference](references/oidc-config.md) for full redirect URI setup details.

---

## Required Configuration

> **Agent instruction:** Before generating any file, collect the values below from the user.
> Ask for all `required` parameters up front in a single prompt. For optional parameters, show the
> default and ask whether the user wants to override it. Do **not** proceed to Step 1 until every
> required parameter has a non-empty value.

### Parameters to collect

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `clientId` | Yes | — | OAuth 2.0 Client ID registered in PingOne for this Android app |
| `discoveryEndpoint` | Yes | — | Full OIDC discovery endpoint URL (`.well-known/openid-configuration`) from PingOne |
| `scopes` | Yes | `openid email profile` | Space-separated OAuth 2.0 scopes to request |
| `redirectUri` | Yes | `org.forgerock.demo:/oauth2redirect` | OAuth 2.0 redirect URI registered in PingOne |

### Suggested prompts

```
Before I generate the files, I need a few details about your PingOne DaVinci setup:

1. Client ID           — What is the OAuth 2.0 Client ID for this Android app?
                         (From your PingOne OIDC Web App configuration)
2. Discovery Endpoint  — What is the full OIDC discovery endpoint URL?
                         e.g. https://auth.pingone.com/<envId>/as/.well-known/openid-configuration
3. Scopes              — Which OAuth 2.0 scopes? (default: openid email profile)
4. Redirect URI        — What is the redirect URI? (default: org.forgerock.demo:/oauth2redirect)
```

### Validation rules

- `discoveryEndpoint` must end with `/.well-known/openid-configuration`.
- `clientId` must be non-empty.
- `redirectUri` must follow `<scheme>:/<path>` format; the scheme must match `manifestPlaceholders["appRedirectUriScheme"]`.
- If `scopes` does not include `openid`, prepend it automatically and warn the user.

---

## Implementation Steps

### Step 1 — Configure the DaVinci Instance

Create `DaVinciConfig.kt`. See [DaVinciConfig.kt template](assets/DaVinciConfig.kt.template).

> **Agent instruction:** Substitute all `<parameter>` placeholders with values collected above.

```kotlin
val daVinci = DaVinci {
    logger = Logger.STANDARD

    module(Oidc) {
        clientId          = "<clientId>"
        discoveryEndpoint = "<discoveryEndpoint>"
        scopes            = mutableSetOf("openid", "email", "profile")
        redirectUri       = "<redirectUri>"
    }
}
```

See [DaVinci SDK API Reference](references/davinci-sdk.md) for all configuration options.

---

### Step 2 — Create the DaVinci State

Create `DaVinciState.kt`. See [DaVinciState.kt template](assets/DaVinciState.kt.template).

```kotlin
data class DaVinciState(
    val node: Node? = null,
    val counter: Int = 0   // Triggers recomposition when node is the same object
)
```

---

### Step 3 — Create the DaVinci ViewModel

Create `DaVinciViewModel.kt`. See [DaVinciViewModel.kt template](assets/DaVinciViewModel.kt.template).

Key methods:
- `start()` — Starts or restarts the DaVinci flow
- `next(node: ContinueNode)` — Advances to the next node after collectors are populated
- `refresh()` — Triggers recomposition without advancing
- `logout(onCompleted)` — Logs out the current user

---

### Step 4 — Create the ContinueNode Composable

Create `ContinueNode.kt` which dispatches each collector in a `ContinueNode` to its dedicated Composable. See [ContinueNode.kt template](assets/ContinueNode.kt.template).

The pattern:

```kotlin
@Composable
fun ContinueNode(continueNode: ContinueNode, onNodeUpdated: () -> Unit, onNext: (ContinueNode) -> Unit, onStart: () -> Unit) {
    var hasAction = false
    continueNode.collectors.forEach { collector ->
        when (collector) {
            is TextCollector -> Text(collector, onNodeUpdated)
            is PasswordCollector -> Password(collector, onNodeUpdated)
            is SubmitCollector -> { hasAction = true; SubmitButton(collector, onNext) }
            is FlowCollector -> { hasAction = true; FlowButton(collector, onNext) }
            is LabelCollector -> Label(collector)
            // ... more collectors
        }
    }
    if (!hasAction) { Button(onClick = { onNext(continueNode) }) { Text("Next") } }
}
```

See [Collector Types Reference](references/collectors.md) for the full list of supported collectors.

---

### Step 5 — Create Collector Composables

Create individual Composable files for each collector type. See the `assets/` directory for all templates.

All collector types supported by the Ping Orchestration Android SDK's DaVinci module:

**Core Collectors (`davinci` module):**

| Collector Class | Composable | Description |
|-----------------|------------|-------------|
| `TextCollector` | `Text` | Text input with validation |
| `PasswordCollector` | `Password` | Secure password input with policy validation |
| `SubmitCollector` | `SubmitButton` | Form submission button (Submittable) |
| `FlowCollector` | `FlowButton` | Navigation between flow branches (Submittable) |
| `LabelCollector` | `Label` | Static text/label display |
| `SingleSelectCollector` | `Dropdown` / `Radio` | Single selection — Dropdown (type=DROPDOWN) or Radio buttons |
| `MultiSelectCollector` | `ComboBox` / `CheckBox` | Multiple selection — ComboBox (type=COMBOBOX) or Checkboxes |
| `PhoneNumberCollector` | `PhoneNumber` | Phone number input |
| `DeviceRegistrationCollector` | `DeviceRegistration` | MFA device registration (Submittable) |
| `DeviceAuthenticationCollector` | `DeviceAuthentication` | MFA device authentication (Submittable) |

**Optional Collectors (additional modules):**

| Collector Class | Module | Composable | Description |
|-----------------|--------|------------|-------------|
| `IdpCollector` | `external-idp` | `SocialLoginButton` | Social login (Google, Facebook, Apple) |
| `FidoRegistrationCollector` | `fido` | `FidoRegistration` | FIDO2 passkey / security-key registration (Submittable) |
| `FidoAuthenticationCollector` | `fido` | `FidoAuthentication` | FIDO2 passkey / security-key authentication (Submittable) |
| `ProtectCollector` | `protect` | `Protect` | PingOne Protect risk signals collection |

Each collector Composable follows this pattern:
1. **Read** display values from the collector (e.g., `collector.label`)
2. **Render** an appropriate Jetpack Compose control
3. **Set** user input back on the collector (e.g., `collector.value = text`)
4. **Call** `onNodeUpdated()` or `onNext()` as appropriate

> **Note:** `Submittable` collectors (`SubmitCollector`, `FlowCollector`, `DeviceRegistrationCollector`, `DeviceAuthenticationCollector`, `FidoRegistrationCollector`, `FidoAuthenticationCollector`) provide their own action triggers. When any `Submittable` collector is present, the default "Next" button is hidden. `ProtectCollector` auto-collects signals and should call `onNext()` when complete.

See also:
- [DeviceRegistration.kt template](assets/DeviceRegistration.kt.template)
- [DeviceAuthentication.kt template](assets/DeviceAuthentication.kt.template)
- [SocialLoginButton.kt template](assets/SocialLoginButton.kt.template)
- [FidoRegistration.kt template](assets/FidoRegistration.kt.template)
- [FidoAuthentication.kt template](assets/FidoAuthentication.kt.template)
- [Protect.kt template](assets/Protect.kt.template)

---

### Step 6 — Create the DaVinci Screen Composable

Create `DaVinciScreen.kt`. See [DaVinciScreen.kt template](assets/DaVinciScreen.kt.template).

```kotlin
@Composable
fun DaVinciScreen(viewModel: DaVinciViewModel, onSuccess: () -> Unit) {
    BackHandler { viewModel.start() }
    val state by viewModel.state.collectAsState()
    val loading by viewModel.loading.collectAsState()

    Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
        if (loading) CircularProgressIndicator()
        when (val node = state.node) {
            is ContinueNode -> ContinueNode(node,
                onNodeUpdated = { viewModel.refresh() },
                onNext = { viewModel.next(it) },
                onStart = { viewModel.start() })
            is FailureNode -> ErrorCard(message = node.cause.message ?: "Unknown error")
            is ErrorNode -> ErrorCard(message = node.message, onRetry = {
                // ErrorNode may have a continueNode() to re-render the previous form
            })
            is SuccessNode -> LaunchedEffect(true) { onSuccess() }
            null -> {}
        }
    }
}
```

---

### Step 7 — Wire Navigation

In your `NavHost`, add:

```kotlin
composable("auth") {
    val vm: DaVinciViewModel = viewModel()
    DaVinciScreen(viewModel = vm) {
        navController.navigate("home") {
            popUpTo("auth") { inclusive = true }
        }
    }
}
```

---

## Scaffolding Script

For quick setup, use the scaffolding script to copy all template files into your project:

```bash
chmod +x scripts/scaffold_auth.sh
./scripts/scaffold_auth.sh \
    --package com.example.myapp \
    --src-dir app/src/main/java
```

See [scaffold_auth.sh](scripts/scaffold_auth.sh) for details.

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Wrong redirect URI scheme | Must match `manifestPlaceholders["appRedirectUriScheme"]` in `build.gradle.kts` |
| Missing `openid` scope | Always include `openid` — required for OIDC token exchange |
| Unhandled collector type | Add a `when` branch in `ContinueNode` for every collector your DaVinci flow uses |
| Hardcoded credentials | Use `BuildConfig` fields or a config file — never commit secrets |
| Forgetting `LaunchedEffect` for `SuccessNode` | Navigate away inside `LaunchedEffect(true)` to avoid recomposition loops |
| Using Journey instead of DaVinci | DaVinci uses `DaVinci { }` not `Journey { }`, uses `collectors` not `callbacks`, uses `module(Oidc)` from `com.pingidentity.davinci.module.Oidc` |
| Not hiding default Next when Submittable present | When `SubmitCollector`, `FlowCollector`, `DeviceRegistrationCollector`, `DeviceAuthenticationCollector`, `FidoRegistrationCollector`, or `FidoAuthenticationCollector` is present, hide the fallback Next button |
| Calling `node.next()` without populating collectors | Always set collector values (e.g., `collector.value = "..."`) before advancing |
| Forgetting to add optional collector dependencies | Import and add the relevant Gradle dependency (`external-idp`, `fido`, `protect`) for optional collectors |
| Confusing DaVinci Oidc with Journey Oidc | Import `com.pingidentity.davinci.module.Oidc`, not `com.pingidentity.journey.module.Oidc` |

---

## Reference Documentation

- [DaVinci SDK API Reference](references/davinci-sdk.md) — DaVinci instance, node types, user/session operations
- [Collector Types Reference](references/collectors.md) — All supported collector types and their properties
- [OIDC Configuration Reference](references/oidc-config.md) — OIDC module setup, storage, redirect URI

---

## Related Skills

- `ping-quickstart` — Platform detection and Ping Identity orientation
- `ping-orchestration-android-journey-sdk` — Android authentication using the Journey module (for PingOne AIC/PingAM)
