# OIDC Scaffold: Steps O1-O3

Read this file when `flowType = 'oidc'` and follow Steps O1-O3 exactly, in order. They cover the screens, the `App.tsx` stack, and the install command. For `flowType = 'both'`, use [journey-oidc-scaffold.md](journey-oidc-scaffold.md) instead. Everything else in the scaffold (project creation, `PingTheme`, logo, launch) is unchanged.

Inputs collected by the wizard:

| Input | Source | Values |
|---|---|---|
| `clientId`, `redirectUri`, `discoveryEndpoint`, `scopes` | Step W3 | See the common parameter table in SKILL.md |
| `<AppName>` | Step W3 | App name used in file names |

---

## O1 - Write the screens

Read each template from this skill's `assets/` directory and write it to the project. Do not generate these files from memory; always read the template first.

**Screen files** (OIDC flow):
- Read `assets/LoginScreen.oidc.tsx.template` → write to `<projectDir>/src/screens/LoginScreen.tsx`
- Read `assets/HomeScreen.oidc.tsx.template` → write to `<projectDir>/src/screens/HomeScreen.tsx`

After writing templates, substitute `<AppName>` placeholders in `LoginScreen.tsx` and `HomeScreen.tsx` with the actual app name.

**Acceptance:** `LoginScreen.tsx` and `HomeScreen.tsx` exist in `src/screens/`, with no `<AppName>` placeholder left.

---

## O2 - Overwrite `App.tsx`

Overwrite `<projectDir>/App.tsx` with a React Navigation stack. **All Ping providers must wrap the single `NavigationContainer`** — never use multiple `NavigationContainer` instances or nest providers inside screen components. A single flat stack gives every screen a back button automatically.

**OIDC flow:**
```tsx
import React, { useMemo } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { OidcProvider, createOidcClient, createOidcWebClient } from '@ping-identity/rn-oidc';
import { LoginScreen } from './src/screens/LoginScreen';
import { HomeScreen } from './src/screens/HomeScreen';

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

Screens navigate with `useNavigation<any>()`, as the templates do. After successful login call `navigation.replace('Home')`. After logout call `navigation.replace('Login')`. Use `replace` — not `navigate` — so the back button cannot return to the auth screen after login or to the home screen after logout.

All screens use `useOidc()` with no client argument — they read from the provider above the navigator.

**Acceptance:** exactly one `NavigationContainer`; `OidcProvider` sits above it with a client created in `useMemo` at the `App` level; the routes in `RootStackParamList` match the `Stack.Screen` names.

---

## O3 - Install command and platform setup

Run the Ping SDK and navigation install command using the Bash tool:
```bash
cd <projectDir> && npm install @ping-identity/rn-core@1.1.0 <flow packages> @react-navigation/native @react-navigation/native-stack react-native-screens react-native-safe-area-context
```
`rn-core` is a required peer dependency. Replace `<flow packages>` by selection:

| Selection | `<flow packages>` |
|---|---|
| OIDC | `@ping-identity/rn-oidc@1.1.0` |

Apply the platform setup in [references/platform-setup.md](platform-setup.md) before running the app. Always apply its Baseline section (iOS 16.0: the Podfile platform line, the Podfile post_install raise for pod targets, and the app-target `IPHONEOS_DEPLOYMENT_TARGET`; Android minSdk 29; the Android JVM-target flags; then `pod install`), plus the section for each flow or package in use: OIDC redirect wiring, `rn-fido`, `rn-external-idp`, `rn-protect`, `rn-device-profile`, `rn-binding`/`rn-device-client`, `rn-push`.

**Acceptance:** the install command lists `rn-core`, the navigation packages, and `@ping-identity/rn-oidc@1.1.0`.
