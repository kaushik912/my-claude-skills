---
name: api-regression-guard
description: End-to-end workflow for API regression coverage — brainstorms neat test scenarios for a repo's API interactively (category by category), implements a confirmed one as a documented Bruno `.bru` regression test with a cross-checkable scenario ID, and adds a `make regressions` target to run the collection on demand. Framework-agnostic, no dependency beyond `npx @usebruno/cli`. Use when the user wants to "brainstorm test scenarios" for an API, "grill me on the API", find "what could go wrong" with an endpoint, "implement this scenario as a bruno test", "add a regression test for X", "turn this into a .bru test", or wire up "make regressions" / an on-demand regression-test run target.
---

# API Regression Guard

Take a repo from "no regression coverage" to "one `make` command runs a real
regression suite," in three phases run in order: **Discuss** scenarios worth
testing → **Implement** a confirmed one as a `.bru` test → **Run** it on
demand via a Makefile target. Each phase can also be entered on its own
(e.g. the collection already exists, just add the Makefile target).

Two reference files hold the mechanics that don't change per-run — read them
when the step below points at them:
- `references/scenario-checklist.md` — the angles to consider in Phase 1
  step 4.
- `references/bru-authoring.md` — the `docs/api-scenarios.md` table format,
  ID scheme, collection layout, and `.bru` file shape/naming used in Phase 1
  step 6 and Phase 2 steps 1 & 3.

## Phase 1 — Discuss: brainstorm scenarios

Goal: find scenarios worth testing, one reviewable batch at a time. Never
dump the whole API surface at once.

1. **Resolve the target repo.** Use the path from the prompt, else the
   current directory. Confirm it looks like an API project (controllers,
   routes, handlers, RPC/tool defs near the root). If ambiguous, ask.

   **Check for prior progress first.** Look for `docs/api-scenarios.md` in
   the target repo. If it exists, read it and report what's already there —
   which categories have been explored, and which scenarios are still
   `not yet tested` vs `implemented in <path>.bru`. Offer to pick up a
   `not yet tested` row (skip straight to Phase 2) or explore a new
   category (continue below).

2. **Scan the API — facts only, never ask the user for this.** For each
   endpoint, note: method + path, inputs and their validation, auth guards,
   and failure paths (what gets thrown/returned, and the status it maps to).
   Framework-agnostic — look for the *kind* of signal (validation
   attributes, custom exceptions, status annotations), not one framework's
   exact syntax. Also skim root-level docs (`README*`, `API.md`, `docs/`)
   for worked curl/example walkthroughs, and any `.bru` tests already in the
   repo, so you don't re-suggest what's covered.

3. **Propose categories.** Group endpoints by resource/module — usually
   falls out of the scan (same controller/route file, same URL prefix).
   Present a short numbered list and ask which to explore. Always do this —
   never jump straight to scenarios for the whole API.

4. **Show up to 8 scenarios for the chosen category**, plain English, happy
   path first (for orientation), then the edge cases that matter most. See
   `references/scenario-checklist.md` for the angles to consider — skip
   whichever don't apply. Skip anything already covered by an existing
   `.bru` test, noting it instead of re-listing it. Cap at 8; if more
   genuinely apply, keep what matters most (money/data-safety and
   undocumented/ambiguous behavior outrank routine checks) and say how many
   were left out. One line per scenario on why it matters, flagging
   anything that's a guess about intended behavior rather than confirmed
   from code/docs.

5. **Confirm.** Ask the user to drop, edit, or approve the list — nothing
   gets written until they've confirmed.

6. **Persist the confirmed list to `docs/api-scenarios.md`** in the target
   repo — this is what makes it safe to drop off and resume later, in a
   different session. Use the table format and `SCN-<NNN>` ID scheme in
   `references/bru-authoring.md`. Do this **before** moving on, regardless
   of whether the user wants to implement one right away or stop here — the
   list must never exist only in the conversation.

   Then ask whether to implement one of these now (Phase 2) or stop for now.

## Phase 2 — Implement: scenario → `.bru` test

Goal: turn one confirmed scenario into a working, documented Bruno test.

0. **Resolve which scenario.** Either the one just picked at the end of
   Phase 1, or — entering Phase 2 directly in a fresh session — read
   `docs/api-scenarios.md`, show the `not yet tested` rows with their IDs,
   and ask which to implement. If that file doesn't exist and no scenario
   was described, say so and offer to run Phase 1 first rather than
   inventing one.

   **Ad hoc scenario with no doc row yet**: add it to
   `docs/api-scenarios.md` first (same ID rule as Phase 1 step 6) *before*
   drafting the `.bru` file — every implemented test needs a row with the
   same ID. Skip this only for the bug-fix handoff from
   `regression-testing`, which doesn't use `docs/api-scenarios.md`.

1. **Find or create the collection.** Look for an existing Bruno collection
   in the repo (a directory with `bruno.json`). If none exists, scaffold one
   at `regressions/` — confirm with the user first. See
   `references/bru-authoring.md` for the exact layout and file contents
   (check the project's real configured port before defaulting to 8080).

2. **Dedup check.** Grep the collection (filenames, `meta{}`, `tests{}`,
   `docs{}`) for a test already covering this endpoint + condition. If one
   exists, say so and offer to extend it instead of duplicating.

3. **Draft the `.bru` file.** See `references/bru-authoring.md` for the
   exact request shape, naming (`<ID>-<slug>.bru`, or the bug-fix
   `BUG-<id>-<slug>.bru` exception), and `docs{}` format. The `docs{}` block
   is mandatory on every test — plain English, no jargon, no code.

4. **Confirm before writing.** Show the full drafted file and ask the user
   to approve, edit, or drop it. **Never write it silently.**

5. **Write it, then update `docs/api-scenarios.md`**: change this
   scenario's Status from `not yet tested` to `implemented in <path>.bru` —
   leave every other row untouched. This keeps the doc and the collection in
   sync, so a later resume never re-derives or re-implements the same
   scenario.

6. Ask if they want to implement another `not yet tested` row now, or move
   on to Phase 3.

## Phase 3 — Run: Makefile target

Goal: the collection can be run on demand, locally, against a running local
instance, with one command — no git hook, no CI wiring.

Precondition: the collection from Phase 2 must exist with at least one
test. If it doesn't, say so and offer to run Phase 2 first.

1. **Check for an existing `regressions` target.** If the project already
   has a `Makefile` with a `regressions` (or equivalently-named) target,
   show it and ask before changing it rather than adding a duplicate.

2. **Add the target.** Confirm with the user before creating or editing the
   `Makefile` — framework-agnostic, no build-tool-specific wiring:

   ```makefile
   .PHONY: regressions
   regressions:
   	npx --yes @usebruno/cli run regressions/ --env local --recursive \
   		--output regressions-results.xml --format junit
   ```

   Use the real collection directory name from Phase 2 step 1 if it's not
   literally `regressions`. `npx --yes` avoids needing a global `bru`
   install on any dev machine.

3. **Tell the user how to use it**: `make regressions` (the app must
   already be running locally at the `baseUrl` from
   `environments/local.bru`). Suggest pinning `@usebruno/cli` to a specific
   version once they've settled on one, so `npx` doesn't drift on "latest."

## Guidelines

- Never write a `.bru` file, scaffold a collection, or create/edit a
  Makefile without asking first.
- Always write confirmed Phase 1 scenarios to `docs/api-scenarios.md`
  before the turn ends, even if the user stops without implementing any of
  them — it's the only thing that makes a drop-off resumable later.
- Never show more than 8 scenarios in one batch in Phase 1.
- Plain English in every `docs{}` block — no framework/library jargon.
- Every proactive scenario's ID is the same in three places: the `ID`
  column in `docs/api-scenarios.md`, the `.bru` filename, and its `docs{}`
  block's `Scenario ID:` line. Never let these drift apart.
- Each phase can be entered directly if the earlier ones are already done
  (e.g. a collection already exists — skip straight to Phase 2 or 3).
