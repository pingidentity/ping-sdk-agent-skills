# Ping Orchestration SDK Agent Skills

**A 10-minute technical walkthrough**
Audience: Engineering, Support, Professional Services
Repo: [pingidentity/ping-sdk-agent-skills](https://github.com/pingidentity/ping-sdk-agent-skills)

---

## 1. The problem we're solving

Integrating with Ping's Orchestration platform (PingOne, PingOne AIC, PingAM, DaVinci) is **not hard for the SDK author** — it's hard for **every customer doing it once**:

- 3 client platforms (Android, iOS, JavaScript) × 3 orchestration backends (Journey, DaVinci, OIDC) × N callback/collector types.
- Migration pressure: thousands of customers still on the legacy **ForgeRock SDK** that needs to move to the Ping Orchestration SDK.
- Generic LLMs hallucinate against this domain — they remember `forgerock-android-sdk` better than `com.pingidentity.sdks:android`, and they invent callbacks that don't exist.

Every wrong answer becomes a **support ticket** or a **PS engagement hour**. Skills attack the cause, not the symptom.

---

## 2. What is an Agent Skill?

An [Agent Skill](https://agentskills.io/specification) is an **open-standard folder** the AI loads on demand:

```
skill-name/
├── SKILL.md          # YAML frontmatter + instructions (≤ 500 lines)
├── references/       # Deep-dive docs, loaded only when needed
├── assets/           # Code templates, logos, theme files
└── scripts/          # Scaffolding helpers (e.g. scaffold_auth.sh)
```

The frontmatter `description:` is the **trigger**. When the user says "add Ping login to my iOS app", the agent matches that phrase, loads `SKILL.md`, and follows it like a runbook.

Compatible with **Claude Code, GitHub Copilot, Cursor, Gemini CLI** — one source of truth, four IDEs.

---

## 3. The seven skills in this repo

```
plugins/ping-orchestration-sdks/skills/
├── ping-orchestration-sdk-router          ← entry point for vague requests
├── ping-orchestration-android-sdk         ← umbrella: Journey + DaVinci + OIDC
├── ping-orchestration-ios-sdk             ← umbrella: Journey + DaVinci + OIDC
├── ping-orchestration-javascript-sdk      ← umbrella: delegates to the two below
├── ping-orchestration-reactjs-journey-sdk ← Vite + React 18, Journey callbacks
├── ping-orchestration-reactjs-davinci-sdk ← Vite + React 18, DaVinci collectors
└── forgerock-to-ping-journey-migration    ← cross-platform legacy migration
```

Three architectural roles, deliberately layered:

| Role | Skill(s) | What it does |
|---|---|---|
| **Router** | `ping-orchestration-sdk-router` | Probes the working dir, detects platform, hands off |
| **Umbrella** | `ping-orchestration-{android,ios,javascript}-sdk` | Owns a platform; either implements or delegates |
| **Specialist** | `ping-orchestration-reactjs-{journey,davinci}-sdk` | Concrete framework + flow combination |
| **Cross-cutting** | `forgerock-to-ping-journey-migration` | Wins over platform routing when legacy code is present |

---

## 4. How the skills actually work — end to end

### 4a. The router probes, doesn't ask

`ping-orchestration-sdk-router` runs **bounded `find` probes** at depth ≤ 4, ignoring `node_modules`, `Pods`, `.gradle`, `build`, `DerivedData`:

- `build.gradle*` / `AndroidManifest.xml` → Android
- `Package.swift` / `*.xcodeproj` / `Podfile` → iOS
- `package.json` → JavaScript (then check deps)
- `@forgerock/*` or `forgerock-*-sdk` references found → **migration skill takes precedence**

A registry table inside `SKILL.md` is the single source of truth — adding React Native is one row + one probe block. The skill is built to be extended, not rewritten.

### 4b. The umbrella branches by intent

Every umbrella skill opens with a **wizard** (`AskUserQuestion`):

```
A) Build a new sample app      — full project scaffold + Ping branding
B) Integrate into existing app — drop-in SDK files, no scaffold
C) Browse the reference guide  — show full SDK reference
D) Something else              — free-text routing
```

For (A) on iOS, the skill **uses the `xcodebuildmcp` MCP server** declared in its `compatibility:` block to drive Xcode. Templates in `assets/` (Theme files, logos, callback renderers) get materialized; `references/` ship the callback-by-callback API mapping the LLM needs but doesn't have memorized.

### 4c. Specialist skills carry runnable scaffolds

`ping-orchestration-reactjs-davinci-sdk/scripts/scaffold_auth.sh` is a real shell script the agent invokes — not a copy-pasted snippet. Vite + React 18 + the right `@forgerock/davinci-client` version come up in one command. **Determinism replaces hallucination.**

### 4d. The migration skill is the most disciplined

`forgerock-to-ping-journey-migration` codifies five core principles, all enforced in the workflow:

1. **Never silently delete** — comment out legacy code with a grep-able marker so rollback is one diff.
2. **Always leave the build working** — verify build *before* migrating; a broken baseline aborts the run.
3. **Pause on ambiguity** — callbacks → coroutines/async-await is not a mechanical 1:1; emit `TODO(ping-migration):` and ask.
4. **Preview before editing** — every change site shown, grouped by file, before any write.
5. **Explain in the report** — line-numbered audit log is a first-class deliverable, not an afterthought.

This is the difference between an LLM "doing a migration" and a **reviewable, auditable engineering artifact**.

---

## 5. Why this benefits the customer

- **Time-to-first-token-exchange drops from days to minutes.** A new customer says "I want a Ping-authenticated iOS app" — the wizard scaffolds the project, wires Journey/DaVinci/OIDC, and applies branding in a single session.
- **The right SDK, every time.** No more `forgerock-android-sdk` in 2026 codebases. The skill knows the current package coordinates (`com.pingidentity.sdks:android`, `Ping/ping-ios-sdk`, `@forgerock/journey-client`) and the right module split.
- **Best-practice patterns by default.** Jetpack Compose + MVVM on Android, SwiftUI + MVVM on iOS, `KeychainStorage` / `EncryptedDataStore`, OIDC centralized login via `ASWebAuthenticationSession` — customers inherit Ping's recommended architecture instead of inventing one.
- **Migration becomes a Tuesday afternoon, not a quarter.** The migration skill turns ForgeRock sunset risk from a planning exercise into a guided, reversible run with a report attached.
- **Same answers across IDEs.** Whichever assistant the customer's team standardizes on, the integration story is identical.

---

## 6. Why this benefits Support and Professional Services

**Support**

- **Reproduction in seconds.** A ticket says "DaVinci FIDO collector loops on Android." Support runs the umbrella skill in the customer's repo, gets the canonical implementation, diffs it against what the customer wrote — the bug usually surfaces immediately.
- **Ticket deflection at the source.** The most common "how do I…" tickets (callback rendering, OIDC redirect wiring, token storage) are answered before they're filed because the skill answered them in the customer's IDE.
- **Skills evolve with the platform.** When a callback gets a new field, we update one `SKILL.md` and every agent everywhere is current the next session — no doc-site cache, no version drift.

**Professional Services**

- **Consistent starting point across every engagement.** No more "this PS engineer scaffolds it differently than that one." The skill is the standard.
- **Faster discovery.** The router probes a customer's monorepo and tells PS exactly what's there: Android + iOS + lingering ForgeRock JS. Engagement scoping in minutes.
- **Migration playbook, productized.** PS ForgeRock-to-Ping migrations stop being bespoke and start being a guided run with an auditable report — billable hours shift from mechanical edits to high-value design decisions.
- **Knowledge capture loop.** Every recurring PS pattern ("this customer needed X, we did Y") becomes a skill update, so the next engagement starts where the last one ended.

---

## 7. What's next

- **React Native** — already a placeholder row in the router registry; activating it is one probe block.
- **More backend-specific skills** — Protect, Verify, Authorize, MFA Push.
- **Telemetry** — measure which skills fire, which paths users take, where they drop off, and feed that back into the descriptions.
- **Contributions welcome** — `CONTRIBUTING.md` explains the pattern. Every PS engineer and Support engineer is a potential skill author.

---