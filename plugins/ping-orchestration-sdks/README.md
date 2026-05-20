![Ping Identity](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)

# Ping Orchestration SDK Skills

Platform-specific Ping Identity Orchestration SDK skills with complete implementation guides for authentication flows, callback handling, session management, and token access.

## Installation

### GitHub Copilot
```bash
npx skills add pingidentity/ping-sdk-agent-skills/plugins/ping-orchestration-sdks
```

### Claude Code
```bash
# Install the full plugin
npx skills add pingidentity/ping-sdk-agent-skills/plugins/ping-orchestration-sdks

# Or install a particular skill
npx skills add pingidentity/ping-sdk-agent-skills/plugins/ping-orchestration-sdks/skills/ping-orchestration-ios-sdk
npx skills add pingidentity/ping-sdk-agent-skills/plugins/ping-orchestration-sdks/skills/ping-orchestration-android-sdk
npx skills add pingidentity/ping-sdk-agent-skills/plugins/ping-orchestration-sdks/skills/ping-orchestration-javascript-sdk
npx skills add pingidentity/ping-sdk-agent-skills/plugins/ping-orchestration-sdks/skills/ping-orchestration-sdk-router
npx skills add pingidentity/ping-sdk-agent-skills/plugins/ping-orchestration-sdks/skills/ping-orchestration-reactjs-journey-sdk
npx skills add pingidentity/ping-sdk-agent-skills/plugins/ping-orchestration-sdks/skills/ping-orchestration-reactjs-davinci-sdk
npx skills add pingidentity/ping-sdk-agent-skills/plugins/ping-orchestration-sdks/skills/forgerock-to-ping-journey-migration
```

### Cursor
```bash
npx skills add pingidentity/ping-sdk-agent-skills/plugins/ping-orchestration-sdks
```

### Manual Installation
```bash
git clone https://github.com/pingidentity/ping-sdk-agent-skills.git
cp -r ping-sdk-agent-skills/plugins/ping-orchestration-sdks/skills/* .github/skills/
```

## Usage in Your AI Assistant

Once installed, reference the SDK you're working with in your prompt:

**GitHub Copilot/Claude Code/Cursor:**
```
"Help me implement authentication in my Android app using the Ping Orchestration Journey SDK"
```

Or specify a particular skill:

**SDK Integration:**
- `ping-orchestration-ios-sdk` - iOS (Journey, DaVinci, OIDC)
- `ping-orchestration-android-sdk` - Android (Journey, DaVinci, OIDC)
- `ping-orchestration-javascript-sdk` - JavaScript/React (Journey, DaVinci, OIDC)
- `ping-orchestration-sdk-router` - Auto-detect platform and route to the right skill

**Migration:**
- `forgerock-to-ping-journey-migration` - Migrate from ForgeRock SDK to Ping Journey SDK

## Skills

### SDK Integration Skills

| Skill | Description | Documentation |
|-------|-------------|---------------|
| [ping-orchestration-ios-sdk](skills/ping-orchestration-ios-sdk) | Implements authentication in iOS apps using the Ping Orchestration iOS SDK (`Ping/ping-ios-sdk`) — SwiftUI + MVVM, Journey callbacks, DaVinci collectors, OIDC centralized login (ASWebAuthenticationSession/SFSafariViewController), FIDO/passkeys, Protect, device binding, KeychainStorage, and full Xcode project scaffolding. Also covers PingAM/AIC Journey export analysis. | [SKILL.md](skills/ping-orchestration-ios-sdk/SKILL.md) |
| [ping-orchestration-android-sdk](skills/ping-orchestration-android-sdk) | Implements authentication in Android apps using the Ping Orchestration Android SDK (`com.pingidentity.sdks:android`) — Jetpack Compose + MVVM, Journey callbacks, DaVinci collectors, OIDC centralized login, FIDO/passkeys, Protect, device binding, EncryptedDataStore, and full project scaffolding. Covers both new project creation and existing app integration. | [SKILL.md](skills/ping-orchestration-android-sdk/SKILL.md) |
| [ping-orchestration-javascript-sdk](skills/ping-orchestration-javascript-sdk) | Implements authentication in web apps using the Ping Orchestration JavaScript SDK (`@forgerock/journey-client`, `@forgerock/davinci-client`, `@forgerock/oidc-client`) — React + Vite, Journey callbacks, DaVinci collectors, OIDC centralized login. Delegates Journey and DaVinci to specialized skills; handles OIDC centralized login inline. Covers both sample app creation and existing app integration. | [SKILL.md](skills/ping-orchestration-javascript-sdk/SKILL.md) |
| [ping-orchestration-reactjs-journey-sdk](skills/ping-orchestration-reactjs-journey-sdk) | Implements authentication in ReactJS SPAs using the Ping Orchestration JavaScript SDK (`@forgerock/journey-client`). Covers Journey client configuration, OIDC token exchange, dynamic callback rendering, protected routes, user profile display, and full scaffold generation. Supports both sample app creation and existing app integration. | [SKILL.md](skills/ping-orchestration-reactjs-journey-sdk/SKILL.md) |
| [ping-orchestration-reactjs-davinci-sdk](skills/ping-orchestration-reactjs-davinci-sdk) | Implements authentication in ReactJS SPAs using the Ping Orchestration JavaScript SDK (`@forgerock/davinci-client`). Covers DaVinci client configuration, OIDC setup, collector handling (text, password, social login, MFA, FIDO2, PingOne Protect), and full scaffold generation. | [SKILL.md](skills/ping-orchestration-reactjs-davinci-sdk/SKILL.md) |

### Routing Skills

| Skill | Description | Documentation |
|-------|-------------|---------------|
| [ping-orchestration-sdk-router](skills/ping-orchestration-sdk-router) | First point of contact for vague Ping SDK requests. Probes the user's working directory for Android, iOS, JavaScript, or React Native projects (and ForgeRock SDK references), asks if ambiguous, and routes to the matching umbrella skill (`ping-orchestration-android-sdk`, `ping-orchestration-ios-sdk`, `ping-orchestration-javascript-sdk`; React Native on the roadmap) or to `forgerock-to-ping-journey-migration`. Designed for easy expansion via a platform registry. | [SKILL.md](skills/ping-orchestration-sdk-router/SKILL.md) |

### Migration Skills

| Skill | Description | Documentation |
|-------|-------------|---------------|
| [forgerock-to-ping-journey-migration](skills/forgerock-to-ping-journey-migration) | Migrates an existing app from the legacy ForgeRock SDK (`forgerock-android-sdk`, `forgerock-ios-sdk`, `forgerock-javascript-sdk`) to the Ping Orchestration Journey SDK. Detects Android/iOS/JavaScript, scans for legacy usage, comments-out-and-replaces (for easy rollback), verifies the build, and generates a line-numbered migration report. | [SKILL.md](skills/forgerock-to-ping-journey-migration/SKILL.md) |

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