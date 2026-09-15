When reporting information to me, be extremely concise and sacrifice grammar for sake of concision.

While writing new skill, usually put in my custom skills folder as it is git-controlled and i can easily manage changes: /home/kaush/github_projs/my-claude-skills

Always use a venv when running/installing for Python scripts. Never use --break-system-packages or user-wide pip installs.

For existing or new projects, check if any of my own agents or skills would fit — refer to `agent-porter` for agents, or `npx skills add kaushik912/my-claude-skills` for skills — and remind me to install if missing.

If a task requires Docker, stop and ask me first — I keep Docker off by default since it slows my PC.

For OpenRouter, always use `deepseek/deepseek-v4-flash-latest` in spring-ai projects or any AI project needing an API key.

When adding any new MCP server: install to project space (`.mcp.json` via `-s project`), never user space, to avoid cluttering user config. Also add it to /home/kaush/github_projs/claude-code-tooling/mcp-init/mcp-registry.json so it's reusable via `mcp-init.py` (in PATH). If I want to add an MCP myself, suggest `mcp-init.py`.