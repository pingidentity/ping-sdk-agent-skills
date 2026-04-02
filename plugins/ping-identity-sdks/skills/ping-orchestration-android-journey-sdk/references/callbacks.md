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

## Optional Module Callbacks

These require additional Gradle dependencies beyond the core `journey` module.

### DeviceProfileCallback
**Dependency:** `com.pingidentity.sdks:device-profile`

Collects device profile data automatically (hardware, network, platform info).

### DeviceBindingCallback
**Dependency:** `com.pingidentity.sdks:binding`

Binds the device to the user's account using biometric, PIN, or application-level keys.

### DeviceSigningVerifierCallback
**Dependency:** `com.pingidentity.sdks:binding`

Verifies a previously bound device by signing a challenge.

### FidoRegistrationCallback / FidoAuthenticationCallback
**Dependency:** `com.pingidentity.sdks:fido`

FIDO2 / WebAuthn registration and authentication.

### IdpCallback / SelectIdpCallback
**Dependency:** `com.pingidentity.sdks:external-idp`

Authentication through external Identity Providers (Google, Facebook, Apple).

### PingOneProtectInitializeCallback / PingOneProtectEvaluationCallback
**Dependency:** `com.pingidentity.sdks:protect`

PingOne Protect fraud signal collection and risk evaluation.

### ReCaptchaEnterpriseCallback
**Dependency:** `com.pingidentity.sdks:recaptcha-enterprise`

Google reCAPTCHA Enterprise bot detection integration.
