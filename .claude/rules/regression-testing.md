# Regression Testing for API Bug Fixes

When you finish fixing an API-related bug (any project, any language), remind the
user to add a Bruno regression test under `/regressions` — unless one already exists.
No file-type restriction: this is a judgment call about the change, not the file touched.

- **Counts as an API bug fix**: request/response handling, status codes, validation,
  auth/authz, endpoint business logic, error mapping, or contract issues (path/query
  params, schema) — where a client would now observe corrected behavior.
- **Doesn't count**: pure refactors, new features/endpoints, UI-only fixes, non-API
  internal changes, test/docs/perf-only changes.
- If unsure: "would a client calling this endpoint see different behavior now?" → yes
  means it applies.

**Before proposing a new test**: check `/regressions` (project or module root) for an
existing `.bru` covering this bug — grep filenames/`meta{}`/`tests{}` for the endpoint,
method, or error condition. Reuse/extend it instead of duplicating.

**If no match exists**: draft the `.bru` content and ask the user before creating
anything — never write it silently. If they agree, create `/regressions` (plus
`bruno.json` and `environments/local.bru` below, if new) and the test file. If they
decline, drop it for this fix.

**Naming**: `regressions/BUG-<id-or-date>-<slug>.bru`, e.g.
`regressions/BUG-JIRA-123-null-email-500.bru`.

**Syntax**: use the `bruno` skill (`my-claude-skills:bruno`) for `.bru` format.

## Collection layout

```
regressions/
├── bruno.json
├── environments/
│   └── local.bru
└── BUG-<id-or-date>-<slug>.bru ...
```

`bruno.json`:
```json
{ "version": "1", "name": "regressions", "type": "collection" }
```

`environments/local.bru` (check `server.port`/config for the real local port before
defaulting to 8080 — a wrong port fails tests with "connection refused," not a real
signal about the bug):
```
vars {
  baseUrl: http://localhost:8080
}
```

## On-demand run target

Once `/regressions` exists, add a `Makefile` target so the collection can be run
on demand, locally, against a running local instance — unless the project already
has one. Confirm with the user before creating/editing the `Makefile`. Framework-
agnostic (Spring, Node, Python, Go, ...) — no build-tool-specific wiring, no CI
requirement.

Uses `npx --yes @usebruno/cli` rather than a global `bru` install, so no dev/CI
machine needs a standing global npm package.

```makefile
.PHONY: regressions
regressions:
	npx --yes @usebruno/cli run regressions/ --env local --recursive \
		--output regressions-results.xml --format junit
```

Local usage: `make regressions` (app must already be running locally). Pin
`@usebruno/cli` to a specific version once the team settles on one, to avoid `npx`
drifting on "latest."
