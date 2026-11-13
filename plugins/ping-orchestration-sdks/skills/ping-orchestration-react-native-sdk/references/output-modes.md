# Output Modes

Read this file after Step W4, once the wizard has collected `intent`, `flowType`, and `outputDir`. The mode decides what is written, where, and what is run. The flow modules decide what the files contain, so every mode takes its file content, root component, and install command from the table in Flow modules below.

| `intent` | `outputDir` | Mode |
|---|---|---|
| A (scaffold a new project) | set | [New project](#new-project) |
| B (add to an existing app) | set | [Existing app](#existing-app) |
| A or B | `null` | [Print only](#print-only) |

`create-sample` uses `intent = A` and takes `outputDir` from its `output-dir` argument: **New project** when `output-dir` is given, **Print only** when it is omitted (see `create-sample` in SKILL.md).

## Flow modules

Each mode needs the same three things from the chosen flow. Follow the listed steps, in order:

| Concern | Journey | OIDC | Journey + OIDC | DaVinci |
|---|---|---|---|---|
| Views, screens, and client or config files | [J1-J3](journey-scaffold.md) | [O1](oidc-scaffold.md) | J1 and J3 of [journey-scaffold.md](journey-scaffold.md), then [P1](journey-oidc-scaffold.md) | [D1-D3](davinci-scaffold.md) |
| Root component | [J4](journey-scaffold.md) | [O2](oidc-scaffold.md) | [P2](journey-oidc-scaffold.md) | [D4](davinci-scaffold.md) |
| Install command and platform setup | [J5](journey-scaffold.md) | [O3](oidc-scaffold.md) | [P3](journey-oidc-scaffold.md) | [D5](davinci-scaffold.md) |

---

## New project

Intent is **A** and `outputDir` is set.

1. Run the React Native scaffold command first using the Bash tool:
   ```bash
   npx @react-native-community/cli@latest init <AppName> --directory <outputDir>/<AppName>
   ```
   Wait for it to complete before writing any files. If it fails, report the error and stop.

2. Set `projectDir = <outputDir>/<AppName>`.

3. **Apply Ping Identity branding and copy templates** — always do this before writing any screen files.

   - Read `assets/PingTheme.tsx.template` from this skill and write it to `<projectDir>/src/theme/PingTheme.tsx` (no substitutions needed).
   - Copy `assets/ping_logo.png` from this skill to `<projectDir>/src/assets/ping_logo.png`.
   - Create the directory `<projectDir>/src/callbacks/` (`src/collectors/` when `flowType = 'davinci'`).

   All generated screens import branded components from `../theme/PingTheme` — never inline ad-hoc styles.

   Branded components available: `PingPrimaryButton`, `PingHeaderView`, `PingTextField`, `PingSecureField`, `PingErrorMessage`, `PingErrorCard`, `PingLoadingOverlay`. Color tokens: `PingColors.red`, `PingColors.redDark`, `PingColors.textField`, etc.

4. **Write the views, screens, and client or config files** — read each template from this skill's `assets/` directory and write it to the project. Do not generate these files from memory; always read the template first. Follow the first row of the Flow modules table.

5. **Overwrite `<projectDir>/App.tsx`** with the root component from the second row of the Flow modules table.

6. **Install** with the command in the third row of the Flow modules table, run with the Bash tool from `<projectDir>`.

7. **Launch** the app as described in Launch below.

8. Report what was scaffolded with a summary of next steps: the placeholders to fill in, and the items [platform-setup.md](platform-setup.md) assigns to the user (server-side hosting and provider console setup).

---

## Existing app

Intent is **B** and `outputDir` is set. The app already exists: do **not** run `npx react-native init` or any scaffold command. Set `projectDir = outputDir`. `appName` is never asked: derive it from the `name` in `<projectDir>/package.json` by dropping any `@scope/` prefix, splitting on `-`, `_`, `.` and spaces, and capitalising and joining the parts (`my-app` becomes `MyApp`). Use `PingDemo` only if `package.json` cannot be read or the result does not start with a letter.

1. **Check before writing.** Before writing any file, check whether the target path already exists. If it does, show what differs and ask before replacing it; never overwrite silently.

2. **Choose the theme.** Every template imports `../theme/PingTheme`, whatever the flow, so ask the user using `AskUserQuestion`:
   ```
   "Which theme should the generated screens use?"
   Options:
     A) Ping theme     — copy PingTheme and the logo; the screens work as generated
     B) My app's theme — keep the app's own theme; I'll adapt the screens to its components
   ```
   - **A** → copy `assets/PingTheme.tsx.template` to `src/theme/PingTheme.tsx` and `assets/ping_logo.png` to `src/assets/ping_logo.png` as in New project step 3.
   - **B** → copy neither. After step 3 has written the screens, replace every import from `../theme/PingTheme` and every use of `PingPrimaryButton`, `PingHeaderView`, `PingTextField`, `PingSecureField`, `PingErrorMessage`, `PingErrorCard`, `PingLoadingOverlay`, and `PingColors` with the app's own equivalent, found by reading the app's existing theme or components. If the app has no equivalent for one of them, tell the user which one and ask how to proceed; do not invent a component or fall back to inline styles.

3. **Write the views, screens, and client or config files** from the first row of the Flow modules table, with `outputDir` as `<projectDir>`.

4. **Merge the root component; do not overwrite it.** Present the example in the second row of the Flow modules table as the merge pattern instead: wrap the existing root (or its existing navigator) in the flow's provider (`JourneyProvider`, `OidcProvider`, both, or `DaVinciProvider`), keep a single `NavigationContainer`, register the flow's routes in the app's own param list, and adapt any `RootStackParamList` import in the written screens (the DaVinci screens import it from `../../App`).

5. **Install** with the command in the third row of the Flow modules table, run with the Bash tool from `outputDir` instead of a new scaffold directory.

6. **Apply the native setup**, following [platform-setup.md](platform-setup.md): its Baseline section, plus the section for each flow or package in use. For OIDC and Journey + OIDC that includes the redirect URI scheme wiring (Android `manifestPlaceholders`, iOS `CFBundleURLTypes`), with the scheme taken from the `redirectUri` collected in Step W3. For DaVinci, only the Full tier needs the redirect wiring (D5 of [davinci-scaffold.md](davinci-scaffold.md)). Edit the app's existing native files (`android/app/build.gradle`, the iOS `Info.plist`, and so on) with targeted changes rather than replacing them, and if a key you would add already exists, show it and ask. Apply it once: the install step of the flow module points to the same file.

7. **Launch** the app as described in Launch below.

8. Report what was generated with a summary of remaining next steps: the placeholders to fill in, and the items [platform-setup.md](platform-setup.md) assigns to the user (server-side hosting and provider console setup).

---

## Print only

`outputDir` is `null`. Nothing is written to disk, no command is run, and the app is not launched. `appName` defaults to `PingDemo` and is never asked.

1. Print every file that Existing app step 3 would write, plus `PingTheme.tsx` (there is no app theme to read, so the screens assume the Ping theme), each with a `// --- <path> ---` header showing its intended path, with all placeholder values substituted.

2. Print the root component:
   - Intent **A** — there is no existing app: print the complete root component from the second row of the Flow modules table as a usable `App.tsx`.
   - Intent **B** — print the merge pattern from Existing app step 4.

3. Print the install command from the third row of the Flow modules table for the user to run, and the sections of [platform-setup.md](platform-setup.md) that apply to the flow.

4. Print the run commands from Launch below for the user to run.

---

## Launch

Used by New project and Existing app.

**Consent gate:** Before any launch-related action, ask the platform question below using `AskUserQuestion` and wait for the user's answer. Launch-related actions include checking emulator or device state, checking whether Metro is running, starting or restarting Metro, building or installing the app on a device or simulator, and capturing a screenshot. Approval to scaffold the project does not grant approval to launch it. Static checks such as type-checking and linting do not require launch approval. If the user selects **Skip**, do not run launch-related commands; provide the manual run commands instead.

Ask the user which platform(s) to launch using `AskUserQuestion`:
```
"Launch the app now?"
Options:
  A) iOS    — run on booted iOS simulator
  B) Android — run on booted Android emulator / connected device
  C) Both   — launch iOS and Android
  D) Skip   — I'll run it manually
```

For each selected platform, start Metro in the background first (if not already running), then run the app:

**iOS:**
```bash
# Start Metro in background
cd <projectDir> && npx react-native start --reset-cache &
# Wait ~5s for Metro to be ready, then build and install
cd <projectDir> && npx react-native run-ios --no-packager
```

**Android** (requires a booted emulator or connected device — check with `adb devices` first):
```bash
cd <projectDir> && npx react-native run-android --no-packager
```

After launching, take a simulator/emulator screenshot and show it to the user to confirm the app is running. The expected first screen is either a loading spinner (Journey starting) or an error view with "Try again" (placeholder server URL — correct behaviour).
