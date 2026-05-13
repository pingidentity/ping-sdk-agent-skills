# DaVinci Collector Implementations

## Key API Facts

- **`Option` struct**: `.label` (display string), `.value` (submission key). Not `Hashable` — use `ForEach(collector.options.indices, id: \.self)`, never `ForEach(collector.options, id: \.self)` or `id: \.label`.
- **`PhoneNumberCollector`**: set `.phoneNumber`, not `.value`. Also has `.countryCode`.
- **`ProtectCollector`**: call `await collector.collect()` (not `.start()`). Returns `Result<String, Error>`. Fire-and-forget inside `.task`.
- **`FidoRegistrationCollector` (DaVinci)**: `collector.register(window:)` — no `deviceName:` param (unlike Journey's `FidoRegistrationCallback.register(deviceName:window:)`).
- **`Device` struct**: `.title` for display (not `.name`). Also has `.type`, `.id`, `.description`, `.iconSrc`, `.isDefault`. Not `Hashable` — use `ForEach(Array(collector.devices.enumerated()), id: \.offset)`.
- **`SubmitCollector` / `FlowCollector`**: **always** set `collector.value = collector.id` before calling `onNext()`, otherwise `actionKey` and `eventType` are absent from the POST body.

---

## TextCollectorView

```swift
struct TextCollectorView: View {
    let collector: TextCollector
    @State private var text = ""

    var body: some View {
        PingTextField(
            placeholder: collector.label.isEmpty ? "Enter text" : collector.label,
            text: $text
        )
        .onChange(of: text) { _, newValue in
            collector.value = newValue
        }
    }
}
```

## PasswordCollectorView

```swift
struct PasswordCollectorView: View {
    let collector: PasswordCollector
    @State private var password = ""

    var body: some View {
        PingSecureField(
            placeholder: collector.label.isEmpty ? "Password" : collector.label,
            text: $password
        )
        .onChange(of: password) { _, newValue in
            collector.value = newValue
        }
    }
}
```

## MultiSelectCheckBoxView

```swift
struct MultiSelectCheckBoxView: View {
    let collector: MultiSelectCollector
    @State private var selected: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !collector.label.isEmpty {
                Text(collector.label)
                    .font(.subheadline).foregroundColor(.secondary)
            }
            ForEach(collector.options.indices, id: \.self) { index in
                let option = collector.options[index]
                Button {
                    if selected.contains(option.value) { selected.remove(option.value) }
                    else { selected.insert(option.value) }
                    collector.value = Array(selected)
                } label: {
                    HStack {
                        Image(systemName: selected.contains(option.value) ? "checkmark.square.fill" : "square")
                            .foregroundColor(.pingRed)
                        Text(option.label)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

## MultiSelectComboBoxView

```swift
struct MultiSelectComboBoxView: View {
    let collector: MultiSelectCollector
    @State private var selected: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !collector.label.isEmpty {
                Text(collector.label)
                    .font(.subheadline).foregroundColor(.secondary)
            }
            ForEach(collector.options.indices, id: \.self) { index in
                let option = collector.options[index]
                Button {
                    if selected.contains(option.value) { selected.remove(option.value) }
                    else { selected.insert(option.value) }
                    collector.value = Array(selected)
                } label: {
                    HStack {
                        Image(systemName: selected.contains(option.value) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(.pingRed)
                        Text(option.label)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

## SingleSelectDropdownView

```swift
struct SingleSelectDropdownView: View {
    let collector: SingleSelectCollector
    @State private var selection = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !collector.label.isEmpty {
                Text(collector.label)
                    .font(.subheadline).foregroundColor(.secondary)
            }
            Picker(collector.label, selection: $selection) {
                Text("Select…").tag("")
                ForEach(collector.options.indices, id: \.self) { index in
                    let option = collector.options[index]
                    Text(option.label).tag(option.value)
                }
            }
            .pickerStyle(.menu)
            .tint(.pingRed)
            .onChange(of: selection) { _, newValue in
                collector.value = newValue
            }
        }
    }
}
```

## SingleSelectRadioView

```swift
struct SingleSelectRadioView: View {
    let collector: SingleSelectCollector
    @State private var selection = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !collector.label.isEmpty {
                Text(collector.label)
                    .font(.subheadline).foregroundColor(.secondary)
            }
            ForEach(collector.options.indices, id: \.self) { index in
                let option = collector.options[index]
                Button {
                    selection = option.value
                    collector.value = option.value
                } label: {
                    HStack {
                        Image(systemName: selection == option.value ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.pingRed)
                        Text(option.label)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

## PhoneCollectorView

Note: uses `.phoneNumber` not `.value`.

```swift
struct PhoneCollectorView: View {
    let collector: PhoneNumberCollector
    @State private var phoneNumber = ""

    var body: some View {
        PingTextField(
            placeholder: collector.label.isEmpty ? "Phone number" : collector.label,
            text: $phoneNumber,
            contentType: .telephoneNumber,
            autocapitalization: .never
        )
        .onChange(of: phoneNumber) { _, newValue in
            collector.phoneNumber = newValue
        }
    }
}
```

## ProtectCollectorView

Note: uses `await collector.collect()` not `.start()`. Fire-and-forget inside `.task`.

```swift
struct ProtectCollectorView: View {
    let collector: ProtectCollector

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.75)
            Text("Verifying device security…")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .task {
            _ = await collector.collect()
        }
    }
}
```

## FidoRegistrationCollectorView

Note: DaVinci variant — `collector.register(window:)` only, no `deviceName:` parameter.

```swift
struct FidoRegistrationCollectorView: View {
    let collector: FidoRegistrationCollector
    let onNext: () -> Void

    @State private var errorMessage: String?
    @State private var isRegistering = false

    var body: some View {
        VStack(spacing: 20) {
            FidoIconView(systemName: "faceid", tint: .pingRed)

            Text("Register Passkey")
                .font(.title2).fontWeight(.semibold)

            Text("Create a passkey for fast, secure biometric login.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let errorMessage {
                ErrorMessageView(message: errorMessage)
            }

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
            let result = await collector.register(window: window)
            switch result {
            case .success:
                onNext()
            case .failure(let error):
                errorMessage = error.localizedDescription
                onNext()
            }
        }
    }
}
```

## FidoAuthenticationCollectorView

```swift
struct FidoAuthenticationCollectorView: View {
    let collector: FidoAuthenticationCollector
    let onNext: () -> Void

    @State private var errorMessage: String?
    @State private var isAuthenticating = false

    var body: some View {
        VStack(spacing: 20) {
            FidoIconView(systemName: "touchid", tint: .pingRed)

            Text("Biometric Authentication")
                .font(.title2).fontWeight(.semibold)

            Text("Use your passkey to sign in securely.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let errorMessage {
                ErrorMessageView(message: errorMessage)
            }

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
            let result = await collector.authenticate(window: window)
            switch result {
            case .success:
                onNext()
            case .failure(let error):
                errorMessage = error.localizedDescription
                onNext()
            }
        }
    }
}
```

## DeviceRegistrationCollectorView

Note: uses `collector.value = device` (not `.register()`). `Device.title` for display (not `.name`). Use `enumerated()` because `Device` is not `Hashable`.

```swift
struct DeviceRegistrationCollectorView: View {
    let collector: DeviceRegistrationCollector
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            FidoIconView(systemName: "iphone.badge.play", tint: .pingRed)

            Text("Register Device")
                .font(.title2).fontWeight(.semibold)

            if !collector.devices.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select device:")
                        .font(.subheadline).foregroundColor(.secondary)
                    ForEach(Array(collector.devices.enumerated()), id: \.offset) { _, device in
                        Button {
                            collector.value = device
                            onNext()
                        } label: {
                            HStack {
                                Image(systemName: "iphone")
                                    .foregroundColor(.pingRed)
                                Text(device.title)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Button("Register Device") {
                    onNext()
                }
                .buttonStyle(PingPrimaryButtonStyle())
            }
        }
    }
}
```

## DeviceAuthenticationCollectorView

```swift
struct DeviceAuthenticationCollectorView: View {
    let collector: DeviceAuthenticationCollector
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            FidoIconView(systemName: "iphone.badge.play", tint: .pingRed)

            Text("Device Authentication")
                .font(.title2).fontWeight(.semibold)

            if !collector.devices.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select device:")
                        .font(.subheadline).foregroundColor(.secondary)
                    ForEach(Array(collector.devices.enumerated()), id: \.offset) { _, device in
                        Button {
                            collector.value = device
                            onNext()
                        } label: {
                            HStack {
                                Image(systemName: "iphone")
                                    .foregroundColor(.pingRed)
                                Text(device.title)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Button("Authenticate Device") {
                    onNext()
                }
                .buttonStyle(PingPrimaryButtonStyle())
            }
        }
    }
}
```

---

## DaVinci Authenticated View

```swift
import SwiftUI
import PingDavinci
import PingOrchestrate
import PingOidc

struct DaVinciAuthenticatedView: View {
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
                                Text("User Profile")
                                    .font(.headline).padding(.horizontal, 16).padding(.vertical, 12)
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
        guard let user = await AppDaVinci.shared.daVinci.user() else { return }
        if case .success(let info) = await user.userinfo(cache: false) { userInfo = info }
    }

    private func signOut() async {
        isSigningOut = true
        defer { isSigningOut = false }
        if let user = await AppDaVinci.shared.daVinci.user() { await user.revoke() }
        _ = await AppDaVinci.shared.daVinci.signOff()
        onSignOut()
    }
}
```

## DaVinci Session Lifecycle

```swift
// Retrieve the authenticated user
let user = await AppDaVinci.shared.daVinci.user()

// Fetch user info
if let user = user {
    let result = await user.userinfo(cache: false)
    switch result {
    case .success(let info):
        info.forEach { key, value in print("\(key): \(String(describing: value))") }
    case .failure(let error):
        print(error.localizedDescription)
    }
}

// Sign out
if let user = await AppDaVinci.shared.daVinci.user() { await user.revoke() }
_ = await AppDaVinci.shared.daVinci.signOff()
```
