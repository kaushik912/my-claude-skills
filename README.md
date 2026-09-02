# my-claude-skills

Personal collection of coding-agent skills.

## Layout

- `.claude/skills/` — Claude Code specific (uses Claude-only tools/conventions, e.g. `EnterWorktree`, slash commands).
- `.agents/skills/` — agent agnostic (plain git/shell only; works with Claude Code, GitHub Copilot CLI, or any coding agent).

## Installing into another project

```
npx skills add https://github.com/kaushik912/my-claude-skills --skill <name> --agent <agent>
```

e.g. `npx skills add https://github.com/kaushik912/my-claude-skills --skill ticket-spec-agnostic --agent github-copilot`

Omitting `--agent` auto-detects agents installed on your machine (not the same as `--agent '*'`, which force-installs to every supported agent).

Local path also works: `npx skills add /path/to/my-claude-skills --skill <name>`. Use `-l` to list available skills first.
