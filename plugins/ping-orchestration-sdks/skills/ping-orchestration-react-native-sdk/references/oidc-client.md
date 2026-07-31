# OIDC Client Reference

## Overview

The OIDC Web flow uses two client handles:

- **`OidcClient`** — base native client. Holds config; can token/refresh/userinfo/revoke without a browser.
- **`OidcWebClient`** — wraps `OidcClient`; launches the system browser for authorization code flow.

Create both at module scope:

```ts
import { createOidcClient, createOidcWebClient } from '@ping-identity/rn-oidc';

const oidcClient    = createOidcClient(config);
const oidcWebClient = createOidcWebClient(oidcClient);
```

---

## `OidcClientConfig`

```ts
type OidcClientConfig = {
  // Required (one of these two):
  clientId:           string;
  discoveryEndpoint?: string;  // Full .well-known/openid-configuration URL
  openId?: {                   // Manual endpoint override — use instead of discoveryEndpoint
    authorizationEndpoint: string;
    tokenEndpoint:         string;
    userinfoEndpoint:      string;
    endSessionEndpoint?:   string;
    revocationEndpoint?:   string;
  };

  // Required for web flows:
  redirectUri:  string;   // Custom scheme, e.g. com.example.app://callback
  scopes:       string[]; // Must include 'openid'

  // Optional:
  acrValues?:             string;
  state?:                 string;
  nonce?:                 string;
  uiLocales?:             string;
  loginHint?:             string;
  display?:               string;
  prompt?:                string;
  refreshThreshold?:      number;
  additionalParameters?:  Record<string, string>;
  storage?:               OidcStorageHandle; // From configureOidcStorage() in @ping-identity/rn-storage
  logger?:                LoggerInstance;    // From @ping-identity/rn-logger
  ios?: {                  // iOS-only browser options (ignored on Android)
    prefersEphemeralWebBrowserSession?: boolean;
    // Additional ASWebAuthenticationSession options
  };
};
```

Throws `OidcError` with code `OIDC_STATE_ERROR` when neither `discoveryEndpoint` nor `openId` is provided.

---

## `OidcClient` Methods

| Method | Signature | Description |
|---|---|---|
| `token` | `() => Promise<Tokens>` | Get current token bundle |
| `refresh` | `() => Promise<Tokens>` | Force-refresh tokens |
| `userinfo` | `(cache?: boolean) => Promise<Record<string, unknown>>` | Fetch userinfo endpoint |
| `revoke` | `() => Promise<void>` | Revoke current tokens |
| `endSession` | `() => Promise<boolean>` | End session (server-side logout) |
| `dispose` | `() => Promise<void>` | Release native resources |

`Tokens` shape: `{ accessToken: string; idToken?: string; refreshToken?: string; tokenType?: string; scope?: string }` (internal `tokenExpiry` is stripped before returning to JS).

---

## `OidcWebClient` Methods

| Method | Signature | Description |
|---|---|---|
| `authorize` | `(options?: OidcAuthorizeOptions) => Promise<OidcAuthorizeResult>` | Launch browser authorization |
| `user` | `() => Promise<OidcUser \| null>` | Resolve current user; `null` if not authenticated |
| `dispose` | `() => Promise<void>` | Release native web client resources |

---

## `OidcAuthorizeOptions`

Per-request overrides for `authorize()`:

```ts
type OidcAuthorizeOptions = {
  acrValues?:             string;
  state?:                 string;
  nonce?:                 string;
  uiLocales?:             string;
  loginHint?:             string;
  display?:               string;
  prompt?:                string;
  additionalParameters?:  Record<string, string>;
};
```

---

## `OidcAuthorizeResult`

```ts
type OidcAuthorizeResult =
  | { type: 'success' }
  | { type: 'cancel' }
  | { type: string; [key: string]: unknown };  // forward-compatible extension
```

Always check `result.type` before assuming authentication succeeded:

```ts
const result = await oidcWebClient.authorize();
if (result.type === 'success') {
  // user is now authenticated — call user() to get the handle
}
if (result.type === 'cancel') {
  // user dismissed the browser
}
```

---

## `OidcUser` Methods

Returned by `oidcWebClient.user()` and stored in `useOidc` state:

| Method | Signature | Description |
|---|---|---|
| `token` | `() => Promise<Tokens>` | Get current token bundle |
| `refresh` | `() => Promise<Tokens>` | Force-refresh tokens |
| `userinfo` | `(cache?: boolean) => Promise<Record<string, unknown>>` | Fetch userinfo |
| `revoke` | `() => Promise<void>` | Revoke tokens |
| `logout` | `() => Promise<void>` | Logout user session |

---

## `useOidc(client?)` Hook

```ts
import { useOidc } from '@ping-identity/rn-oidc';

const [state, actions] = useOidc(oidcWebClient); // explicit client
const [state, actions] = useOidc();              // from nearest OidcProvider
```

Returns `[OidcHookState, OidcHookActions]`.

### `OidcHookState`

```ts
type OidcHookState = {
  isLoading:       boolean;
  isAuthenticated: boolean;
  user:            OidcUser | null;
  tokens:          Tokens | null;
  userInfo:        Record<string, unknown> | null;
  authorizeResult: OidcAuthorizeResult | null;
  error:           OidcError | null;
};
```

### `OidcHookActions`

| Action | Signature | Description |
|---|---|---|
| `restore` | `() => Promise<OidcUser \| null>` | Resolve + cache auth state from native; call on mount to check for existing session. Deduplicates in-flight calls. |
| `authorize` | `(options?) => Promise<OidcAuthorizeResult>` | Launch browser authorization; updates `isAuthenticated` on success |
| `token` | `() => Promise<Tokens \| null>` | Get + cache tokens for current user; `null` if not authenticated |
| `refresh` | `() => Promise<Tokens \| null>` | Refresh + cache tokens; `null` if not authenticated |
| `userinfo` | `(cache?) => Promise<Record<string, unknown> \| null>` | Fetch + cache userinfo; `null` if not authenticated |
| `revoke` | `() => Promise<boolean>` | Revoke tokens + clear auth state; `false` if no user |
| `logout` | `() => Promise<boolean>` | Logout user + clear auth state; `false` if no user |
| `clear` | `() => void` | Clear transient state (tokens, userInfo, authorizeResult, error) without logging out |

---

## `OidcProvider`

Shares one `useOidc` state instance across a subtree:

```tsx
import { OidcProvider, useOidc } from '@ping-identity/rn-oidc';

<OidcProvider client={oidcWebClient}>
  <LoginScreen />
  <ProfileScreen />
</OidcProvider>

// In any descendant:
const [state, actions] = useOidc(); // no client arg needed
```

---

## Typical App Lifecycle Pattern

```tsx
function App() {
  const [state, actions] = useOidc(oidcWebClient);

  // Restore session on mount:
  useEffect(() => {
    (async () => { await actions.restore(); })();
  }, []);

  if (state.isLoading) return <ActivityIndicator />;

  if (!state.isAuthenticated) {
    return (
      <Button
        title="Sign In"
        onPress={async () => {
          const result = await actions.authorize();
          if (result.type === 'success') {
            await actions.restore(); // refresh local state post-auth
          }
        }}
      />
    );
  }

  return (
    <View>
      <Text>Signed in</Text>
      <Button title="Get Tokens" onPress={() => actions.token()} />
      <Button title="Sign Out" onPress={() => actions.logout()} />
    </View>
  );
}
```

---

## `OidcError`

```ts
import { OidcError } from '@ping-identity/rn-oidc';

type OidcErrorCode =
  | 'OIDC_AUTHORIZE_ERROR'
  | 'OIDC_HAS_USER_ERROR'
  | 'OIDC_STATE_ERROR'     // Missing client / provider
  | 'OIDC_TOKEN_ERROR'
  | 'OIDC_REFRESH_ERROR'
  | 'OIDC_USERINFO_ERROR'
  | 'OIDC_REVOKE_ERROR'
  | 'OIDC_LOGOUT_ERROR'
  | (string & {});         // Native codes passed through as-is

try {
  await actions.authorize();
} catch (err) {
  if (err instanceof OidcError) {
    console.log(err.code);    // OidcErrorCode
    console.log(err.message);
  }
}
```

---

## Android Redirect URI

`android/app/src/main/AndroidManifest.xml`:

```xml
<activity android:name=".MainActivity" ...>
  <intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.example.app" />
  </intent-filter>
</activity>
```

The `android:scheme` value must match the scheme part of your `redirectUri`.

## iOS Redirect URI

`ios/<AppName>/Info.plist`:

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

---

## Common Pitfalls

- **Two client handles, one lifecycle** — `OidcWebClient.dispose()` releases the web client handle only; it does not release the base `OidcClient`. Call `OidcClient.dispose()` separately when tearing down completely.
- **`restore()` on every mount** — always call `actions.restore()` in a `useEffect` on mount to rehydrate auth state from native storage. Without it, `isAuthenticated` starts as `false` even if the user has a valid session.
- **`authorize()` result is not a guarantee** — `result.type === 'success'` means the browser flow completed, not that `user()` is non-null. Always call `restore()` after a successful authorize to confirm native state.
- **`clear()` vs `logout()`** — `clear()` wipes transient JS-side state (tokens, userInfo, error) without touching native storage. `logout()` calls native logout and clears JS state. Use `clear()` on navigation away; use `logout()` for sign-out.
