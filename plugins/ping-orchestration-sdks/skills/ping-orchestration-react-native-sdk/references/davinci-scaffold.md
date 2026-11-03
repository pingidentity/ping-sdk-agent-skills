# DaVinci Scaffold: Steps D1-D5

Read this file when `flowType = 'davinci'` and follow Steps D1-D5 exactly, in order. They cover the collector views, the renderer and screens, the `<AppName>DaVinciConfig.ts` config module, the integration wiring, the `App.tsx` stack, and the install command with the tier prerequisites. Everything else in the scaffold (project creation, `PingTheme`, logo, launch) is unchanged.

Inputs collected by the wizard:

| Input | Source | Values |
|---|---|---|
| `collectorMode` | Step W2.7 | `managed` or `manual` |
| `collectorTier` | Step W2.8 | `basic`, `standard`, or `full` |
| `discoveryEndpoint`, `clientId`, `redirectUri`, `scopes`, `timeout`, `acrValues`, `par`, `storage`, `logger` | Step W3 | See the DaVinci parameter table in SKILL.md |
| `<AppName>` | Step W3 | App name used in file names |

For API depth see [davinci-client.md](davinci-client.md). For collector behavior see [davinci-collectors.md](davinci-collectors.md). This file only says which files to write and what to put in them.

---

## D1 - Write the screens, renderer, and collector views

Read each template from this skill's `assets/` directory. Do not generate these files from memory.

**Collector views** (`assets/collectors/*.tsx.template` to `<projectDir>/src/collectors/*.tsx`). Always write all 15 core views:

- `TextCollectorView`, `PasswordCollectorView`, `SingleSelectCollectorView`, `MultiSelectCollectorView`, `PhoneNumberCollectorView`
- `BooleanCollectorView`, `LabelCollectorView`, `ReadOnlyTextCollectorView`
- `DeviceRegistrationCollectorView`, `DeviceAuthenticationCollectorView`
- `SubmitCollectorView`, `FlowCollectorView`, `PollingCollectorView`, `QRCodeCollectorView`, `IntegrationCollectorView`

The tier never gates core views: the server-side flow decides which core collectors appear, and an undispatched core collector leaves the node unrenderable or unsubmittable. The tier gates only the integration views:

| `collectorTier` | Integration views to write | Total views |
|---|---|---|
| `basic` | none | 15 |
| `standard` | `FidoCollectorView`, `ProtectCollectorView` | 17 |
| `full` | `FidoCollectorView`, `ProtectCollectorView`, `SocialLoginCollectorView` | 18 |

**Renderer shell**: pick by `collectorMode` only and write it to `<projectDir>/src/screens/DaVinciCollectorRenderer.tsx`:

| `collectorMode` | Template |
|---|---|
| `managed` | `assets/DaVinciCollectorRenderer.form.tsx.template` |
| `manual` | `assets/DaVinciCollectorRenderer.tsx.template` |

The shell carries five marked regions that make it tier-agnostic; fill them from the tier, then delete the markers. The integration views own their operations and advance through the parent's guarded `onNext` (the same view-owns-the-operation pattern as the Journey templates); the shell provides the dispatch, the single-flight guard, and the submit path.

| `collectorTier` | Region content |
|---|---|
| `basic` | All five regions empty (leave the placeholder comments) |
| `standard` | Imports: `useDaVinciContext` from `@ping-identity/rn-davinci`; `collectProtect`, `protectCollectorType` from `@ping-identity/rn-protect`; `fidoCollectorType` and the `FidoCollector` type from `@ping-identity/rn-fido`; `protectReady` from the config module; `FidoCollectorView`, `ProtectCollectorView` from `../collectors/`. Client statement: `const client = useDaVinciContext()?.client ?? null;`. Prepare body: `await protectReady;`. Handled types (managed shell only): `fidoCollectorType, protectCollectorType,`. Pre-submit (managed and manual shells): after a `client` null guard, call `collectProtect(client)` once when the node contains a `PROTECT` field, and throw an explanatory error before collecting when it contains more than one. Do not loop per field: the v1.1.0 `collectProtect` has no collector selector and both native bridges hardcode index 0, so a loop would collect the first collector repeatedly and leave the others uncollected. The throw surfaces through the shell's action error. Integration cases: an `if (field.type === fidoCollectorType)` branch rendering `FidoCollectorView` (client, typeIndex among same-action FIDO collectors, `onPerform={run}`, `disabled={busy}`, `onNext={async () => { await next({ collectors: [] }); }}` (promise-returning; the view awaits it inside the guard)) and an `if (field.type === protectCollectorType)` branch rendering `ProtectCollectorView` |
| `full` | The Standard content plus: `socialLoginCollectorType` and the `IdpCollector` type from `@ping-identity/rn-external-idp`; `SocialLoginCollectorView` import and an `if (field.type === socialLoginCollectorType)` case rendering `SocialLoginCollectorView` (client, typeIndex among all SOCIAL_LOGIN_BUTTON collectors, `onPerform={run}`, `disabled={busy}`, `onNext={async () => { await next({ collectors: [] }); }}` (promise-returning; the view awaits it inside the guard)) |

An integration collector type with no filled case falls through to `IntegrationCollectorView`. In the managed shell `HANDLED_COLLECTOR_TYPES` (from `PLACEHOLDER_HANDLED_TYPES`) is passed to `useDaVinciForm` so unhandled integration types do not block `canSubmit`; the manual shell has no such set because it builds its own payload. The ceremonies live in the views (`fidoClient`/`idpClient` come from the config module through the view files), so the shell imports only the type constants and the views.

**Screens**:

- `assets/DaVinciLoginScreen.tsx.template` to `<projectDir>/src/screens/DaVinciLoginScreen.tsx`
- `assets/DaVinciHomeScreen.tsx.template` to `<projectDir>/src/screens/DaVinciHomeScreen.tsx`

The screens contain no `<AppName>` placeholder; the integration views do (they import the config module), so substitute it in every written file that contains it. The login screen awaits `prepareIntegrations()` (exported by the renderer shell) before `start()` in every tier. For Standard and Full that waits on `protectReady` from the config module in D2; for Basic it resolves immediately.

**Acceptance:** all files exist with `<AppName>` substituted; `src/collectors/` holds 15, 17, or 18 views for Basic, Standard, or Full; the Basic output imports no `@ping-identity/rn-fido`, `rn-protect`, or `rn-external-idp` module; the renderer shell contains no leftover `PLACEHOLDER_` marker.

---

## D2 - Write the config module

Write `<projectDir>/src/<AppName>DaVinciConfig.ts`. It exports a `DaVinciConfig` object built from the W3 answers. It does **not** create a DaVinci client: `DaVinciProvider` takes the config and builds the client internally, so there is no `<AppName>DaVinciClient.ts` in a DaVinci scaffold.

```ts
import type { DaVinciConfig } from '@ping-identity/rn-davinci';

export const davinciConfig: DaVinciConfig = {
  timeout: 15000,
  modules: {
    oidc: {
      discoveryEndpoint: '<discoveryEndpoint>',
      clientId: '<clientId>',
      redirectUri: '<redirectUri>',
      scopes: ['openid'],
      acrValues: '<acrValues>',
    },
  },
};
```

Rules for the object:

- `discoveryEndpoint`, `clientId`, and `redirectUri` are required. A missing or empty value makes `createDaVinciClient` (and therefore `DaVinciProvider`) throw `DAVINCI_CONFIG_ERROR`.
- `scopes` always contains `openid`; add the other scopes the user supplied. The native default is an empty set, so omitting `scopes` yields a token request without `openid`.
- Include `timeout`, `acrValues`, `par`, `storage`, and `logger` only when the user supplied them in W3 (`timeout` defaults to 15000 ms when omitted). Of these, `timeout` and `logger` are top-level fields; `acrValues`, `par`, and `storage` go under `modules.oidc`.
- `storage` and `logger` are runtime objects, not values. A W3 yes/no answer does not supply them, so the generator builds them in this module as described below. Both require their package in the D5 install command.
- There is no W3 question for `additionalParameters`. Tell the user they can add it by hand under `modules.oidc` when they need extra authorization parameters.
- Integration clients (Standard and Full tier) are created in this same module at module scope. See D3.

**Building `logger` (when the user chose a logger).** Create it above `davinciConfig` and assign it to the top-level `logger` field:

```ts
import { logger } from '@ping-identity/rn-logger';

const davinciLogger = logger({ level: 'debug' });
```

`level` is one of `'debug'`, `'info'`, `'warn'`, `'error'`, `'none'`. Use `'debug'` unless the user named a level.

**Building `storage` (when the user chose custom token storage).** Create it above `davinciConfig` and assign it to `modules.oidc.storage`:

```ts
import { configureOidcStorage } from '@ping-identity/rn-storage';

const davinciStorage = configureOidcStorage({
  android: {
    keyAlias: '<appname-lowercase>_davinci_key',
    fileName: '<appname-lowercase>_davinci_tokens',
  },
  ios: {
    account: 'com.example.<appname-lowercase>.davinci',
    encryptor: true,
    cacheable: false,
  },
});
```

`configureOidcStorage` registers native storage when the module is imported and throws `StorageError` if the config is invalid. Replace the `ios.account` placeholder with the app's real bundle identifier when it is known, and tell the user the generated key alias, file name, and account are defaults they may rename. Use only the options shown here; do not add others without checking the `rn-storage` types.

When the user chose neither, write neither import and leave both fields out. The config then uses the SDK defaults.

**Acceptance:** the object satisfies the `DaVinciConfig` type; no `createDaVinciClient` call and no `DaVinciClient` export appears in the file, and a DaVinci scaffold contains no `<AppName>DaVinciClient.ts` and no Journey or OIDC files; `logger` and `storage` appear in the config only when the matching object is built in the same file and its package is in the D5 install command.

---

## D3 - Integration wiring by tier

Skip this step for `basic`: no integration package is imported anywhere.

**Why module scope.** `createFidoClient()` and `createExternalIdpClient()` each register their collector type and a native serializer on creation. The first DaVinci node mapping depends on that registration, so both calls belong at module scope in `src/<AppName>DaVinciConfig.ts` (evaluated on import, before the login screen can call `start()`). Never create them inside a component, hook, effect, or lazily on a button press: the first node would then surface the collector only through the generic integration path and the ceremony could not run.

**Standard** (adds FIDO and Protect). In `src/<AppName>DaVinciConfig.ts`:

```ts
import { createFidoClient } from '@ping-identity/rn-fido';
import { startProtect } from '@ping-identity/rn-protect';

export const fidoClient = createFidoClient();

export const protectReady: Promise<void> = startProtect({
  envId: '<pingOneEnvironmentId>',
});
```

`startProtect` must resolve before the first DaVinci operation, and the `PROTECT` collector type is registered only after it succeeds. This is why the D1 Standard region's prepare body awaits `protectReady` and the D1 login screen awaits `prepareIntegrations()` before `start()`. Ask the user for the PingOne environment ID in this step if W3 did not collect it.

**Full** (adds Social Login). In addition, in the same config module:

```ts
import { createExternalIdpClient } from '@ping-identity/rn-external-idp';

export const idpClient = createExternalIdpClient({
  redirectUri: '<redirectUri>',
});
```

**Shell wiring.** Fill the D1 placeholder regions as the D1 table says. The operations specified in [davinci-collectors.md](davinci-collectors.md) are implemented as follows: the FIDO ceremony and Social Login authorization live inside their views (`fidoClient`/`idpClient` come from the config module through the view files), and Protect collection is the shell's pre-submit region. What each tier reads from the config module:

| Tier | View files that import the config module | Imported from the config module |
|---|---|---|
| `standard` | `FidoCollectorView` (`fidoClient`), `ProtectCollectorView` (`protectReady`) | `fidoClient`, `protectReady` |
| `full` | Standard plus `SocialLoginCollectorView` (`idpClient`) | `fidoClient`, `protectReady`, `idpClient` |

In this provider-based scaffold the DaVinci client always comes from `useDaVinciContext()?.client`, resolved in the shell's tier region (not a prop), and both shells advance the flow through the `next` from `useDaVinci()` inside their single-flight guard, never through `client.next`.

**Acceptance:** every integration the tier advertises has its client created at module scope, a `handledCollectorTypes` entry (managed shell), and a trigger path in its view; no integration code appears below the tier; in Standard and Full, `fidoClient` and `protectReady` are created at module scope; in Full, `idpClient` is created at module scope.

---

## D4 - Overwrite `App.tsx`

Wrap a single `NavigationContainer` in `DaVinciProvider`. Pass the **config**, never a client (the opposite of `JourneyProvider client={...}`).

```tsx
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { DaVinciProvider } from '@ping-identity/rn-davinci';
import { davinciConfig } from './src/<AppName>DaVinciConfig';
import { DaVinciLoginScreen } from './src/screens/DaVinciLoginScreen';
import { DaVinciHomeScreen } from './src/screens/DaVinciHomeScreen';

export type RootStackParamList = {
  DaVinciLogin: undefined;
  DaVinciHome: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function App() {
  return (
    <DaVinciProvider config={davinciConfig}>
      <NavigationContainer>
        <Stack.Navigator initialRouteName="DaVinciLogin">
          <Stack.Screen
            name="DaVinciLogin"
            component={DaVinciLoginScreen}
            options={{ headerShown: false }}
          />
          <Stack.Screen
            name="DaVinciHome"
            component={DaVinciHomeScreen}
            options={{ title: 'Profile' }}
          />
        </Stack.Navigator>
      </NavigationContainer>
    </DaVinciProvider>
  );
}
```

Importing `./src/<AppName>DaVinciConfig` here is what runs the module-scope integration setup from D3 before any screen can call `start()`. Screens call `useDaVinci()` with no argument and read the client from the provider. Navigate with `replace` (`navigation.replace('DaVinciHome')` after success, `navigation.replace('DaVinciLogin')` after logout) so the back button cannot return to the auth screen.

**Acceptance:** exactly one `NavigationContainer`; `DaVinciProvider config={davinciConfig}` sits above it; no `client=` prop on the provider.

---

## D5 - Install command and tier prerequisites

Run from `<projectDir>` with the Bash tool. The base command is the same for every tier:

```bash
npm install @ping-identity/rn-core@1.1.0 @ping-identity/rn-davinci@1.1.0 @react-navigation/native @react-navigation/native-stack react-native-screens react-native-safe-area-context
```

Append packages by tier and by W3 choices:

| Selection | Append |
|---|---|
| `standard` | `@ping-identity/rn-fido@1.1.0 @ping-identity/rn-protect@1.1.0` |
| `full` | the Standard packages plus `@ping-identity/rn-external-idp@1.1.0` |
| `storage` chosen in W3 | `@ping-identity/rn-storage@1.1.0` |
| `logger` chosen in W3 | `@ping-identity/rn-logger@1.1.0` |

The install list must contain exactly the tier's packages. Then apply the Baseline section of [platform-setup.md](platform-setup.md) (iOS 16.0: the Podfile platform line, the Podfile post_install raise for pod targets, and the app-target `IPHONEOS_DEPLOYMENT_TARGET`; Android `minSdkVersion = 29`; the Android JVM-target flags) and run `cd ios && pod install`. The native versions and JVM target that `rn-davinci` wraps are listed in the "Native dependencies" section of [davinci-client.md](davinci-client.md).

A plain DaVinci flow needs **no** redirect wiring: no `manifestPlaceholders`, no `CustomTabActivity` intent filter, no `CFBundleURLTypes`. Redirect wiring appears below only for the Social Login integration.

**Standard prerequisites.**

*FIDO (`rn-fido`).* Apply the app setup in the FIDO section of [platform-setup.md](platform-setup.md) yourself (Play Services dependencies, Associated Domains, `NSFaceIDUsageDescription`); passkeys fail at runtime without it. The server-side items that section lists (Digital Asset Links, the Apple App Site Association file, the RP origin domains) are the user's to complete: tell the user, and do not invent a console path. The only DaVinci-specific part is the call shape (`registerForDaVinci` / `authenticateForDaVinci`, wired in D3).

*Protect (`rn-protect`).* Run `cd ios && pod install` after installing the package. `startProtect({ envId })` with the PingOne environment ID must resolve before the first DaVinci operation (wired in D3).

**Full prerequisites** (`rn-external-idp`). Apply the Social login section of [platform-setup.md](platform-setup.md): the redirect scheme, the Android provider SDK dependencies, the iOS provider pods (then run `cd ios && pod install` again, because the first one ran before the pods were added), and the Google and Facebook callback routing. Add only the providers the flow uses; ask the user if you do not know which. The provider console setup is the user's to complete: tell the user. DaVinci-specific behavior: without a linked provider SDK, DaVinci falls back to browser sign-in; the redirect scheme is the only redirect wiring in a DaVinci scaffold.

**Acceptance:** the install command lists exactly the tier's packages; Basic applies no integration setup; Standard has applied the FIDO and Protect sections of `platform-setup.md`; Full has additionally applied the Social login section, including the second `pod install` after the provider pods are added to the `Podfile`; the user has been told about the server-side and provider console items.
