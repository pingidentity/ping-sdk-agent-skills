---
name: ping-orchestration-react-native-sdk
description: >-
  Guide for building React Native apps with the Ping Identity React Native SDK (npm
  scope `@ping-identity`; packages: `rn-journey`, `rn-davinci`, `rn-oidc`, `rn-fido`,
  `rn-protect`, `rn-external-idp`, `rn-oath`, `rn-logger`, `rn-storage`). Use whenever
  the user is: (1) building a React Native app that authenticates against PingOne,
  PingOne Advanced Identity Cloud (AIC), or PingAM using Journey, DaVinci, or OIDC
  flows; (2) rendering Journey callbacks or DaVinci collectors in React Native; (3)
  configuring `createJourneyClient`, `createDaVinciClient`, or `createOidcClient`;
  (4) using `useJourney`, `JourneyProvider`, `useDaVinci`, `DaVinciProvider`,
  `useOidc`, or `OidcProvider`; (5) wiring OIDC redirect URIs; (6) adding FIDO
  passkeys to a Journey or DaVinci flow, or PingOne Protect to a DaVinci flow;
  (7) scaffolding a new React Native project. Invoke even when phrased loosely:
  "add Journey to my React Native app", "add DaVinci login to my React
  Native app", "use rn-davinci".
license: MIT
metadata:
  author: Ping Identity
  version: "1.1.0"
---

## Project-Type Guard

Run this check before Step W1 and before any generation, whenever the request concerns an existing app ("this app", "my app", "add authentication to my project") rather than a new project.

If a `package.json` is present in the working directory, run:

```bash
grep -E '"(react-native|react-dom|vite|next|vue|@angular/core)"[[:space:]]*:' package.json
```

- `react-native` in the output → React Native project → continue normally.
- A web marker (`react-dom`, `vite`, `next`, `vue`, `@angular/core`) in the output but no `react-native` line → the project is a web app, and the React Native SDK packages are native-backed and cannot run in it. Stop the wizard and do not generate React Native code. Do not name any `@ping-identity/rn-*` package for this project, not even as an alternative or a "migrate to native later" option. Tell the user the project is a web app, route to `ping-orchestration-javascript-sdk` (which delegates DaVinci flows to `ping-orchestration-reactjs-davinci-sdk`), and answer their underlying question in web terms.
- No output, or no `package.json` → nothing to detect → continue.

Scaffolding a new React Native project (intent **A**, or `create-sample` with `output-dir`) is never gated by this check.

## Skill Parameters

When invoked with no arguments, run the wizard. With arguments, generate inline.

### No-arg Invocation — Wizard Mode

**Step W1 — Determine intent** using `AskUserQuestion`:

```
"What would you like to do?"
Options:
  A) Scaffold a new React Native project  — complete working app with Ping SDK wired in
  B) Add to an existing app               — generate only the files to drop into your project
  C) Browse the reference guide           — show the full integration guide
  D) Something else                       — let me describe what I need
```

- **A/B** → Step W2
- **C** → read and display [references/integration-guide.md](references/integration-guide.md). Stop.
- **D** → follow-up free-text question, route accordingly.

**Step W2 — Flow type** (options A and B only) using `AskUserQuestion`:

```
"Which authentication flow do you need?"
Options:
  1) Journey        — native in-app UI, targets PingAM / PingOne AIC
  2) OIDC Web       — browser-based login, any OIDC provider
  3) Journey + OIDC — both flows in one app, FlowPicker as the entry screen
  4) DaVinci        - orchestrated flows against PingOne via @ping-identity/rn-davinci
```

- **1** → store `flowType = 'journey'`
- **2** → store `flowType = 'oidc'`
- **3** → store `flowType = 'both'`; collect parameters for both Journey and OIDC in W3; ask W2.5 and W2.6 as normal for the Journey portion; generate both sets of screens plus `FlowPicker`; install combined package set (Journey full tier + `rn-oidc`)
- **4** → store `flowType = 'davinci'`; ask in the following order W1c, W2.7, and W2.8; skip W1b, W2.5, and W2.6. There is no combined Journey + DaVinci option.

DaVinci uses OIDC underneath for the token exchange, but the flow itself returns the authorization code: there is no browser redirect and no separate OIDC setup. Redirect wiring is needed only for the Social Login integration (W2.8 Full tier). See [references/davinci-client.md](references/davinci-client.md).

**Step W1b — Journey export offer** (Journey only, skip when `flowType = 'oidc'` or `'davinci'`; `create-sample` uses this branch when its flow is `journey` or `both` and the user supplies or asks to use a Journey export).

Ask using `AskUserQuestion`:

```
"Do you have a Journey export JSON file? I can analyse it to identify the exact callbacks your Journey uses and pre-populate the callback tier."
Options:
  A) Yes, I will attach it as a file
  B) No, skip this step
```

- **A** → follow the Export file protocol below, running Section 7 (Journey Export Analysis, [references/journey-export-analysis.md](references/journey-export-analysis.md)) before Step W2.5. Pre-populate `journeyName` and `callbackTier` from the analysis. Ask Step W2.5 (callback mode) as usual — `callbackMode` cannot be inferred from the export and must still be asked.
- **B** → continue as normal.

**Export file protocol** (applies to the option **A** branches of W1b and W1c, and when `create-sample` routes to either branch).

If the user has not already provided a readable export file, ask them to attach the exported JSON file (or give its path on disk), then **stop and wait**. Do not continue to any later step in the same turn. Do not ask the user to paste the JSON into the chat: exports are large and get truncated.

- If a readable file is already provided or the next message provides one (attachment or path): read the whole file, then run the analysis named in the matching step's option **A**.
- If the user pastes the JSON inline and it is incomplete or not valid JSON, do not analyse it. Ask for the file instead.
- If the next message provides neither, ask again for the file. Only move on without it when the user explicitly says to skip or that they do not have it. Never treat a missing file as a "no".

**Step W1c: DaVinci flow export offer** (DaVinci only, skip when `flowType` is not `'davinci'`; `create-sample` uses this branch when its flow is `davinci` and the user supplies or asks to use a DaVinci export).

Ask using `AskUserQuestion`:

```
"Do you have a DaVinci flow export JSON file (Download Flow JSON from the DaVinci console)? I can analyse it to identify which integration packages (`rn-fido`, `rn-protect`, `rn-external-idp`) your flow needs and pre-select the collector tier."
Options:
  A) Yes, I will attach it as a file
  B) No, skip this step
```

- **A** → follow the Export file protocol above, running the analysis in [references/davinci-export-analysis.md](references/davinci-export-analysis.md) before Step W2.7 and pre-selecting `collectorTier`. Protect is only a candidate signal; confirm it with the user in W2.8.
- **B** → continue as normal.

**Step W2.5 — Callback handling** (Journey only, skip when `flowType = 'oidc'` or `'davinci'`) using `AskUserQuestion`:

```
"How would you like to handle Journey callbacks?"
Options:
  A) Managed (Recommended) — useJourneyForm handles field state, validation,
     and payload building. Simpler code; less boilerplate.
  B) Manual                 — useJourney only. You control field state and
     build the submit payload yourself. More flexibility, more code.
```

Store the answer as `callbackMode` (`managed` or `manual`). Used in step 4 to pick the correct `CallbackRenderer` template.

**Step W2.6 — Callback tier** (Journey only, skip when `flowType = 'oidc'` or `'davinci'`) using `AskUserQuestion`:

```
"Which callbacks does your Journey use?"
Options:
  A) Basic     — username, password, text, choice, T&C, KBA.
                 No extra packages needed beyond rn-journey.
  B) Standard  — Basic + FIDO passkeys, device binding, device profile.
                 Adds: rn-fido, rn-binding, rn-device-profile.
  C) Full      — Standard + social / external IdP (Google, Apple, Facebook).
                 Adds: rn-external-idp.
```

Store the answer as `callbackTier` (`basic`, `standard`, or `full`). Used in steps 4 and 5 to pick the correct templates and install commands.

**Step W2.7: Collector handling** (DaVinci only, skip when `flowType` is not `'davinci'`) using `AskUserQuestion`:

```
"How would you like to handle DaVinci collectors?"
Options:
  A) Managed (Recommended) - useDaVinciForm handles field state, defaults,
     and payload building. Simpler code; less boilerplate.
  B) Manual                 - useDaVinci only. You control field state and
     build the submit payload yourself. More flexibility, more code.
```

Store the answer as `collectorMode` (`managed` or `manual`). Used in step 4 to pick the renderer template (`DaVinciCollectorRenderer.form` for managed, `DaVinciCollectorRenderer` for manual).

**Step W2.8: Collector tier** (DaVinci only, skip when `flowType` is not `'davinci'`) using `AskUserQuestion`:

```
"Which collectors does your DaVinci flow use?"
Options:
  A) Basic     - All core collectors (text, password, selects, phone,
                 boolean, label, read-only, devices, polling, QR, submit,
                 flow). No integrations.
                 No extra packages needed beyond rn-davinci.
  B) Standard  - Basic + FIDO passkeys, Protect.
                 Adds: rn-fido, rn-protect.
  C) Full      - Standard + social login (Google, Apple, Facebook).
                 Adds: rn-external-idp.
```

Store the answer as `collectorTier` (`basic`, `standard`, or `full`). If the W1c analysis identified integrations, pre-select the tier that covers them (FIDO or Protect: Standard or Full; Social Login: Full) and confirm with the user. Unlike the Journey tiers, the DaVinci tiers never gate core collectors: the flow, not the tier, decides which core collectors appear, so every tier generates all 15 core collector views. Tiers differ only in integration views, handlers, and packages. Used in steps 4 and 5 via [references/davinci-scaffold.md](references/davinci-scaffold.md).

**Step W3 — Collect configuration.**

Ask all required parameters in a single `AskUserQuestion`. Show defaults where they exist. Do not generate until every required field has a value.

**Common parameters (all flows):**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `appName` | Scaffold only | `PingDemo` | App name. **Only ask when intent is A (scaffold)**. For intent B (add to existing), skip this and never prompt for it: the name is derived from the existing app's `package.json` (see Existing app in [references/output-modes.md](references/output-modes.md)), with `PingDemo` as the fallback. |
| `clientId` | Yes | — | OAuth 2.0 Client ID |
| `redirectUri` | Yes | — | OAuth 2.0 redirect URI (custom scheme, e.g. `com.example.app://callback`) |
| `discoveryEndpoint` | Yes | — | Full `.well-known/openid-configuration` URL |
| `scopes` | No | `openid profile email` | Space-separated OAuth 2.0 scopes |

**Journey-only additional parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `serverUrl` | Yes | — | PingAM/AIC base URL, no trailing `/` |
| `realm` | No | `alpha` | Authentication realm |
| `cookieName` | No | `iPlanetDirectoryPro` | Session cookie name |
| `journeyName` | No | `Login` | Journey tree name |

**DaVinci-only additional parameters:** DaVinci has no `serverUrl`, `realm`, `cookieName`, or `journeyName`; the flow is resolved from `discoveryEndpoint`. For DaVinci, `redirectUri` must match the DaVinci application's configured redirect URI (it is used inside the flow's authorize request, not for OS-level navigation), and `scopes` always includes `openid` because the native default is an empty scope set.

| Parameter | Required | Default | Description |
|---|---|---|---|
| `timeout` | No | `15000` | Network timeout in milliseconds |
| `acrValues` | No | None | Authentication context class reference values |
| `par` | No | None | Use pushed authorization requests (boolean; omit unless the user asks) |
| `storage` | No | No | Whether to use custom token storage (`rn-storage`) |
| `logger` | No | No | Whether to add an SDK logger (`rn-logger`) |
| `pingOneEnvironmentId` | Standard and Full tier only | None | PingOne environment ID passed to `startProtect` (`rn-protect`) |

See [references/davinci-client.md](references/davinci-client.md) for the remaining optional `modules.oidc` fields, which are not wizard questions.

**Validation rules:**
- `redirectUri` must use a custom scheme (not `http://` or `https://`) for Journey, OIDC, and the DaVinci Full tier. For the other DaVinci tiers it only has to match the DaVinci application.
- `discoveryEndpoint` must start with `https://` and end with `/.well-known/openid-configuration`.
- `scopes` must include `openid`. If missing, prepend it and warn.
- `serverUrl` (Journey) must start with `https://` and have no trailing `/`.

**Step W3.5 — Output path.** Ask where to write the files using `AskUserQuestion`:

```
"Where should the files be written?"
Options:
  A) Current working directory  — write files to the project root
  B) Specify a path             — I'll provide an absolute or relative path
  C) Print to chat only         — show the code inline, don't write to disk
```

- **A** → use the current working directory as `outputDir`.
- **B** → follow-up free-text question: "Enter the output directory path:". Use that value as `outputDir`.
- **C** → set `outputDir = null` (inline output only).

> **Scaffold intent note:** When intent is **A (Scaffold a new project)** and `outputDir` is set, the React Native project will be initialised as `<outputDir>/<appName>/`. All Ping SDK files are written into that subdirectory. The final structure is `<outputDir>/<appName>/` containing the generated project.

**Step W4 — Confirm and generate.** Summarise collected values (including output path) in a short table, ask "Ready to generate — does this look right?", then proceed on confirmation.

**Generate.** Follow [references/output-modes.md](references/output-modes.md): **New project** when intent is **A** and `outputDir` is set, **Existing app** when intent is **B** and `outputDir` is set, **Print only** when `outputDir` is `null`. The mode takes the file content, root component, and install command from the flow module for `flowType` (J, O, P, or D steps), through the table in that file.

---

### Parameters (with-args invocation)

| Parameter | Syntax | Purpose |
|---|---|---|
| `create-sample` | `create-sample "<description>"` | Generate a complete runnable sample for the described flow |
| `flow` | `flow journey`, `flow oidc`, `flow both`, or `flow davinci` | Set the flow type explicitly |
| `app-name` | `app-name "<name>"` | Set the app name. Defaults to `"PingDemo"` if omitted. |
| `output-dir` | `output-dir "<path>"` | Parent directory for the generated project (absolute or relative). When set, `create-sample` scaffolds a new project at `<output-dir>/<appName>/`. When omitted, nothing is written to disk and the code is printed only. |

### `create-sample "<description>"`

1. **Analyse** the description — identify flow type (`journey`, `oidc`, `both`, or `davinci`).
2. For `journey` or `both`, if the user supplies or asks to use a Journey export, run W1b's option A path and the analysis in [references/journey-export-analysis.md](references/journey-export-analysis.md) before collecting the callback tier. For `davinci`, if the user supplies or asks to use a DaVinci export, run W1c's option A path and the analysis in [references/davinci-export-analysis.md](references/davinci-export-analysis.md) before collecting the collector tier. Follow the Export file protocol above; use the results to pre-select the tier as W1b/W1c specify. If no export is provided or requested, skip export analysis.
3. **Ask one clarifying question** only if the flow type is genuinely ambiguous. Otherwise collect the flow-type choices (W2.5 and W2.6 for Journey and `both`; W2.7 and W2.8 for DaVinci), then the required parameters for the detected flow (see W3 tables), in a single `AskUserQuestion` with an explicit "I can use placeholders" option. When analysis pre-selects a tier, confirm it with the user rather than silently treating it as final.
4. **Resolve the app name** from `app-name` or use `"PingDemo"`.
5. **Generate**, substituting all placeholder values. The files, root component, and install command come from the flow module for the detected flow, through the table in [references/output-modes.md](references/output-modes.md), with the Ping theme.
   - **`output-dir` is defined:** set `outputDir` to its value, use `intent = A`, and follow [New project](references/output-modes.md#new-project). This creates `<outputDir>/<appName>/`, runs the init command, and installs dependencies.
   - **`output-dir` is not defined:** set `outputDir = null` and follow [Print only](references/output-modes.md#print-only). Nothing is written to disk and no packages are installed. Never fall back to the current working directory.

**Examples:**

```
/ping-orchestration-react-native-sdk create-sample "username and password login using Journey"
/ping-orchestration-react-native-sdk create-sample "OIDC browser login with sign-out" app-name "MyApp"
/ping-orchestration-react-native-sdk create-sample "Journey login with FIDO passkey registration" app-name "FidoDemo"
/ping-orchestration-react-native-sdk create-sample "DaVinci login with username and password"
/ping-orchestration-react-native-sdk create-sample "Journey login" app-name "MyApp" output-dir "~/projects"
/ping-orchestration-react-native-sdk flow journey
/ping-orchestration-react-native-sdk flow oidc
```

---

## UnsupportedCallbackView

`UnsupportedCallbackView` is the standard fallback for any callback with `executionMode === 'integration_required'` or `'unsupported'` that the app does not yet handle (e.g. `PingOneProtectInitializeCallback`, `ReCaptchaEnterpriseCallback`). All form-managed `CallbackRenderer` variants generate it automatically. Manual-mode renderers should also include it as the `default` branch in their callback switch.

## Reference Files

- [references/integration-guide.md](references/integration-guide.md) — Full integration guide: installation, Journey, OIDC, FIDO, Push, common pitfalls
- [references/journey-client.md](references/journey-client.md) — Full `createJourneyClient` config, `JourneyConfig`, all hook actions, `JourneyNextInput`
- [references/callbacks.md](references/callbacks.md) — All callback types, `useJourneyForm` conjunction pattern and when to use it, execution modes
- [references/oidc-client.md](references/oidc-client.md) — Full `OidcClientConfig`, `createOidcWebClient`, all `useOidc` actions, error codes
- [references/common-mistakes.md](references/common-mistakes.md) — RN-specific gotchas: client scope, navigation, callback index, OIDC redirect, platform minimums
- [references/oath.md](references/oath.md) — `createOathClient`, TOTP/HOTP credential management, policy evaluator, error codes
- [references/journey-export-analysis.md](references/journey-export-analysis.md) — Journey export JSON analysis steps (A1–A8), node→callback mapping table
- [references/davinci-client.md](references/davinci-client.md): `createDaVinciClient` and `DaVinciConfig`, `useDaVinci`, `DaVinciProvider`, `useDaVinciForm`, the key-indexed `next()` contract (differs from Journey), node shapes, error codes, native dependencies
- [references/davinci-collectors.md](references/davinci-collectors.md): collector-to-payload mapping table, execution modes, integration-required collectors (Social Login, FIDO, Protect)
- [references/davinci-export-analysis.md](references/davinci-export-analysis.md): DaVinci flow export JSON analysis steps (A1-A7), integration detection, tier pre-selection
- [references/davinci-scaffold.md](references/davinci-scaffold.md): DaVinci scaffold steps D1-D5 (templates, config module, `App.tsx`, install command, tier prerequisites)
- [references/journey-scaffold.md](references/journey-scaffold.md): Journey scaffold steps J1-J5 (callback views, screens, client file, `App.tsx`, install command)
- [references/oidc-scaffold.md](references/oidc-scaffold.md): OIDC scaffold steps O1-O3 (screens, `App.tsx`, install command)
- [references/journey-oidc-scaffold.md](references/journey-oidc-scaffold.md): Journey + OIDC scaffold steps P1-P3 (flow-specific screen names, `FlowPicker`, `App.tsx`, install command)
- [references/output-modes.md](references/output-modes.md): New project, Existing app, and Print only: what each mode writes, runs, and launches, and which flow-module steps it follows
- [references/platform-setup.md](references/platform-setup.md): Android and iOS native setup: platform minimums, Android JVM-target flags, OIDC redirect wiring, and per-package setup (FIDO, social login, Protect, device profile, binding, push)
