---
name: ping-orchestration-android-journey-sdk
description: Use when building Android authentication with Ping Identity — scaffolds a complete Jetpack Compose + MVVM authentication flow using the Ping Orchestration Android SDK against PingOne Advanced Identity Cloud (AIC) or PingAM. Handles Journey configuration, OIDC token exchange, dynamic callback rendering, device binding, FIDO2, and logout.
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---

# Android Authentication with Ping Orchestration Android SDK

Scaffold a complete authentication flow in an Android app using Jetpack Compose, MVVM, and the Ping Orchestration Android SDK (Journey module).

---

## Metadata

| Field       | Value |
|-------------|-------|
| Language    | Kotlin |
| Framework   | Android, Jetpack Compose, AndroidX ViewModel |
| SDK         | Ping Orchestration Android SDK (Journey module, `com.pingidentity.sdks:journey`) |
| Pattern     | MVVM (Model-View-ViewModel) |
| Min SDK     | 29 |
| Compile SDK | 36 |

---

## Overview

This skill adds a complete **authentication flow** to an Android application using Jetpack Compose and the MVVM pattern. It uses the **Ping Orchestration Android SDK (Journey module)** to authenticate users against **PingOne AIC (Advanced Identity Cloud)**.

The implementation covers:
- Journey instance configuration (server URL, realm, OIDC module)
- MVVM state management with `StateFlow`
- Composable UI that renders dynamic callback nodes
- Handling all core callback types (username, password, text, choice, etc.)
- Optional advanced callbacks (Device Binding, FIDO, Protect, reCAPTCHA, IdP)
- Success, error, and failure node handling
- Logout support

---

## Prerequisites

### 1. Gradle Dependencies

Add the following to the **app-level** `build.gradle.kts`. See [build.gradle.kts template](assets/build.gradle.kts.template) for a complete example.

```kotlin
dependencies {
    // Ping Orchestration Android SDK (Journey module)
    implementation("com.pingidentity.sdks:journey:<version>")

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
| `serverUrl` | Yes | — | Base URL of the PingOne AIC tenant (e.g. `https://your-tenant.forgeblocks.com/am`) |
| `realm` | Yes | `alpha` | Realm name inside the tenant |
| `clientId` | Yes | — | OAuth 2.0 Client ID registered in PingOne AIC for this Android app |
| `discoveryEndpoint` | Yes | — | Full OIDC discovery endpoint URL (`.well-known/openid-configuration`) |
| `scopes` | Yes | `openid email profile phone` | Space-separated OAuth 2.0 scopes to request |
| `redirectUri` | Yes | `org.forgerock.demo:/oauth2redirect` | OAuth 2.0 redirect URI registered in PingOne AIC |
| `cookieName` | Yes | `iPlanetDirectoryPro` | SSO cookie name for the realm; omit the `cookie` line if blank |
| `journeyName` | No | `Login` | Name of the Journey/Tree to invoke on start |

### Suggested prompts

```
Before I generate the files, I need a few details about your PingOne AIC setup:

1. Server URL          — What is your PingOne AIC tenant base URL?
                         e.g. https://your-tenant.forgeblocks.com/am
2. Client ID           — What is the OAuth 2.0 Client ID for this Android app?
3. Discovery Endpoint  — What is the full OIDC discovery endpoint URL?
                         e.g. https://your-tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration
4. Realm               — Which realm? (default: alpha)
5. Scopes              — Which OAuth 2.0 scopes? (default: openid email profile phone)
6. Redirect URI        — What is the redirect URI? (default: org.forgerock.demo:/oauth2redirect)
7. Cookie name         — SSO cookie name? (default: iPlanetDirectoryPro)
8. Journey name        — Which Journey/Tree to start? (default: Login)
```

### Validation rules

- `serverUrl` must start with `https://` and **not** end with a trailing `/`.
- `discoveryEndpoint` must end with `/.well-known/openid-configuration`.
- `clientId` must be non-empty.
- `redirectUri` must follow `<scheme>:/<path>` format; the scheme must match `manifestPlaceholders["appRedirectUriScheme"]`.
- If `scopes` does not include `openid`, prepend it automatically and warn the user.
- If `discoveryEndpoint` domain differs from `serverUrl` domain, warn the user but proceed.

---

## Implementation Steps

### Step 1 — Configure the Journey Instance

Create `JourneyConfig.kt`. See [JourneyConfig.kt template](assets/JourneyConfig.kt.template).

> **Agent instruction:** Substitute all `<parameter>` placeholders with values collected above.
> Omit the `cookie` line entirely if `cookieName` is blank.

```kotlin
val journey = Journey {
    logger = Logger.STANDARD
    serverUrl = "<serverUrl>"
    realm = "<realm>"
    cookie = "<cookieName>"

    module(Oidc) {
        clientId = "<clientId>"
        discoveryEndpoint = "<discoveryEndpoint>"
        scopes = mutableSetOf("openid", "email", "profile", "phone")
        redirectUri = "<redirectUri>"
    }
}
```

See [Journey SDK API Reference](references/journey-sdk.md) for all configuration options.

---

### Step 2 — Create the Auth State

Create `AuthState.kt`. See [AuthState.kt template](assets/AuthState.kt.template).

```kotlin
data class AuthState(
    val node: Node? = null,
    val counter: Int = 0   // Triggers recomposition when node is the same object
)
```

---

### Step 3 — Create the Auth ViewModel

Create `AuthViewModel.kt`. See [AuthViewModel.kt template](assets/AuthViewModel.kt.template).

Key methods:
- `start()` — Starts or restarts the Journey
- `next(node: ContinueNode)` — Advances to the next node after callbacks are populated
- `refresh()` — Triggers recomposition without advancing
- `logout(onCompleted)` — Logs out the current user

---

### Step 4 — Create the Callback Node Composable

Create `CallbackNode.kt` which dispatches each callback in a `ContinueNode` to its dedicated Composable. See [CallbackNode.kt template](assets/CallbackNode.kt.template).

The pattern:

```kotlin
@Composable
fun CallbackNode(continueNode: ContinueNode, onNodeUpdated: () -> Unit, onNext: () -> Unit) {
    var showNext = true
    continueNode.callbacks.forEach { callback ->
        when (callback) {
            is NameCallback -> NameCallbackField(callback, onNodeUpdated)
            is PasswordCallback -> PasswordCallbackField(callback, onNodeUpdated)
            is ChoiceCallback -> ChoiceCallbackField(callback, onNodeUpdated)
            is ConfirmationCallback -> { showNext = false; ConfirmationCallbackField(callback, onNext) }
            // Add more callbacks as needed
        }
    }
    if (showNext) { Button(onClick = onNext) { Text("Next") } }
}
```

See [Callback Types Reference](references/callbacks.md) for the full list of supported callbacks.

---

### Step 5 — Create Callback Field Composables

Create `CallbackFields.kt` with individual Composables for each callback type. See [CallbackFields.kt template](assets/CallbackFields.kt.template).

All callback types supported by the Ping Android SDK:

**Core Callbacks (Journey module):**

| Callback Class | Composable | Description |
|----------------|------------|-------------|
| `NameCallback` | `NameCallbackField` | Text input for username |
| `PasswordCallback` | `PasswordCallbackField` | Secure text input with visibility toggle |
| `ValidatedUsernameCallback` | `ValidatedUsernameCallbackField` | Username with policy validation |
| `ValidatedPasswordCallback` | `ValidatedPasswordCallbackField` | Password with policy validation |
| `TextInputCallback` | `TextInputCallbackField` | Generic text input (e.g., OTP) |
| `TextOutputCallback` | `TextOutputCallbackField` | Display messages (info, warning, error) |
| `SuspendedTextOutputCallback` | `SuspendedTextOutputCallbackField` | Suspended journey (magic link) |
| `BooleanAttributeInputCallback` | `BooleanCallbackField` | Switch/checkbox for boolean attributes |
| `NumberAttributeInputCallback` | `NumberCallbackField` | Numeric input |
| `StringAttributeInputCallback` | `StringAttributeCallbackField` | String attribute (email, name) |
| `ChoiceCallback` | `ChoiceCallbackField` | Dropdown for multiple choice selection |
| `ConfirmationCallback` | `ConfirmationCallbackField` | Action buttons (Yes/No, OK/Cancel) |
| `KbaCreateCallback` | `KbaCreateCallbackField` | Security question and answer |
| `TermsAndConditionsCallback` | `TermsCallbackField` | Terms acceptance checkbox |
| `ConsentMappingCallback` | `ConsentCallbackField` | Consent to share profile data |
| `PollingWaitCallback` | `PollingWaitCallbackField` | Auto-advancing wait step |
| `HiddenValueCallback` | — | Non-visual — hidden form value |
| `MetadataCallback` | — | Non-visual — specializes into FIDO2/Protect callbacks |

**Optional Callbacks (additional modules):**

| Callback Class | Module | Composable | Description |
|----------------|--------|------------|-------------|
| `SelectIdpCallback` | `external-idp` | `SelectIdpCallbackField` | Social/external IdP selection |
| `IdpCallback` | `external-idp` | `IdpCallbackField` | External IdP OAuth flow |
| `DeviceProfileCallback` | `device-profile` | `DeviceProfileCallbackField` | Auto-collects device metadata |
| `DeviceBindingCallback` | `binding` | `DeviceBindingCallbackField` | Binds device to user account |
| `DeviceSigningVerifierCallback` | `binding` | `DeviceSigningVerifierCallbackField` | Signs challenge with device key |
| `FidoRegistrationCallback` | `fido` | `FidoRegistrationCallbackField` | FIDO2/Passkey registration |
| `FidoAuthenticationCallback` | `fido` | `FidoAuthenticationCallbackField` | FIDO2/Passkey authentication |
| `PingOneProtectInitializeCallback` | `protect` | `PingOneProtectInitializeCallbackField` | Initializes PingOne Protect |
| `PingOneProtectEvaluationCallback` | `protect` | `PingOneProtectEvaluationCallbackField` | Evaluates threat signals |
| `ReCaptchaEnterpriseCallback` | `recaptcha-enterprise` | `ReCaptchaEnterpriseCallbackField` | reCAPTCHA Enterprise verification |

Each callback Composable follows this pattern:
1. **Read** display values from the callback (e.g., `callback.prompt`)
2. **Render** an appropriate Jetpack Compose control
3. **Set** user input back on the callback (e.g., `callback.name = text`)
4. **Call** `onNodeUpdated()` or `onNext()` as appropriate

> **Note:** Auto-advancing callbacks (`PollingWaitCallback`, `DeviceProfileCallback`, `DeviceBindingCallback`, `DeviceSigningVerifierCallback`, `FidoRegistrationCallback`, `FidoAuthenticationCallback`, `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback`, `ReCaptchaEnterpriseCallback`) perform their operation in `LaunchedEffect` and call `onNext()` automatically when complete. Set `showNext = false` for these.

See also:
- [DeviceBindingCallbackField template](assets/DeviceBindingCallbackField.kt.template) and [DeviceBindingCallbackViewModel template](assets/DeviceBindingCallbackViewModel.kt.template)
- [DeviceSigningVerifierCallbackField template](assets/DeviceSigningVerifierCallbackField.kt.template) and [DeviceSigningVerifierCallbackViewModel template](assets/DeviceSigningVerifierCallbackViewModel.kt.template)

---

### Step 6 — Create the Auth Screen Composable

Create `AuthScreen.kt`. See [AuthScreen.kt template](assets/AuthScreen.kt.template).

```kotlin
@Composable
fun AuthScreen(viewModel: AuthViewModel, onSuccess: () -> Unit) {
    BackHandler { viewModel.start() }
    val state by viewModel.state.collectAsState()
    val loading by viewModel.loading.collectAsState()

    Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
        if (loading) CircularProgressIndicator()
        when (val node = state.node) {
            is ContinueNode -> CallbackNode(node, onNodeUpdated = { viewModel.refresh() }, onNext = { viewModel.next(node) })
            is FailureNode -> ErrorCard(message = node.cause.message ?: "Unknown error")
            is ErrorNode -> ErrorCard(message = node.message)
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
composable("auth/{journeyName}", arguments = listOf(
    navArgument("journeyName") { type = NavType.StringType }
)) { backStack ->
    val name = backStack.arguments?.getString("journeyName") ?: "Login"
    val vm: AuthViewModel = viewModel(factory = AuthViewModel.factory(name))
    AuthScreen(viewModel = vm) {
        navController.navigate("home") {
            popUpTo("auth/{journeyName}") { inclusive = true }
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
    --src-dir app/src/main/java \
    --journey Login
```

See [scaffold_auth.sh](scripts/scaffold_auth.sh) for details.

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Wrong redirect URI scheme | Must match `manifestPlaceholders["appRedirectUriScheme"]` in `build.gradle.kts` |
| Missing `openid` scope | Always include `openid` — required for OIDC token exchange |
| Unhandled callback type | Add a `when` branch in `CallbackNode` for every callback your Journey uses |
| Hardcoded credentials | Use `BuildConfig` fields or a config file — never commit secrets |
| Forgetting `LaunchedEffect` for `SuccessNode` | Navigate away inside `LaunchedEffect(true)` to avoid recomposition loops |
| Not setting `showNext = false` for `ConfirmationCallback` | `ConfirmationCallback` provides its own buttons — hide the default Next button |
| Not setting `showNext = false` for auto-advancing callbacks | Auto-advancing callbacks (DeviceBinding, FIDO, Protect, reCAPTCHA, DeviceProfile, PollingWait) must set `showNext = false` |
| Calling `node.next()` without populating callbacks | Always set callback values (e.g., `callback.name = "..."`) before advancing |
| Forgetting to register optional callback modules | Import and add the relevant Gradle dependency (`binding`, `fido`, `protect`, `external-idp`, `device-profile`, `recaptcha-enterprise`) for optional callbacks |
| Not calling `onNext()` after auto-advancing callbacks | Auto-advancing callbacks must call `onNext()` after their async operation completes (use `LaunchedEffect`) |

---

## Reference Documentation

- [Journey SDK API Reference](references/journey-sdk.md) — Journey instance, node types, user/session operations
- [Callback Types Reference](references/callbacks.md) — All supported callback types and their properties
- [OIDC Configuration Reference](references/oidc-config.md) — OIDC module setup, storage, redirect URI

---

## Related Skills

- `ping-quickstart` — Platform detection and Ping Identity orientation
