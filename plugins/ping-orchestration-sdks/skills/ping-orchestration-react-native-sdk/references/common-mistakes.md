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

## DaVinci

| Mistake | Fix |
|---|---|
| Submitting Journey's `{ callbacks: [{ type, value, index? }] }` payload to DaVinci `next()` | DaVinci does not use that shape: it is key-indexed — `{ collectors: [{ key, value }] }`, where `key` is the `collector.key` from the active `ContinueNode`. An unknown key throws `DAVINCI_COLLECTOR_APPLY_ERROR`. |
| Expecting `ACTION`/`FLOW_BUTTON`/`FLOW_LINK` to submit the form | They advance the flow by their own key as a single-entry payload and bypass all other field values. Use `form.submitFlow(key)` (or `setValue` on the flow key, which auto-submits). |
| Omitting the first `SUBMIT_BUTTON` from a manually built payload | `buildNextInput` adds it once as `{ key, value: key }`; the native POST needs `actionKey`/`eventType` from that value. Manual payloads must include it. |
| Treating `validate()` as a pure check | It writes the value onto the live collector — the value will be submitted by the next `next()`. An empty result can also mean the collector has no validator. |
| Waiting for `pollStatus` to advance the flow | It never calls `next()`; advance explicitly on a terminal status (`complete`, `timedOut`, `expired`, `error`). The unsubscribe function stops local delivery only — the native poll cannot be cancelled. |
| `useDaVinciForm(node)` outside `DaVinciProvider` calling `submitFlow` | Pass `next` from `useDaVinci(client)` via `options.next`. Without it, `submitFlow` and FlowCollector auto-submit throw `DaVinciError`. |
| Passing `client={...}` to `DaVinciProvider` | `DaVinciProvider` takes `config={DaVinciConfig}` and builds the client internally. |
| Creating a second client with `createDaVinciClient` in a provider-based app | Get the existing client via `useDaVinciContext()?.client`; integration calls (`collectProtect`, `registerForDaVinci`, `authenticateForDaVinci`, `authorizeForDaVinci`) must target the same native instance the flow runs on. |
| `createDaVinciClient` inside a component (client-based apps) | Create at module scope — same rule as the other clients. Pick one pattern per app: provider-based or client-based, not both. |
| Adding `manifestPlaceholders`/`CFBundleURLTypes` for a plain DaVinci flow | Unnecessary — DaVinci resolves sign-in through the flow itself, no browser redirect. Redirect wiring is only needed for the Social Login integration (`rn-external-idp`: `appRedirectUriScheme` + `CFBundleURLTypes`). |

---

## Platform & build

| Mistake | Fix |
|---|---|
| `pod install` not run after `npm install` | Native modules require CocoaPods linking on iOS. Always run `pod install` from `ios/` after adding or updating packages. |
| Android `minSdkVersion` below 29 | The SDK requires API 29+. Set `minSdkVersion = 29` in `android/build.gradle`. |
| Google/Facebook login does nothing on iOS: the provider page opens, the redirect lands, but no handler fires and the flow stalls | The open-URL routing was written into the wrong lifecycle. If `ios/<AppName>/Info.plist` declares `UIApplicationSceneManifest` with `UISceneDelegateClassName` (RN 0.88+ template), iOS never calls `application(_:open:options:)` in the AppDelegate; the routing must live in the scene delegate's `scene(_:openURLContexts:)` (and `connectionOptions.urlContexts` for cold starts). See the Social login section of `platform-setup.md`. |
| `The iOS Simulator deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 9.0/12.0, but the range of supported deployment target versions is 15.0 to ...` (in targets from project 'Pods') | A pod target sits below the Xcode minimum: pods are built at their podspec's target, not at the Podfile `platform` line, and RN 0.80's own `post_install` skips the `-Privacy` resource-bundle targets. Add the post_install raise loop from the Baseline section of `platform-setup.md` and re-run `pod install`. |
| iOS deployment target below 16.0 | The SDK requires iOS 16.0+. Three settings: the `platform :ios, '16.0'` line in the `Podfile` (resolution), the post_install raise loop (pod build targets), and every `IPHONEOS_DEPLOYMENT_TARGET` in `project.pbxproj` at 16.0+ (app target). The Podfile never changes the app target; CocoaPods does not edit the app project. See the Baseline section of `platform-setup.md`. |
| Metro bundler caches stale native module paths | Run `npx react-native start --reset-cache` after changing native dependencies. |
| "has not been registered" error on launch | Metro is running from a different project directory. Kill all Metro instances (`pkill -f "react-native start"`), then restart from the correct project root before relaunching the app. |
