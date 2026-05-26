# AGENTS.md

This repository contains Agent Skills content, not a deployable runtime app. Most work here is documentation and template maintenance under plugins.

## Start Here

1. Read [README.md](README.md) for repository purpose and skill inventory.
2. Read [CONTRIBUTING.md](CONTRIBUTING.md) before creating or changing a skill.
3. Read plugin docs at [plugins/ping-orchestration-sdks/README.md](plugins/ping-orchestration-sdks/README.md) when working in that plugin.

## Repository Map

- `plugins/ping-orchestration-sdks/skills/<skill-name>/SKILL.md`: required entry point for each skill.
- `plugins/ping-orchestration-sdks/skills/<skill-name>/references/`: detailed docs that SKILL.md should link to.
- `plugins/ping-orchestration-sdks/skills/<skill-name>/assets/`: templates used by generated scaffolds.
- `plugins/ping-orchestration-sdks/skills/<skill-name>/scripts/`: helper scripts, typically scaffolders.
- `.claude-plugin/plugin.json`: required at repository root.
- `plugins/<plugin>/.claude-plugin/plugin.json`: required at plugin level.

## Commands Agents Should Run

- Validate a specific skill:
  - `npx skills-ref validate ./plugins/<plugin>/skills/<skill-name>`
- If available in local environment, run repository lint rules:
  - `claudelint .`

There is no standard unit test suite in this repository. Validation is primarily skill schema and structure checks plus documentation consistency.

## Required Conventions

1. Keep `SKILL.md` concise (target under 500 lines); move deep detail into `references/` and link it.
2. Include complete YAML frontmatter in every `SKILL.md`:
   - `name` must match the skill directory name exactly.
   - `description` must say when to use the skill and what it does.
   - include `license` and `metadata.author`.
3. Allowed subdirectories in each skill are only `assets`, `references`, and `scripts`.
4. When adding or renaming a skill, update both:
   - [README.md](README.md)
   - [plugins/ping-orchestration-sdks/README.md](plugins/ping-orchestration-sdks/README.md)
5. Use relative Markdown links for internal references; do not duplicate long reference content in multiple places.
6. Never commit secrets or environment-specific credentials.

## Common Failure Modes

- Missing required plugin manifest files:
  - `.claude-plugin/plugin.json` at root
  - `plugins/<plugin>/.claude-plugin/plugin.json` at plugin level
- Missing `SKILL.md` in a skill folder.
- Extra top-level directories in a skill folder (only `assets`, `references`, `scripts` allowed).
- Skill updated but README tables not updated.

## Change Strategy For Agents

1. Make the smallest possible change in one skill at a time.
2. Preserve existing voice and structure unless asked to refactor.
3. Prefer linking to existing docs over copying large blocks.
4. After edits, run relevant validation commands and summarize exactly what was verified.
