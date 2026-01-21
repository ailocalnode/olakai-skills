# Olakai Plugin for Claude Code

Official plugin for integrating AI agents with [Olakai](https://olakai.ai) - the enterprise AI observability and governance platform.

## Skills Included

| Skill | Description |
|-------|-------------|
| **olakai-create-agent** | Create a new AI agent with Olakai monitoring from scratch |
| **olakai-add-monitoring** | Add Olakai monitoring to an existing AI agent |
| **olakai-troubleshoot** | Troubleshoot monitoring issues - missing events, KPI problems |
| **generate-analytics-reports** | Generate terminal-based analytics reports from Olakai data |

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
