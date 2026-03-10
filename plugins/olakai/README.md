# Olakai Plugin for Claude Code

Official plugin for integrating AI agents with [Olakai](https://olakai.ai) - the enterprise AI analytics and governance platform. Measure ROI, govern risk, control costs across all AI tools.

## Skills Included

| Skill | Description |
|-------|-------------|
| **olakai-get-started** | Install the CLI, authenticate, and send your first monitored event |
| **olakai-new-project** | Build a new AI agent project from scratch with full observability |
| **olakai-integrate** | Add Olakai to existing AI code with minimal changes |
| **olakai-troubleshoot** | Diagnose and fix issues with events, KPIs, or SDK integration |
| **olakai-reports** | Generate usage summaries, KPI trends, ROI reports from the terminal |

## Agent Included

| Agent | Description |
|-------|-------------|
| **olakai-expert** | Bundled expert that combines all skills for complete Olakai integration |

## Prerequisites

- [Olakai CLI](https://www.npmjs.com/package/olakai-cli): `npm install -g olakai-cli`
- Olakai account and API key

## Usage

Once installed, simply ask Claude to help with Olakai-related tasks:

- "Create a new AI agent with Olakai monitoring"
- "Add monitoring to my existing OpenAI integration"
- "My KPIs are showing string values instead of numbers"

Or invoke the bundled agent directly:

- "Use the olakai-expert agent to set up monitoring"

## The Golden Rule

Always validate integrations by generating a test event:

```bash
olakai activity list --agent-id AGENT_ID --limit 1 --json
olakai activity get EVENT_ID --json | jq '{customData, kpiData}'
```

## Links

- [Olakai Documentation](https://app.olakai.ai/llms.txt)
- [TypeScript SDK](https://www.npmjs.com/package/@olakai/sdk)
- [Python SDK](https://pypi.org/project/olakai-sdk/)
- [CLI Reference](https://www.npmjs.com/package/olakai-cli)
