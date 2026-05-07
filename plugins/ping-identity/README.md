![Ping SDK Agent Skills](https://www.pingidentity.com/content/dam/picr/nav/Ping-Logo-2.svg)

# Quick Start

Core Ping Identity skills for platform orientation, onboarding, and understanding the Ping Identity ecosystem. These skills help AI agents route users to the correct SDK and provide foundational knowledge about PingOne Advanced Identity Cloud (AIC).

## Installation

### GitHub Copilot
```bash
npx skills add pingidentity/agent-skills/plugins/ping-identity
```

### Claude Code
```bash
npx skills add pingidentity/agent-skills/plugins/ping-identity
```

### Cursor
```bash
npx skills add pingidentity/agent-skills/plugins/ping-identity
```

### Manual Installation
```bash
git clone https://github.com/pingidentity/agent-skills.git
cp -r agent-skills/plugins/ping-identity/skills/* .github/skills/
```

## Usage in Your AI Assistant

Once installed, reference the skill in your prompt:

**GitHub Copilot/Claude Code/Cursor:**
```
"Help me understand how to integrate Ping Identity into my application"
```

The `ping-quickstart` skill will automatically detect your platform and route you to the appropriate SDK.

## Skills

| Skill | Description | Documentation |
|-------|-------------|---------------|
| [ping-quickstart](skills/ping-quickstart) | Detects the project's platform (Android, iOS, JavaScript/Web) and guides through Ping Identity integration. Provides key terms, concepts, and routes to the correct SDK skill. | [SKILL.md](skills/ping-quickstart/SKILL.md) |

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