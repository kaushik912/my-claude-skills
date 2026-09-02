# Regression Testing for API Bug Fixes

When you finish fixing an API-related bug (any project, any language), remind the
user to add a Bruno regression test under `/regressions` — unless one already exists.
No file-type restriction: this is a judgment call about the change, not the file touched.

For proactively discovering test scenarios that aren't tied to a specific bug (and
as a learning guide to how the API is supposed to behave), use the
`api-regression-guard` skill's Phase 1 — its output at `docs/api-scenarios.md` is a
good place to check before drafting a new regression test here.

- **Counts as an API bug fix**: request/response handling, status codes, validation,
  auth/authz, endpoint business logic, error mapping, or contract issues (path/query
  params, schema) — where a client would now observe corrected behavior.
- **Doesn't count**: pure refactors, new features/endpoints, UI-only fixes, non-API
  internal changes, test/docs/perf-only changes.
- If unsure: "would a client calling this endpoint see different behavior now?" → yes
  means it applies.

**Drafting the test**: invoke the `api-regression-guard` skill's Phase 2 to do the
actual work — finding/scaffolding the `/regressions` collection, deduping against
existing tests, confirming content before writing. Override the skill's defaults
with these bug-fix-specific conventions instead:

- **Naming**: `regressions/BUG-<id-or-date>-<slug>.bru` (not the skill's default
  `<slug>.bru`), e.g. `regressions/BUG-JIRA-123-null-email-500.bru`.
- **`docs {}` format**: `Scenario` / `Before fix` / `Now` (not the skill's default
  `Scenario` / `Expected`) — plain English, no jargon/code:
  ```
  docs {
    Scenario: user signs up with an email already in use.
    Before fix: server 500'd. Now: 409 with a clear "email taken" message.
  }
  ```

If the user declines the test, drop it for this fix — don't create anything.

Everything else (collection layout, `bruno.json`/`environments/local.bru`
scaffolding, dedup check, confirm-before-write, the `make regressions` target) is
handled identically to `api-regression-guard`'s Phase 2/3 — no separate convention
to maintain here.
