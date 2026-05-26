# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A collection of [Agent Skills](https://agentskills.io/specification) for AI coding assistants (Claude Code, GitHub Copilot, Cursor, Gemini CLI). Skills teach AI agents how to build apps with Ping Identity's Orchestration SDKs (Android, iOS, ReactJS). This repo contains **no deployable runtime code** — all work is documentation and template maintenance.

## Validation

```bash
# Validate a single skill (primary check before submitting changes)
npx skills-ref validate ./plugins/ping-orchestration-sdks/skills/<skill-name>

# Run all repository lint rules (requires claudelint installed)
claudelint .
```

There is no test suite. Validation is schema/structure checks plus documentation consistency enforced by `claudelint` via `.claudelint.yaml` and the custom rules in `.claudelint/rules.py`.

## Architecture

### Plugin → Skill hierarchy

```
.claude-plugin/marketplace.json          # Root marketplace manifest
plugins/
└── ping-orchestration-sdks/
    ├── .claude-plugin/plugin.json       # Plugin manifest (required)
    └── skills/
        └── <skill-name>/
            ├── SKILL.md                 # Required — metadata + instructions
            ├── references/              # Detailed docs linked from SKILL.md
            ├── assets/                  # Code templates used by scaffolds
            └── scripts/                 # Scaffold helper scripts
```

Both `.claude-plugin/plugin.json` (root) and `plugins/<plugin>/.claude-plugin/plugin.json` are required — their absence is a lint error. Cursor discovery uses the parallel `.cursor-plugin/` manifests.

### SKILL.md structure

Every `SKILL.md` must open with YAML frontmatter:

```yaml
---
name: <must match parent directory name exactly>
description: >-
  Use when [trigger phrase]. Does [what it does]. Covers [specific capabilities].
license: MIT
metadata:
  author: Ping Identity
  version: "1.0.0"
---
```

Keep `SKILL.md` under 500 lines; move detailed content to `references/` and link it with relative Markdown links.

## Required Conventions

- `name` in frontmatter **must** match the skill directory name exactly.
- Only `assets`, `references`, and `scripts` subdirectories are allowed inside a skill directory.
- When adding or renaming a skill, update **both** README tables:
  - [`README.md`](README.md) (root Available Skills section)
  - [`plugins/ping-orchestration-sdks/README.md`](plugins/ping-orchestration-sdks/README.md)
- Use relative Markdown links for all internal cross-references; never duplicate large content blocks.
- Branch naming: `feature/`, `bugfix/`, `docs/`, or `chore/` prefix.

## Common Failure Modes (lint errors)

- Missing `.claude-plugin/plugin.json` at root or plugin level
- Missing `SKILL.md` in a skill folder
- Extra subdirectory in a skill folder (only `assets`, `references`, `scripts` allowed)
- Skill added/renamed but README tables not updated
- `name` in frontmatter doesn't match directory name
