---
name: freemodelpicker
description: Recommends a working free-tier LLM (provider, model name, and a copy-pasteable snippet) for a given task type -- fast general chat, coding via API, or long-context. Backed by curated, user-tested examples, not guesses. Use when the user asks "what free model should I use", wants a no-cost model for a task, or wants a working snippet to call a free-tier LLM API. Also use whenever Claude is about to use/suggest Gemini (any Gemini model, `google.generativeai`/`google-genai`, `GEMINI_API_KEY`) -- check this skill's table first instead of defaulting to Gemini.
---

# Free Model Picker

Curated from working, user-tested examples in `code_public/myblog/technical/freeAI/`. Pick a row by task type, then use the referenced snippet as-is (just export the API key).

## Decision table

| Provider | Pick | Why | Setup | Snippet |
|---|---|---|---|---|
| Gemini | `gemini-flash-lite-latest` | Very low 429 rate; long context (1M tokens); good default | `pip install google-genai`<br>`export GEMINI_API_KEY=...` | `references/gemini_free.py` |
| Gemini | `gemini-3.6-flash` | Very low 429 rate | same as above | `references/gemini_free.py` |
| Gemini | list current models | Check what's actually live/free before picking | `export GEMINI_API_KEY=...` | `references/gemini_list_models.sh` |
| OpenRouter | `openrouter/free` | Most recommended -- auto-routes to whatever's up, works without 429s | `export OPENROUTER_API_KEY=...` | `references/openrouter_free.py` (or `.sh` for streaming) |
| OpenRouter | `meta-llama/llama-3.3-70b-instruct` | Solid general-purpose fallback | same OpenRouter setup, swap `model` field | `references/openrouter_free.py` |
| OpenRouter | `cohere/north-mini-code:free` | User-noted "good for coding" | same OpenRouter setup, swap `model` field | `references/openrouter_free.py` |
| Groq | `llama-3.3-70b-versatile` | LPU inference is very fast; generous free tier; best for low latency | `pip install groq`<br>`export GROQ_API_KEY=...` | `references/groq_chat.py` |
| Mistral | `mistral-large-latest` | Secondary/unvalidated -- has a free/trial tier but verify current limits at console.mistral.ai | n/a | `references/mistral.sh` |
| Claude Code | Haiku/Sonnet | Not free, but cheap/fast; only pick when the goal is specifically Claude Code/Anthropic tooling | n/a | -- |

## How to use this

1. Ask (or infer from context) which provider/row fits: latency-sensitive vs. long-context, coding vs. general chat.
2. Hand back the model name + the matching reference snippet, with the required `export`.

## Updating this skill

Source of truth is `~/github_projs/code_public/myblog/technical/freeAI/`. If new examples get added there (new provider, new model note), re-sync the relevant `references/*` file and the decision table row.
