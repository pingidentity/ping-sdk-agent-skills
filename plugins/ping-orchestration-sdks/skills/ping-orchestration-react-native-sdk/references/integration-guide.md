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
| `@ping-identity/rn-device-client` | Unified device management bridge (OATH/Push/Bound/WebAuthn/Profile) — install when building custom device flows beyond what the Journey callbacks cover |
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

See [callbacks.md](callbacks.md) for the `useJourneyForm` conjunction pattern and return contract.

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

See [callbacks.md](callbacks.md) for `FidoRegistrationCallback` and `FidoAuthenticationCallback` patterns. Add `@ping-identity/rn-fido`:

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

## 6 — Push MFA Integration

Push MFA can be layered on top of any Journey or OIDC flow after the core auth is working.

**Install:**
```bash
npm install @ping-identity/rn-push @ping-identity/rn-logger @ping-identity/rn-storage react-native-vector-icons
cd ios && pod install
```
Note: `@ping-identity/rn-logger` and `@ping-identity/rn-storage` are already installed if using Full tier. `react-native-vector-icons` requires native linking — follow its setup guide for iOS (add to Podfile) and Android (auto-linked in RN >= 0.60).

**Copy templates:**
- `assets/push/PushNotificationProvider.tsx.template` → `src/PushNotificationProvider.tsx`
- `assets/push/NotificationCardView.tsx.template` → `src/screens/NotificationCardView.tsx`

**Android:**
- Copy `assets/push/PushMessagingService.kt.template` → `android/app/src/main/java/<package>/PushMessagingService.kt`. Register the service in `AndroidManifest.xml` (with the `MESSAGING_EVENT` intent filter) and add the FCM Google Services dependency.
- Copy `assets/push/strings.ping_push.xml.template` → `android/app/src/main/res/values/strings.ping_push.xml` (required — `PushMessagingService` references these string resources at runtime).
- Copy `assets/push/colors.ping_push.xml.template` → `android/app/src/main/res/values/colors.ping_push.xml` (required — provides the notification accent color).
- Copy `assets/push/ping_push_notification_icon.xml.template` → `android/app/src/main/res/drawable/ping_push_notification_icon.xml` (optional — falls back to system info icon if absent).

**iOS:** Copy `assets/push/AppDelegate.push.swift.template` → `ios/<AppName>/AppDelegate.swift`. Enable the Push Notifications capability in Xcode and register for remote notifications.

See [callbacks.md](callbacks.md#push-mfa) for the full `usePush` hook API, `PushProvider`, push notification shapes, and `PushClient` methods.

## 7 — Common Pitfalls

- **Client created inside component** — `createJourneyClient` / `createOidcClient` must be called at module scope or in a stable ref. Creating inside a component body causes a new native instance on every render.
- **Missing `openid` scope** — always include `openid` in `scopes`. The native layer will throw if omitted.
- **`redirectUri` scheme must match native config** — the scheme in `redirectUri` must match the URL scheme registered in `AndroidManifest.xml` and `Info.plist`.
- **`FailureNode` vs `ErrorNode`** — `FailureNode` is a server-level auth failure (wrong password, locked account); `ErrorNode` is a network/protocol error. Handle both.
- **`next()` called without active node** — `useJourney` will throw `JOURNEY_STATE_ERROR` if `next()` is called before `start()` or `resume()` has returned a node.
- **Multiple `NavigationContainer` instances kill the back button** — never render two `NavigationContainer` elements (e.g. one per flow). There must be exactly one in the tree. Use a flat stack with a `FlowPicker` initial screen instead of switching containers via React state.
- **`OidcProvider` inside a screen component loses state on re-render** — create the OIDC client in `useMemo` at the `App` level and place `OidcProvider` above `NavigationContainer`, same as `JourneyProvider`.
- **`isLoading` does not track `restore()`** — `restore()` is a silent keychain read and does not set `isLoading`. Gate the initial restore spinner with local `restoring` state + async/await as shown in section 4.2, not with `state.isLoading`. `isLoading` only covers `authorize`, `token`, `refresh`, `userinfo`, `revoke`, and `logout`.
- **`dispose()` on unmount** — call `client.dispose()` when the client is no longer needed to release native resources. For long-lived clients, dispose on app teardown or user switch.

## 8 — Journey Export Analysis

When the user provides a Journey export JSON (Step W1b), run the full analysis in [journey-export-analysis.md](journey-export-analysis.md) (steps A1–A8) before writing any code.
