# Journey + OIDC Scaffold: Steps P1-P3

Read this file when `flowType = 'both'`. Follow J1 and J3 of [journey-scaffold.md](journey-scaffold.md) exactly as written, then follow Steps P1-P3 here in place of J2, J4, J5, and every step of [oidc-scaffold.md](oidc-scaffold.md). Both flows write a `LoginScreen` and a `HomeScreen` and both navigate to `Login` and `Home`, so they cannot share file names or route names in one app. Everything else in the scaffold (project creation, `PingTheme`, logo, launch) is unchanged.

Inputs collected by the wizard: the Journey inputs listed in [journey-scaffold.md](journey-scaffold.md) and the OIDC inputs listed in [oidc-scaffold.md](oidc-scaffold.md).

---

## P1 - Write the screens

Read each template from this skill's `assets/` directory and write it to the project. Do not generate these files from memory; always read the template first.

Pick the `CallbackRenderer` template by `callbackMode` + `callbackTier` and write it to `<projectDir>/src/screens/CallbackRenderer.tsx`, using the table in J2 of [journey-scaffold.md](journey-scaffold.md).

Write the remaining screens under flow-specific names:

| Flow | Template | Write to |
|---|---|---|
| Journey | `assets/LoginScreen.tsx.template` | `<projectDir>/src/screens/JourneyLoginScreen.tsx` |
| Journey | `assets/HomeScreen.tsx.template` | `<projectDir>/src/screens/JourneyHomeScreen.tsx` |
| OIDC | `assets/LoginScreen.oidc.tsx.template` | `<projectDir>/src/screens/OidcLoginScreen.tsx` |
| OIDC | `assets/HomeScreen.oidc.tsx.template` | `<projectDir>/src/screens/OidcHomeScreen.tsx` |
| Picker | `assets/FlowPicker.tsx.template` | `<projectDir>/src/screens/FlowPicker.tsx` |

After writing templates, substitute `<AppName>` placeholders with the actual app name in every written file that contains one.

Each login screen navigates to `Home` and each home screen navigates to `Login`. Rename those targets so the two flows get their own routes. Replace only the `navigation.replace(...)` call; do not touch `JOURNEY_NAME = 'Login'` in the Journey login screen, which is a Journey name and not a route:

| File | Replace | With |
|---|---|---|
| `JourneyLoginScreen.tsx` | `navigation.replace('Home')` | `navigation.replace('JourneyHome')` |
| `JourneyHomeScreen.tsx` | `navigation.replace('Login')` | `navigation.replace('JourneyLogin')` |
| `OidcLoginScreen.tsx` | `navigation.replace('Home')` | `navigation.replace('OidcHome')` |
| `OidcHomeScreen.tsx` | `navigation.replace('Login')` | `navigation.replace('OidcLogin')` |

The files still export `LoginScreen` and `HomeScreen`; `App.tsx` aliases them in P2.

**Acceptance:** all five screens exist with `<AppName>` substituted; no `navigation.replace('Home')` or `navigation.replace('Login')` remains in `src/screens/`; `JOURNEY_NAME` is unchanged.

---

## P2 - Overwrite `App.tsx`

Overwrite `<projectDir>/App.tsx` with one React Navigation stack that starts on `FlowPicker`. **All Ping providers must wrap the single `NavigationContainer`** — never use multiple `NavigationContainer` instances or nest providers inside screen components. Create the `OidcProvider` client in `useMemo` at the `App` level.

```tsx
import React, { useMemo } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { JourneyProvider } from '@ping-identity/rn-journey';
import { OidcProvider, createOidcClient, createOidcWebClient } from '@ping-identity/rn-oidc';
import { journeyClient } from './src/<AppName>JourneyClient';
import { FlowPicker } from './src/screens/FlowPicker';
import { LoginScreen as JourneyLoginScreen } from './src/screens/JourneyLoginScreen';
import { HomeScreen as JourneyHomeScreen } from './src/screens/JourneyHomeScreen';
import { LoginScreen as OidcLoginScreen } from './src/screens/OidcLoginScreen';
import { HomeScreen as OidcHomeScreen } from './src/screens/OidcHomeScreen';

export type RootStackParamList = {
  FlowPicker: undefined;
  JourneyLogin: undefined;
  JourneyHome: undefined;
  OidcLogin: undefined;
  OidcHome: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function App() {
  const oidcClient = useMemo(
    () =>
      createOidcWebClient(
        createOidcClient({
          clientId: '<clientId>',
          discoveryEndpoint: '<discoveryEndpoint>',
          redirectUri: '<redirectUri>',
          scopes: ['openid', 'profile', 'email'],
        }),
      ),
    [],
  );

  return (
    <JourneyProvider client={journeyClient}>
      <OidcProvider client={oidcClient}>
        <NavigationContainer>
          <Stack.Navigator initialRouteName="FlowPicker">
            <Stack.Screen name="FlowPicker" component={FlowPicker} options={{ headerShown: false }} />
            <Stack.Screen name="JourneyLogin" component={JourneyLoginScreen} options={{ title: 'Sign In' }} />
            <Stack.Screen name="JourneyHome" component={JourneyHomeScreen} options={{ title: 'Profile' }} />
            <Stack.Screen name="OidcLogin" component={OidcLoginScreen} options={{ title: 'Sign In' }} />
            <Stack.Screen name="OidcHome" component={OidcHomeScreen} options={{ title: 'Profile' }} />
          </Stack.Navigator>
        </NavigationContainer>
      </OidcProvider>
    </JourneyProvider>
  );
}
```

`journeyClient` is the named export of the client file written in J3, because the Journey login screen imports it by name. The screens use `useJourney()` / `useOidc()` with no client argument — they read from the provider above the navigator. Navigation between auth screens uses `replace` so the back button cannot return to the auth screen after login or to the home screen after logout; `FlowPicker` uses `navigate` so back returns to the picker.

**Acceptance:** exactly one `NavigationContainer`; both providers sit above it; the five routes in `RootStackParamList` match the five `Stack.Screen` names.

---

## P3 - Install command and platform setup

Run the Ping SDK and navigation install command using the Bash tool:
```bash
cd <projectDir> && npm install @ping-identity/rn-core@1.1.0 <flow packages> @react-navigation/native @react-navigation/native-stack react-native-screens react-native-safe-area-context
```
`rn-core` is a required peer dependency. Replace `<flow packages>` by selection:

| Selection | `<flow packages>` |
|---|---|
| Journey + OIDC | Journey Full tier, plus `@ping-identity/rn-oidc@1.1.0` |

The Journey Full tier packages are listed in J5 of [journey-scaffold.md](journey-scaffold.md).

Apply the platform setup in [platform-setup.md](platform-setup.md) before running the app. Always apply its Baseline section (iOS 16.0, Android minSdk 29, the Android JVM-target flags, then `pod install`), plus the section for each flow or package in use: OIDC redirect wiring, `rn-fido`, `rn-external-idp`, `rn-protect`, `rn-device-profile`, `rn-binding`/`rn-device-client`, `rn-push`.

**Acceptance:** the install command lists `rn-core`, the navigation packages, the Journey Full tier packages, and `@ping-identity/rn-oidc@1.1.0`.
