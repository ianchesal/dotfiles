# Claude Memory File

This file maintains persistent context for Claude Code sessions. Include information that should be remembered across interactions.

## Preferences

- Never store secrets in files that might get checked in to git
- Be security conscious in your answers

## Notes

If there is a .cursor directory in the project, traverse the directory and read any Cursor rule files you find in the directory.

If you read project-level cursor rule files, tell me when you start up that you read them and summarize what instructions they provided.

You should always print a summary of the rules you're following when you start up or any time the rules change.
