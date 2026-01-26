# CLAUDE.md - Olakai Skills Repository

This file provides guidance to Claude Code when working with the olakai-skills repository.

## Repository Overview

This is a **Claude Code skills plugin** for the Olakai AI observability platform. It provides guided workflows for integrating AI agents with Olakai monitoring, analytics, and governance.

**Purpose**: Help developers integrate Olakai into their AI agents through interactive Claude Code skills.

**Target Users**: AI coding assistants (Claude Code, Cursor, VS Code Copilot) helping developers with Olakai integration.

## Repository Structure

The repository uses a **dual-directory structure** for compatibility with both the Agent Skills standard (skills.sh) and the Claude Code plugin system.

```
olakai-skills/
├── skills/                       # CANONICAL: Agent Skills standard structure
│   ├── olakai-get-started/
│   │   └── SKILL.md              # Onboarding: install CLI, auth, first agent (~300 lines)
│   ├── olakai-create-agent/
│   │   └── SKILL.md              # Create new agents with monitoring (~540 lines)
│   ├── olakai-add-monitoring/
│   │   └── SKILL.md              # Add monitoring to existing code (~680 lines)
│   ├── olakai-troubleshoot/
│   │   └── SKILL.md              # Diagnose and fix issues (~610 lines)
│   └── generate-analytics-reports/
│       └── SKILL.md              # Generate CLI-based analytics reports (~500 lines)
├── plugins/
│   └── olakai/                   # Claude Code plugin directory
│       ├── .claude-plugin/
│       │   └── plugin.json       # Plugin metadata (version 1.4.0)
│       ├── README.md             # Plugin documentation
│       ├── agents/
│       │   └── olakai-expert.md  # Bundled agent combining all skills
│       └── skills/               # SYMLINKS to root skills/ directory
│           ├── olakai-get-started -> ../../../skills/olakai-get-started
│           ├── olakai-create-agent -> ../../../skills/olakai-create-agent
│           ├── olakai-add-monitoring -> ../../../skills/olakai-add-monitoring
│           ├── olakai-troubleshoot -> ../../../skills/olakai-troubleshoot
│           ├── generate-analytics-reports -> ../../../skills/generate-analytics-reports
│           └── olakai-planning -> ../../../skills/olakai-planning
├── .claude-plugin/
│   └── marketplace.json          # Root marketplace manifest
├── hooks/                        # Optional skill activation hooks
│   ├── skill-activator.sh        # Hook script for auto-invocation
│   ├── README.md                 # Hook installation instructions
│   └── settings-snippet.json     # Settings configuration to copy
├── docs/
│   └── publishing-guide.md       # Distribution & packaging guide
├── CLAUDE.md                     # This file
├── README.md                     # User-facing installation guide (skills.sh compatible)
├── AGENTS.md                     # Agent compatibility documentation
└── LICENSE                       # MIT License
```

### Dual-Directory Design

**Root `skills/` directory** (canonical location):
- Contains the actual SKILL.md files
- Follows the Agent Skills standard structure
- Used by `npx add-skill` for installation
- Edits should be made here

**`plugins/olakai/skills/` directory** (symlinks):
- Contains symbolic links pointing to root `skills/`
- Provides Claude Code plugin compatibility
- Changes in root skills/ are automatically reflected here
- Do NOT edit files through symlinks directly

## Skills Overview

| Skill | Lines | Purpose |
|-------|-------|---------|
| `olakai-get-started` | ~300 | Onboarding: account creation, CLI install, auth, first agent |
| `olakai-create-agent` | ~540 | Build new AI agents from scratch with full observability |
| `olakai-add-monitoring` | ~680 | Add Olakai to existing working AI code with minimal changes |
| `olakai-troubleshoot` | ~610 | Diagnose missing events, KPI issues, SDK errors |
| `generate-analytics-reports` | ~500 | Generate terminal-based analytics reports (usage, KPIs, risk, ROI) |
| `olakai-planning` | ~350 | Structure implementation plans to survive context clearing |

Each skill follows YAML frontmatter + Markdown format with:
- `name`: Skill identifier
- `description`: Brief purpose
- `license`: MIT
- `metadata`: Author and version info

## The Golden Rule

All skills enforce this validation pattern:

```bash
# 1. Run agent (generate event)
# 2. Fetch event
olakai activity list --agent-id AGENT_ID --limit 1 --json
olakai activity get EVENT_ID --json | jq '{customData, kpiData}'

# 3. Validate:
#    - customData has expected fields
#    - kpiData shows NUMBERS (not strings like "MyVariable")
#    - kpiData shows VALUES (not null)
```

This pattern MUST be preserved across all skills.

---

## Workflow Hierarchy Principle

**Every agent MUST belong to a workflow**, even single agents.

```
Workflow (required container)
└── Agent(s)
```

**Why:**
- Enables future multi-agent expansion
- Provides workflow-level KPI aggregation
- Establishes proper organizational hierarchy
- Supports workflow-level governance

**When creating agents, always:**
1. Create workflow first: `olakai workflows create --name "Name"`
2. Associate agent: `olakai agents create --workflow WORKFLOW_ID ...`

---

## customData Purpose and Restrictions

**customData is ONLY for:**
1. KPI variables (fields used in formula calculations)
2. Tagging/filtering (fields used to query/group events)

**DO NOT send in customData:**
| Field Type | Already Tracked By | Don't Duplicate |
|------------|-------------------|-----------------|
| Session ID | SDK automatic | ❌ sessionId |
| Agent ID | API key | ❌ agentId |
| User email | userEmail param | ❌ email |
| Timestamps | Event metadata | ❌ timestamp |
| Token count | tokens param | ❌ tokenCount |
| Model/Provider | Auto-detected | ❌ model, provider |

**Before creating a CustomDataConfig, ask:**
- "Will I use this in a KPI formula?" → Yes → Create it
- "Will I filter/group by this?" → Yes → Create it
- Neither → Don't create it

---

## Critical Concept: customData → KPI Pipeline

**This is the most important concept to convey to users.** Understanding this pipeline prevents most integration issues.

### The Data Flow

```
SDK customData → CustomDataConfig (Schema) → Context Variable → KPI Formula → kpiData
```

1. **SDK customData**: Raw JSON sent with each event (accepts any structure)
2. **CustomDataConfig**: Platform schema defining which fields are processed
3. **Context Variable**: CustomDataConfig fields become available for formulas
4. **KPI Formula**: Expression that computes a metric (e.g., `SuccessRate * 100`)
5. **kpiData**: Computed KPI values returned with each event

### The Critical Insight

> ⚠️ **The SDK accepts any JSON in customData, but ONLY fields with CustomDataConfigs become KPI variables.**

| What You Send | CustomDataConfig Exists? | Result |
|---------------|-------------------------|--------|
| `ItemsProcessed: 10` | ✅ Yes | Available in KPIs, queryable |
| `randomField: "foo"` | ❌ No | Stored but **NOT usable in KPIs** |

### Why This Matters

When implementing agents, coding assistants often:
- ❌ Send extra "helpful" fields in customData that are never registered
- ❌ Create KPIs before CustomDataConfigs exist
- ❌ Skip KPI setup entirely, losing Olakai's core value

### The Correct Sequence

1. **Design metrics** - Decide what fields you need
2. **Create CustomDataConfigs** - `olakai custom-data create --name X --type NUMBER`
3. **Create KPIs** - `olakai kpis create --formula "X" --agent-id ID`
4. **THEN write SDK code** - Send only registered fields in customData

### Scoping: CustomDataConfigs vs KPIs

| Aspect | CustomDataConfig | KPI |
|--------|-----------------|-----|
| **Scope** | Account-level | Agent-level |
| **Sharing** | Shared across all agents | Unique to one agent |
| **Creation** | Create once, available everywhere | Create separately for each agent |
| **CLI flag** | No `--agent-id` needed | `--agent-id` required |

CustomDataConfigs define the schema for fields your SDK sends — they are created once per account and apply to all agents. KPIs, however, are **bound to a single agent**. Even if two agents need the same KPI formula, you must create the KPI separately for each agent using `olakai kpis create --agent-id EACH_AGENT_ID`.

---

## KPIs Are Mandatory, Not Optional

**Olakai's value proposition is custom KPI tracking.** Skills must emphasize:

- Every agent should have 2-4 KPIs
- KPIs answer: "How do I know this agent is performing well?"
- Without KPIs, you're just logging - not gaining insights

### Typical KPIs by Agent Type

| Agent Type | Typical KPIs |
|------------|--------------|
| **Agentic (workflows)** | Items processed, success rate, step efficiency, error count |
| **Assistive (chatbots)** | Response quality, resolution rate, user satisfaction |

### KPIs Are Unique Per Agent

> ⚠️ **KPIs are unique per agent.** Each KPI definition belongs to exactly one agent and cannot be shared or reused across agents. If multiple agents need the same KPI, create it separately for each using `olakai kpis create --agent-id EACH_AGENT_ID`. This is unlike CustomDataConfigs, which are account-level and shared.

The `--agent-id` flag on all KPI commands (`kpis list`, `kpis create`, `kpis validate`) is not optional — it reflects the architectural binding of KPIs to individual agents. There is no way to create a "global" KPI that applies to multiple agents.

---

## Skill Auto-Invocation Guide

Before answering Olakai-related questions, evaluate whether to load a skill:

### Skill Selection Matrix

| User Intent | Skill to Load | Keywords |
|-------------|---------------|----------|
| **Not set up yet** | `olakai-get-started` | get started, setup, install, signup, account, new to olakai |
| Build new AI agent | `olakai-create-agent` | create, new, build, start, design agent |
| Add monitoring to existing code | `olakai-add-monitoring` | add, integrate, existing, wrap, instrument |
| Something not working | `olakai-troubleshoot` | not working, error, missing, wrong, null, debug |
| View data/metrics | `generate-analytics-reports` | report, analytics, summary, trends, usage |
| Create implementation plan | `olakai-planning` | plan, steps, roadmap, architecture, design, plan mode |

### Invocation Pattern

1. **CHECK PREREQUISITES FIRST**: Run `which olakai` and `olakai whoami` to detect setup state
2. **IF NOT SET UP**: Invoke `olakai-get-started` regardless of user intent
3. **EVALUATE**: Does this prompt relate to Olakai? Check for keywords above.
4. **SELECT**: Match intent to the appropriate skill.
5. **INVOKE**: Use `Skill("skill-name")` before proceeding.
6. **EXECUTE**: Follow the skill's instructions.

### Always Invoke olakai-expert Agent When:

- User mentions "olakai" in any context
- User asks about AI agent monitoring or observability
- User mentions KPIs, governance, or event tracking for AI
- User references olakai.yaml, olakai CLI, or Olakai SDKs

---

## Installation Methods

### Agent Skills Standard (Recommended)

```bash
# Using add-skill CLI
npx add-skill olakai-ai/olakai-skills --list
npx add-skill olakai-ai/olakai-skills/olakai-create-agent
```

### Claude Code Plugin

```bash
# Plugin Marketplace
/plugin marketplace add olakai-ai/olakai-skills
/plugin install olakai-create-agent@olakai-skills
```

### Direct Git (user-level)

```bash
git clone https://github.com/olakai-ai/olakai-skills ~/.claude/skills/olakai-skills
```

### Project-level

```bash
git clone https://github.com/olakai-ai/olakai-skills .claude/skills/olakai-skills
```

---

## Cross-Repository Dependencies

This skills repository **documents** the APIs of other Olakai repositories. It does NOT contain code that runs - only markdown guides.

### Dependency Map

```
┌─────────────────────────────────────────────────────────────────────┐
│                    olakai-skills (This Repo)                        │
│   Documents CLI commands, SDK patterns, API endpoints               │
└─────────────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   olakai-cli    │  │ olakai-sdk-     │  │ olakai-sdk-     │
│                 │  │ typescript      │  │ python          │
│ CLI commands    │  │                 │  │                 │
│ documented in   │  │ TypeScript      │  │ Python          │
│ all SKILL.md    │  │ patterns in     │  │ patterns in     │
│ files           │  │ SKILL.md files  │  │ SKILL.md files  │
└─────────────────┘  └─────────────────┘  └─────────────────┘
          │                   │                   │
          └───────────────────┼───────────────────┘
                              ▼
                    ┌─────────────────┐
                    │  localnode-app  │
                    │                 │
                    │ API endpoints   │
                    │ referenced in   │
                    │ curl examples   │
                    └─────────────────┘
```

### What This Repo Documents

| Source Repository | What's Documented | Location in Skills |
|-------------------|-------------------|-------------------|
| `olakai-cli` | CLI commands (agents, activity, kpis, custom-data) | All SKILL.md files |
| `olakai-sdk-typescript` | `OlakaiSDK`, `olakai.wrap()`, `olakai.event()` | All SKILL.md files |
| `olakai-sdk-python` | `olakai_config()`, `instrument_openai()`, `olakai_event()` | All SKILL.md files |
| `localnode-app` | `POST /api/monitoring/prompt` endpoint | olakai-troubleshoot |

---

## Synchronization Requirements

### When to Update This Repo

**CRITICAL**: This repository must stay in sync with CLI and SDK changes. Outdated documentation leads to failed integrations.

| Change Type | Source Repo | Files to Update |
|-------------|-------------|-----------------|
| CLI command syntax change | `olakai-cli` | All SKILL.md + CLAUDE.md |
| New CLI command | `olakai-cli` | Relevant SKILL.md + CLAUDE.md |
| CLI command removed | `olakai-cli` | All SKILL.md + CLAUDE.md |
| TypeScript SDK API change | `olakai-sdk-typescript` | All SKILL.md (TypeScript examples) |
| Python SDK API change | `olakai-sdk-python` | All SKILL.md (Python examples) |
| API endpoint change | `localnode-app` | olakai-troubleshoot (curl examples) |
| New KPI feature | `localnode-app` | olakai-create-agent, olakai-troubleshoot |

### Synchronization Checklist

When updating source repositories, run these checks:

```bash
# After CLI changes in olakai-cli:
cd olakai-skills

# Find all CLI command references (search root skills/ directory)
grep -r "olakai agents" skills/
grep -r "olakai activity" skills/
grep -r "olakai kpis" skills/
grep -r "olakai custom-data" skills/
grep -r "olakai login\|olakai whoami" skills/

# After TypeScript SDK changes:
grep -r "OlakaiSDK" skills/
grep -r "olakai.wrap" skills/
grep -r "olakai.event" skills/
grep -r "olakai.init" skills/
grep -r "@olakai/sdk" skills/

# After Python SDK changes:
grep -r "olakai_config" skills/
grep -r "instrument_openai" skills/
grep -r "olakai_event" skills/
grep -r "olakai_context" skills/
grep -r "olakaisdk" skills/

# After API endpoint changes:
grep -r "api/monitoring/prompt" skills/
grep -r "app.olakai.ai" skills/
```

### CLI Commands Referenced in Skills

These commands appear in SKILL.md files and must match `olakai-cli` implementation:

```bash
# Authentication
olakai login
olakai logout
olakai whoami

# Agents
olakai agents list [--json]
olakai agents create --name "Name" [--description "Desc"] [--with-api-key] [--json]
olakai agents get AGENT_ID [--json]
olakai agents update AGENT_ID [--name "Name"] [--workflow WORKFLOW_ID]

# Activity
olakai activity list [--limit N] [--agent-id ID] [--json]
olakai activity get EVENT_ID [--json]

# KPIs
olakai kpis list --agent-id ID [--json]
olakai kpis create --name "Name" --agent-id ID --calculator-id formula --formula "X" [--unit "unit"] [--aggregation SUM|AVERAGE]
olakai kpis update KPI_ID --formula "X"
olakai kpis validate --formula "X" --agent-id ID
olakai kpis delete KPI_ID [--force]

# Custom Data
olakai custom-data list [--json]
olakai custom-data create --name "Name" --type NUMBER|STRING [--description "Desc"]

# Workflows
olakai workflows create --name "Name"
```

### SDK Patterns Referenced in Skills

**TypeScript (`@olakai/sdk`):**
```typescript
// Initialization
const olakai = new OlakaiSDK({ apiKey: process.env.OLAKAI_API_KEY!, debug: boolean });
await olakai.init();

// Wrapped client
const openai = olakai.wrap(new OpenAI({ apiKey }), { provider: "openai", defaultContext: {...} });

// Call with context (session grouping is automatic)
await openai.chat.completions.create(params, { userEmail, task, customData });

// Manual event
olakai.event({ prompt, response, tokens, requestTime, task, customData });
```

**Python (`olakai-sdk`):**
```python
# Initialization
from olakaisdk import olakai_config, instrument_openai, olakai_context, olakai_event, OlakaiEventParams

olakai_config(api_key, debug=bool)
instrument_openai()

# Context manager
with olakai_context(userEmail=str, task=str, customData=dict):
    response = client.chat.completions.create(...)

# Manual event
olakai_event(OlakaiEventParams(prompt=str, response=str, tokens=int, requestTime=int, task=str, customData=dict))
```

---

## Editing Guidelines

### Skill File Guidelines

1. **Keep under 500 lines** - Preserves Claude's context for actual work
2. **YAML frontmatter required** - `name`, `description`, `license`, `metadata` fields
3. **Test after changes** - Install skill in Claude Code and invoke it
4. **Preserve the Golden Rule** - Test → Fetch → Validate pattern in all skills

### Adding New Skills

1. Create directory in root: `skills/new-skill-name/SKILL.md`
2. Add YAML frontmatter with `name`, `description`, `license`, `metadata`
3. Create symlink: `ln -s ../../../skills/new-skill-name plugins/olakai/skills/new-skill-name`
4. Follow existing skill structure
5. Update this CLAUDE.md if skill references new CLI/SDK patterns

### Modifying Existing Skills

1. **Edit in root `skills/` directory** (not through symlinks)
2. Check if change affects the Golden Rule validation pattern
3. Ensure code examples compile/run correctly
4. Verify CLI commands match current `olakai-cli` implementation
5. Test the skill in Claude Code after changes

---

## Version Coordination

When bumping version in `plugins/olakai/.claude-plugin/plugin.json`:

1. Update version number (currently 1.4.0)
2. Update version in all SKILL.md frontmatter metadata
3. Ensure all SKILL.md files are in sync with current CLI/SDK versions
4. Update changelog if maintained

### SDK/CLI Versions Reference

The authoritative source for current published SDK/CLI versions is:
`localnode-app/packages/config/sdk-versions.ts`

Check this file to ensure skills reference the correct versions:
- TypeScript SDK: `@olakai/sdk`
- Python SDK: `olakai-sdk` (PyPI)
- CLI: `olakai-cli`

When SDK or CLI releases occur, verify that code examples in SKILL.md files are compatible with the new version.

---

## Related Repositories

| Repository | Relationship |
|------------|--------------|
| `olakai-cli` | **Source of truth** for CLI commands - skills document these |
| `olakai-sdk-typescript` | **Source of truth** for TypeScript SDK - skills document patterns |
| `olakai-sdk-python` | **Source of truth** for Python SDK - skills document patterns |
| `localnode-app` | Backend API - skills reference endpoints for troubleshooting |

See workspace `/Users/esteban/dev/olakai/CLAUDE.md` for full repository map.
