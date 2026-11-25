# mxLore Skills

AI-powered development workflows for [Claude Code](https://claude.ai/claude-code). These skills turn Claude into a structured engineering partner — with persistent memory, architectural decisions, and automated quality checks.

> **What is mxLore?** A self-hosted MCP server that gives your AI assistant a brain. Specs, plans, decisions, lessons learned — stored in MariaDB, recalled automatically.
> **[See mxLore in action at mxlore.dev](https://www.mxlore.dev)**

## Skills Overview

### Core Workflow

| Skill | What it does |
|-------|-------------|
| **`/mxOrchestrate`** | Session orchestrator. Manages workflow stacks, ad-hoc tasks, team agents. Tracks what you're working on across sessions. Incoming agent messages reach the session through the local proxy, also while it sits idle. |
| **`/mxSave`** | Persist everything. Session notes, lessons learned, state sync. Run before closing Claude Code. |
| **`/mxPlan`** | Create structured implementation plans with milestones, tasks, and dependencies. |
| **`/mxSpec`** | Write specifications with acceptance criteria, constraints, and design decisions. |
| **`/mxDecision`** | Document architectural decisions as ADRs. Track rationale, alternatives, and consequences. |

### Quality & Analysis

| Skill | What it does |
|-------|-------------|
| **`/mxDesignChecker`** | Review code and designs against specs. Finds inconsistencies, missing error handling, architectural violations. |
| **`/mxBugChecker`** | Find bugs with proof. Every finding requires a code reference — no false positives from guessing. |
| **`/mxHealth`** | Knowledge DB consistency checks. Finds stale docs, orphaned relations, broken summaries. |
| **`/mxKnowledge`** | Component and library dossiers. Retrieves what the knowledge DB knows about a reusable component, tool or third-party library, and creates a dossier when a repeatedly-consulted one has none. |
| **`/mxHelp`** | Lists all installed mx* skills grouped by category, or explains one in detail. Read-only. |

### Setup & Migration

| Skill | What it does |
|-------|-------------|
| **`/mxSetup`** | One-command onboarding. Installs all skills, proxy, hooks, and connects to your mxLore server. |
| **`/mxInitProject`** | Bootstrap a new project in the knowledge DB. Creates CLAUDE.md, registers in MCP. |
| **`/mxMigrateToDb`** | Migrate existing local docs (specs, plans, decisions) into the MCP knowledge DB. |

## Quick Start

### Option A: Via mxSetup (recommended, ~15 seconds)

1. Set up your [mxLore server](https://github.com/MicrotronX/mxLore) first
2. Download the setup skill:
   ```powershell
   # Windows (PowerShell)
   mkdir "$env:USERPROFILE\.claude\skills\mxSetup" -Force
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MicrotronX/mxLore-skills/main/mxSetup/SKILL.md" -OutFile "$env:USERPROFILE\.claude\skills\mxSetup\SKILL.md"
   ```
   ```bash
   # Linux / macOS
   mkdir -p ~/.claude/skills/mxSetup
   curl -o ~/.claude/skills/mxSetup/SKILL.md https://raw.githubusercontent.com/MicrotronX/mxLore-skills/main/mxSetup/SKILL.md
   ```
3. Start Claude Code and run `/mxSetup YOUR_API_KEY`
4. Enter your server URL when prompted (e.g. `http://localhost:8080/mcp`)
5. mxSetup installs all skills, hooks, proxy, and configures the MCP connection
6. Restart Claude Code — done, everything works

### Option B: Manual install

Clone this repo and copy skills to your Claude Code config:

```bash
git clone https://github.com/MicrotronX/mxLore-skills.git
cp -r mxLore-skills/mx* ~/.claude/skills/
cp -r mxLore-skills/_shared ~/.claude/skills/
cp -r mxLore-skills/hooks/* ~/.claude/hooks/
cp -r mxLore-skills/reference/* ~/.claude/reference/
```

Then connect MCP manually:
```bash
claude mcp add -s user --transport http mxai-knowledge \
  "http://localhost:8080/mcp" \
  --header "Authorization: Bearer YOUR_API_KEY"
```

## What's Included

```
mxBugChecker/          — Bug finder with verification
mxDecision/            — ADR documentation
mxDesignChecker/       — Code & design review
  rules/               — Review rules (Delphi, web, general, spec)
mxHealth/              — Knowledge DB health checks
mxHelp/                — Skill overview and help
mxInitProject/         — Project bootstrapping
mxKnowledge/           — Component and library dossiers
mxMigrateToDb/         — Local-to-MCP migration
mxOrchestrate/         — Session orchestrator
  workflows.md         — Workflow templates
mxPlan/                — Implementation planning
mxSave/                — Session persistence
mxSetup/               — Developer onboarding
mxSpec/                — Specification writing
_shared/               — Shared rule files the skills read (installed to ~/.claude/skills/_shared)
hooks/                 — 9 automation hooks + 1 notes file (recall gate, orchestration, env guard, status line)
reference/             — Delphi, PHP/web, encoding guides + MCP tools reference
setup-version.json     — Skills release version
```

## How Skills Work

Skills are slash commands in Claude Code. Type `/mxPlan` and Claude creates a structured implementation plan in your knowledge DB. Type `/mxSave` and your entire session is persisted — decisions, findings, lessons learned.

The skills communicate with your mxLore server via MCP (Model Context Protocol). Everything is stored in MariaDB, searchable across projects, and recalled automatically in future sessions.

```
You: /mxPlan add user authentication
Claude: Creates a plan with milestones, tasks, risks
        Stores it in MariaDB via MCP
        Links it to related specs and decisions

Next session:
Claude: Recalls the plan, your progress, and relevant lessons
        Picks up exactly where you left off
```

## Requirements

- [mxLore MCP Server](https://github.com/MicrotronX/mxLore) (self-hosted)
- [Claude Code](https://claude.ai/claude-code) CLI or IDE extension
- MariaDB 10.6+
- [Node.js](https://nodejs.org/) for the hooks (7 of the 9 are Node scripts; without it the skills still work, but state tracking and the recall gate stay silent)
- An API key — created in the mxLore server's Admin UI (<http://localhost:8081>)

## Links

- **[mxlore.dev](https://www.mxlore.dev)** — Product overview, features, comparison
- **[Team Collaboration Guide](https://github.com/MicrotronX/mxLore/blob/main/docs/team-collaboration.md)** — How PM, Dev, QA & Doc work together through mxLore
- **[MicrotronX/mxLore](https://github.com/MicrotronX/mxLore)** — Server source code
- **[MicrotronX/mxLore-skills](https://github.com/MicrotronX/mxLore-skills)** — This repo

## License

The skills are released under the MIT License (see [LICENSE.txt](LICENSE.txt)). The [mxLore server](https://github.com/MicrotronX/mxLore/blob/main/LICENSE.txt) is licensed under BSL 1.1.
