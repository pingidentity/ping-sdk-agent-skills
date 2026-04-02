# Contributing to Ping Identity Agent Skills

We appreciate your help! We welcome contributions in the form of new skills, improvements to existing ones, bug reports, and feature requests.

> **Before you start**, please know:
>
> 1. If you have any questions, please ask! We'll help as best we can.
> 2. While we appreciate perfect PRs, it's not essential. We'll fix up any housekeeping changes before merge.
> 3. We may not be able to respond quickly; our development cycles are on a priority basis.
> 4. We base our priorities on customer need and the number of votes (👍) on issues/PRs. If there is an existing issue for something you'd like, please vote!

---

## How to Contribute

There are several ways to contribute:

- **Create a new skill** — Add a skill for a Ping Identity product, SDK, or workflow
- **Improve an existing skill** — Fix errors, add examples, update code patterns
- **Report an issue** — Found a problem with a skill? Let us know
- **Request a skill** — Want a skill that doesn't exist yet? Open an issue

---

## Creating a New Skill

### 1. Determine where your skill belongs

Skills are organized into **plugins**, each grouping related skills:

| Plugin | Path | Purpose |
|--------|------|---------|
| `ping-identity` | `plugins/ping-identity/skills/` | Core skills — platform orientation, quickstart, configuration |
| `ping-identity-sdks` | `plugins/ping-identity-sdks/skills/` | SDK-specific skills — Android, iOS, JavaScript |

If your skill doesn't fit an existing plugin, open an issue to discuss creating a new one.

### 2. Understand the Agent Skills specification

Skills follow the [Agent Skills specification](https://agentskills.io/specification). Read these before creating a skill:

- [What are Agent Skills?](https://agentskills.io/what-are-skills) — Concepts and how skills work
- [Agent Skills Specification](https://agentskills.io/specification) — File format, naming rules, structure
- [VS Code Agent Skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills) — How VS Code discovers and uses skills

### 3. Create the skill directory structure

Every skill is a directory containing at minimum a `SKILL.md` file:

```
plugins/<plugin>/skills/<skill-name>/
├── SKILL.md           # Required: metadata + instructions
├── references/        # Optional: detailed reference documentation
│   ├── api.md
│   └── concepts.md
├── assets/            # Optional: templates, code samples
│   └── MyTemplate.kt.template
└── scripts/           # Optional: executable helper scripts
    └── scaffold.sh
```

### 4. Write the SKILL.md

Your `SKILL.md` must include:

**YAML Frontmatter (required):**

```yaml
---
name: my-skill-name
description: >-
  Use when [trigger phrase]. Does [what it does].
  Covers [specific capabilities].
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---
```

**Frontmatter rules:**

| Field | Required | Rules |
|-------|----------|-------|
| `name` | Yes | Max 64 chars. Lowercase, hyphens only. **Must match the parent directory name.** |
| `description` | Yes | Max 1024 chars. Describe both what the skill does **and when to use it**. Include keywords that help agents match tasks. |
| `license` | No | License name (e.g., `MIT`, `Apache-2.0`) |
| `metadata` | No | Key-value pairs for author, version, etc. |

**Body content guidelines:**

- Write clear, step-by-step instructions that an AI agent can follow
- Include working code examples for each step
- Document common mistakes and how to fix them
- Reference additional files using relative paths: `[API Reference](references/api.md)`
- Keep the main `SKILL.md` under 500 lines — move detailed content to `references/`
- List related skills at the end

**Good description example:**
```yaml
description: >-
  Use when building Android authentication with Ping Identity — scaffolds a
  complete Jetpack Compose + MVVM authentication flow using the Ping Journey
  SDK against PingOne Advanced Identity Cloud (AIC).
```

**Poor description example:**
```yaml
description: Helps with Android auth.
```

### 5. Validate your skill

Use the [skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref) reference library to validate:

```bash
npx skills-ref validate ./plugins/ping-identity-sdks/skills/my-skill
```

### 6. Test with an AI assistant

Before submitting, verify your skill works:

1. Install the skill locally:
   ```bash
   # Copy to your project's skills directory
   cp -r ./plugins/ping-identity-sdks/skills/my-skill .github/skills/

   # Or install via Skills CLI from local path
   npx skills add ./plugins/ping-identity-sdks
   ```
2. Open your AI coding assistant and ask it to perform the task your skill covers
3. Verify the generated code is correct and follows the patterns in your skill
4. Test with multiple AI assistants if possible (Copilot, Claude Code, Cursor)

### 7. Update documentation

- Add your skill to the appropriate table in the plugin's `README.md`
- Add your skill to the **Available Skills** section in the root [README.md](README.md)

---

## Updating Existing Skills

1. Fork the repository
2. Make your changes
3. Ensure all code examples are correct and up to date
4. Update `version` in the SKILL.md metadata if making significant changes
5. Test the skill with an AI assistant to verify correctness
6. Submit a pull request with a clear description of changes

---

## Development Workflow

### Branch Naming

Use descriptive branch names following this convention:

```
<type>/<description>
```

| Type | Use |
|------|-----|
| `feature/` | New skills or capabilities |
| `bugfix/` | Fixing errors in existing skills |
| `docs/` | Documentation changes |
| `chore/` | Maintenance, formatting, tooling |

Example:
```bash
git checkout -b feature/add-ios-orchestration-sdk
```

### Commit Messages

Write clear, descriptive commit messages:

```bash
git commit -m "feat: add ping-ios-orchestration-sdk skill

- Added SKILL.md with SwiftUI authentication flow
- Added references for callbacks and OIDC config
- Added asset templates for ViewModel and Views"
```

---

## Pull Request Process

### Before Submitting

- [ ] Skill follows the [Agent Skills specification](https://agentskills.io/specification)
- [ ] `name` in SKILL.md frontmatter matches the parent directory name
- [ ] `description` clearly states what the skill does **and** when to use it
- [ ] Code examples are correct and tested
- [ ] Skill has been tested with at least one AI coding assistant
- [ ] Plugin and root README.md tables are updated
- [ ] No secrets, credentials, or personal information in any files

### PR Description Should Include

- What was changed and why
- Which plugin/skill is affected
- How to test the changes (e.g., "Ask Copilot to add Android auth with Ping")
- Related issue numbers (e.g., `Closes #12`)

### Review Process

1. A maintainer will review your PR
2. Address any feedback or requested changes
3. Once approved, a maintainer will merge your PR
4. Your contribution will be included in the next release

---

## Reporting Issues

When reporting issues, please use the [GitHub issue tracker](https://github.com/pingidentity/agent-skills/issues/new) and include:

- **A clear, descriptive title**
- **Which skill is affected** (or "general" if repo-wide)
- **Steps to reproduce** — what you asked the AI assistant, what it generated
- **Expected behavior** — what the skill should have produced
- **Actual behavior** — what actually happened
- **AI assistant used** — Copilot, Claude Code, Cursor, etc.
- **Any relevant logs or error messages**

### Issue Labels

| Label | Use |
|-------|-----|
| `bug` | Something isn't working correctly in a skill |
| `enhancement` | Improve an existing skill |
| `skill-request` | Request a new skill |
| `question` | General question about skills or the repo |

---

## Requesting a New Skill

Want a skill that doesn't exist yet? [Open an issue](https://github.com/pingidentity/agent-skills/issues/new) with the `skill-request` label and include:

- **Which Ping Identity product or SDK** the skill should cover
- **What the skill should help an AI agent do** (e.g., "scaffold an iOS app with PingOne DaVinci authentication")
- **Your use case** — what are you trying to build?

We prioritize skill requests based on customer need and community votes (👍).

---

## Code of Conduct

Please be respectful and constructive in all interactions. We're all here to build something great together. See Ping Identity's open source guidelines for more details.

---

## Questions?

If you have questions about contributing, feel free to:

- [Open an issue](https://github.com/pingidentity/agent-skills/issues/new) with the `question` label
- Reach out to the maintainers

Thank you for contributing to Ping Identity Agent Skills!
