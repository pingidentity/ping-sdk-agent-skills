---
name: ping-orchestration-android-sdk
description: >-
  Guide for building Android apps that integrate with the Ping Orchestration Android SDK
  (also referred to as the Ping Identity Android SDK, formerly the ForgeRock Android SDK
  / forgerock-android-sdk; Gradle artifact: `com.pingidentity.sdks:android`; modules:
  `journey`, `davinci`, `oidc`, `fido`, `protect`, `externalidp`, `binding`, `oath`,
  `push`). Covers both new project scaffolding and adding the SDK to an existing app.
  Use this skill whenever the user is: (1) building any Android app that authenticates
  against PingOne, PingOne Advanced Identity Cloud (AIC), PingAM, or DaVinci using
  Journey, DaVinci, or OIDC flows; (2) configuring SDK modules (Journey, DaVinci, OIDC,
  FIDO/passkeys, Protect, ExternalIdP, OATH, Push, Device Binding); (3) rendering Journey
  callbacks or DaVinci collectors in Jetpack Compose; (4) troubleshooting Ping
  authentication flows in an Android app; (5) setting up token or session storage with
  `EncryptedDataStore`; (6) scaffolding a new Android/Kotlin project for a
  Ping-authenticated app; (7) implementing OIDC centralized login with `OidcWebClient`,
  handling browser redirects, or wiring the redirect URI intent filter for OAuth 2.0
  authorization code flows. Invoke proactively even when the user phrases it loosely —
  "add PingOne login to my Android app", "how do I set up Journey in Android", "how do I
  add OIDC centralized login", "make this look like a Ping sample app", "use the Ping
  Android SDK", "integrate pingidentity sdk on Android", "use forgerock-android-sdk",
  or "migrate from ForgeRock to Ping on Android".
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---

## Skill Parameters

When invoked with no arguments, run the wizard. With arguments, generate inline.

### No-arg Invocation — Wizard Mode

**Step W1 — Determine intent** using `AskUserQuestion`:

```
"What would you like to do?"
Options:
  A) Scaffold a new Android project   — complete Gradle project with Ping SDK wired in
  B) Add to an existing project       — generate only the Kotlin files to drop in
  C) Browse the reference guide       — show the full SDK reference
  D) Something else                   — let me describe what I need
```

- **A/B** → Step W2 to collect config, then generate
- **C** → display the integration guide below. Stop.
- **D** → follow-up free-text question, route accordingly.

**Step W2 — Collect configuration** (A and B only).

Ask all required parameters in a single `AskUserQuestion`. Show defaults where they exist. Do not generate until every required field has a value.

| Parameter | Required | Default | Description |
|---|---|---|---|
| `flowType` | Yes | — | `davinci` · `journey` · `oidc-web` |
| `clientId` | Yes | — | OAuth 2.0 Client ID |
| `discoveryEndpoint` | Yes | — | Full `.well-known/openid-configuration` URL |
| `redirectUri` | Yes | `com.example.myapp:/oauth2redirect` | OAuth 2.0 redirect URI (must match manifest scheme) |
| `scopes` | No | `openid profile email` | Space-separated OAuth 2.0 scopes |
| `serverUrl` | Journey only | — | PingAM/AIC base URL (no trailing `/`) |
| `realm` | Journey only | `alpha` | Authentication realm |
| `cookieName` | Journey only | `iPlanetDirectoryPro` | SSO cookie name |
| `journeyName` | Journey only | `Login` | Journey tree name |
| `callbackTier` | Journey/DaVinci | — | `basic`, `standard`, or `full` (see Section 11) |
| `packageName` | Yes (A only) | — | Android package name, e.g. `com.example.myapp` |
| `outputPath` | Yes (A only) | — | Absolute path for project output |

**Validation rules:**
- `redirectUri` scheme must match `manifestPlaceholders["appRedirectUriScheme"]` in `build.gradle.kts`.
- `discoveryEndpoint` must end with `/.well-known/openid-configuration`.
- `serverUrl` (Journey) must start with `https://` and have no trailing `/`.
- `scopes` must include `openid`. If missing, prepend it and warn.

**Step W3 — Confirm and generate.** Summarise values in a short table, ask "Ready to generate — does this look right?", then proceed.

**Step W4 — Post-generation checklist.** Run through this **before** reporting done:

1. **Maven repository** — `settings.gradle.kts` needs only `google()` + `mavenCentral()`. Do NOT add `maven.forgerock.org` (401) or `maven.pingidentity.com`. SDK 2.0.0+ is on Maven Central.

2. **`gradle.properties`** — must exist at project root:
   ```properties
   android.useAndroidX=true
   android.enableJetifier=true
   org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
   kotlin.code.style=official
   ```
   Missing this = build fails with AndroidX classpath wall.

3. **`gradlew` wrapper** — omit from scaffolded output; tell user to open in Android Studio first.

4. **`ExposedDropdownMenuBox` anchor** — use `Modifier.menuAnchor(MenuAnchorType.PrimaryNotEditable)`, import `androidx.compose.material3.MenuAnchorType`. No-arg overload deprecated in Material3 1.3.x.

5. **Versions baseline** — `agp = "8.9.1"`, `kotlin = "2.1.21"`, `compileSdk = 36`, `targetSdk = 36`. AGP 8.9.1 requires Kotlin 2.1.x (2.0.x → K2 crash `FirIncompatibleClassExpressionChecker`). `androidx.browser:1.9.0` and `androidx.core:1.17.0+` require AGP 8.9.1+ and `compileSdk 36`.

6. **`minSdk` floor** — Journey: `minSdk = 29`. DaVinci/OIDC: `minSdk = 28`.

7. **Ping Identity branding** — always apply. Read `assets/Theme.kt.template`, write to `ui/theme/PingTheme.kt`, substitute `PLACEHOLDER_PACKAGE_NAME`. Copy `assets/ping_logo.png` to `app/src/main/res/drawable/`.

8. **`res/values/themes.xml` parent** — use `Theme.AppCompat.Light.NoActionBar`, NOT `Theme.Material3.DayNight.NoActionBar`. The Material3 XML theme requires the `com.google.android.material` library which is not in the dependency list. `Theme.AppCompat.Light.NoActionBar` is always available transitively via `activity-compose`. Using the wrong parent → AAPT resource linking failure at build time.

9. **App icon — never reference `@mipmap/ic_launcher`** — scaffolded projects have no mipmap directories. In `AndroidManifest.xml` use `@drawable/ping_logo` (already copied in step 7) for both `android:icon` and `android:roundIcon`. Referencing a missing mipmap → AAPT resource linking failure identical to the theme error above.

---

# Ping Orchestration Android SDK — Integration Guide

## Flow Types

**Journey (native)** — Compose UI in-app, callbacks, targets PingOne AIC / PingAM.
**DaVinci** — Like Journey but targets PingOne DaVinci; uses collectors, no `serverUrl`/`realm`/`cookie`.
**OIDC Web** — Browser via Custom Tabs; wire redirect URI intent filter.

## Module Map

| Artifact (`com.pingidentity.sdks:<name>`) | When to add |
|---|---|
| `journey` | Journey flows + all callback types |
| `davinci` | DaVinci flows + all collector types |
| `oidc` | Standalone `OidcWebClient` |
| `external-idp` | Social login (`IdpCollector`, `SelectIdpCallback`) |
| `fido` | FIDO2 / Passkeys |
| `protect` | PingOne Protect risk signals |
| `binding` | Device binding & signing |
| `device-profile` | Device metadata |
| `oath` | TOTP/HOTP — artifact is `oath`, NOT `mfa-oath` |
| `push` | Push MFA — artifact is `push`, NOT `mfa-push` |
| `recaptcha-enterprise` | reCAPTCHA Enterprise |

## 1 — Gradle Dependencies

SDK 2.0.0+ is on Maven Central — no custom repo needed.

```kotlin
// settings.gradle.kts
dependencyResolutionManagement {
    repositories { google(); mavenCentral() }
}
```

```kotlin
// app/build.gradle.kts
android {
    compileSdk = 36
    defaultConfig {
        minSdk = 29
        targetSdk = 36
        manifestPlaceholders["appRedirectUriScheme"] = "com.example.myapp"
    }
    buildFeatures { buildConfig = true }
}

dependencies {
    implementation("com.pingidentity.sdks:journey:2.0.0")   // or :davinci:2.0.0
    implementation("com.pingidentity.sdks:fido:2.0.0")
    implementation("com.pingidentity.sdks:protect:2.0.0")
    implementation("com.pingidentity.sdks:binding:2.0.0")
    implementation("com.pingidentity.sdks:device-profile:2.0.0")
    implementation("com.pingidentity.sdks:external-idp:2.0.0")

    val composeBom = platform("androidx.compose:compose-bom:<bom_version>")
    implementation(composeBom)
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose")
    implementation("androidx.navigation:navigation-compose")
}
```

`gradle/libs.versions.toml` baseline: `agp = "8.9.1"`, `kotlin = "2.1.21"`.

## 2 — AndroidManifest.xml — Redirect URI

```xml
<activity android:name=".MainActivity" ...>
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="${appRedirectUriScheme}" />
    </intent-filter>
</activity>
```

## 3 — Node Types (`com.pingidentity.orchestrate`)

```kotlin
sealed interface Node
// ContinueNode  — more input needed; .next() to advance
// SuccessNode   — authenticated; .session
// ErrorNode     — server error (recoverable); .message: String
// FailureNode   — unexpected error; .cause: Throwable (NON-OPTIONAL)
```

`Node` is not `Equatable` — use `counter: Int` in state to force recomposition.

## 4 — DaVinci Configuration

```kotlin
import com.pingidentity.davinci.DaVinci
import com.pingidentity.davinci.module.Oidc
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD  // top-level extension — explicit import required

val daVinci = DaVinci {
    logger = Logger.STANDARD
    module(Oidc) {
        clientId          = BuildConfig.CLIENT_ID
        discoveryEndpoint = BuildConfig.DISCOVERY_ENDPOINT
        scopes            = mutableSetOf("openid", "profile", "email")
        redirectUri       = BuildConfig.REDIRECT_URI
    }
}

// Start: val node: Node = daVinci.start()          — suspend
// Advance: val next: Node = continueNode.next()    — suspend
// Session: val user = daVinci.user()               — suspend, null if none
// Logout: user?.logout()
// Token: user?.accessToken()  // Result<Token, OidcError>
```

## 5 — Journey Configuration

```kotlin
import com.pingidentity.journey.Journey
import com.pingidentity.journey.module.Oidc
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD     // top-level extension
import com.pingidentity.journey.start       // top-level extension — NOT a Journey member
import com.pingidentity.journey.user        // top-level extension — NOT a Journey member

val journey = Journey {
    logger    = Logger.STANDARD
    serverUrl = BuildConfig.SERVER_URL
    realm     = BuildConfig.REALM
    cookie    = BuildConfig.COOKIE_NAME
    module(Oidc) {
        clientId          = BuildConfig.CLIENT_ID
        discoveryEndpoint = BuildConfig.DISCOVERY_ENDPOINT
        scopes            = mutableSetOf("openid", "profile", "email")
        redirectUri       = BuildConfig.REDIRECT_URI
    }
}

// Start:   val node: Node = journey.start(BuildConfig.JOURNEY_NAME)  — suspend
// Session: val user = journey.user()   — suspend, null if none
// Logout:  user?.logout()
// Token:   user?.token()  // Result<Token, OidcError>
```

**All four symbols below are top-level extensions — unresolved if not imported:**

| Symbol | Import |
|---|---|
| `journey.start(name)` | `import com.pingidentity.journey.start` |
| `journey.user()` | `import com.pingidentity.journey.user` |
| `continueNode.callbacks` | `import com.pingidentity.journey.plugin.callbacks` |
| `Logger.STANDARD` | `import com.pingidentity.logger.STANDARD` |

## 6 — MVVM State & ViewModel

```kotlin
data class AuthState(val node: Node? = null, val counter: Int = 0)

class AuthViewModel : ViewModel() {
    val state = MutableStateFlow(AuthState())
    val loading = MutableStateFlow(false)

    fun start() { viewModelScope.launch {
        loading.value = true
        val node = journey.start(BuildConfig.JOURNEY_NAME)
        state.update { AuthState(node = node, counter = it.counter + 1) }
        loading.value = false
    }}

    fun next(continueNode: ContinueNode) { viewModelScope.launch {
        loading.value = true
        val node = continueNode.next()
        state.update { AuthState(node = node, counter = it.counter + 1) }
        loading.value = false
    }}

    fun refresh() { state.update { it.copy(counter = it.counter + 1) } }

    fun logout(onCompleted: () -> Unit) { viewModelScope.launch {
        journey.user()?.logout()
        state.value = AuthState()
        onCompleted()
    }}
}
```

## 7 — Top-Level Auth Screen

```kotlin
@Composable
fun AuthScreen(viewModel: AuthViewModel, onSuccess: () -> Unit) {
    BackHandler { viewModel.start() }  // restart rather than navigate back
    val state by viewModel.state.collectAsState()
    val loading by viewModel.loading.collectAsState()

    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        when (val node = state.node) {
            is ContinueNode -> CallbackNodeView(node, { viewModel.refresh() }) { viewModel.next(node) }
            is FailureNode  -> PingErrorCard(node.cause.message ?: "Unexpected error") { viewModel.start() }
            is ErrorNode    -> PingErrorCard(node.message) { viewModel.start() }
            is SuccessNode  -> LaunchedEffect(Unit) { onSuccess() }  // LaunchedEffect prevents recomposition loop
            null            -> LaunchedEffect(Unit) { viewModel.start() }
        }
        if (loading) PingLoadingOverlay("Signing in…")
    }
}
```

## 8 — DaVinci: Collector Rendering

```kotlin
@Composable
fun ContinueNodeView(node: ContinueNode, onNodeUpdated: () -> Unit, onNext: (ContinueNode) -> Unit) {
    var hasSubmittable = false
    node.collectors.forEach { collector ->
        when (collector) {
            is TextCollector     -> TextCollectorField(collector, onNodeUpdated)
            is PasswordCollector -> PasswordCollectorField(collector, onNodeUpdated)
            is LabelCollector    -> Text(collector.content, style = MaterialTheme.typography.bodyMedium)
            is SingleSelectCollector -> SingleSelectField(collector, onNodeUpdated)
            is MultiSelectCollector  -> MultiSelectField(collector, onNodeUpdated)
            is PhoneNumberCollector  -> PhoneNumberField(collector, onNodeUpdated)
            is SubmitCollector -> { hasSubmittable = true; SubmitButton(collector) { onNext(node) } }
            is FlowCollector   -> { hasSubmittable = true; FlowButton(collector) { onNext(node) } }
            is DeviceRegistrationCollector   -> { hasSubmittable = true; DeviceRegistrationView(collector) { onNext(node) } }
            is DeviceAuthenticationCollector -> { hasSubmittable = true; DeviceAuthView(collector) { onNext(node) } }
            is FidoRegistrationCollector     -> { hasSubmittable = true; FidoRegistrationView(collector) { onNext(node) } }
            is FidoAuthenticationCollector   -> { hasSubmittable = true; FidoAuthView(collector) { onNext(node) } }
            is ProtectCollector -> ProtectCollectorView(collector) { onNext(node) }
            is IdpCollector     -> IdpButton(collector) { onNext(node) }
        }
    }
    if (!hasSubmittable) { PingPrimaryButton("Next") { onNext(node) } }
}
```

**Key collector properties:**

| Collector | Key properties | Input |
|---|---|---|
| `TextCollector` | `label`, `value`, `required` | `collector.value = text` |
| `PasswordCollector` | `label`, `value` | call `collector.validate(pwd)` first; `collector.value = pwd` |
| `SubmitCollector` / `FlowCollector` | `label` | call `onNext` |
| `LabelCollector` | `content` | display only |
| `SingleSelectCollector` | `label`, `options: List<Option>`, `value: String` | `collector.value = option.value` |
| `MultiSelectCollector` | `label`, `options: List<Option>`, `value: List<String>` | `collector.value = listOf(...)` |
| `PhoneNumberCollector` | `label`, `defaultCountryCode`, `countryCode`, `phoneNumber` | set both fields |
| `DeviceRegistrationCollector` / `DeviceAuthenticationCollector` | `devices: List<Device>` | `collector.value = device` then `onNext` |
| `ProtectCollector` | — | `suspend collector.collect()` then `onNext` |
| `FidoRegistrationCollector` | — | `suspend collector.register()` then `onNext` |
| `FidoAuthenticationCollector` | — | `suspend collector.authenticate()` then `onNext` |
| `IdpCollector` | `label`, `type`, `iconUrl` | `suspend collector.authorize(redirectUri)` |

## 9 — Journey: Callback Rendering

```kotlin
import com.pingidentity.journey.plugin.callbacks  // extension property — required

@Composable
fun CallbackNodeView(node: ContinueNode, onNodeUpdated: () -> Unit, onNext: () -> Unit) {
    var showNext = true
    node.callbacks.forEach { callback ->
        when (callback) {
            is NameCallback            -> NameField(callback, onNodeUpdated)
            is PasswordCallback        -> PasswordField(callback, onNodeUpdated)
            is ValidatedUsernameCallback -> ValidatedUsernameField(callback, onNodeUpdated)
            is ValidatedPasswordCallback -> ValidatedPasswordField(callback, onNodeUpdated)
            is TextInputCallback       -> TextInputField(callback, onNodeUpdated)
            is TextOutputCallback      -> Text(callback.message, style = MaterialTheme.typography.bodyMedium)
            is ChoiceCallback          -> ChoiceField(callback, onNodeUpdated)
            is ConfirmationCallback    -> { showNext = false; ConfirmationButtons(callback, onNext) }
            is TermsAndConditionsCallback -> TermsCheckbox(callback, onNodeUpdated)
            is KbaCreateCallback       -> KbaField(callback, onNodeUpdated)
            is BooleanAttributeInputCallback -> BooleanAttributeField(callback, onNodeUpdated)
            is StringAttributeInputCallback  -> StringAttributeField(callback, onNodeUpdated)
            is PollingWaitCallback     -> { showNext = false; PollingWaitView(callback, onNext) }
            is DeviceProfileCallback   -> { showNext = false; DeviceProfileView(callback, onNext) }
            is DeviceBindingCallback   -> { showNext = false; DeviceBindingView(callback, onNext) }
            is FidoRegistrationCallback   -> { showNext = false; FidoRegistrationView(callback, onNext) }
            is FidoAuthenticationCallback -> { showNext = false; FidoAuthView(callback, onNext) }
            is PingOneProtectInitializeCallback -> { showNext = false; ProtectInitView(callback, onNext) }
            is PingOneProtectEvaluationCallback -> { showNext = false; ProtectEvalView(callback, onNext) }
            is SelectIdpCallback -> { showNext = false; SelectIdpView(callback, onNext) }
        }
    }
    if (showNext) { PingPrimaryButton("Next", onClick = onNext) }
}
```

**Callback reference** (exact names, packages, property names, suspend methods — compile errors if guessed wrong): [references/callback-reference.md](references/callback-reference.md)

Key gotchas: `ValidatedUsernameCallback` → `.username` (not `.value`); `TextInputCallback` → `.text`; `ChoiceCallback` → `.selectedIndex`; `TermsAndConditionsCallback` → `.accepted`; `DeviceProfileCallback.collect()`, `DeviceBindingCallback.bind()`, `PingOneProtectInitializeCallback.start()`.

**Auto-advancing callbacks** — wrap in `LaunchedEffect(callback)`, set `showNext = false`: `PollingWaitCallback`, `DeviceProfileCallback`, `DeviceBindingCallback`, `FidoRegistrationCallback`, `FidoAuthenticationCallback`, `PingOneProtectInitializeCallback`, `PingOneProtectEvaluationCallback`.

## 10 — OIDC Web Flow

```kotlin
import com.pingidentity.oidc.OidcWebClient
import com.pingidentity.oidc.module.Oidc

val webClient = OidcWebClient {
    module(Oidc) {
        clientId = BuildConfig.CLIENT_ID
        discoveryEndpoint = BuildConfig.DISCOVERY_ENDPOINT
        scopes = mutableSetOf("openid", "profile", "email")
        redirectUri = BuildConfig.REDIRECT_URI
    }
}

// In ViewModel:
webClient.authorize()
    .onSuccess { user -> /* authenticated */ }
    .onFailure { error -> /* handle OidcError */ }

val user = webClient.user()  // null if no active session
```

`authorize()` is suspend. Launches Custom Tabs, waits for redirect, exchanges code for tokens.

## 11 — Collector/Callback Tiers

| Tier | Journey additions | DaVinci additions | Extra modules |
|---|---|---|---|
| **Basic** | `NameCallback`, `PasswordCallback`, `TextOutputCallback`, `ChoiceCallback` | `TextCollector`, `PasswordCollector`, `SubmitCollector`, `LabelCollector`, `FlowCollector` | None |
| **Standard** | + validated callbacks, attribute callbacks, `ConfirmationCallback`, `TermsAndConditionsCallback`, `KbaCreateCallback`, `PollingWaitCallback`, all device/FIDO/Protect/SelectIdp callbacks | + `SingleSelectCollector`, `MultiSelectCollector`, `PhoneNumberCollector`, device/FIDO/Protect collectors | `fido`, `protect`, `binding`, `device-profile`, `external-idp` |
| **Full** | + `IdpCallback`, `ReCaptchaEnterpriseCallback` | + `IdpCollector` | + `recaptcha-enterprise` |

```
FIDO / Protect / device binding?  No → Basic
  Yes → Social login or reCAPTCHA?  No → Standard  Yes → Full
```

## 12 — Common Mistakes

See [references/common-mistakes.md](references/common-mistakes.md) — covers import errors, wrong callback property names, suspend method names, recomposition loops, Gradle/AGP version issues, AAPT errors, and branding component pitfalls.

## 13 — MFA Modules

**Push (FCM)** — artifact `com.pingidentity.sdks:push`:
```kotlin
val pushClient = PushClient { }
pushClient.addCredentialFromUri(uri)           // QR scan
pushClient.processNotification(remoteMessage.data)  // FCM
pushClient.approveNotification(notificationId)
```

**OATH (TOTP/HOTP)** — artifact `com.pingidentity.sdks:oath`:
```kotlin
val oathClient = OathClient { }
oathClient.addCredentialFromUri(otpauthUri)
val code = oathClient.generateCode(credentialId)
```

**Protect (standalone)**:
```kotlin
Protect.config { isBehavioralDataCollection = true; envId = "api.pingone.com" }
Protect.init()
```

## 14 — ForgeRock → Ping Migration

| Legacy | Ping SDK |
|---|---|
| `org.forgerock:forgerock-auth` | `com.pingidentity.sdks:journey` |
| `FRAuth.start()` | `journey.start("Login")` |
| `FRUser.getCurrentUser()` | `journey.user()` / `daVinci.user()` |
| `Node.getCallbacks()` | `continueNode.callbacks` |

For a full guided migration, read the `forgerock-to-ping-journey-migration` skill.

## 15 — Ping Identity Visual Branding

Write `assets/Theme.kt.template` to `ui/theme/PingTheme.kt` (substitute `PLACEHOLDER_PACKAGE_NAME`). Copy `assets/ping_logo.png` → `app/src/main/res/drawable/ping_logo.png`.

Branded components: `PingPrimaryButton`, `PingHeaderView`, `PingTextFieldBranded` (name avoids clash with `PingTextField` color constant), `PingSecureField`, `PingErrorMessage`, `PingErrorCard`, `PingLoadingOverlay` (must be top sibling in `Box(Modifier.fillMaxSize())`).

Login screen: `Box(fillMaxSize)` wrapping a `Column(verticalScroll)` with `PingHeaderView` at the top, `CallbackNodeView`/`CollectorNodeView` below, and `PingLoadingOverlay` overlaid when loading. Apply `PingRed` tint to `Checkbox`/`Switch`.
