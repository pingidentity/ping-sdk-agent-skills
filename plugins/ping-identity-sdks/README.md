![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)

# Ping Orchestration SDK Skills

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
| [forgerock-to-ping-journey-migration](skills/forgerock-to-ping-journey-migration) | Migrates an existing app from the legacy ForgeRock SDK (`forgerock-android-sdk`, `forgerock-ios-sdk`, `forgerock-javascript-sdk`) to the new Ping Identity Journey SDK. Detects Android/iOS/JavaScript, scans for legacy usage, comments-out-and-replaces (for easy rollback), verifies the build, and generates a line-numbered migration report. | [SKILL.md](skills/forgerock-to-ping-journey-migration/SKILL.md) |

# Disclaimer

> **This code is provided by Ping Identity Corporation ("Ping") on an "as is" basis, without
warranty of any kind, to the fullest extent permitted by law.
> Ping Identity Corporation does not represent or warrant or make any guarantee regarding the use of
this code or the accuracy, timeliness or completeness of any data or information relating to this
code, and Ping Identity Corporation hereby disclaims all warranties whether express, or implied or
statutory, including without limitation the implied warranties of merchantability, fitness for a
particular purpose, and any warranty of non-infringement.
> Ping Identity Corporation shall not have any liability arising out of or related to any use,
implementation or configuration of this code, including but not limited to use for any commercial
purpose.
> Any action or suit relating to the use of the code may be brought only in the courts of a
jurisdiction wherein Ping Identity Corporation resides or in which Ping Identity Corporation
conducts its primary business, and under the laws of that jurisdiction excluding its conflict-of-law
provisions.**

# License

This software may be modified and distributed under the terms of the MIT license. See the [LICENSE](./LICENSE) file for details

© Copyright 2026 Ping Identity Corporation. All rights reserved.