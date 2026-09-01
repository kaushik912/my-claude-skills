---
name: api-grill
description: Explores a project's API (controllers/routes/handlers, validation, error mapping, existing docs, and existing Bruno tests) to find test scenarios worth writing. Presents a short menu of categories (endpoint groups) instead of dumping everything at once; once you pick one, shows up to 10 candidate scenarios for it, in plain English, for you to review and confirm. Writes confirmed scenarios to docs/api-scenarios.md, doubling as a learning guide (understand a system by what could go wrong) and a checklist feeding the project's Bruno regression-test workflow. Use when the user wants to find test scenarios for an API, wants to "grill me on the API", wants to understand what could go wrong with an endpoint, wants a test-case brainstorm before writing Bruno tests, or asks for an API scenarios/learning doc.
---

# API Grill

Find the test scenarios worth writing for a project's API, one reviewable
batch at a time. Never dump the whole API surface on the user at once —
propose categories, let them pick, show at most 10 scenarios for that
category.

## Steps

### 1. Resolve the target project

Use the path from the prompt if given, else the current directory. Confirm
it looks like an API project (controllers, routes, handlers, RPC/tool defs
within a couple directories of the root). If ambiguous, ask which
project/service.

### 2. Scan the API — facts only, never asks the user

For each endpoint: method + path, inputs and their validation, auth guards,
and failure paths (typed exceptions → status). Framework-agnostic — describe
the kind of signal to look for (validation attributes, custom errors, status
annotations), not one framework's syntax specifically.

Also read root-level docs (`README*`, `MANUAL_TEST*`, `API.md`, `docs/`) —
curl/example walkthroughs with an expected result are ready-made scenario
material, treat them as facts.

Also find any existing `.bru` tests (anywhere in the repo, not just
`/regressions`) and any existing `docs/api-scenarios.md`, and note what they
already cover — don't re-suggest it.

### 3. Propose categories

Group endpoints by resource/module (usually falls out of the scan — same
controller/route file, same URL prefix). Present a short numbered list (e.g.
"1. Add item to cart, 2. View cart, 3. Checkout flow, 4. Cancel order, 5.
View order") and ask which one to explore. Always do this — never skip
straight to scenarios for the whole API.

### 4. Show up to 10 scenarios for the chosen category

For the chosen category's endpoint(s), list candidate scenarios in plain
English: the happy path first (for orientation), then the edge cases that
matter. Use `references/scenario-checklist.md` as a prompt list of categories
to consider (validation, auth, not-found, conflict/idempotency, lifecycle,
boundary values, external-dependency failure, concurrency) — not every
category applies to every endpoint, skip what doesn't fit. Skip
anything already covered by an existing `.bru` test; note it as already
covered instead of re-listing it as a candidate.

Cap it at 10. If more than 10 genuinely apply, keep the 10 that matter most
(money/data-safety and anything undocumented or ambiguous outrank routine
validation/not-found checks) and say how many were left out — offer to show
the rest on request.

For each scenario, give one line on why it matters and, if the behavior
isn't already obvious from the code/docs, flag that it's a judgment call
worth double-checking rather than assuming.

### 5. Confirm

Ask the user to confirm the list — drop, edit, or add anything. Don't write
anything until they've confirmed.

### 6. Write `docs/api-scenarios.md`

In the **target project**. One `##` section per category explored so far
(across all runs) — endpoint(s), one-line description, then a table:
`Scenario | Why it matters | Status`, where status is `not yet tested`,
`covered by <path>.bru`, or `documented only, not automatable`. If the file
already exists, update only the section(s) for this run's category and leave
the rest alone. Plain English throughout — define any unavoidable technical
term inline the first time it's used.

### 7. Offer the next category

Once written, ask if they want to pick another category from the step-3
list.

## Guidelines

- Never ask the user something the code or docs already answer.
- Never show more than 10 scenarios in one go.
- Never write `.bru` files — this skill only identifies what's worth
  testing; turning a scenario into a `.bru` file is the `bruno` skill /
  `regression-testing` rule's job.
- Plain English always; technical words are fine if explained inline.

## Example

**ecommerce-checkout**: scan finds five categories — Add item to cart, View
cart, Checkout flow, Cancel order, View order. User picks **Checkout flow**.
Scenarios shown (happy path already covered by an existing `.bru`, so it's
noted, not counted against the cap): AUTH failure → 422, no order created;
CAPTURE failure → order kept as PAYMENT_FAILED, not rolled back; duplicate
checkout with the same idempotency key → same order both times; same key
reused on a different cart → 409; checkout on a cart that doesn't exist →
404. Five scenarios, all "not yet tested," each with a one-line reason —
under the cap, so nothing trimmed. User confirms, `docs/api-scenarios.md`
gets a "Checkout flow" section, and they're offered the next category.
