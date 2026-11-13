# DaVinci Client Reference

## `createDaVinciClient(config)`

Creates a native-backed DaVinci client. Call at module scope or in a stable app-level singleton, never inside a component body.

```ts
import { createDaVinciClient, type DaVinciConfig } from '@ping-identity/rn-davinci';

const config: DaVinciConfig = {
  modules: {
    oidc: {
      discoveryEndpoint: 'https://auth.example.com/.well-known/openid-configuration',
      clientId: 'my-client-id',
      redirectUri: 'myapp://callback',
    },
  },
};

const daVinciClient = createDaVinciClient(config);
```

Throws `DaVinciError` with code `DAVINCI_CONFIG_ERROR` (type `argument_error`) when `modules.oidc.discoveryEndpoint`, `modules.oidc.clientId`, or `modules.oidc.redirectUri` is missing or empty, or when a `storage` handle is present but has an invalid shape.

Most apps do not call this factory directly: `DaVinciProvider` takes the config and builds the client internally (see [DaVinciProvider](#davinciprovider)). Use `createDaVinciClient` only for the client-based pattern described in that section.

---

## `DaVinciConfig`

```ts
type DaVinciConfig = {
  timeout?: number;          // Network timeout in ms. Default: 15000
  logger?:   LoggerInstance; // From @ping-identity/rn-logger
  modules: {
    oidc: DaVinciOidcModuleConfig;  // Required. See table below
  };
};
```

All OIDC identity fields live under `modules.oidc`. The `openId` manual endpoint override available to the OIDC package is intentionally not exposed here: DaVinci's native OIDC path always resolves endpoints through discovery.

### `modules.oidc` fields

| Field                 | Type                      | Required | Notes |
|-----------------------|---------------------------|----------|-------|
| `discoveryEndpoint`   | `string`                  | Yes      | PingOne environment `.well-known/openid-configuration` URL. The flow entry point is resolved from it; there is no separate flow name |
| `clientId`            | `string`                  | Yes      | OAuth2 client registered with the PingOne environment |
| `redirectUri`         | `string`                  | Yes      | Must match the DaVinci application's configured redirect URI. Used inside the flow-resident authorize request, not for OS-level navigation (see [No browser redirect wiring needed](#no-browser-redirect-wiring-needed)) |
| `scopes`              | `string[]`                | No       | Native default is an empty scope set on both platforms when omitted |
| `storage`             | `OidcStorageHandle`       | No       | Token storage handle from `configureOidcStorage()` in `@ping-identity/rn-storage`. A malformed handle throws `DAVINCI_CONFIG_ERROR` |
| `acrValues`           | `string`                  | No       | Authentication context class reference values |
| `signOutRedirectUri`  | `string`                  | No       | Post-logout redirect |
| `state`               | `string`                  | No       | OAuth2 state parameter |
| `nonce`               | `string`                  | No       | OAuth2 nonce parameter |
| `uiLocales`           | `string`                  | No       | Preferred UI locales |
| `refreshThreshold`    | `number`                  | No       | Token refresh threshold in seconds |
| `loginHint`           | `string`                  | No       | Pre-fill login identifier |
| `display`             | `string`                  | No       | OIDC display parameter |
| `prompt`              | `string`                  | No       | OIDC prompt parameter |
| `par`                 | `boolean`                 | No       | Pushed authorization requests |
| `additionalParameters`| `Record<string, string>`  | No       | Extra authorization parameters forwarded to the native config |

Example:

```ts
import { logger } from '@ping-identity/rn-logger';
import { configureOidcStorage } from '@ping-identity/rn-storage';
import { createDaVinciClient } from '@ping-identity/rn-davinci';

const client = createDaVinciClient({
  timeout: 20000,
  logger: logger({ level: 'debug' }),
  modules: {
    oidc: {
      discoveryEndpoint: 'https://auth.example.com/.well-known/openid-configuration',
      clientId: 'my-client-id',
      redirectUri: 'myapp://callback',
      scopes: ['openid', 'profile'],
      storage: configureOidcStorage({ android: { keyAlias: 'davinci_key' } }),
    },
  },
});
```

---

## `DaVinciClient` Methods

| Method | Signature | Description |
|---|---|---|
| `start` | `(options?: DaVinciStartOptions) => Promise<DaVinciNode>` | Start the flow. The entry point is determined by the discovery URL in config, so no flow name is passed at runtime. Each call starts a fresh flow |
| `next` | `(input: DaVinciNextInput) => Promise<DaVinciNode>` | Apply key-indexed collector values and advance the flow |
| `validate` | `(collectorKey: string, value: unknown) => Promise<DaVinciFieldValidationError[]>` | Update and validate one collector without advancing (command-query, see below) |
| `user` | `() => Promise<DaVinciUserSession \| null>` | Resolve active session |
| `refresh` | `() => Promise<DaVinciUserSession \| null>` | Refresh access token |
| `revoke` | `() => Promise<boolean>` | Revoke access/refresh tokens |
| `userinfo` | `() => Promise<Record<string, unknown> \| null>` | Fetch userinfo claims |
| `logoutUser` | `() => Promise<void>` | Log out and clear session |
| `dispose` | `() => Promise<void>` | Release the native instance and runtime state |
| `getId` | `() => Promise<string>` | Native instance id used by cross-module integrations to target this client |
| `pollStatus` | `(onStatus, options?) => Promise<() => void>` | Stream `PollingStatus` updates (see below) |

`start()` takes no flow name: the flow is resolved from the discovery endpoint in config.

---

## `DaVinciStartOptions` (RFC 8628 device approval)

```ts
type DaVinciStartOptions = {
  verificationUri?: string;  // RFC 8628 verification_uri_complete URL
};
```

Pass `verificationUri` when this device is the approving device in an RFC 8628 device authorization grant: the DaVinci flow extracts the `user_code` from the URL and approves the requesting device. Requires native SDK 2.1.0 or later on both platforms.

```ts
import { useDaVinci } from '@ping-identity/rn-davinci';

const { start } = useDaVinci();

await start({ verificationUri: 'https://example.com/device?user_code=WDJB-MJHT' });
```

---

## Key-indexed `next()` input

DaVinci submits values **keyed by `collector.key`** from the active `ContinueNode`:

```ts
type DaVinciNextInput = {
  collectors: DaVinciCollectorInput[];
};

type DaVinciCollectorInput = {
  /** Collector key from the active ContinueNode. */
  key: string;
  /** Value to apply to the collector. */
  value: unknown;
};
```

---

## `validate(key, value)` is a command-query

`validate()` is not a pure check. Neither native SDK exposes a primitive that validates a candidate value without first setting it, so the bridge **writes `value` onto the live collector** backing the in-progress submission. The value passed in *will* be part of what a subsequent `next()` submits, even if the caller only intended a speculative check.

An empty result array means either "no validation errors" or "this collector has no validator"; it is not a positive confirmation that the value was checked.

Validation errors arrive as structured objects, so consumers never parse localized messages:

| Code | Extra fields |
|---|---|
| `REQUIRED` | none |
| `REGEX_ERROR` | `message` |
| `INVALID_LENGTH` | `min`, `max` |
| `UNIQUE_CHARACTER` | `min` |
| `MAX_REPEAT` | `max` |
| `MIN_CHARACTERS` | `character`, `min` |

---

## `pollStatus(onStatus, options?)`

Streams `PollingStatus` updates for the active `PollingCollector` on the current node:

```ts
type PollingStatus =
  | { status: 'continue'; retryCount: number; maxRetries: number }
  | { status: 'complete'; value: string }
  | { status: 'timedOut' }
  | { status: 'expired' }
  | { status: 'error'; error: { message: string } };
```

Contract (verbatim from the bridge implementation):

- **Does not auto-advance the flow.** The consumer must call `next()` explicitly on any terminal status (`complete`, `timedOut`, `expired`, `error`) to progress past it.
- The returned unsubscribe function **stops local event delivery only**. Neither native SDK exposes a primitive to cancel an in-flight poll, so the native poll keeps running to completion (bounded by `pollRetries` × `pollInterval`) even after unsubscribing.
- Terminal statuses self-remove the listener: no further ticks are emitted for the same subscription after one fires.
- `options.key` selects the collector when more than one `PollingCollector` is present on the active node; when omitted, the first one is resolved.

---

## `useDaVinci(client?)` Hook

```ts
import { createDaVinciClient, useDaVinci } from '@ping-identity/rn-davinci';

const daVinciClient = createDaVinciClient(config); // config from the DaVinciConfig section

// With explicit client (local screen state):
const { node, start, next } = useDaVinci(daVinciClient);

// Without client (reads from nearest DaVinciProvider):
const { node, start, next } = useDaVinci();
```

Throws `DaVinciError` with code `DAVINCI_STATE_ERROR` (type `state_error`) when called without a client and no `DaVinciProvider` is in scope.

Returns `DaVinciHookResult = DaVinciHookActions & { node: DaVinciNode | null }`.

### `DaVinciHookActions`

| Action | Signature | Description |
|---|---|---|
| `start` | `(options?) => Promise<DaVinciNode>` | Start the flow; sets `node` state |
| `next` | `(input: DaVinciNextInput) => Promise<DaVinciNode>` | Apply values and advance; updates `node` state |
| `validate` | `(key, value) => Promise<DaVinciFieldValidationError[]>` | Same command-query semantics as the client method |
| `user` | `() => Promise<DaVinciUserSession \| null>` | Resolve active session |
| `refresh` | `() => Promise<DaVinciUserSession \| null>` | Refresh tokens |
| `revoke` | `() => Promise<boolean>` | Revoke tokens |
| `userinfo` | `() => Promise<Record<string, unknown> \| null>` | Fetch userinfo |
| `logoutUser` | `() => Promise<void>` | Log out and clear session state |
| `pollStatus` | `(onStatus, options?) => Promise<() => void>` | Stream polling status (same contract as the client method) |
| `dispose` | `() => Promise<void>` | Dispose native client; resets `node` and `error` |
| `loading` | `boolean` | True while `start`/`next` is in flight |
| `error` | `DaVinciError \| null` | Last hook-level error |

`loading` and `error` are scoped to the node-rendering state machine. Session operations (`user`, `refresh`, `revoke`, `userinfo`, `logoutUser`, `dispose`) resolve through their returned `Promise`; manage per-operation loading and error feedback locally when needed.

The hook does not auto-advance nodes: progression policy is app-controlled through explicit `next()` calls.

---

## `DaVinciProvider`

Shares one `useDaVinci` state instance (and one client) across a component subtree.

```tsx
import { DaVinciProvider, useDaVinci } from '@ping-identity/rn-davinci';

<DaVinciProvider config={davinciConfig}>
  <LoginScreen />
</DaVinciProvider>

// In any descendant:
const { node, next } = useDaVinci(); // no client arg needed
```

Props:

```ts
type DaVinciProviderProps = {
  config:   DaVinciConfig;   // Provider builds the client from this config
  children: React.ReactNode;
};
```

### Provider-based vs client-based apps

`DaVinciProvider` takes the **config** and builds the client internally. This is the opposite of `JourneyProvider`, which takes an already-created `client`. Pick one pattern per app and do not mix them:

**Provider-based (recommended for multi-screen apps).** Define the config at module scope, wrap the tree with `<DaVinciProvider config={davinciConfig}>`, and call `useDaVinci()` with no argument in screens.

```ts
// src/MyAppDaVinciConfig.ts
import type { DaVinciConfig } from '@ping-identity/rn-davinci';

export const davinciConfig: DaVinciConfig = {
  modules: {
    oidc: {
      discoveryEndpoint: 'https://auth.example.com/.well-known/openid-configuration',
      clientId: 'my-client-id',
      redirectUri: 'myapp://callback',
    },
  },
};
```

**Client-based.** Create the client once at module scope with `createDaVinciClient(config)` and pass it to `useDaVinci(client)`. Never create the client inside a component body.

### Obtaining the client for integration calls

Integration operations take the live `DaVinciClient` (or a matching instance contract) as their first argument: `collectProtect(daVinci)`, `fido.registerForDaVinci(daVinci, ...)`, `fido.authenticateForDaVinci(daVinci, ...)`, `externalIdp.authorizeForDaVinci(daVinci, ...)`.

- In a provider-based app, get the shared client from `useDaVinciContext()?.client` and guard for `null`:

  ```ts
  import { useDaVinciContext } from '@ping-identity/rn-davinci';

  const davinciContext = useDaVinciContext();
  const daVinciClient = davinciContext?.client;
  if (!daVinciClient) {
    throw new Error('DaVinci client unavailable: missing DaVinciProvider');
  }
  ```

  Do not create a second client with `createDaVinciClient` in integration code: the integration call must target the same native instance the flow is running on.

- In a client-based app, reference the module-scope client directly.

`useDaVinciContext()` returns the context value (`{ client, davinci }`) or `null` when called outside a provider. Reference wiring: `PingSampleApp/ui/davinci/hooks/useDaVinciClientPanelController.ts` in the React Native SDK repository.

---

## `useDaVinciForm(node, options?)`

Headless form helper over the active `ContinueNode`: normalizes collectors, seeds defaults, tracks values, and builds the submit payload. `node` and `next` come from `useDaVinci()`:

```ts
import { useDaVinci, useDaVinciForm } from '@ping-identity/rn-davinci';

const { node, next } = useDaVinci();
const form = useDaVinciForm(node);

form.canSubmit;             // payload readiness
form.input;                 // DaVinciNextInput built from node + values
await next(form.input);     // submit through useDaVinci
```

### `DaVinciFormOptions`

```ts
type DaVinciFormOptions = {
  handledCollectorTypes?: ReadonlySet<string>; // Integration types already handled by the app
  next?: (input: DaVinciNextInput) => Promise<DaVinciNode>; // Required for flow-advancing calls outside a provider
};
```

When `next` is omitted and no `DaVinciProvider` context exists, the flow-advancing paths (`submitFlow` and FlowCollector auto-submit in `setValue`) throw `DaVinciError`. Value management still works without `next`.

### `DaVinciNormalizedCollector`

`form.fields` entries are `DaVinciNormalizedCollector`: the raw collector union enriched with UI-helper metadata.

```ts
type DaVinciNormalizedCollector =
  | (TextCollector & { kind: 'text'; ... })
  | (PasswordCollector & { kind: 'password'; ... })
  /* ... one member per collector shape ... */
  | (IntegrationCollector & { kind: 'integration'; ... })
  | (IntegrationCollector & { kind: 'unknown'; ... });
```

Each member carries:

| Field | Type | Description |
|---|---|---|
| `kind` | `DaVinciFieldKind` | UI-oriented discriminant: `'text' \| 'password' \| 'boolean' \| 'singleSelect' \| 'multiSelect' \| 'phone' \| 'device' \| 'output' \| 'polling' \| 'qrCode' \| 'flow' \| 'integration' \| 'unknown'` |
| `executionMode` | `DaVinciExecutionMode` | `'manual' \| 'output_only' \| 'immediate' \| 'integration_required' \| 'unsupported'` |
| `requiresUserInput` | `boolean` | `true` only when `executionMode === 'manual'` |
| `defaultValue` | `DaVinciFormValue` (optional) | Server-seeded default, present when the collector has one |

Narrow on `kind` before accessing fields outside the generic integration contract.

### `DaVinciFormResult`

| Member | Description |
|---|---|
| `fields` | `DaVinciNormalizedCollector[]` for the active `ContinueNode` (each carries `kind`, `executionMode`, `requiresUserInput`, optional `defaultValue`) |
| `values` | Current value map keyed by `collector.key` |
| `input` | Submit payload derived from `node + values` |
| `canSubmit` | Whether `input` can be safely submitted |
| `issues` | Planning issues (`NO_ACTIVE_CONTINUE_NODE`, `REQUIRED_VALUE_MISSING`, `UNSUPPORTED_COLLECTOR`, `INTEGRATION_REQUIRED`) |
| `meta` | Aggregate flags: `hasManual`, `hasOutputOnly`, `hasAutoCapable` (always `false`), `hasIntegrationRequired`, `hasUnsupported` |
| `setValue(key, value)` | Sets one value. On a FlowCollector key (`ACTION`, `FLOW_BUTTON`, `FLOW_LINK`) it immediately calls `next()` with only that key (submitting the supplied value without storing it, see the value rule below), bypassing all other field values, and returns the pending `Promise<DaVinciNode>` |
| `setValues(updater)` | Merges a patch object or updater function |
| `clearValue(key)` | Removes one value |
| `reset(nextValues?)` | Resets the map and reapplies collector defaults |
| `buildInput(overrides?)` | Fresh submit plan for the current node |
| `getField(key)` / `getFieldsByType(type)` / `getFieldByType(type, typeIndex?)` | Field lookups |
| `setValueByType(type, value, typeIndex?)` | Sets by type string; delegates to `setValue` (same auto-submit rule) |
| `submitFlow(flowKey)` | Explicit FlowCollector submission: builds a single-entry payload for that key and returns the next node (value rule below) |

The form auto-resets when the node object identity changes, so a node transition clears stale values.

### `DaVinciSubmitIssue`

`form.issues` (and `buildInput(overrides?).issues`) entries are `DaVinciSubmitIssue` records:

```ts
type DaVinciSubmitIssue = {
  code: DaVinciSubmitIssueCode;
  message: string;
  key?: string;  // Collector key associated with the issue, when applicable
};
```

| `code` | Blocking | Meaning |
|---|---|---|
| `NO_ACTIVE_CONTINUE_NODE` | yes | No active node; call `start()` first |
| `REQUIRED_VALUE_MISSING` | yes | Required manual collector has no value |
| `INTEGRATION_REQUIRED` | yes | Integration collector type absent from `handledCollectorTypes` |
| `UNSUPPORTED_COLLECTOR` | no | Type not recognized by the helper submit builder; reported for visibility, does not block `canSubmit` |

### FlowCollector value rule

For flow keys (`ACTION`, `FLOW_BUTTON`, `FLOW_LINK`), both `submitFlow(key)` and the `setValue` auto-submit path send the form value stored under that key if one exists, falling back to the key itself as the value. The two paths differ in how the value gets there:

- `setValue(key, 'custom')` on a flow key **submits immediately with `'custom'` without storing it**: the flow branch returns the pending `Promise<DaVinciNode>` before any state update, so `form.values` never contains the flow key. The payload carries `'custom'` for that one call only.
- `submitFlow(key)` sends whatever is already stored under `key` (normally nothing, so `value: key`); it never writes a value either.

In both cases the payload is a single entry for that key; all other field values are bypassed.

The `handledCollectorTypes` set suppresses `INTEGRATION_REQUIRED` issues for collector types the app handles through an integration package. See [davinci-collectors.md](davinci-collectors.md).

---

## `DaVinciNode` Shape

```ts
type DaVinciNode = ContinueNode | SuccessNode | ErrorNode | FailureNode;
```

| Field | Node types | Description |
|---|---|---|
| `type` | all | `'ContinueNode'` \| `'SuccessNode'` \| `'ErrorNode'` \| `'FailureNode'` |
| `collectors` | ContinueNode | Collector list for this step |
| `unsupportedFields` | ContinueNode | Optional. Fields the native SDK could not instantiate; each entry has `key` and `type`. Render a placeholder, log, or block submission when present |
| `id` | ContinueNode | Optional connector id from the server payload |
| `name` / `description` / `category` | ContinueNode | Optional form step metadata |
| `input` | ContinueNode, ErrorNode | Optional full server `input` payload |
| `session` | SuccessNode | `{ value: string }` token payload |
| `message` | ErrorNode, FailureNode | Human-readable message |
| `status` | ErrorNode | HTTP status code. **iOS only**: absent on Android (parity gap) |
| `cause` | FailureNode | Optional failure reason |

---

## `DaVinciError`

```ts
import { DaVinciError, useDaVinci } from '@ping-identity/rn-davinci';

const { start } = useDaVinci();

try {
  await start();
} catch (err) {
  if (err instanceof DaVinciError) {
    console.log(err.code, err.type, err.message);
  }
}
```

`DaVinciError` extends `PingError` (which extends `Error`). Stable codes:

```ts
type DaVinciErrorCode =
  | 'DAVINCI_CONFIG_ERROR'               // createDaVinciClient: missing/invalid modules.oidc fields
  | 'DAVINCI_INIT_ERROR'                 // native workflow construction failure
  | 'DAVINCI_START_ERROR'                // start()
  | 'DAVINCI_NEXT_ERROR'                 // next(): flow progression failure
  | 'DAVINCI_COLLECTOR_APPLY_ERROR'      // next(): collector value application failure (e.g. wrong key)
  | 'DAVINCI_UNSUPPORTED_COLLECTOR_ERROR'// unsupported collector mutation request
  | 'DAVINCI_VALIDATE_ERROR'             // validate(): collector validation failure
  | 'DAVINCI_SESSION_ERROR'              // user() / refresh() / revoke() / userinfo()
  | 'DAVINCI_LOGOUT_ERROR'               // logoutUser()
  | 'DAVINCI_DISPOSE_ERROR'              // dispose()
  | 'DAVINCI_POLL_ERROR'                 // pollStatus(): poll start/subscription failure
  | 'DAVINCI_ARGUMENT_ERROR'             // invalid argument at the call site
  | 'DAVINCI_STATE_ERROR'                // operation on invalid state (e.g. no active node/client)
  | 'DAVINCI_MISSING_INTEGRATION_ERROR'  // collector requires an additional module integration
  | 'DAVINCI_UNKNOWN_ERROR'              // catch-all
  | (string & {});                       // native codes passed through as-is
```

---

## Session Types

```ts
type DaVinciUserSession = {
  accessToken:   string;
  refreshToken?: string;
  expiresIn?:    number;  // Seconds
};
```

`userinfo()` returns the raw claims payload as `Record<string, unknown> | null` (no dedicated type is exported for it).

---

## Native dependencies

`@ping-identity/rn-davinci` 1.1.0 wraps native Ping SDK 2.1.0:

- **Android**: `com.pingidentity.sdks:davinci:2.1.0`; JVM target 21; `minSdkVersion 29`; `compileSdkVersion 36`
- **iOS**: pods `PingDaVinci`, `PingDaVinciPlugin`, `PingOrchestrate`, `PingOidc`, `PingStorage`, `PingLogger` at 2.1.0; platform minimum iOS 16.0

---

## No browser redirect wiring needed

A plain DaVinci flow does not launch a browser. The flow returns the OAuth2 `authorizeResponse` in its own payload (the native SDK's `pi.flow` handling does not use a redirect), so no `manifestPlaceholders` entry, `CustomTabActivity` intent filter, or `CFBundleURLTypes` registration is required for core DaVinci collectors.

`redirectUri` is still required config: it participates in the flow-resident authorize request, not in OS-level navigation.

The exception is the Social Login integration (`@ping-identity/rn-external-idp`): when social login is used, Android needs `manifestPlaceholders["appRedirectUriScheme"]` in `android/app/build.gradle` so the OS can return to the app on devices that fall back to Custom Tabs, and iOS needs the custom scheme registered under `CFBundleURLTypes` in `Info.plist`. See [davinci-collectors.md](davinci-collectors.md).

---

## Known parity gaps

- **Android `QRCodeCollector.key` is `""`** until the native SDK exposes it: the server sends the key in the raw field JSON, but the native Android collector's `init()` never reads it and its `id()` falls back to a fresh random UUID on every call. iOS parses the key and is unaffected.
- **`ErrorNode.status` is absent on Android.** The native iOS `ErrorNode` carries the HTTP status from the server response; the Android SDK does not expose it.
- **Regex anchoring differs on unanchored patterns.** Android (`Regex.matches()`) requires the pattern to match the entire value; iOS (`NSRegularExpression.firstMatch`) accepts a match anywhere. Anchored patterns (e.g. `^valid$`) behave identically. An unanchored `validation.regex` on a `TEXT`/`PASSWORD` collector can therefore accept a value on iOS that Android rejects.
