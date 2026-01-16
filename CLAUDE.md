# CLAUDE.md - Olakai Skills Repository

This file provides guidance to Claude Code when working with the olakai-skills repository.

## Repository Overview

This is a **Claude Code skills plugin** for the Olakai AI observability platform. It provides guided workflows for integrating AI agents with Olakai monitoring, analytics, and governance.

**Purpose**: Help developers integrate Olakai into their AI agents through interactive Claude Code skills.

**Target Users**: AI coding assistants (Claude Code, Cursor, VS Code Copilot) helping developers with Olakai integration.

## Repository Structure

```
olakai-skills/
├── .claude-plugin/
│   └── marketplace.json          # Root marketplace manifest
├── plugins/
│   └── olakai/                   # Main plugin directory
│       ├── .claude-plugin/
│       │   └── plugin.json       # Plugin metadata (version 1.0.0)
│       ├── README.md             # Plugin documentation
│       ├── agents/
│       │   └── olakai-expert.md  # Bundled agent combining all skills
│       └── skills/
│           ├── olakai-create-agent/
│           │   └── SKILL.md      # Create new agents with monitoring (~540 lines)
│           ├── olakai-add-monitoring/
│           │   └── SKILL.md      # Add monitoring to existing code (~680 lines)
│           └── olakai-troubleshoot/
│               └── SKILL.md      # Diagnose and fix issues (~610 lines)
├── docs/
│   └── publishing-guide.md       # Distribution & packaging guide
├── CLAUDE.md                     # This file
├── README.md                     # User-facing installation guide
└── LICENSE                       # MIT License
```

## Skills Overview

| Skill | Lines | Purpose |
|-------|-------|---------|
| `olakai-create-agent` | ~540 | Build new AI agents from scratch with full observability |
| `olakai-add-monitoring` | ~680 | Add Olakai to existing working AI code with minimal changes |
| `olakai-troubleshoot` | ~610 | Diagnose missing events, KPI issues, SDK errors |

Each skill follows YAML frontmatter + Markdown format with progressive disclosure (description loads at startup, full body on activation).

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

# Find all CLI command references
grep -r "olakai agents" plugins/
grep -r "olakai activity" plugins/
grep -r "olakai kpis" plugins/
grep -r "olakai custom-data" plugins/
grep -r "olakai login\|olakai whoami" plugins/

# After TypeScript SDK changes:
grep -r "OlakaiSDK" plugins/
grep -r "olakai.wrap" plugins/
grep -r "olakai.event" plugins/
grep -r "olakai.init" plugins/
grep -r "@olakai/sdk" plugins/

# After Python SDK changes:
grep -r "olakai_config" plugins/
grep -r "instrument_openai" plugins/
grep -r "olakai_event" plugins/
grep -r "olakai_context" plugins/
grep -r "olakaisdk" plugins/

# After API endpoint changes:
grep -r "api/monitoring/prompt" plugins/
grep -r "app.olakai.ai" plugins/
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

// Call with context
await openai.chat.completions.create(params, { userEmail, chatId, task, customData });

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
2. **YAML frontmatter required** - `name`, `description` fields
3. **Test after changes** - Install skill in Claude Code and invoke it
4. **Preserve the Golden Rule** - Test → Fetch → Validate pattern in all skills

### Adding New Skills

1. Create directory: `plugins/olakai/skills/new-skill-name/SKILL.md`
2. Add YAML frontmatter with `name` and `description`
3. Follow existing skill structure
4. Update this CLAUDE.md if skill references new CLI/SDK patterns

### Modifying Existing Skills

1. Check if change affects the Golden Rule validation pattern
2. Ensure code examples compile/run correctly
3. Verify CLI commands match current `olakai-cli` implementation
4. Test the skill in Claude Code after changes

---

## Installation Methods

**Plugin Marketplace (recommended):**
```bash
/plugin marketplace add olakai/olakai-skills
/plugin install olakai-create-agent@olakai-skills
```

**Direct Git (user-level):**
```bash
git clone https://github.com/olakai/olakai-skills ~/.claude/skills/olakai-skills
```

**Project-level:**
```bash
git clone https://github.com/olakai/olakai-skills .claude/skills/olakai-skills
```

---

## Version Coordination

When bumping version in `plugins/olakai/.claude-plugin/plugin.json`:

1. Update version number (currently 1.0.0)
2. Ensure all SKILL.md files are in sync with current CLI/SDK versions
3. Update changelog if maintained

---

## Related Repositories

| Repository | Relationship |
|------------|--------------|
| `olakai-cli` | **Source of truth** for CLI commands - skills document these |
| `olakai-sdk-typescript` | **Source of truth** for TypeScript SDK - skills document patterns |
| `olakai-sdk-python` | **Source of truth** for Python SDK - skills document patterns |
| `localnode-app` | Backend API - skills reference endpoints for troubleshooting |

See workspace `/Users/esteban/dev/olakai/CLAUDE.md` for full repository map.
