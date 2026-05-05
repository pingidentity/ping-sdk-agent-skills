# ping-identity-sdks

Platform-specific Ping Identity Orchestration SDK skills with complete implementation guides for authentication flows, callback handling, session management, and token access.

## Installation

### GitHub Copilot
```bash
npx skills add pingidentity/agent-skills/plugins/ping-identity-sdks
```

### Claude Code
```bash
npx skills add pingidentity/agent-skills/plugins/ping-identity-sdks
```

### Cursor
```bash
npx skills add pingidentity/agent-skills/plugins/ping-identity-sdks
```

### Manual Installation
```bash
git clone https://github.com/pingidentity/agent-skills.git
cp -r agent-skills/plugins/ping-identity-sdks/skills/* .github/skills/
```

## Usage in Your AI Assistant

Once installed, reference the SDK you're working with in your prompt:

**GitHub Copilot/Claude Code/Cursor:**
```
"Help me implement authentication in my Android app using the Ping Orchestration Journey SDK"
```

Or specify a particular SDK skill:
- `ping-orchestration-android-journey-sdk` - Android Journey SDK
- `ping-orchestration-ios-journey-sdk` - iOS Journey SDK
- `ping-orchestration-reactjs-js-journey-sdk` - ReactJS Journey SDK
- `ping-orchestration-android-davinci-sdk` - Android DaVinci SDK
- `ping-orchestration-ios-davinci-sdk` - iOS DaVinci SDK
- `ping-orchestration-reactjs-js-davinci-sdk` - ReactJS DaVinci SDK

## Skills

| Skill | Description | Documentation |
|-------|-------------|---------------|
| [ping-orchestration-android-journey-sdk](skills/ping-orchestration-android-journey-sdk) | Implements authentication in Android apps using the Ping Orchestration Android SDK (Journey module) with Jetpack Compose and MVVM. Covers Journey configuration, OIDC module setup, callback handling, and full scaffold generation. | [SKILL.md](skills/ping-orchestration-android-journey-sdk/SKILL.md) |
| [ping-orchestration-reactjs-js-journey-sdk](skills/ping-orchestration-reactjs-js-journey-sdk) | Implements authentication in ReactJS SPAs using the Ping Orchestration JavaScript SDK. Covers Journey client configuration, OIDC token exchange, dynamic callback rendering, protected routes, user profile display, and full scaffold generation. Supports both sample app creation and existing app integration. | [SKILL.md](skills/ping-orchestration-reactjs-js-journey-sdk/SKILL.md) |
| [ping-orchestration-ios-journey-sdk](skills/ping-orchestration-ios-journey-sdk) | Implements authentication in iOS apps using the Ping Orchestration iOS SDK (Journey module) with SwiftUI and MVVM. Covers Journey configuration, OIDC module setup, callback handling, device binding, FIDO2, and full scaffold generation. Supports both sample app creation and existing app integration. | [SKILL.md](skills/ping-orchestration-ios-journey-sdk/SKILL.md) |
| [ping-orchestration-android-davinci-sdk](skills/ping-orchestration-android-davinci-sdk) | Implements authentication in Android apps using the Ping Orchestration Android SDK (DaVinci module) with Jetpack Compose and MVVM. Covers DaVinci configuration, OIDC module setup, collector handling (text, password, social login, MFA, FIDO2, PingOne Protect), and full scaffold generation. | [SKILL.md](skills/ping-orchestration-android-davinci-sdk/SKILL.md) |
| [ping-orchestration-ios-davinci-sdk](skills/ping-orchestration-ios-davinci-sdk) | Implements authentication in iOS apps using the Ping Orchestration iOS SDK (DaVinci module) with SwiftUI and MVVM. Covers DaVinci configuration, OIDC module setup, collector handling (text, password, social login, MFA, FIDO2, PingOne Protect), and full scaffold generation. | [SKILL.md](skills/ping-orchestration-ios-davinci-sdk/SKILL.md) |
| [ping-orchestration-reactjs-js-davinci-sdk](skills/ping-orchestration-reactjs-js-davinci-sdk) | Implements authentication in ReactJS SPAs using the Ping Orchestration JavaScript SDK (DaVinci). Covers DaVinci client configuration, OIDC setup, collector handling (text, password, social login, MFA, FIDO2, PingOne Protect), and full scaffold generation. | [SKILL.md](skills/ping-orchestration-reactjs-js-davinci-sdk/SKILL.md) |
