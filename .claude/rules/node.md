---
paths:
  - "**/*.js"
  - "**/*.ts"
  - "**/*.jsx"
  - "**/*.tsx"
  - "**/package.json"
---

# Node

Always use the project's local Node version (via `nvm`/`.nvmrc`/`.node-version` if present) when running/installing. Never install packages globally (`npm install -g`) — add them as project dependencies instead.
