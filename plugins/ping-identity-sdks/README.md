# ping-identity-sdks

Platform-specific Ping Identity Orchestration SDK skills with complete implementation guides for authentication flows, callback handling, session management, and token access.

## Installation

**Via Skills CLI:**

```bash
npx skills add pingidentity/agent-skills/plugins/ping-identity-sdks
```

**Manual:**

```bash
cp -r plugins/ping-identity-sdks/skills/* .github/skills/
```

## Skills

| Skill | Description | Documentation |
|-------|-------------|---------------|
| [ping-orchestration-android-journey-sdk](skills/ping-orchestration-android-journey-sdk) | Implements authentication in Android apps using the Ping Identity Journey SDK with Jetpack Compose and MVVM. Covers Journey configuration, OIDC module setup, callback handling, and full scaffold generation. | [SKILL.md](skills/ping-orchestration-android-journey-sdk/SKILL.md) |

## Planned Skills

| Skill | Platform | SDK Repository |
|-------|----------|----------------|
| `ping-orchestration-ios-journey-sdk` | iOS (Swift) | [ping-ios-sdk](https://github.com/ForgeRock/ping-ios-sdk/) |
| `ping-orchestration-javascript-journey-sdk` | JavaScript / Web | [ping-javascript-sdk](https://github.com/ForgeRock/ping-javascript-sdk/) |
| `ping-orchestration-android-davinci-sdk` | Android | [ping-javascript-sdk](https://github.com/ForgeRock/ping-javascript-sdk/) |
| `ping-orchestration-ios-davinci-sdk` | iOS (Swift) | [ping-ios-sdk](https://github.com/ForgeRock/ping-ios-sdk/) |
| `ping-orchestration-javascript-davinci-sdk` | JavaScript / Web | [ping-javascript-sdk](https://github.com/ForgeRock/ping-javascript-sdk/) |
