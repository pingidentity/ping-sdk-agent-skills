![Ping Identity Agent Skills](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)

# Ping Identity Agent Skills

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

 :robot: [Try it out](#try-it-out) · :pencil: [Feedback](#feedback) · :thumbsup: [Contributing](CONTRIBUTING.md)

Ping Agent Skills help AI-powered coding assistants (such as GitHub Copilot, Claude Code, Gemini CLI, Cursor) build your solutions with Ping Identity products.

> [!NOTE]
>
> As Agent Skills "uplevel" the utility of coding assistants, we are actively building skills and will continue releasing new ones. If you already use a skill to build with Ping and you find it useful, or if you want to suggest a skill or enhance an existing one, we want to hear from you!

## What are Agent Skills?

[Agent Skills](https://agentskills.io/home) are an [open standard](https://agentskills.io/specification) for giving AI agents new capabilities and domain expertise. Each skill is a folder containing a `SKILL.md` file with structured instructions, code patterns, and best practices that AI agents can load on demand.

This repository is the central place for all of Ping Identity's agent skills — from client-side SDK integration to platform configuration.

Learn more at [agentskills.io](https://agentskills.io) and [skills.sh](https://skills.sh)

## Try it out

### Prerequisites

Depending on the skill your AI agent uses, you'll need the following:
- If using PingOne AIC-related skills, a PingOne AIC environment.
- If using PingOne related skills, a PingOne environment. Don't have a tenant? [Sign up for a free trial here](https://www.pingidentity.com/en/try-ping.html).
- Access to an AI coding assistant (GitHub Copilot, Claude Code, Cursor, etc.)

### Steps

1. **Install Ping's skills** (choose one method):

    *Option 1: Via Skills CLI (recommended)*

    ```bash
    # Install all skills from all plugins
    npx skills add pingidentity/agent-skills

    # Install skills from a specific plugin
    npx skills add pingidentity/agent-skills/plugins/ping-identity
    npx skills add pingidentity/agent-skills/plugins/ping-identity-sdks

    # Install a particular skill
    npx skills add pingidentity/agent-skills/plugins/ping-identity-sdks/skills/ping-orchestration-android-journey-sdk
    npx skills add pingidentity/agent-skills/plugins/ping-identity-sdks/skills/ping-orchestration-reactjs-js-journey-sdk
    npx skills add pingidentity/agent-skills/plugins/ping-identity-sdks/skills/ping-orchestration-ios-journey-sdk
    npx skills add pingidentity/agent-skills/plugins/ping-identity-sdks/skills/ping-orchestration-android-davinci-sdk
    npx skills add pingidentity/agent-skills/plugins/ping-identity-sdks/skills/ping-orchestration-ios-davinci-sdk
    npx skills add pingidentity/agent-skills/plugins/ping-identity-sdks/skills/ping-orchestration-reactjs-js-davinci-sdk
    ```

    *Option 2: Manual installation*

    Clone the repository and copy skills to your project or user-level skills directory:

    ```bash
    # Clone the repository
    git clone https://github.com/pingidentity/agent-skills.git

    # Copy all skills to your project's skills directory
    cp -r agent-skills/plugins/ping-identity/skills/* .github/skills/
    cp -r agent-skills/plugins/ping-identity-sdks/skills/* .github/skills/

    # Or copy to your user-level skills directory
    cp -r agent-skills/plugins/*/skills/* ~/.copilot/skills/
    ```

2. **Start using the skills!**

    ```
    "I want to understand how to integrate my mobile apps with Ping.
     Start by helping me build a sample app with the Android Orchestration SDK."
    ```

## Available Skills

### Core Skills ([ping-identity](./plugins/ping-identity/) plugin)

| Skill | Description |
|-------|-------------|
| [ping-quickstart](./plugins/ping-identity/skills/ping-quickstart/SKILL.md) | Detects your platform (Android, iOS, Web), explains Ping Identity concepts, and routes to the correct SDK skill |

### SDK Skills ([ping-identity-sdks](./plugins/ping-identity-sdks/) plugin)

| Skill | Description |
|-------|-------------|
| [ping-orchestration-android-journey-sdk](./plugins/ping-identity-sdks/skills/ping-orchestration-android-journey-sdk/SKILL.md) | Android authentication with the Ping Journey SDK — Jetpack Compose + MVVM, callback handling, OIDC token exchange |
| [ping-orchestration-reactjs-js-journey-sdk](./plugins/ping-identity-sdks/skills/ping-orchestration-reactjs-js-journey-sdk/SKILL.md) | ReactJS authentication with the Ping Orchestration JavaScript SDK — Vite + React 18, all Journey callbacks, OIDC token exchange |
| [ping-orchestration-ios-journey-sdk](./plugins/ping-identity-sdks/skills/ping-orchestration-ios-journey-sdk/SKILL.md) | iOS authentication with the Ping Journey SDK — SwiftUI + MVVM, all Journey callbacks, OIDC token exchange, device binding, FIDO2 |
| [ping-orchestration-android-davinci-sdk](./plugins/ping-identity-sdks/skills/ping-orchestration-android-davinci-sdk/SKILL.md) | Android authentication with the Ping Orchestration Android SDK (DaVinci module) — Jetpack Compose + MVVM, all DaVinci collectors including FIDO2, OIDC token exchange |
| [ping-orchestration-ios-davinci-sdk](./plugins/ping-identity-sdks/skills/ping-orchestration-ios-davinci-sdk/SKILL.md) | iOS authentication with the Ping Orchestration iOS SDK (DaVinci module) — SwiftUI + MVVM, all DaVinci collectors including FIDO2, OIDC token exchange |
| [ping-orchestration-reactjs-js-davinci-sdk](./plugins/ping-identity-sdks/skills/ping-orchestration-reactjs-js-davinci-sdk/SKILL.md) | ReactJS authentication with the Ping Orchestration JavaScript SDK (DaVinci) — Vite + React 18, all DaVinci collectors including FIDO2, OIDC token exchange |

---

## Repository Structure

```
plugins/
├── ping-identity/                           # Core Plugin
│   └── skills/
│       └── ping-quickstart/                 # Platform detection & orientation
│           ├── SKILL.md
│           └── references/
└── ping-identity-sdks/                      # SDK Plugin
    └── skills/
        ├── ping-orchestration-android-journey-sdk/  # Orchestration Android SDK Journey skill
        │   ├── SKILL.md
        │   ├── references/
        │   ├── assets/
        │   └── scripts/
        ├── ping-orchestration-reactjs-js-journey-sdk/  # Orchestration JS SDK - ReactJS Journey SDK skill
        │   ├── SKILL.md
        │   ├── references/
        │   ├── assets/
        │   └── scripts/
        ├── ping-orchestration-ios-journey-sdk/  # Orchestration iOS SDK Journey skill
        │   ├── SKILL.md
        │   ├── references/
        │   ├── assets/
        │   └── scripts/
        ├── ping-orchestration-android-davinci-sdk/  # Orchestration Android SDK DaVinci skill
        │   ├── SKILL.md
        │   ├── references/
        │   ├── assets/
        │   └── scripts/
        ├── ping-orchestration-ios-davinci-sdk/  # Orchestration iOS SDK DaVinci skill
        │   ├── SKILL.md
        │   ├── references/
        │   ├── assets/
        │   └── scripts/
        └── ping-orchestration-reactjs-js-davinci-sdk/  # Orchestration JS SDK - ReactJS Davinci Skill
            ├── SKILL.md
            ├── references/
            ├── assets/
            └── scripts/
```

## Contributing

We welcome contributions! Whether it's a new skill, an improvement to an existing one, or a bug fix — see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:

- How to create a new skill
- Skill structure and `SKILL.md` requirements
- How to submit a pull request
- How to report issues or request skills

## Feedback

If you have feedback, questions, or want to request a new skill:

- [Open an issue](https://github.com/pingidentity/agent-skills/issues/new) with the appropriate label (`enhancement`, `bug`, `question`, or `skill-request`)
- Vote on existing issues with 👍 to help us prioritize

## License

This project is licensed under the Apache 2.0 License — see the [LICENSE](LICENSE) file for details.

## Related Resources

- [Ping Developer Portal](https://developer.pingidentity.com/)
- [Ping Developer Blog](https://developer.pingidentity.com/blog/)
- [Ping Orchestration SDKs](https://docs.pingidentity.com/sdks/latest/sdks/index.html)
- [Agent Skills Standard](https://agentskills.io/)
- [Skills CLI](https://skills.sh)
- [VS Code Agent Skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills)

