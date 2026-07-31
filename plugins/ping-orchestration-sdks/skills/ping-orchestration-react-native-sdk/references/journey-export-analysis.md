# Journey Export Analysis

When the user provides a Journey export JSON (exported from the PingOne / AIC Platform UI), run this analysis before writing any TypeScript/TSX. The goal is to discover every callback the React Native app must handle so the generated sample is an exact match to the server-side Journey.

## Export Format

```
trees/
  <TreeName>/
    tree/
      nodes      — layout + connections map; each entry has nodeType and connections
      staticNodes — Success / Failure terminal nodes
    nodes        — full config; _type._id is the canonical node class name
    scripts      — JS scripts keyed by UUID, referenced by ScriptedDecisionNode
    innerNodes   — (usually empty; inner trees appear as sibling tree entries)
```

Inner trees appear as separate top-level entries in `trees` and are linked via `InnerTreeEvaluatorNode` (its `tree` field names the inner tree). Analyse every tree, not just the entry tree.

## Analysis Steps

**A1 — Enumerate trees.** List every key in `trees`. Identify the entry tree (referenced from `meta` or inferred as the one not referenced by any `InnerTreeEvaluatorNode`). Mark the rest as inner trees.

**A2 — Collect node types.** For every node in each tree's `nodes` object, record `_type._id`. This is the authoritative node class name.

**A3 — Map to SDK callbacks.**

| `_type._id` | SDK callback / notes |
|---|---|
| `UsernameCollectorNode` | `NameCallback` |
| `PasswordCollectorNode` | `PasswordCallback` |
| `DataStoreDecisionNode` | No UI — server-side credential validation |
| `SessionDataNode` | No UI — reads session token into shared state |
| `WebAuthnRegistrationNode` | `FidoRegistrationCallback` |
| `WebAuthnAuthenticationNode` | `FidoAuthenticationCallback` |
| `InnerTreeEvaluatorNode` | No UI — recurse into the named inner tree |
| `ScriptedDecisionNode` | See A4 — may produce callbacks |
| `MessageNode` | Info message + confirm button; use `message.en` text |
| `ChoiceCollectorNode` | `ChoiceCallback` |
| `AttributeCollectorNode` | `StringAttributeInputCallback` / `BooleanAttributeInputCallback` |
| `KbaCreateNode` | `KbaCreateCallback` |
| `TermsAndConditionsNode` | `TermsAndConditionsCallback` |
| `DeviceProfileNode` | `DeviceProfileCallback` |
| `DeviceBindingNode` | `DeviceBindingCallback` |
| `DeviceSigningVerifierNode` | `DeviceSigningVerifierCallback` |
| `PingOneProtectInitializeNode` | `PingOneProtectInitializeCallback` ⚠️ not yet supported — render `UnsupportedCallbackView` |
| `PingOneProtectEvaluationNode` | `PingOneProtectEvaluationCallback` ⚠️ not yet supported — render `UnsupportedCallbackView` |
| `SelectIdpNode` | `SelectIdpCallback` (Full tier) |
| `SocialProviderHandlerNode` | `IdpCallback` (Full tier) |
| `PollingWaitNode` | `PollingWaitCallback` |

**A4 — Inspect scripts.** For each `ScriptedDecisionNode`, look up its `script` UUID in `scripts`. The `script` field is a JSON-encoded string — unescape `\"` and `\\n` before reading. In the decoded JavaScript, look for:

- **Callback construction**: `new NameCallback(...)`, `new PasswordCallback(...)`, `new TextOutputCallback(...)`, `new ConfirmationCallback(...)`, etc. These are sent to the device and must be handled by the React Native app exactly like callbacks from a native node. Add them to the callback list.
- **`callbackFactory` / `action.goTo().withCallbacks()` patterns**: extract every callback class name referenced.
- **State reads/writes**: `nodeState.get(...)`, `sharedState.get(...)`, `nodeState.putShared(...)` — note keys downstream nodes depend on.
- **Routing-only scripts**: if the script only reads state and sets `outcome`, mark it "server-side routing, no callbacks" — no RN UI needed.

**A5 — Trace the flow.** Follow `connections` from the entry node through all outcomes (including inner tree `true`/`false`) to the Success and Failure static nodes. Identify which paths lead to authentication vs registration.

**A6 — Determine callback tier.**
- Any of `WebAuthnRegistrationNode`, `WebAuthnAuthenticationNode`, `DeviceBindingNode`, `DeviceSigningVerifierNode`, `PingOneProtectInitializeNode`, `PingOneProtectEvaluationNode` → **Standard** minimum.
- `SocialProviderHandlerNode` or `SelectIdpNode` → **Full**.
- Otherwise → **Basic**.

**A7 — Extract configuration.**
- `journeyName` — entry tree key in `trees`.
- `callbackTier` — from A6; default `callbackMode` to `managed` (ask the user to confirm in Step W2.5).
- `relyingPartyDomain` (from `WebAuthnRegistrationNode` / `WebAuthnAuthenticationNode`) → hint for `serverUrl`.
- `origins` — FIDO registered origins; warn if the target iOS bundle ID or Android package name is missing.
- `userVerificationRequirement` — if `REQUIRED`, note biometric/PIN is enforced.

**A8 — Report, then generate.** Output a plain-text summary (tree names, node→callback mapping, identified flows, tier, FIDO origins warnings) before writing any TypeScript/TSX. The generated `CallbackRenderer` must handle exactly the callbacks identified — no more, no less.

## Special Cases

**Inner tree as registration fallback.** When `InnerTreeEvaluatorNode` is wired to `failure`/`noDevice` outcomes, the React Native app receives different callback sets on different steps. Distinguish screens by inspecting which callbacks are present in the current node (e.g. only `FidoAuthenticationCallback` → auth screen; `NameCallback` + `PasswordCallback` → registration form).

**`MessageNode`.** Map to a `TextOutputCallback`-style view showing `message.en` with a single "Continue" button.
