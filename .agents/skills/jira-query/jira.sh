#!/usr/bin/env bash
# Jira REST caller. Usage:
#   ./jira.sh GET "/rest/api/3/search?jql=project=ABC"
#   ./jira.sh POST "/rest/api/3/issue" '{"fields":{...}}'
set -euo pipefail

CNF="${JIRA_CNF:-./jira.cnf}"

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <GET|POST|PUT|DELETE> \"<path>\" ['<json_body>']" >&2
    exit 1
fi

METHOD="$1"
PATH_Q="$2"
BODY="${3:-}"

if [[ ! "$METHOD" =~ ^(GET|POST|PUT|DELETE)$ ]]; then
    echo "ERROR: method must be GET/POST/PUT/DELETE (got: $METHOD)" >&2
    exit 1
fi

if [ ! -f "$CNF" ]; then
    echo "ERROR: config file not found: $CNF (set JIRA_CNF or create ./jira.cnf)" >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$CNF"

: "${JIRA_SITE:?JIRA_SITE not set in $CNF}"
: "${JIRA_EMAIL:?JIRA_EMAIL not set in $CNF}"
: "${JIRA_TOKEN:?JIRA_TOKEN not set in $CNF}"

AUTH=$(printf '%s' "${JIRA_EMAIL}:${JIRA_TOKEN}" | base64 -w0)

if [ -n "$BODY" ]; then
    curl -sS -X "$METHOD" \
        -H "Authorization: Basic ${AUTH}" \
        -H "Content-Type: application/json" \
        -d "$BODY" \
        "https://${JIRA_SITE}${PATH_Q}"
else
    curl -sS -X "$METHOD" \
        -H "Authorization: Basic ${AUTH}" \
        "https://${JIRA_SITE}${PATH_Q}"
fi
