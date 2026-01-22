# Agent Compatibility

This document describes compatibility with AI coding agents that support the [Agent Skills Standard](https://skills.sh).

## Supported Agents

| Agent | Installation Method | Notes |
|-------|---------------------|-------|
| **Claude Code** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support, recommended |
| **Cursor** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **VS Code Copilot** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **Windsurf** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **Cline** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **Aider** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **Continue** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **Zed** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **Void** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **Roo Code** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **Trae** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **Codex** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **GitHub Copilot** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **Amazon Q** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **Tabnine** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **JetBrains AI** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **CodeGPT** | `npx add-skill olakai-ai/olakai-skills/<skill>` | Full support |
| **Claude Desktop** | ZIP upload via Settings | Manual installation |

## Installation

### Via add-skill (Recommended)

The `add-skill` CLI tool automatically detects your AI coding agent and installs skills in the correct location.

```bash
# List available skills
npx add-skill olakai-ai/olakai-skills --list

# Install specific skill
npx add-skill olakai-ai/olakai-skills/olakai-create-agent

# Install all skills
npx add-skill olakai-ai/olakai-skills/olakai-create-agent
npx add-skill olakai-ai/olakai-skills/olakai-add-monitoring
npx add-skill olakai-ai/olakai-skills/olakai-troubleshoot
npx add-skill olakai-ai/olakai-skills/generate-analytics-reports
```

### Manual Installation

For agents not supported by `add-skill` or for offline installation:

```bash
# User-level (all projects)
git clone https://github.com/olakai-ai/olakai-skills ~/.claude/skills/olakai-skills

# Project-level (version controlled)
git clone https://github.com/olakai-ai/olakai-skills .claude/skills/olakai-skills
```

## Skill Capabilities

All Olakai skills are **read-write** skills that guide users through:

1. **CLI Operations** - Running Olakai CLI commands for configuration
2. **Code Generation** - Writing SDK integration code in TypeScript/Python
3. **Diagnostics** - Inspecting and validating monitoring data

### Required Tools

Skills expect the following tools to be available:

| Tool | Purpose | Required By |
|------|---------|-------------|
| **Bash/Terminal** | Running CLI commands | All skills |
| **File Read** | Examining existing code | olakai-add-monitoring, olakai-troubleshoot |
| **File Write** | Adding SDK integration | olakai-create-agent, olakai-add-monitoring |

## Invocation

Skills are automatically triggered based on user requests. Example triggers:

| User Request | Skill Invoked |
|--------------|---------------|
| "Create an AI agent with monitoring" | olakai-create-agent |
| "Add Olakai to my existing code" | olakai-add-monitoring |
| "My KPIs are showing wrong values" | olakai-troubleshoot |
| "Generate a usage report" | generate-analytics-reports |

## Bundled Agent

For complex integration tasks, the **olakai-expert** agent combines all skills:

```
Use the olakai-expert agent to set up monitoring for my AI chatbot
```

The bundled agent is available when skills are installed via git clone (not individual skill installation).

## Feedback

Report issues at [github.com/olakai-ai/olakai-skills/issues](https://github.com/olakai-ai/olakai-skills/issues).
