# OIDC Web Flow — Full Reference

## `OidcWebClientConfig` API Reference

`OidcWebClient.createOidcWebClient { webConfig in ... }` configures top-level browser behaviour.
`webConfig.module(PingOidc.OidcModule.config) { oidcValue in ... }` configures OIDC parameters.

**`webConfig` properties:**

| Property | Type | Default | Notes |
|---|---|---|---|
| `browserType` | `BrowserType` | `.authSession` | `.authSession` = ASWebAuthenticationSession; `.sfViewController` = SFSafariViewController |
| `browserMode` | `BrowserMode` | `.login` | Use `.login` for `authorize()`. Used internally for sign-out. |
| `logger` | `Logger` | `LogManager.logger` | Use `LogManager.standard` |
| `timeout` | `TimeInterval` | `30` | Set automatically by `createOidcWebClient` |

**`oidcValue` properties (from `OidcClientConfig`, SDK 2.0.0):**

| Property | Type | Notes |
|---|---|---|
| `clientId` | `String` | Required |
| `scopes` | `Set<String>` | Required — include `openid` |
| `redirectUri` | `String` | Must match a scheme registered via the URL-scheme Ruby script in Step D |
| `discoveryEndpoint` | `String` | `.well-known/openid-configuration` URL |
| `acrValues` | `String?` | Optional ACR values — omit unless you actually need them; leaving as `nil` is fine |
| `loginHint` | `String?` | Optional login hint |
| `state` | `String?` | Optional state parameter |
| `nonce` | `String?` | Optional nonce |
| `display` | `String?` | Optional display parameter |
| `prompt` | `String?` | Optional prompt parameter |
| `uiLocales` | `String?` | Optional UI locales |
| `storage` | `StorageDelegate<Token>` | Defaults to Keychain with `SecuredKeyEncryptor` |
| `refreshThreshold` | `Int64` | Seconds before expiry to trigger silent refresh (`0` = disabled) |
| `additionalParameters` | `[String: String]` | Static extra parameters; for per-call parameters use `OidcOptions` |

**Properties that do NOT exist** in SDK 2.0.0 — do not generate code that sets these (the compiler will reject them with `value of type 'OidcClientConfig' has no member`):
- `par` — RFC 9126 PAR is not exposed as a config flag in the public API
- `pkce` — PKCE is always on internally; there's no toggle

## `authorize()` and the `Result<User, OidcError>` shape

`authorize()` is `async throws` and returns `Result<User, OidcError>`. There are **two** error
channels — `throws` for network/OIDC discovery failures and `Result.failure` for authorization
errors. Always handle both:

```swift
import PingOidc

do {
    let result = try await AppOidc.shared.oidcWebClient.authorize { options in
        options.additionalParameters = ["custom_param": "value"]
    }
    switch result {
    case .success(let user):
        // user is authenticated — navigate to your authenticated state
    case .failure(let oidcError):
        // display oidcError.localizedDescription
    }
} catch {
    // network or OIDC discovery error
    print(error.localizedDescription)
}
```

## `OidcError` Cases

`OidcError` cases: `.authorizeError(cause:message:)`, `.networkError(cause:message:)`,
`.apiError(code:message:)`, `.unknown(cause:message:)`.

## `BrowserType` Choice

| Type | Trade-offs |
|---|---|
| `.authSession` | `ASWebAuthenticationSession` — system sheet, shares Safari cookies, no app-switch, no manual redirect wiring needed. **Recommended for most apps.** |
| `.sfViewController` | `SFSafariViewController` — in-app browser, custom presentation possible, redirect comes back through `onOpenURL`. Use when you need custom chrome or full cookie isolation. |

## User, Token, and Sign-Out Lifecycle

```swift
// Get the authenticated user (checks Keychain / in-memory cache)
let user: User? = await AppOidc.shared.oidcWebClient.user()
// Alternatively: await AppOidc.shared.oidcWebClient.oidcLoginUser()

// Get the access token
if let user = user {
    let tokenResult: Result<Token, OidcError> = await user.token()
}

// Get user info
if let user = user {
    let userInfoResult: Result<UserInfo, OidcError> = await user.userinfo(cache: false)
}

// Revoke token + end OP session (end_session_endpoint)
if let user = await AppOidc.shared.oidcWebClient.user() {
    await user.revoke()
}
_ = await AppOidc.shared.oidcWebClient.signOff()
```

## OidcLoginViewModel

```swift
import Foundation
import Observation
import PingOidc

@Observable
@MainActor
final class OidcLoginViewModel {
    var state: Result<User, OidcError>?
    var isLoading = false

    func authorize() async {
        isLoading = true
        defer { isLoading = false }
        do {
            state = try await AppOidc.shared.oidcWebClient.authorize()
        } catch {
            state = .failure(.unknown(cause: error, message: error.localizedDescription))
        }
    }

    func signOut() async {
        if let user = await AppOidc.shared.oidcWebClient.user() { await user.revoke() }
        _ = await AppOidc.shared.oidcWebClient.signOff()
        state = nil
    }
}
```

## Branded OidcLoginView

```swift
import SwiftUI
import PingOidc

struct OidcLoginView: View {
    @State private var oidcLoginViewModel = OidcLoginViewModel()

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    PingHeaderView(title: "My App", subtitle: "Centralized Login")
                    VStack(spacing: 24) {
                        switch oidcLoginViewModel.state {
                        case .success:
                            EmptyView()   // navigate away on success
                        case .failure(let oidcError):
                            ErrorView(
                                message: oidcError.localizedDescription,
                                onRetry: { Task { await oidcLoginViewModel.authorize() } }
                            )
                        case .none:
                            Button("Sign In with Browser") {
                                Task { await oidcLoginViewModel.authorize() }
                            }
                            .buttonStyle(PingPrimaryButtonStyle())
                        }
                    }
                    .padding(24)
                }
            }
            if oidcLoginViewModel.isLoading { LoadingOverlay("Opening browser…") }
        }
        .navigationBarBackButtonHidden(oidcLoginViewModel.isLoading)
    }
}
```

## Multi-flow ConfigurationManager factory

For multi-flow apps, add this factory to `ConfigurationManager`:

```swift
private static func buildOidcWebClient(_ config: Configuration) -> OidcWebClient {
    OidcWebClient.createOidcWebClient { webConfig in
        webConfig.browserType = .sfViewController
        webConfig.browserMode = .login
        webConfig.logger      = LogManager.standard
        webConfig.module(PingOidc.OidcModule.config) { oidcValue in
            oidcValue.clientId          = config.clientId
            oidcValue.scopes            = Set<String>(config.scopes)
            oidcValue.redirectUri       = config.redirectUri
            oidcValue.discoveryEndpoint = config.discoveryEndpoint
            oidcValue.storage           = KeychainStorage<Token>(account: "ACCESS_TOKEN_STORAGE_OIDCWEB")
            // Only include acrValues when provided: oidcValue.acrValues = "urn:acr:value"
        }
    }
}
```
