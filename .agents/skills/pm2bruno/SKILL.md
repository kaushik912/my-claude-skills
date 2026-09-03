---
name: pm2bruno
description: Converts Postman's `pm.*` scripting API calls (pm.collectionVariables, pm.environment, pm.variables, pm.globals, pm.response, pm.request, pm.test, etc.) into Bruno's `bru`/`req`/`res` scripting API. Use this whenever a Bruno collection (.bru files or opencollection.yml/.yml files with `runtime.scripts` / pre-request / post-response / after-response blocks) still contains leftover `pm.*` code — most commonly right after importing a Postman collection with `bru import` or the Bruno desktop app, since neither reliably translates script bodies. Trigger on phrases like "fix this pm script for bruno", "convert postman variables to bruno", "this collection still has pm.* calls", or when a Bruno request errors with "pm is not defined".
---

# Postman → Bruno variable/script conversion

Bruno collections imported from Postman often carry over raw `pm.*` JavaScript in
`runtime.scripts` (or the `script:pre-request` / `script:post-response` blocks in
`.bru` files) because the importer converts requests/headers/URLs but doesn't
always rewrite script bodies. Bruno's sandbox has no `pm` global — leaving these
in place fails at runtime with `pm is not defined` or silently no-ops.

The fix is a mechanical substitution: find every `pm.*` call in scripts, replace
it with the Bruno equivalent below, and flag anything without a confident
equivalent instead of guessing.

## Where to look

- `.bru` files: `script:pre-request { ... }`, `script:post-response { ... }`, `tests { ... }`
- `opencollection.yml` / per-request `.yml` files (Bruno's newer YAML-based
  format, e.g. `bru import ... --collection-format opencollection`):
  `runtime.scripts[].code`, and the collection-level `request.scripts` block
- Collection-level scripts (in `opencollection.yml` or `collection.bru`) run
  before/after *every* request in the collection — check these too, not just
  individual request files.

Grep for the pattern first: `grep -rn "pm\." <collection-dir>`

## Confident mappings (apply directly)

| Postman | Bruno | Notes |
|---|---|---|
| `pm.collectionVariables.set(key, val)` | `bru.setVar(key, val)` | Bruno has one runtime-variable scope per collection run; no separate collection/environment distinction at the API level |
| `pm.collectionVariables.get(key)` | `bru.getVar(key)` | |
| `pm.collectionVariables.unset(key)` | `bru.deleteVar(key)` | |
| `pm.environment.set(key, val)` | `bru.setEnvVar(key, val)` | writes to the active Bruno environment |
| `pm.environment.get(key)` | `bru.getEnvVar(key)` | |
| `pm.environment.unset(key)` | `bru.deleteEnvVar(key)` | |
| `pm.variables.set(key, val)` | `bru.setVar(key, val)` | Postman's `pm.variables` is the highest-precedence read; on write, runtime var is the closest Bruno equivalent |
| `pm.variables.get(key)` | `bru.getVar(key)` — but if not set, fall back to `bru.getEnvVar(key)` | Postman's `pm.variables.get` reads across scopes; Bruno doesn't merge scopes automatically |
| `pm.request` | `req` | already in scope in Bruno scripts, e.g. `req.getUrl()`, `req.setUrl()`, `req.getHeader(name)`, `req.setHeader(name, val)`, `req.getBody()`, `req.setBody()` |
| `pm.response` | `res` | e.g. `res.getStatus()`, `res.getBody()`, `res.getHeader(name)`, `res.getResponseTime()` |
| `pm.response.json()` | `res.getBody()` | Bruno already parses JSON responses; no `.json()` call needed |
| `JSON.stringify(...)` / plain JS | unchanged | Bruno scripts are plain Node-ish JS — only the `pm` surface needs translating |

## Needs manual verification (don't guess — flag for the user)

These don't have a clean 1:1 Bruno equivalent, or the equivalent depends on the
Bruno version in use. Call these out explicitly rather than silently emitting
something that might be wrong:

- `pm.globals.get/set/unset` — global (cross-collection) variables; recent
  Bruno versions expose `bru.getGlobalEnvVar` / `bru.setGlobalEnvVar`, but
  confirm against the installed Bruno/CLI version before relying on it.
- `pm.test(name, fn)` / `pm.expect(...)` — Bruno's test blocks use a similar
  `test(name, fn)` + `expect(...)` (chai-style) global API, but it lives in a
  separate `tests { }` block (`.bru`) rather than inline in pre/post scripts —
  moving the code, not just renaming `pm`, may be required.
- `pm.sendRequest(...)` — no confirmed direct Bruno equivalent; check current
  Bruno docs before converting.
- `pm.cookies.*`, `pm.info.*` — no confirmed direct equivalent; flag for manual
  review.
- `pm.environment.has(key)` / `pm.collectionVariables.has(key)` — no `has()`
  helper in Bruno; use `!!bru.getEnvVar(key)` / `!!bru.getVar(key)` as an
  approximation, but note the falsy-value edge case (e.g. a var literally set
  to `"0"` or `false`) if it matters for the script's logic.

## Workflow

1. Grep the target collection directory for `pm\.` to find every occurrence.
2. For each match, apply the confident mapping above via a direct string edit —
   don't restructure surrounding code beyond the `pm.*` → `bru.*`/`req`/`res`
   substitution.
3. For anything in the "needs manual verification" list, don't silently
   translate it — call it out to the user with the file and line, and let them
   confirm the target API before changing it.
4. If a variable name being get/set contains characters that aren't valid
   Bruno double-brace identifiers (e.g. dots, like `service.token`), leave the
   name as-is since Bruno historically tolerates dotted names via existing
   collections, but mention it as worth a runtime smoke test — don't rename
   preemptively.
5. After editing, re-grep for `pm\.` in the same directory to confirm none
   were missed.
