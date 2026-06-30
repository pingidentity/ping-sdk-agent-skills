# ping-orchestration-react-native-sdk

A Claude Code skill for scaffolding and integrating React Native apps with the [Ping Identity React Native SDK](https://docs.pingidentity.com/sdks/latest/pingoneaidpsdks/get_started_react_native_sdk.html) (PingOne AIC / PingAM).

---

## What it does

When invoked, the skill either:

- **Scaffolds a complete React Native project** — all config, navigation, Ping-branded components, and callback views wired together and ready to run, or
- **Generates the integration files** to drop into an existing project, or
- **Acts as a reference guide** for SDK configuration, callbacks, and common mistakes.

It covers two flow types:

| Flow | Use case |
|---|---|
| **Journey** | Native in-app UI with callbacks, targeting PingOne AIC or PingAM |
| **OIDC Web** | Browser-based login via system browser / in-app browser |

---

## How to invoke

### Without arguments — wizard mode

```
/ping-orchestration-react-native-sdk
```

The skill asks four questions in sequence:

1. **Intent** — scaffold new project, add to existing, or browse the reference guide
2. **Flow type** — Journey or OIDC Web
3. **Callback handling** (Journey only) — Managed (`useJourneyForm`) or Manual (`useJourney`)
4. **Callback tier** (Journey only) — Basic, Standard, or Full
5. **Configuration** — app name, clientId, discoveryEndpoint, redirectUri, serverUrl, realm, cookieName, journey name, output path
6. **Confirmation** — shows a summary table before generating

### With arguments — inline generation

```
/ping-orchestration-react-native-sdk create-sample "username/password login using Journey"
/ping-orchestration-react-native-sdk create-sample "OIDC web login" app-name "PingDemo"
```

---

## Callback tiers

When building a Journey app, you pick a tier that controls which callback views are generated and which packages are installed.

| Tier | Callbacks included | Extra packages |
|---|---|---|
| **Basic** | `NameCallback`, `PasswordCallback`, `ValidatedCreateUsernameCallback`, `ValidatedCreatePasswordCallback`, `TextInputCallback`, `StringAttributeInputCallback`, `NumberAttributeInputCallback`, `BooleanAttributeInputCallback`, `TextOutputCallback`, `SuspendedTextOutputCallback`, `ChoiceCallback`, `ConfirmationCallback`, `TermsAndConditionsCallback`, `ConsentMappingCallback`, `KbaCreateCallback`, `PollingWaitCallback` | None beyond `rn-journey` |
| **Standard** | Basic + `FidoRegistrationCallback`, `FidoAuthenticationCallback`, `DeviceBindingCallback`, `DeviceSigningVerifierCallback`, `DeviceProfileCallback` | `rn-fido`, `rn-binding`, `rn-device-profile` |
| **Full** | Standard + `SelectIdpCallback` / `SelectIdPCallback` | `rn-external-idp` |

Unrecognised callbacks render an `UnsupportedCallbackView` warning card rather than silently failing.

---

## Callback handling modes

| Mode | How it works |
|---|---|
| **Managed** (`useJourneyForm`) | Form state, validation, and payload assembly handled by the SDK. Simpler code; less boilerplate. Recommended. |
| **Manual** (`useJourney`) | You control field state and build the submit payload yourself. More flexibility; more code. |

---

## SDK packages

| Package | Purpose |
|---|---|
| `@ping-identity/rn-core` | Required peer dependency |
| `@ping-identity/rn-journey` | Journey flows, `useJourney`, `useJourneyForm` |
| `@ping-identity/rn-fido` | FIDO2 / Passkeys |
| `@ping-identity/rn-binding` | Device binding & signing verifier |
| `@ping-identity/rn-device-profile` | Device metadata collection |
| `@ping-identity/rn-external-idp` | Social / external identity providers |
| `@ping-identity/rn-oidc` | OIDC web flow |
| `@ping-identity/rn-push` | Push notification authentication |
| `@ping-identity/rn-logger` | Logging |
| `@ping-identity/rn-storage` | Credential/token storage |

Minimum requirements: **React Native ≥ 0.80.1**, **iOS 16.0**, **Android minSdk 29**.

---

## Generated project structure

```
<AppName>/
├── App.tsx                          # Navigation container + providers
├── src/
│   ├── <AppName>JourneyClient.ts    # createJourneyClient singleton
│   ├── OidcClient.ts                # createOidcWebClient (OIDC flow)
│   ├── theme/
│   │   └── PingTheme.tsx            # Ping branding — colors, buttons, inputs
│   ├── assets/
│   │   └── ping_logo.png
│   ├── screens/
│   │   ├── LoginScreen.tsx
│   │   ├── HomeScreen.tsx
│   │   └── CallbackRenderer.tsx     # Routes callbacks to their views
│   └── callbacks/
│       ├── NameCallbackView.tsx
│       ├── PasswordCallbackView.tsx
│       ├── TextOutputCallbackView.tsx
│       ├── PollingWaitCallbackView.tsx
│       ├── SelectIdpCallbackView.tsx  (Full tier)
│       ├── UnsupportedCallbackView.tsx
│       └── ... (one file per callback type)
```

---

## Common mistakes (quick reference)

| Mistake | Fix |
|---|---|
| `createJourneyClient()` inside a component | Create at module scope — recreating loses session state |
| `createOidcWebClient()` inside a component | Use `useMemo` at App level or module scope |
| Importing from `@ping-identity/rn-device-binding` | Package doesn't exist — use `@ping-identity/rn-binding` |
| Importing from `@ping-identity/rn-fido2` | Package doesn't exist — use `@ping-identity/rn-fido` |
| `useJourney()` outside `JourneyProvider` with no client arg | Pass client directly or wrap tree with `<JourneyProvider>` |
| OIDC redirect never returns on Android | Add `manifestPlaceholders = [appRedirectUriScheme: "yourscheme"]` to `build.gradle` `defaultConfig` |
| `PollingWaitCallback` shown as static text | SDK correctly classifies it as `output_only`; `CallbackRenderer` intercepts by type to run the timer |

Full list in `references/common-mistakes.md`.

---

## Reference files

| File | Contents |
|---|---|
| `references/callbacks.md` | Full callback type reference with input shapes by tier |
| `references/journey-client.md` | `createJourneyClient` config, `useJourney` / `useJourneyForm` API |
| `references/oidc-client.md` | `createOidcWebClient` config, `useOidc` API |
| `references/common-mistakes.md` | RN-specific gotchas and fixes |
| `references/oath.md` | OATH / TOTP MFA with `@ping-identity/rn-oath` |

---

## After generation

1. Replace placeholder config values (`<serverUrl>`, `<clientId>`, etc.) in the generated client file.
2. For **OIDC on Android**: confirm `appRedirectUriScheme` in `android/app/build.gradle` matches your redirect URI scheme.
3. For **FIDO / Passkeys**: register your app's origin / associated domain in the PingOne AIC console.
4. For **Device Binding**: ensure the AIC journey has a Device Binding node with biometric authentication type.
5. For **Push Notifications**: add `google-services.json` (Android) and configure APNs (iOS) — see `src/push/` templates.
6. Run `pod install` in `ios/` after `npm install`.
