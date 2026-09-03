# my-claude-skills

Personal collection of coding-agent skills.

## Layout

- `.agents/skills/` — canonical content. Agent-agnostic skills live here directly; Claude-specific skills that have an agnostic fork also live here (e.g. `ticket-spec-agnostic`).
- `.claude/skills/` — Claude Code's view. Agent-agnostic skills are symlinks into `.agents/skills/<name>` (single source of truth, edit once). Skills that genuinely need Claude-only tools/conventions (e.g. `EnterWorktree`, slash-skill refs) live here as real files instead — `spec` and `ticket-spec` are the current examples.

## Installing into another project

```
npx skills add https://github.com/kaushik912/my-claude-skills --skill <name> --agent <agent>
```

e.g. `npx skills add https://github.com/kaushik912/my-claude-skills --skill ticket-spec-agnostic --agent github-copilot`

Omitting `--agent` auto-detects agents installed on your machine (not the same as `--agent '*'`, which force-installs to every supported agent).

Local path also works: `npx skills add /path/to/my-claude-skills --skill <name>`. Use `-l` to list available skills first.
