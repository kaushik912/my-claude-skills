---
name: freemodelpicker
description: Recommends a working free-tier LLM (provider, model name, and a copy-pasteable snippet) for a given task type -- fast general chat, coding via API, agentic/CLI coding, long-context, or fully local/offline. Backed by curated, user-tested examples, not guesses. Use when the user asks "what free model should I use", wants a no-cost model for a task, or wants a working snippet to call a free-tier LLM API.
---

# Free Model Picker

Curated from working, user-tested examples in `code_public/myblog/technical/freeAI/`. Pick a row by task type, then use the referenced snippet as-is (just export the API key).

## Decision table

| Task type | Pick | Why | Setup | Snippet |
|---|---|---|---|---|
| Fast general chat / low latency | Groq `llama-3.3-70b-versatile` | Groq's LPU inference is very fast; generous free tier | `pip install groq`<br>`export GROQ_API_KEY=...` | `references/groq_chat.py` |
| General chat, don't care which model | OpenRouter `openrouter/free` | Auto-routes to whatever free model is currently up; zero curation | `export OPENROUTER_API_KEY=...` | `references/openrouter_free.py` (or `.sh` for streaming) |
| Coding help via plain API call (not an agent) | OpenRouter `cohere/north-mini-code:free` | User-noted "good for coding" | Same OpenRouter setup, swap `model` field | `references/openrouter_free.py` |
| Long context / big documents | Gemini `gemini-flash-lite-latest` (or `gemini-2.5-pro` for harder reasoning) | 1M-token context on the free API tier | `pip install google-genai`<br>`export GEMINI_API_KEY=...` | `references/gemini_free.py` |
| Agentic coding, best quality | opencode + Gemini 3.5 Flash Lite | User: "awesome" | install opencode, set Gemini as provider | `references/coding_agents.md` |
| Agentic coding, lightweight/low-memory | pi agent + Gemini 3.6 flash | pi is minimally bootstrapped, less RAM than opencode; pair with `npm:safe-coder` to block destructive file ops | install pi + `npm:safe-coder` | `references/coding_agents.md` |
| Agentic coding, fully offline / no API key | ollama `qwen2.5-coder:7b` | Confirmed workable on 16GB RAM for occasional use; pairs with opencode or pi as the local backend | `ollama pull qwen2.5-coder:7b` | `references/coding_agents.md` |
| Exploring the Claude-specific ecosystem | Claude Code + Haiku/Sonnet | Not free, but cheap/fast tier; only pick this if the goal is specifically Claude Code/Anthropic tooling | n/a | -- |

Secondary option: Mistral `mistral-large-latest` via `references/mistral.sh` -- has a free/trial tier but verify current limits at console.mistral.ai before relying on it; not otherwise validated in these notes.

## How to use this

1. Ask (or infer from context) which row fits: raw API call vs. agentic CLI coding, latency-sensitive vs. long-context, online vs. offline.
2. Hand back the model name + the matching reference snippet, with the required `export`.
3. For agentic rows, `references/coding_agents.md` has the full set of user-tested combos and caveats (e.g. `openrouter/free` hallucinated more with pi; always install `safe-coder` with pi to avoid unintended file deletion).

## Updating this skill

Source of truth is `~/github_projs/code_public/myblog/technical/freeAI/`. If new examples get added there (new provider, new model note), re-sync the relevant `references/*` file and the decision table row.
