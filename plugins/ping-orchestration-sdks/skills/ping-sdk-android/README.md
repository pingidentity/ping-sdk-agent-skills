# ping-sdk-android

A Claude Code skill for scaffolding and integrating Android apps with the [Ping Orchestration Android SDK](https://docs.pingidentity.com/sdks/latest/pingoneaidpsdks/get_started_android_sdk.html) (PingOne AIC / PingAM / DaVinci).

---

## What it does

When invoked, the skill either:

- **Scaffolds a complete Android project** from scratch — all Gradle files, Kotlin sources, Compose UI, and Ping branding wired together and ready to open in Android Studio, or
- **Generates the Kotlin integration files** to drop into an existing project, or
- **Acts as a reference guide** for SDK configuration, callbacks, collectors, and common mistakes.

It covers three flow types:

| Flow | Use case |
|---|---|
| **Journey** | Native in-app UI with callbacks, targeting PingOne AIC or PingAM |
| **DaVinci** | Native in-app UI with collectors, targeting PingOne DaVinci |
| **OIDC Web** | Browser-based login via Custom Tabs / redirect URI |

---

## How to invoke

### With arguments — inline generation

Pass your configuration directly as the command argument:

```
/ping-sdk-android create a sample app at /path/to/MyApp with clientId "myClient",
discoveryEndpoint "https://...", serverUrl "https://...", realm "alpha",
cookieName "abc123", redirectUri "myapp://callback", scopes openid email address,
I want Login + Registration + Passkeys + Device Binding
```

The skill reads your configuration, infers the callback tier (Basic / Standard / Full), generates all files, and reports what was created.

### Without arguments — wizard mode

```
/ping-sdk-android
```

The skill asks four questions in sequence:

1. **Intent** — scaffold new project, add to existing, or browse the reference guide
2. **Configuration** — clientId, discoveryEndpoint, redirectUri, serverUrl, realm, cookieName, scopes, journey names, package name, output path
3. **Confirmation** — shows a summary table before generating
4. **Post-generation checklist** — verifies Maven repos, `gradle.properties`, versions, icon references, and theme before reporting done

---

## What gets generated (scaffold mode)

```
MyApp/
├── settings.gradle.kts          # google() + mavenCentral() only
├── build.gradle.kts
├── gradle.properties            # AndroidX, Jetifier, JVM args
├── gradle/
│   └── libs.versions.toml       # AGP 8.9.1, Kotlin 2.1.21, SDK 2.0.0
└── app/
    ├── build.gradle.kts         # compileSdk 36, minSdk 29, buildConfigFields
    ├── src/main/
    │   ├── AndroidManifest.xml  # redirect URI intent-filter, @drawable/ping_logo icon
    │   ├── res/
    │   │   ├── drawable/ping_logo.png
    │   │   ├── values/strings.xml
    │   │   └── values/themes.xml   # Theme.AppCompat.Light.NoActionBar
    │   └── kotlin/.../
    │       ├── MainActivity.kt      # NavHost with Landing → Login/Register → Home → Profile
    │       ├── auth/
    │       │   ├── JourneyInstance.kt   # singleton Journey client
    │       │   ├── AuthViewModel.kt     # startLogin / startRegistration / next / logout
    │       │   ├── LandingScreen.kt
    │       │   ├── AuthScreen.kt
    │       │   ├── HomeScreen.kt
    │       │   ├── ProfileViewModel.kt  # calls user.userinfo()
    │       │   └── ProfileScreen.kt     # displays all returned claims
    │       ├── callbacks/
    │       │   ├── BasicCallbacks.kt        # Name, Password, ValidatedUsername/Password, Choice, TextOutput
    │       │   ├── RegistrationCallbacks.kt # StringAttribute, BooleanAttribute, TermsAndConditions
    │       │   ├── DeviceCallbacks.kt       # DeviceProfile, DeviceBinding, FidoRegistration, FidoAuthentication
    │       │   └── CallbackNodeView.kt      # routes all callbacks to their composables
    │       └── ui/theme/
    │           └── PingTheme.kt     # PingRed, PingHeaderView, PingPrimaryButton, PingSecureField, etc.
```

---

## Supported callbacks & collectors

### Journey callbacks

| Tier | Callbacks |
|---|---|
| Basic | `NameCallback`, `PasswordCallback`, `TextOutputCallback`, `ChoiceCallback` |
| Standard | + `ValidatedUsernameCallback`, `ValidatedPasswordCallback`, `StringAttributeInputCallback`, `BooleanAttributeInputCallback`, `TermsAndConditionsCallback`, `ConfirmationCallback`, `KbaCreateCallback`, `PollingWaitCallback`, `DeviceProfileCallback`, `DeviceBindingCallback`, `FidoRegistrationCallback`, `FidoAuthenticationCallback`, `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback`, `SelectIdpCallback` |
| Full | + `IdpCallback`, `ReCaptchaEnterpriseCallback` |

### DaVinci collectors

`TextCollector`, `PasswordCollector`, `SubmitCollector`, `FlowCollector`, `LabelCollector`, `SingleSelectCollector`, `MultiSelectCollector`, `PhoneNumberCollector`, `DeviceRegistrationCollector`, `DeviceAuthenticationCollector`, `FidoRegistrationCollector`, `FidoAuthenticationCollector`, `ProtectCollector`, `IdpCollector`

---

## SDK modules included

| Module | Purpose |
|---|---|
| `com.pingidentity.sdks:journey` | Journey flows |
| `com.pingidentity.sdks:davinci` | DaVinci flows |
| `com.pingidentity.sdks:fido` | FIDO2 / Passkeys |
| `com.pingidentity.sdks:binding` | Device binding & signing |
| `com.pingidentity.sdks:device-profile` | Device metadata |
| `com.pingidentity.sdks:protect` | PingOne Protect risk signals |
| `com.pingidentity.sdks:external-idp` | Social login |
| `com.pingidentity.sdks:oidc` | Standalone OIDC web flow |

All artifacts are on Maven Central (SDK 2.0.0+). No custom repository required.

---

## Known build gotchas the skill avoids

| Issue | What the skill does |
|---|---|
| `Theme.Material3.DayNight.NoActionBar` not found (AAPT) | Uses `Theme.AppCompat.Light.NoActionBar` — available without an extra library |
| `mipmap/ic_launcher` not found (AAPT) | Uses `@drawable/ping_logo` instead — no mipmap directories needed |
| K2 compiler crash (`FirIncompatibleClassExpressionChecker`) | Pins `kotlin = "2.1.21"` — Kotlin 2.0.x is incompatible with AGP 8.9.1 |
| HTTP 401 on SDK artifacts | Only `google()` + `mavenCentral()` in repositories — no Ping/ForgeRock Maven URL |
| `journey.start()` / `.user()` unresolved | Explicit top-level extension imports added to every file that needs them |
| `menuAnchor()` deprecation | Uses `Modifier.menuAnchor(MenuAnchorType.PrimaryNotEditable)` |
| `PingTextField` name clash | Color constant named `PingTextField`, composable named `PingTextFieldBranded` |

---

## After generation

1. Open the project folder in **Android Studio** — it generates the Gradle wrapper (`gradlew`) automatically on first import.
2. Adjust `JOURNEY_LOGIN` and `JOURNEY_REGISTRATION` in `app/build.gradle.kts` if your AIC journey tree names differ.
3. For Device Binding: ensure your AIC journey has a Device Binding node with `Authentication Type = Biometric`.
4. For Passkeys (FIDO): ensure your AIC journey has a WebAuthn Registration / Authentication node and your app's SHA-256 fingerprint is registered.
