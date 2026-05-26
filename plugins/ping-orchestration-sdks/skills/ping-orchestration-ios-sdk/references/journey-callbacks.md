# Journey Callback Implementations

This file contains SwiftUI implementations for all Standard-tier Journey callbacks.
Read this file when generating a Journey app with `callbackTier = basic` or `callbackTier = standard`.

## Critical API Facts — Read Before Writing Any Callback View

These are the exact property and method names as defined in the SDK source. Getting these wrong
causes compile errors. Do NOT guess — use only what is listed here.

### ValidatedUsernameCallback
- `.username` — read/write `String` (NOT `.value`)
- `.prompt` — read-only `String`
- `.failedPolicies` — read-only `[FailureCallback]`, each has `.failedDescription(for: String) -> String`

### ValidatedPasswordCallback
- `.password` — read/write `String` (NOT `.value`)
- `.prompt` — read-only `String`
- `.failedPolicies` — read-only array (same as above)

### ConfirmationCallback
- `.options` — read-only `[String]` (NOT `.choices`)
- `.selectedIndex` — write `Int?` (optional, NOT `Int`)
- `.prompt` — read-only `String`

### TermsAndConditionsCallback
- `.accepted` — read/write `Bool` (NOT `.accept`)
- `.terms` — read-only `String`
- `.version` — read-only `String`
- `.createDate` — read-only `String`

### ConsentMappingCallback
- `.accepted` — read/write `Bool` (NOT `.accept`)
- `.displayName` — read-only `String`
- `.name` — read-only `String`
- `.message` — read-only `String`

### KbaCreateCallback
- `.selectedQuestion` — read/write `String`
- `.selectedAnswer` — read/write `String` (NOT `.answer`)
- `.predefinedQuestions` — read-only `[String]`
- `.allowUserDefinedQuestions` — read-only `Bool`

### SelectIdpCallback (from PingExternalIdP)
- `.providers` — read-only `[IdPValue]`
- `.value` — read/write `String` — set to `provider.provider` before calling `onNext()`
- `IdPValue` has `.provider: String` and `.uiConfig: [String: Any]`
  - `uiConfig` is a plain dictionary, NOT a struct — access keys like `uiConfig["buttonDisplayName"]`
  - There is NO `.setProvider(_:)` method on the callback; assign `.value` directly

### DeviceProfileCallback (from PingDeviceProfile)
- `.collect() async -> Result<[String: any Sendable], Error>` — call and await; result can be discarded
- There is NO `.getData()` method

### DeviceBindingCallback (from PingBinding)
- `.bind(config: (DeviceBindingConfig) -> Void = { _ in }) async -> Result<[String: Any], Error>`
- No `window:` parameter — binding uses system biometrics internally

### DeviceSigningVerifierCallback (from PingBinding)
- `.sign(config: (DeviceBindingConfig) -> Void = { _ in }) async -> Result<[String: Any], Error>`
- No `window:` parameter

### PingOneProtectInitializeCallback (from PingProtect)
- `.start() async -> Result<Void, Error>` — call and await; result can be discarded
- There is NO `.getData()` method

### PingOneProtectEvaluationCallback (from PingProtect)
- `.collect() async -> Result<String, Error>` — call and await; result can be discarded
- There is NO `.getData()` method

---

## Basic Tier Callbacks

### NameCallbackView

```swift
struct NameCallbackView: View {
    let callback: NameCallback
    @State private var username = ""

    var body: some View {
        PingTextField(
            placeholder: callback.prompt.isEmpty ? "Username" : callback.prompt,
            text: $username,
            contentType: .username
        )
        .onChange(of: username) { callback.name = username }
    }
}
```

### PasswordCallbackView

```swift
struct PasswordCallbackView: View {
    let callback: PasswordCallback
    @State private var password = ""

    var body: some View {
        PingSecureField(
            placeholder: callback.prompt.isEmpty ? "Password" : callback.prompt,
            text: $password
        )
        .onChange(of: password) { callback.password = password }
    }
}
```

### ChoiceCallbackView

```swift
struct ChoiceCallbackView: View {
    let callback: ChoiceCallback
    @State private var selectedIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !callback.prompt.isEmpty {
                Text(callback.prompt).font(.subheadline).foregroundColor(.secondary)
            }
            Picker(callback.prompt, selection: $selectedIndex) {
                ForEach(callback.choices.indices, id: \.self) { index in
                    Text(callback.choices[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedIndex) { callback.selectedIndex = selectedIndex }
        }
    }
}
```

---

## Standard Tier — Text Input Variants

### TextInputCallbackView

```swift
struct TextInputCallbackView: View {
    let callback: TextInputCallback
    @State private var text = ""

    var body: some View {
        PingTextField(
            placeholder: callback.prompt.isEmpty ? "Enter value" : callback.prompt,
            text: $text
        )
        .onChange(of: text) { callback.text = text }
    }
}
```

### ValidatedUsernameCallbackView

**Key API**: use `.username` (not `.value`). Policy errors are in `.failedPolicies`.

```swift
struct ValidatedUsernameCallbackView: View {
    let callback: ValidatedUsernameCallback
    @State private var username = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            PingTextField(
                placeholder: callback.prompt.isEmpty ? "Username" : callback.prompt,
                text: $username,
                contentType: .username
            )
            .onAppear { username = callback.username }
            .onChange(of: username) { callback.username = username }

            if !callback.failedPolicies.isEmpty {
                ForEach(callback.failedPolicies.indices, id: \.self) { i in
                    ErrorMessageView(message: callback.failedPolicies[i].failedDescription(for: callback.prompt))
                }
            }
        }
    }
}
```

### ValidatedPasswordCallbackView

**Key API**: use `.password` (not `.value`).

```swift
struct ValidatedPasswordCallbackView: View {
    let callback: ValidatedPasswordCallback
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            PingSecureField(
                placeholder: callback.prompt.isEmpty ? "Password" : callback.prompt,
                text: $password
            )
            .onAppear { password = callback.password }
            .onChange(of: password) { callback.password = password }

            if !callback.failedPolicies.isEmpty {
                ForEach(callback.failedPolicies.indices, id: \.self) { i in
                    ErrorMessageView(message: callback.failedPolicies[i].failedDescription(for: callback.prompt))
                }
            }
        }
    }
}
```

---

## Standard Tier — Attribute Input Callbacks

### StringAttributeCallbackView

```swift
struct StringAttributeCallbackView: View {
    let callback: StringAttributeInputCallback
    @State private var value = ""

    var body: some View {
        PingTextField(
            placeholder: callback.prompt.isEmpty ? callback.name : callback.prompt,
            text: $value
        )
        .onChange(of: value) { callback.value = value }
    }
}
```

### BoolAttributeCallbackView

```swift
struct BoolAttributeCallbackView: View {
    let callback: BooleanAttributeInputCallback
    @State private var isOn = false

    var body: some View {
        Toggle(callback.prompt.isEmpty ? callback.name : callback.prompt, isOn: $isOn)
            .tint(.pingRed)
            .onChange(of: isOn) { callback.value = isOn }
    }
}
```

### NumberAttributeCallbackView

```swift
struct NumberAttributeCallbackView: View {
    let callback: NumberAttributeInputCallback
    @State private var text = ""

    var body: some View {
        PingTextField(
            placeholder: callback.prompt.isEmpty ? callback.name : callback.prompt,
            text: $text
        )
        .keyboardType(.numberPad)
        .onChange(of: text) {
            if let number = Double(text) { callback.value = number }
        }
    }
}
```

---

## Standard Tier — Confirmation / Suspended

### ConfirmationCallbackView

**Key API**: `.options` (not `.choices`). `.selectedIndex` is `Int?`.
Self-advancing — suppress the generic Next button when present.

```swift
struct ConfirmationCallbackView: View {
    let callback: ConfirmationCallback
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if !callback.prompt.isEmpty {
                Text(callback.prompt)
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            ForEach(callback.options.indices, id: \.self) { index in
                Button(callback.options[index]) {
                    callback.selectedIndex = index
                    onNext()
                }
                .buttonStyle(PingPrimaryButtonStyle())
            }
        }
    }
}
```

### SuspendedCallbackView

Self-advancing — suppress the generic Next button when present.

```swift
struct SuspendedCallbackView: View {
    let callback: SuspendedTextOutputCallback
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(callback.message)
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Continue", action: onNext)
                .buttonStyle(PingPrimaryButtonStyle())
        }
    }
}
```

---

## Standard Tier — Polling Wait

```swift
struct PollingWaitCallbackView: View {
    let callback: PollingWaitCallback
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(callback.message.isEmpty ? "Please wait…" : callback.message)
                .font(.subheadline).foregroundColor(.secondary)
        }
        .task {
            try? await Task.sleep(nanoseconds: UInt64(callback.waitTime) * 1_000_000)
            onNext()
        }
    }
}
```

---

## Standard Tier — Terms & Conditions / Consent / KBA

### TermsAndConditionsCallbackView

**Key API**: `.accepted` (not `.accept`).

```swift
struct TermsAndConditionsCallbackView: View {
    let callback: TermsAndConditionsCallback
    @State private var accepted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Terms & Conditions").font(.headline)
            ScrollView {
                Text(callback.terms)
                    .font(.caption).foregroundColor(.secondary)
            }
            .frame(maxHeight: 160)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            Toggle("I accept the Terms & Conditions", isOn: $accepted)
                .tint(.pingRed)
                .onAppear { accepted = callback.accepted }
                .onChange(of: accepted) { callback.accepted = accepted }
        }
    }
}
```

### ConsentMappingCallbackView

**Key API**: `.accepted` (not `.accept`). Use `.displayName` for the label.

```swift
struct ConsentMappingCallbackView: View {
    let callback: ConsentMappingCallback
    @State private var accepted = false

    var body: some View {
        Toggle(callback.displayName.isEmpty ? "Accept" : callback.displayName, isOn: $accepted)
            .tint(.pingRed)
            .onAppear { accepted = callback.accepted }
            .onChange(of: accepted) { callback.accepted = accepted }
    }
}
```

### KbaCreateCallbackView

**Key API**: `.selectedQuestion` and `.selectedAnswer` (NOT `.question`/`.answer`).

```swift
struct KbaCreateCallbackView: View {
    let callback: KbaCreateCallback
    @State private var selectedQuestion = ""
    @State private var answer = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Security Question").font(.subheadline).foregroundColor(.secondary)
            Picker("Question", selection: $selectedQuestion) {
                ForEach(callback.predefinedQuestions, id: \.self) { q in
                    Text(q).tag(q)
                }
            }
            .pickerStyle(.menu)
            .tint(.pingRed)
            .onAppear {
                if selectedQuestion.isEmpty, let first = callback.predefinedQuestions.first {
                    selectedQuestion = first
                    callback.selectedQuestion = first
                }
            }
            .onChange(of: selectedQuestion) { callback.selectedQuestion = selectedQuestion }

            PingTextField(placeholder: "Answer", text: $answer)
                .onChange(of: answer) { callback.selectedAnswer = answer }
        }
    }
}
```

---

## Standard Tier — Social IdP (SelectIdp browser-based)

**Key API**: `.value = provider.provider` (assign the string, there is no `.setProvider()` method).
`IdPValue.uiConfig` is `[String: Any]` — not a struct, no `.buttonDisplayName` property.
Self-advancing — suppress the generic Next button when present.

```swift
struct SelectIdpCallbackView: View {
    let callback: SelectIdpCallback
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Select a provider").font(.headline)
            ForEach(callback.providers) { provider in
                Button(provider.provider.capitalized) {
                    callback.value = provider.provider
                    onNext()
                }
                .buttonStyle(PingPrimaryButtonStyle())
            }
        }
    }
}
```

---

## Standard Tier — FIDO

```swift
struct FidoRegistrationCallbackView: View {
    let callback: FidoRegistrationCallback
    let onNext: () -> Void

    @State private var deviceName = UIDevice.current.name
    @State private var errorMessage: String?
    @State private var isRegistering = false

    var body: some View {
        VStack(spacing: 20) {
            FidoIconView(systemName: "faceid", tint: .pingRed)
            Text("Register Passkey").font(.title2).fontWeight(.semibold)
            Text("Create a passkey for fast, secure biometric login.")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            PingTextField(placeholder: "Device Name", text: $deviceName)
            if let errorMessage { ErrorMessageView(message: errorMessage) }
            Button(action: register) {
                if isRegistering { ProgressView().tint(.white) }
                else { Text("Register with Passkey") }
            }
            .buttonStyle(PingPrimaryButtonStyle())
            .disabled(isRegistering)
        }
    }

    private func register() {
        Task {
            isRegistering = true
            defer { isRegistering = false }
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                errorMessage = "Unable to find active window."
                return
            }
            let result = await callback.register(deviceName: deviceName.isEmpty ? nil : deviceName, window: window)
            switch result {
            case .success: onNext()
            case .failure(let error): errorMessage = error.localizedDescription; onNext()
            }
        }
    }
}

struct FidoAuthenticationCallbackView: View {
    let callback: FidoAuthenticationCallback
    let onNext: () -> Void

    @State private var errorMessage: String?
    @State private var isAuthenticating = false

    var body: some View {
        VStack(spacing: 20) {
            FidoIconView(systemName: "touchid", tint: .pingRed)
            Text("Biometric Authentication").font(.title2).fontWeight(.semibold)
            Text("Use your passkey to sign in securely.")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            if let errorMessage { ErrorMessageView(message: errorMessage) }
            Button(action: authenticate) {
                if isAuthenticating { ProgressView().tint(.white) }
                else { Text("Authenticate with Passkey") }
            }
            .buttonStyle(PingPrimaryButtonStyle())
            .disabled(isAuthenticating)
        }
    }

    private func authenticate() {
        Task {
            isAuthenticating = true
            defer { isAuthenticating = false }
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                errorMessage = "Unable to find active window."
                return
            }
            let result = await callback.authenticate(window: window)
            switch result {
            case .success: onNext()
            case .failure(let error): errorMessage = error.localizedDescription; onNext()
            }
        }
    }
}
```

---

## Standard Tier — Device Profile

**Key API**: `.collect() async` (NOT `.getData()`). Takes an optional config closure.

```swift
struct DeviceProfileCallbackView: View {
    let callback: DeviceProfileCallback
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ProgressView().progressViewStyle(.circular).scaleEffect(1.4)
            Text("Gathering device profile…").font(.subheadline).foregroundColor(.secondary)
        }
        .task {
            _ = await callback.collect()
            onNext()
        }
    }
}
```

---

## Standard Tier — Device Binding / Signing

**Key API**: both `.bind()` and `.sign()` take an optional config closure — NO `window:` parameter.

```swift
struct DeviceBindingCallbackView: View {
    let callback: DeviceBindingCallback
    let onNext: () -> Void

    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            ProgressView().progressViewStyle(.circular).scaleEffect(1.4)
            Text("Binding device…").font(.subheadline).foregroundColor(.secondary)
            if let errorMessage { ErrorMessageView(message: errorMessage) }
        }
        .task {
            let result = await callback.bind()
            if case .failure(let error) = result { errorMessage = error.localizedDescription }
            onNext()
        }
    }
}

struct DeviceSigningCallbackView: View {
    let callback: DeviceSigningVerifierCallback
    let onNext: () -> Void

    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            ProgressView().progressViewStyle(.circular).scaleEffect(1.4)
            Text("Verifying device…").font(.subheadline).foregroundColor(.secondary)
            if let errorMessage { ErrorMessageView(message: errorMessage) }
        }
        .task {
            let result = await callback.sign()
            if case .failure(let error) = result { errorMessage = error.localizedDescription }
            onNext()
        }
    }
}
```

---

## Standard Tier — PingOne Protect

**Key APIs**:
- `PingOneProtectInitializeCallback.start() async -> Result<Void, Error>` (NOT `.getData()`)
- `PingOneProtectEvaluationCallback.collect() async -> Result<String, Error>` (NOT `.getData()`)

Both are self-advancing. Use a `hasStarted` guard to prevent double-execution on re-render.

```swift
struct PingOneProtectInitCallbackView: View {
    let callback: PingOneProtectInitializeCallback
    let onNext: () -> Void
    @State private var hasStarted = false

    var body: some View {
        VStack(spacing: 16) {
            ProgressView().progressViewStyle(.circular).scaleEffect(1.4)
            Text("Initializing device profile collection…")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            Task {
                _ = await callback.start()
                onNext()
            }
        }
    }
}

struct PingOneProtectEvalCallbackView: View {
    let callback: PingOneProtectEvaluationCallback
    let onNext: () -> Void
    @State private var hasStarted = false

    var body: some View {
        VStack(spacing: 16) {
            ProgressView().progressViewStyle(.circular).scaleEffect(1.4)
            Text("Collecting device profile…")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            Task {
                _ = await callback.collect()
                onNext()
            }
        }
    }
}
```

---

## AuthenticatedView (Journey)

After a `SuccessNode`, retrieve the user via `journey.journeyUser()`:

```swift
import SwiftUI
import PingJourney
import PingOrchestrate
import PingOidc

struct AuthenticatedView: View {
    let onSignOut: () -> Void

    @State private var userInfo: [String: Any]?
    @State private var isLoadingUserInfo = true
    @State private var isSigningOut = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    PingHeaderView(title: "Welcome", subtitle: "You are authenticated")
                    VStack(spacing: 20) {
                        if isLoadingUserInfo {
                            ProgressView("Loading profile…")
                        } else if let userInfo {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("User Profile").font(.headline).padding(.horizontal, 16).padding(.vertical, 12)
                                Divider()
                                ForEach(userInfo.keys.sorted(), id: \.self) { key in
                                    HStack(alignment: .top) {
                                        Text(key).font(.caption).foregroundColor(.secondary).frame(width: 110, alignment: .leading)
                                        Text(String(describing: userInfo[key] ?? "")).font(.caption)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                    Divider().padding(.leading, 16)
                                }
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                        }
                        Button("Sign Out") { Task { await signOut() } }
                            .buttonStyle(PingPrimaryButtonStyle())
                    }
                    .padding(24)
                }
            }
            if isSigningOut { LoadingOverlay("Signing out…") }
        }
        .task { await loadUserInfo() }
    }

    private func loadUserInfo() async {
        isLoadingUserInfo = true
        defer { isLoadingUserInfo = false }
        guard let user = await AppJourney.shared.journey.journeyUser() else { return }
        if case .success(let info) = await user.userinfo(cache: false) { userInfo = info }
    }

    private func signOut() async {
        isSigningOut = true
        defer { isSigningOut = false }
        _ = await AppJourney.shared.journey.signOff()
        onSignOut()
    }
}
```
