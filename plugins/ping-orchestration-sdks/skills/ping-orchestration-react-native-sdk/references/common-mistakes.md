# Common Mistakes — React Native SDK

Quick reference for RN-specific gotchas. Check this when debugging unexpected behavior.

---

## Imports & client setup

| Mistake | Fix |
|---|---|
| `createJourneyClient(config)` called inside a component body | Create at module scope — it's synchronous and must be created once. Recreating on every render loses session state. |
| `createOidcClient(config)` called inside a component body | Use `useMemo` at App level or create at module scope. Same reason: session state lives in the client instance. |
| `createBindingClient()` called inside a component | Create at module scope — it is synchronous and stateless. |
| `createFidoClient()` called inside a component | Create at module scope — same as above. |
| Importing from `@ping-identity/rn-device-binding` | Package does not exist. Use `@ping-identity/rn-binding`. |
| Importing from `@ping-identity/rn-fido2` | Package does not exist. Use `@ping-identity/rn-fido`. |
| `fidoClient.registerForJourney(cb, journeyClient, ...)` | Wrong signature — `cb` arg was removed. Correct: `registerForJourney(journey, { index, deviceName })`. |
| `bindingClient.bindForJourney(cb, journeyClient, ...)` | Wrong signature. Correct: `bindForJourney(journey, { index, deviceName? })`. |
| `{ pinCollector: ... }` passed to binding operation | `pinCollector` does not exist on binding operation options. PIN collection is handled natively by the SDK. |
| `PingTheme.ts` written with JSX components | JSX requires `.tsx` extension. Write `src/theme/PingTheme.tsx`, not `PingTheme.ts`. |
| Wrong package for OIDC web flow | `createOidcWebClient` (not `createOidcClient`) opens the system browser for authorization. Use `createOidcClient` only for native/embedded flows. |

---

## Hooks & providers

| Mistake | Fix |
|---|---|
| `useJourney()` called outside `JourneyProvider` with no client arg | Either pass the client directly: `useJourney(journeyClient)`, or wrap the component tree with `<JourneyProvider client={journeyClient}>`. Calling the hook with no arg and no provider throws `JOURNEY_STATE_ERROR`. |
| `useOidc()` called outside `OidcProvider` with no client arg | Same pattern — pass client directly or use provider. |
| `state.isLoading` used to gate the restore() spinner | `restore()` is a silent keychain read; it does NOT set `isLoading`. Use local state: `const [restoring, setRestoring] = useState(true)` then `await actions.restore()` then `setRestoring(false)`. |
| `useJourneyForm` used as a callback renderer | `useJourneyForm` is a headless submit planner — it does NOT render UI. Use it alongside `useJourney` when you need managed form state (KBA multi-index, T&C consent blocking). Do not reach for it on simple username/password flows. |

---

## Navigation

| Mistake | Fix |
|---|---|
| `navigation.navigate('Home')` after login | Use `navigation.replace('Home')`. `navigate` leaves Login on the stack — the user can press Back to return to the login form while authenticated. |
| `navigation.navigate('Login')` after logout | Use `navigation.replace('Login')` — same reason. |
| Two `NavigationContainer` instances (one per flow) | Use a single `NavigationContainer` with a `FlowPicker` root screen that conditionally renders Journey or OIDC screens. Two containers break the back button and cause navigation state conflicts. |
| `JourneyProvider` or `OidcProvider` placed inside a screen component | Place both providers above `NavigationContainer` in `App.tsx`. Providers placed inside screens lose their state when the screen unmounts. |

---

## Journey callbacks

| Mistake | Fix |
|---|---|
| `next()` called before `start()` resolves | `start()` is async — await it or wait for the `node` state to populate before calling `next`. |
| `index` in `JourneyNextInput` passed as array position | `index` is a **per-type** zero-based counter, not the array position of the callback. Track a separate counter for each callback type when building the input payload. |
| Next button shown for `PollingWaitCallback` | Suppress the Next button for `auto_capable` and `integration_required` callbacks — they advance the Journey themselves. |
| Next button shown for FIDO / DeviceBinding callbacks | Same — these views call `onNext()` directly after the native operation completes. |
| `KbaCreateCallback` — wrong `index` when multiple KBA questions | Two `KbaCreateCallback`s on the same node both need their own per-type index (0 and 1). If both send `index: 0`, the server matches both answers to the first question. |

---

## OIDC

| Mistake | Fix |
|---|---|
| `restore()` not called on mount | Without `restore()`, `isAuthenticated` starts false even when a valid token is stored. Call `await actions.restore()` in a `useEffect` on mount. |
| `authorize()` result used to set authenticated state directly | `authorize()` handles the redirect; call `restore()` afterward to confirm native token state. |
| `redirectUri` scheme not in `AndroidManifest.xml` | Add `<data android:scheme="<your-scheme>" />` to the `<intent-filter>` for the redirect activity. |
| `redirectUri` scheme not in `Info.plist` | Add the scheme under `CFBundleURLTypes` > `CFBundleURLSchemes`. |
| Missing `manifestPlaceholders` in `build.gradle` | Add `manifestPlaceholders = [appRedirectUriScheme: "<your-scheme>"]` to the `android` block in `app/build.gradle`. |

---

## Platform & build

| Mistake | Fix |
|---|---|
| `pod install` not run after `npm install` | Native modules require CocoaPods linking on iOS. Always run `pod install` from `ios/` after adding or updating packages. |
| Android `minSdkVersion` below 29 | The SDK requires API 29+. Set `minSdkVersion = 29` in `android/build.gradle`. |
| iOS deployment target below 16.0 | The SDK requires iOS 16.0+. Set `IPHONEOS_DEPLOYMENT_TARGET = 16.0` in Xcode or `Podfile`. |
| Metro bundler caches stale native module paths | Run `npx react-native start --reset-cache` after changing native dependencies. |
| "has not been registered" error on launch | Metro is running from a different project directory. Kill all Metro instances (`pkill -f "react-native start"`), then restart from the correct project root before relaunching the app. |
