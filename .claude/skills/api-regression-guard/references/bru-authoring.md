# Bru Authoring Reference

Detail for Phase 1 step 6 (persisting scenarios) and Phase 2 steps 1 & 3
(scaffolding the collection, drafting the `.bru` file).

## `docs/api-scenarios.md` table format

One `##` section per category explored so far (across all runs of this
skill), each with a table:

| ID | Scenario | Why it matters | Status |
|---|---|---|---|

**ID scheme**: assign each new row the next sequential `SCN-<NNN>`
(zero-padded, e.g. `SCN-001`, `SCN-002`) — scan the whole file for the
highest existing ID first, don't restart per category. IDs are permanent
once assigned: never renumber or reuse one, even if its scenario is later
dropped. This ID is the cross-check key between this doc and the `.bru`
file that implements it — the same ID appears in the `ID` column, the
`.bru` filename, and that file's `docs{}` block.

Status is `not yet tested` when just confirmed, `implemented in <path>.bru`
once Phase 2 writes the test. If the file already exists, update/append
only the current category's section — leave every other section untouched.

## Collection layout

```
regressions/
├── bruno.json
├── environments/
│   └── local.bru
└── <scenario files> ...
```

`bruno.json`:
```json
{ "version": "1", "name": "regressions", "type": "collection" }
```

`environments/local.bru` — check the project's actual configured port
(server config, README, docker-compose) before defaulting to 8080; a wrong
port fails every test with "connection refused," not a real signal about
the scenario:
```
vars {
  baseUrl: http://localhost:8080
}
```

## `.bru` file shape

```
meta {
  name: <short human name>
  type: http
  seq: <next number in the folder>
}

<method> {
  url: {{baseUrl}}<path>
  body: json
  auth: <none | bearer | inherit>
}

headers {
  Content-Type: application/json
}

body:json {
  { ...request payload... }
}

script:post-response {
  // only if a later request in this collection needs a value from this response
  if (res.status === <expected>) {
    bru.setVar("<name>", res.body.<field>);
  }
}

tests {
  test("<what this proves>", () => {
    expect(res.status).to.equal(<expected>);
  });
  // one or more further assertions on res.body as needed
}

docs {
  Scenario ID: <SCN-NNN — matches the row in docs/api-scenarios.md>
  Scenario: <what request this sends and under what conditions>
  Expected: <the correct behavior this test asserts>
}
```

The `docs{}` block is mandatory on every test — plain English, no jargon,
no code. It's what makes the collection double as a readable spec of how
the API is supposed to behave.

## Naming and `docs{}` format — two modes

**Proactive scenario** (from `docs/api-scenarios.md`, or ad hoc) — the
default shown above:
- Filename: `<ID>-<slug>.bru`, e.g. `SCN-004-checkout-conflict.bru`.
- `docs{}`: `Scenario ID:` / `Scenario:` / `Expected:`.

**Bug-fix test** (invoked from the `regression-testing` rule — no
`docs/api-scenarios.md` row, no ID):
- Filename: `BUG-<id-or-date>-<slug>.bru`, e.g.
  `BUG-JIRA-123-null-email-500.bru`.
- `docs{}`: no `Scenario ID:` line; `Scenario:` / `Before fix:` / `Now:`.

Everything else (collection scaffolding, dedup, request shape,
confirm-before-write) is identical either way.
