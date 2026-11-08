---
name: worktree
description: Launch one or more tasks in new git worktrees, each opened as a herdr workspace with its own claude.
disable-model-invocation: true
allowed-tools: Bash, Write
---

Launch one or more tasks in new git worktrees. Each one becomes a herdr
workspace with a claude agent already working on its task.

Tasks: $ARGUMENTS

## Requires herdr

Run `test "${HERDR_ENV:-}" = 1` first. If it fails, tell the user this skill
needs a herdr session and stop.

## You are a dispatcher, not an implementer

**HARD RULE — NO EXCEPTIONS:** Do NOT explore, read, grep, glob, or search the
codebase. Do NOT use the Task/Explore agent. Do NOT investigate the problem. You
are a thin dispatcher: your ONLY job is to write prompt files and run the
dispatch script. The worktree agent does all the exploration and implementation.

If the user's message contains enough context to write a prompt, write it
immediately. If not, ask the user for clarification. Do NOT try to figure it out
by reading code.

If tasks reference earlier conversation (e.g., "do option 2"), include all
relevant context in each prompt you write.

If tasks reference a markdown file (e.g., a plan or spec), re-read the file to
make sure you have the latest version before writing prompts.

For each task:

1. Pick a short, descriptive branch name (2-4 words, kebab-case). It also names
   the worktree (`<repo>__worktrees/<branch>`) and the herdr agent.
2. Write a detailed implementation prompt to a temp file.
3. Dispatch it (see Workflow).

The prompt file should:

- Include the full task description
- Use RELATIVE paths only (never absolute paths: each worktree has its own root)
- Be specific about what the agent should accomplish

## Skill delegation

If the user passes a skill reference (e.g., `/auto`, `/plan-review`), the prompt
should tell the agent to use that skill instead of spelling out implementation
steps. Pass any flags through (`/auto --gemini`).

```
[Task description here]

Use the skill: /skill-name [flags if any] [task description]
```

## Flags

**`--merge`**: add an instruction to finish with the `/merge` skill:

```
...
Then use the /merge skill to commit, rebase, and merge the branch.
```

Only tell the worktree agent to `/merge` if the user explicitly asked for it.

**`--fork`**: herdr cannot copy this conversation into the new agent (a claude
session can't be resumed from another directory). Tell the user so, then put
the conversation context the agent needs into the prompt file verbatim.

## Cross-project dispatch

If a task targets another repository, run the dispatch with that repository as
the working directory: `(cd <project-path> && BRANCH=... ~/.config/herdr/add-worktree.sh)`.
Use the project path the user gave or one already in the conversation; don't
explore it, and ask if it's unclear. herdr files the new workspace with that
repository's other workspaces.

If a task spans repositories, write one prompt and dispatch one worktree per
repository. Each prompt explains the cross-repo context and may name the other
repository by absolute path, but each agent changes only its own worktree unless
the user asks otherwise.

## Workflow

Write ALL prompt files first, THEN dispatch them all.

Step 1 - Write every prompt file (in parallel):

```bash
f=$(mktemp "${TMPDIR:-/tmp}/worktree-task.XXXXXX")
cat >"$f" <<'EOF'
Implement feature X...
EOF
echo "$f"
```

Step 2 - Dispatch each one from the CURRENT directory. Do NOT `cd` to the main
checkout: the new branch is cut from the branch checked out here, which also
becomes the branch `/merge` lands it on.

```bash
BRANCH=feature-x BASE="$(git branch --show-current)" PROMPT_FILE=/path/from/step1 NO_FOCUS=1 \
  ~/.config/herdr/add-worktree.sh </dev/null
```

On a detached HEAD, use `BASE="$(git rev-parse HEAD)"`. The script creates
`<repo>__worktrees/<branch>`, opens it as a herdr workspace without taking the
user's focus, starts claude with the prompt file as its first message, and
prints `agent <name> in pane <id>`.

If it reports that claude is waiting at a startup prompt (folder trust on a new
path), the task is queued behind it. Tell the user which workspace needs them to
accept it. Don't answer it yourself.

After dispatching, tell the user the branches and agent names you created.

**Remember:** your task is COMPLETE once the worktrees exist. Do NOT implement
anything yourself.
