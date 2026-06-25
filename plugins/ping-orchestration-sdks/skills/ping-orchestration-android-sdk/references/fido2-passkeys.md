# Android FIDO2 / Passkeys Implementation Guide

Gradle module: `com.pingidentity.sdks:fido`. Both `FidoRegistrationCallback` and `FidoAuthenticationCallback` are **auto-advancing** — always wrap in `LaunchedEffect(callback)` with `showNext = false`.

---

## AIC Prerequisites

Before mobile WebAuthn will work, three server-side steps must be completed in AIC:

1. Upload `assetlinks.json` using the `applyAndroidAssetLinks` MCP tool (or via AIC console)
2. Upload `apple-app-site-association` for iOS counterpart
3. Add a CORS policy allowing the app origin

See: `ping-orchestration` skill → `references/curated/pingone-st/journey-use-cases/webauthn-mobile-setup.md`

---

## Gradle dependency

```kotlin
// build.gradle.kts (app module)
dependencies {
    implementation("com.pingidentity.sdks:fido:<version>")
}
```

Import: `import com.pingidentity.fido.journey.FidoRegistrationCallback` and `import com.pingidentity.fido.journey.FidoAuthenticationCallback`.

---

## Journey variant — Jetpack Compose

### Registration

```kotlin
@Composable
fun FidoRegistrationCallbackView(
    callback: FidoRegistrationCallback,
    onNext: () -> Unit,
    showNext: Boolean = false   // always false — callback self-advances
) {
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var isRegistering by remember { mutableStateOf(false) }

    // Auto-advance: runs once per distinct callback instance
    LaunchedEffect(callback) {
        isRegistering = true
        try {
            callback.register()
            onNext()
        } catch (e: Exception) {
            errorMessage = e.message ?: "Registration failed"
        } finally {
            isRegistering = false
        }
    }

    if (isRegistering) {
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
    }
    errorMessage?.let { Text(it, color = MaterialTheme.colorScheme.error) }
    // showNext is always false — do not render a Next button
}
```

### Authentication

```kotlin
@Composable
fun FidoAuthenticationCallbackView(
    callback: FidoAuthenticationCallback,
    onNext: () -> Unit,
    showNext: Boolean = false
) {
    var errorMessage by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(callback) {
        try {
            callback.authenticate()
            onNext()
        } catch (e: Exception) {
            errorMessage = e.message ?: "Authentication failed"
        }
    }

    errorMessage?.let { Text(it, color = MaterialTheme.colorScheme.error) }
}
```

### Wire into `CallbackNodeView`

```kotlin
is FidoRegistrationCallback -> FidoRegistrationCallbackView(callback = callback, onNext = onNext)
is FidoAuthenticationCallback -> FidoAuthenticationCallbackView(callback = callback, onNext = onNext)
```

The `showNext = false` in the parent `CallbackNodeView` **must** be set when any auto-advancing callback is present.

---

## DaVinci variant

DaVinci exposes FIDO2 through `FidoRegistrationCollector` and `FidoAuthenticationCollector` inside a `ContinueNode`. Handle them in the `ContinueNodeView` when block:

```kotlin
is FidoRegistrationCollector -> {
    var done by remember { mutableStateOf(false) }
    LaunchedEffect(collector) {
        collector.register()
        done = true
    }
    if (done) onNext()
}

is FidoAuthenticationCollector -> {
    LaunchedEffect(collector) {
        collector.authenticate()
        onNext()
    }
}
```

---

## Auto-advancing rule

`FidoRegistrationCallback` and `FidoAuthenticationCallback` trigger the OS biometric prompt and must advance the flow themselves. **Always:**
- Set `showNext = false` in the enclosing callback or collector view
- Wrap the suspend call in `LaunchedEffect(callback)` — using a button `onClick` causes double-execution on recompose if the composable is re-entered

---

## Common mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Missing `fido` Gradle module | `Unresolved reference: FidoRegistrationCallback` | Add `implementation("com.pingidentity.sdks:fido:<version>")` |
| Button `onClick` instead of `LaunchedEffect` | OS prompt shown twice on recompose | Use `LaunchedEffect(callback)` |
| Calling `.execute()` | `Unresolved reference: execute` — there is no `.execute()` | Use `.register()` / `.authenticate()` |
| `showNext = true` left on parent | Next button visible during biometric prompt | Set `showNext = false` whenever a FIDO callback is present |
| Asset links not uploaded to AIC | WebAuthn ceremony fails with `NotAllowedError` | Complete AIC prerequisites (see above) before testing |
| `rpId` mismatch between registration and authentication | Assertion rejected after successful credential creation | `WebAuthnRegistrationNode.rpId` must equal `WebAuthnAuthenticationNode.rpId` exactly |
