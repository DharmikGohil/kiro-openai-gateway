# Kiro Gateway API Reference

Base URL: **`https://kiro-claude-bypass.dharmikgohil.in`**

The gateway exposes two API formats on the same server. Use whichever your client library supports:

| Format | Endpoint | Works with |
|--------|----------|------------|
| OpenAI Chat Completions | `POST /v1/chat/completions` | OpenAI SDK, LangChain, Cursor, Continue, any "OpenAI-compatible" setting |
| Anthropic Messages | `POST /v1/messages` | Anthropic SDK, Claude Code |

All examples use `YOUR_API_KEY`. Replace it with the `PROXY_API_KEY` set in the Render environment.

---

## Contents

1. [Authentication](#1-authentication)
2. [Endpoints](#2-endpoints)
3. [Models](#3-models)
4. [OpenAI format: `/v1/chat/completions`](#4-openai-format-v1chatcompletions)
5. [Anthropic format: `/v1/messages`](#5-anthropic-format-v1messages)
6. [Errors](#6-errors)
7. [Client code examples](#7-client-code-examples)
8. [Behaviour notes](#8-behaviour-notes)

---

## 1. Authentication

Every `/v1/*` endpoint requires the API key. Send it in **one** of these headers:

```http
Authorization: Bearer YOUR_API_KEY
```
```http
x-api-key: YOUR_API_KEY
```

Both headers work on both endpoints. `/` and `/health` need no key.

---

## 2. Endpoints

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/` | No | Liveness check |
| GET | `/health` | No | Health check with timestamp |
| GET | `/v1/models` | Yes | List models available to the account |
| POST | `/v1/chat/completions` | Yes | Chat, OpenAI format |
| POST | `/v1/messages` | Yes | Chat, Anthropic format |
| GET | `/docs` | No | Interactive Swagger UI |

### `GET /`

```bash
curl https://kiro-claude-bypass.dharmikgohil.in/
```
```json
{"status": "ok", "message": "Kiro Gateway is running", "version": "2.4.dev.13"}
```

### `GET /health`

```bash
curl https://kiro-claude-bypass.dharmikgohil.in/health
```
```json
{"status": "healthy", "timestamp": "2026-11-17T04:48:04.974887+00:00", "version": "2.4.dev.13"}
```

### `GET /v1/models`

```bash
curl https://kiro-claude-bypass.dharmikgohil.in/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"
```
```json
{
  "object": "list",
  "data": [
    {
      "id": "auto-kiro",
      "object": "model",
      "created": 1794890909,
      "owned_by": "anthropic",
      "description": "Claude model via Kiro API"
    },
    {
      "id": "claude-haiku-4.5",
      "object": "model",
      "created": 1794890909,
      "owned_by": "anthropic",
      "description": "Claude model via Kiro API"
    }
  ]
}
```

(Shortened. The real list has every model in section 3.) `owned_by` and `description` are the same for every model, including non-Claude ones.

---

## 3. Models

Pass one of these IDs in the `model` field. All were tested on this account in November 2026.

| Model ID | Provider | Context | Good for |
|----------|----------|---------|----------|
| `auto-kiro` | Kiro router | — | Default choice, Kiro picks the model |
| `claude-opus-5.5` | Anthropic | 1M | Hardest coding and reasoning |
| `claude-sonnet-5.5` | Anthropic | 1M | Fast, strong general model |
| `claude-haiku-5.5` | Anthropic | 1M | Cheapest, high volume |
| `claude-opus-5`, `claude-opus-4.8`, `claude-opus-4.7`, `claude-opus-4.6` | Anthropic | 1M | Older Opus |
| `claude-opus-4.5` | Anthropic | 200K | Older Opus |
| `claude-sonnet-5`, `claude-sonnet-4.6` | Anthropic | 1M | Older Sonnet |
| `claude-sonnet-4.5` | Anthropic | 200K | Older Sonnet |
| `claude-haiku-4.5` | Anthropic | 200K | Older Haiku |
| `gpt-5.6-sol` | OpenAI | 1M | Long multi-step tasks |
| `gpt-5.6-terra` | OpenAI | 1M | Balanced |
| `gpt-5.6-luna` | OpenAI | 1M | Fast, cheap |
| `grok-4.7` | xAI | 500K | Experimental |
| `deepseek-3.2` | Open weight | 128K | Cheap, experimental |
| `minimax-m2.5`, `minimax-m2.1` | Open weight | 200K | Cheap |
| `glm-5` | Open weight | 200K | Large codebases |
| `qwen3-coder-next` | Open weight | 256K | Cheapest coding model |

**Name formats:** the gateway accepts common variants and converts them. These all reach `claude-sonnet-4.5`: `claude-sonnet-4-5`, `claude-sonnet-4.5`, `claude-sonnet-4-5-20250929`, `claude-4.5-sonnet-high`. A `[1m]` suffix is ignored.

**Unknown names** are forwarded to Kiro unchanged. If Kiro doesn't recognise one, you get the 400 error in section 6.

---

## 4. OpenAI format: `/v1/chat/completions`

### Request body

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | Yes | See section 3 |
| `messages` | array | Yes | `{"role": "system" \| "user" \| "assistant" \| "tool", "content": ...}` |
| `stream` | boolean | No | Default `false` |
| `tools` | array | No | OpenAI function tool definitions |
| `tool_choice` | string/object | No | Standard OpenAI values |
| `max_tokens` | integer | No | Upper limit on output length |
| `temperature`, `top_p` | number | No | Accepted for compatibility |

`content` can be a string, or an array of parts (`{"type":"text","text":"..."}`, `{"type":"image_url","image_url":{"url":"data:image/png;base64,..."}}`) for images.

### 4.1 Basic request

```bash
curl https://kiro-claude-bypass.dharmikgohil.in/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4.5",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Say hello in 3 words"}
    ]
  }'
```

Response:

```json
{
  "id": "chatcmpl-374e56b9a09b4640b539837aa1745f4b",
  "object": "chat.completion",
  "created": 1794890915,
  "model": "claude-sonnet-4.5",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello, I'm Kiro.",
        "reasoning_content": "\nThe user is asking me to say hello in exactly 3 words. ..."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {"prompt_tokens": 5074, "completion_tokens": 136, "total_tokens": 5210}
}
```

| Field | Meaning |
|-------|---------|
| `choices[0].message.content` | **The answer.** Read this. |
| `choices[0].message.reasoning_content` | The model's thinking. Extra field, safe to ignore. |
| `choices[0].finish_reason` | `stop` (done), `tool_calls` (wants a tool), `length` (hit `max_tokens`) |
| `usage` | Token counts. These are estimates from the gateway, not billing figures. |

### 4.2 Streaming

Add `"stream": true`. Use `curl -N` so output prints as it arrives.

```bash
curl -N https://kiro-claude-bypass.dharmikgohil.in/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4.5",
    "stream": true,
    "messages": [{"role": "user", "content": "Say hello in 3 words"}]
  }'
```

The response is Server-Sent Events (`Content-Type: text/event-stream`). Each line is `data: <json>`, and the stream ends with `data: [DONE]`:

```text
data: {"id": "chatcmpl-b6d7...", "object": "chat.completion.chunk", "created": 1794890917, "model": "claude-sonnet-4.5", "choices": [{"index": 0, "delta": {"role": "assistant", "reasoning_content": "\nThe user is ask"}, "finish_reason": null}]}
data: {"id": "chatcmpl-b6d7...", "object": "chat.completion.chunk", "created": 1794890917, "model": "claude-sonnet-4.5", "choices": [{"index": 0, "delta": {"reasoning_content": "ing me to say hello"}, "finish_reason": null}]}
...
data: {"id": "chatcmpl-b6d7...", "object": "chat.completion.chunk", "created": 1794890918, "model": "claude-sonnet-4.5", "choices": [{"index": 0, "delta": {"content": "Hey"}, "finish_reason": null}]}
data: {"id": "chatcmpl-b6d7...", "object": "chat.completion.chunk", "created": 1794890918, "model": "claude-sonnet-4.5", "choices": [{"index": 0, "delta": {"content": " there, friend."}, "finish_reason": null}]}
data: {"id": "chatcmpl-b6d7...", "object": "chat.completion.chunk", "created": 1794890918, "model": "claude-sonnet-4.5", "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}]}
data: [DONE]
```

To build the answer, join every `choices[0].delta.content`. Thinking chunks (`delta.reasoning_content`) come first. Skip them if you only want the answer.

### 4.3 Tool calling

```bash
curl https://kiro-claude-bypass.dharmikgohil.in/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4.5",
    "messages": [{"role": "user", "content": "What is the weather in London?"}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "get_weather",
        "description": "Get weather for a location",
        "parameters": {
          "type": "object",
          "properties": {"location": {"type": "string"}},
          "required": ["location"]
        }
      }
    }]
  }'
```

Response:

```json
{
  "id": "chatcmpl-31880d45f505409191e24efeefcf0973",
  "object": "chat.completion",
  "created": 1794890923,
  "model": "claude-sonnet-4.5",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "\n\nI'll check the weather in London for you.",
        "reasoning_content": "\nThe user is asking for the weather in London. ...",
        "tool_calls": [
          {
            "id": "tooluse_VMQJy5pmieEl2Bn9BnNWym",
            "type": "function",
            "function": {"name": "get_weather", "arguments": "{\"location\": \"London\"}"}
          }
        ]
      },
      "finish_reason": "tool_calls"
    }
  ],
  "usage": {"prompt_tokens": 5165, "completion_tokens": 89, "total_tokens": 5254}
}
```

`arguments` is a JSON **string**, so parse it. Run the tool yourself, then send the result back. Include the assistant message with its `tool_calls`, followed by a `tool` message with the same id:

```json
{
  "model": "claude-sonnet-4.5",
  "messages": [
    {"role": "user", "content": "What is the weather in London?"},
    {"role": "assistant", "content": "", "tool_calls": [
      {"id": "tooluse_VMQJy5pmieEl2Bn9BnNWym", "type": "function",
       "function": {"name": "get_weather", "arguments": "{\"location\": \"London\"}"}}
    ]},
    {"role": "tool", "tool_call_id": "tooluse_VMQJy5pmieEl2Bn9BnNWym", "content": "12°C, cloudy"}
  ],
  "tools": [ ...same tools as before... ]
}
```

### 4.4 Image input

```bash
curl https://kiro-claude-bypass.dharmikgohil.in/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4.5",
    "messages": [{"role": "user", "content": [
      {"type": "text", "text": "What is in this image?"},
      {"type": "image_url", "image_url": {"url": "data:image/png;base64,iVBORw0KGgo..."}}
    ]}]
  }'
```

Send images as base64 `data:` URLs.

---

## 5. Anthropic format: `/v1/messages`

### Request body

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | Yes | See section 3 |
| `max_tokens` | integer | Yes | Upper limit on output length |
| `messages` | array | Yes | `{"role": "user" \| "assistant", "content": ...}` |
| `system` | string/array | No | System prompt. Goes here, **not** in `messages` |
| `stream` | boolean | No | Default `false` |
| `tools` | array | No | Anthropic tool definitions (`name`, `description`, `input_schema`) |

Also send the `anthropic-version: 2023-06-01` header, as the Anthropic SDK does.

### 5.1 Basic request

```bash
curl https://kiro-claude-bypass.dharmikgohil.in/v1/messages \
  -H "x-api-key: YOUR_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4.5",
    "max_tokens": 1024,
    "system": "You are a helpful assistant.",
    "messages": [{"role": "user", "content": "Say hello in 3 words"}]
  }'
```

Response:

```json
{
  "id": "msg_3c6a3eaa7e97402d8a689910",
  "type": "message",
  "role": "assistant",
  "content": [
    {
      "type": "thinking",
      "thinking": "\nThe user is asking me to say hello in 3 words. ...",
      "signature": "sig_7679982163ee43bfa01a33213a9b6d32"
    },
    {
      "type": "text",
      "text": "Hi, I'm Kiro."
    }
  ],
  "model": "claude-sonnet-4.5",
  "stop_reason": "end_turn",
  "stop_sequence": null,
  "usage": {"input_tokens": 5075, "output_tokens": 140}
}
```

To get the answer, take the blocks in `content` where `type == "text"`. A `thinking` block usually comes first. `stop_reason` is `end_turn`, `tool_use`, or `max_tokens`.

### 5.2 Streaming

```bash
curl -N https://kiro-claude-bypass.dharmikgohil.in/v1/messages \
  -H "x-api-key: YOUR_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4.5",
    "max_tokens": 1024,
    "stream": true,
    "messages": [{"role": "user", "content": "Say hello in 3 words"}]
  }'
```

The stream uses standard Anthropic events. Each one is an `event:` line followed by a `data:` line:

```text
event: message_start
data: {"type": "message_start", "message": {"id": "msg_c85d...", "type": "message", "role": "assistant", "content": [], "model": "claude-sonnet-4.5", "stop_reason": null, "stop_sequence": null, "usage": {"input_tokens": 71, "output_tokens": 0}}}

event: content_block_start
data: {"type": "content_block_start", "index": 0, "content_block": {"type": "thinking", "thinking": "", "signature": "sig_e859..."}}

event: content_block_delta
data: {"type": "content_block_delta", "index": 0, "delta": {"type": "thinking_delta", "thinking": "\nThe user is asking me t"}}

event: content_block_stop
data: {"type": "content_block_stop", "index": 0}

event: content_block_start
data: {"type": "content_block_start", "index": 1, "content_block": {"type": "text", "text": ""}}

event: content_block_delta
data: {"type": "content_block_delta", "index": 1, "delta": {"type": "text_delta", "text": "Hey there, friend."}}

event: content_block_stop
data: {"type": "content_block_stop", "index": 1}

event: message_delta
data: {"type": "message_delta", "delta": {"stop_reason": "end_turn", "stop_sequence": null}, "usage": {"output_tokens": 188}}

event: message_stop
data: {"type": "message_stop"}
```

To build the answer, join the `delta.text` of every `text_delta` event. The stream is finished at `message_stop`.

### 5.3 Tool calling

```bash
curl https://kiro-claude-bypass.dharmikgohil.in/v1/messages \
  -H "x-api-key: YOUR_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4.5",
    "max_tokens": 1024,
    "messages": [{"role": "user", "content": "What is the weather in London?"}],
    "tools": [{
      "name": "get_weather",
      "description": "Get weather for a location",
      "input_schema": {
        "type": "object",
        "properties": {"location": {"type": "string"}},
        "required": ["location"]
      }
    }]
  }'
```

The response has `"stop_reason": "tool_use"` and a content block like this:

```json
{"type": "tool_use", "id": "tooluse_...", "name": "get_weather", "input": {"location": "London"}}
```

Here `input` is already an object, unlike the OpenAI format. To return the result, send a `user` message containing `{"type": "tool_result", "tool_use_id": "tooluse_...", "content": "12°C, cloudy"}`.

---

## 6. Errors

| HTTP | When | Body |
|------|------|------|
| 401 | Missing or wrong API key | `{"detail": "Invalid or missing API Key"}` |
| 400 | Model doesn't exist or isn't on the plan | `{"error": {"message": "Invalid model ID or insufficient subscription level to use it.", "type": "kiro_api_error", "code": 400}}` |
| 422 | Request body invalid (e.g. no `messages`) | `{"detail": [{"type": "missing", "loc": ["body", "messages"], "msg": "Field required", ...}]}` |
| 429 | Kiro rate limit | Error object. Retry after a short wait |
| 5xx | Kiro or network problem | Error object. Safe to retry |

Check the HTTP status first. On 429 and 5xx, retry with backoff, for example after 1s, 2s, then 4s.

---

## 7. Client code examples

### JavaScript / TypeScript (OpenAI SDK)

```ts
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: "https://kiro-claude-bypass.dharmikgohil.in/v1",
  apiKey: process.env.KIRO_GATEWAY_KEY,
});

const res = await client.chat.completions.create({
  model: "claude-sonnet-4.5",
  messages: [{ role: "user", content: "Hello!" }],
});
console.log(res.choices[0].message.content);

// Streaming
const stream = await client.chat.completions.create({
  model: "claude-sonnet-4.5",
  messages: [{ role: "user", content: "Hello!" }],
  stream: true,
});
for await (const chunk of stream) {
  process.stdout.write(chunk.choices[0]?.delta?.content ?? "");
}
```

### JavaScript (plain `fetch`, no SDK)

```js
const res = await fetch("https://kiro-claude-bypass.dharmikgohil.in/v1/chat/completions", {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${process.env.KIRO_GATEWAY_KEY}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    model: "claude-sonnet-4.5",
    messages: [{ role: "user", content: "Hello!" }],
  }),
});
if (!res.ok) throw new Error(`Gateway error ${res.status}: ${await res.text()}`);
const data = await res.json();
console.log(data.choices[0].message.content);
```

### Python (OpenAI SDK)

```python
import os
from openai import OpenAI

client = OpenAI(
    base_url="https://kiro-claude-bypass.dharmikgohil.in/v1",
    api_key=os.environ["KIRO_GATEWAY_KEY"],
)

res = client.chat.completions.create(
    model="claude-sonnet-4.5",
    messages=[{"role": "user", "content": "Hello!"}],
)
print(res.choices[0].message.content)
```

### Python (Anthropic SDK)

```python
import os
import anthropic

client = anthropic.Anthropic(
    base_url="https://kiro-claude-bypass.dharmikgohil.in",  # no /v1 here
    api_key=os.environ["KIRO_GATEWAY_KEY"],
)

msg = client.messages.create(
    model="claude-sonnet-4.5",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello!"}],
)
print("".join(b.text for b in msg.content if b.type == "text"))
```

### Base URL rules

| Client | Base URL |
|--------|----------|
| OpenAI SDK / OpenAI-compatible tools | `https://kiro-claude-bypass.dharmikgohil.in/v1` |
| Anthropic SDK / Claude Code | `https://kiro-claude-bypass.dharmikgohil.in` (the SDK adds `/v1/messages`) |

---

## 8. Behaviour notes

- **Cold start:** the service runs on Render's free plan. If it has been idle, the first request can take about 50 seconds. A keep-alive job pings `/health` every 10 minutes to prevent this. Set client timeouts to at least 120 seconds.
- **Thinking output:** responses include the model's reasoning (`reasoning_content` in the OpenAI format, `thinking` blocks in the Anthropic format). This is controlled on the server by `FAKE_REASONING` and `FAKE_REASONING_HANDLING`. Set `FAKE_REASONING=false` in Render to turn it off.
- **Identity:** models may introduce themselves as "Kiro", because Kiro adds its own system prompt upstream.
- **Token counts:** `usage` numbers are estimates and include Kiro's hidden system prompt, so even a tiny prompt shows thousands of input tokens.
- **No conversation state:** every request is independent. Send the full message history each time.
- **Keep the key server-side:** don't put `YOUR_API_KEY` in browser or mobile code. Anyone who has it can use your Kiro credits. Call the gateway from your own backend.
