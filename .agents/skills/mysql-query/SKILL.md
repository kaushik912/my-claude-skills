---
name: mysql-query
description: >-
  Use when the user asks to query, check, count, or look up data in a project's
  MySQL database (e.g. "how many users are active", "show me orders from last week",
  "check the db for...", "what tables exist"). Runs read-only SQL via dbq.sh —
  no MCP or DB driver needed, just the mysql CLI and a local credentials file.
license: MIT
compatibility: "Requires mysql CLI client installed; not for write/DDL operations"
metadata:
  author: kaushik912
  version: "1.0.0"
  category: development
  tags: ["mysql", "database", "sql", "cli", "read-only"]
---
# MySQL Query — Read-Only DB Access via CLI

## Overview

Query a project's MySQL database straight from the CLI using `dbq.sh`, without an
MCP server or DB driver dependency. Credentials live in a local, gitignored
`db.cnf` — never inline on the command line (avoids leaking passwords into shell
history / process listing).

Read-only by design: `dbq.sh` enforces SELECT/SHOW/DESCRIBE/EXPLAIN only, blocks
multi-statement queries, and auto-caps unbounded SELECTs at 50 rows.

## Usage

`db.cnf` is expected in the cwd. If it lives elsewhere, set `DBQ_CNF=/path/to/db.cnf`.

```bash
./dbq.sh "SELECT id, name FROM users WHERE active = 1"
./dbq.sh "SELECT COUNT(*) FROM orders WHERE status = 'pending'"
./dbq.sh "SHOW TABLES"
./dbq.sh "DESCRIBE users"
./dbq.sh "EXPLAIN SELECT * FROM orders WHERE user_id = 5"
```

## Rules

- Only SELECT / SHOW / DESCRIBE / DESC / EXPLAIN allowed — enforced by the script,
  not just a suggestion. Anything else (INSERT/UPDATE/DELETE/DDL) is rejected.
- Multi-statement queries (`;` followed by more SQL) are rejected — one statement
  per call.
- Unbounded SELECTs get `LIMIT 50` appended automatically (override with
  `DBQ_LIMIT=200 ./dbq.sh "..."`).
- Requires `db.cnf` next to the script (or `DBQ_CNF` pointing at one) — never pass
  `-u/-p` credentials inline.
- If the script errors "only read-only queries allowed", rephrase as a SELECT/SHOW
  instead of asking to modify data.
- This skill is intentionally read-only. If the task needs INSERT/UPDATE/DELETE,
  say so explicitly rather than trying to route it through `dbq.sh` — don't loosen
  the guardrail regex to make it fit.

## Troubleshooting

- `ERROR: config file not found` — no `db.cnf` in cwd; create it from
  `db.cnf.example` or set `DBQ_CNF`.
- `mysql: command not found` — install a MySQL client (`apt install mysql-client`,
  `brew install mysql-client`, etc.).
- Access denied — check `user`/`password`/`host`/`database` in `db.cnf`.
