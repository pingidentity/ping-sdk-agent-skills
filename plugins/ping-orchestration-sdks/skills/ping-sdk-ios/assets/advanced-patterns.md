# Advanced Patterns

## ConfigurationManager — Multi-Flow Apps

Use when your app needs to switch between Journey, DaVinci, and OIDC Web in a single session.

```swift
import PingJourney
import PingDavinci
import PingOidc
import PingOrchestrate
import PingStorage
import PingLogger

@MainActor
class ConfigurationManager {
    static let shared = ConfigurationManager()

    var journey: Journey?
    var davinci: DaVinci?
    var oidcLogin: OidcWebClient?

    static func buildJourney(_ config: Configuration) -> Journey {
        Journey.createJourney { journeyConfig in
            journeyConfig.serverUrl = config.serverUrl ?? ""
            journeyConfig.realm     = config.realm ?? "root"
            journeyConfig.cookie    = config.cookieName ?? ""
            journeyConfig.logger    = LogManager.standard
            journeyConfig.module(PingJourney.OidcModule.config) { oidcConfig in
                oidcConfig.clientId          = config.clientId
                oidcConfig.scopes            = Set(config.scopes)
                oidcConfig.redirectUri       = config.redirectUri
                oidcConfig.discoveryEndpoint = config.discoveryEndpoint
                oidcConfig.logger            = LogManager.standard
            }
        }
    }
}
```

## Token Storage Patterns

The SDK persists tokens to Keychain by default. Only configure `oidcConfig.storage` explicitly when you need isolated storage per-instance or hardware encryption.

```swift
// Multiple Journey instances — give each a unique account key to prevent overwrites
oidcConfig.storage = KeychainStorage<Token>(account: "tokens_journey_alpha")

// Secure Enclave-backed encryption
oidcConfig.storage = KeychainStorage<Token>(
    account: "tokens_journey",
    encryptor: SecuredKeyEncryptor() ?? NoEncryptor()
)
```
