# Scenario Checklist

Angles to consider per endpoint when building candidate scenarios in
Phase 1. Not every angle applies to every endpoint — skip what doesn't fit.

| Angle | What to look for | Example question |
|---|---|---|
| Validation | required/optional fields, type/format/range constraints | What happens with a missing, blank, or wrong-type field? |
| Auth/authz | missing token, wrong role, expired credential | What happens with no token? With the wrong role? |
| Not found | references to something that doesn't exist | What happens fetching/acting on an ID that isn't there? |
| Conflict / idempotency | duplicate requests, replay, reused keys | Does calling it twice cause a duplicate side effect? |
| Lifecycle / state | action attempted in the wrong state | What happens cancelling something already cancelled? |
| Error mapping | which exception maps to which status/response | Does every thrown error map to a sensible status code? |
| Boundary values | empty lists, zero/negative numbers, max length, unicode | What happens at zero quantity? Negative price? |
| External dependency failure | downstream service down, slow, or returns garbage | What happens if the payment gateway times out? |
| Concurrency | two requests racing on the same resource | What happens if two requests hit this at once? |
