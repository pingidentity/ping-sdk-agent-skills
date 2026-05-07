# Collector Types Reference (iOS)

Collectors are returned inside a `ContinueNode` during the DaVinci authentication flow.
Access them via `continueNode.collectors`.

> **DaVinci vs Journey:** DaVinci uses **Collectors** (not Callbacks). Collectors are automatically
> created based on field types in the DaVinci JSON response.

---

## Core DaVinci Collectors

### TextCollector
Collects **text input** (username, email, custom fields).

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier (e.g., `user.username`) |
| `label` | `String` | Display label |
| `type` | `String` | Always `"TEXT"` |
| `required` | `Bool` | Whether the field is required |
| `value` | `String` | Read/write: the user's input |

```swift
case let c as TextCollector:
    c.value = "johndoe"
    let errors = c.validate()  // Returns [ValidationError]
```

---

### PasswordCollector
Collects a **password** with optional policy validation.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `type` | `String` | `"PASSWORD"` or `"PASSWORD_VERIFY"` |
| `required` | `Bool` | Whether the field is required |
| `value` | `String` | Read/write: the user's input |

```swift
case let c as PasswordCollector:
    c.value = "s3cr3t"
    let errors = c.validate()
```

---

### SubmitCollector
Renders a **form submission button**. Conforms to `Submittable`.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Button label |
| `value` | `String` | Read/write: value sent on submit |

```swift
case let c as SubmitCollector:
    c.value = "Submit"
    // Call onNext(true) — true triggers validation
```

---

### FlowCollector
Renders a **flow navigation button or link**. Conforms to `Submittable`.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Button/link label |
| `type` | `String` | `"FLOW_BUTTON"` or `"FLOW_LINK"` |
| `value` | `String` | Read/write: value sent on action |

```swift
case let c as FlowCollector:
    c.value = c.key
    // Call onNext(false) — false skips validation
```

---

### LabelCollector
Displays a **static text label** (no user input).

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `content` | `String` | The text content to display |

```swift
case let c as LabelCollector:
    Text(c.content)
```

---

### SingleSelectCollector
Allows the user to select **one option** from a list.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `type` | `String` | `"DROPDOWN"` or `"RADIO"` |
| `options` | `[Option]` | Available options (each has `label` and `value`) |
| `value` | `String` | Read/write: selected option value |

```swift
case let c as SingleSelectCollector:
    if c.type == "DROPDOWN" {
        // Render Picker
    } else {
        // Render radio buttons
    }
```

---

### MultiSelectCollector
Allows the user to select **multiple options**.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `type` | `String` | `"COMBOBOX"` or `"CHECKBOX"` |
| `options` | `[Option]` | Available options |
| `value` | `[String]` | Read/write: selected option values |

```swift
case let c as MultiSelectCollector:
    if c.type == "COMBOBOX" {
        // Render multi-select combo box
    } else {
        // Render checkboxes
    }
```

---

### PhoneNumberCollector
Collects a **phone number**.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `required` | `Bool` | Whether the field is required |
| `value` | `String` | Read/write: the phone number |

---

### DeviceRegistrationCollector
Handles **MFA device registration**. Conforms to `Submittable`.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `devices` | `[Device]` | Available devices for registration |
| `value` | `Device?` | Read/write: selected device |

---

### DeviceAuthenticationCollector
Handles **MFA device authentication**. Conforms to `Submittable`.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `devices` | `[Device]` | Available devices for authentication |
| `value` | `Device?` | Read/write: selected device |

---

## Optional Collectors

### IdpCollector (PingExternalIdP module)
Handles **social/external identity provider** login.

| Property | Type | Description |
|----------|------|-------------|
| `idpEnabled` | `Bool` | Whether the IdP is enabled |
| `idpId` | `String` | IdP identifier |
| `idpType` | `String` | IdP type (`"GOOGLE"`, `"FACEBOOK"`, `"APPLE"`) |
| `label` | `String` | Display label |

```swift
case let c as IdpCollector:
    // Render social login button
    // The collector manages the browser-based OAuth redirect internally
```

---

### FidoRegistrationCollector (PingFido module)
Handles **FIDO2 passkey / security-key registration**.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `type` | `String` | Always `"FIDO2"` |
| `required` | `Bool` | Whether the field is required |
| `publicKeyCredentialCreationOptions` | `[String: Any]` | WebAuthn creation options (transformed from DaVinci format) |

```swift
case let c as FidoRegistrationCollector:
    let result = await c.register(window: window)
    switch result {
    case .success: onNext(false)
    case .failure(let error): /* handle error */
    }
```

Requires SPM product: `PingFido`

> **Note:** `FidoRegistrationCollector` conforms to `Submittable`. The `trigger` property controls whether registration auto-starts or requires a button tap.

---

### FidoAuthenticationCollector (PingFido module)
Handles **FIDO2 passkey / security-key authentication**.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `label` | `String` | Display label |
| `type` | `String` | Always `"FIDO2"` |
| `required` | `Bool` | Whether the field is required |
| `publicKeyCredentialRequestOptions` | `[String: Any]` | WebAuthn request options (transformed from DaVinci format) |

```swift
case let c as FidoAuthenticationCollector:
    let result = await c.authenticate(window: window)
    switch result {
    case .success: onNext(false)
    case .failure(let error): /* handle error */
    }
```

Requires SPM product: `PingFido`

> **Note:** `FidoAuthenticationCollector` conforms to `Submittable`. The `trigger` property controls whether authentication auto-starts or requires a button tap.

---

### ProtectCollector (PingProtect module)
Collects **PingOne Protect risk signals** automatically.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Field identifier |
| `behavioralDataCollection` | `Bool` | Whether behavioral data is collected |
| `universalDeviceIdentification` | `Bool` | Whether universal device ID is enabled |

```swift
case let c as ProtectCollector:
    // Auto-collect signals via .task { }
    try await c.collect()
    onNext(false)
```
