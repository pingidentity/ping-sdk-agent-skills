# Callback Types Reference

Callbacks are returned inside a `ContinueNode` during the Journey authentication flow.
Access them via `continueNode.callbacks`.

---

## Core Journey Callbacks

### NameCallback
Collects a **username** or generic name input.

| Property | Type     | Description                     |
|----------|----------|---------------------------------|
| `prompt` | `String` | Label to display to the user    |
| `name`   | `String` | Read/write: the user's input    |

```kotlin
is NameCallback -> {
    callback.name = "johndoe"
}
```

---

### PasswordCallback
Collects a **password** or one-time passcode.

| Property   | Type     | Description                   |
|------------|----------|-------------------------------|
| `prompt`   | `String` | Label to display              |
| `password` | `String` | Write-only: the user's secret |

```kotlin
is PasswordCallback -> {
    callback.password = "s3cr3t"
}
```

---

### ValidatedUsernameCallback
Collects a username **with server-side policy validation**.

| Property   | Type     | Description                        |
|------------|----------|------------------------------------|
| `prompt`   | `String` | Label                              |
| `username` | `String` | Read/write: validated username     |
| `policies` | `List`   | Optional: validation policy hints  |

---

### ValidatedPasswordCallback
Collects a password **with server-side policy validation**.

| Property   | Type     | Description                         |
|------------|----------|-------------------------------------|
| `prompt`   | `String` | Label                               |
| `password` | `String` | Write-only                          |
| `policies` | `List`   | Optional: validation policy hints   |

---

### TextInputCallback
Collects generic **text input** (e.g., nickname, OTP, custom field).

| Property      | Type     | Description                  |
|---------------|----------|------------------------------|
| `prompt`      | `String` | Label                        |
| `defaultText` | `String` | Pre-filled default value     |
| `value`       | `String` | Read/write: the user's input |

---

### TextOutputCallback
Displays a **server-provided message** (no user input required).

| Property        | Type  | Description                                      |
|-----------------|-------|--------------------------------------------------|
| `message`       | `String` | The text to display                           |
| `messageType`   | `Int` | `0` = INFO, `1` = WARNING, `2` = ERROR, `4` = SCRIPT |

```kotlin
is TextOutputCallback -> {
    Text(callback.message)
}
```

---

### ChoiceCallback
Allows the user to select **one option from a list**.

| Property         | Type           | Description                             |
|------------------|----------------|-----------------------------------------|
| `prompt`         | `String`       | Label                                   |
| `choices`        | `List<String>` | Available options                       |
| `defaultChoice`  | `Int`          | Index of default selection              |
| `selectedIndex`  | `Int`          | Read/write: index of selected choice    |

---

### ConfirmationCallback
Displays **action buttons** (e.g., "Submit", "Cancel"). Replaces the default Next button.

| Property   | Type           | Description                             |
|------------|----------------|-----------------------------------------|
| `prompt`   | `String`       | Optional prompt text                    |
| `options`  | `List<String>` | Button labels                           |
| `selectedIndex` | `Int`     | Read/write: which button was pressed    |

> Set `showNext = false` in your `CallbackNode` when this callback is present.

---

### BooleanAttributeInputCallback
Collects a **true/false** value (e.g., "Receive marketing emails?").

| Property | Type      | Description              |
|----------|-----------|--------------------------|
| `prompt` | `String`  | Label                    |
| `value`  | `Boolean` | Read/write: user's input |

---

### NumberAttributeInputCallback
Collects a **numeric** value.

| Property | Type     | Description              |
|----------|----------|--------------------------|
| `prompt` | `String` | Label                    |
| `value`  | `Double` | Read/write: user's input |

---

### StringAttributeInputCallback
Collects an **arbitrary string attribute** (for profile enrichment).

| Property | Type     | Description              |
|----------|----------|--------------------------|
| `prompt` | `String` | Label                    |
| `value`  | `String` | Read/write: user's input |

---

### KbaCreateCallback
Collects **Knowledge-Based Authentication** (security question & answer).

| Property          | Type           | Description                        |
|-------------------|----------------|------------------------------------|
| `prompt`          | `String`       | Instruction text                   |
| `predefinedQuestions` | `List<String>` | Questions to choose from       |
| `selectedQuestion` | `String`      | Write: question selected by user   |
| `answer`          | `String`       | Write: user's answer               |

---

### TermsAndConditionsCallback
Displays **terms & conditions** for user acceptance.

| Property  | Type     | Description                         |
|-----------|----------|-------------------------------------|
| `terms`   | `String` | The T&C text                        |
| `version` | `String` | Version identifier                  |
| `accept`  | `Boolean`| Write: whether user accepted        |

---

### ConsentMappingCallback
Prompts the user to **consent to data sharing**.

| Property       | Type     | Description                   |
|----------------|----------|-------------------------------|
| `name`         | `String` | Consent name                  |
| `displayName`  | `String` | Human-readable name           |
| `fields`       | `List`   | Fields being consented to     |
| `accept`       | `Boolean`| Write: consent decision       |

---

### PollingWaitCallback
Instructs the client to **wait** then auto-resubmit.

| Property        | Type  | Description                            |
|-----------------|-------|----------------------------------------|
| `waitTime`      | `Int` | Milliseconds to wait before advancing  |
| `message`       | `String` | Message to display while waiting    |

> Set `showNext = false`. Launch a coroutine to `delay(waitTime)` then call `onNext()`.

---

### SuspendedTextOutputCallback
Pauses authentication for **magic-link / email verification**. Similar to `TextOutputCallback` but
the journey is suspended server-side.

> Set `showNext = false`. Display the message and wait for the user to click a link in their email.

---

### HiddenValueCallback
Carries **hidden data** between client and server. Not rendered visually.

> Render nothing. The SDK handles the value automatically.

---

### MetadataCallback
Carries **server-provided metadata**. Specializes into FIDO2 and PingOne Protect callbacks based on content.

> The MetadataCallback is handled internally by the SDK. When the metadata contains WebAuthn or PingOne Protect data, the SDK automatically creates the appropriate specialized callback (`FidoRegistrationCallback`, `FidoAuthenticationCallback`, `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback`).

---

## Optional Module Callbacks

These require additional Gradle dependencies beyond the core `journey` module.

---

### SelectIdpCallback
**Dependency:** `com.pingidentity.sdks:external-idp`

Presents a list of **external identity providers** for social login.

| Property | Type | Description |
|----------|------|-------------|
| `providers` | `List<IdpValue>` | Available providers (each has `.provider` and `.uiName`) |
| `value` | `String` | Write: selected provider name |

```kotlin
is SelectIdpCallback -> {
    // showNext = false
    field.providers.forEach { provider ->
        Button(onClick = { field.value = provider.provider; onNext() }) {
            Text("Sign in with ${provider.uiName}")
        }
    }
}
```

> Set `showNext = false`. When the user selects a provider, set `value` and call `onNext()` immediately.

---

### IdpCallback
**Dependency:** `com.pingidentity.sdks:external-idp`

Handles the **OAuth/OIDC flow** with an external identity provider.

| Property | Type | Description |
|----------|------|-------------|
| `provider` | `String` | Provider name |
| `clientId` | `String` | OAuth client ID |
| `redirectUri` | `String` | Redirect URI |
| `scopes` | `List<String>` | OAuth scopes |

```kotlin
is IdpCallback -> {
    // showNext = false
    LaunchedEffect(field) { field.signIn(); onNext() }
    CircularProgressIndicator()
}
```

> **Auto-advancing.** Call `field.signIn()` to initiate the external IdP flow, then `onNext()` when complete.

---

### DeviceProfileCallback
**Dependency:** `com.pingidentity.sdks:device-profile`

**Auto-advancing** — collects device metadata and submits.

```kotlin
is DeviceProfileCallback -> {
    // showNext = false
    LaunchedEffect(field) {
        field.execute(DeviceProfileConfig {
            addCollector(HardwareCollector)
            addCollector(BrowserCollector)
            addCollector(PlatformCollector)
            addCollector(NetworkCollector)
            addCollector(TelephonyCollector)
        })
        onNext()
    }
    CircularProgressIndicator()
}
```

---

### DeviceBindingCallback
**Dependency:** `com.pingidentity.sdks:binding`

**Auto-advancing** — binds the device to the user's account using biometric, PIN, or application-level keys.

| Method | Description |
|--------|-------------|
| `bind()` | Initiates the binding process |
| `setType(type)` | Sets the key type (`APPLICATION_PIN`, `BIOMETRIC_ONLY`, `BIOMETRIC_ALLOW_FALLBACK`, `NONE`) |

```kotlin
is DeviceBindingCallback -> {
    // showNext = false
    // Uses dedicated ViewModel — see DeviceBindingCallbackField template
    val vm: DeviceBindingCallbackViewModel = viewModel(
        factory = DeviceBindingCallbackViewModel.factory(field)
    )
    DeviceBindingCallbackField(vm, onNext)
}
```

See [DeviceBindingCallbackField template](../assets/DeviceBindingCallbackField.kt.template) and [DeviceBindingCallbackViewModel template](../assets/DeviceBindingCallbackViewModel.kt.template).

---

### DeviceSigningVerifierCallback
**Dependency:** `com.pingidentity.sdks:binding`

**Auto-advancing** — verifies a previously bound device by signing a challenge.

| Method | Description |
|--------|-------------|
| `sign()` | Signs the server challenge with the device key |

```kotlin
is DeviceSigningVerifierCallback -> {
    // showNext = false
    // Uses dedicated ViewModel — see DeviceSigningVerifierCallbackField template
    val vm: DeviceSigningVerifierCallbackViewModel = viewModel(
        factory = DeviceSigningVerifierCallbackViewModel.factory(field)
    )
    DeviceSigningVerifierCallbackField(vm, onNext)
}
```

See [DeviceSigningVerifierCallbackField template](../assets/DeviceSigningVerifierCallbackField.kt.template) and [DeviceSigningVerifierCallbackViewModel template](../assets/DeviceSigningVerifierCallbackViewModel.kt.template).

---

### FidoRegistrationCallback
**Dependency:** `com.pingidentity.sdks:fido`

**Auto-advancing** — initiates FIDO2/WebAuthn/Passkey registration.

```kotlin
is FidoRegistrationCallback -> {
    // showNext = false
    LaunchedEffect(field) { field.register(); onNext() }
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        CircularProgressIndicator()
        Text("Registering FIDO2 credential...")
    }
}
```

---

### FidoAuthenticationCallback
**Dependency:** `com.pingidentity.sdks:fido`

**Auto-advancing** — initiates FIDO2/WebAuthn/Passkey authentication.

```kotlin
is FidoAuthenticationCallback -> {
    // showNext = false
    LaunchedEffect(field) { field.authenticate(); onNext() }
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        CircularProgressIndicator()
        Text("Authenticating with FIDO2...")
    }
}
```

---

### PingOneProtectInitializeCallback
**Dependency:** `com.pingidentity.sdks:protect`

**Auto-advancing** — initializes PingOne Protect signals collection.

```kotlin
is PingOneProtectInitializeCallback -> {
    // showNext = false
    LaunchedEffect(field) { field.start(); onNext() }
    CircularProgressIndicator()
}
```

---

### PingOneProtectEvaluationCallback
**Dependency:** `com.pingidentity.sdks:protect`

**Auto-advancing** — collects and submits threat signals.

```kotlin
is PingOneProtectEvaluationCallback -> {
    // showNext = false
    LaunchedEffect(field) { field.getData(); onNext() }
    CircularProgressIndicator()
}
```

---

### ReCaptchaEnterpriseCallback
**Dependency:** `com.pingidentity.sdks:recaptcha-enterprise`

**Auto-advancing** — performs reCAPTCHA Enterprise bot detection.

```kotlin
is ReCaptchaEnterpriseCallback -> {
    // showNext = false
    LaunchedEffect(field) { field.execute(); onNext() }
    CircularProgressIndicator()
}
```

---

## Callback Composable Pattern

All callback Composables follow this pattern:

```kotlin
@Composable
fun ExampleCallbackField(field: ExampleCallback, onNodeUpdated: () -> Unit) {
    var value by remember(field) { mutableStateOf(field.value) }
    OutlinedTextField(
        value = value,
        onValueChange = { value = it; field.value = it; onNodeUpdated() },
        label = { Text(field.prompt) }
    )
}
```

- **User-input callbacks** receive `onNodeUpdated` — triggers recomposition when the user modifies a value.
- **Auto-advancing callbacks** receive `onNext` — submits the current node after the async operation completes.
- **Selection callbacks** (Confirmation, SelectIdP) receive `onNext` and call it immediately after the user makes a selection.

> **Note:** Auto-advancing callbacks (`PollingWaitCallback`, `DeviceProfileCallback`, `DeviceBindingCallback`, `DeviceSigningVerifierCallback`, `FidoRegistrationCallback`, `FidoAuthenticationCallback`, `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback`, `ReCaptchaEnterpriseCallback`) perform their operation in `LaunchedEffect` and call `onNext()` automatically when complete. Set `showNext = false` for these.
