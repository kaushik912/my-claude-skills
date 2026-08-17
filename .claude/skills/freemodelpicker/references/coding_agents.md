# Coding-agent + free-model combos (user-tested notes)

- opencode agent + bigpickle model (free) — pretty decent.
- opencode + Gemini 3.5 Flash Lite (Google) — awesome.
- opencode + DeepSeek V4 Flash — also good.

- pi agent + openrouter/free — okay, some hallucinations observed.
- pi agent + Gemini 3.6 flash — worked great.
- pi takes up less memory than opencode (minimally bootstrapped).
- pi: install `npm:safe-coder` — must-have, blocks unintended destructive ops (e.g. file deletion).

- ollama, paired with any of the above agents, is a solid local fallback.
- ollama/qwen2.5-coder:7b — okay for occasional use on 16GB RAM.

- claude code + haiku/sonnet — good for exploring the claude-specific ecosystem specifically (not "free" in the same sense, but cheap/fast tier).

- pi + herdr (tmux for AI agents) is a good combo for running pi in a terminal multiplexer.
