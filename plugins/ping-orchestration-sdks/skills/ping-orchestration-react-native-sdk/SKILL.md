---
name: ping-orchestration-react-native-sdk
description: >-
  Guide for building React Native apps that integrate with the Ping Identity
  React Native SDK (npm scope: `@ping-identity`; packages: `@ping-identity/rn-journey`,
  `@ping-identity/rn-oidc`, `@ping-identity/rn-fido`, `@ping-identity/rn-push`,
  `@ping-identity/rn-oath`, `@ping-identity/rn-binding`, `@ping-identity/rn-device-client`,
  `@ping-identity/rn-device-profile`, `@ping-identity/rn-external-idp`,
  `@ping-identity/rn-core`). Use this skill whenever the user is: (1) building any
  React Native app that authenticates against PingOne, PingOne Advanced Identity Cloud
  (AIC), or PingAM using Journey or OIDC flows; (2) rendering Journey callbacks
  (NameCallback, PasswordCallback, FIDO, DeviceBinding, etc.) in React Native
  components; (3) configuring `createJourneyClient` or `createOidcClient`; (4) using
  `useJourney`, `useJourneyForm`, `JourneyProvider`, `useOidc`, or `OidcProvider`;
  (5) handling node types (ContinueNode, SuccessNode, FailureNode, ErrorNode); (6)
  wiring OIDC browser redirect URIs for iOS and Android; (7) adding FIDO passkey
  registration or authentication to a Journey flow; (8) scaffolding a new React
  Native project for a Ping-authenticated app. Invoke proactively even when the user
  phrases it loosely — "add PingOne login to my React Native app", "how do I set up
  Journey in RN", "add OIDC login to my RN app", "use the Ping RN SDK", "integrate
  ping-identity in React Native".
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
  A) Scaffold a new React Native project  — complete working app with Ping SDK wired in
  B) Add to an existing app               — generate only the files to drop into your project
  C) Browse the reference guide           — show the full SDK reference
  D) Something else                       — let me describe what I need
```

- **A/B** → Step W1b
- **C** → display the integration guide from "Ping SDK for React Native — Integration Guide" onward. Stop.
- **D** → follow-up free-text question, route accordingly.

**Step W1b — Journey export offer** (options A and B only).

Ask: "Do you have a Journey export JSON? If so, paste it and I'll analyse it to identify the exact callbacks your Journey uses and pre-populate the callback tier."

- If provided: run Section 7 (Journey Export Analysis, [references/journey-export-analysis.md](references/journey-export-analysis.md)) before Step W2. Pre-populate `journeyName` and `callbackTier` from the analysis. Ask Step W2.5 (callback mode) as usual — `callbackMode` cannot be inferred from the export and must still be asked.
- If not provided: continue to Step W2 as normal.

**Step W2 — Flow type** using `AskUserQuestion`:

```
"Which authentication flow do you need?"
Options:
  1) Journey        — native in-app UI, targets PingAM / PingOne AIC
  2) OIDC Web       — browser-based login, any OIDC provider
  3) Journey + OIDC — both flows in one app, FlowPicker as the entry screen
```

- **1** → store `flowType = 'journey'`
- **2** → store `flowType = 'oidc'`
- **3** → store `flowType = 'both'`; collect parameters for both Journey and OIDC in W3; ask W2.5 and W2.6 as normal for the Journey portion; generate both sets of screens plus `FlowPicker`; install combined package set (Journey full tier + `rn-oidc`)

**Step W2.5 — Callback handling** (Journey only, skip when `flowType = 'oidc'`) using `AskUserQuestion`:

```
"How would you like to handle Journey callbacks?"
Options:
  A) Managed (Recommended) — useJourneyForm handles field state, validation,
     and payload building. Simpler code; less boilerplate.
  B) Manual                 — useJourney only. You control field state and
     build the submit payload yourself. More flexibility, more code.
```

Store the answer as `callbackMode` (`managed` or `manual`). Used in step 4 to pick the correct `CallbackRenderer` template.

**Step W2.6 — Callback tier** (Journey only) using `AskUserQuestion`:

```
"Which callbacks does your Journey use?"
Options:
  A) Basic     — username, password, text, choice, T&C, KBA.
                 No extra packages needed beyond rn-journey.
  B) Standard  — Basic + FIDO passkeys, device binding, device profile.
                 Adds: rn-fido, rn-binding, rn-device-profile.
  C) Full      — Standard + social / external IdP (Google, Apple, Facebook).
                 Adds: rn-external-idp.
```

Store the answer as `callbackTier` (`basic`, `standard`, or `full`). Used in steps 4 and 5 to pick the correct templates and install commands.

**Step W3 — Collect configuration.**

Ask all required parameters in a single `AskUserQuestion`. Show defaults where they exist. Do not generate until every required field has a value.

**Common parameters (both flows):**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `appName` | Scaffold only | `PingDemo` | App name. **Only ask when intent is A (scaffold)**. For intent B (add to existing), skip this — use `PingDemo` as default and never prompt for it. |
| `clientId` | Yes | — | OAuth 2.0 Client ID |
| `redirectUri` | Yes | — | OAuth 2.0 redirect URI (custom scheme, e.g. `com.example.app://callback`) |
| `discoveryEndpoint` | Yes | — | Full `.well-known/openid-configuration` URL |
| `scopes` | No | `openid profile email` | Space-separated OAuth 2.0 scopes |

**Journey-only additional parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `serverUrl` | Yes | — | PingAM/AIC base URL, no trailing `/` |
| `realm` | No | `alpha` | Authentication realm |
| `cookieName` | No | `iPlanetDirectoryPro` | Session cookie name |
| `journeyName` | No | `Login` | Journey tree name |

**Validation rules:**
- `redirectUri` must use a custom scheme (not `http://` or `https://`).
- `discoveryEndpoint` must start with `https://` and end with `/.well-known/openid-configuration`.
- `scopes` must include `openid`. If missing, prepend it and warn.
- `serverUrl` (Journey) must start with `https://` and have no trailing `/`.

**Step W3.5 — Output path.** Ask where to write the files using `AskUserQuestion`:

```
"Where should the files be written?"
Options:
  A) Current working directory  — write files to the project root
  B) Specify a path             — I'll provide an absolute or relative path
  C) Print to chat only         — show the code inline, don't write to disk
```

- **A** → use the current working directory as `outputDir`.
- **B** → follow-up free-text question: "Enter the output directory path:". Use that value as `outputDir`.
- **C** → set `outputDir = null` (inline output only).

> **Scaffold intent note:** When intent is **A (Scaffold a new project)** and `outputDir` is set, the React Native project will be initialised as `<outputDir>/<appName>/`. All Ping SDK files are written into that subdirectory. The final structure is `<outputDir>/<appName>/` containing the generated project.

**Step W4 — Confirm and generate.** Summarise collected values (including output path) in a short table, ask "Ready to generate — does this look right?", then proceed on confirmation.

**If intent is A (Scaffold a new project) and `outputDir` is set:**

1. Run the React Native scaffold command first using the Bash tool:
   ```bash
   npx @react-native-community/cli@latest init <AppName> --directory <outputDir>/<AppName>
   ```
   Wait for it to complete before writing any files. If it fails, report the error and stop.

2. Set `projectDir = <outputDir>/<AppName>`.

3. **Apply Ping Identity branding and copy templates** — always do this before writing any screen files.

   - Read `assets/PingTheme.tsx.template` from this skill and write it to `<projectDir>/src/theme/PingTheme.tsx` (no substitutions needed).
   - Copy `assets/ping_logo.png` from this skill to `<projectDir>/src/assets/ping_logo.png`.
   - Create the directory `<projectDir>/src/callbacks/`.

   All generated screens import branded components from `../theme/PingTheme` — never inline ad-hoc styles.

   Branded components available: `PingPrimaryButton`, `PingHeaderView`, `PingTextField`, `PingSecureField`, `PingErrorMessage`, `PingErrorCard`, `PingLoadingOverlay`. Color tokens: `PingColors.red`, `PingColors.redDark`, `PingColors.textField`, etc.

4. **Write screens and callbacks from templates** — read each template from this skill's `assets/` directory and write it to the project. Do not generate these files from memory; always read the template first.

   **Callback components — Basic tier** (all tiers write these):
   - `assets/callbacks/NameCallbackView.tsx.template` → `src/callbacks/NameCallbackView.tsx`
   - `assets/callbacks/ValidatedUsernameCallbackView.tsx.template` → `src/callbacks/ValidatedUsernameCallbackView.tsx`
   - `assets/callbacks/PasswordCallbackView.tsx.template` → `src/callbacks/PasswordCallbackView.tsx`
   - `assets/callbacks/ValidatedPasswordCallbackView.tsx.template` → `src/callbacks/ValidatedPasswordCallbackView.tsx`
   - `assets/callbacks/TextInputCallbackView.tsx.template` → `src/callbacks/TextInputCallbackView.tsx`
   - `assets/callbacks/StringAttributeInputCallbackView.tsx.template` → `src/callbacks/StringAttributeInputCallbackView.tsx`
   - `assets/callbacks/NumberAttributeInputCallbackView.tsx.template` → `src/callbacks/NumberAttributeInputCallbackView.tsx`
   - `assets/callbacks/BooleanAttributeInputCallbackView.tsx.template` → `src/callbacks/BooleanAttributeInputCallbackView.tsx`
   - `assets/callbacks/TextOutputCallbackView.tsx.template` → `src/callbacks/TextOutputCallbackView.tsx`
   - `assets/callbacks/SuspendedTextOutputCallbackView.tsx.template` → `src/callbacks/SuspendedTextOutputCallbackView.tsx`
   - `assets/callbacks/ChoiceCallbackView.tsx.template` → `src/callbacks/ChoiceCallbackView.tsx`
   - `assets/callbacks/ConfirmationCallbackView.tsx.template` → `src/callbacks/ConfirmationCallbackView.tsx`
   - `assets/callbacks/TermsAndConditionsCallbackView.tsx.template` → `src/callbacks/TermsAndConditionsCallbackView.tsx`
   - `assets/callbacks/KbaCreateCallbackView.tsx.template` → `src/callbacks/KbaCreateCallbackView.tsx`
   - `assets/callbacks/PollingWaitCallbackView.tsx.template` → `src/callbacks/PollingWaitCallbackView.tsx`

   **Callback components — Standard tier** (write these when `callbackTier = standard` or `full`):
   - `assets/callbacks/ConsentMappingCallbackView.tsx.template` → `src/callbacks/ConsentMappingCallbackView.tsx`
   - `assets/callbacks/FidoRegistrationCallbackView.tsx.template` → `src/callbacks/FidoRegistrationCallbackView.tsx`
   - `assets/callbacks/FidoAuthenticationCallbackView.tsx.template` → `src/callbacks/FidoAuthenticationCallbackView.tsx`
   - `assets/callbacks/DeviceBindingCallbackView.tsx.template` → `src/callbacks/DeviceBindingCallbackView.tsx`
   - `assets/callbacks/DeviceSigningVerifierCallbackView.tsx.template` → `src/callbacks/DeviceSigningVerifierCallbackView.tsx`
   - `assets/callbacks/DeviceProfileCallbackView.tsx.template` → `src/callbacks/DeviceProfileCallbackView.tsx`

   **Callback components — Full tier** (write these when `callbackTier = full`):
   - `assets/callbacks/SelectIdpCallbackView.tsx.template` → `src/callbacks/SelectIdpCallbackView.tsx`

   **Screen files** (Journey flow) — pick template based on `callbackMode` + `callbackTier`:

   | `callbackMode` | `callbackTier` | Template to use |
   |---|---|---|
   | managed | basic | `assets/CallbackRenderer.form.basic.tsx.template` |
   | managed | standard | `assets/CallbackRenderer.form.standard.tsx.template` |
   | managed | full | `assets/CallbackRenderer.form.tsx.template` |
   | manual | basic | `assets/CallbackRenderer.basic.tsx.template` |
   | manual | standard | `assets/CallbackRenderer.standard.tsx.template` |
   | manual | full | `assets/CallbackRenderer.tsx.template` |

   Write the chosen template to `<projectDir>/src/screens/CallbackRenderer.tsx`.

   - Read `assets/LoginScreen.tsx.template` → write to `<projectDir>/src/screens/LoginScreen.tsx`
   - Read `assets/HomeScreen.tsx.template` → write to `<projectDir>/src/screens/HomeScreen.tsx`

   **Screen files** (OIDC flow):
   - Read `assets/LoginScreen.oidc.tsx.template` → write to `<projectDir>/src/screens/LoginScreen.tsx`
   - Read `assets/HomeScreen.oidc.tsx.template` → write to `<projectDir>/src/screens/HomeScreen.tsx`

   After writing templates, substitute `<AppName>` placeholders in `LoginScreen.tsx` and `HomeScreen.tsx` with the actual app name.

   **These files are still generated** (they contain user-supplied config values):
   - `<projectDir>/src/<AppName>JourneyClient.ts` (or `OidcClient.ts` for OIDC)

5. Overwrite `<projectDir>/App.tsx` with a React Navigation stack. **All Ping providers must wrap the single `NavigationContainer`** — never use multiple `NavigationContainer` instances or nest providers inside screen components. A single flat stack gives every screen a back button automatically.

   **Journey flow:**
   ```tsx
   import React from 'react';
   import { NavigationContainer, useNavigation } from '@react-navigation/native';
   import { createNativeStackNavigator } from '@react-navigation/native-stack';
   import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
   import { JourneyProvider } from '@ping-identity/rn-journey';
   import journeyClient from './<AppName>JourneyClient';
   import LoginScreen from './screens/LoginScreen';
   import HomeScreen from './screens/HomeScreen';

   export type RootStackParamList = {
     Login: undefined;
     Home: undefined;
   };

   const Stack = createNativeStackNavigator<RootStackParamList>();

   export default function App() {
     return (
       <JourneyProvider client={journeyClient}>
         <NavigationContainer>
           <Stack.Navigator initialRouteName="Login">
             <Stack.Screen name="Login" component={LoginScreen} options={{ headerShown: false }} />
             <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'Profile' }} />
           </Stack.Navigator>
         </NavigationContainer>
       </JourneyProvider>
     );
   }
   ```

   **OIDC flow:**
   ```tsx
   import React, { useMemo } from 'react';
   import { NavigationContainer } from '@react-navigation/native';
   import { createNativeStackNavigator } from '@react-navigation/native-stack';
   import { OidcProvider, createOidcClient, createOidcWebClient } from '@ping-identity/rn-oidc';
   import LoginScreen from './screens/LoginScreen';
   import HomeScreen from './screens/HomeScreen';

   export type RootStackParamList = {
     Login: undefined;
     Home: undefined;
   };

   const Stack = createNativeStackNavigator<RootStackParamList>();

   export default function App() {
     const client = useMemo(() => {
       const oidcClient = createOidcClient({
         clientId: '<clientId>',
         discoveryEndpoint: '<discoveryEndpoint>',
         redirectUri: '<redirectUri>',
         scopes: ['openid', 'profile', 'email'],
       });
       return createOidcWebClient(oidcClient);
     }, []);

     return (
       <OidcProvider client={client}>
         <NavigationContainer>
           <Stack.Navigator initialRouteName="Login">
             <Stack.Screen name="Login" component={LoginScreen} options={{ headerShown: false }} />
             <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'Profile' }} />
           </Stack.Navigator>
         </NavigationContainer>
       </OidcProvider>
     );
   }
   ```

   **Both flows (flow picker):** When scaffolding both Journey and OIDC, use a single stack with a `FlowPicker` screen as the initial route. Both providers sit above the single `NavigationContainer`. The `OidcProvider` client is created in `useMemo` at the `App` level — never inside a screen component.

   ```tsx
   export type RootStackParamList = {
     FlowPicker: undefined;
     JourneyLogin: undefined;
     JourneyHome: undefined;
     OidcLogin: undefined;
     OidcHome: undefined;
   };

   export default function App() {
     const oidcClient = useMemo(() => createOidcWebClient(createOidcClient({...})), []);
     return (
       <JourneyProvider client={journeyClient}>
         <OidcProvider client={oidcClient}>
           <NavigationContainer>
             <Stack.Navigator initialRouteName="FlowPicker">
               <Stack.Screen name="FlowPicker" component={FlowPicker} options={{ headerShown: false }} />
               <Stack.Screen name="JourneyLogin" component={LoginScreen} options={{ title: 'Sign In' }} />
               <Stack.Screen name="JourneyHome" component={HomeScreen} options={{ title: 'Profile' }} />
               <Stack.Screen name="OidcLogin" component={OidcLoginScreen} options={{ title: 'Sign In' }} />
               <Stack.Screen name="OidcHome" component={OidcHomeScreen} options={{ title: 'Profile' }} />
             </Stack.Navigator>
           </NavigationContainer>
         </OidcProvider>
       </JourneyProvider>
     );
   }
   ```

   Screens navigate via `useNavigation<NativeStackNavigationProp<RootStackParamList>>()`. After successful login call `navigation.replace('Home')` (or `'JourneyHome'`/`'OidcHome'`). After logout call `navigation.replace('Login')`. Use `replace` — not `navigate` — so the back button cannot return to the auth screen after login or to the home screen after logout.

   All screens use `useJourney()` / `useOidc()` with no client argument — they read from the provider above the navigator.

5. Run the Ping SDK and navigation install command using the Bash tool:
   ```bash
   # Journey — Basic tier (rn-core is a required peer dep)
   cd <projectDir> && npm install @ping-identity/rn-core@1.0.0 @ping-identity/rn-journey@1.0.0 @react-navigation/native @react-navigation/native-stack react-native-screens react-native-safe-area-context

   # Journey — Standard tier (adds FIDO, binding, device profile)
   cd <projectDir> && npm install @ping-identity/rn-core@1.0.0 @ping-identity/rn-journey@1.0.0 @ping-identity/rn-fido@1.0.0 @ping-identity/rn-binding@1.0.0 @ping-identity/rn-device-profile@1.0.0 @react-navigation/native @react-navigation/native-stack react-native-screens react-native-safe-area-context

   # Journey — Full tier (adds external IdP, logger, storage, device-id, oath on top of Standard)
   cd <projectDir> && npm install @ping-identity/rn-core@1.0.0 @ping-identity/rn-journey@1.0.0 @ping-identity/rn-fido@1.0.0 @ping-identity/rn-binding@1.0.0 @ping-identity/rn-device-profile@1.0.0 @ping-identity/rn-external-idp@1.0.0 @ping-identity/rn-logger@1.0.0 @ping-identity/rn-storage@1.0.0 @ping-identity/rn-device-id@1.0.0 @ping-identity/rn-oath@1.0.0 @react-navigation/native @react-navigation/native-stack react-native-screens react-native-safe-area-context

   # OIDC flow
   cd <projectDir> && npm install @ping-identity/rn-core@1.0.0 @ping-identity/rn-oidc@1.0.0 @react-navigation/native @react-navigation/native-stack react-native-screens react-native-safe-area-context
   ```
   The Ping SDK requires React Native >= 0.80.1. Apply these platform minimums before running pod install / gradle:

   **iOS** — requires iOS 16.0. In `ios/Podfile` ensure:
   ```
   platform :ios, '16.0'
   ```

   **Android** — requires minSdk 29. In `android/build.gradle` ensure:
   ```
   minSdkVersion = 29
   ```
   **Android (OIDC flow only)** — `rn-oidc` injects `${appRedirectUriScheme}` into its `AndroidManifest.xml`. Add a placeholder in `android/app/build.gradle` inside `defaultConfig`:
   ```groovy
   manifestPlaceholders = [appRedirectUriScheme: "<redirectUri-scheme>"]
   ```
   where `<redirectUri-scheme>` is the scheme portion of your `redirectUri` (e.g. `com.example.app` for `com.example.app://oauth2redirect`). Without this the build fails with "no value for &lt;appRedirectUriScheme&gt; is provided".

   **iOS (OIDC flow only)** — register the redirect URI scheme in `ios/<AppName>/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string><redirectUri-scheme></string>
       </array>
     </dict>
   </array>
   ```

   **Android (`rn-device-profile` only)** — the network collector requires `ACCESS_NETWORK_STATE`. Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   ```
   Optional: add `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` if using the location collector.

   Then run `pod install`:
   ```bash
   cd <projectDir>/ios && pod install
   ```

6. Ask the user which platform(s) to launch using `AskUserQuestion`:
   ```
   "Launch the app now?"
   Options:
     A) iOS    — run on booted iOS simulator
     B) Android — run on booted Android emulator / connected device
     C) Both   — launch iOS and Android
     D) Skip   — I'll run it manually
   ```

7. For each selected platform, start Metro in the background first (if not already running), then run the app:

   **iOS:**
   ```bash
   # Start Metro in background
   cd <projectDir> && npx react-native start --reset-cache &
   # Wait ~5s for Metro to be ready, then build and install
   cd <projectDir> && npx react-native run-ios --no-packager
   ```

   **Android** (requires a booted emulator or connected device — check with `adb devices` first):
   ```bash
   cd <projectDir> && npx react-native run-android --no-packager
   ```

   After launching, take a simulator/emulator screenshot and show it to the user to confirm the app is running. The expected first screen is either a loading spinner (Journey starting) or an error view with "Try again" (placeholder server URL — correct behaviour).

8. Report what was scaffolded with a summary of next steps (fill in placeholders, register redirect URI scheme in AndroidManifest.xml and Info.plist).

**If intent is B (Add to existing app) or `outputDir` is null:**

1. Write files to `outputDir` using the Write tool when `outputDir` is set; otherwise print inline. Do **not** run `npx react-native init` or any scaffold command.

2. Run the install command for the chosen flow and tier using the Bash tool (same commands as intent A step 5, but `cd` to `outputDir` instead of a new scaffold directory). If `outputDir` is null, print the install command for the user to run.

3. For OIDC or Journey+OIDC flows, remind the user to add the redirect URI scheme native wiring (Android `manifestPlaceholders` + intent filter, iOS `CFBundleURLTypes`) as documented in the platform setup section above.

4. Ask the user which platform(s) to launch (same options as intent A step 6: iOS / Android / Both / Skip).

5. For each selected platform, run the app using the same commands as intent A step 7. If `outputDir` is null, print the run commands instead.

6. Report what was generated with a summary of remaining next steps.

---

### Parameters (with-args invocation)

| Parameter | Syntax | Purpose |
|---|---|---|
| `create-sample` | `create-sample "<description>"` | Generate a complete runnable sample for the described flow |
| `flow` | `flow journey`, `flow oidc`, or `flow both` | Set the flow type explicitly |
| `app-name` | `app-name "<name>"` | Set the app name. Defaults to `"PingDemo"` if omitted. |

### `create-sample "<description>"`

1. **Analyse** the description — identify flow type (`journey` or `oidc`).
2. **Ask one clarifying question** only if the flow type is genuinely ambiguous. Otherwise collect required parameters for the detected flow (see W3 table) in a single `AskUserQuestion` with an explicit "I can use placeholders" option.
3. **Resolve the app name** from `app-name` or use `"PingDemo"`.
4. **Generate** — produce the following files inline (or to disk if an output path is given), substituting all placeholder values:

   **Journey flow:**
   - `<AppName>JourneyClient.ts` — `createJourneyClient` singleton
   - `<AppName>LoginScreen.tsx` — `useJourney` screen with node switch
   - `CallbackRenderer.tsx` — `node.callbacks` renderer for the detected callback set
   - `HomeScreen.tsx` — authenticated screen showing userinfo

   **OIDC Web flow:**
   - `<AppName>OidcClient.ts` — `createOidcClient` + `createOidcWebClient` singletons
   - `<AppName>LoginScreen.tsx` — `useOidc` screen with `restore()` on mount and `authorize()` on press
   - `HomeScreen.tsx` — authenticated screen with token display and sign-out

5. **Print each file** with a `// --- <Filename> ---` header. Include `package.json` dependency snippets and native wiring notes (redirect URI for both platforms).

**Examples:**

```
/ping-orchestration-react-native-sdk create-sample "username and password login using Journey"
/ping-orchestration-react-native-sdk create-sample "OIDC browser login with sign-out" app-name "MyApp"
/ping-orchestration-react-native-sdk create-sample "Journey login with FIDO passkey registration" app-name "FidoDemo"
/ping-orchestration-react-native-sdk flow journey
/ping-orchestration-react-native-sdk flow oidc
```

---

# Ping SDK for React Native — Integration Guide

## Flow Types — Choose Your Integration Path

**Journey (native)** — authentication UI rendered entirely inside your React Native app using your own components. Callbacks arrive as a structured node; you render fields and call `next()` to advance. Targets PingOne AIC / PingAM.

**OIDC Web** — launches the system browser (ASWebAuthenticationSession on iOS, Custom Tabs on Android). No in-app credential UI. Works with any OIDC provider including PingOne.

## Package Map

Install only what your flow needs:

| Package | When to add |
|---|---|
| `@ping-identity/rn-journey` | Journey flows — `createJourneyClient`, `useJourney`, `useJourneyForm`, `JourneyProvider` |
| `@ping-identity/rn-oidc` | OIDC Web flows — `createOidcClient`, `createOidcWebClient`, `useOidc`, `OidcProvider` |
| `@ping-identity/rn-fido` | FIDO2 / passkey registration and authentication callbacks |
| `@ping-identity/rn-binding` | Device binding and signing callbacks |
| `@ping-identity/rn-device-profile` | Device profile collection callback |
| `@ping-identity/rn-device-client` | Device registration/authentication collectors |
| `@ping-identity/rn-external-idp` | Social / external IdP callbacks |
| `@ping-identity/rn-push` | Push MFA |
| `@ping-identity/rn-oath` | TOTP / HOTP MFA |
| `@ping-identity/rn-core` | Core bridge utilities (transitive dep — usually not imported directly) |

## 1 — Installation

```bash
npm install @ping-identity/rn-journey     # Journey flows
npm install @ping-identity/rn-oidc        # OIDC Web flows

# Native dependencies (required for all flows)
cd ios && pod install
```

Pin the version explicitly:

```json
{
  "dependencies": {
    "@ping-identity/rn-journey": "1.0.0",
    "@ping-identity/rn-oidc":    "1.0.0"
  }
}
```

## 2 — Node Types

Both flows share the same node discriminator pattern. Nodes arrive as plain objects — discriminate on `node.type`:

| `node.type` | Meaning | Key fields |
|---|---|---|
| `ContinueNode` | More input needed | `node.callbacks` — array of callback objects |
| `SuccessNode` | Authenticated | — |
| `FailureNode` | Auth failed (server-level) | `node.cause` — error message string |
| `ErrorNode` | Network / protocol error | `node.message` — error message string |

```tsx
switch (node?.type) {
  case 'ContinueNode':
    return <CallbackRenderer node={node} />;
  case 'SuccessNode':
    return <HomeScreen />;
  case 'FailureNode':
    return <ErrorView message={node.cause ?? 'Authentication failed'} />;
  case 'ErrorNode':
    return <ErrorView message={node.message ?? 'An error occurred'} />;
  default:
    return <StartButton onPress={start} />;
}
```

## 3 — Journey Flow

### 3.1 — Create a client

```tsx
import { createJourneyClient } from '@ping-identity/rn-journey';

const journeyClient = createJourneyClient({
  serverUrl: 'https://your-server.example.com/am',
  realm: 'alpha',
  cookie: 'iPlanetDirectoryPro',
  modules: {
    oidc: {
      clientId: 'your-client-id',
      discoveryEndpoint: 'https://your-server.example.com/am/oauth2/alpha/.well-known/openid-configuration',
      redirectUri: 'com.example.app://callback',
      scopes: ['openid', 'profile', 'email'],
    },
  },
});
```

Create the client outside the component tree (module scope or app-level singleton) so it is not re-created on every render.

### 3.2 — Wrap with JourneyProvider + useJourney hook

Create the client at module scope and wrap your screen tree with `JourneyProvider` at the app or navigator root. All descendant screens call `useJourney()` with no client argument.

```tsx
// App.tsx (or navigator root):
import React from 'react';
import { JourneyProvider } from '@ping-identity/rn-journey';
import { journeyClient } from './JourneyClient';
import LoginScreen from './LoginScreen';

export default function App() {
  return (
    <JourneyProvider client={journeyClient}>
      <LoginScreen />
    </JourneyProvider>
  );
}
```

```tsx
// LoginScreen.tsx — reads from JourneyProvider, no client arg:
import { useJourney } from '@ping-identity/rn-journey';

function LoginScreen() {
  const [node, { start, next, logoutUser, loading, error }] = useJourney();

  useEffect(() => {
    start('Login');
  }, []);

  if (loading) return <ActivityIndicator />;
  if (error)   return <Text>Error: {error.message}</Text>;

  switch (node?.type) {
    case 'ContinueNode':
      return <CallbackRenderer node={node} onNext={next} />;
    case 'SuccessNode':
      return <HomeScreen />;
    case 'FailureNode':
      return <Text>{node.cause ?? 'Authentication failed'}</Text>;
    case 'ErrorNode':
      return <Text>{node.message ?? 'An error occurred'}</Text>;
    default:
      return <Button title="Sign In" onPress={() => { start('Login'); }} />;
  }
}
```

For a standalone screen outside the provider tree, pass the client directly: `useJourney(journeyClient)`.

### 3.3 — JourneyProvider props

```ts
type JourneyProviderProps = {
  client:   JourneyClient;
  children: React.ReactNode;
};
```

### 3.4 — Advancing a node

Pass callback input to `next()` using `JourneyNextInput`:

```tsx
import type { JourneyNextInput } from '@ping-identity/rn-journey';

const input: JourneyNextInput = {
  callbacks: [
    { type: 'NameCallback',     value: username },
    { type: 'PasswordCallback', value: password },
  ],
};

await next(input);
```

Multiple callbacks of the same type use the `index` field (zero-based, per-type):

```tsx
{ type: 'NameCallback', value: 'user@example.com', index: 0 }
```

### 3.5 — Session lifecycle

```tsx
const [node, { user, refresh, revoke, userinfo, ssoToken, logoutUser }] = useJourney();

// Check for existing session on mount:
const session = await user();       // JourneyUserSession | null
if (session) { /* already signed in */ }

// Fetch user profile:
const info = await userinfo();      // JourneyUserInfo | null

// Refresh tokens:
const refreshed = await refresh();  // JourneyUserSession | null

// Revoke tokens:
await revoke();

// Sign out (clears session + tokens):
await logoutUser();
```

### 3.6 — Callback renderer pattern

Iterate `node.callbacks` and switch on `cb.type`. For a basic username/password flow:

```tsx
import type { JourneyNode, JourneyCallback } from '@ping-identity/rn-journey';

function CallbackRenderer({
  node,
  onNext,
}: {
  node: JourneyNode;
  onNext: (input: JourneyNextInput) => Promise<void>;
}) {
  const [values, setValues] = useState<Record<string, string>>({});

  const handleSubmit = async () => {
    const callbacks = node.callbacks?.map((cb, i) => ({
      type: cb.type,
      value: values[`${cb.type}_${i}`] ?? '',
    }));
    await onNext({ callbacks });
  };

  return (
    <View>
      {node.callbacks?.map((cb, i) => (
        <CallbackField
          key={`${cb.type}_${i}`}
          callback={cb}
          value={values[`${cb.type}_${i}`] ?? ''}
          onChange={(v) => setValues((prev) => ({ ...prev, [`${cb.type}_${i}`]: v }))}
        />
      ))}
      <Button title="Next" onPress={handleSubmit} />
    </View>
  );
}
```

Two `CallbackRenderer` patterns are available — chosen in step W2.5 of the wizard:
- **Managed** (`CallbackRenderer.form.tsx.template`) — uses `useJourneyForm` for field state, validation, and payload assembly. Recommended for most flows.
- **Manual** (`CallbackRenderer.tsx.template`) — uses raw `node.callbacks` with manual `useState` and index tracking. Use when you need direct control over the payload.

See [references/callbacks.md](references/callbacks.md) for the `useJourneyForm` conjunction pattern and return contract.

## 4 — OIDC Web Flow

### 4.1 — Create clients

```tsx
import { createOidcClient, createOidcWebClient } from '@ping-identity/rn-oidc';

// Create the base client once (module scope):
const oidcClient = createOidcClient({
  clientId: 'your-client-id',
  discoveryEndpoint: 'https://your-tenant.pingone.com/as/.well-known/openid-configuration',
  redirectUri: 'com.example.app://callback',
  scopes: ['openid', 'profile', 'email'],
});

// Create the web client from the base client:
const oidcWebClient = createOidcWebClient(oidcClient);
```

### 4.2 — Wrap with OidcProvider + useOidc hook

Create the clients at module scope and wrap your screen tree with `OidcProvider` at the app or navigator root. All descendant screens call `useOidc()` with no client argument.

```tsx
// App.tsx (or navigator root):
import React from 'react';
import { OidcProvider } from '@ping-identity/rn-oidc';
import { oidcWebClient } from './OidcClient';
import LoginScreen from './LoginScreen';

export default function App() {
  return (
    <OidcProvider client={oidcWebClient}>
      <LoginScreen />
    </OidcProvider>
  );
}
```

```tsx
// LoginScreen.tsx — reads from OidcProvider, no client arg:
import React, { useEffect, useState } from 'react';
import { useOidc } from '@ping-identity/rn-oidc';

function LoginScreen() {
  const [state, actions] = useOidc();
  const { isAuthenticated, error } = state;
  // restore() is a silent keychain read — it does not set isLoading.
  // Use local state to track when the initial session check is done.
  const [restoring, setRestoring] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        await actions.restore();
      } catch {
      } finally {
        setRestoring(false);
      }
    })();
  }, []);

  if (restoring) return <ActivityIndicator />;
  if (isAuthenticated) return <HomeScreen />;

  return (
    <Button
      title="Sign In"
      onPress={async () => {
        await actions.authorize();
      }}
    />
  );
}
```

For a standalone screen outside the provider tree, pass the client directly: `useOidc(oidcWebClient)`.

### 4.3 — OidcProvider props

```ts
type OidcProviderProps = {
  client:   OidcWebClient;
  children: React.ReactNode;
};
```

### 4.4 — Token and session operations

```tsx
const [state, actions] = useOidc();

// Get tokens:
const tokens = await actions.token();
// tokens.accessToken, tokens.idToken, tokens.refreshToken

// Refresh tokens:
const refreshed = await actions.refresh();

// Fetch userinfo:
const info = await actions.userinfo();     // cache: false by default
const cached = await actions.userinfo(true);

// Revoke tokens:
await actions.revoke();

// Logout:
await actions.logout();

// Clear transient state (errors, tokens, userinfo) without logging out:
actions.clear();
```

### 4.5 — Android redirect URI wiring

`rn-oidc` uses AppAuth's `RedirectUriReceiverActivity` (declared in the library's own manifest) to catch the redirect. The `appRedirectUriScheme` manifest placeholder wires the scheme automatically — **do not** add an additional `<intent-filter>` to `MainActivity`. Doing so causes `MainActivity` to intercept the callback URL before AppAuth can complete the token exchange, leaving the app stuck after browser login.

Only the placeholder is needed — in `android/app/build.gradle` inside `defaultConfig`:

```groovy
manifestPlaceholders = [appRedirectUriScheme: "com.example.app"]
```

### 4.6 — iOS redirect URI wiring

In `ios/<AppName>/Info.plist`, add a URL scheme entry:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.example.app</string>
    </array>
  </dict>
</array>
```

## 5 — FIDO / Passkeys (Journey)

See [references/callbacks.md](references/callbacks.md) for `FidoRegistrationCallback` and `FidoAuthenticationCallback` patterns. Add `@ping-identity/rn-fido`:

```bash
npm install @ping-identity/rn-fido
cd ios && pod install
```

**iOS native requirements (required — passkeys will silently fail without these):**

1. Add `NSFaceIDUsageDescription` to `ios/<AppName>/Info.plist`:
   ```xml
   <key>NSFaceIDUsageDescription</key>
   <string>Used to authenticate with a passkey</string>
   ```

2. Add an Associated Domains entitlement for `webcredentials` in `ios/<AppName>/<AppName>.entitlements` (create the file if it does not exist, then link it in Xcode under Signing & Capabilities → Associated Domains):
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
     <key>com.apple.developer.associated-domains</key>
     <array>
       <string>webcredentials:yourdomain.com</string>
     </array>
   </dict>
   </plist>
   ```
   Replace `yourdomain.com` with the domain configured in your PingAM/AIC FIDO service. Your server must host `https://yourdomain.com/.well-known/apple-app-site-association` with the `webcredentials` section pointing to your app's Team ID + Bundle ID.

```tsx
import { createFidoClient } from '@ping-identity/rn-fido';

const fidoClient = createFidoClient();

// Registration — first arg is journey (JourneyClient), index is per-type:
await fidoClient.registerForJourney(journey, {
  index: field.ref.typeIndex,
  deviceName: 'My iPhone',
});

// Authentication:
await fidoClient.authenticateForJourney(journey, { index: field.ref.typeIndex });
```

After calling register/authenticate, call `next({})` to advance the node.

## 5 — Push MFA Integration

Push MFA can be layered on top of any Journey or OIDC flow after the core auth is working.

**Install:**
```bash
npm install @ping-identity/rn-push
cd ios && pod install
```

**Copy templates:**
- `assets/push/PushNotificationProvider.tsx.template` → `src/PushNotificationProvider.tsx`
- `assets/push/NotificationCardView.tsx.template` → `src/screens/NotificationCardView.tsx`

**Android:** Copy `assets/push/PushMessagingService.kt.template` → `android/app/src/main/java/<package>/PushMessagingService.kt`. Register the service in `AndroidManifest.xml` (with the `MESSAGING_EVENT` intent filter) and add the FCM Google Services dependency.

**iOS:** Copy `assets/push/AppDelegate.push.swift.template` → `ios/<AppName>/AppDelegate.swift`. Enable the Push Notifications capability in Xcode and register for remote notifications.

See [references/callbacks.md](references/callbacks.md#push-mfa) for the full `usePush` hook API, `PushProvider`, push notification shapes, and `PushClient` methods.

## UnsupportedCallbackView

`UnsupportedCallbackView` is the standard fallback for any callback with `executionMode === 'integration_required'` or `'unsupported'` that the app does not yet handle (e.g. `PingOneProtectInitializeCallback`, `ReCaptchaEnterpriseCallback`). All form-managed `CallbackRenderer` variants generate it automatically. Manual-mode renderers should also include it as the `default` branch in their callback switch.

## 6 — Common Pitfalls

- **Client created inside component** — `createJourneyClient` / `createOidcClient` must be called at module scope or in a stable ref. Creating inside a component body causes a new native instance on every render.
- **Missing `openid` scope** — always include `openid` in `scopes`. The native layer will throw if omitted.
- **`redirectUri` scheme must match native config** — the scheme in `redirectUri` must match the URL scheme registered in `AndroidManifest.xml` and `Info.plist`.
- **`FailureNode` vs `ErrorNode`** — `FailureNode` is a server-level auth failure (wrong password, locked account); `ErrorNode` is a network/protocol error. Handle both.
- **`next()` called without active node** — `useJourney` will throw `JOURNEY_STATE_ERROR` if `next()` is called before `start()` or `resume()` has returned a node.
- **Multiple `NavigationContainer` instances kill the back button** — never render two `NavigationContainer` elements (e.g. one per flow). There must be exactly one in the tree. Use a flat stack with a `FlowPicker` initial screen instead of switching containers via React state.
- **`OidcProvider` inside a screen component loses state on re-render** — create the OIDC client in `useMemo` at the `App` level and place `OidcProvider` above `NavigationContainer`, same as `JourneyProvider`.
- **`isLoading` does not track `restore()`** — `restore()` is a silent keychain read and does not set `isLoading`. Gate the initial restore spinner with local `restoring` state + async/await as shown in section 4.2, not with `state.isLoading`. `isLoading` only covers `authorize`, `token`, `refresh`, `userinfo`, `revoke`, and `logout`.
- **`dispose()` on unmount** — call `client.dispose()` when the client is no longer needed to release native resources. For long-lived clients, dispose on app teardown or user switch.

## 7 — Journey Export Analysis

When the user provides a Journey export JSON (Step W1b), run the full analysis in [references/journey-export-analysis.md](references/journey-export-analysis.md) (steps A1–A8) before writing any code.

## Reference Files

- [references/journey-client.md](references/journey-client.md) — Full `createJourneyClient` config, `JourneyConfig`, all hook actions, `JourneyNextInput`
- [references/callbacks.md](references/callbacks.md) — All callback types, `useJourneyForm` conjunction pattern and when to use it, execution modes
- [references/oidc-client.md](references/oidc-client.md) — Full `OidcClientConfig`, `createOidcWebClient`, all `useOidc` actions, error codes
- [references/common-mistakes.md](references/common-mistakes.md) — RN-specific gotchas: client scope, navigation, callback index, OIDC redirect, platform minimums
- [references/oath.md](references/oath.md) — `createOathClient`, TOTP/HOTP credential management, policy evaluator, error codes
- [references/journey-export-analysis.md](references/journey-export-analysis.md) — Journey export JSON analysis steps (A1–A8), node→callback mapping table
