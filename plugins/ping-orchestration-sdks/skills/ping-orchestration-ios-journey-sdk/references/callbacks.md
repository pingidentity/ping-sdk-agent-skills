# Callback Types Reference — iOS SDK

All callback types supported by the Ping Orchestration iOS SDK for Journey-based authentication.

---

## ContinueNode Properties

Before dispatching callbacks, the `ContinueNode` exposes the following page-level metadata:

| Property | Type | Description |
|----------|------|-------------|
| `pageHeader` | `String` | Node page header — **non-optional**, check `.isEmpty` |
| `pageDescription` | `String` | Node page description — **non-optional**, check `.isEmpty` |
| `callbacks` | `[Callback]` | Array of callbacks to render |
| `submitButtonText` | `String?` | Optional custom submit button label (use `"Next"` as fallback) |

```swift
// Correct — pageHeader and pageDescription are non-optional Strings
if !continueNode.pageHeader.isEmpty {
    Text(continueNode.pageHeader)
}

// WRONG — these properties do not exist
continueNode.header          // compile error
continueNode.nodeDescription // compile error
```

> **Note:** The `JourneyView.swift.template` previously referenced `continueNode.header` and
> `continueNode.description` — those are incorrect. Always use `pageHeader` and `pageDescription`.

---

## Core Callbacks (PingJourney)

These callbacks are registered automatically by `Journey.createJourney`.

### NameCallback

Collects a **username** or name.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `prompt` | `String` | read-only | Label text |
| `name` | `String` | read-write | The user's input value |

```swift
case let callback as NameCallback:
    // Read: callback.prompt
    // Write: callback.name = "entered_username"
```

---

### PasswordCallback

Collects a **password** or one-time passcode.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `prompt` | `String` | read-only | Label text |
| `password` | `String` | read-write | The user's password input |

```swift
case let callback as PasswordCallback:
    // Read: callback.prompt
    // Write: callback.password = "entered_password"
```

---

### ValidatedUsernameCallback (ValidatedCreateUsernameCallback)

Collects a **username** with server-side policy validation.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `prompt` | `String` | read-only | Label text |
| `name` | `String` | read-write | The username input |
| `policies` | `[String: Any]` | read-only | Policy requirements |
| `failedPolicies` | `[String]` | read-only | Policies that failed validation |
| `validateOnly` | `Bool` | read-write | If true, validate without submitting |

---

### ValidatedPasswordCallback (ValidatedCreatePasswordCallback)

Collects a **password** with server-side policy validation.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `prompt` | `String` | read-only | Label text |
| `password` | `String` | read-write | The password input |
| `echoOn` | `Bool` | read-only | Whether to display input |
| `policies` | `[String: Any]` | read-only | Policy requirements |
| `failedPolicies` | `[String]` | read-only | Policies that failed validation |
| `validateOnly` | `Bool` | read-write | If true, validate without submitting |

---

### TextInputCallback

Collects generic **text input** (e.g., OTP, nickname).

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `prompt` | `String` | read-only | Label text |
| `defaultText` | `String` | read-only | Default value |
| `text` | `String` | read-write | The user's text input |

```swift
case let callback as TextInputCallback:
    // Read: callback.prompt, callback.defaultText
    // Write: callback.text = "user_input"
```

---

### TextOutputCallback

Displays a **read-only message** with a message type.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `message` | `String` | read-only | Message to display |
| `messageType` | `MessageType` | read-only | `.information`, `.warning`, `.error`, `.script`, `.unknown` |

```swift
case let callback as TextOutputCallback:
    // Read: callback.message, callback.messageType
    // No user input required
```

**MessageType enum:**
| Value | Raw | Description |
|-------|-----|-------------|
| `.information` | 0 | Informational message |
| `.warning` | 1 | Warning message |
| `.error` | 2 | Error message |
| `.script` | 4 | Script message |
| `.unknown` | -1 | Unknown type |

---

### SuspendedTextOutputCallback

Extends `TextOutputCallback`. Indicates the journey is **suspended** (e.g., waiting for magic link or email verification).

Same properties as `TextOutputCallback`. Display the message and instruct the user to check their email.

---

### BooleanAttributeInputCallback

Collects a **boolean** value.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `prompt` | `String` | read-only | Label text |
| `name` | `String` | read-only | Attribute name |
| `required` | `Bool` | read-only | Whether the attribute is required |
| `value` | `Bool` | read-write | The boolean value |
| `policies` | `[String: Any]` | read-only | Policy requirements |
| `failedPolicies` | `[String]` | read-only | Failed policies |
| `validateOnly` | `Bool` | read-write | Validate-only flag |

---

### NumberAttributeInputCallback

Collects a **numeric** value.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `prompt` | `String` | read-only | Label text |
| `name` | `String` | read-only | Attribute name |
| `required` | `Bool` | read-only | Whether required |
| `value` | `Double` | read-write | The numeric value |

---

### StringAttributeInputCallback

Collects a **string attribute** (email, name, etc.) with policy validation.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `prompt` | `String` | read-only | Label text |
| `name` | `String` | read-only | Attribute name (e.g., `mail`, `givenName`) |
| `required` | `Bool` | read-only | Whether required |
| `value` | `String` | read-write | The string value |
| `policies` | `[String: Any]` | read-only | Policy requirements |
| `failedPolicies` | `[String]` | read-only | Failed policies |
| `validateOnly` | `Bool` | read-write | Validate-only flag |

---

### ChoiceCallback

Presents **multiple choices** for single selection.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `prompt` | `String` | read-only | Label text |
| `choices` | `[String]` | read-only | Available options |
| `defaultChoice` | `Int` | read-only | Default selected index |
| `selectedIndex` | `Int` | read-write | User's selected index |

---

### ConfirmationCallback

Presents **action buttons** (Yes/No, OK/Cancel).

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `prompt` | `String` | read-only | Prompt text |
| `options` | `[String]` | read-only | Button labels |
| `optionType` | `OptionType` | read-only | `.unspecified`, `.yesNo`, `.yesNoCancel`, `.okCancel` |
| `messageType` | `MessageType` | read-only | Message severity |
| `defaultOption` | `OptionType` | read-only | Default option |
| `selectedIndex` | `Int?` | read-write | User's selected option index |

> **Important:** When the user selects an option, set `selectedIndex` and immediately call `onNext()`.

---

### KbaCreateCallback

Collects a **security question and answer**.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `prompt` | `String` | read-only | Label text |
| `predefinedQuestions` | `[String]` | read-only | Available security questions |
| `allowUserDefinedQuestions` | `Bool` | read-only | Whether custom questions are allowed |
| `selectedQuestion` | `String` | read-write | The selected question |
| `selectedAnswer` | `String` | read-write | The user's answer |

---

### TermsAndConditionsCallback

Presents **terms and conditions** for acceptance.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `version` | `String` | read-only | Terms version |
| `terms` | `String` | read-only | Terms text |
| `createDate` | `String` | read-only | Creation date |
| `accepted` | `Bool` | read-write | Whether the user accepted |

---

### ConsentMappingCallback

Prompts the user to **consent to share profile data**.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `String` | read-only | Consent mapping name |
| `displayName` | `String` | read-only | Display name |
| `icon` | `String` | read-only | Icon URL |
| `accessLevel` | `String` | read-only | Access level |
| `isRequired` | `Bool` | read-only | Whether consent is required |
| `fields` | `[String]` | read-only | Fields being shared |
| `message` | `String` | read-only | Message to display |
| `accepted` | `Bool` | read-write | Whether the user accepted |

---

### PollingWaitCallback

Instructs the client to **wait** for a period, then re-submit.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `waitTime` | `Int` | read-only | Milliseconds to wait |
| `message` | `String` | read-only | Message to display |

> This callback auto-submits. Display a spinner with the message, delay by `waitTime`, then call `onNext()`.

---

### HiddenValueCallback

Carries **hidden data** between client and server. Not rendered visually.

> Render as `EmptyView()`. The SDK handles the value automatically.

---

### MetadataCallback

Carries **server-provided metadata**. Specializes into FIDO2 and PingOne Protect callbacks based on content.

> The MetadataCallback is handled internally by the SDK. When the metadata contains WebAuthn or PingOne Protect data, the SDK automatically creates the appropriate specialized callback (`FidoRegistrationCallback`, `FidoAuthenticationCallback`, `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback`).

---

## Optional Callbacks

### SelectIdpCallback (PingExternalIdP)

Presents a list of **external identity providers**.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `providers` | `[IdpValue]` | read-only | Available providers (each has `.provider` string) |
| `value` | `String` | read-write | Selected provider name |

> When user selects a provider, set `value` to the provider name and call `onNext()`. Use `"localAuthentication"` to skip social login and use the "Next" button for local auth.

---

### IdpCallback (PingExternalIdP)

Handles the **OAuth/OIDC flow** with an external identity provider.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `provider` | `String` | read-only | Provider name |
| `clientId` | `String` | read-only | OAuth client ID |
| `redirectUri` | `String` | read-only | Redirect URI |
| `scopes` | `[String]` | read-only | OAuth scopes |

> Call `callback.authorize()` to initiate the external IdP flow. The callback handles the browser flow and token exchange.

---

### DeviceProfileCallback (PingDeviceProfile)

**Auto-collecting** — collects device metadata and submits.

```swift
case let callback as DeviceProfileCallback:
    // Show a loading indicator
    Task {
        await callback.execute()
        onNext()
    }
```

---

### DeviceBindingCallback (PingBinding)

**Auto-advancing** — binds the device to the user account.

```swift
case let callback as DeviceBindingCallback:
    Task {
        let result = await callback.bind()
        // Handle result
        onNext()
    }
```

Supports custom PIN collectors and biometric authentication configuration.

---

### DeviceSigningVerifierCallback (PingBinding)

**Auto-advancing** — signs a challenge with the device key.

```swift
case let callback as DeviceSigningVerifierCallback:
    Task {
        let result = await callback.sign()
        // Handle result
        onNext()
    }
```

---

### FidoRegistrationCallback (PingFido)

Initiates **FIDO2/Passkey registration**.

```swift
case let callback as FidoRegistrationCallback:
    // Get the active window for the authorization controller
    guard let window = UIApplication.shared.connectedScenes
        .first(where: { $0 is UIWindowScene }) as? UIWindowScene,
        let activeWindow = window.windows.first else { return }

    let result = await callback.register(presentOn: activeWindow)
    // Handle result
    onNext()
```

---

### FidoAuthenticationCallback (PingFido)

Initiates **FIDO2/Passkey authentication**.

```swift
case let callback as FidoAuthenticationCallback:
    guard let window = ... else { return }
    let result = await callback.authenticate(presentOn: activeWindow)
    onNext()
```

---

### PingOneProtectInitializeCallback (PingProtect)

**Auto-advancing** — initializes PingOne Protect signals collection.

```swift
case let callback as PingOneProtectInitializeCallback:
    Task {
        await callback.start()
        onNext()
    }
```

---

### PingOneProtectEvaluationCallback (PingProtect)

**Auto-advancing** — collects and submits threat signals.

```swift
case let callback as PingOneProtectEvaluationCallback:
    Task {
        await callback.getData()
        onNext()
    }
```

---

### ReCaptchaEnterpriseCallback (PingReCaptchaEnterprise)

**Auto-advancing** — performs reCAPTCHA Enterprise verification.

```swift
case let callback as ReCaptchaEnterpriseCallback:
    Task {
        await callback.execute()
        onNext()
    }
```

---

## Callback View Pattern

All callback views follow this SwiftUI pattern:

```swift
struct ExampleCallbackView: View {
    let callback: ExampleCallback
    let onNodeUpdated: () -> Void  // For user-input callbacks
    // or
    let onNext: () -> Void         // For auto-advancing callbacks

    @State private var value: String = ""

    var body: some View {
        TextField(callback.prompt, text: $value)
            .onChange(of: value) { newValue in
                callback.value = newValue
            }
            .onAppear {
                value = callback.value
            }
    }
}
```

- **User-input callbacks** receive `onNodeUpdated` — a closure that refreshes the ViewModel when the user modifies a value.
- **Auto-advancing callbacks** receive `onNext` — a closure that submits the current node after the async operation completes.
- **Selection callbacks** (Confirmation, SelectIdP) receive `onNext` and call it immediately after the user makes a selection.
