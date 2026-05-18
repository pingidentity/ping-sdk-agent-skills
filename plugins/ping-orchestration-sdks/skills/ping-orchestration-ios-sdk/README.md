# ping-orchestration-ios-sdk Skill

A Claude Code skill for building iOS apps that integrate with the **Ping Identity SDK (PingSDK)**. Covers new app scaffolding, SDK integration into existing projects, Journey export analysis, and the full reference guide.

---

## When it triggers

The skill activates automatically when you:

- Ask how to add PingOne, PingAM/AIC, DaVinci, Journey, or OIDC login to an iOS app
- Ask how to configure any PingSDK module (Journey, DaVinci, OIDC, FIDO, Protect, ExternalIdP, OATH, Push)
- Ask how to render Journey callbacks or DaVinci collectors in SwiftUI
- Troubleshoot authentication flows in a PingSDK-based iOS app
- Ask about token/session storage with `KeychainStorage`
- Scaffold a new Xcode project for a PingSDK app
- Apply Ping Identity branding to a sample app
- Set up OIDC centralized login (`OidcWebClient`, `ASWebAuthenticationSession`, `SFSafariViewController`, `onOpenURL`)
- Paste or attach a Journey export JSON for analysis

---

## How to invoke

### Wizard mode — `/ping-orchestration-ios-sdk`

No arguments starts an interactive wizard:

1. **Choose intent** — build a new sample app, integrate into an existing project, browse the reference guide, or describe something else.
2. **Journey export offer** — optionally paste a Journey export JSON; the skill analyses it and pre-populates your config.
3. **Collect configuration** — app name, flow type, OAuth credentials, server details, callback tier.
4. **Confirm and generate** — review a summary table, then the skill writes all files.

### Quick sample — `/ping-orchestration-ios-sdk create-sample "<description>"`

Describe what you want in plain English and the skill generates a complete, runnable sample.

```
/ping-orchestration-ios-sdk create-sample "username/password login using Journey"
/ping-orchestration-ios-sdk create-sample "OIDC centralized login with token display" app-name "PingDemo" output-path "/Users/me/Dev"
/ping-orchestration-ios-sdk create-sample "Journey login with FIDO passkey registration" app-name "FidoSample"
```

Optional parameters:

| Parameter | Syntax | Purpose |
|---|---|---|
| `app-name` | `app-name "MyApp"` | Swift type name, bundle ID, and header title |
| `output-path` | `output-path "/path/to/dir"` | Write an Xcode project to disk; omit to print inline |

---

## Flow types

| Flow | Description | Browser? |
|---|---|---|
| `journey` | Native/embedded UI — callbacks rendered in SwiftUI | No |
| `davinci` | Like Journey but uses collectors | No (unless social IdP) |
| `oidc-web` | Centralized login via `SFSafariViewController` / `ASWebAuthenticationSession` | Yes |

---

## Callback / Collector tiers

When building a Journey or DaVinci app, you pick a tier that determines which callbacks are supported and which SPM packages are added.

| Tier | Callbacks included | Extra dependencies |
|---|---|---|
| **Basic** | Username, password, text output, choice | None |
| **Standard** | Basic + FIDO, Protect, device binding/profile, T&C, KBA, polling wait, consent, SelectIdp | `PingFido`, `PingProtect`, `PingBinding`, `PingDeviceProfile`, `PingExternalIdP` |
| **Full fat** | Standard + native social login (Apple, Google, Facebook), ReCaptcha Enterprise | Third-party social SDKs + `PingReCaptchaEnterprise` |

If you provide a Journey export JSON, the skill determines the correct tier automatically.

---

## Journey export analysis

Paste or attach a Journey export JSON (exported from the PingOne / AIC Platform UI) and the skill:

1. Enumerates all trees (entry tree + inner trees linked via `InnerTreeEvaluatorNode`)
2. Maps every node type to its SDK callback — including callbacks constructed inside `ScriptedDecisionNode` scripts
3. Decodes and inspects JavaScript scripts for `new NameCallback(...)`, `callbackFactory` patterns, and shared-state dependencies
4. Traces the authentication flow through all connection paths to identify auth vs registration branches
5. Determines the correct callback tier
6. Extracts `journeyName`, FIDO `origins`, `relyingPartyDomain`, and `userVerificationRequirement`
7. Reports a plain-text summary before generating any Swift

The generated `ContinueNodeView` handles exactly the callbacks found in the export — no more, no less.

---

## Generated project structure

When `output-path` is provided, the skill creates a flat Xcode project:

```
<output-path>/
├── <AppName>.xcodeproj/
├── <AppName>/               ← Swift sources (auto-included via PBXFileSystemSynchronizedRootGroup)
│   ├── App.swift
│   ├── ContentView.swift
│   ├── LoginView.swift
│   ├── AuthenticatedView.swift
│   ├── AppJourney.swift      ← (Journey) or AppOidc.swift / AppDaVinci.swift
│   ├── LoginViewModel.swift
│   └── Theme.swift
└── Config/
    └── <AppName>.xcconfig
```

- Deployment target: **iOS 18.0**
- ViewModels: `@Observable @MainActor` (never `ObservableObject` / `@Published`)
- Branding: Ping Identity red (`#A31300`), gradient header, `PingPrimaryButtonStyle`

---

## Asset files

The skill loads these on demand — they are not in context by default:

| File | Contents |
|---|---|
| `assets/project-scaffolding.md` | Step-by-step Xcode project creation (Steps 0–G) |
| `assets/journey-callbacks.md` | Complete SwiftUI implementations for all Journey callbacks |
| `assets/davinci-collectors.md` | Full `CollectorNodeView`, all collector views, DaVinci session lifecycle |
| `assets/oidc-web-reference.md` | `AppOidc` singleton, `OidcWebClientConfig` API, `BrowserType` trade-offs, `OidcLoginViewModel` |
| `assets/Theme.swift.template` | Ping Identity branding — color tokens, button styles, header, text fields |
| `assets/advanced-patterns.md` | `ConfigurationManager` for multi-flow apps, Keychain storage customisation |

---

## Key SDK facts

- Import `PingOrchestrate` in every file that pattern-matches on `Node` types
- Import `PingJourneyPlugin` in every file that uses `any Callback`
- Import `PingDavinciPlugin` in every file that uses `any Collector`
- `FailureNode.cause` is **non-optional** — never use `?.localizedDescription`
- `Node` is **not `Equatable`** — track state via Bool flags, not `.onChange(of: node)`
- `SubmitCollector.value` and `FlowCollector.value` **must be set** before calling `next()`
- Journey/DaVinci native flows do **not** need `onOpenURL`; OIDC Web and social IdP flows do

---

## Common pitfalls (quick reference)

| Error | Fix |
|---|---|
| `cannot find type 'Callback' in scope` | Add `import PingJourneyPlugin` |
| `cannot find type 'Collector' in scope` | Add `import PingDavinciPlugin` |
| `'Observable()' is only available in iOS 17.0 or newer` | Set `IPHONEOS_DEPLOYMENT_TARGET = 18.0` |
| `Multiple commands produce Info.plist` | Delete hand-authored `Info.plist`; use Ruby URL-scheme snippet instead |
| Browser redirect never returns | URL scheme not registered — use Ruby snippet in project scaffolding Step D |
| DaVinci: `actionKey` missing from POST | Set `submitCollector.value = submitCollector.id` before `next()` |

Full pitfalls list is in the skill's **Common Pitfalls** section.
