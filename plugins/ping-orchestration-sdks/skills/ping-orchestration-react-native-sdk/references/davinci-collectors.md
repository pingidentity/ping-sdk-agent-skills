# DaVinci Collectors Reference

DaVinci collectors are plain discriminated-union objects: the app renders each collector by its `type`, tracks user input by `collector.key`, and submits `{ collectors: [{ key, value }] }` to `next()`. There is no Journey-style `type` + `index` addressing; every value is keyed by the collector's `key` from the active `ContinueNode`. See [davinci-client.md](davinci-client.md) for the key-indexed contract contrast with Journey.

## Execution modes

Every normalized collector carries an `executionMode` that classifies how the app must treat it:

| Mode | Meaning | Type strings |
|---|---|---|
| `manual` | Requires explicit user input; value submitted from form state | `TEXT`, `PASSWORD`, `PASSWORD_VERIFY`, `SINGLE_CHECKBOX`, `SINGLE_SELECT`, `DROPDOWN`, `RADIO`, `MULTI_SELECT`, `COMBOBOX`, `CHECKBOX`, `PHONE_NUMBER`, `DEVICE_REGISTRATION`, `DEVICE_AUTHENTICATION` |
| `output_only` | Display-only; excluded from the submit payload | `LABEL`, `READ_ONLY_TEXT`, `POLLING`, `QR_CODE` |
| `immediate` | Activating it advances the flow without waiting for other fields | `SUBMIT_BUTTON`, `ACTION`, `FLOW_BUTTON`, `FLOW_LINK` |
| `integration_required` | Handled entirely by an external integration package before `next()` | `SOCIAL_LOGIN_BUTTON`, `FIDO2`, `PROTECT`, and any future registered type |
| `unsupported` | Not recognized by the bridge or any registered integration | anything else |

No `auto_capable` mode exists: every collector requires an explicit user gesture or an external-package action (`DaVinciFormMeta.hasAutoCapable` is a constant-`false` stub).

## Collector-to-payload mapping

The authoritative table for what each collector contributes to the `next()` payload. Submit with `{ collectors: [{ key, value }] }` using the collector's own `key`.

| Type string(s) | kind | `next()` payload for this key | Notes |
|---|---|---|---|
| `TEXT` | `text` | `value: string` | Optional `validation.regex` (see the anchoring parity note in [davinci-client.md](davinci-client.md)) |
| `PASSWORD`, `PASSWORD_VERIFY` | `password` | `value: string` | Write-only: the bridge clears the value in node output. Optional `passwordPolicy` for rendering requirements |
| `SINGLE_CHECKBOX` | `boolean` | `value: boolean` | `appearance` selects `CHECKBOX` or `SWITCH` rendering; `errorMessage` is shown when `required` and unchecked |
| `SINGLE_SELECT`, `DROPDOWN`, `RADIO` | `singleSelect` | `value: string` (one of `options[].value`) | `options: { label, value }[]` |
| `MULTI_SELECT`, `COMBOBOX`, `CHECKBOX` | `multiSelect` | `value: string[]` | `options: { label, value }[]` |
| `PHONE_NUMBER` | `phone` | `value: { countryCode, phoneNumber, extension? }` | `defaultCountryCode`, `showExtension`, `extensionLabel` are read-only config; render the extension input only when `showExtension` is `true` |
| `DEVICE_REGISTRATION` | `device` | `value: { type }` where `type` is the chosen `devices[].type` | `devices: DeviceOption[]`; see the device payload note below |
| `DEVICE_AUTHENTICATION` | `device` | `value: { type, id?, description? }` | `devices: DeviceOption[]`; see the device payload note below |
| `SUBMIT_BUTTON` | `flow` | Auto-added once by `buildNextInput` as `{ key, value: key }` | The native POST body needs a non-empty submit value so `actionKey`/`eventType` are set. Manual payload builders must include the first `SUBMIT_BUTTON` themselves |
| `ACTION`, `FLOW_BUTTON`, `FLOW_LINK` | `flow` | Single-entry payload `{ collectors: [{ key, value }] }`: `value` is the form value stored under that key if one exists, else the key itself | Advances the flow by its own key and **bypasses all other field values**. `useDaVinciForm.setValue(key, …)` on a flow key auto-submits immediately with the supplied value **without storing it** in form state; `submitFlow(key)` is the explicit variant (value rule in [davinci-client.md](davinci-client.md)) |
| `LABEL` | `output` | Excluded from the payload | Render `content`, or `richContent` template text with named replacements (replacement values may carry `href`, `type`, `target`) |
| `READ_ONLY_TEXT` | `output` | Excluded from the payload | `title` (shown when `titleEnabled`), `content`, `agreementId`; no mutable value |
| `POLLING` | `polling` | Excluded from the payload; drive via `pollStatus(onStatus, { key? })` | `pollInterval`, `pollRetries`, `pollChallengeStatus`, `challenge`. `pollStatus` never auto-advances: call `next({ collectors: [...] })` explicitly on a terminal status. See [davinci-client.md](davinci-client.md) |
| `QR_CODE` | `qrCode` | Excluded from the payload | `content` is the full `data:image/...;base64,` URI; `fallbackText` is the alternative text. Android emits `key: ""` (parity gap in [davinci-client.md](davinci-client.md)) |
| Any unregistered type | `integration` / `unknown` | See the integration table below; otherwise excluded from the payload and surfaced as a non-blocking `UNSUPPORTED_COLLECTOR` issue (or listed in `unsupportedFields`) | Generic shape is `key` + `type` + optional `raw` |

## Integration-required collectors

Integration collectors have a stable `key` and `type` but no common value shape. The owning package performs its native operation **before** `next()`, and the collector's key must not appear in the `next()` payload. Register the owning package's type string in `handledCollectorTypes` so `buildNextInput`/`useDaVinciForm` do not raise blocking `INTEGRATION_REQUIRED` issues:

```ts
import { useDaVinciForm } from '@ping-identity/rn-davinci';
import { fidoCollectorType } from '@ping-identity/rn-fido';
import { protectCollectorType } from '@ping-identity/rn-protect';

const form = useDaVinciForm(node, {
  handledCollectorTypes: new Set([fidoCollectorType, protectCollectorType]),
});
```

| Type | Owning package | Constant | Flow |
|---|---|---|---|
| `SOCIAL_LOGIN_BUTTON` | `@ping-identity/rn-external-idp` | `socialLoginCollectorType` | `createExternalIdpClient(config)` **before** the node is normalized (client creation registers the collector type and the native serializer); one button per collector with the collector's `label`; `authorizeForDaVinci(daVinci, { index })` resolves `void` (the token flows through the DaVinci request pipeline), then advance with `next({ collectors: [] })` |
| `FIDO2` | `@ping-identity/rn-fido` | `fidoCollectorType` | One collector type with `action: 'REGISTER' \| 'AUTHENTICATE'`. `createFidoClient()` before the node is normalized. Run `registerForDaVinci(daVinci, { index: 0 })` or `authenticateForDaVinci(daVinci, { index: 0 })` (the ceremony must complete before `next()`), then `next({ collectors: [] })`. The FIDO collector key must NOT appear in the payload |
| `PROTECT` | `@ping-identity/rn-protect` | `protectCollectorType` | `startProtect(config)` (with the PingOne environment ID) before the first DaVinci operation; the type is registered only after initialization succeeds. Before submitting a node containing a `PROTECT` collector, call `collectProtect(daVinci)` (resolves `void`; it only collects data natively), then submit as usual |

The `index` option is the zero-based position of the target collector among the group that call counts, and defaults to `0`. The groups differ per package (verified in both native resolvers): FIDO counts registration and authentication collectors **separately**: Android resolves `FidoRegistrationCollector` and `FidoAuthenticationCollector` instances into two independent sequences, and iOS does the same, while Social Login counts all `SOCIAL_LOGIN_BUTTON` collectors on the node together. Compute the index when more than one collector can be present in the relevant group.

### Device payload note (`{ type }` map, not a bare string)

The TypeScript declaration of `DeviceRegistrationCollector.value` is `string | undefined`, and `resolveDefaultValue` treats it as a string, but **both native appliers require a map**. Android's `DaVinciCollectorValueApplier.kt` reads `asStringMap(value)["type"]` and throws `IllegalArgumentException("value map must include 'type'")` for a non-map input (its `asStringMap` returns an empty map for anything that is not a map); iOS's `DaVinciCollectorValueApplier.swift` does the same via `DaVinciBridgeError.collectorApply`. The native SDK's device collectors hold a `Device` object, so the map shape is inherent, not a bridge choice.

The working payloads are:

- Registration: `value: { type: device.type }`
- Authentication: `value: { type: device.type, id?: device.id, description?: device.description }`

Do not pass the bare `device.type` string; the applier will reject it with `DAVINCI_COLLECTOR_APPLY_ERROR`.

### Obtaining the client for integration calls

Every `*ForDaVinci` / `collectProtect` operation takes the live DaVinci client (or a matching instance contract) as its first argument, and must target the same native instance the flow is running on:

- **Provider-based app**: get it from `useDaVinciContext()?.client` with a `null` guard. Do not create a second client with `createDaVinciClient` in integration code. (`getId()` exists for cross-module targeting, but the sample-app pattern is the direct context client.)
- **Client-based app**: pass the module-scope client directly.

Reference wiring: `PingSampleApp/ui/davinci/hooks/useDaVinciClientPanelController.ts` in the React Native SDK repository (context client obtained once, then used for `collectProtect`, `registerForDaVinci`/`authenticateForDaVinci`, and `authorizeForDaVinci`).

## Submit payload rules (`buildNextInput`)

`buildNextInput(node, values, handledCollectorTypes?, flowKey?)` returns `{ canSubmit, input, issues }`:

- **Flow-collector shortcut**: when `flowKey` is provided, the payload contains only that single entry: `{ key: flowKey, value: flowKey }` when no value is stored under the key, otherwise the stored value: and no other field values.
- **`SUBMIT_BUTTON` first-only rule**: the first `SUBMIT_BUTTON` on the node is auto-added to the payload as `{ key, value: key }`; additional submit buttons are skipped. Without a non-empty submit value the native POST body lacks `actionKey`/`eventType`, so manual payload builders must include the first `SUBMIT_BUTTON` themselves.
- `output_only` collectors are excluded; `integration_required` types not present in `handledCollectorTypes` raise a blocking `INTEGRATION_REQUIRED` issue; unrecognized types raise `UNSUPPORTED_COLLECTOR`.
- Required manual collectors without a value raise `REQUIRED_VALUE_MISSING`; both it and `INTEGRATION_REQUIRED` block `canSubmit` (`canSubmit: false`). `UNSUPPORTED_COLLECTOR` is reported but non-blocking.

Issue codes:

| Code | Blocking | Fields |
|---|---|---|
| `NO_ACTIVE_CONTINUE_NODE` | yes (nothing to submit) | none |
| `REQUIRED_VALUE_MISSING` | yes | `key` |
| `INTEGRATION_REQUIRED` | yes | `key` |
| `UNSUPPORTED_COLLECTOR` | no | `key` |

## Unsupported fields

When the native SDK cannot instantiate a server field, the bridge surfaces it in `ContinueNode.unsupportedFields` (entries with `key` and the server-declared `type`). Render a placeholder, log, or block submission for these rather than silently omitting them.

## Not yet in rn-davinci 1.1.0

Roadmap items, not available in the 1.1.0 package this skill covers:

- `IMAGE` collector (SDKS-5381)
- FIDO2 error-code mapping (SDKS-5383)
- Protect Journey callbacks (SDKS-5391; the DaVinci-side `collectProtect` **is** in 1.1.0)
- Native SDK 2.2.0 dependency bump (SDKS-5515)
