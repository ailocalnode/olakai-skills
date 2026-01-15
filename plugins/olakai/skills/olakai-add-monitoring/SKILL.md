---
name: olakai-add-monitoring
description: Add Olakai monitoring to an existing AI agent. Use when you have working AI code that needs observability and analytics added.
---

# Add Olakai Monitoring to Existing Agent

This skill guides you through adding Olakai monitoring to an existing AI agent or LLM-powered application with minimal code changes.

For full SDK documentation, see: https://app.olakai.ai/llms.txt

## Prerequisites

- Existing working AI agent/application using OpenAI, Anthropic, or other LLM
- Olakai CLI installed and authenticated (`npm install -g olakai-cli && olakai login`)
- Olakai API key for your agent (get via CLI: `olakai agents get AGENT_ID --json | jq '.apiKey'`)
- Node.js 18+ (for TypeScript) or Python 3.7+ (for Python)

> **Note:** Each agent can have its own API key. Create one with `olakai agents create --name "Name" --with-api-key`

## Quick Start (5-Minute Integration)

### For TypeScript/JavaScript

**1. Install the SDK:**
```bash
npm install @olakai/sdk
```

**2. Wrap your existing client:**

Before:
```typescript
import OpenAI from "openai";
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
```

After:
```typescript
import OpenAI from "openai";
import { OlakaiSDK } from "@olakai/sdk";

const olakai = new OlakaiSDK({ apiKey: process.env.OLAKAI_API_KEY! });
await olakai.init();

const openai = olakai.wrap(
  new OpenAI({ apiKey: process.env.OPENAI_API_KEY }),
  { provider: "openai" }
);
```

**That's it!** All calls through `openai` are now automatically tracked.

### For Python

**1. Install the SDK:**
```bash
pip install olakai-sdk
```

**2. Add instrumentation:**

Before:
```python
from openai import OpenAI
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
```

After:
```python
from openai import OpenAI
from olakaisdk import olakai_config, instrument_openai

olakai_config(os.getenv("OLAKAI_API_KEY"))
instrument_openai()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
```

**That's it!** All calls through `client` are now automatically tracked.

---

## Detailed Integration Guide

### Step 1: Identify Your Integration Pattern

**Pattern A: Single LLM Client**
You have one OpenAI/Anthropic client used throughout your app.
→ Use the wrapped client approach (shown above)

**Pattern B: Multiple LLM Calls per Request**
Your agent makes several LLM calls to complete one task.
→ Use manual event tracking to aggregate calls

**Pattern C: Streaming Responses**
You stream LLM responses to users.
→ SDK handles this automatically; events sent after stream completes

**Pattern D: Third-Party LLM (not OpenAI/Anthropic)**
You use Perplexity, Groq, local models, etc.
→ Use manual event tracking via REST API or `olakai.event()`

### Step 2: Install and Configure

#### TypeScript Setup

```typescript
// lib/olakai.ts - Create a singleton
import { OlakaiSDK } from "@olakai/sdk";
import OpenAI from "openai";

let olakaiInstance: OlakaiSDK | null = null;
let wrappedOpenAI: OpenAI | null = null;

export async function getOlakaiClient(): Promise<OlakaiSDK> {
  if (!olakaiInstance) {
    olakaiInstance = new OlakaiSDK({
      apiKey: process.env.OLAKAI_API_KEY!,
      debug: process.env.NODE_ENV === "development",
      retries: 3,
      timeout: 30000,
    });
    await olakaiInstance.init();
  }
  return olakaiInstance;
}

export async function getOpenAI(): Promise<OpenAI> {
  if (!wrappedOpenAI) {
    const olakai = await getOlakaiClient();
    wrappedOpenAI = olakai.wrap(
      new OpenAI({ apiKey: process.env.OPENAI_API_KEY }),
      {
        provider: "openai",
        defaultContext: {
          task: "Software Development", // Default task category
        },
      }
    );
  }
  return wrappedOpenAI;
}
```

#### Python Setup

```python
# lib/olakai.py - Create initialization module
import os
from olakaisdk import olakai_config, instrument_openai

_initialized = False

def init_olakai():
    global _initialized
    if not _initialized:
        olakai_config(
            api_key=os.getenv("OLAKAI_API_KEY"),
            debug=os.getenv("DEBUG") == "true"
        )
        instrument_openai()
        _initialized = True

# Call at app startup
init_olakai()
```

### Step 3: Add Context to Calls

#### Adding User Information

TypeScript:
```typescript
const response = await openai.chat.completions.create(
  {
    model: "gpt-4o",
    messages: [{ role: "user", content: userMessage }],
  },
  {
    userEmail: user.email,        // Track by user
    chatId: conversationId,       // Group by conversation
    task: "Customer Experience",  // Categorize
  }
);
```

Python:
```python
from olakaisdk import olakai_context

with olakai_context(
    userEmail=user.email,
    chatId=conversation_id,
    task="Customer Experience"
):
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": user_message}]
    )
```

#### Adding Custom Data

TypeScript:
```typescript
const response = await openai.chat.completions.create(
  { model: "gpt-4o", messages },
  {
    userEmail: user.email,
    customData: {
      department: user.department,
      projectId: currentProject.id,
      isProduction: process.env.NODE_ENV === "production",
      priority: ticket.priority,
    },
  }
);
```

Python:
```python
with olakai_context(
    userEmail=user.email,
    customData={
        "department": user.department,
        "projectId": project.id,
        "priority": ticket.priority
    }
):
    response = client.chat.completions.create(...)
```

### Step 4: Handle Agentic Workflows

If your agent makes multiple LLM calls per task, aggregate them into a single event:

```typescript
async function processDocument(doc: Document): Promise<ProcessingResult> {
  const olakai = await getOlakaiClient();
  const openai = await getOpenAI();

  const startTime = Date.now();
  let totalTokens = 0;

  // Step 1: Extract
  const extraction = await openai.chat.completions.create({
    model: "gpt-4o",
    messages: [{ role: "user", content: `Extract from: ${doc.content}` }],
  });
  totalTokens += extraction.usage?.total_tokens ?? 0;

  // Step 2: Analyze
  const analysis = await openai.chat.completions.create({
    model: "gpt-4o",
    messages: [{ role: "user", content: `Analyze: ${extraction.choices[0].message.content}` }],
  });
  totalTokens += analysis.usage?.total_tokens ?? 0;

  // Step 3: Summarize
  const summary = await openai.chat.completions.create({
    model: "gpt-4o",
    messages: [{ role: "user", content: `Summarize: ${analysis.choices[0].message.content}` }],
  });
  totalTokens += summary.usage?.total_tokens ?? 0;

  const result = summary.choices[0].message.content ?? "";

  // Track the complete workflow as ONE event
  olakai.event({
    prompt: `Process document: ${doc.title}`,
    response: result,
    tokens: totalTokens,
    requestTime: Date.now() - startTime,
    task: "Data Processing & Analysis",
    customData: {
      documentId: doc.id,
      documentType: doc.type,
      stepCount: 3,
      success: true,
    },
  });

  return { summary: result, tokens: totalTokens };
}
```

### Step 5: Configure Platform (Optional but Recommended)

#### Install CLI
```bash
npm install -g olakai-cli
olakai login
```

#### Register Your Agent
```bash
# Create agent entry
olakai agents create --name "Document Processor" --description "Processes and summarizes documents"

# Note the agent ID returned
```

#### Create Custom Data Configs

For each custom field you send, create a config so KPIs can reference it:

```bash
olakai custom-data create --name "documentId" --type STRING
olakai custom-data create --name "documentType" --type STRING
olakai custom-data create --name "stepCount" --type NUMBER
olakai custom-data create --name "success" --type NUMBER  # Use 1/0 for boolean
```

#### Create KPIs
```bash
olakai kpis create \
  --name "Documents Processed" \
  --agent-id YOUR_AGENT_ID \
  --calculator-id formula \
  --formula "IF(success = 1, 1, 0)" \
  --aggregation SUM

olakai kpis create \
  --name "Avg Steps per Document" \
  --agent-id YOUR_AGENT_ID \
  --calculator-id formula \
  --formula "stepCount" \
  --aggregation AVERAGE
```

## Framework-Specific Integrations

### Next.js API Routes

```typescript
// app/api/chat/route.ts
import { NextRequest, NextResponse } from "next/server";
import { getOpenAI } from "@/lib/olakai";
import { auth } from "@/auth";

export async function POST(req: NextRequest) {
  const session = await auth();
  if (!session?.user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { message, conversationId } = await req.json();
  const openai = await getOpenAI();

  const response = await openai.chat.completions.create(
    {
      model: "gpt-4o",
      messages: [{ role: "user", content: message }],
    },
    {
      userEmail: session.user.email!,
      chatId: conversationId,
      task: "Customer Experience",
    }
  );

  return NextResponse.json({
    reply: response.choices[0].message.content,
  });
}
```

### Express.js

```typescript
// middleware/olakai.ts
import { getOlakaiClient, getOpenAI } from "../lib/olakai";

export async function initOlakai() {
  await getOlakaiClient();
  console.log("Olakai initialized");
}

// routes/chat.ts
import express from "express";
import { getOpenAI } from "../lib/olakai";

const router = express.Router();

router.post("/", async (req, res) => {
  const openai = await getOpenAI();
  const { message } = req.body;

  const response = await openai.chat.completions.create(
    { model: "gpt-4o", messages: [{ role: "user", content: message }] },
    { userEmail: req.user.email, chatId: req.body.conversationId }
  );

  res.json({ reply: response.choices[0].message.content });
});
```

### FastAPI (Python)

```python
# main.py
from fastapi import FastAPI, Depends
from openai import OpenAI
from olakaisdk import olakai_config, instrument_openai, olakai_context

app = FastAPI()

@app.on_event("startup")
async def startup():
    olakai_config(os.getenv("OLAKAI_API_KEY"))
    instrument_openai()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

@app.post("/chat")
async def chat(message: str, user: User = Depends(get_current_user)):
    with olakai_context(userEmail=user.email, task="Customer Support"):
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": message}]
        )
    return {"reply": response.choices[0].message.content}
```

## Handling Edge Cases

### Streaming Responses

The SDK automatically handles streaming. Events are sent after the stream completes:

```typescript
const stream = await openai.chat.completions.create(
  {
    model: "gpt-4o",
    messages: [{ role: "user", content: userMessage }],
    stream: true,
  },
  { userEmail: user.email }
);

for await (const chunk of stream) {
  // Stream to client
  res.write(chunk.choices[0]?.delta?.content ?? "");
}
// Event automatically sent here with full response
```

### Error Handling

Wrap calls to ensure errors are tracked:

```typescript
try {
  const response = await openai.chat.completions.create({
    model: "gpt-4o",
    messages,
  });
  return response.choices[0].message.content;
} catch (error) {
  // SDK still tracks the failed attempt
  // Optionally send explicit error event
  olakai.event({
    prompt: messages[messages.length - 1].content,
    response: `Error: ${error instanceof Error ? error.message : "Unknown"}`,
    task: "Software Development",
    customData: { error: true, errorType: error.name },
  });
  throw error;
}
```

### Non-OpenAI Providers

For Anthropic, Perplexity, or other providers, use manual tracking:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

async function callClaude(prompt: string): Promise<string> {
  const startTime = Date.now();

  const response = await anthropic.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 1024,
    messages: [{ role: "user", content: prompt }],
  });

  const content = response.content[0].type === "text" ? response.content[0].text : "";

  // Manual tracking for non-wrapped clients
  olakai.event({
    prompt,
    response: content,
    tokens: response.usage.input_tokens + response.usage.output_tokens,
    requestTime: Date.now() - startTime,
    task: "Content Development",
    customData: {
      provider: "anthropic",
      model: "claude-sonnet-4-20250514",
    },
  });

  return content;
}
```

## Test-Validate-Iterate Cycle

**CRITICAL:** Never assume your integration is working. Always validate by generating a test event and inspecting the actual data.

### Step 1: Generate a Test Event

Run your application to trigger at least one LLM call:

```bash
# For a web app, make a test request
curl -X POST http://localhost:3000/api/chat -d '{"message": "test"}'

# For a script, run it
node my-agent.js "test input"
python my_agent.py "test input"
```

### Step 2: Fetch and Inspect the Event

```bash
# Get the most recent event
olakai activity list --limit 1 --json

# Get full details (note the event ID from above)
olakai activity get EVENT_ID --json
```

### Step 3: Validate Each Component

**Check the event was received:**
```bash
olakai activity list --limit 1 --json | jq '.prompts[0] | {id, createdAt, app}'
```

If no event: Check API key, SDK initialization, and debug mode.

**Check customData is present:**
```bash
olakai activity get EVENT_ID --json | jq '.customData'
```

If missing or incomplete: Verify your SDK code passes `customData` correctly.

**Check KPIs are numeric (if configured):**
```bash
olakai activity get EVENT_ID --json | jq '.kpiData'
```

**CORRECT:**
```json
{ "My KPI": 42 }
```

**WRONG (formula stored as string):**
```json
{ "My KPI": "MyVariable" }
```

Fix with: `olakai kpis update KPI_ID --formula "MyVariable"`

**WRONG (null value):**
```json
{ "My KPI": null }
```

Fix by ensuring:
1. CustomDataConfig exists: `olakai custom-data create --name "MyVariable" --type NUMBER`
2. Field name case matches exactly (case-sensitive)
3. SDK actually sends the field in customData

### Step 4: Iterate Until Correct

```
┌────────────────────────────────────────────────────┐
│  1. Trigger LLM call (generate event)              │
│                    ↓                               │
│  2. Fetch: olakai activity get ID --json           │
│                    ↓                               │
│  3. Event exists?                                  │
│     NO → Check API key, SDK init, debug mode       │
│                    ↓                               │
│  4. customData correct?                            │
│     NO → Fix SDK customData parameter              │
│                    ↓                               │
│  5. kpiData numeric?                               │
│     NO → olakai kpis update ID --formula "X"       │
│                    ↓                               │
│  6. kpiData not null?                              │
│     NO → Create CustomDataConfig, check case       │
│                    ↓                               │
│  ✅ Integration validated                          │
└────────────────────────────────────────────────────┘
```

### Example Validation Session

```bash
# 1. Trigger a test call
$ curl -X POST localhost:3000/api/chat -d '{"message":"hello"}'
{"reply":"Hi there!"}

# 2. Fetch the event
$ olakai activity list --limit 1 --json | jq '.prompts[0].id'
"cmkeabc123"

# 3. Inspect it
$ olakai activity get cmkeabc123 --json | jq '{customData, kpiData}'
{
  "customData": {
    "userId": "user-123",
    "department": "Engineering"
  },
  "kpiData": {
    "Response Quality": 8.5
  }
}

# ✅ All values present and numeric - integration working!
```

## Common Integration Points

| Application Type | Integration Point | Recommended Approach |
|-----------------|-------------------|---------------------|
| API endpoint | Request handler | Wrap client, add user context |
| Background job | Job execution | Manual event at job completion |
| CLI tool | Command handler | Wrap client |
| Slack/Discord bot | Message handler | Wrap client, use chatId for threads |
| Scheduled task | Cron function | Manual event with workflow aggregation |

## Quick Reference

```typescript
// Wrap client (automatic tracking)
const openai = olakai.wrap(new OpenAI({ apiKey }), { provider: "openai" });

// Add context to calls
await openai.chat.completions.create(params, {
  userEmail: "user@example.com",
  chatId: "conversation-123",
  task: "Customer Experience",
  customData: { key: "value" }
});

// Manual event (for aggregation or non-OpenAI)
olakai.event({
  prompt: "input",
  response: "output",
  tokens: 1500,
  requestTime: 5000,
  task: "Data Processing & Analysis",
  customData: { workflowId: "abc" }
});
```

```python
# Auto-instrumentation
olakai_config(api_key)
instrument_openai()

# Context for calls
with olakai_context(userEmail="user@example.com", task="Support"):
    response = client.chat.completions.create(...)

# Manual event
olakai_event(OlakaiEventParams(
    prompt="input",
    response="output",
    tokens=1500,
    customData={"key": "value"}
))
```
