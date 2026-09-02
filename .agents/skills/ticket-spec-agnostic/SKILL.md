---
name: ticket-spec-agnostic
description: Non-interactive, resumable spec->plan->tasks->implement run driven by a YAML ticket file, isolated in a plain `git worktree` named after the ticket's feature. Companion to `spec-agnostic`, for parallel worktree-based workflow testing (one ticket = one worktree = one independent run). Agent-agnostic — worktree lifecycle is plain git + shell, no Claude-Code-only tool calls, so it can be run under Claude Code, GitHub Copilot CLI, or any coding agent with file read/write and a shell.
disable-model-invocation: true
---

Runs a single YAML ticket through the same four stages as the `spec-agnostic` skill (spec -> plan -> tasks -> implement), inside a dedicated worktree named after the ticket's feature, writing to `.spec/<slug>/` there. Same resumable disk-state contract as `spec-agnostic` — trust only what's on disk, never memory. Difference from `spec-agnostic`: input is a ticket file, not an interview; the worktree is named deterministically from the ticket instead of randomly; and approval gates are skippable for unattended parallel runs.

Preferred launch is from the shell, one worktree per ticket:

```
git worktree add .agents/worktrees/<slug> -b worktree-<slug>
cd .agents/worktrees/<slug>
```

Then, inside that directory, invoke whichever coding agent you're using and point it at this skill plus `tickets/<id>.yaml` — via that agent's own invocation mechanism if it has one (a slash command, a custom-instructions file, a pasted prompt), or by just handing it this file's contents directly if it has no such mechanism. If the skill instead ends up being invoked from a session not already in the right worktree, it falls back to plain `git worktree` + `cd` to get there itself (see Stage: Worktree) — no special "enter worktree" tool is assumed to exist.

## Input

Invoked with a path to a ticket YAML, e.g. `tickets/TICKET-001.yaml`. No path given -> look for exactly one `*.yaml` under `./tickets/`; several -> ask which.

**Given freeform text instead of a path** (e.g. "build me a thing that does X, Y, Z"), and no unambiguous ticket YAML resolves per the rule above: this is a new ticket, not yet written — do not silently author one from assumptions. Interview the user first, same rigor as `spec-agnostic`'s Spec stage (problem, goal, non-goals, acceptance criteria, pushing on ambiguity until each criterion is testable), plus the ticket-specific fields below that a real ticket author would otherwise have pinned down: stack choice (if the repo doesn't already dictate one), `testing_seam`, `api_docs`, and whether to run unattended (`auto_approve`). Only write `tickets/<slug>.yaml` once the user has confirmed those answers — then proceed to Bootstrap as normal. Skip the interview only when the freeform text already answers all of the above unambiguously (rare) or when a matching ticket YAML already exists.

Ticket schema:

```yaml
id: TICKET-001
slug: likes              # kebab-case, feature-descriptive — becomes the worktree/branch name, never random
title: Like/unlike quotes
problem: |
  ...
goal: |
  ...
non_goals:
  - ...
acceptance:
  - ...
stack_notes: ...          # optional, feeds Plan stage
testing_seam: single      # layered | single — skips the interactive ask in Plan
api_docs: false           # true|false — skips the interactive ask in Plan
auto_approve: true        # true = flip status:approved at every gate, unattended
```

When authoring the ticket yourself from an interview (see freeform-input case above), default `auto_approve` to `false` unless the user explicitly asks for an unattended run — `true` is an opt-in for the parallel-worktree use case, not a default to assume on someone's behalf.

`slug` is mandatory and does double duty: `.spec/<slug>/` dir name and the worktree/branch name. Pick it from the feature itself (what the ticket does), not the ticket id — e.g. `likes`, `search-filter`, `csv-export`. If a ticket omits it, derive one by slugifying `title` (lowercase, spaces/punctuation -> `-`) and write it back into the ticket file rather than inventing something unrelated to the feature. Must be a valid git branch-name component and directory name: letters, digits, dots, underscores, dashes only.

## Stage: Worktree (before everything else)

Every invocation confirms it's in the right worktree first, before touching `.spec/`, using only plain `git` commands and the shell tool the executing agent already has — no special "enter/exit worktree" tool is assumed:

- **Already there**: if the cwd is under `.agents/worktrees/<slug>` (or the current branch is `worktree-<slug>`) — the normal case when launched via the shell steps above — do nothing, proceed straight to Resume.
- **Resuming from elsewhere**: if `.agents/worktrees/<slug>` exists but this session isn't cd'ed into it, run `git worktree list` to confirm, then `cd .agents/worktrees/<slug>`. This relies only on the shell tool's cwd persisting across commands within the session (true for Claude Code's Bash tool and equivalent shell tools in other agents) — not on any agent-specific worktree API.
- **Starting fresh from elsewhere**: if no such worktree exists yet, run `git worktree add .agents/worktrees/<slug> -b worktree-<slug>`, then `cd .agents/worktrees/<slug>`.
- If the repo's `.gitignore` doesn't already ignore `.agents/worktrees/`, add it — these are local working trees, not something to commit.

All subsequent stages run with that worktree as the working directory.

## Resume

Identical convention to `spec-agnostic`: `.spec/<slug>/{spec,plan,tasks}.md`, `status: draft|approved` frontmatter, `- [ ]`/`- [x]` tasks. On every invocation (after entering the worktree), check `.spec/<slug>/` and jump to the first undone stage per `spec-agnostic`'s Resume rules — this is what makes a killed/restarted worktree run safe to just re-invoke.

## Stage: Bootstrap (replaces spec's interview)

If `.spec/<slug>/` doesn't exist: `mkdir -p .spec/<slug>`, write `spec.md` straight from the ticket's `problem`/`goal`/`non_goals`/`acceptance` fields, same section format as `spec-agnostic`'s Spec stage. `status: approved` if `auto_approve: true`, else `status: draft` and stop for human approval exactly like `spec-agnostic` does.

## Stage: Plan / Tasks / Implement

Read `../spec-agnostic/SKILL.md` and follow its Plan, Tasks, and Implement stage instructions verbatim, with two overrides:

- **Skip interactive questions** the ticket already answers: use `testing_seam`/`api_docs` from the ticket directly in Plan; only ask if the ticket omits them.
- **Approval gates**: at each of `spec.md`/`plan.md`/`tasks.md` -> approved, if `auto_approve: true` flip status immediately and continue without waiting; if `false`, wait for explicit human approval same as `spec-agnostic`.

Unlike `spec-agnostic` (which leaves commits to the user), always commit after each task passes: `<ticket id>: <task>`. There's no downside — this is a local worktree branch nobody else is touching — and it's what gives the resumable checkpoint real teeth: a killed run leaves committed history, not just uncommitted working-tree state someone could lose with a stray `git checkout`/`clean`.

## Stage: Wrap-up

When `tasks.md` is all `[x]`, tell the user the feature is complete, report the worktree path and branch name, and quote the literal verify command from the Makefile/README written in the last task (per `spec-agnostic`'s Tasks stage). Leave the worktree exactly as it is — never run `git worktree remove` yourself, mid-run or on completion, since the whole point is to hand back a reviewable branch for the user to inspect, merge, and clean up on their own terms.

## Parallel worktree usage

Worktree lifecycle is plain `git worktree` commands run from the shell, no agent-specific flag or tool. The loop:

1. Author one YAML ticket per parallel feature under `tickets/`, each with a feature-descriptive `slug`.
2. Per ticket, in its own terminal:
   ```
   git worktree add .agents/worktrees/<slug> -b worktree-<slug>
   cd .agents/worktrees/<slug>
   ```
   then invoke your coding agent inside that directory with this skill and `tickets/<id>.yaml`. Run as many of these side by side as tickets — that's the parallelism. Different tickets can even use different agents (e.g. one worktree driven by Claude Code, another by GitHub Copilot CLI) since nothing here depends on a specific agent's tooling.
3. With `auto_approve: true`, each run goes unattended to completion or to a failure it can't resolve.
4. Because all state lives under `.spec/<slug>/` on that ticket's own worktree/branch, runs never cross-talk, and re-invoking after an interrupt is just: cd back into `.agents/worktrees/<slug>` and invoke your agent again — it resumes from `tasks.md` state on disk, the same disk-state contract that makes this agent-agnostic in the first place.
5. Review and merge branches back manually once each reports done; then remove the worktree (`git worktree remove .agents/worktrees/<slug>`) once merged.
