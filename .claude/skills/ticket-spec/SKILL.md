---
name: ticket-spec
description: Non-interactive, resumable spec->plan->tasks->implement run driven by a YAML ticket file, isolated in a Claude Code worktree named after the ticket's feature. Companion to `spec`, for parallel worktree-based workflow testing (one ticket = one worktree = one independent run).
disable-model-invocation: true
---

Runs a single YAML ticket through the same four stages as the `spec` skill (spec -> plan -> tasks -> implement), inside a dedicated worktree named after the ticket's feature, writing to `.spec/<slug>/` there. Same resumable disk-state contract as `spec` — trust only what's on disk, never memory. Difference from `spec`: input is a ticket file, not an interview; the worktree is named deterministically from the ticket instead of randomly; and approval gates are skippable for unattended parallel runs.

Preferred launch is from the shell, one command per ticket: `claude -w <slug>` (creates `.claude/worktrees/<slug>/` on branch `worktree-<slug>` and starts the session already inside it), then `/ticket-spec tickets/<id>.yaml` in that session. If the skill is instead invoked from a session not already in the right worktree, it falls back to the in-session `EnterWorktree`/`ExitWorktree` tools to get there itself (see Stage: Worktree).

## Input

Invoked with a path to a ticket YAML, e.g. `/ticket-spec tickets/TICKET-001.yaml`. No path given -> look for exactly one `*.yaml` under `./tickets/`; several -> ask which.

**Given freeform text instead of a path** (e.g. `/ticket-spec build me a thing that does X, Y, Z`), and no unambiguous ticket YAML resolves per the rule above: this is a new ticket, not yet written — do not silently author one from assumptions. Interview the user first, same rigor as `spec`'s Spec stage (problem, goal, non-goals, acceptance criteria, pushing on ambiguity until each criterion is testable), plus the ticket-specific fields below that a real ticket author would otherwise have pinned down: stack choice (if the repo doesn't already dictate one), `testing_seam`, `api_docs`, and whether to run unattended (`auto_approve`). Only write `tickets/<slug>.yaml` once the user has confirmed those answers — then proceed to Bootstrap as normal. Skip the interview only when the freeform text already answers all of the above unambiguously (rare) or when a matching ticket YAML already exists.

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

`slug` is mandatory and does double duty: `.spec/<slug>/` dir name and the worktree/branch name. Pick it from the feature itself (what the ticket does), not the ticket id — e.g. `likes`, `search-filter`, `csv-export`. If a ticket omits it, derive one by slugifying `title` (lowercase, spaces/punctuation -> `-`) and write it back into the ticket file rather than inventing something unrelated to the feature. Must satisfy `EnterWorktree`'s `name` constraint: letters, digits, dots, underscores, dashes only.

## Stage: Worktree (before everything else)

Every invocation confirms it's in the right worktree first, before touching `.spec/`:

- **Already there**: if the cwd is `.claude/worktrees/<slug>` (or current branch is `worktree-<slug>`) — the normal case when launched via `claude -w <slug>` — do nothing, proceed straight to Resume.
- **Resuming from elsewhere**: if `.claude/worktrees/<slug>` exists but this session isn't in it (check `git worktree list`), call `EnterWorktree(path: ".claude/worktrees/<slug>")` to switch into it.
- **Starting fresh from elsewhere**: if no such worktree exists yet, call `EnterWorktree(name: <slug>)` — this both creates the worktree and names it after the feature, never leaving the name to autogenerate randomly.

All subsequent stages run with that worktree as the working directory.

## Resume

Identical convention to `spec`: `.spec/<slug>/{spec,plan,tasks}.md`, `status: draft|approved` frontmatter, `- [ ]`/`- [x]` tasks. On every invocation (after entering the worktree), check `.spec/<slug>/` and jump to the first undone stage per `spec`'s Resume rules — this is what makes a killed/restarted worktree run safe to just re-invoke.

## Stage: Bootstrap (replaces spec's interview)

If `.spec/<slug>/` doesn't exist: `mkdir -p .spec/<slug>`, write `spec.md` straight from the ticket's `problem`/`goal`/`non_goals`/`acceptance` fields, same section format as `spec`'s Spec stage. `status: approved` if `auto_approve: true`, else `status: draft` and stop for human approval exactly like `spec` does.

## Stage: Plan / Tasks / Implement

Read `../spec/SKILL.md` and follow its Plan, Tasks, and Implement stage instructions verbatim, with two overrides:

- **Skip interactive questions** the ticket already answers: use `testing_seam`/`api_docs` from the ticket directly in Plan; only ask if the ticket omits them.
- **Approval gates**: at each of `spec.md`/`plan.md`/`tasks.md` -> approved, if `auto_approve: true` flip status immediately and continue without waiting; if `false`, wait for explicit human approval same as `spec`.

Unlike `spec` (which leaves commits to the user), always commit after each task passes: `<ticket id>: <task>`. There's no downside — this is a local worktree branch nobody else is touching — and it's what gives the resumable checkpoint real teeth: a killed run leaves committed history, not just uncommitted working-tree state someone could lose with a stray `git checkout`/`clean`.

## Stage: Wrap-up

When `tasks.md` is all `[x]`, tell the user the feature is complete, report the worktree path and branch name, and quote the literal verify command from the Makefile/README written in the last task (per `spec`'s Tasks stage). Then call `ExitWorktree(action: "keep")` — never `"remove"`, since the point is to hand back a reviewable branch. Do not exit the worktree before then, and do not exit it on a mid-run failure either (leave it for the user to inspect/resume).

## Parallel worktree usage

No manual `git worktree add` — worktree lifecycle is driven by the `-w` flag (your manual per-ticket trigger) with `EnterWorktree`/`ExitWorktree` as the in-session fallback. The loop:

1. Author one YAML ticket per parallel feature under `tickets/`, each with a feature-descriptive `slug`.
2. Per ticket, in its own terminal: `claude -w <slug>`, then inside that session `/ticket-spec tickets/<id>.yaml`. Run as many of these side by side as tickets — that's the parallelism.
3. With `auto_approve: true`, each run goes unattended to completion or to a failure it can't resolve.
4. Because all state lives under `.spec/<slug>/` on that ticket's own worktree/branch, runs never cross-talk, and re-invoking after an interrupt (`claude -w <slug>` again, or `--continue`/`--resume` per Claude Code's usual session resume) just picks up where `tasks.md` left off.
5. Review and merge branches back manually once each reports done; then remove the worktree (`git worktree remove .claude/worktrees/<slug>`) once merged.
