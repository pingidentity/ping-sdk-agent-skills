# Collector Types Reference

Collectors are returned inside a `ContinueNode` during the DaVinci authentication flow.
Access them via `continueNode.collectors`.

> **DaVinci vs Journey:** DaVinci uses **Collectors** (not Callbacks). Collectors are created by
> the `CollectorFactory` based on field types in the DaVinci JSON response.

---

## Core DaVinci Collectors

### TextCollector
Collects **text input** (username, email, custom fields).

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier (e.g., `user.username`) |
| `label` | `String` | Display label |
| `type` | `String` | Always `"TEXT"` |
| `required` | `Boolean` | Whether the field is required |
| `value` | `String` | Read/write: the user's input |
| `validation` | `Validation?` | Regex and error message for client-side validation |

```kotlin
is TextCollector -> {
    it.value = "johndoe"
    val errors = it.validate()  // Returns List<ValidationError>
}
```

Registered type: `TEXT`

---

### PasswordCollector
Collects a **password** with optional policy validation.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `type` | `String` | `"PASSWORD"` or `"PASSWORD_VERIFY"` |
| `required` | `Boolean` | Whether the field is required |
| `value` | `String` | Read/write: the user's input |

```kotlin
is PasswordCollector -> {
    it.value = "s3cr3t"
    val errors = it.validate()  // Validates against password policy
    val policy = it.passwordPolicy()  // Retrieve password policy details
}
```

Additional password-specific checks:
- `it.type == "PASSWORD_VERIFY"` — indicates a password confirmation field

Registered types: `PASSWORD`, `PASSWORD_VERIFY`

---

### SubmitCollector
Renders a **form submission button**. Implements `Submittable`.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Button label |
| `type` | `String` | Always `"SUBMIT_BUTTON"` |
| `value` | `String` | Read/write: value sent on submit |

```kotlin
is SubmitCollector -> {
    it.value = "Submit"
    // Triggers node.next() when clicked
}
```

Registered type: `SUBMIT_BUTTON`

---

### FlowCollector
Renders a **flow navigation button or link**. Implements `Submittable`.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Button/link label |
| `type` | `String` | `"FLOW_BUTTON"` or `"FLOW_LINK"` |
| `value` | `String` | Read/write: value sent on action |

```kotlin
is FlowCollector -> {
    // Check type to decide rendering (button vs link)
    if (it.type == "FLOW_LINK") { /* render as link */ }
    it.value = it.key
    // Triggers node.next() when clicked
}
```

Registered types: `FLOW_BUTTON`, `FLOW_LINK`

---

### LabelCollector
Displays a **static text label** (no user input).

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `content` | `String` | The text content to display |

```kotlin
is LabelCollector -> {
    Text(it.content)
}
```

Registered type: `LABEL`

---

### SingleSelectCollector
Allows the user to select **one option** from a list. Renders as either a **Dropdown** or **Radio** buttons.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `type` | `String` | `"DROPDOWN"` or `"RADIO"` |
| `options` | `List<Option>` | Available options (each has `label` and `value`) |
| `value` | `String` | Read/write: selected option value |

```kotlin
is SingleSelectCollector -> {
    if (it.type == "DROPDOWN") {
        // Render dropdown
    } else {
        // Render radio buttons
    }
    it.value = selectedOption.value
}
```

Registered types: `DROPDOWN`, `RADIO` (via `inputType = SINGLE_SELECT`)

---

### MultiSelectCollector
Allows the user to select **multiple options**. Renders as either a **ComboBox** or **Checkboxes**.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `type` | `String` | `"COMBOBOX"` or `"CHECKBOX"` |
| `options` | `List<Option>` | Available options (each has `label` and `value`) |
| `value` | `List<String>` | Read/write: selected option values |

```kotlin
is MultiSelectCollector -> {
    if (it.type == "COMBOBOX") {
        // Render combo box
    } else {
        // Render checkboxes
    }
    it.value = listOf("option1", "option2")
}
```

Registered types: `COMBOBOX`, `CHECKBOX` (via `inputType = MULTI_SELECT`)

---

### PhoneNumberCollector
Collects a **phone number**.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `required` | `Boolean` | Whether the field is required |
| `value` | `String` | Read/write: the phone number |

```kotlin
is PhoneNumberCollector -> {
    it.value = "+1234567890"
}
```

---

### DeviceRegistrationCollector
Handles **MFA device registration**. Implements `Submittable`.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `devices` | `List<Device>` | Available devices for registration |
| `value` | `Device?` | Read/write: selected device |

```kotlin
is DeviceRegistrationCollector -> {
    // Display available devices
    it.devices.forEach { device -> /* render device option */ }
    it.value = selectedDevice
    // Triggers node.next() when selected
}
```

---

### DeviceAuthenticationCollector
Handles **MFA device authentication**. Implements `Submittable`.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `devices` | `List<Device>` | Available devices for authentication |
| `value` | `Device?` | Read/write: selected device |

```kotlin
is DeviceAuthenticationCollector -> {
    // Display available devices
    it.devices.forEach { device -> /* render device option */ }
    it.value = selectedDevice
    // Triggers node.next() when selected
}
```

---

## Optional Collectors

### IdpCollector (external-idp module)
Handles **social/external identity provider** login (Google, Facebook, Apple).

| Property | Type | Description |
|----------|------|-------------|
| `idpEnabled` | `Boolean` | Whether the IdP is enabled |
| `idpId` | `String` | IdP identifier |
| `idpType` | `String` | IdP type (e.g., `"GOOGLE"`, `"FACEBOOK"`, `"APPLE"`) |
| `label` | `String` | Display label (e.g., "Sign in with Google") |
| `link` | `URL` | Authentication link |

```kotlin
is IdpCollector -> {
    // Render social login button
    // The collector handles the OAuth redirect flow internally
    it.authorize(context)  // Launches browser for IdP auth
}
```

Requires Gradle dependency: `com.pingidentity.sdks:external-idp`
Registered type: `SOCIAL_LOGIN_BUTTON`

---

### FidoRegistrationCollector (fido module)
Handles **FIDO2 passkey / security-key registration**.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `trigger` | `String` | Trigger type (`"BUTTON"` or auto) |
| `required` | `Boolean` | Whether the field is required |
| `publicKeyCredentialCreationOptions` | `JsonObject` | WebAuthn creation options (transformed from DaVinci format) |

```kotlin
is FidoRegistrationCollector -> {
    val result = it.register()
    result.onSuccess { onNext() }
    result.onFailure { error -> /* handle error */ }
}
```

Requires Gradle dependency: `com.pingidentity.sdks:fido`
Registered type: `FIDO2` (action=`REGISTER`)

> **Note:** `FidoRegistrationCollector` implements `Submittable`. When `trigger != "BUTTON"`, registration should auto-trigger via `LaunchedEffect`.

---

### FidoAuthenticationCollector (fido module)
Handles **FIDO2 passkey / security-key authentication**.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `trigger` | `String` | Trigger type (`"BUTTON"` or auto) |
| `required` | `Boolean` | Whether the field is required |
| `publicKeyCredentialRequestOptions` | `JsonObject` | WebAuthn request options (transformed from DaVinci format) |

```kotlin
is FidoAuthenticationCollector -> {
    val result = it.authenticate()
    result.onSuccess { onNext() }
    result.onFailure { error -> /* handle error */ }
}
```

Requires Gradle dependency: `com.pingidentity.sdks:fido`
Registered type: `FIDO2` (action=`AUTHENTICATE`)

> **Note:** `FidoAuthenticationCollector` implements `Submittable`. When `trigger != "BUTTON"`, authentication should auto-trigger via `LaunchedEffect`.

---

### ProtectCollector (protect module)
Collects **PingOne Protect risk signals** automatically.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `behavioralDataCollection` | `Boolean` | Whether behavioral data is collected |
| `universalDeviceIdentification` | `Boolean` | Whether universal device ID is enabled |

```kotlin
is ProtectCollector -> {
    val result = it.collect()
    when (result) {
        is Result.Success -> { /* signals collected, advance */ }
        is Result.Failure -> { /* handle error */ }
    }
}
```

Requires Gradle dependency: `com.pingidentity.sdks:protect`

---

## Collector Factory Registration

Collectors are auto-registered via Android's `ContentProvider` initialization:

| Field Type | Collector Class |
|------------|----------------|
| `TEXT` | `TextCollector` |
| `PASSWORD` | `PasswordCollector` |
| `PASSWORD_VERIFY` | `PasswordCollector` |
| `SUBMIT_BUTTON` | `SubmitCollector` |
| `ACTION` (inputType) | `FlowCollector` |
| `LABEL` | `LabelCollector` |
| `SINGLE_SELECT` (inputType) | `SingleSelectCollector` |
| `MULTI_SELECT` (inputType) | `MultiSelectCollector` |
| `SOCIAL_LOGIN_BUTTON` | `IdpCollector` |
| `FIDO2` | `FidoCollector` → `FidoRegistrationCollector` or `FidoAuthenticationCollector` |
| `PROTECT` | `ProtectCollector` |
