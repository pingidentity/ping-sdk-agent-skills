# ping-identity

Core Ping Identity skills for platform orientation, onboarding, and understanding the Ping Identity ecosystem. These skills help AI agents route users to the correct SDK and provide foundational knowledge about PingOne Advanced Identity Cloud (AIC).

## Installation

**Via Skills CLI:**

```bash
npx skills add pingidentity/agent-skills/plugins/ping-identity
```

**Manual:**

```bash
cp -r plugins/ping-identity/skills/* .github/skills/
```

## Skills

| Skill | Description | Documentation |
|-------|-------------|---------------|
| [ping-quickstart](skills/ping-quickstart) | Detects the project's platform (Android, iOS, JavaScript/Web) and guides through Ping Identity integration. Provides key terms, concepts, and routes to the correct SDK skill. | [SKILL.md](skills/ping-quickstart/SKILL.md) |
