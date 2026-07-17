---
name: ping-orchestration-ios-sdk
description: >-
  Guide for building iOS apps that integrate with the Ping Orchestration iOS SDK
  (also referred to as the Ping Identity iOS SDK, formerly the ForgeRock iOS SDK
  / forgerock-ios-sdk; Swift Package: `Ping/ping-ios-sdk`; modules: `PingJourney`,
  `PingDavinci`, `PingOidc`, `PingExternalIdP`, `PingProtect`, `PingOath`, `PingLogger`,
  `PingStorage`). Use this skill whenever the user is: (1) building any iOS app that
  authenticates against PingOne, PingOne Advanced Identity Cloud (AIC), PingAM, or
  DaVinci using Journey, DaVinci, or OIDC flows; (2) configuring modules (Journey,
  DaVinci, OIDC, FIDO/passkeys, Protect, ExternalIdP, OATH, Push); (3) rendering
  Journey callbacks or DaVinci collectors in SwiftUI; (4) troubleshooting Ping
  authentication flows in an iOS app; (5) setting up token or session storage with
  `KeychainStorage`; (6) scaffolding a new Xcode project for a Ping-authenticated
  app; (7) applying Ping Identity branding to a sample app; (8) implementing OIDC
  centralized login with `OidcWebClient`, configuring `ASWebAuthenticationSession`
  or `SFSafariViewController`, handling browser redirects, or wiring `onOpenURL`
  for OAuth 2.0 authorization code flows; (9) analysing a PingAM/AIC Journey export
  JSON to identify required callbacks and generate a matching iOS sample. Invoke
  proactively even when the user phrases it loosely — "add PingOne login to my
  iOS app", "how do I set up Journey in Swift", "add OIDC centralized login",
  "make this look like a Ping sample app", "use the Ping iOS SDK", "use the
  PingSDK in my iPhone app", "integrate ping-ios-sdk", or pastes / attaches a
  Journey export JSON.
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
compatibility:
  mcp:
    - xcodebuildmcp  # required for Xcode project scaffolding (see assets/project-scaffolding.md)
---

## Skill Parameters

This skill accepts an optional argument string when invoked as `/ping-orchestration-ios-sdk <args>`.

### No-arg Invocation — Wizard Mode

When invoked with **no arguments** (`/ping-orchestration-ios-sdk`), run the wizard:

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

**Step W1b — Manifest / Journey export check** (options A and B only).

First, silently check for `.ping/journey-manifest.*.json` in the working directory. If found:
- Load the manifest. Pre-populate `journeyName`, `serverUrl`, `realm`, `cookieName` (from `sessionCookieName`), and `callbackTier` (from `recommendedCallbackTier`) without asking.
- Skip the journey export offer below and proceed directly to Step W2.

If no manifest is found, ask:
> "Do you have a Journey export JSON file? If so, paste it or attach it and I'll analyse it to generate a sample that handles exactly the callbacks your Journey uses."

- If provided: run Section 13 (Journey Export Analysis) before Step W2. Pre-populate `journeyName`, `callbackTier`, and `serverUrl` from the analysis results.
- If not: continue to Step W2 as normal.

**Step W2 — Collect configuration** (required for A and B).

First determine `flowType` if not already known, then ask only the parameters relevant to that flow in a single `AskUserQuestion` call. Show defaults where they exist. Do not proceed until every required field has a value.

**Common parameters (all flows):**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `appName` | Yes | — | App name used for Swift types, `PingHeaderView` title, and bundle ID. E.g. `PingDemo` |
| `outputPath` | Yes (option A only) | — | Directory to write the Xcode project (absolute path) |
| `flowType` | Yes | — | `oidc-web` · `journey` · `davinci` |
| `clientId` | Yes | — | OAuth 2.0 Client ID |
| `redirectUri` | Yes | — | OAuth 2.0 redirect URI (custom scheme, e.g. `myapp://callback`) |
| `discoveryEndpoint` | Yes | — | Full OIDC discovery URL ending in `/.well-known/openid-configuration` |
| `scopes` | No | `openid profile email` | OAuth 2.0 scopes, space-separated |

**Journey-only additional parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `serverUrl` | Yes | — | PingAM/AIC server base URL (no trailing `/`) |
| `realm` | No | `alpha` | Authentication realm |
| `cookieName` | No | `iPlanetDirectoryPro` | Session cookie name — **tenant-specific**; confirm from AIC Native Console → Access Management → `<realm>` → Authentication → Settings → Core → Cookie Name, or read from the Journey Node Manifest's `sessionCookieName` field |
| `journeyName` | No | `Login` | Journey tree name |
| `callbackTier` | Yes | — | `basic`, `standard`, or `full` (see Section 12) |

**DaVinci-only additional parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `callbackTier` | Yes | — | `basic`, `standard`, or `full` (see Section 12) |
| `acrValues` | No | _(none)_ | Optional ACR values string — omit entirely if not provided |

**OIDC Web-only additional parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `acrValues` | No | _(none)_ | Optional ACR values string — omit entirely if not provided |

Present `callbackTier` options (Journey and DaVinci only):
- **Basic** — `NameCallback`, `PasswordCallback`, `TextOutputCallback`, `ChoiceCallback` (Journey) / `TextCollector`, `PasswordCollector`, `SubmitCollector`, `LabelCollector`, `FlowCollector` (DaVinci). Minimal dependencies.
- **Standard** — Everything in Basic plus: attribute callbacks, FIDO, Protect, Device Binding/Profile, SelectIdp, T&C, KBA, PollingWait, ConsentMapping. No third-party social SDKs.
- **Full fat** — Everything in Standard plus `IdpCallback`/`IdpCollector`/`SocialCollectorView` (social login) and `ReCaptchaEnterpriseCallback`. Requires Facebook, Google, and ReCaptcha Enterprise SPM dependencies.

**Validation rules:**
- `redirectUri` must use a custom scheme (not `http://` or `https://`).
- `discoveryEndpoint` must start with `https://` and end with `/.well-known/openid-configuration`. If the user provides a base AM URL, construct `<serverUrl>/oauth2/<realm>/.well-known/openid-configuration` and confirm.
- `scopes` must include `openid`. If missing, prepend it and warn.
- `serverUrl` (Journey only) must start with `https://` and have no trailing `/`.

**Step W3 — Confirm and generate.** Summarise collected values in a short table, ask "Ready to generate — does this look right?", then proceed on confirmation.

---

### Parameters (with-args invocation)

| Parameter | Syntax | Purpose |
|---|---|---|
| `create-sample` | `create-sample "<description>"` | Generate a complete runnable sample app |
| `app-name` | `app-name "<name>"` | Set the app name. Defaults to `"MyApp"` if omitted. |
| `output-path` | `output-path "<path>"` | Write files to disk. If omitted, print inline. |
| `--manifest` | `--manifest "<path>"` | Path to a Journey Node Manifest JSON (`.ping/journey-manifest.<Name>.json`). When provided, `callbackUnion` and per-node `emitsCallbacks` in the manifest drive callback/collector view generation — overrides tier inference. |

### `create-sample "<description>"`

1. **Analyse** the description — identify flow type(s), modules, and implied screens.
2. **Journey manifest check** — if the flow type is `journey` (or could be) and no `--manifest` arg was given:
   - Look for `.ping/journey-manifest.*.json` in the working directory.
   - If found, load it. Use `callbackUnion` as the authoritative callback list. Set `callbackTier` from `recommendedCallbackTier`, `cookieName` from `sessionCookieName`, `serverUrl` and `realm` from the manifest. Do **not** infer callbacks from node type names.
   - If not found, continue and emit a warning after collecting parameters: *"No Journey Node Manifest found — callback generation is tier-based, not ground truth. Run `/ping-orchestration` to produce a manifest for an exact match."*
3. **Journey export offer** — if the flow type is `journey`, no manifest was loaded, and the user has not provided an export, ask:
   > "Do you have a Journey export JSON? I can analyse it and tailor the sample to exactly the callbacks your Journey uses."
   If provided, run Section 13 before proceeding. Use its output to determine `callbackTier` and screens.
4. **Ask one clarifying question** only if the flow type is genuinely ambiguous. Collect required parameters for the detected flow type (see W2 table) in a single `AskUserQuestion` with an explicit "I can use placeholders" option.
5. **Resolve the app name** from `app-name` or use `"MyApp"`.
6. **Generate** using the template files in `assets/`. Substitute all `PLACEHOLDER_*` tokens (see table below). Use `@Observable @MainActor` ViewModels — never `ObservableObject`/`@Published`. Apply Ping Identity branding (Section 11).

   **OIDC Web flow** — read and substitute:
   `App.swift.oidc.template`, `AppOidc.swift.template`, `OidcLoginViewModel.swift.template`, `ContentView.swift.oidc.template`, `LoginView.swift.oidc.template`, `AuthenticatedView.swift.oidc.template`, `Theme.swift.template`

   **Journey flow** — read and substitute:
   `App.swift.journey.template`, `AppJourney.swift.template`, `JourneyLoginViewModel.swift.template`, `ContentView.swift.journey.template`, `LoginView.swift.journey.template`, `AuthenticatedView.swift.journey.template`, `ContinueNodeView.swift.journey.template`, `Theme.swift.template`

   Then, for each callback in `callbackTier`, read and substitute the matching file from `assets/callbacks/`:
   - **Basic:** `NameCallbackView`, `PasswordCallbackView`, `ChoiceCallbackView`, `TextOutputCallbackView`
   - **Standard:** everything in Basic plus `TextInputCallbackView`, `ValidatedUsernameCallbackView`, `ValidatedPasswordCallbackView`, `StringAttributeInputCallbackView`, `NumberAttributeInputCallbackView`, `BooleanAttributeInputCallbackView`, `ConfirmationCallbackView`, `TermsAndConditionsCallbackView`, `KbaCreateCallbackView`, `ConsentMappingCallbackView`, `PollingWaitCallbackView`, `SelectIdpCallbackView`, `FidoRegistrationCallbackView`, `FidoAuthenticationCallbackView`, `DeviceProfileCallbackView`, `DeviceBindingCallbackView`, `DeviceSigningVerifierCallbackView`, `PingOneProtectInitializeCallbackView`, `PingOneProtectEvaluationCallbackView`
   - **Full fat:** everything in Standard plus `IdpCallbackView`, `ReCaptchaEnterpriseCallbackView`

   In `ContinueNodeView.swift.journey.template`, replace `// PLACEHOLDER_CALLBACK_CASES` with the appropriate `switch` cases for the tier, and replace `// PLACEHOLDER_TIER_IMPORTS` with the matching import statements. Replace `// PLACEHOLDER_SELF_ADVANCING_TYPES` with the self-advancing types for the tier.

   **DaVinci flow** — read and substitute:
   `App.swift.davinci.template`, `AppDaVinci.swift.template`, `DaVinciLoginViewModel.swift.template`, `ContentView.swift.davinci.template`, `LoginView.swift.davinci.template`, `AuthenticatedView.swift.davinci.template`, `CollectorNodeView.swift.davinci.template`, `Theme.swift.template`

   Then, for each collector in `callbackTier`, read and substitute the matching file from `assets/collectors/`:
   - **Basic:** `TextCollectorView`, `PasswordCollectorView`, `SubmitCollectorView`, `LabelCollectorView`, `FlowCollectorView`
   - **Standard:** everything in Basic plus `MultiSelectCheckBoxView`, `MultiSelectComboBoxView`, `SingleSelectDropdownView`, `SingleSelectRadioView`, `PhoneNumberCollectorView`, `ProtectCollectorView`, `FidoRegistrationCollectorView`, `FidoAuthenticationCollectorView`, `DeviceRegistrationCollectorView`, `DeviceAuthenticationCollectorView`
   - **Full fat:** everything in Standard plus `SocialCollectorView`

   In `CollectorNodeView.swift.davinci.template`, replace `// PLACEHOLDER_COLLECTOR_CASES` with the appropriate `switch` cases for the tier, and replace `// PLACEHOLDER_TIER_IMPORTS` and `// PLACEHOLDER_SELF_ADVANCING_TYPES` accordingly.

7. **Deliver:**
   - With `output-path`: read `assets/project-scaffolding.md` and follow Steps 0–G exactly. For SPM products per flow type, see Step C in that document.
   - Without `output-path`: print every file inline with a `// --- <Filename>.swift ---` header.

### Template Placeholders

| Placeholder | Replaces with |
|---|---|
| `PLACEHOLDER_APP_NAME` | Resolved app name (e.g. `PingDemo`) |
| `PLACEHOLDER_APP_NAME_UPPER` | Upper-cased app name (e.g. `PINGDEMO`) — used in Keychain account key construction |
| `PLACEHOLDER_CLIENT_ID` | `clientId` value |
| `PLACEHOLDER_REDIRECT_URI` | `redirectUri` value |
| `PLACEHOLDER_DISCOVERY_ENDPOINT` | `discoveryEndpoint` value |
| `PLACEHOLDER_SCOPES` | Scopes as comma-separated quoted strings for `Set([...])` (e.g. `"openid", "profile", "email"`) |
| `PLACEHOLDER_SERVER_URL` | `serverUrl` (Journey/DaVinci only) |
| `PLACEHOLDER_REALM` | `realm` (Journey/DaVinci only) |
| `PLACEHOLDER_COOKIE_NAME` | `cookieName` (Journey/DaVinci only) |
| `PLACEHOLDER_JOURNEY_NAME` | `journeyName` (Journey only, default `"Login"`) |
| `PLACEHOLDER_ACR_VALUES_LINE` | DaVinci/OIDC: entire `oidcConfig.acrValues = "..."` line — omit the line entirely if not provided |
| `PLACEHOLDER_KEYCHAIN_ACCOUNT` | Keychain account key — use `"<APP_NAME_UPPER>_ACCESS_TOKEN"` pattern (e.g. `"PINGDEMO_ACCESS_TOKEN"`) |

When the user chose placeholder mode: use `"yourClientId"`, `"yourapp://callback"`, `"https://your-tenant.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration"`.

### Automated Project Creation (when `output-path` is provided)

Read `assets/project-scaffolding.md` and follow Steps 0–G exactly. Key reminders:
- Use deployment target `18.0`.
- Layout is **flat** — `.xcodeproj`, source dir, and `Config/` are siblings directly under `<output-path>/`.
- `PBXFileSystemSynchronizedRootGroup` means Swift files dropped in the source dir are included automatically.
- Use `project.objects.each` (not `project.root_object.objects`) to iterate all project objects in Ruby scripts.

**Examples:**
```
/ping-orchestration-ios-sdk create-sample "a simple username/password login using Journey"
/ping-orchestration-ios-sdk create-sample "OIDC centralized login with token display and sign-out" app-name "PingDemo" output-path "/Users/me/Dev"
/ping-orchestration-ios-sdk create-sample "Journey login with FIDO passkey registration and biometric auth" app-name "FidoSample"
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

Journey callback properties are **non-optional Strings**. Do not use `?? fallback`. Basic-tier properties: `NameCallback.name/prompt`, `PasswordCallback.password/prompt`, `TextInputCallback.text/prompt`, `ChoiceCallback.selectedIndex/choices`, `TextOutputCallback.message/messageType`.

**Standard-tier gotchas** (compile errors if guessed wrong): `ValidatedUsernameCallback` → `.username` (NOT `.value`); `ValidatedPasswordCallback` → `.password`; `ConfirmationCallback` → `.options`/`.selectedIndex: Int?`; `TermsAndConditionsCallback` → `.accepted: Bool`; `KbaCreateCallback` → `.selectedQuestion`/`.selectedAnswer`; `SelectIdpCallback` → `.value = provider.provider` (no `.setProvider()`).

Read `references/journey-callbacks.md` for the complete Critical API Facts section before writing any Standard-tier callback view.

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

For multi-flow apps (Journey + DaVinci + OIDC Web) and token storage customisation, see `references/advanced-patterns.md`.

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

`Callback` lives in `PingJourneyPlugin` — import it alongside `PingOrchestrate`. Use `any Callback` in function signatures (Swift 6 existential syntax). Suppress the Next button when `hasSelfAdvancingCallback` (FIDO, Confirmation, Protect, SelectIdp, DeviceBinding callbacks advance themselves).

Use `assets/ContinueNodeView.swift.journey.template` as the full implementation reference. **Always read `references/journey-callbacks.md`** before writing any callback view code.

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

For the `AppOidc` singleton, `OidcWebClientConfig` API, `OidcError` cases, `BrowserType` trade-offs, `OidcLoginViewModel`, and branded `OidcLoginView` — read `references/oidc-web-reference.md`.

## 9 — DaVinci Flow

DaVinci uses **collectors** instead of callbacks. The `@Observable` ViewModel pattern is identical to Journey. Replace `PingJourney.OidcModule` with `PingDavinci.OidcModule`. DaVinci does **not** use `serverUrl`, `realm`, or `cookieName`.

`hasSelfAdvancingCollector` types: `SubmitCollector`, `FlowCollector`, `FidoRegistrationCollector`, `FidoAuthenticationCollector`, `DeviceRegistrationCollector`, `DeviceAuthenticationCollector`.

**Critical:** always set `submitCollector.value = submitCollector.id` and `flowCollector.value = flowCollector.id` before calling `next()` — these drive the `actionKey` and `eventType` in the POST body.

For the `AppDaVinci` singleton, full `CollectorNodeView`, individual collector views, `DaVinciAuthenticatedView`, and session lifecycle — read `references/davinci-collectors.md`.

## 10 — Swift 6 Notes

- Mark ViewModels `@MainActor` — correct isolation for `@Observable` properties.
- Use `Task { }` inside `@MainActor` code to bridge into `async` SDK calls.
- Write `any Callback` / `any Collector` in function signatures — required by Swift 6 existential syntax.
- `Node` is not `Equatable`. Track state transitions via Bool flags, not `.onChange(of: node)`.
- Always add `import Foundation` to `@Observable` classes that use `UserDefaults`.

## 11 — Ping Identity Visual Branding

Write `assets/Theme.swift.template` as-is to `<AppName>/Theme.swift` (substitute `PLACEHOLDER_APP_NAME`). Contains: `PingPrimaryButtonStyle`, `PingHeaderView`, `PingTextField`, `PingSecureField`, `FidoIconView`, `ErrorMessageView`, `LoadingOverlay`, `ErrorView`. Key tokens: `Color.pingRed` = `#A31300`, corner radius 15pt (buttons) / 8pt (fields), header padding 32pt, content padding 24pt.

Copy `assets/Logo.imageset/` into `Assets.xcassets/Logo.imageset/` and reference with `Image("Logo")`. Apply `.tint(.pingRed)` to any `Form`.

## 12 — Callback / Collector Tiers

Full tier breakdown with decision guide: [references/callback-tiers.md](references/callback-tiers.md)

**Summary:** Basic (username/password/choice, no extra SPM) → Standard (adds FIDO, Protect, device binding, T&C, KBA, social IdP browser-based) → Full fat (adds native Apple/Google/Facebook social + ReCaptcha Enterprise). The wizard's `callbackTier` parameter maps directly to these tiers.

## Common Pitfalls

See [references/common-pitfalls.md](references/common-pitfalls.md) — covers Swift 6 errors, OIDC redirect issues, DaVinci collector gotchas, SPM build errors, and simulator problems.

## 13 — Journey Export Analysis

When the user provides a Journey export JSON, run the full analysis in [references/journey-export-analysis.md](references/journey-export-analysis.md) before writing any code (steps A1–A8: enumerate trees, map nodes→callbacks, inspect scripts, determine tier, extract config).
