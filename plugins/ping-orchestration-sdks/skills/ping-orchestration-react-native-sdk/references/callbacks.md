# Callback Reference

## Callback Shape

Every callback in `node.callbacks` has this base shape:

```ts
type JourneyCallback = {
  type:     JourneyCallbackType; // e.g. 'NameCallback'
  prompt?:  string;              // User-facing label/prompt from server
  message?: string;              // Optional message from server
  value?:   unknown;             // Optional default/current value
  [key: string]: unknown;        // Additional native metadata
};
```

Discriminate on `cb.type` to render the correct input field.

---

## Callback Type Reference

### Basic Tier — username / password flows

| Callback type | Input to `next()` | Notes |
|---|---|---|
| `NameCallback` | `{ type: 'NameCallback', value: string }` | Username / email field |
| `PasswordCallback` | `{ type: 'PasswordCallback', value: string }` | Password field — never log the value |
| `TextInputCallback` | `{ type: 'TextInputCallback', value: string }` | Generic text field; `cb.prompt` is the label |
| `TextOutputCallback` | No input — output only | Display `cb.message`; no submit needed |
| `ChoiceCallback` | `{ type: 'ChoiceCallback', value: number }` | Selected option index (0-based); options list in `cb.choices` |
| `ConfirmationCallback` | `{ type: 'ConfirmationCallback', value: number }` | Button index; button labels in `cb.options` |

### Standard Tier — account attributes, device, FIDO, Protect

| Callback type | Input to `next()` | Notes |
|---|---|---|
| `ValidatedCreateUsernameCallback` | `{ type: 'ValidatedCreateUsernameCallback', value: string }` | Policy-validated username |
| `ValidatedCreatePasswordCallback` | `{ type: 'ValidatedCreatePasswordCallback', value: string }` | Policy-validated password |
| `StringAttributeInputCallback` | `{ type: 'StringAttributeInputCallback', value: string }` | Single string attribute field |
| `NumberAttributeInputCallback` | `{ type: 'NumberAttributeInputCallback', value: number }` | Numeric attribute field |
| `BooleanAttributeInputCallback` | `{ type: 'BooleanAttributeInputCallback', value: boolean }` | Boolean toggle |
| `TermsAndConditionsCallback` | `{ type: 'TermsAndConditionsCallback', value: boolean }` | Must be `true` to proceed; `cb.terms` is the T&C text |
| `KbaCreateCallback` | `{ type: 'KbaCreateCallback', value: { selectedQuestion: string, selectedAnswer: string, allowUserDefinedQuestions: boolean }, index: number }` | KBA question + answer pair; `index` differentiates multiple instances on the same node |
| `PollingWaitCallback` | No input — auto-advancing | Poll server; re-call `next({})` after `cb.waitTime` ms |
| `DeviceProfileCallback` | No input — auto-advancing | Collect device profile; requires `@ping-identity/rn-device-profile` |
| `DeviceBindingCallback` | No input — integration-required | Device binding; requires `@ping-identity/rn-binding` |
| `DeviceSigningVerifierCallback` | No input — integration-required | Device signing; requires `@ping-identity/rn-binding` |
| `FidoRegistrationCallback` | No input — integration-required | FIDO2 registration; requires `@ping-identity/rn-fido` |
| `FidoAuthenticationCallback` | No input — integration-required | FIDO2 authentication; requires `@ping-identity/rn-fido` |
| `PingOneProtectInitializeCallback` | No input — auto-advancing | Initialize Protect SDK; ⚠️ not yet supported in `@ping-identity/rn-*` — render `UnsupportedCallbackView` |
| `PingOneProtectEvaluationCallback` | No input — auto-advancing | Evaluate Protect risk signal; ⚠️ not yet supported in `@ping-identity/rn-*` — render `UnsupportedCallbackView` |
| `ConsentMappingCallback` | `{ type: 'ConsentMappingCallback', value: boolean }` | Consent grant |

### Full Tier — social login

| Callback type | Notes |
|---|---|
| `SelectIdpCallback` | Social IdP selector; `value` is the provider id string; requires `@ping-identity/rn-external-idp` |
| `IdpCallback` | Handles the OAuth redirect after IdP selection; always paired with `SelectIdpCallback`; requires `@ping-identity/rn-external-idp` |
| `ReCaptchaEnterpriseCallback` | reCAPTCHA Enterprise token; ⚠️ not yet supported in `@ping-identity/rn-*` — render `UnsupportedCallbackView` |

---

## Execution Mode Classification

When building a callback renderer, callbacks fall into four execution modes:

| Mode | What it means | UI action |
|---|---|---|
| `manual` | User must enter a value | Render an input field; show Next button |
| `output_only` | Display content only, no input | Render text; no input or Next needed for this callback |
| `auto_capable` | Can be executed automatically without user interaction | Auto-call `next({})` after a delay or native op — do not show Next button |
| `integration_required` | Requires a native SDK operation (FIDO, Binding, DeviceProfile) | Call the relevant SDK method, then call `next({})` |

**Auto-capable callbacks** (auto-advance after native op or timeout):
- `PollingWaitCallback` — wait `cb.waitTime` ms, then call `next({})`
- `PingOneProtectInitializeCallback` — initialize, then `next({})` ⚠️ not yet supported in `@ping-identity/rn-*`
- `PingOneProtectEvaluationCallback` — evaluate, then `next({})` ⚠️ not yet supported in `@ping-identity/rn-*`

**Integration-required callbacks** (call native SDK first, then `next({})`):
- `FidoRegistrationCallback` — `fidoClient.registerForJourney(...)`
- `FidoAuthenticationCallback` — `fidoClient.authenticateForJourney(...)`
- `DeviceProfileCallback` — device-profile collection
- `DeviceBindingCallback` / `DeviceSigningVerifierCallback` — binding SDK ops
- `SelectIdpCallback` / `IdpCallback` — external IdP OAuth redirect; requires `@ping-identity/rn-external-idp`

---

## FIDO Integration Pattern

```bash
npm install @ping-identity/rn-fido
cd ios && pod install
```

```tsx
import { createFidoClient } from '@ping-identity/rn-fido';

const fidoClient = createFidoClient();

// FidoRegistrationCallback — first arg is the JourneyClient (journey), not cb:
await fidoClient.registerForJourney(journey, {
  index: field.ref.typeIndex, // per-type callback index from useJourneyForm
  deviceName: 'My Phone',     // display name for the passkey
});
await next({});

// FidoAuthenticationCallback:
await fidoClient.authenticateForJourney(journey, {
  index: field.ref.typeIndex,
});
await next({});
```

`fidoIntegration` helper — when using `useJourneyForm`, pass a `fidoIntegration(fidoClient, options)` descriptor to the auto-forwarder to handle FIDO callbacks automatically. See Advanced Patterns below.

---

## Device Binding Integration Pattern

Device binding is `integration_required` — call the native SDK operation, then call `next({})`. Both `DeviceBindingCallback` and `DeviceSigningVerifierCallback` follow this pattern.

```bash
npm install @ping-identity/rn-binding
cd ios && pod install
```

`createBindingClient` is synchronous — create at module scope:

```ts
import { createBindingClient } from '@ping-identity/rn-binding';

const bindingClient = createBindingClient();
```

### Basic Pattern

First arg is the JourneyClient (`journey`), not `cb`. `index` is the per-type callback index — use `field.ref.typeIndex` from `useJourneyForm`:

```tsx
// DeviceBindingCallback — registers a new device key
await bindingClient.bindForJourney(journey, {
  index: field.ref.typeIndex,
  deviceName: 'My Phone',     // optional; SDK uses device default if omitted
});
await next({});

// DeviceSigningVerifierCallback — signs a challenge with an existing key
// PIN collection is handled natively — no pinCollector needed
await bindingClient.signForJourney(journey, { index: field.ref.typeIndex });
await next({});
```

### User Key Selection

When multiple device keys are registered, supply a `userKeySelector` to let the user pick which one to use during signing:

```ts
const bindingClient = createBindingClient({
  ui: {
    userKeySelector: async (keys) => {
      // keys: UserKeyOption[] — { id, userId, username, authenticationType }
      return await showKeyPicker(keys); // return the selected UserKeyOption
    },
  },
});
```

### Key Management

```ts
import { getAllKeys, deleteKey, deleteAllKeys } from '@ping-identity/rn-binding';

// List all registered device keys:
const keys = await getAllKeys();
// keys: UserKeyOption[] — { id, userId, username, authenticationType }

// Delete a specific key:
await deleteKey(keys[0]);

// Delete all keys:
await deleteAllKeys();
```

### `BindingConfig`

```ts
type BindingConfig = {
  logger?:         LoggerInstance;   // from @ping-identity/rn-logger
  ui?: {
    userKeySelector?:  (keys: UserKeyOption[]) => Promise<UserKeyOption>;
  };
  userKeyStorage?: UserKeyStorage;   // from configureBindingUserKeyStorage()
};
```

### `BindingError` Codes

| Code | Description |
|---|---|
| `BINDING_BIND_ERROR` | `bindForJourney` failed |
| `BINDING_SIGN_ERROR` | `signForJourney` failed |
| `BINDING_CANCELLED` | User cancelled the biometric / PIN prompt |
| `BINDING_UNSUPPORTED_DEVICE` | Device does not support the required authenticator |
| `BINDING_NOT_REGISTERED` | No key found for signing — device not bound |
| `BINDING_KEY_INVALIDATED` | Key was invalidated (e.g. biometric re-enrolment) |
| `BINDING_AUTH_FAILED` | Biometric / PIN authentication failed |
| `BINDING_KEY_READ_ERROR` | Key storage read error |
| `BINDING_KEY_DELETE_ERROR` | Key deletion failed |

---

## `useJourneyForm` — Advanced Submit Planning

> **Headless submit planner — used alongside `useJourney`, not instead of it.**
>
> `useJourneyForm` takes the `node` from `useJourney` as input and adds normalized field access, managed `values` state, a pre-built `input` payload, and `canSubmit` / `issues` validation. You still write all your own UI. `useJourney` owns the session lifecycle; `useJourneyForm` owns the form mechanics.
>
> ```tsx
> const [node, { start, next }] = useJourney(journeyClient); // drives Journey state machine
> const form = useJourneyForm(node);                          // wraps node for form helpers
>
> await next(form.input);                                     // form built the payload, Journey advances it
> ```
>
> **Use `useJourneyForm` when** you want the SDK to manage field state and build the submit payload — recommended for most flows. It handles KBA multi-index, T&C consent blocking, and `executionMode` classification automatically.
>
> **Use `useJourney` alone when** you need direct control over the payload or are building a fully custom renderer from scratch.

`useJourneyForm` normalizes `node.callbacks` into typed fields, manages form state, and validates submit readiness. Use it when:
- Your flow has consent/T&C callbacks that must be explicitly accepted before submission
- You need `executionMode` classification to drive auto-advancing callbacks
- You want built-in multi-callback submit planning without manual field tracking

```tsx
import { useJourney, useJourneyForm } from '@ping-identity/rn-journey';

function CallbackScreen() {
  const [node, { next }] = useJourney(journeyClient);

  const {
    fields,
    values,
    setValue,
    canSubmit,
    issues,
    input,
    meta,
  } = useJourneyForm(node, {
    handledCallbackTypes: new Set(['FidoRegistrationCallback', 'FidoAuthenticationCallback']),
  });

  return (
    <View>
      {fields.map((field) => {
        if (field.executionMode === 'output_only') {
          return <Text key={field.id}>{field.message ?? field.prompt}</Text>;
        }
        if (field.kind === 'password') {
          return (
            <TextInput
              key={field.id}
              secureTextEntry
              placeholder={field.prompt}
              onChangeText={(v) => setValue(field.id, v)}
            />
          );
        }
        return (
          <TextInput
            key={field.id}
            placeholder={field.prompt}
            value={String(values[field.id] ?? '')}
            onChangeText={(v) => setValue(field.id, v)}
          />
        );
      })}
      <Button
        title="Next"
        disabled={!canSubmit}
        onPress={() => next(input)}
      />
      {issues.map((issue) => (
        <Text key={issue.code} style={{ color: 'red' }}>{issue.message}</Text>
      ))}
    </View>
  );
}
```

### `useJourneyForm` Return Contract

| Field | Type | Description |
|---|---|---|
| `fields` | `JourneyNormalizedField[]` | Normalized callbacks for the active node |
| `values` | `JourneyFormValues` | Current form value map keyed by `field.id` |
| `input` | `JourneyNextInput` | Ready-to-submit payload derived from `node + values` |
| `canSubmit` | `boolean` | True when input can be safely passed to `next()` |
| `issues` | `JourneySubmitIssue[]` | Blocking / non-blocking validation issues |
| `meta` | `JourneyFormMeta` | Derived flags: `hasManual`, `hasOutputOnly`, `hasAutoCapable`, `hasIntegrationRequired`, `hasUnsupported`, `hasRequiredConsentMissing` |
| `setValue(id, value)` | — | Set one field value by normalized id |
| `setValues(updater)` | — | Merge one or more field values |
| `clearValue(id)` | — | Remove one field value |
| `reset(next?)` | — | Reset values and re-apply callback defaults |
| `buildInput(overrides?)` | `JourneyBuildNextInputResult` | Build a submit plan with optional value overrides |
| `getField(id)` | `JourneyNormalizedField \| undefined` | Look up one field by id |
| `getFieldsByType(type)` | `JourneyNormalizedField[]` | Look up fields by callback type |
| `getFieldByType(type, index?)` | `JourneyNormalizedField \| undefined` | Look up one field by type + per-type index |
| `setValueByType(type, value, index?)` | `boolean` | Set a field value by callback type + index; returns true if found |

### `JourneyNormalizedField` Shape

```ts
type JourneyNormalizedField = {
  id:              string;             // Stable opaque field key
  ref:             { type: JourneyCallbackType; typeIndex: number };
  prompt:          string;             // Label from callback payload
  message?:        string;
  required:        boolean;
  kind:            'text' | 'password' | 'number' | 'boolean' | 'choice' | 'kba' | 'output' | 'unknown';
  executionMode:   'manual' | 'auto_capable' | 'integration_required' | 'output_only' | 'unsupported';
  requiresUserInput: boolean;
  defaultValue?:   JourneyFormValue;
  options?:        Array<{ index: number; label: string; value: unknown }>;
  raw:             JourneyCallback;    // Original native callback payload
};
```

### `handledCallbackTypes` Option

Pass a `Set` of callback types that your app already handles via native integrations (e.g. FIDO, Binding). These are excluded from `issues` so `canSubmit` reports true readiness:

```ts
const form = useJourneyForm(node, {
  handledCallbackTypes: new Set([
    'FidoRegistrationCallback',
    'FidoAuthenticationCallback',
    'DeviceBindingCallback',
  ]),
});
```

### `JourneySubmitIssue` Codes

| Code | Description |
|---|---|
| `NO_ACTIVE_CONTINUE_NODE` | `next()` called with no active `ContinueNode` |
| `INTEGRATION_REQUIRED` | A callback requires a native integration not yet handled |
| `UNSUPPORTED_CALLBACK` | An unrecognized callback type is present |
| `REQUIRED_CONSENT_MISSING` | A `TermsAndConditionsCallback` or `ConsentMappingCallback` has not been accepted |
| `INVALID_VALUE` | A required field has an invalid or missing value |

---

## ChoiceCallback Pattern

```tsx
// cb.choices is an array of option strings
// Submit the zero-based selected index:
{cb.type === 'ChoiceCallback' && (
  cb.choices?.map((choice: string, i: number) => (
    <TouchableOpacity key={i} onPress={() => setSelectedChoice(i)}>
      <Text>{choice}</Text>
    </TouchableOpacity>
  ))
)}
// Submit: { type: 'ChoiceCallback', value: selectedChoiceIndex }
```

## TermsAndConditionsCallback Pattern

```tsx
// Must be accepted (value: true) for canSubmit to be true:
{cb.type === 'TermsAndConditionsCallback' && (
  <View>
    <Text>{cb.terms}</Text>
    <Switch
      value={Boolean(values[field.id])}
      onValueChange={(v) => setValue(field.id, v)}
    />
  </View>
)}
```

## PollingWaitCallback Pattern

```tsx
// Auto-advancing: wait cb.waitTime ms, then call next({})
useEffect(() => {
  if (cb.type === 'PollingWaitCallback') {
    const timer = setTimeout(async () => {
      await next({});
    }, cb.waitTime ?? 5000);
    return () => clearTimeout(timer);
  }
}, [cb]);
```

---

## Push MFA

Push MFA is a standalone module — it is independent of Journey callbacks and requires its own client lifecycle.

### Installation

```bash
npm install @ping-identity/rn-push
cd ios && pod install
```

### `PushConfig`

```ts
type PushConfig = {
  logger?:                    LoggerInstance;              // from @ping-identity/rn-logger
  storage?:                   PushStorageHandle;           // from @ping-identity/rn-storage
  enableCredentialCache?:     boolean;                     // default: false
  timeoutMs?:                 number;                      // default: 15000
  notificationCleanupConfig?: PushNotificationCleanupConfig;
  ios?: {
    encryptionEnabled?: boolean;                           // default: true; iOS only
  };
};

type PushNotificationCleanupConfig = {
  cleanupMode:             'NONE' | 'COUNT_BASED' | 'AGE_BASED' | 'HYBRID';
  maxStoredNotifications?: number;  // default: 100 — applies to COUNT_BASED / HYBRID
  maxNotificationAgeDays?: number;  // default: 30  — applies to AGE_BASED / HYBRID
};
```

### `PushNotification` Shape

```ts
type PushNotification = {
  id:               string;         // unique notification id
  credentialId:     string;         // enrolled credential this belongs to
  pushType:         'default' | 'challenge' | 'biometric' | string;
  ttl:              number;         // seconds
  messageId:        string;
  messageText:      string | null;  // display text
  challenge:        string | null;  // raw challenge string for 'challenge' type
  numbersChallenge: string | null;  // comma-separated numbers, e.g. "12,34,56"
  customPayload:    string | null;
  pending:          boolean;
  approved:         boolean;
  createdAt:        number;         // ms since epoch
  sentAt:           number | null;
  respondedAt:      number | null;
};
```

Use `getNumbersChallenge(notification)` to parse `numbersChallenge` into `number[]`.

### `usePush` Hook + `PushProvider`

```tsx
import { PushProvider, usePush, getNumbersChallenge } from '@ping-identity/rn-push';

// Option A: provider wraps the screen tree (shared state)
<PushProvider config={{ timeoutMs: 20000 }}>
  <PushScreen />
</PushProvider>

// In PushScreen (or any descendant):
function PushScreen() {
  const [data, { loading, error, refresh }] = usePush();
  // or usePush(config) to create a local client without PushProvider

  if (loading) return <ActivityIndicator />;
  if (error)   return <Text>{error.message}</Text>;

  const { client, credentials, deviceToken, pendingNotifications } = data!;
  // ...
}
```

`usePush` returns `readonly [PushData | null, PushActions]`.

`PushData`:

| Field | Type | Description |
|---|---|---|
| `client` | `PushClient` | Active client — use for mutations |
| `credentials` | `PushCredential[]` | All enrolled push credentials |
| `deviceToken` | `string \| null` | Current FCM/APNs device token |
| `pendingNotifications` | `PushNotification[]` | Notifications awaiting a response |
| `allNotifications` | `PushNotification[]` | All stored notifications |

`PushActions`:

| Field | Type | Description |
|---|---|---|
| `loading` | `boolean` | True while initialising or fetching |
| `error` | `PushError \| null` | Last error from client creation or data fetch |
| `refresh` | `() => Promise<void>` | Re-fetch all push data; call after mutations |

### Enrollment

```tsx
// Scan a QR code or receive a pushauth:// URI from the server
const credential = await client.addCredentialFromUri('pushauth://...');
await refresh(); // update displayed credential list
```

### Responding to Notifications

```tsx
const handleNotification = async (notification: PushNotification) => {
  switch (notification.pushType) {

    case 'default':
      // Simple approve/deny
      if (userApproved) {
        await client.approveNotification(notification.id);
      } else {
        await client.denyNotification(notification.id);
      }
      break;

    case 'challenge': {
      // Numbers matching — user selects the correct number
      const numbers = getNumbersChallenge(notification); // e.g. [12, 34, 56]
      const selected = await showNumbersPicker(numbers);  // your UI
      await client.approveChallengeNotification(notification.id, String(selected));
      break;
    }

    case 'biometric':
      await client.approveBiometricNotification(notification.id, 'biometric');
      break;

    default:
      await client.denyNotification(notification.id);
  }
  await refresh();
};
```

### Full Screen Pattern

```tsx
import React, { useEffect } from 'react';
import {
  View, Text, FlatList, Button, ActivityIndicator, TouchableOpacity
} from 'react-native';
import { PushProvider, usePush, getNumbersChallenge } from '@ping-identity/rn-push';

function PushNotificationScreen() {
  const [data, { loading, error, refresh }] = usePush();

  useEffect(() => {
    // Check for notifications that arrived before this screen mounted
    (async () => { await refresh(); })();
  }, []);

  if (loading) return <ActivityIndicator />;
  if (error)   return <Text style={{ color: 'red' }}>{error.message}</Text>;
  if (!data)   return null;

  const { client, pendingNotifications } = data;

  const approve = async (n: Parameters<typeof getNumbersChallenge>[0]) => {
    if (n.pushType === 'challenge') {
      const numbers = getNumbersChallenge(n);
      // show numbers picker; for simplicity approve first option:
      await client.approveChallengeNotification(n.id, String(numbers[0]));
    } else {
      await client.approveNotification(n.id);
    }
    await refresh();
  };

  const deny = async (id: string) => {
    await client.denyNotification(id);
    await refresh();
  };

  return (
    <FlatList
      data={pendingNotifications}
      keyExtractor={(n) => n.id}
      renderItem={({ item }) => (
        <View>
          <Text>{item.messageText ?? 'Authentication request'}</Text>
          <Button title="Approve" onPress={() => approve(item)} />
          <Button title="Deny"    onPress={() => deny(item.id)} />
        </View>
      )}
      ListEmptyComponent={<Text>No pending notifications</Text>}
    />
  );
}

// App root or navigator wrapper:
export default function App() {
  return (
    <PushProvider config={{ timeoutMs: 20000 }}>
      <PushNotificationScreen />
    </PushProvider>
  );
}
```

### `PushClient` Methods

| Method | Signature | Description |
|---|---|---|
| `addCredentialFromUri` | `(uri: string) => Promise<PushCredential>` | Enroll from `pushauth://` URI |
| `getCredentials` | `() => Promise<PushCredential[]>` | All enrolled credentials |
| `getCredential` | `(id: string) => Promise<PushCredential \| null>` | Single credential by id |
| `saveCredential` | `(c: PushCredential) => Promise<PushCredential>` | Persist updated credential |
| `deleteCredential` | `(id: string) => Promise<boolean>` | Remove enrollment |
| `approveNotification` | `(id: string) => Promise<boolean>` | Approve default notification |
| `approveChallengeNotification` | `(id, response: string) => Promise<boolean>` | Approve numbers challenge |
| `approveBiometricNotification` | `(id, method: string) => Promise<boolean>` | Approve biometric challenge |
| `denyNotification` | `(id: string) => Promise<boolean>` | Deny notification |
| `getPendingNotifications` | `() => Promise<PushNotification[]>` | Pending only |
| `getAllNotifications` | `() => Promise<PushNotification[]>` | All stored notifications |
| `getNotification` | `(id: string) => Promise<PushNotification \| null>` | Single notification |
| `cleanupNotifications` | `(credentialId?: string) => Promise<number>` | Run cleanup strategy; returns removed count |
| `getDeviceToken` | `() => Promise<string \| null>` | Current FCM/APNs token |
| `setDeviceToken` | `(token: string, credentialId?: string) => Promise<boolean>` | Update token (manual) |
| `refreshToken` | `() => Promise<string \| null>` | Force-refresh FCM/APNs token |
| `onTokenRegistered` | `(cb) => () => void` | Subscribe to token events; returns unsubscribe |
| `onNotification` | `(cb) => () => void` | Subscribe to incoming notifications; returns unsubscribe |
| `processNotification` | `(data: Record<string, unknown>) => Promise<PushNotification \| null>` | Parse raw message dict |
| `close` | `() => Promise<void>` | Release native resources |

---

## OATH (TOTP / HOTP)

OATH is a standalone module for managing software authenticator credentials. It is independent of Journey callbacks.

### Installation

```bash
npm install @ping-identity/rn-oath
cd ios && pod install
```

### `OathClientConfig`

```ts
type OathClientConfig = {
  logger?:               LoggerInstance;             // from @ping-identity/rn-logger
  timeout?:              number;                     // seconds; default: 15
  enableCredentialCache?: boolean;                   // default: false
  encryptionEnabled?:    boolean;                    // iOS only; default: true
  storage?:              OathStorageHandle;          // from @ping-identity/rn-storage
  policyEvaluator?:      OathPolicyEvaluatorHandle;  // from configureOathPolicyEvaluator()
};
```

### Creating a Client

```ts
import { createOathClient } from '@ping-identity/rn-oath';

const client = await createOathClient();          // native defaults
const client = await createOathClient({ timeout: 30, enableCredentialCache: true });
// Always close when done:
await client.close();
```

### Enrollment

```ts
// Parse an otpauth:// or mfauth:// URI and register the credential
const credential = await client.addCredentialFromUri('otpauth://totp/Example?secret=JBSWY3DPEHPK3PXP&issuer=Example');
```

Both `otpauth://` and `mfauth://` URI schemes are accepted.

### Generating TOTP Codes

```tsx
import { createOathClient } from '@ping-identity/rn-oath';
import React, { useEffect, useState } from 'react';
import { View, Text } from 'react-native';

function TotpCodeDisplay({ credentialId }: { credentialId: string }) {
  const [code, setCode]           = useState('');
  const [timeRemaining, setTime]  = useState(30);

  useEffect(() => {
    let client: Awaited<ReturnType<typeof createOathClient>>;

    const init = async () => {
      client = await createOathClient();
      const info = await client.generateCodeWithValidity(credentialId);
      setCode(info.code);
      setTime(Math.round(info.timeRemaining));
    };

    init();
    const interval = setInterval(async () => {
      if (!client) return;
      const info = await client.generateCodeWithValidity(credentialId);
      setCode(info.code);
      setTime(Math.round(info.timeRemaining));
    }, 1000);

    return () => {
      clearInterval(interval);
      if (client) {
        client.close().catch(() => {});
      }
    };
  }, [credentialId]);

  return (
    <View>
      <Text style={{ fontSize: 32, fontFamily: 'monospace' }}>{code}</Text>
      <Text>Expires in {timeRemaining}s</Text>
    </View>
  );
}
```

### `OathCodeInfo` Shape

```ts
type OathCodeInfo = {
  code:          string;  // OTP string
  timeRemaining: number;  // TOTP: seconds left in window; HOTP: -1
  counter:       number;  // HOTP: counter after generation; TOTP: -1
  progress:      number;  // TOTP: 0.0–1.0 elapsed fraction; HOTP: 0.0
  totalPeriod:   number;  // TOTP: period in seconds; HOTP: 0
};
```

### Generating HOTP Codes

```ts
// HOTP increments the counter on each call
const code = await client.generateCode(credentialId);
```

Use `generateCode()` for HOTP — the counter advances automatically. For TOTP prefer `generateCodeWithValidity()` to get timing metadata for the countdown UI.

### Credential Management

```ts
const credentials = await client.getCredentials();
const cred        = await client.getCredential('my-id');   // null if not found
const saved       = await client.saveCredential(cred!);
const deleted     = await client.deleteCredential('my-id');
```

### `OathCredential` Shape

```ts
type OathCredential = {
  id:                 string;
  issuer:             string;
  displayIssuer:      string;
  accountName:        string;
  displayAccountName: string;
  type:               'TOTP' | 'HOTP';
  digits:             number;         // 6 or 8
  period:             number;         // TOTP period in seconds
  counter:            number;         // HOTP counter
  algorithm:          'SHA1' | 'SHA256' | 'SHA512';
  isLocked:           boolean;        // locked by device policy
  userId:             string | null;
  resourceId:         string | null;
  imageURL:           string | null;
  backgroundColor:    string | null;
  policies:           string | null;  // JSON-encoded policy config
  lockingPolicy:      string | null;
  createdAt:          number;         // ms since epoch
};
```

### Policy Evaluator (Optional)

```ts
import { configureOathPolicyEvaluator, createOathClient } from '@ping-identity/rn-oath';

// Configure once at module scope (synchronous):
const evaluator = configureOathPolicyEvaluator({
  policies: [
    { kind: 'biometricAvailable' },  // fails if no biometric enrolled
    { kind: 'deviceTampering' },     // fails if device is rooted/jailbroken
  ],
});

// Pass to client — code generation fails if a policy is violated:
const client = await createOathClient({ policyEvaluator: evaluator });
```

Valid policy kinds: `'biometricAvailable'`, `'deviceTampering'`. Throws `OathError` (`argument_error`) when `policies` is empty or contains an unknown kind.

### `OathClient` Methods

| Method | Signature | Description |
|---|---|---|
| `addCredentialFromUri` | `(uri: string) => Promise<OathCredential>` | Enroll from `otpauth://` or `mfauth://` URI |
| `getCredential` | `(id: string) => Promise<OathCredential \| null>` | Single credential by id |
| `getCredentials` | `() => Promise<OathCredential[]>` | All stored credentials |
| `saveCredential` | `(c: OathCredential) => Promise<OathCredential>` | Persist updated credential |
| `deleteCredential` | `(id: string) => Promise<boolean>` | Remove credential |
| `generateCode` | `(id: string) => Promise<string>` | Generate OTP code (TOTP or HOTP) |
| `generateCodeWithValidity` | `(id: string) => Promise<OathCodeInfo>` | Generate OTP + timing metadata |
| `close` | `() => Promise<void>` | Release native resources |

### `OathError` Codes

| Code | Description |
|---|---|
| `OATH_INVALID_URI` | URI could not be parsed |
| `OATH_INVALID_PARAMETER` | Invalid argument (e.g. bad digits, negative period) |
| `OATH_DUPLICATE_CREDENTIAL` | Credential with this id already exists |
| `OATH_CREDENTIAL_NOT_FOUND` | Credential id not in store |
| `OATH_CREDENTIAL_LOCKED` | Policy violation prevents code generation |
| `OATH_CODE_GENERATION_FAILED` | OTP generation error |
| `OATH_POLICY_VIOLATION` | Policy evaluator rejected the operation |
| `OATH_STORAGE_FAILURE` | Persistence error |
| `OATH_STATE_ERROR` | Client already closed |
