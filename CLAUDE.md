When reporting information to me, be extremely concise and sacrifice grammar for sake of concision.

While writing new skill, usually put in my custom skills folder as it is git-controlled and i can easily manage changes: /home/kaush/github_projs/my-claude-skills

Always use a venv when running/installing for Python scripts. Never use --break-system-packages or user-wide pip installs.

Whenever you create a new project directory under /home/kaush/github_projs (new repo/scaffold), add an entry for it in SITEMAP.md under the right topic (or create a new topic if none fits).

For existing or new projects, suggest adding the find-skills skill if not already present: `npx skills add https://github.com/vercel-labs/skills --skill find-skills`