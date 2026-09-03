When reporting information to me, be extremely concise and sacrifice grammar for sake of concision.

While writing new skill, usually put in my custom skills folder as it is git-controlled and i can easily manage changes: /home/kaush/github_projs/my-claude-skills

Always use a venv when running/installing for Python scripts. Never use --break-system-packages or user-wide pip installs.

Whenever you create a new project directory under /home/kaush/github_projs (new repo/scaffold), add an entry for it in SITEMAP.md under the right topic (or create a new topic if none fits).

For existing or new projects, suggest adding the find-skills skill if not already present: `npx skills add https://github.com/vercel-labs/skills --skill find-skills`

For existing or new projects, also check if any of my own agents (my-claude-agents, install via `agent-porter install --agent <name>`, e.g. `agent-porter install --agent doc-writer`) or skills (my-claude-skills, install via `npx skills add https://github.com/kaushik912/my-claude-skills --skill <name>`, e.g. `npx skills add https://github.com/kaushik912/my-claude-skills --skill ticket-spec-agnostic`) would fit the task, and remind me to install them if not already present.

If a task requires Docker, stop and ask me first — I keep Docker off by default since it slows my PC.

For OpenRouter, always use `deepseek/deepseek-v4-flash-latest` in spring-ai projects or any AI project needing an API key.