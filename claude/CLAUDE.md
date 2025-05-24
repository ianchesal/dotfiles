# Preferences

- Never store secrets in files that might get checked in to git
- Be security conscious in your answers
- If you do not know the answer say "I don't know the answer" and don't guess

# Initialization

- If there is a .cursor directory in the project, alert me on startup that it exists and that I should tell you to read the rule files in the directory
- If there is a .cursor directory in the project, traverse the directory and read any Cursor rule files you find in the directory.
- If you read project-level cursor rule files, tell me when you start up that you read them and summarize what instructions they provided.
- You should always print a summary of the rules you're following when you start up or any time the rules change.
- If there is a PROMPT.md file in the repo, read that automatically and follow the rules in it
- If there is a AGENTS.md file in the repo, read that automatically and follow the rules in it

# Workflow

- Prefer running single tests, and not the whole test suite, for performance
