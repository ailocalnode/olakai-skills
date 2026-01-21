# Olakai Skills for Claude Code

Official skills for integrating AI agents with [Olakai](https://olakai.ai) - the enterprise AI observability and governance platform.

These skills follow the [Agent Skills Open Standard](https://agentskills.io) and work with Claude Code, Cursor, VS Code Copilot, and other compatible AI coding assistants.

## Available Skills

| Skill | Description |
|-------|-------------|
| **olakai-create-agent** | Create a new AI agent with Olakai monitoring from scratch |
| **olakai-add-monitoring** | Add Olakai monitoring to an existing AI agent or LLM integration |
| **olakai-troubleshoot** | Troubleshoot monitoring issues - missing events, KPI problems, SDK errors |
| **generate-analytics-reports** | Generate terminal-based analytics reports (usage, KPIs, risk, ROI) without the web UI |

## Bundled Agent

The **olakai-expert** agent bundles all four skills together, providing a single specialist that can handle any Olakai integration task:

| Agent | Description |
|-------|-------------|
| **olakai-expert** | Full Olakai integration specialist - creates agents, adds monitoring, troubleshoots issues, generates reports |

## Installation

### Option 1: Claude Code Plugin Marketplace (Recommended)

```bash
# Add the Olakai skills marketplace
/plugin marketplace add olakai-ai/olakai-skills

# Install individual skills
/plugin install olakai-create-agent@olakai-skills
/plugin install olakai-add-monitoring@olakai-skills
/plugin install olakai-troubleshoot@olakai-skills
/plugin install generate-analytics-reports@olakai-skills
```

### Option 2: Direct Git Installation (User-level)

Install for all your projects:

```bash
git clone https://github.com/olakai-ai/olakai-skills ~/.claude/skills/olakai-skills
```

### Option 3: Project-level Installation

Install for a specific project (add to version control):

```bash
git clone https://github.com/olakai-ai/olakai-skills .claude/skills/olakai-skills
```

### Option 4: Claude Desktop / claude.ai

Download the ZIP files from the [Releases](https://github.com/olakai-ai/olakai-skills/releases) page and upload through **Settings > Capabilities > Skills**.

### Installing the Bundled Agent

The plugin marketplace installs individual skills. To use the bundled **olakai-expert** agent, clone the repo and copy the agents directory:

```bash
# Clone the repo
git clone https://github.com/olakai-ai/olakai-skills /tmp/olakai-skills

# Copy agents to user-level (available in all projects)
cp -r /tmp/olakai-skills/agents ~/.claude/agents/

# Or copy to project-level (version controlled)
cp -r /tmp/olakai-skills/agents .claude/agents/

# Clean up
rm -rf /tmp/olakai-skills
```

Alternatively, use the full git installation (Option 2 or 3) which includes both skills and agents.

## Usage

### Individual Skills

Once installed, simply ask Claude to help with Olakai-related tasks:

- "Create a new AI agent with Olakai monitoring"
- "Add monitoring to my existing OpenAI integration"
- "My KPIs are showing string values instead of numbers"

Claude will automatically invoke the relevant skill.

### Bundled Agent

If you installed the bundled agent, you can invoke it directly:

```
Use the olakai-expert agent to set up monitoring for my AI chatbot
```

The agent has all three skills loaded and will guide you through the complete workflow.

## The Golden Rule: Test → Fetch → Validate

**Always validate your Olakai integration by generating a test event and inspecting it:**

```bash
# 1. Run your agent/trigger LLM call
# 2. Fetch the event
olakai activity list --agent-id AGENT_ID --limit 1 --json
olakai activity get EVENT_ID --json | jq '{customData, kpiData}'

# 3. Validate:
#    - customData has all expected fields
#    - kpiData shows NUMBERS (not strings like "MyVariable")
#    - kpiData shows VALUES (not null)
```

## Prerequisites

- [Olakai CLI](https://www.npmjs.com/package/olakai-cli): `npm install -g olakai-cli`
- Olakai account and API key

## Quick Reference

```bash
# CLI Authentication
olakai login
olakai whoami

# View Activity
olakai activity list --limit 10
olakai activity get EVENT_ID --json

# Manage Agents (includes API key generation)
olakai agents list
olakai agents create --name "Agent Name" --with-api-key --json
olakai agents get AGENT_ID --json | jq '.apiKey'

# Manage KPIs
olakai kpis list --agent-id ID
olakai kpis create --formula "Variable" --agent-id ID

# Manage Custom Data
olakai custom-data list
olakai custom-data create --name "Field" --type NUMBER
```

## SDK Quick Start

**TypeScript:**
```typescript
import { OlakaiSDK } from "@olakai/sdk";
const olakai = new OlakaiSDK({ apiKey: process.env.OLAKAI_API_KEY! });
await olakai.init();
const openai = olakai.wrap(new OpenAI({ apiKey }), { provider: "openai" });
```

**Python:**
```python
from olakaisdk import olakai_config, instrument_openai
olakai_config(os.getenv("OLAKAI_API_KEY"))
instrument_openai()
```

## Documentation

- [Olakai Documentation](https://app.olakai.ai/llms.txt)
- [TypeScript SDK](https://www.npmjs.com/package/@olakai/sdk)
- [Python SDK](https://pypi.org/project/olakai-sdk/)
- [CLI Reference](https://www.npmjs.com/package/olakai-cli)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please read our contributing guidelines before submitting PRs.

---

Built with ❤️ by [Olakai](https://olakai.ai)
