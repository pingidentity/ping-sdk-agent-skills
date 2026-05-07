---
name: ping-orchestration-ios-journey-sdk
description: Use when building iOS authentication with Ping Identity — scaffolds a complete SwiftUI + MVVM authentication flow using the Ping Orchestration iOS SDK against PingOne Advanced Identity Cloud (AIC) or PingAM. Handles Journey configuration, OIDC token exchange, dynamic callback rendering, device binding, FIDO2, and logout.
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---

# iOS Authentication with Ping Orchestration iOS SDK

Scaffold a complete authentication flow in an iOS app using SwiftUI, MVVM, and the Ping Orchestration iOS SDK (Journey module).

---

## Metadata

| Field       | Value |
|-------------|-------|
| Language    | Swift |
| Framework   | SwiftUI, Combine |
| SDK         | Ping Orchestration iOS SDK (Journey module: `PingJourney`, `PingOidc`, `PingOrchestrate`) |
| Pattern     | MVVM (Model-View-ViewModel) with `@StateObject` / `@ObservedObject` |
| Min iOS     | 16.0 |
| Xcode       | Latest recommended |

---

## Overview

This skill adds a complete **authentication flow** to an iOS application using SwiftUI and the MVVM pattern. It uses the **Ping Identity Orchestration iOS SDK** (Journey module) to authenticate users against **PingOne Advanced Identity Cloud (AIC)** or **PingAM**.

The implementation covers:
- Journey instance configuration (server URL, realm, cookie, OIDC module)
- MVVM state management with `@Published` properties and `@MainActor`
- SwiftUI views that render dynamic callback nodes
- Handling all core callback types (username, password, text, choice, etc.)
- Optional advanced callbacks (Device Binding, Device Signing Verifier, FIDO2, Protect, reCAPTCHA Enterprise, External IdP)
- Node type handling: `ContinueNode`, `SuccessNode`, `FailureNode`, `ErrorNode`
- Session management and OIDC token exchange
- Logout support

### Use Cases

1. **Sample Application** — Build a complete, themed iOS app from scratch to demonstrate how the Ping Orchestration iOS SDK works with PingAM and AIC. This includes all SDK integration files **plus** a full UI with navigation, styled views, user info, access token display, and device management. The agent should generate the Xcode project structure, `Package.swift` dependencies, `Info.plist` entries, and all views/components.
2. **Existing Application Integration** — Integrate the Ping Orchestration iOS SDK into an existing SwiftUI app to add authentication, step-up authentication, or any Journey/Tree-based flow supported by the SDK. The agent should generate **only** the SDK integration files (JourneyViewModel, callback views, JourneyView, utility views) and guide the user on wiring them into their existing navigation and layout.

---

## Prerequisites

### 1. Swift Package Manager Dependencies

Add the Ping iOS SDK via Swift Package Manager in Xcode:

**Package URL:** `https://github.com/ForgeRock/ping-ios-sdk`

Required products:

```swift
// In Package.swift or Xcode > File > Add Package Dependencies
.package(url: "https://github.com/ForgeRock/ping-ios-sdk", from: "1.3.0")

// Products to include:
// - PingJourney          (core Journey orchestration)
// - PingOidc             (OIDC token management)
// - PingOrchestrate      (base orchestration framework)
// - PingJourneyPlugin    (callback infrastructure)
```

Optional products for advanced features:

```swift
// - PingBinding               (Device Binding / Signing Verifier)
// - PingFido                  (FIDO2 / WebAuthn)
// - PingExternalIdP           (External IdP base)
// - PingExternalIdPGoogle     (Google Sign-In)
// - PingExternalIdPFacebook   (Facebook Login)
// - PingExternalIdPApple      (Sign in with Apple)
// - PingProtect               (PingOne Protect threat signals)
// - PingDeviceProfile         (Device profile collection)
// - PingReCaptchaEnterprise   (reCAPTCHA Enterprise)
// - PingDeviceId              (Device identifier)
// - PingTamperDetector        (Jailbreak detection)
// - PingBrowser               (In-app browser)
// - PingStorage               (Secure storage)
// - PingLogger                (Logging)
```

See [Package.swift template](assets/Package.swift.template) for a complete example.

### 2. CORS Configuration (PingAM / AIC)

Configure CORS in your PingAM or AIC tenant:

| Setting | Value |
|---------|-------|
| Allowed Origins | Your app's redirect URI scheme |
| Allowed Methods | `GET`, `POST` |
| Allowed Headers | `Content-Type`, `X-Requested-With`, `X-Requested-Platform`, `Accept-API-Version`, `Authorization` |
| Allow Credentials | Enabled |

### 3. OAuth 2.0 Client Registration

Create a **native/mobile** OAuth client in PingAM / AIC:

| Setting | Value |
|---------|-------|
| Client Type | Native / Public |
| Grant Types | Authorization Code |
| Token Endpoint Auth Method | `none` |
| Scopes | `openid profile email` (minimum) |
| Redirect URIs | Your app's custom URL scheme (e.g., `myapp://callback`) |
| Implicit Consent | Enabled |

### 4. Info.plist Configuration

Add the following to your `Info.plist` for URL scheme handling:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

If using Google Sign-In, add the reversed client ID URL scheme. If using Facebook, add the Facebook app ID and display name entries.

---

## Required Configuration

> **Agent instruction:** Before generating any file, collect the values below from the user.
>
> **Step 0 — Determine use case:** Ask the user whether they want a **sample app** (full scaffold
> including Xcode project structure, `Package.swift`, `Info.plist`, navigation, and styled views) or
> **existing app integration** (only SDK integration files: JourneyViewModel, callback views, JourneyView).
> This affects what files are generated in later steps.
>
> Ask for all `required` parameters up front in a single prompt. For optional parameters, show the
> default and ask whether the user wants to override it. Do **not** proceed to Step 1 until every
> required parameter has a non-empty value.

### Parameters to collect

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `serverUrl` | Yes | — | PingAM / AIC server URL (e.g., `https://your-tenant.forgeblocks.com/am`) |
| `realm` | Yes | `alpha` | Authentication realm |
| `cookieName` | No | `iPlanetDirectoryPro` | Session cookie name |
| `clientId` | Yes | — | OAuth 2.0 Client ID registered in PingAM / AIC for this iOS app |
| `scopes` | Yes | `openid profile email` | OAuth 2.0 scopes (as a Swift array of strings) |
| `redirectUri` | Yes | — | OAuth 2.0 redirect URI (custom URL scheme, e.g., `myapp://callback`) |
| `discoveryEndpoint` | Yes | — | OIDC discovery endpoint URL (e.g., `https://your-tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration`) |
| `journeyLogin` | No | `Login` | Name of the login Journey/Tree to invoke |
| `journeyRegister` | No | `Registration` | Name of the registration Journey/Tree to invoke |

### Suggested prompts

```
Before I get started, I want to confirm — are you wanting me to help you create a sample app or
integrate with your existing iOS app?

Before I generate the files, I need a few details about your PingAM / AIC setup:

1. Server URL          — What is your PingAM/AIC server URL?
                         e.g. https://your-tenant.forgeblocks.com/am
2. Realm               — Which realm? (default: alpha)
3. Cookie Name         — Session cookie name? (default: iPlanetDirectoryPro)
4. Client ID           — What is the OAuth 2.0 Client ID for this iOS app?
5. Scopes              — Which OAuth 2.0 scopes? (default: openid profile email)
6. Redirect URI        — What is the redirect URI? (e.g., myapp://callback)
7. Discovery Endpoint  — What is the OIDC discovery endpoint URL?
                         e.g. https://your-tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration
8. Login Journey       — Which Journey/Tree for login? (default: Login)
9. Register Journey    — Which Journey/Tree for registration? (default: Registration)
```

### Validation rules

- `serverUrl` must start with `https://` and should not have a trailing `/`.
- `realm` must be non-empty (commonly `alpha`, `bravo`, or `root`).
- `clientId` must be non-empty.
- If `scopes` does not include `openid`, prepend it automatically and warn the user.
- `redirectUri` must use a custom URL scheme (not `http://` or `https://`), e.g., `myapp://callback`.
- `discoveryEndpoint` must start with `https://` and end with `/.well-known/openid-configuration`.

### Discovery endpoint construction guidance

> **Agent instruction:** Users often provide a **base AM URL** (e.g., `https://your-tenant.forgeblocks.com/am`)
> instead of the full discovery endpoint. If the provided URL does **not** end with
> `/.well-known/openid-configuration`:
>
> 1. **Ask the user which realm** they are using (commonly `alpha` or `bravo` for AIC).
> 2. **Construct the discovery endpoint** as:
>    `<serverUrl>/oauth2/<realm>/.well-known/openid-configuration`
> 3. Strip any trailing `/` from the server URL before construction.
> 4. Confirm the constructed URL with the user before proceeding.

---

## Implementation Steps

### Step 1 — Configure the Journey Instance

Create `JourneyViewModel.swift` — the central ViewModel that configures the Journey instance and manages the authentication flow. See [JourneyViewModel.swift template](assets/JourneyViewModel.swift.template).

The Journey instance is created with `Journey.createJourney`:

```swift
import PingJourney
import PingOrchestrate
import PingOidc

let journey = Journey.createJourney { config in
    config.serverUrl = "<serverUrl>"
    config.realm = "<realm>"
    config.cookie = "<cookieName>"
    config.module(PingJourney.OidcModule.config) { oidcConfig in
        oidcConfig.clientId = "<clientId>"
        oidcConfig.scopes = [<scopes>]
        oidcConfig.redirectUri = "<redirectUri>"
        oidcConfig.discoveryEndpoint = "<discoveryEndpoint>"
    }
}
```

> **Agent instruction:** Substitute all `<parameter>` placeholders with values collected above.

See [Journey SDK Reference](references/journey-sdk.md) for configuration details.

---

### Step 2 — Implement the Journey ViewModel

The `JourneyViewModel` manages the Journey flow state using `@Published` properties:

```swift
@MainActor
class JourneyViewModel: ObservableObject {
    @Published var state: JourneyState = JourneyState()
    @Published var isLoading: Bool = false
    @Published var showJourneyNameInput: Bool = true

    func startJourney(with journeyName: String) async { ... }
    func next(node: ContinueNode) async { ... }
    func refresh() { ... }
}
```

Key responsibilities:
- Start or restart a Journey by name
- Advance to the next node with `ContinueNode.next()`
- Handle `SuccessNode`, `FailureNode`, and `ErrorNode` outcomes
- Manage loading state and journey name persistence

See [JourneyViewModel.swift template](assets/JourneyViewModel.swift.template).

---

### Step 3 — Create the Journey View

Create `JourneyView.swift` — the SwiftUI view that renders the current Journey node. See [JourneyView.swift template](assets/JourneyView.swift.template).

The view:
- Shows a Journey name input screen initially
- Switches to the callback rendering view when a Journey is started
- Handles node types: `ContinueNode` → render callbacks, `SuccessNode` → navigate to token, `ErrorNode`/`FailureNode` → show error

```swift
struct JourneyView: View {
    @StateObject private var journeyViewModel = JourneyViewModel()
    @Binding var path: [MenuItem]

    var body: some View {
        // Switch on journeyViewModel.state.node type
    }
}
```

---

### Step 4 — Create the Callback Dispatch View

Create `CallbackView` (within `JourneyView.swift`) — dispatches each callback to its dedicated SwiftUI view using Swift `switch` on callback type.

```swift
// Inside JourneyNodeView
for callback in continueNode.callbacks {
    switch callback {
    case let nameCallback as NameCallback:
        NameCallbackView(callback: nameCallback, onNodeUpdated: onNodeUpdated)
    case let passwordCallback as PasswordCallback:
        PasswordCallbackView(callback: passwordCallback, onNodeUpdated: onNodeUpdated)
    // ... other callback types
    default:
        Text("Unsupported callback type")
    }
}
```

See [Callback Types Reference](references/callbacks.md) for the full list of supported callbacks.

---

### Step 5 — Create Callback Views

Create individual SwiftUI views for each callback type. See [callback view templates](assets/).

All callback types supported by the Ping iOS SDK:

**Core Callbacks (PingJourney module):**

| Callback Class | View | Description |
|----------------|------|-------------|
| `NameCallback` | `NameCallbackView` | Text input for username |
| `PasswordCallback` | `PasswordCallbackView` | Secure text input for password |
| `ValidatedUsernameCallback` | `ValidatedUsernameCallbackView` | Username with policy validation |
| `ValidatedPasswordCallback` | `ValidatedPasswordCallbackView` | Password with policy validation |
| `TextInputCallback` | `TextInputCallbackView` | Generic text input (e.g., OTP) |
| `TextOutputCallback` | `TextOutputCallbackView` | Display messages (info, warning, error) |
| `SuspendedTextOutputCallback` | `TextOutputCallbackView` | Suspended journey (magic link) — reuses TextOutputCallbackView |
| `BooleanAttributeInputCallback` | `BooleanAttributeInputCallbackView` | Toggle for boolean attributes |
| `NumberAttributeInputCallback` | `NumberAttributeInputCallbackView` | Numeric input |
| `StringAttributeInputCallback` | `StringAttributeInputCallbackView` | String attribute (email, name) with validation |
| `ChoiceCallback` | `ChoiceCallbackView` | Picker for multiple choice selection |
| `ConfirmationCallback` | `ConfirmationCallbackView` | Action buttons (Yes/No, OK/Cancel) |
| `KbaCreateCallback` | `KbaCreateCallbackView` | Security question and answer |
| `TermsAndConditionsCallback` | `TermsAndConditionsCallbackView` | Terms acceptance toggle |
| `ConsentMappingCallback` | `ConsentMappingCallbackView` | Consent to share profile data |
| `PollingWaitCallback` | `PollingWaitCallbackView` | Auto-advancing wait step |
| `HiddenValueCallback` | `EmptyView` | Non-visual — hidden form value |
| `MetadataCallback` | (handled internally) | Non-visual — specializes into FIDO2/Protect callbacks |

**Optional Callbacks (additional modules):**

| Callback Class | Module | View | Description |
|----------------|--------|------|-------------|
| `SelectIdpCallback` | `PingExternalIdP` | `SelectIdpCallbackView` | Social/external IdP selection |
| `IdpCallback` | `PingExternalIdP` | `IdpCallbackView` | External IdP OAuth flow |
| `DeviceProfileCallback` | `PingDeviceProfile` | `DeviceProfileCallbackView` | Auto-collects device metadata |
| `DeviceBindingCallback` | `PingBinding` | `DeviceBindingCallbackView` | Binds device to user account |
| `DeviceSigningVerifierCallback` | `PingBinding` | `DeviceSigningVerifierCallbackView` | Signs challenge with device key |
| `FidoRegistrationCallback` | `PingFido` | `FidoRegistrationCallbackView` | FIDO2/Passkey registration |
| `FidoAuthenticationCallback` | `PingFido` | `FidoAuthenticationCallbackView` | FIDO2/Passkey authentication |
| `PingOneProtectInitializeCallback` | `PingProtect` | `PingOneProtectInitializeCallbackView` | Initializes PingOne Protect |
| `PingOneProtectEvaluationCallback` | `PingProtect` | `PingOneProtectEvaluationCallbackView` | Evaluates threat signals |
| `ReCaptchaEnterpriseCallback` | `PingReCaptchaEnterprise` | `ReCaptchaEnterpriseCallbackView` | reCAPTCHA Enterprise verification |

Each callback view follows this pattern:
1. **Read** display values from the callback (e.g., `callback.prompt`)
2. **Render** an appropriate SwiftUI control
3. **Set** user input back on the callback (e.g., `callback.name = text`)
4. **Call** `onNodeUpdated()` or `onNext()` as appropriate

> **Note:** Auto-advancing callbacks (`PollingWaitCallback`, `DeviceProfileCallback`, `DeviceBindingCallback`, `DeviceSigningVerifierCallback`, `FidoRegistrationCallback`, `FidoAuthenticationCallback`, `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback`, `ReCaptchaEnterpriseCallback`) perform their operation in `.onAppear` and call `onNext()` automatically when complete.

---

### Step 6 — Create Utility Views

Create shared utility views used across the app. See [CustomViews.swift template](assets/CustomViews.swift.template) and [ErrorView.swift template](assets/ErrorView.swift.template).

- `NextButton` — Reusable styled button for form submission
- `HeaderView` / `DescriptionView` — Node header and description display
- `ErrorView` / `ErrorNodeView` / `ErrorMessageView` — Error state views
- Color extensions for theme consistency

---

### Step 7 — Create the Content View and Navigation

Create `ContentView.swift` — the main app view with navigation. See [ContentView.swift template](assets/ContentView.swift.template).

```swift
struct ContentView: View {
    @State private var path: [MenuItem] = []

    var body: some View {
        NavigationStack(path: $path) {
            // Menu items: Journey, Token, User Info, Logout, etc.
        }
        .navigationDestination(for: MenuItem.self) { item in
            switch item {
            case .journey: JourneyView(path: $path)
            case .token: AccessTokenView(menuItem: item)
            case .user: UserInfoView(menuItem: item)
            case .logout: LogOutView(path: $path)
            // ... other items
            }
        }
    }
}
```

---

### Step 8 — Create Supporting Views

Create views for token display, user info, logout, and device management:

- `AccessTokenView` — Displays the current access token. See [AccessTokenView.swift template](assets/AccessTokenView.swift.template).
- `UserInfoView` — Displays user info from the OIDC userinfo endpoint. See [UserInfoView.swift template](assets/UserInfoView.swift.template).
- `LogOutView` — Ends the session and revokes tokens. See [LogOutView.swift template](assets/LogOutView.swift.template).

---

### Step 9 — Create Supporting ViewModels

Create ViewModels for token, user info, and logout operations:

- `AccessTokenViewModel` — Fetches the access token from the OIDC module. See [AccessTokenViewModel.swift template](assets/AccessTokenViewModel.swift.template).
- `UserInfoViewModel` — Fetches user info from the OIDC userinfo endpoint. See [UserInfoViewModel.swift template](assets/UserInfoViewModel.swift.template).
- `LogOutViewModel` — Handles session revocation and logout. See [LogOutViewModel.swift template](assets/LogOutViewModel.swift.template).

---

### Step 10 — Create the App Entry Point

Create the `@main` App struct. See [App.swift template](assets/App.swift.template).

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle URL scheme callbacks (Google, Facebook, etc.)
                }
        }
    }
}
```

---

## Common Mistakes

> **Agent instruction:** Watch for these patterns and warn the user.

| Mistake | Fix |
|---------|-----|
| Using `http://` for `serverUrl` | Always use `https://` for the server URL |
| Forgetting to register optional callback modules | Import and register callbacks from `PingBinding`, `PingFido`, `PingProtect`, `PingExternalIdP`, `PingDeviceProfile`, `PingReCaptchaEnterprise` as needed |
| Not handling `ErrorNode` vs `FailureNode` | `ErrorNode` = server-side errors (invalid credentials), `FailureNode` = SDK-side failures (network error). Handle both. |
| Missing `@MainActor` on ViewModel | The `JourneyViewModel` must be annotated `@MainActor` since it updates `@Published` properties from async contexts |
| Not calling `onNext()` after auto-advancing callbacks | Auto-advancing callbacks (DeviceBinding, FIDO, Protect, reCAPTCHA, DeviceProfile) must call `onNext()` after their async operation completes |
| Missing URL scheme in Info.plist | The custom URL scheme for OAuth redirect must be registered in `Info.plist` `CFBundleURLTypes` |
| Not configuring OIDC module | The `PingJourney.OidcModule.config` block is required for token exchange to work after `SuccessNode` |
| Using `ObservableObject` without `@StateObject` or `@ObservedObject` | Use `@StateObject` for ownership, `@ObservedObject` for injection |
| `SuccessNode`: using `path.append(...)` or `path = [.someView]` instead of `path = []` | `path.append` skips the root home view entirely; `path = [.someView]` creates a *new* view instance that re-runs `checkSession()` and may see no user yet (timing), reverting to logged-out state. The correct pattern is `path = []` — pop to root so the existing root view's `onChange(of: path)` triggers `checkSession()` against `journey.user()` and transitions to the logged-in state. |
| Importing optional modules not added as SPM products | Only `import` a module if it has been added as an SPM product in Xcode. Each optional import (`PingBinding`, `PingFido`, `PingProtect`, etc.) requires the corresponding product added under File > Add Package Dependencies. Importing a module not in the target produces "No such module" build errors. |

---

## References

- [Journey SDK Reference](references/journey-sdk.md) — Journey API, configuration, node types, session management
- [Callback Types Reference](references/callbacks.md) — All callback types with properties and usage
- [OIDC Configuration Reference](references/oidc-config.md) — OIDC module configuration, token management, user info
- [Ping iOS SDK Repository](https://github.com/ForgeRock/ping-ios-sdk/)
- [iOS Sample App (Journey Module)](https://github.com/ForgeRock/sdk-sample-apps/tree/main/iOS/swiftui-journey-module)
- [Ping SDK Documentation](https://docs.pingidentity.com/sdks/latest/sdks/index.html)
