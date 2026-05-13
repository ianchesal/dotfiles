# Morning Startup Preflight Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Step 0 preflight check to the morning-startup skill that probes all three MCP data sources in parallel and fails fast if any are unavailable, before any notes are read or files written.

**Architecture:** Insert a new Step 0 section before the existing Step 1. Rename existing Steps 1–4 to Steps 2–5, updating all internal cross-references. The preflight check runs three lightweight probe calls in parallel and either confirms availability or stops with a clear per-source error message.

**Tech Stack:** Markdown skill file (`SKILL.md`), three MCP tools (`mcp__claude_ai_Google_Calendar__list_calendars`, `mcp__claude_ai_Slack__slack_search_users`, `mcp__claude_ai_Atlassian__atlassianUserInfo`)

---

### Task 1: Update the intro summary list

**Files:**
- Modify: `claude/skills/morning-startup/SKILL.md:8-12`

- [ ] **Step 1: Edit the intro numbered list**

Replace the current intro list:

```
This skill helps you start your workday by:
1. Reading context from yesterday's and today's notes (personal and work)
2. Gathering today's context from Calendar, Slack, and Jira in parallel
3. Writing a full Work Daily Note with all work context
4. Writing a slim `## Work Day` stub (wikilink + coaching highlights) into today's personal journal
```

With:

```
This skill helps you start your workday by:
1. Checking all data sources are available (preflight check)
2. Reading context from yesterday's and today's notes (personal and work)
3. Gathering today's context from Calendar, Slack, and Jira in parallel
4. Writing a full Work Daily Note with all work context
5. Writing a slim `## Work Day` stub (wikilink + coaching highlights) into today's personal journal
```

- [ ] **Step 2: Verify the change**

Run:
```bash
grep -n "^[0-9]\." /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Expected output:
```
9:1. Checking all data sources are available (preflight check)
10:2. Reading context from yesterday's and today's notes (personal and work)
11:3. Gathering today's context from Calendar, Slack, and Jira in parallel
12:4. Writing a full Work Daily Note with all work context
13:5. Writing a slim `## Work Day` stub (wikilink + coaching highlights) into today's personal journal
```

- [ ] **Step 3: Commit**

```bash
git add claude/skills/morning-startup/SKILL.md
git commit -m "feat(morning-startup): update intro list for preflight step"
```

---

### Task 2: Insert Step 0 preflight check section

**Files:**
- Modify: `claude/skills/morning-startup/SKILL.md` — insert before `## Step 1:`

- [ ] **Step 1: Insert the Step 0 section**

Find the line `## Step 1: Read Context from Notes` and insert the following block immediately before it (keep a blank line between the preceding `---` and the new section):

```markdown
## Step 0: Preflight Check

Before reading any notes or gathering any data, verify all three MCP data sources
are reachable. Run the following probe calls **in parallel**:

| Source | Probe call |
|--------|-----------|
| Google Calendar | `mcp__claude_ai_Google_Calendar__list_calendars` |
| Slack | `mcp__claude_ai_Slack__slack_search_users` with query `{{SLACK_USER_ID}}` |
| Jira | `mcp__claude_ai_Atlassian__atlassianUserInfo` |

**If all three probes succeed**, print:

> ✅ All data sources available (Calendar, Slack, Jira) — starting briefing…

Then proceed to Step 2.

**If any probe fails**, print an error block naming every failed source:

> ❌ Preflight check failed — cannot start morning briefing.
>
> The following data sources are not available:
> - **[Source name]** — [diagnosis]
>
> Fix the above and re-run your morning startup.

Then **stop immediately**. Do not read any notes. Do not write any files.

**Error diagnosis by error type:**
- **Tool not found / schema not loaded**: "MCP server may not be running. Restart Claude Code or check your MCP config."
- **Authentication / authorization error**: "Auth expired or invalid. Re-authenticate via the MCP server settings."
- **Unexpected / unknown error**: "Unexpected error — [include the raw error message]."

---

```

- [ ] **Step 2: Verify Step 0 is present**

Run:
```bash
grep -n "## Step 0" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Expected:
```
32:## Step 0: Preflight Check
```

- [ ] **Step 3: Commit**

```bash
git add claude/skills/morning-startup/SKILL.md
git commit -m "feat(morning-startup): add Step 0 preflight check"
```

---

### Task 3: Renumber Steps 1–4 to Steps 2–5 and fix cross-references

**Files:**
- Modify: `claude/skills/morning-startup/SKILL.md` — update seven step headers and three sub-section labels and one cross-reference

- [ ] **Step 1: Rename step headers**

Make each of these replacements (find → replace):

| Find | Replace |
|------|---------|
| `## Step 1: Read Context from Notes` | `## Step 2: Read Context from Notes` |
| `## Step 2: Gather Context (Run in Parallel)` | `## Step 3: Gather Context (Run in Parallel)` |
| `## Step 3: Write Work Daily Note` | `## Step 4: Write Work Daily Note` |
| `## Step 4: Write Personal Journal Stub` | `## Step 5: Write Personal Journal Stub` |

- [ ] **Step 2: Rename sub-section headers inside the gather step**

Make each of these replacements:

| Find | Replace |
|------|---------|
| `### 2a. Google Calendar` | `### 3a. Google Calendar` |
| `### 2b. Slack — Unread Messages Triage` | `### 3b. Slack — Unread Messages Triage` |
| `### 2c. Jira — Assigned Issues` | `### 3c. Jira — Assigned Issues` |

- [ ] **Step 3: Fix the cross-reference in the write-note step**

Find this sentence (currently in the Step 4 Write Work Daily Note section):

```
After writing the work note, hold **The One Thing** and **One Question** values
verbatim in memory — you will copy them into Step 4.
```

Replace with:

```
After writing the work note, hold **The One Thing** and **One Question** values
verbatim in memory — you will copy them into Step 5.
```

- [ ] **Step 4: Verify all step headers are correct**

Run:
```bash
grep -n "^## Step" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Expected output:
```
32:## Step 0: Preflight Check
XX:## Step 2: Read Context from Notes
XX:## Step 3: Gather Context (Run in Parallel)
XX:## Step 4: Write Work Daily Note
XX:## Step 5: Write Personal Journal Stub
```

(Line numbers will vary after insertions — verify only the content.)

- [ ] **Step 5: Verify sub-section headers are correct**

Run:
```bash
grep -n "^### [0-9]" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Expected:
```
XX:### 3a. Google Calendar
XX:### 3b. Slack — Unread Messages Triage
XX:### 3c. Jira — Assigned Issues
```

- [ ] **Step 6: Verify no stale Step 1/Step 4 cross-references remain**

Run:
```bash
grep -n "Step [14]\b" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Expected: no output (zero matches).

- [ ] **Step 7: Commit**

```bash
git add claude/skills/morning-startup/SKILL.md
git commit -m "feat(morning-startup): renumber steps 1-4 to 2-5, fix cross-references"
```

---

### Task 4: Smoke test

**Files:** none — verification only

- [ ] **Step 1: Scan the final skill file for consistency**

Run:
```bash
grep -n "Step [0-9]" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Verify:
- Step 0 appears (preflight)
- Step 1 does NOT appear (was renumbered)
- Steps 2–5 appear
- No references to old sub-section labels `2a`, `2b`, `2c`

- [ ] **Step 2: Read the Step 0 section in context**

Run:
```bash
grep -n -A 40 "## Step 0" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Verify:
- Three probe calls listed in the table
- Success and failure branches both present
- Error diagnosis table present
- Section closes with `---` before Step 2

- [ ] **Step 3: Final commit if any cleanup was needed**

If no changes were required, skip this step. Otherwise:
```bash
git add claude/skills/morning-startup/SKILL.md
git commit -m "fix(morning-startup): preflight check cleanup"
```
