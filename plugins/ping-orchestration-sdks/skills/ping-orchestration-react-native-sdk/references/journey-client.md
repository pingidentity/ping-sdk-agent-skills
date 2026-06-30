# Journey Client Reference

## `createJourneyClient(config)`

Creates a native-backed Journey client. Call at module scope or in a stable app-level singleton — never inside a component body.

```ts
import { createJourneyClient } from '@ping-identity/rn-journey';

const journeyClient = createJourneyClient(config: JourneyConfig): JourneyClient
```

Throws `JourneyError` with code `JOURNEY_CONFIG_ERROR` when `serverUrl` is missing or empty.

---

## `JourneyConfig`

```ts
type JourneyConfig = {
  serverUrl: string;          // Required. PingAM/AIC base URL, no trailing /
  realm?:    string;          // Default: 'alpha'
  cookie?:   string;          // Default: 'iPlanetDirectoryPro'
  timeout?:  number;          // Network timeout in milliseconds
  logger?:   LoggerInstance;  // From @ping-identity/rn-logger
  modules?: {
    session?: {
      storage?: SessionStorageHandle; // From configureSessionStorage() in @ping-identity/rn-storage
    };
    oidc?: {
      clientId:          string;
      discoveryEndpoint: string;   // Full .well-known/openid-configuration URL
      redirectUri:       string;   // Custom scheme, e.g. com.example.app://callback
      scopes:            string[]; // Must include 'openid'
      // Optional OIDC fields:
      acrValues?:             string;
      state?:                 string;
      nonce?:                 string;
      uiLocales?:             string;
      loginHint?:             string;
      display?:               string;
      prompt?:                string;
      refreshThreshold?:      number;
      signOutRedirectUri?:    string;
      additionalParameters?:  Record<string, string>;
      storage?:               OidcStorageHandle; // From configureOidcStorage() in @ping-identity/rn-storage
      openId?: {               // Manual endpoint override — use instead of discoveryEndpoint
        authorizationEndpoint: string;
        tokenEndpoint:         string;
        userinfoEndpoint:      string;
        endSessionEndpoint?:   string;
        revocationEndpoint?:   string;
      };
    };
  };
};
```

---

## `JourneyClient` Methods

| Method | Signature | Description |
|---|---|---|
| `init` | `() => Promise<string>` | Eagerly configure the native instance; returns native id |
| `getId` | `() => Promise<string>` | Returns native journey id (configures lazily if needed) |
| `start` | `(name: string, options?: JourneyStartOptions) => Promise<JourneyNode>` | Start a Journey by tree name |
| `next` | `(input?: JourneyNextInput) => Promise<JourneyNode>` | Advance with callback input |
| `resume` | `(uri: string) => Promise<JourneyNode>` | Resume a suspended Journey from a redirect URI |
| `user` | `() => Promise<JourneyUserSession \| null>` | Resolve active session |
| `refresh` | `() => Promise<JourneyUserSession \| null>` | Refresh access token |
| `revoke` | `() => Promise<boolean>` | Revoke tokens |
| `userinfo` | `() => Promise<JourneyUserInfo \| null>` | Fetch userinfo payload |
| `ssoToken` | `() => Promise<JourneySSOToken \| null>` | Resolve SSO token |
| `logoutUser` | `() => Promise<boolean>` | Logout and clear session |
| `dispose` | `() => Promise<void>` | Release native resources |

---

## `JourneyStartOptions`

```ts
type JourneyStartOptions = {
  forceAuth?: boolean;  // Force re-authentication even when an SSO session exists
  noSession?: boolean;  // Start a sessionless flow
};
```

---

## `useJourney(client?)` Hook

```ts
import { useJourney } from '@ping-identity/rn-journey';

// With explicit client (local screen state):
const [node, actions] = useJourney(journeyClient);

// Without client (reads from nearest JourneyProvider):
const [node, actions] = useJourney();
```

Returns `[JourneyNode | null, JourneyHookActions]`.

Throws `JourneyError` with code `JOURNEY_STATE_ERROR` if called without a client and no `JourneyProvider` is in scope.

### `JourneyHookActions`

| Action | Signature | Description |
|---|---|---|
| `start` | `(name: string, options?) => Promise<JourneyNode>` | Start a Journey; sets `node` state |
| `next` | `(input?) => Promise<JourneyNode>` | Advance node; throws if no active node |
| `resume` | `(uri: string) => Promise<JourneyNode>` | Resume from redirect URI |
| `user` | `() => Promise<JourneyUserSession \| null>` | Resolve active session |
| `refresh` | `() => Promise<JourneyUserSession \| null>` | Refresh tokens |
| `revoke` | `() => Promise<boolean>` | Revoke tokens |
| `userinfo` | `() => Promise<JourneyUserInfo \| null>` | Fetch userinfo |
| `ssoToken` | `() => Promise<JourneySSOToken \| null>` | Resolve SSO token |
| `logoutUser` | `() => Promise<boolean>` | Logout; resets `node` to `null` |
| `dispose` | `() => Promise<void>` | Dispose native client; resets `node` and `error` |
| `loading` | `boolean` | True while any async action is in flight |
| `error` | `JourneyError \| null` | Last hook-level error |

---

## `JourneyProvider`

Shares one `useJourney` state instance across a component subtree. Use when multiple screens need to read or advance the same Journey session.

```tsx
import { JourneyProvider, useJourney } from '@ping-identity/rn-journey';

<JourneyProvider client={journeyClient}>
  <LoginScreen />
</JourneyProvider>

// In any descendant:
const [node, { next }] = useJourney(); // no client arg needed
```

Props:

```ts
type JourneyProviderProps = {
  client:   JourneyClient;
  children: React.ReactNode;
};
```

---

## `JourneyNode` Shape

```ts
type JourneyNode = {
  type?:      'ContinueNode' | 'SuccessNode' | 'FailureNode' | 'ErrorNode';
  message?:   string;   // Node-level message from server
  cause?:     string;   // FailureNode: failure reason
  callbacks?: JourneyCallback[];  // ContinueNode: callback collection
  input?:     Record<string, unknown>;
};
```

---

## `JourneyNextInput`

Payload passed to `next()` to submit callback values:

```ts
type JourneyNextInput = {
  callbacks?: JourneyCallbackInput[];
};

type JourneyCallbackInput = {
  type:   JourneyCallbackType;  // e.g. 'NameCallback'
  value?: string | number | boolean | null | Record<string, unknown> | Array<unknown>;
  index?: number;  // Per-type zero-based index when multiple callbacks share the same type
};
```

Example — username + password:

```ts
await next({
  callbacks: [
    { type: 'NameCallback',     value: 'user@example.com' },
    { type: 'PasswordCallback', value: 'secret' },
  ],
});
```

Example — two KBA questions (both are `KbaCreateCallback`, differentiated by index):

```ts
await next({
  callbacks: [
    { type: 'KbaCreateCallback', value: { selectedQuestion: 'q1', selectedAnswer: 'a1', allowUserDefinedQuestions: false }, index: 0 },
    { type: 'KbaCreateCallback', value: { selectedQuestion: 'q2', selectedAnswer: 'a2', allowUserDefinedQuestions: false }, index: 1 },
  ],
});
```

---

## `JourneyError`

```ts
import { JourneyError } from '@ping-identity/rn-journey';

// Stable error codes:
type JourneyErrorCode =
  | 'JOURNEY_CONFIG_ERROR'    // Bad/missing configuration
  | 'JOURNEY_START_ERROR'     // start() failed
  | 'JOURNEY_NEXT_ERROR'      // next() failed
  | 'JOURNEY_RESUME_ERROR'    // resume() failed
  | 'JOURNEY_STATE_ERROR'     // Called action with no active node / no client
  | (string & {});            // Native codes passed through as-is

// Narrowing:
try {
  await start('Login');
} catch (err) {
  if (err instanceof JourneyError) {
    console.log(err.code);    // JourneyErrorCode
    console.log(err.message); // Human-readable description
  }
}
```

---

## Session Types

```ts
type JourneyUserSession = {
  accessToken?:  string;
  idToken?:      string;
  refreshToken?: string;
  tokenType?:    string;
  scope?:        string;
};

type JourneyUserInfo = Record<string, unknown>; // userinfo endpoint payload

type JourneySSOToken = {
  tokenId:    string;
  successUrl: string;
  realm:      string;
};
```
