---
name: ping-sdk-ios
description: >
  Guide for building iOS apps that integrate with the Ping Identity SDK (PingSDK). Use this
  skill whenever the user is: (1) building any iOS app that uses PingOne, PingAM/AIC, DaVinci,
  Journey, or OIDC authentication; (2) asking how to configure PingSDK modules (Journey, DaVinci,
  OIDC, FIDO, Protect, ExternalIdP, OATH, Push); (3) asking how to render Journey callbacks or
  DaVinci collectors in SwiftUI; (4) troubleshooting authentication flows in a PingSDK-based iOS
  app; (5) setting up token/session storage with KeychainStorage; (6) scaffolding a new Xcode
  project for a PingSDK app; (7) applying Ping Identity branding to a sample app; (8) implementing
  OIDC centralized login with OidcWebClient, configuring ASWebAuthenticationSession or
  SFSafariViewController, handling browser redirects, or wiring onOpenURL for OAuth2 authorization
  code flows; (9) analysing a PingAM/AIC Journey export JSON to identify required callbacks and
  generate a matching iOS sample. Invoke proactively even if the user just says "I need to add
  PingOne login to my app", "how do I set up Journey in iOS", "how do I add OIDC centralized
  login", "make this look like a Ping sample app", or pastes / attaches a Journey export JSON.
compatibility:
  mcp:
    - xcodebuildmcp  # required for Xcode project scaffolding (Section 0)
---

## Skill Parameters

This skill accepts an optional argument string when invoked as `/ping-sdk-ios <args>`.

### No-arg Invocation — Wizard Mode

When invoked with **no arguments** (`/ping-sdk-ios`), run the wizard:

**Step W1 — Determine intent** using `AskUserQuestion`:

```
"What would you like to do?"
Options:
  A) Build a new sample app      — scaffold a complete Xcode project with full Ping branding
  B) Integrate into existing app — generate only the SDK files to drop into your project
  C) Browse the reference guide  — show the full SDK reference
  D) Something else              — let me describe what I need
```

- **A / B** → Step W1b, then Step W2
  - A: follow with Automated Project Creation (read `assets/project-scaffolding.md`)
  - B: generate SDK integration files only (no Xcode project scaffolding)
- **C** → display the reference guide from "Ping SDK for iOS — Integration Guide" onward. Stop.
- **D** → follow-up free-text question, then route accordingly.

**Step W1b — Journey export offer** (options A and B only).

Ask:
> "Do you have a Journey export JSON file? If so, paste it or attach it and I'll analyse it to generate a sample that handles exactly the callbacks your Journey uses."

- If provided: run Section 15 (Journey Export Analysis) before Step W2. Pre-populate `journeyName`, `callbackTier`, and `serverUrl` from the analysis results.
- If not: continue to Step W2 as normal.

**Step W2 — Collect configuration** (required for A and B).

Ask all required parameters in a single `AskUserQuestion` call. Show defaults where they exist. Do not proceed until every required field has a value.

| Parameter | Required | Default | Description |
|---|---|---|---|
| `appName` | Yes | — | App name used for Swift types, `PingHeaderView` title, and bundle ID. E.g. `PingDemo` |
| `outputPath` | Yes (A only) | — | Directory to write the Xcode project (absolute path) |
| `flowType` | Yes | — | `oidc-web` · `journey` · `davinci` |
| `clientId` | Yes | — | OAuth 2.0 Client ID |
| `redirectUri` | Yes | — | OAuth 2.0 redirect URI (custom scheme, e.g. `myapp://callback`) |
| `discoveryEndpoint` | Yes | — | OIDC discovery endpoint URL (`.well-known/openid-configuration`) |
| `scopes` | No | `openid profile email` | OAuth 2.0 scopes, comma-separated |
| `serverUrl` | Journey/DaVinci only | — | PingAM/AIC server URL |
| `realm` | Journey/DaVinci only | `alpha` | Authentication realm |
| `cookieName` | Journey/DaVinci only | `iPlanetDirectoryPro` | Session cookie name |
| `callbackTier` | Journey/DaVinci only | — | `basic`, `standard`, or `full` (see Section 14) |
| `journeyName` | Journey only | `Login` | Journey tree name |
| `acrValues` | DaVinci/OIDC only | _(none)_ | Optional ACR values; omit entirely if not provided |

Ask `callbackTier` only for journey/davinci. Ask `journeyName` only for journey. Ask `acrValues` only for davinci/oidc-web.

Present `callbackTier` options:
- **Basic** — `NameCallback`, `PasswordCallback`, `TextOutputCallback`, `ChoiceCallback` (Journey) / `TextCollector`, `PasswordCollector`, `SubmitCollector`, `LabelCollector` (DaVinci). Minimal dependencies.
- **Standard** — Everything in Basic plus: attribute callbacks, FIDO, Protect, Device Binding/Profile, SelectIdp, T&C, KBA, PollingWait, ConsentMapping. No third-party social SDKs.
- **Full fat** — Everything in Standard plus `IdpCallback`/`IdpCollector` (social login) and `ReCaptchaEnterpriseCallback`. Requires Facebook, Google, and ReCaptcha Enterprise SPM dependencies.

**Validation rules:**
- `redirectUri` must use a custom scheme (not `http://` or `https://`).
- `discoveryEndpoint` must start with `https://` and end with `/.well-known/openid-configuration`. If the user provides a base AM URL, construct `<serverUrl>/oauth2/<realm>/.well-known/openid-configuration` and confirm.
- `scopes` must include `openid`. If missing, prepend it and warn.
- `serverUrl` must start with `https://` and have no trailing `/`.

**Step W3 — Confirm and generate.** Summarise collected values in a short table, ask "Ready to generate — does this look right?", then proceed on confirmation.

---

### Parameters (with-args invocation)

| Parameter | Syntax | Purpose |
|---|---|---|
| `create-sample` | `create-sample "<description>"` | Generate a complete runnable sample app |
| `app-name` | `app-name "<name>"` | Set the app name. Defaults to `"MyApp"` if omitted. |
| `output-path` | `output-path "<path>"` | Write files to disk. If omitted, print inline. |

### `create-sample "<description>"`

1. **Analyse** the description — identify flow type(s), modules, and implied screens.
2. **Journey export offer** — if the flow type is `journey` (or could be), ask:
   > "Do you have a Journey export JSON? I can analyse it and tailor the sample to exactly the callbacks your Journey uses."
   If provided, run Section 15 before proceeding. Use its output to determine `callbackTier` and screens.
3. **Ask one clarifying question** only if the flow type is genuinely ambiguous. Collect `clientId`, `redirectUri`, and `discoveryEndpoint` in a single `AskUserQuestion` with an explicit "I can use placeholders" option.
4. **Resolve the app name** from `app-name` or use `"MyApp"`.
5. **Generate** using the template files in `assets/`:
   - For OIDC Web flows: start from `App.swift.oidc.template`, `AppOidc.swift.template`, `OidcLoginViewModel.swift.template`, `ContentView.swift.oidc.template`, `LoginView.swift.oidc.template`, `AuthenticatedView.swift.oidc.template`, `Theme.swift.template`
   - Substitute all `PLACEHOLDER_*` tokens (see table below)
   - `@Observable @MainActor` ViewModels — never `ObservableObject`/`@Published`
   - SwiftUI views with Ping Identity branding (Section 13)
   - Full node/state switch covering success, failure, error, and continue cases
6. **Deliver:**
   - With `output-path`: read `assets/project-scaffolding.md` and follow Steps 0–G exactly.
   - Without `output-path`: print every file inline with a `// --- <Filename>.swift ---` header.

### Template Placeholders

| Placeholder | Replaces with |
|---|---|
| `PLACEHOLDER_APP_NAME` | Resolved app name (e.g. `PingDemo`) |
| `PLACEHOLDER_APP_NAME_UPPER` | Upper-cased app name (e.g. `PINGDEMO`) |
| `PLACEHOLDER_CLIENT_ID` | `clientId` value |
| `PLACEHOLDER_REDIRECT_URI` | `redirectUri` value |
| `PLACEHOLDER_DISCOVERY_ENDPOINT` | `discoveryEndpoint` value |
| `PLACEHOLDER_SCOPES` | Scopes as Swift array literal (e.g. `"openid", "profile", "email"`) |
| `PLACEHOLDER_SERVER_URL` | `serverUrl` (Journey/DaVinci only) |
| `PLACEHOLDER_REALM` | `realm` (Journey/DaVinci only) |
| `PLACEHOLDER_COOKIE_NAME` | `cookieName` (Journey/DaVinci only) |
| `PLACEHOLDER_JOURNEY_NAME` | `journeyName` (Journey only, default `"Login"`) |
| `PLACEHOLDER_ACR_VALUES` | `acrValues` — omit the entire line if not provided |

When the user chose placeholder mode: use `"yourClientId"`, `"yourapp://callback"`, `"https://your-tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration"`.

### Automated Project Creation (when `output-path` is provided)

Read `assets/project-scaffolding.md` and follow Steps 0–G exactly. Key reminders:
- Use deployment target `18.0`.
- Layout is **flat** — `.xcodeproj`, source dir, and `Config/` are siblings directly under `<output-path>/`.
- `PBXFileSystemSynchronizedRootGroup` means Swift files dropped in the source dir are included automatically.
- Use `project.objects.each` (not `project.root_object.objects`) to iterate all project objects in Ruby scripts.

**Examples:**
```
/ping-sdk-ios create-sample "a simple username/password login using Journey"
/ping-sdk-ios create-sample "OIDC centralized login with token display and sign-out" app-name "PingDemo" output-path "/Users/me/Dev"
/ping-sdk-ios create-sample "Journey login with FIDO passkey registration and biometric auth" app-name "FidoSample"
```

---

# Ping SDK for iOS — Integration Guide

## Naming Conventions for Code Examples

Always use full, descriptive variable and parameter names. Never abbreviate: `vm` → `viewModel`, `cb` → `nameCallback`, `cfg` → `journeyConfig`. This applies to local bindings in `switch` statements and closure arguments (never use `$0`).

## Flow Types — Choose Your Integration Path

**Journey (native/embedded)** — Authentication UI rendered entirely inside your app using SwiftUI views. No browser launched. `onOpenURL` / `OpenURLMonitor` are **not needed**.

**OIDC Web (`OidcWebClient`)** — Uses `SFSafariViewController` or `ASWebAuthenticationSession`. Must wire `onOpenURL` → `OpenURLMonitor.shared.handleOpenURL(url)` and handle foreground resumption.

**DaVinci** — Like Journey (native), but uses collectors instead of callbacks. Social IdP collectors (`IdpCollector`) do launch a browser, so wire `onOpenURL` if your DaVinci flow uses them.

## Module Map

Pick only what you need — the SDK is modular:

| Module | Import | When to add |
|---|---|---|
| `PingOrchestrate` | Core engine — `Node`, `ContinueNode`, `SuccessNode`, `FailureNode`, `ErrorNode` | Always (import explicitly in any file using node types) |
| `PingJourneyPlugin` | `Callback` protocol | Any file that declares `any Callback` parameters |
| `PingJourney` | `import PingJourney` | PingOne AIC / AM Journey flows, all concrete callback types |
| `PingDavinci` | `import PingDavinci` | PingOne DaVinci flows |
| `PingDavinciPlugin` | `import PingDavinciPlugin` | `Collector` protocol — any file using `any Collector` or switching on collector types |
| `PingOidc` | `import PingOidc` | OIDC / OAuth token handling, `User` / `userinfo`, `OidcWebClient` |
| `PingBrowser` | `import PingBrowser` | Centralized login — `BrowserType`, `BrowserMode`, `BrowserLauncher`, `OpenURLMonitor` |
| `PingLogger` | `import PingLogger` | Unified logging |
| `PingStorage` | `import PingStorage` | Keychain token/session storage |
| `PingExternalIdP` | `import PingExternalIdP` | Social login (Apple/Google/Facebook) |
| `PingFido` | `import PingFido` | FIDO2 / WebAuthn |
| `PingProtect` | `import PingProtect` | PingOne Protect risk signals |
| `PingBinding` | `import PingBinding` | Device binding & signing |
| `PingOath` | `import PingOath` | TOTP / HOTP MFA |
| `PingPush` | `import PingPush` | Push notification MFA |

## 1 — SDK Package Reference

```
https://github.com/ForgeRock/ping-ios-sdk
```

```swift
.package(url: "https://github.com/ForgeRock/ping-ios-sdk", from: "2.0.0")
// Add only the products your target needs:
.product(name: "PingJourney", package: "ping-ios-sdk"),
.product(name: "PingOidc", package: "ping-ios-sdk"),
.product(name: "PingBrowser", package: "ping-ios-sdk"),   // OidcWebClient flows
```

**CocoaPods:**
```ruby
pod 'PingJourney'
pod 'PingStorage'
pod 'PingLogger'
```

## 2 — Node Type Reference

```swift
// PingOrchestrate — import in any file pattern-matching on nodes

struct FailureNode: Node {
    let cause: Error          // NON-OPTIONAL — use cause.localizedDescription
}
struct ErrorNode: Node {
    let message: String       // NON-OPTIONAL
    let status: Int?
}
struct SuccessNode: Node {
    let session: Session      // NON-OPTIONAL
}
// ContinueNode — more input needed (callbacks for Journey, collectors for DaVinci)
```

**`Node` is NOT `Equatable`** — track state changes via separate Bool flags:
```swift
var isRegistered = false   // set in next() based on returned node type
```

## 3 — Callback Property Types

Journey callback properties are **non-optional Strings**. Do not use `?? fallback`.

**Basic tier:**

| Callback | Property | Type |
|---|---|---|
| `NameCallback` | `.name` (write), `.prompt` (read) | `String` |
| `PasswordCallback` | `.password` (write), `.prompt` (read) | `String` |
| `TextInputCallback` | `.text` (write), `.prompt` (read) | `String` |
| `ChoiceCallback` | `.selectedIndex` (write), `.prompt`, `.choices` (read) | `String` / `[String]` |
| `TextOutputCallback` | `.message` (read), `.messageType` (read) | `String` / `MessageType` |

**Standard tier — non-obvious property names (compile errors if guessed wrong):** Read `assets/journey-callbacks.md` for the complete Critical API Facts section before writing any Standard-tier callback view.

Key gotchas:
- `ValidatedUsernameCallback` → `.username` (NOT `.value`)
- `ValidatedPasswordCallback` → `.password` (NOT `.value`)
- `ConfirmationCallback` → `.options` (NOT `.choices`), `.selectedIndex: Int?`
- `TermsAndConditionsCallback` → `.accepted: Bool` (NOT `.accept`)
- `KbaCreateCallback` → `.selectedQuestion`, `.selectedAnswer` (NOT `.answer`)
- `SelectIdpCallback` → `.value = provider.provider` — NO `.setProvider()` method

## 4 — AppJourney Singleton

```swift
import PingJourney
import PingOrchestrate
import PingLogger

@MainActor
class AppJourney {
    static let shared = AppJourney()

    let journey: Journey

    private init() {
        journey = Journey.createJourney { journeyConfig in
            journeyConfig.serverUrl = "https://your-server.example.com/am"
            journeyConfig.realm     = "alpha"
            journeyConfig.cookie    = "your-cookie-name"
            journeyConfig.logger    = LogManager.standard
            journeyConfig.module(PingJourney.OidcModule.config) { oidcConfig in
                oidcConfig.clientId          = "yourClientId"
                oidcConfig.scopes            = ["openid", "profile", "email"]
                oidcConfig.redirectUri       = "yourapp://callback"
                oidcConfig.discoveryEndpoint = "https://your-server.example.com/am/oauth2/alpha/.well-known/openid-configuration"
                oidcConfig.logger            = LogManager.standard
            }
        }
    }
}
```

The `journeyName` collected in the wizard is passed to `journey.start()` at call time:
```swift
node = await AppJourney.shared.journey.start(journeyName)
```

For multi-flow apps (Journey + DaVinci + OIDC Web) and token storage customisation, see `assets/advanced-patterns.md`.

## 5 — Journey Authentication Flow

### ViewModel pattern

```swift
import Foundation
import Observation
import PingJourney
import PingOrchestrate

@Observable
@MainActor
final class LoginViewModel {
    var node: Node?
    var isLoading = false

    let journeyName: String

    init(journeyName: String = "Login") {
        self.journeyName = journeyName
    }

    func start() async {
        isLoading = true
        defer { isLoading = false }
        node = await AppJourney.shared.journey.start(journeyName)
    }

    func next(continueNode: ContinueNode) async {
        isLoading = true
        defer { isLoading = false }
        node = await continueNode.next()
    }

    func reset() { node = nil }
}
```

Own the model with `@State`, not `@StateObject`:
```swift
@State private var loginViewModel = LoginViewModel()
```

### Top-Level Node Switch

```swift
import PingOrchestrate
import PingJourney

switch loginViewModel.node {
case let successNode as SuccessNode:
    AuthenticatedView(successNode: successNode, onSignOut: loginViewModel.reset)
case let failureNode as FailureNode:
    ErrorView(message: failureNode.cause.localizedDescription, onRetry: retry)
case let errorNode as ErrorNode:
    ErrorView(
        message: errorNode.message.isEmpty ? "An error occurred." : errorNode.message,
        onRetry: retry
    )
case let continueNode as ContinueNode:
    LoginView(continueNode: continueNode, isLoading: loginViewModel.isLoading,
              onNext: { Task { await loginViewModel.next(continueNode: continueNode) } })
default:
    LoginView(continueNode: nil, isLoading: loginViewModel.isLoading,
              onNext: { Task { await loginViewModel.start() } })
}
```

### Callback Renderer (`ContinueNodeView`)

`Callback` lives in `PingJourneyPlugin` — import it explicitly:

```swift
import PingJourney
import PingJourneyPlugin   // required for `any Callback`
import PingOrchestrate
import PingFido

struct ContinueNodeView: View {
    let node: ContinueNode
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ForEach(node.callbacks, id: \.id) { callback in
                callbackView(for: callback)
            }
            if !hasSelfAdvancingCallback {
                Button("Next", action: onNext).buttonStyle(PingPrimaryButtonStyle())
            }
        }
    }

    private var hasSelfAdvancingCallback: Bool {
        node.callbacks.contains { callback in
            callback is FidoRegistrationCallback || callback is FidoAuthenticationCallback
        }
    }

    @ViewBuilder
    private func callbackView(for callback: any Callback) -> some View {  // 'any Callback' required in Swift 6
        switch callback {
        case let nameCallback as NameCallback:
            NameCallbackView(callback: nameCallback)
        case let passwordCallback as PasswordCallback:
            PasswordCallbackView(callback: passwordCallback)
        case let textOutputCallback as TextOutputCallback:
            Text(textOutputCallback.message).font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        case let fidoRegistrationCallback as FidoRegistrationCallback:
            FidoRegistrationCallbackView(callback: fidoRegistrationCallback, onNext: onNext)
        case let fidoAuthenticationCallback as FidoAuthenticationCallback:
            FidoAuthenticationCallbackView(callback: fidoAuthenticationCallback, onNext: onNext)
        default:
            EmptyView()
        }
    }
}
```

When generating a Journey app, **always read `assets/journey-callbacks.md`** before writing any callback view code.

## 6 — Session Lifecycle

```swift
let user: User? = await AppJourney.shared.journey.journeyUser()

if let user = user {
    let result = await user.userinfo(cache: false)
    switch result {
    case .success(let info):
        info.forEach { key, value in print("\(key): \(String(describing: value))") }
    case .failure(let error):
        print(error.localizedDescription)
    }
}

_ = await AppJourney.shared.journey.signOff()
```

## 7 — App Entry Point Integration

**Journey / DaVinci native flows** — no `onOpenURL` needed:
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

**OIDC Web and social IdP callbacks — three required wiring points:**
```swift
import PingBrowser

@main
struct MyApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    OpenURLMonitor.shared.handleOpenURL(url)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active,
                       BrowserLauncher.currentBrowser.isInProgress {
                        BrowserLauncher.currentBrowser.handleAppActivation()
                    }
                }
        }
    }
}
```

**URL scheme registration** — in scaffold projects using `GENERATE_INFOPLIST_FILE = YES`, use the Ruby snippet (Step D in `assets/project-scaffolding.md`). Do not hand-author `Info.plist` (causes `Multiple commands produce Info.plist`) or use xcconfig bracketed syntax (causes `error: expected to find '=' in macro condition`).

## 8 — OIDC Web Flow (`OidcWebClient`)

Choose **OIDC Web** when the IDP hosts the login page. Choose **Journey native** (Section 5) when you need credential fields in your app's SwiftUI views.

`authorize()` is `async throws` and returns `Result<User, OidcError>`. Two error channels — `throws` for network/OIDC discovery failures and `Result.failure` for authorization errors. Always handle both in a `do/catch` wrapping a `switch result`.

For the `AppOidc` singleton, `OidcWebClientConfig` API, `OidcError` cases, `BrowserType` trade-offs, `OidcLoginViewModel`, and branded `OidcLoginView` — read `assets/oidc-web-reference.md`.

## 9 — DaVinci Flow

DaVinci uses **collectors** instead of callbacks. The `@Observable` ViewModel pattern is identical to Journey. Replace `PingJourney.OidcModule` with `PingDavinci.OidcModule`. DaVinci does **not** use `serverUrl`, `realm`, or `cookieName`.

`hasSelfAdvancingCollector` types: `SubmitCollector`, `FlowCollector`, `FidoRegistrationCollector`, `FidoAuthenticationCollector`, `DeviceRegistrationCollector`, `DeviceAuthenticationCollector`.

**Critical:** always set `submitCollector.value = submitCollector.id` and `flowCollector.value = flowCollector.id` before calling `next()` — these drive the `actionKey` and `eventType` in the POST body.

For the `AppDaVinci` singleton, full `CollectorNodeView`, individual collector views, `DaVinciAuthenticatedView`, and session lifecycle — read `assets/davinci-collectors.md`.

## 10 — Swift 6 Notes

- Mark ViewModels `@MainActor` — correct isolation for `@Observable` properties.
- Use `Task { }` inside `@MainActor` code to bridge into `async` SDK calls.
- Write `any Callback` / `any Collector` in function signatures — required by Swift 6 existential syntax.
- `Node` is not `Equatable`. Track state transitions via Bool flags, not `.onChange(of: node)`.
- Always add `import Foundation` to `@Observable` classes that use `UserDefaults`.

## 11 — Ping Identity Visual Branding

Read `assets/Theme.swift.template` and write it as-is to `<output-path>/<AppName>/Theme.swift`, substituting `PLACEHOLDER_APP_NAME`. The file contains: color tokens, `PingPrimaryButtonStyle`, `PingHeaderView`, `PingTextField`, `PingSecureField`, `FidoIconView`, `ErrorMessageView`, `LoadingOverlay`, and `ErrorView`.

**Design tokens:**

| Token | Value | Usage |
|---|---|---|
| `Color.pingRed` | `#A31300` (RGB 163, 19, 0) | Primary action buttons, icons, accents |
| `Color.pingRedDark` | RGB 0.6, 0.1, 0.1 | Gradient end color in headers |
| `Color.pingTextField` | RGB 220, 230, 230 | Input field stroke border |
| Button corner radius | 15 pt | Primary action buttons |
| Input corner radius | 8 pt | Text / secure fields |
| Header padding | 32 pt vertical | `PingHeaderView` |
| Standard padding | 24 pt | Content areas |

**Login screen pattern:**
```swift
ZStack {
    ScrollView {
        VStack(spacing: 0) {
            PingHeaderView(title: "My App", subtitle: "Secure authentication")
            VStack(spacing: 24) {
                if let continueNode {
                    ContinueNodeView(node: continueNode, onNext: onNext)
                } else {
                    Button("Sign In", action: onNext).buttonStyle(PingPrimaryButtonStyle())
                }
            }.padding(24)
        }
    }
    if isLoading { LoadingOverlay("Signing in…") }
}
```

**Logo asset:** Copy `Ping Identity Logo.png` from `SampleApps/PingExample/PingExample/Assets.xcassets/Logo.imageset/` into your new app's `Assets.xcassets/Logo.imageset/`. Reference with `Image("Logo")`.

**Settings / Form:** apply `.tint(.pingRed)` to the `Form`.

## 12 — Callback / Collector Tiers

| Tier | Who it's for |
|---|---|
| **Basic** | Login/password journeys with optional multi-choice prompts. Zero extra dependencies. |
| **Standard** | All common patterns — FIDO, Protect, device binding/profile, T&C, KBA, polling wait, consent, social IdP (browser-based). No third-party native social SDKs. |
| **Full fat** | Matches official PingExample sample app. Adds native social login (Apple, Facebook, Google) and ReCaptcha Enterprise. Requires those third-party SDKs. |

**Tier 1 — Basic**

Journey: `NameCallback`, `PasswordCallback`, `TextOutputCallback`, `ChoiceCallback`
DaVinci: `TextCollector`, `PasswordCollector`, `SubmitCollector`, `LabelCollector`, `FlowCollector`

**Tier 2 — Standard**

Everything in Basic plus:

Journey: `TextInputCallback`, `ValidatedUsernameCallback`, `ValidatedPasswordCallback`, attribute callbacks, `ConfirmationCallback`, `SuspendedTextOutputCallback`, `HiddenValueCallback`, `PollingWaitCallback`, `TermsAndConditionsCallback`, `ConsentMappingCallback`, `KbaCreateCallback`, `SelectIdpCallback`, `FidoRegistrationCallback`, `FidoAuthenticationCallback`, `DeviceProfileCallback`, `DeviceBindingCallback`, `DeviceSigningVerifierCallback`, `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback`

DaVinci: `MultiSelectCollector` (CheckBox/ComboBox), `SingleSelectCollector` (Dropdown/RadioButton), `PhoneNumberCollector`, `ProtectCollector`, `FidoRegistrationCollector`, `FidoAuthenticationCollector`, `DeviceRegistrationCollector`, `DeviceAuthenticationCollector`

Additional SPM products: `PingFido`, `PingProtect`, `PingBinding`, `PingDeviceProfile`, `PingExternalIdP`

Self-advancing callbacks (suppress the Next button): `ConfirmationCallback`, `SuspendedTextOutputCallback`, `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback`, `SelectIdpCallback`, `IdpCallback`, `FidoRegistrationCallback`, `FidoAuthenticationCallback`, `DeviceBindingCallback`, `DeviceSigningVerifierCallback`

**Tier 3 — Full fat**

Additional Journey: `IdpCallback`, `ReCaptchaEnterpriseCallback`
Additional DaVinci: `IdpCollector`
Additional SPM: `PingReCaptchaEnterprise`, `PingExternalIdPApple`, `PingExternalIdPFacebook`, `PingExternalIdPGoogle`

**Decision guide:**
```
FIDO / Protect / device binding / T&C / KBA in your journey?
  No  → Basic
  Yes → Native Apple/Google/Facebook social or ReCaptcha?
          No  → Standard
          Yes → Full fat
```

## Common Pitfalls

| Symptom | Likely cause |
|---|---|
| `cannot find type 'Callback' in scope` | Missing `import PingJourneyPlugin` |
| `cannot find type 'Collector' in scope` | Missing `import PingDavinciPlugin` |
| `cannot find type 'ContinueNode' / 'SuccessNode'` | Missing `import PingOrchestrate` |
| `use of protocol 'Callback' as a type must be written 'any Callback'` | Swift 6 existential syntax |
| `cannot use optional chaining on non-optional value of type 'any Error'` | `FailureNode.cause` is non-optional — remove the `?` |
| `'appendInterpolation' is deprecated` on `\(value)` where value is `Any` | Use `String(describing: value)` |
| `result of call to 'signOff()' is unused` | Use `_ = await journey.signOff()` |
| `type 'any Node' cannot conform to 'Equatable'` | Use a Bool flag instead of `.onChange(of: node)` |
| `'Observable()' is only available in iOS 17.0 or newer` | `IPHONEOS_DEPLOYMENT_TARGET = 16.0` in xcconfig — bump to `18.0` |
| `cannot find 'UserDefaults' in scope` inside `@Observable` | Missing `import Foundation` |
| Tokens overwritten between Journey instances | Each needs a unique `account` string on `KeychainStorage<Token>` |
| Social IdP redirect not handled | Missing `onOpenURL` → `OpenURLMonitor.shared.handleOpenURL` |
| Browser opens but redirect never returns | URL scheme not registered — use Ruby snippet in Section 7 / Step D |
| `error: expected to find '=' in macro condition` at xcconfig | Used `INFOPLIST_KEY_CFBundleURLTypes[0]...` syntax — use underscore-numeric form instead |
| `error: Multiple commands produce Info.plist` | Hand-authored `Info.plist` conflicts with `GENERATE_INFOPLIST_FILE = YES` — delete it |
| `authorize()` returns `.failure(.authorizeError)` immediately | `redirectUri` scheme doesn't match registered scheme |
| `ASWebAuthenticationSession` completes but stays on browser | Missing `BrowserLauncher.currentBrowser.handleAppActivation()` on scene-active |
| `cannot find 'OpenURLMonitor' / 'BrowserLauncher' in scope` | Missing `import PingBrowser` |
| `cannot find type 'UITextContentType'` in Theme.swift | Missing `import UIKit` |
| `Unable to find a device matching ... iPhone 16` | Hardcoded simulator name — detect dynamically via `xcrun simctl list devices` (see `assets/project-scaffolding.md` Step G) |
| `Missing package product '<AppName>Feature'` | Cleanup script missed occurrences — run `grep -n <AppName>Feature project.pbxproj` and delete all matches |
| `undefined method 'objects'` in Ruby script | Use `project.objects.each`, not `project.root_object.objects` |
| DaVinci: `actionKey` and `eventType` missing from POST body | `SubmitCollector.value` / `FlowCollector.value` not set before `next()` |
| DaVinci: `ForEach requires Option to conform to Hashable` | Use `ForEach(collector.options.indices, id: \.self)` |
| DaVinci: `PhoneNumberCollector has no member 'value'` | Use `.phoneNumber` not `.value` |
| DaVinci: `ProtectCollector has no member 'start'` | Use `await collector.collect()` not `.start()` |
| DaVinci: `extra argument 'deviceName'` on `FidoRegistrationCollector` | DaVinci variant takes only `window:` — no `deviceName:` |
| DaVinci: `DeviceRegistrationCollector has no member 'register'` | Set `collector.value = device` then call `onNext()` |
| DaVinci: `Device has no member 'name'` | Use `device.title`, not `.name` |
| Journey: `ValidatedUsernameCallback has no member 'value'` | Use `.username` |
| Journey: `ConfirmationCallback has no member 'value'` | Use `.selectedIndex: Int?`; buttons array is `.options` not `.choices` |
| Journey: `TermsAndConditionsCallback has no member 'accept'` | Use `.accepted` |
| Journey: `KbaCreateCallback has no member 'answer'` | Use `.selectedAnswer` |
| Journey: `SelectIdpCallback has no member 'setProvider'` | Assign `.value = provider.provider` directly |
| SPM: `Type checking error: got 'XCSwiftPackageProductDependency' for attribute 'fileRef'` | Use `build_file.product_ref = dep`, not `build_file.file_ref = dep` |
| `FBSOpenApplicationServiceErrorDomain` on test | Simulator in bad state — run `xcrun simctl shutdown all` |

## 13 — Journey Export Analysis

When the user provides a Journey export JSON (exported from the PingOne / AIC Platform UI), run this analysis before writing any code. The goal is to discover every callback the iOS app must handle so the generated sample is an exact match to the server-side Journey.

### Export Format

```
trees/
  <TreeName>/
    tree/
      nodes      — layout + connections map; each entry has nodeType and connections
      staticNodes — Success / Failure terminal nodes
    nodes        — full config; _type._id is the canonical node class name
    scripts      — JS scripts keyed by UUID, referenced by ScriptedDecisionNode
    innerNodes   — (usually empty; inner trees appear as sibling tree entries)
```

Inner trees appear as separate top-level entries in `trees` and are linked via `InnerTreeEvaluatorNode` (its `tree` field names the inner tree). Analyse every tree, not just the entry tree.

### Analysis Steps

**A1 — Enumerate trees.** List every key in `trees`. Identify the entry tree (referenced from `meta` or inferred as the one not referenced by any `InnerTreeEvaluatorNode`). Mark the rest as inner trees.

**A2 — Collect node types.** For every node in each tree's `nodes` object, record `_type._id`. This is the authoritative node class name.

**A3 — Map to SDK callbacks.**

| `_type._id` | SDK callback / notes |
|---|---|
| `UsernameCollectorNode` | `NameCallback` |
| `PasswordCollectorNode` | `PasswordCallback` |
| `DataStoreDecisionNode` | No UI — server-side credential validation |
| `SessionDataNode` | No UI — reads session token into shared state |
| `WebAuthnRegistrationNode` | `FidoRegistrationCallback` |
| `WebAuthnAuthenticationNode` | `FidoAuthenticationCallback` |
| `InnerTreeEvaluatorNode` | No UI — recurse into the named inner tree |
| `ScriptedDecisionNode` | See A4 — may produce callbacks |
| `MessageNode` | Info message + confirm button; use `message.en` text |
| `ChoiceCollectorNode` | `ChoiceCallback` |
| `AttributeCollectorNode` | `StringAttributeInputCallback` / `BooleanAttributeInputCallback` |
| `KbaCreateNode` | `KbaCreateCallback` |
| `TermsAndConditionsNode` | `TermsAndConditionsCallback` |
| `DeviceProfileNode` | `DeviceProfileCallback` |
| `DeviceBindingNode` | `DeviceBindingCallback` |
| `DeviceSigningVerifierNode` | `DeviceSigningVerifierCallback` |
| `PingOneProtectInitializeNode` | `PingOneProtectInitializeCallback` |
| `PingOneProtectEvaluationNode` | `PingOneProtectEvaluationCallback` |
| `SelectIdpNode` | `SelectIdpCallback` |
| `SocialProviderHandlerNode` | `IdpCallback` (Full tier) |
| `PollingWaitNode` | `PollingWaitCallback` |

**A4 — Inspect scripts.** For each `ScriptedDecisionNode`, look up its `script` UUID in `scripts`. The `script` field is a JSON-encoded string — unescape `\"` and `\\n` before reading. In the decoded JavaScript, look for:

- **Callback construction**: `new NameCallback(...)`, `new PasswordCallback(...)`, `new TextOutputCallback(...)`, `new ConfirmationCallback(...)`, etc. These are sent to the device and must be handled by the iOS app exactly like callbacks from a native node. Add them to the callback list.
- **`callbackFactory` / `action.goTo().withCallbacks()` patterns**: extract every callback class name referenced.
- **State reads/writes**: `nodeState.get(...)`, `sharedState.get(...)`, `nodeState.putShared(...)` — note keys downstream nodes depend on (e.g. `displayName`, `userName`, `WebAuthenticationDOMException`).
- **Routing-only scripts**: if the script only reads state and sets `outcome`, mark it "server-side routing, no callbacks" — no iOS UI needed.
- **Error state keys**: scripts writing `WebAuthenticationDOMException` feed an error-handling node; no iOS UI is generated from the write itself.

**A5 — Trace the flow.** Follow `connections` from the entry node through all outcomes (including inner tree `true`/`false`) to the Success and Failure static nodes. Identify which paths lead to authentication vs registration.

**A6 — Determine callback tier.**
- Any of `WebAuthnRegistrationNode`, `WebAuthnAuthenticationNode`, `DeviceBindingNode`, `DeviceSigningVerifierNode`, `PingOneProtectInitializeNode`, `PingOneProtectEvaluationNode` → **Standard** minimum.
- `SocialProviderHandlerNode` or `IdpCallback` → **Full fat**.
- Otherwise → **Basic**.

**A7 — Extract configuration.**
- `journeyName` — entry tree key in `trees`.
- `relyingPartyDomain` (from `WebAuthnRegistrationNode` / `WebAuthnAuthenticationNode`) → hint for `serverUrl`.
- `origins` — FIDO registered bundle IDs and web origins; warn if the target bundle ID is missing.
- `userVerificationRequirement` — if `REQUIRED`, note biometric/PIN is enforced.

**A8 — Report, then generate.** Output a plain-text summary (tree names, node→callback mapping, identified flows, tier, FIDO origins warnings) before writing any Swift. The generated `ContinueNodeView` must handle exactly the callbacks identified — no more, no less.

### Special Cases

**Inner tree as registration fallback.** When `InnerTreeEvaluatorNode` is wired to `failure`/`noDevice` outcomes, the iOS app receives different callback sets on different steps. Distinguish screens by inspecting which callbacks are present in the current `ContinueNode` (e.g. only `FidoAuthenticationCallback` → auth screen; `NameCallback` + `PasswordCallback` → registration form).

**`MessageNode`.** Map to a `TextOutputCallback`-style view showing `message.en` with a single "Continue" button.

**`ScriptedDecisionNode` writing `displayName`.** The `userUUIDtoDisplayName` pattern copies `username` into `displayName` shared state server-side. No iOS UI needed.
