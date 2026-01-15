---
name: olakai-create-agent
description: Create a new AI agent with Olakai monitoring. Use when building AI features, workflows, or agents that need observability, KPI tracking, and governance.
---

# Create AI Agent with Olakai Monitoring

This skill guides you through creating a new AI agent that is fully integrated with Olakai for monitoring, analytics, and governance.

## Prerequisites

Before starting, ensure:
1. Olakai CLI installed: `npm install -g olakai-cli`
2. CLI authenticated: `olakai login`
3. API key for SDK (generated per-agent via CLI - see Step 2.1)

## Step 1: Design the Agent Architecture

### 1.1 Determine Agent Type

**Agentic AI** (Multi-step autonomous workflows):
- Research agents, document processors, data pipelines
- Track as SINGLE events aggregating all internal LLM calls
- Focus on workflow-level metrics (total tokens, total time, success/failure)

**Assistive AI** (Interactive chatbots/copilots):
- Customer support bots, coding assistants, Q&A systems
- Track EACH interaction as separate events
- Focus on conversation-level metrics (per-message tokens, response quality)

### 1.2 Define Metrics to Track

Plan what custom data your agent will report:

```typescript
// Example custom data fields for an agent
customData: {
  // Workflow identification
  workflowId: string,      // Unique workflow run ID
  executionId: string,     // Correlation ID across steps

  // Business metrics
  itemsProcessed: number,  // Count of items handled
  successRate: number,     // 0-1 success ratio

  // Performance metrics
  stepCount: number,       // Number of workflow steps
  retryCount: number,      // Number of retries needed

  // Domain-specific
  [yourMetric]: number | string | boolean
}
```

## Step 2: Configure Olakai Platform

### 2.1 Create the Agent in Olakai

```bash
# Create the agent with an API key for SDK integration
olakai agents create \
  --name "Your Agent Name" \
  --description "What this agent does" \
  --with-api-key \
  --json

# Returns agent details including apiKey for SDK use:
# {
#   "id": "cmkbteqn501kyjy4yu6p6xrrx",
#   "name": "Your Agent Name",
#   "apiKey": "sk_agent_xxxxx..."   <-- Use this in your SDK
# }

# To retrieve an existing agent's API key:
olakai agents get AGENT_ID --json | jq '.apiKey'
```

### 2.2 Create Custom Data Configurations

For each custom metric your agent will report, create a CustomDataConfig:

```bash
# For numeric metrics
olakai custom-data create --name "ItemsProcessed" --type NUMBER --description "Count of items processed per run"
olakai custom-data create --name "SuccessRate" --type NUMBER --description "Success ratio 0-1"
olakai custom-data create --name "StepCount" --type NUMBER --description "Number of workflow steps executed"

# For string metrics
olakai custom-data create --name "WorkflowId" --type STRING --description "Unique workflow run identifier"
olakai custom-data create --name "ExecutionId" --type STRING --description "Correlation ID for the execution"

# Verify all configs are created
olakai custom-data list
```

### 2.3 Create KPI Definitions

Define KPIs that use your custom data:

```bash
# Simple variable KPIs
olakai kpis create \
  --name "Items Processed" \
  --agent-id YOUR_AGENT_ID \
  --calculator-id formula \
  --formula "ItemsProcessed" \
  --unit "items" \
  --aggregation SUM

# Calculated KPIs
olakai kpis create \
  --name "Success Rate" \
  --agent-id YOUR_AGENT_ID \
  --calculator-id formula \
  --formula "SuccessRate * 100" \
  --unit "%" \
  --aggregation AVERAGE

# Conditional KPIs
olakai kpis create \
  --name "Error Count" \
  --agent-id YOUR_AGENT_ID \
  --calculator-id formula \
  --formula "IF(SuccessRate < 1, 1, 0)" \
  --unit "errors" \
  --aggregation SUM

# Validate formulas before creating
olakai kpis validate --formula "ItemsProcessed" --agent-id YOUR_AGENT_ID
```

### 2.4 Optionally Create a Workflow

If your agent is part of a larger workflow with multiple agents:

```bash
# Create workflow
olakai workflows create --name "My Workflow Name"

# Associate agent with workflow
olakai agents update YOUR_AGENT_ID --workflow WORKFLOW_ID
```

## Step 3: Implement SDK Integration

### 3.1 TypeScript Implementation (Recommended)

**Install dependencies:**
```bash
npm install @olakai/sdk openai
```

**Basic wrapped client setup:**
```typescript
import { OlakaiSDK } from "@olakai/sdk";
import OpenAI from "openai";

// Initialize Olakai
const olakai = new OlakaiSDK({
  apiKey: process.env.OLAKAI_API_KEY!,
  debug: process.env.NODE_ENV === "development",
});
await olakai.init();

// Wrap your LLM client
const openai = olakai.wrap(
  new OpenAI({ apiKey: process.env.OPENAI_API_KEY }),
  {
    provider: "openai",
    defaultContext: {
      task: "Your Task Category", // e.g., "Data Processing & Analysis"
    },
  }
);

// Use wrapped client - monitoring happens automatically
const response = await openai.chat.completions.create({
  model: "gpt-4o",
  messages: [{ role: "user", content: userPrompt }],
});
```

**Agentic workflow with manual event tracking:**
```typescript
async function runAgent(input: string): Promise<string> {
  const startTime = Date.now();
  const executionId = crypto.randomUUID();
  let totalTokens = 0;
  let stepCount = 0;
  let itemsProcessed = 0;

  try {
    // Step 1: Planning
    stepCount++;
    const plan = await openai.chat.completions.create({
      model: "gpt-4o",
      messages: [{ role: "user", content: `Plan: ${input}` }],
    });
    totalTokens += plan.usage?.total_tokens ?? 0;

    // Step 2: Execution (example: process multiple items)
    const items = parseItems(plan.choices[0].message.content);
    for (const item of items) {
      stepCount++;
      const result = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [{ role: "user", content: `Process: ${item}` }],
      });
      totalTokens += result.usage?.total_tokens ?? 0;
      itemsProcessed++;
    }

    // Step 3: Summarize
    stepCount++;
    const summary = await openai.chat.completions.create({
      model: "gpt-4o",
      messages: [{ role: "user", content: "Summarize results" }],
    });
    totalTokens += summary.usage?.total_tokens ?? 0;

    const finalResponse = summary.choices[0].message.content ?? "";

    // Track the complete workflow as a single event
    olakai.event({
      prompt: input,
      response: finalResponse,
      tokens: totalTokens,
      requestTime: Date.now() - startTime,
      task: "Data Processing & Analysis",
      customData: {
        executionId,
        stepCount,
        itemsProcessed,
        successRate: 1.0,
      },
    });

    return finalResponse;
  } catch (error) {
    // Track failed execution
    olakai.event({
      prompt: input,
      response: `Error: ${error instanceof Error ? error.message : "Unknown"}`,
      tokens: totalTokens,
      requestTime: Date.now() - startTime,
      task: "Data Processing & Analysis",
      customData: {
        executionId,
        stepCount,
        itemsProcessed,
        successRate: 0,
      },
    });
    throw error;
  }
}
```

### 3.2 Python Implementation

**Install dependencies:**
```bash
pip install olakai-sdk openai
```

**Auto-instrumentation setup:**
```python
import os
from olakaisdk import olakai_config, instrument_openai, olakai_context, olakai_event, OlakaiEventParams
from openai import OpenAI

# Initialize Olakai
olakai_config(os.getenv("OLAKAI_API_KEY"))
instrument_openai()

# Create OpenAI client (automatically instrumented)
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# For assistive AI - use context manager
with olakai_context(userEmail="user@example.com", task="Customer Support"):
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": user_message}]
    )
```

**Manual event tracking for agentic workflows:**
```python
import time
import uuid

def run_agent(input_text: str) -> str:
    start_time = time.time()
    execution_id = str(uuid.uuid4())
    total_tokens = 0
    step_count = 0
    items_processed = 0

    try:
        # Your workflow steps here...
        step_count += 1
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": input_text}]
        )
        total_tokens += response.usage.total_tokens

        final_response = response.choices[0].message.content

        # Track successful execution
        olakai_event(OlakaiEventParams(
            prompt=input_text,
            response=final_response,
            tokens=total_tokens,
            requestTime=int((time.time() - start_time) * 1000),
            task="Data Processing & Analysis",
            customData={
                "executionId": execution_id,
                "stepCount": step_count,
                "itemsProcessed": items_processed,
                "successRate": 1.0,
            }
        ))

        return final_response

    except Exception as e:
        # Track failed execution
        olakai_event(OlakaiEventParams(
            prompt=input_text,
            response=f"Error: {str(e)}",
            tokens=total_tokens,
            requestTime=int((time.time() - start_time) * 1000),
            task="Data Processing & Analysis",
            customData={
                "executionId": execution_id,
                "stepCount": step_count,
                "itemsProcessed": items_processed,
                "successRate": 0,
            }
        ))
        raise
```

### 3.3 REST API Direct Integration

For other languages or custom integrations:

```bash
curl -X POST "https://app.olakai.ai/api/monitoring/prompt" \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "prompt": "User input here",
    "response": "Agent response here",
    "app": "your-agent-name",
    "task": "Data Processing & Analysis",
    "tokens": 1500,
    "requestTime": 5000,
    "customData": {
      "executionId": "abc-123",
      "stepCount": 5,
      "itemsProcessed": 10,
      "successRate": 1.0
    }
  }'
```

## Step 4: Test-Validate-Iterate Cycle

**CRITICAL:** Always validate your implementation by running a test and inspecting the actual event data. Do not assume configuration is correct - verify it.

### 4.1 Run Your Agent (Generate Test Event)

Execute your agent with test data to generate at least one monitoring event:

```typescript
// Run your agent
const result = await runAgent("Test input for validation");
console.log("Agent completed, checking Olakai...");
```

### 4.2 Fetch and Inspect the Event

```bash
# List recent activity for your agent
olakai activity list --agent-id YOUR_AGENT_ID --limit 1 --json

# Get the full event details including customData and kpiData
olakai activity get EVENT_ID --json
```

### 4.3 Validate Each Component

**Check customData is present and correct:**
```bash
olakai activity get EVENT_ID --json | jq '.customData'
```

Expected output:
```json
{
  "executionId": "abc-123",
  "stepCount": 5,
  "itemsProcessed": 10,
  "successRate": 1.0
}
```

If fields are missing: SDK isn't sending them. Check your `customData` object in the event call.

**Check KPIs are numeric (not strings):**
```bash
olakai activity get EVENT_ID --json | jq '.kpiData'
```

**CORRECT** - numeric values:
```json
{
  "Items Processed": 10,
  "Success Rate": 100
}
```

**WRONG** - string values (indicates broken formula):
```json
{
  "Items Processed": "itemsProcessed",
  "Success Rate": "SuccessRate"
}
```

If KPIs show strings: The formula is stored incorrectly. Fix with:
```bash
olakai kpis update KPI_ID --formula "YourVariable"
```

**Check KPIs show values (not null):**

If KPIs show `null`:
1. Verify customData contains the field: `jq '.customData.YourField'`
2. Verify CustomDataConfig exists: `olakai custom-data list`
3. Verify field name case matches exactly (case-sensitive!)

### 4.4 Iterate Until Correct

Repeat the cycle until all validations pass:

```
┌─────────────────────────────────────────────────────────┐
│  1. Run agent (generate event)                          │
│                    ↓                                    │
│  2. Fetch event: olakai activity get ID --json          │
│                    ↓                                    │
│  3. Check customData present?                           │
│     NO → Fix SDK code, goto 1                           │
│                    ↓                                    │
│  4. Check kpiData numeric (not strings)?                │
│     NO → Fix formula: olakai kpis update ID --formula   │
│          goto 1                                         │
│                    ↓                                    │
│  5. Check kpiData not null?                             │
│     NO → Create CustomDataConfig or fix field name      │
│          goto 1                                         │
│                    ↓                                    │
│  ✅ All validations pass - implementation complete      │
└─────────────────────────────────────────────────────────┘
```

### 4.5 Example Validation Session

```bash
# 1. Run your agent (generates event)
$ node my-agent.js "Test task"
Agent completed successfully

# 2. Get the latest event
$ olakai activity list --agent-id cmkxxx --limit 1 --json | jq '.prompts[0].id'
"cmkeyyy"

# 3. Inspect the event
$ olakai activity get cmkeyyy --json | jq '{customData, kpiData}'
{
  "customData": {
    "stepCount": 3,
    "itemsProcessed": 5,
    "successRate": 1
  },
  "kpiData": {
    "Steps Executed": 3,        # ✅ Numeric
    "Items Processed": 5,       # ✅ Numeric
    "Success Rate": 100         # ✅ Numeric (formula: successRate * 100)
  }
}

# ✅ All good! Implementation is correct.
```

## Step 5: Production Checklist

Before deploying to production:

- [ ] API key stored securely in environment variables
- [ ] Error handling wraps all LLM calls
- [ ] Failed executions still report events (with successRate: 0)
- [ ] All custom data fields have corresponding CustomDataConfig entries
- [ ] KPI formulas validated and showing numeric values (not strings)
- [ ] SDK configured with appropriate retries and timeouts
- [ ] Sensitive data redaction enabled if needed

## Task Categories Reference

Use these predefined task categories for the `task` field:

| Category | Example Subtasks |
|----------|------------------|
| Research & Intelligence | competitive intelligence, market research, legal research |
| Data Processing & Analysis | data extraction, statistical analysis, trend identification |
| Content Development | blog writing, technical documentation, proposal writing |
| Content Refinement | editing, proofreading, grammar correction |
| Customer Experience | complaint resolution, ticket triage, FAQ development |
| Software Development | code generation, code review, debugging |
| Strategic Planning | roadmap development, scenario planning |

## Quick Reference

```bash
# CLI Commands
olakai login                           # Authenticate
olakai agents create --name "Name"     # Create agent
olakai custom-data create --name X --type NUMBER  # Create custom field
olakai kpis create --formula "X" --agent-id ID    # Create KPI
olakai activity list --agent-id ID     # View events

# SDK Initialization (TypeScript)
const olakai = new OlakaiSDK({ apiKey: process.env.OLAKAI_API_KEY });
await olakai.init();
const openai = olakai.wrap(new OpenAI({ apiKey }), { provider: "openai" });

# SDK Initialization (Python)
olakai_config(os.getenv("OLAKAI_API_KEY"))
instrument_openai()
```
