---
name: spec-agnostic
description: Spec-driven feature workflow (spec, then plan, then tasks, then TDD implement), resumable from where it dropped off. Agent-agnostic — no Claude-Code-only tool calls, safe to run under Claude Code, GitHub Copilot CLI, or any coding agent with file read/write and a shell.
disable-model-invocation: true
---

Runs any feature through four stages, each written to a file under `.spec/<slug>/` in the current repo: `spec.md` -> `plan.md` -> `tasks.md` -> implementation. Each artifact carries `status: draft` or `status: approved` in its frontmatter; `tasks.md` items are `- [ ]` / `- [x]`. That state is the only thing this skill trusts — never assume progress from memory of an earlier turn, always resume from what's on disk.

## Resume

On every invocation, before doing anything else, locate `.spec/*/` dirs and determine the slug (if only one exists, use it; if several, ask which; if none, this is a new feature — ask for a short feature name, slugify it, `mkdir -p .spec/<slug>`).

Then read that dir's files and jump to the first stage below that isn't done:

1. No `spec.md`, or `status: draft` -> **Spec** stage.
2. `spec.md` is `status: approved`, no `plan.md` or `plan.md` is `status: draft` -> **Plan** stage.
3. `plan.md` is `status: approved`, no `tasks.md` -> **Tasks** stage.
4. `tasks.md` exists with any `- [ ]` -> **Implement** stage, starting at the first unchecked item.
5. `tasks.md` exists, all `- [x]` -> feature is done; say so and stop.

State what stage you're resuming into and why (e.g. "plan.md is approved, tasks.md missing -> Tasks stage") before starting that stage's work.

## Stage: Spec

Interview the user about the feature: problem, goal, non-goals, acceptance criteria. Push on ambiguity until each acceptance criterion is testable. Write `.spec/<slug>/spec.md`:

```
---
status: draft
---
# <feature name>

## Problem
## Goal
## Non-goals
## Acceptance criteria
- ...
```

Show the drafted spec to the user. Do not flip `status` to `approved` until they explicitly approve it (e.g. "approved", "looks good", "ship it") — a read without objection is not approval. On approval, edit the frontmatter to `status: approved` and move to the Plan stage.

## Stage: Plan

Turn the approved spec into a technical plan: architecture, components touched, key decisions/tradeoffs, risks. Detect the stack from the repo (build files, existing code) before writing the plan, not after.

**Java Spring Boot projects** (`pom.xml`/`build.gradle` depends on `spring-boot`, or the user says so): scaffold and modify via the `spring` CLI (already installed — `spring init`, `spring add`, etc.) instead of hand-writing boilerplate the CLI generates.

**Testing seam**: ask the user which seam to test through, every time (no silent default). Give them this context before asking:

> A "seam" is the boundary your tests drive through. **Layered**: unit tests + slice tests (e.g. `@WebMvcTest`/`@DataJpaTest` in Spring) + integration tests, with mocking at layer boundaries — more tests, each narrower, faster feedback per layer. **Single seam**: one test type only, driving the outermost boundary end-to-end (e.g. HTTP via `MockMvc`/`WebTestClient`) through the real stack — real service, real repository, real DB via Testcontainers (or stack equivalent) — no mocking internal layers, no slice tests. Assertions land on HTTP status/response body/read-back state, never on internal calls or structure. Fewer, higher-confidence tests; less scaffolding; coarser failure signal.

Record the choice in `plan.md` under a `## Testing seam` section (state which, plus the concrete stack-specific tooling it implies, e.g. `MockMvc` + Testcontainers-Postgres for a Spring Boot project). Tasks stage reads this to shape test-first task pairs.

**API docs**: if the feature exposes a REST API, ask whether to generate OpenAPI/Swagger docs (default: yes for a new API, no for changes to an existing one that doesn't already have them). Pick the stack-appropriate tool — e.g. `springdoc-openapi-starter-webmvc-ui` for Spring Boot, FastAPI's built-in OpenAPI, `drf-spectacular` for Django REST Framework, `swagger-jsdoc` + `swagger-ui-express` for Express. Record the choice under a `## API docs` section in `plan.md` (tool + where the UI/spec will be served, e.g. `/swagger-ui.html` and `/v3/api-docs`). Tasks stage reads this to add a wiring task.

Write `.spec/<slug>/plan.md` with the same `status: draft` frontmatter convention. Get explicit approval the same way as Spec, then flip to `approved` and move to Tasks.

## Stage: Tasks

Break the approved plan into an ordered `.spec/<slug>/tasks.md` checklist, `status: draft` frontmatter, each item small enough to implement and verify in one pass:

```
- [ ] <task>
```

Wherever a task changes behavior (as opposed to pure config/scaffolding), order it as a test-first pair: a task to write the failing test, then a task to make it pass. Skip the pairing only for work with nothing to assert (e.g. `spring init` scaffolding, dependency bumps). Write the failing-test tasks to the seam recorded in `plan.md`'s `## Testing seam` section — under single seam, that means one full-stack test per behavior, not per layer.

If `plan.md` has a `## API docs` section recording a tool, add a wiring task (dependency + config) plus a test-first pair asserting the docs UI/spec endpoints are reachable (e.g. 200/3xx on `/swagger-ui.html` and `/v3/api-docs`), placed after the CRUD/behavior tasks it documents.

Always add a final non-test-first task: write a `Makefile` with a `test` target (or, if the stack has no Makefile convention, a `README.md` "Running tests" section) containing the literal, copy-pasteable command from `plan.md`'s `## Testing seam` tooling — e.g. `python3 -m unittest discover -s tests -v`, not just "run the unittest suite". This is the durable, on-disk record of how to verify the feature — don't rely on having said the command in chat.

Get explicit approval on the task list, flip to `approved`, then start Implement immediately on the first unchecked task.

## Stage: Implement

One task at a time, top to bottom. For any task with a paired failing-test task, follow red-green-refactor: write the failing test first; run it and confirm it fails for the expected reason (not a typo or setup error); write the minimal code to make it pass; run it and confirm green; then refactor if needed while keeping it green. For non-test-first tasks, just implement and verify (build/run as appropriate).

After a task passes, check its box in `tasks.md` immediately — don't batch checkbox updates, since a drop-off mid-batch is exactly what the resume logic needs to survive. Do not commit automatically; suggest a commit per completed task and let the user decide.

When the last box is checked, tell the user the feature is complete and point them at the Makefile/README test instructions from the last task, quoting the literal command.
