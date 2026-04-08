---
name: ping-orchestration-ios-davinci-sdk
description: Use when building iOS authentication with PingOne DaVinci — scaffolds a complete SwiftUI + MVVM authentication flow using the Ping Orchestration iOS SDK’s DaVinci module against PingOne DaVinci. Handles DaVinci configuration, OIDC token exchange, dynamic collector rendering, device registration/authentication, FIDO2/passkeys, social login, PingOne Protect, and logout.
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---

# iOS Authentication with Ping Orchestration iOS SDK (DaVinci)

Scaffold a complete authentication flow in an iOS app using SwiftUI, MVVM, and the Ping Orchestration iOS SDK’s DaVinci module.

---

## Metadata

| Field       | Value |
|-------------|-------|
| Language    | Swift |
| Framework   | SwiftUI, Combine |
| SDK         | Ping Identity Orchestration iOS SDK (`PingDavinci`, `PingOidc`, `PingOrchestrate`) |
| Pattern     | MVVM (Model-View-ViewModel) with `@StateObject` / `@ObservedObject` |
| Min iOS     | 16.0 |
| Xcode       | Latest recommended |

---

## Overview

This skill adds a complete **authentication flow** to an iOS application using SwiftUI and the MVVM pattern. It uses the **DaVinci module** of the Ping Orchestration iOS SDK to authenticate users against **PingOne DaVinci**.

> **DaVinci vs Journey:** DaVinci uses **PingOne** as the orchestration server (not PingAM/AIC). It uses **Collectors** instead of Callbacks, and a `DaVinci` class instead of `Journey`. The concepts are similar but the API surface is different.

The implementation covers:
- DaVinci instance configuration (OIDC module with discovery endpoint)
- MVVM state management with `@Published` properties and `@MainActor`
- SwiftUI views that render dynamic collector nodes
- Handling all core collector types (text, password, submit, flow, label, select, etc.)
- Optional collectors (Device Registration/Authentication, Social Login, FIDO2/Passkeys, PingOne Protect)
- Validation via `ValidatedCollector` protocol and `ValidationViewModel`
- Node type handling: `ContinueNode`, `SuccessNode`, `FailureNode`, `ErrorNode`
- ErrorNode handling with `continueNode()` to re-render previous form
- Session management and OIDC token exchange
- Logout support

### Use Cases

1. **Sample Application** — Build a complete, themed iOS app from scratch to demonstrate how the Ping Orchestration iOS SDK works with PingOne DaVinci. This includes all SDK integration files **plus** a full UI with navigation, styled views, user info, access token display. The agent should generate the Xcode project structure, `Package.swift` dependencies, `Info.plist` entries, and all views/components.
2. **Existing Application Integration** — Integrate the Ping Orchestration iOS SDK (DaVinci) into an existing SwiftUI app to add authentication. The agent should generate **only** the SDK integration files (DavinciViewModel, collector views, DavinciView, utility views) and guide the user on wiring them into their existing navigation and layout.

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
// - PingDavinci          (core DaVinci orchestration)
// - PingOidc             (OIDC token management)
// - PingOrchestrate      (base orchestration framework)
```

Optional products for advanced features:

```swift
// - PingExternalIdP           (External IdP base)
// - PingExternalIdPGoogle     (Google Sign-In)
// - PingExternalIdPFacebook   (Facebook Login)
// - PingExternalIdPApple      (Sign in with Apple)
// - PingProtect               (PingOne Protect threat signals)
// - PingFido                  (FIDO2 / Passkey registration & authentication)
// - PingBrowser               (Browser-based authentication flows)
```

### 2. Info.plist — URL Scheme

Register a custom URL scheme for the OAuth 2.0 redirect:

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

---

## Required Configuration

> **Agent instruction:** Before generating any file, collect the values below from the user.
> Ask for all `required` parameters up front in a single prompt. For optional parameters, show the
> default and ask whether the user wants to override it. Do **not** proceed to Step 1 until every
> required parameter has a non-empty value.

### Parameters to collect

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `clientId` | Yes | — | OAuth 2.0 Client ID registered in PingOne for this iOS app |
| `discoveryEndpoint` | Yes | — | Full OIDC discovery endpoint URL (`.well-known/openid-configuration`) from PingOne |
| `scopes` | Yes | `openid email profile` | Space-separated OAuth 2.0 scopes to request |
| `redirectUri` | Yes | `myapp://callback` | OAuth 2.0 redirect URI registered in PingOne |

### Suggested prompts

```
Before I generate the files, I need a few details about your PingOne DaVinci setup:

1. Client ID           — What is the OAuth 2.0 Client ID for this iOS app?
                         (From your PingOne OIDC Web App configuration)
2. Discovery Endpoint  — What is the full OIDC discovery endpoint URL?
                         e.g. https://auth.pingone.com/<envId>/as/.well-known/openid-configuration
3. Scopes              — Which OAuth 2.0 scopes? (default: openid email profile)
4. Redirect URI        — What is the redirect URI? (default: myapp://callback)
```

### Validation rules

- `discoveryEndpoint` must end with `/.well-known/openid-configuration`.
- `clientId` must be non-empty.
- `redirectUri` must follow `<scheme>://<path>` format; the scheme must match `Info.plist` URL scheme.
- If `scopes` does not include `openid`, prepend it automatically and warn the user.

---

## Implementation Steps

### Step 1 — Configure the DaVinci Instance and Create the ViewModel

Create `DavinciViewModel.swift`. See [DavinciViewModel.swift template](assets/DavinciViewModel.swift.template).

> **Agent instruction:** Substitute all `<parameter>` placeholders with values collected above.

```swift
let davinci = DaVinci.createDaVinci { config in
    config.module(OidcModule.config) { oidcValue in
        oidcValue.clientId = "<clientId>"
        oidcValue.scopes = ["openid", "profile", "email"]
        oidcValue.redirectUri = "<redirectUri>"
        oidcValue.discoveryEndpoint = "<discoveryEndpoint>"
    }
}
```

See [DaVinci SDK API Reference](references/davinci-sdk.md) for all configuration options.

---

### Step 2 — Create the Validation ViewModel

Create `ValidationViewModel.swift`. See [ValidationViewModel.swift template](assets/ValidationViewModel.swift.template).

The `ValidationViewModel` is shared across collector views via `@EnvironmentObject` to coordinate form validation before submission.

---

### Step 3 — Create the Main DaVinci View

Create `DavinciView.swift`. See [DavinciView.swift template](assets/DavinciView.swift.template).

```swift
struct DavinciView: View {
    @ObservedObject var viewModel: DavinciViewModel

    var body: some View {
        switch viewModel.state.node {
        case is ContinueNode:
            ConnectorView(node: viewModel.state.node as! ContinueNode, ...)
        case is SuccessNode:
            // Navigate to authenticated state
        case is ErrorNode:
            // Show error with optional re-render of previous form
        case is FailureNode:
            // Show failure message
        default:
            ProgressView()
        }
    }
}
```

---

### Step 4 — Create the ContinueNode View

Create `ContinueNodeView.swift` which dispatches each collector to its dedicated SwiftUI view. See [ContinueNodeView.swift template](assets/ContinueNodeView.swift.template).

The pattern:

```swift
ForEach(node.collectors, id: \.id) { collector in
    switch collector {
    case let c as TextCollector: TextView(collector: c)
    case let c as PasswordCollector: PasswordView(collector: c)
    case let c as SubmitCollector: SubmitButtonView(collector: c, onNext: onNext)
    case let c as FlowCollector: FlowButtonView(collector: c, onNext: onNext)
    case let c as LabelCollector: LabelView(collector: c)
    // ... more collectors
    default: EmptyView()
    }
}
```

See [Collector Types Reference](references/collectors.md) for the full list of supported collectors.

---

### Step 5 — Create Collector Views

Create individual SwiftUI view files for each collector type. See the `assets/` directory for all templates.

All collector types supported by the Ping Orchestration iOS SDK’s DaVinci module:

**Core Collectors (`PingDavinci` module):**

| Collector Class | SwiftUI View | Description |
|-----------------|-------------|-------------|
| `TextCollector` | `TextView` | Text input with validation |
| `PasswordCollector` | `PasswordView` | Secure password input |
| `SubmitCollector` | `SubmitButtonView` | Form submission button (Submittable) |
| `FlowCollector` | `FlowButtonView` | Navigation between flow branches (Submittable) |
| `LabelCollector` | `LabelView` | Static text/label display |
| `SingleSelectCollector` | `DropdownView` / `RadioButtonView` | Single selection — Dropdown or Radio |
| `MultiSelectCollector` | `ComboBoxView` / `CheckBoxView` | Multiple selection — ComboBox or Checkboxes |
| `PhoneNumberCollector` | `PhoneNumberView` | Phone number input |
| `DeviceRegistrationCollector` | `DeviceRegistrationView` | MFA device registration (Submittable) |
| `DeviceAuthenticationCollector` | `DeviceAuthenticationView` | MFA device authentication (Submittable) |

**Optional Collectors (additional modules):**

| Collector Class | Module | SwiftUI View | Description |
|-----------------|--------|-------------|-------------|
| `IdpCollector` | `PingExternalIdP` | `SocialButtonView` | Social login (Google, Facebook, Apple) |
| `FidoRegistrationCollector` | `PingFido` | `FidoRegistrationView` | FIDO2 passkey / security-key registration (Submittable) |
| `FidoAuthenticationCollector` | `PingFido` | `FidoAuthenticationView` | FIDO2 passkey / security-key authentication (Submittable) |
| `ProtectCollector` | `PingProtect` | `PingProtectView` | PingOne Protect risk signals collection |

Each collector view follows this pattern:
1. **Read** display values from the collector (e.g., `collector.label`)
2. **Render** an appropriate SwiftUI control
3. **Bind** user input back to the collector (e.g., `collector.value`)
4. **Call** `onNext(true/false)` as appropriate — `true` for submit actions, `false` for flow navigation

> **Note:** The `onNext` closure takes a `Bool` parameter: `true` indicates a submit action (triggers validation), `false` indicates flow navigation (skips validation).

---

### Step 6 — Wire into Navigation

```swift
@main
struct MyApp: App {
    @StateObject var viewModel = DavinciViewModel()

    var body: some Scene {
        WindowGroup {
            DavinciView(viewModel: viewModel)
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
    --target-dir MyApp/Sources
```

See [scaffold_auth.sh](scripts/scaffold_auth.sh) for details.

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Wrong URL scheme | Must match `Info.plist` `CFBundleURLSchemes` |
| Missing `openid` scope | Always include `openid` — required for OIDC token exchange |
| Unhandled collector type | Add a `case` in `ContinueNodeView` for every collector your DaVinci flow uses |
| Using Journey instead of DaVinci | DaVinci uses `DaVinci.createDaVinci { }` not `Journey.createJourney { }`, uses `collectors` not `callbacks`, uses `PingDavinci` not `PingJourney` |
| Not hiding default Next when Submittable present | When `FlowCollector`, `SubmitCollector`, `DeviceRegistrationCollector`, `DeviceAuthenticationCollector`, `FidoRegistrationCollector`, or `FidoAuthenticationCollector` is present, hide the fallback Next button |
| Forgetting `@EnvironmentObject` for ValidationViewModel | `ValidationViewModel` must be injected via `.environmentObject()` on the parent view |
| Calling `node.next()` without populating collectors | Always set collector values before advancing |
| Confusing DaVinci OidcModule with Journey OidcModule | Import `PingDavinci`, not `PingJourney` |
| Not handling ErrorNode's continueNode() | `ErrorNode` may expose `continueNode()` to re-render the previous form with an error overlay |

---

## Reference Documentation

- [DaVinci SDK API Reference](references/davinci-sdk.md) — DaVinci instance, node types, user/session operations
- [Collector Types Reference](references/collectors.md) — All supported collector types and their properties
- [OIDC Configuration Reference](references/oidc-config.md) — OIDC module setup, storage, redirect URI

---

## Related Skills

- `ping-quickstart` — Platform detection and Ping Identity orientation
- `ping-orchestration-ios-journey-sdk` — iOS authentication using the Journey module (for PingOne AIC/PingAM)
