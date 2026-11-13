# Journey Scaffold: Steps J1-J5

Read this file when `flowType = 'journey'` and follow Steps J1-J5 exactly, in order. For `flowType = 'both'`, follow only J1 and J3 and use [journey-oidc-scaffold.md](journey-oidc-scaffold.md) for the rest. They cover the callback views, the screens, the `<AppName>JourneyClient.ts` client file, the `App.tsx` stack, and the install command. Everything else in the scaffold (project creation, `PingTheme`, logo, launch) is unchanged.

Inputs collected by the wizard:

| Input | Source | Values |
|---|---|---|
| `callbackMode` | Step W2.5 | `managed` or `manual` |
| `callbackTier` | Step W2.6 | `basic`, `standard`, or `full` |
| `serverUrl`, `realm`, `cookieName`, `journeyName`, `clientId`, `redirectUri`, `discoveryEndpoint`, `scopes` | Step W3 | See the Journey parameter table in SKILL.md |
| `<AppName>` | Step W3 | App name used in file names |

---

## J1 - Write the callback views

Read each template from this skill's `assets/` directory and write it to the project. Do not generate these files from memory; always read the template first.

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
- `assets/callbacks/UnsupportedCallbackView.tsx.template` → `src/callbacks/UnsupportedCallbackView.tsx`

**Callback components — Standard tier** (write these when `callbackTier = standard` or `full`):
- `assets/callbacks/ConsentMappingCallbackView.tsx.template` → `src/callbacks/ConsentMappingCallbackView.tsx`
- `assets/callbacks/FidoRegistrationCallbackView.tsx.template` → `src/callbacks/FidoRegistrationCallbackView.tsx`
- `assets/callbacks/FidoAuthenticationCallbackView.tsx.template` → `src/callbacks/FidoAuthenticationCallbackView.tsx`
- `assets/callbacks/DeviceBindingCallbackView.tsx.template` → `src/callbacks/DeviceBindingCallbackView.tsx`
- `assets/callbacks/DeviceSigningVerifierCallbackView.tsx.template` → `src/callbacks/DeviceSigningVerifierCallbackView.tsx`
- `assets/callbacks/DeviceProfileCallbackView.tsx.template` → `src/callbacks/DeviceProfileCallbackView.tsx`

**Callback components — Full tier** (write these when `callbackTier = full`):
- `assets/callbacks/SelectIdpCallbackView.tsx.template` → `src/callbacks/SelectIdpCallbackView.tsx`

**Acceptance:** `src/callbacks/` holds 16, 22, or 23 views for Basic, Standard, or Full.

---

## J2 - Write the screens

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

After writing templates, substitute `<AppName>` placeholders in `LoginScreen.tsx` and `HomeScreen.tsx` with the actual app name.

**Acceptance:** `src/screens/` holds `CallbackRenderer.tsx` from the template row that matches `callbackMode` and `callbackTier`, plus `LoginScreen.tsx` and `HomeScreen.tsx`, with no `<AppName>` placeholder left.

---

## J3 - Write the client file

**This file is still generated** (it contains user-supplied config values):
- `<projectDir>/src/<AppName>JourneyClient.ts`

```ts
import { createJourneyClient } from '@ping-identity/rn-journey';

export const journeyClient = createJourneyClient({
  serverUrl: '<serverUrl>',
  realm: '<realm>',
  cookie: '<cookieName>',
  modules: {
    oidc: {
      clientId: '<clientId>',
      discoveryEndpoint: '<discoveryEndpoint>',
      redirectUri: '<redirectUri>',
      scopes: ['openid', 'profile', 'email'],
    },
  },
});
```

Create the client at module scope and export it by name: the Journey login screen imports `journeyClient` by name. Use the `scopes` value from Step W3 as the array.

**Full tier only** — also export `idpClient` from the Journey client file:
```ts
import { createExternalIdpClient } from '@ping-identity/rn-external-idp';
export const idpClient = createExternalIdpClient();
```
`SelectIdpCallbackView` imports `idpClient` from this file.

**Acceptance:** `journeyClient` is a named export created at module scope; in the Full tier the same file also exports `idpClient`.

---

## J4 - Overwrite `App.tsx`

Overwrite `<projectDir>/App.tsx` with a React Navigation stack. **All Ping providers must wrap the single `NavigationContainer`** — never use multiple `NavigationContainer` instances or nest providers inside screen components. A single flat stack gives every screen a back button automatically.

**Journey flow:**
```tsx
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { JourneyProvider } from '@ping-identity/rn-journey';
import { journeyClient } from './src/<AppName>JourneyClient';
import { LoginScreen } from './src/screens/LoginScreen';
import { HomeScreen } from './src/screens/HomeScreen';

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

Screens navigate with `useNavigation<any>()`, as the templates do. After successful login call `navigation.replace('Home')`. After logout call `navigation.replace('Login')`. Use `replace` — not `navigate` — so the back button cannot return to the auth screen after login or to the home screen after logout.

All screens use `useJourney()` with no client argument — they read from the provider above the navigator.

**Acceptance:** exactly one `NavigationContainer`; `JourneyProvider client={journeyClient}` sits above it; the routes in `RootStackParamList` match the `Stack.Screen` names.

---

## J5 - Install command and platform setup

Run the Ping SDK and navigation install command using the Bash tool:
```bash
cd <projectDir> && npm install @ping-identity/rn-core@1.1.0 <flow packages> @react-navigation/native @react-navigation/native-stack react-native-screens react-native-safe-area-context
```
`rn-core` is a required peer dependency. Replace `<flow packages>` by selection:

| Selection | `<flow packages>` |
|---|---|
| Journey, Basic tier | `@ping-identity/rn-journey@1.1.0` |
| Journey, Standard tier | Basic, plus `@ping-identity/rn-fido@1.1.0 @ping-identity/rn-binding@1.1.0 @ping-identity/rn-device-profile@1.1.0` |
| Journey, Full tier | Standard, plus `@ping-identity/rn-external-idp@1.1.0 @ping-identity/rn-logger@1.1.0 @ping-identity/rn-storage@1.1.0 @ping-identity/rn-device-id@1.1.0 @ping-identity/rn-oath@1.1.0 @ping-identity/rn-device-client@1.1.0` |

Apply the platform setup in [references/platform-setup.md](platform-setup.md) before running the app. Always apply its Baseline section (iOS 16.0: the Podfile platform line, the Podfile post_install raise for pod targets, and the app-target `IPHONEOS_DEPLOYMENT_TARGET`; Android minSdk 29; the Android JVM-target flags; then `pod install`), plus the section for each flow or package in use: OIDC redirect wiring, `rn-fido`, `rn-external-idp`, `rn-protect`, `rn-device-profile`, `rn-binding`/`rn-device-client`, `rn-push`.

**Acceptance:** the install command lists `rn-core`, the navigation packages, and exactly the selected tier's packages.
