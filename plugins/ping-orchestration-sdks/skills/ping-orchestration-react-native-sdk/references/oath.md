# `@ping-identity/rn-oath` — OATH TOTP/HOTP Reference

OATH is a standalone credential manager for software TOTP and HOTP tokens. It is not a Journey callback — there is no `OathCallbackView`. Use it to build a dedicated authenticator screen alongside your Journey flow.

## Install

```bash
npm install @ping-identity/rn-oath@1.0.0
cd ios && pod install
```

## Basic usage

```ts
import { createOathClient } from '@ping-identity/rn-oath';

// Create client — async, call once and hold the reference
const client = await createOathClient();

// Register a credential from an otpauth:// URI (e.g. scanned QR code)
const credential = await client.addCredentialFromUri(
  'otpauth://totp/Example:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example'
);

// List all stored credentials
const credentials = await client.getCredentials();

// Generate a code
const code = await client.generateCode(credential.id);

// Generate a code with countdown metadata (TOTP)
const { code, timeRemaining, progress } = await client.generateCodeWithValidity(credential.id);

// Delete a credential
await client.deleteCredential(credential.id);

// Release native resources when done
await client.close();
```

## Key types

```ts
type OathCredential = {
  id: string;
  issuer: string;
  displayIssuer: string;
  accountName: string;
  displayAccountName: string;
  type: 'TOTP' | 'HOTP';
  digits: number;       // 6 or 8
  period: number;       // TOTP window in seconds (typically 30)
  counter: number;      // HOTP counter
  isLocked: boolean;
  imageURL: string | null;
  backgroundColor: string | null;
};

type OathCodeInfo = {
  code: string;
  timeRemaining: number;  // seconds remaining in TOTP window (-1 for HOTP)
  progress: number;       // 0.0–1.0 fraction of period elapsed (0.0 for HOTP)
  totalPeriod: number;    // TOTP period in seconds (0 for HOTP)
  counter: number;        // HOTP counter after generation (-1 for TOTP)
};
```

## With logger

```ts
import { logger } from '@ping-identity/rn-logger';

const log = logger({ level: 'debug' });
const client = await createOathClient({ logger: log });
```

## With policy evaluator (biometric / tamper check before code generation)

```ts
import { createOathClient, configureOathPolicyEvaluator } from '@ping-identity/rn-oath';

const evaluator = configureOathPolicyEvaluator({
  policies: [{ kind: 'biometricAvailable' }, { kind: 'deviceTampering' }],
});

const client = await createOathClient({ policyEvaluator: evaluator });
```

## Configuration options

| Option | Type | Default | Description |
|---|---|---|---|
| `logger` | `LoggerInstance` | none | Logger from `@ping-identity/rn-logger` |
| `timeout` | `number` | 15 | Network timeout in seconds |
| `enableCredentialCache` | `boolean` | `false` | In-memory credential cache |
| `encryptionEnabled` | `boolean` | `true` | iOS only — encrypt credential storage at rest |
| `storage` | `OathStorageHandle` | native default | Custom storage from `@ping-identity/rn-storage` |
| `policyEvaluator` | `OathPolicyEvaluatorHandle` | native default | Custom policy evaluator |

## Common mistakes

- **Client created in a component** — `createOathClient()` is async and returns a handle to a native session. Create it once at module scope or in a stable ref (`useRef`), not on every render.
- **Calling methods after `close()`** — throws `OathError` with `error: 'OATH_STATE_ERROR'`. Guard with a `closed` flag.
- **`mfauth://` URIs** — accepted by `addCredentialFromUri` directly; the native SDK handles both `otpauth://` and `mfauth://` schemes.
- **`encryptionEnabled` on Android** — silently ignored; Android encryption is governed by the storage provider, not a client config flag.
