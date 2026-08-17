#!/bin/bash

# Universal README generator script
# Usage: ./update-readme.sh /path/to/repo [time]
# Time format: HH:MM (24-hour, optional - default 15:00 for 3 PM IST)

REPO_DIR="${1:-.}"
CRON_TIME="${2:-15:00}"
LOGFILE="$REPO_DIR/.claude/readme-gen.log"

cd "$REPO_DIR" || { echo "Error: Cannot access repo at $REPO_DIR"; exit 1; }

# Detect main branch (main or master)
MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
if [ "$MAIN_BRANCH" = "HEAD" ]; then
  MAIN_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  if git show-ref --verify --quiet refs/heads/main; then
    MAIN_BRANCH="main"
  elif git show-ref --verify --quiet refs/heads/master; then
    MAIN_BRANCH="master"
  fi
fi

# Checkout main branch
git checkout "$MAIN_BRANCH" || git checkout main || git checkout master

# Run Claude in background mode to generate README
claude --bg << 'PROMPT'
Analyze the Java project and generate a comprehensive README.md.

Include:
- Project title and description
- Prerequisites/requirements
- Directory structure overview
- How to build and run
- Key modules/components
- Any relevant configuration info

Look at pom.xml, src/ directory, and existing documentation.

Write the README to README.md in the project root. Be concise but informative.
PROMPT

# Wait for Claude to finish
sleep 3

# Find the most recently created README in worktrees
LATEST_README=$(find "$REPO_DIR/.claude/worktrees" -name "README.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

if [ -n "$LATEST_README" ] && [ -f "$LATEST_README" ]; then
  # Copy the generated README to project root
  cp "$LATEST_README" "$REPO_DIR/README.md"

  git add README.md

  # Check if there are changes to commit
  if git diff --cached --quiet; then
    echo "[$(date)] No changes to commit" >> "$LOGFILE"
  else
    git commit -m "docs: auto-generate README.md" >> "$LOGFILE" 2>&1
    echo "[$(date)] README.md updated and committed" >> "$LOGFILE"
  fi
else
  echo "[$(date)] README.md not created in worktree" >> "$LOGFILE"
fi
