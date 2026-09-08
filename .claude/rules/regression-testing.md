# Regression Testing for API Bug Fixes

When you finish fixing an API-related bug (any project, any language), ask the
user if they want a regression test for it — unless one already exists. No
file-type restriction: this is a judgment call about the change, not the file
touched.

For proactively discovering test scenarios that aren't tied to a specific bug
(and as a learning guide to how the API is supposed to behave), use the
`scenario-grill` agent instead — it's a broader, exploratory workflow with
its own `docs/api-scenarios.md` tracking, not part of this rule.

- **Counts as an API bug fix**: request/response handling, status codes, validation,
  auth/authz, endpoint business logic, error mapping, or contract issues (path/query
  params, schema) — where a client would now observe corrected behavior.
- **Doesn't count**: pure refactors, new features/endpoints, UI-only fixes, non-API
  internal changes, test/docs/perf-only changes.
- If unsure: "would a client calling this endpoint see different behavior now?" → yes
  means it applies.

## If the user confirms

1. **State the happy-path fix in plain English** — what a client sees now vs.
   before, no jargon.
2. **List up to 3 closely-related edge cases** worth covering alongside the main
   fix (e.g. a boundary just next to the one that was buggy, or the same error
   under a slightly different condition) — plain English, one line each on why
   it matters. Skip this if none genuinely apply; don't pad the list.
3. **Confirm** which of these to include, and whether to write it as a Bruno
   `.bru` test or a RestAssured test. Default by project language — Java/Spring
   project (pom.xml/build.gradle present) → RestAssured; otherwise → Bruno — but
   let the user override.
4. **Dedup check**: grep for a test already covering this endpoint + condition
   (Bruno: filenames, `meta{}`, `tests{}`, `docs{}`; RestAssured: test
   class/method names). If one exists, offer to extend it instead of
   duplicating.
5. **Draft the file**, show it in full, and confirm before writing. **Never
   write it silently.**

If the user declines, drop it for this fix — don't create anything.

## Bruno shape

Find or create the collection (a directory with `bruno.json`). If none exists,
scaffold one at `regressions/` — confirm with the user first, and check the
project's actual configured port (server config, README, docker-compose)
before defaulting to 8080:

```
regressions/
├── bruno.json          { "version": "1", "name": "regressions", "type": "collection" }
├── environments/
│   └── local.bru        vars { baseUrl: http://localhost:8080 }
└── BUG-<id-or-date>-<slug>.bru
```

Naming: `regressions/BUG-<id-or-date>-<slug>.bru`, e.g.
`regressions/BUG-JIRA-123-null-email-500.bru`. `docs{}` block — plain English,
no jargon/code, and a `Bug:` line with the id if available (else a short
description):

```
docs {
  Bug: <id, e.g. JIRA-123 — or a short description if no id>
  Scenario: user signs up with an email already in use.
  Before fix: server 500'd. Now: 409 with a clear "email taken" message.
}
```

## RestAssured shape

JUnit 5 + `io.rest-assured:rest-assured`, under the project's existing test
source root (e.g. `src/test/java/**/regression/`). Method named
`givenBugFixed_when<Action>_then<CorrectBehavior>` (BDD style, per
`testing-style.md`), with a one-line comment above it noting the bug id (if
available) or a short description, and `// Before fix:` / `// Now:` alongside
the usual `// Given` / `// When` / `// Then`:

```java
// Bug: JIRA-123 — or a short description if no id
@Test
void givenEmailAlreadyInUse_whenSignUp_thenReturns409() {
    // Given
    userRepository.save(new User("taken@example.com"));

    // When / Then
    // Before fix: server 500'd. Now: 409 with a clear "email taken" message.
    given()
        .contentType(ContentType.JSON)
        .body(new SignUpRequest("taken@example.com"))
    .when()
        .post("/signup")
    .then()
        .statusCode(409)
        .body("message", containsString("email"));
}
```

Runs via the project's existing test runner (`mvn test` / `./gradlew test`) —
no separate wiring needed.
