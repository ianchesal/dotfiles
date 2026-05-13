# Claude Tool Configuration

Rake tasks for managing Claude Code installation. Install method uses the official
installer (`curl -fsSL https://claude.ai/install.sh | bash`), not Homebrew.
Key files: `claude.rake` (install/update/clean tasks), `CLAUDE.md` (this file).

# Workflow Management

## Communication Style
- **Before tool calls**: Tell the user what you're about to do in a single concise sentence
- **During execution**: Provide brief progress updates without asking for permission
- **After major steps**: Update the todo list and show progress
- **When blocked**: Explain the issue and ask for guidance

# Technical Preferences

## Security & Safety
- NEVER store secrets in files that might get checked in to git
- NEVER run commands with sudo
- Be security conscious in your answers
- If you do not know the answer say "I don't know the answer" and don't guess
- If you are running as the root user, stop and kill yourself

## Code Investigation
- Before deep root-cause analysis, run `git pull` (or confirm working tree is current) so the investigation isn't based on stale code
- When debugging hard-to-reproduce issues (e.g., post-sleep hangs, race conditions), explicitly state the hypothesis being tested and ask the user to verify the fix BEFORE moving to the next attempt—avoid stacking speculative fixes

## Editing Notes & Documents
- When the user provides a name, company, or proper noun, verify spelling against existing context (prior notes, calendar entries) before propagating it across a document
