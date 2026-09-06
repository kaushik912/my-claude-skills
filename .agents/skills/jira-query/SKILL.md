---
name: jira-query
description: >-
  Use when the user asks about Jira issues/tickets/sprints — search, look up,
  create, or update (e.g. "find open tickets in ABC", "get issue ABC-123",
  "create a bug ticket"). Runs REST calls via jira.sh — no Atlassian MCP
  needed, just curl and a local credentials file.
license: MIT
compatibility: "Requires curl, jq; not tied to any MCP server"
metadata:
  author: kaushik912
  version: "1.0.0"
  category: development
  tags: ["jira", "atlassian", "cli", "rest"]
---
# Jira Query — Jira via CLI

## Overview

Call the Jira Cloud REST API straight from the CLI using `jira.sh`, without
an MCP server dependency. Credentials live in a local, gitignored `jira.cnf`
— never inline on the command line (avoids leaking the API token into shell
history / process listing).

This is not read-only — issue creation/updates are a normal use case.
There's no method guardrail beyond GET/POST/PUT/DELETE; be deliberate before
issuing a POST/PUT (creates/mutates real tickets).

## Setup

```bash
export JIRA_API_TOKEN="your_api_token"   # add to ~/.bashrc to persist
cp jira.cnf.example jira.cnf
# fill in JIRA_SITE / JIRA_EMAIL; JIRA_TOKEN already references JIRA_API_TOKEN
chmod 600 jira.cnf
echo "jira.cnf" >> .gitignore
chmod +x jira.sh
```

Get an API token at https://id.atlassian.com/manage-profile/security/api-tokens.

## Usage

`jira.cnf` is expected in the cwd. If it lives elsewhere, set
`JIRA_CNF=/path/to/jira.cnf`.

```bash
# Search issues (JQL)
./jira.sh GET "/rest/api/3/search?jql=project=ABC AND status=Open"

# Get one issue
./jira.sh GET "/rest/api/3/issue/ABC-123"

# Create an issue
./jira.sh POST "/rest/api/3/issue" \
  '{"fields":{"project":{"key":"ABC"},"summary":"Test","issuetype":{"name":"Task"}}}'
```

## Trimming output (raw responses are huge)

Jira JSON objects run 50+ fields deep. Always pipe through `jq` to cut tokens
before showing the user.

```bash
# Search results -> key/summary/status
./jira.sh GET "/rest/api/3/search?jql=project=ABC" \
  | jq '.issues[] | {key, summary: .fields.summary, status: .fields.status.name}'

# Single issue -> key/summary/status/assignee
./jira.sh GET "/rest/api/3/issue/ABC-123" \
  | jq '{key, summary: .fields.summary, status: .fields.status.name, assignee: .fields.assignee.displayName}'
```

## Rules

- Requires `jira.cnf` next to the script (or `JIRA_CNF` pointing at one) —
  never pass the token inline.
- `JIRA_TOKEN` in `jira.cnf` may reference an already-exported env var (e.g.
  `JIRA_TOKEN="$JIRA_API_TOKEN"`) instead of a raw literal — `jira.cnf` is
  bash-sourced, so this expands normally.
- GET is safe to run freely for lookups. POST/PUT/DELETE mutate real Jira
  tickets — confirm with the user before issuing one unless they've
  explicitly asked for the create/update/delete.
- Jira API docs: `/rest/api/3/*`.
- Pipe output through `jq` (see above) before showing the user — don't dump
  raw Jira JSON into chat.

## Troubleshooting

- `ERROR: config file not found` — no `jira.cnf` in cwd; create it from
  `jira.cnf.example` or set `JIRA_CNF`.
- `curl: command not found` / `jq: command not found` — install them
  (`apt install curl jq`, `brew install curl jq`, etc.).
- 401/403 from the API — check `JIRA_EMAIL`/`JIRA_TOKEN` in `jira.cnf`; token
  may be expired/revoked.
