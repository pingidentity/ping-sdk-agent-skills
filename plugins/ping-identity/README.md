# ping-identity

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
