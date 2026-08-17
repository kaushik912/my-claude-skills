---
name: setup-cron-readme-gen
description: Setup automated daily cron job to generate README.md with Claude
triggers:
  - "setup cron readme"
  - "install cron job"
  - "auto readme gen"
---

# Setup Cron README Generator

Help user install an automated cron job that generates README.md daily using Claude.

## Workflow

1. **Ask repo directory**: Prompt user for the repository path where they want to install this.

2. **Validate repo**: Check the path exists and has `.git` directory.

3. **Setup cron**: Ask user for:
   - What time daily (default: 3 PM IST = 15:00)
   - What timezone they're in
   - Confirm cron expression in their timezone

4. **Install cron**: Add to crontab pointing to central script:
   - Central script: `/home/kaush/.claude/setup-cron-docgen/update-readme.sh`
   - Call with repo path argument: `0 15 * * * /home/kaush/.claude/setup-cron-docgen/update-readme.sh /path/to/repo`

6. **Test**: Run script manually to verify it works.

7. **Done**: Show logs location and next run time.

## Key Points

- Script auto-detects main/master branch for production safety
- Uses git worktrees (Claude default) for isolation
- Auto-commits with message: `docs: auto-generate README.md`
- Logs all executions to `.claude/readme-gen.log`
- Cron runs unattended, safe from code corruption

## Implementation Notes

- Script location: `/home/kaush/.claude/setup-cron-docgen/update-readme.sh`
- Script accepts repo path as argument: `./update-readme.sh /path/to/repo`
- Cron entry format: `0 15 * * * /home/kaush/.claude/setup-cron-docgen/update-readme.sh /path/to/repo`
- Handle timezone conversion for cron times
- Validate git config exists before setting up
- Provide troubleshooting info if issues arise
- Single central script for all repos = easy maintenance
