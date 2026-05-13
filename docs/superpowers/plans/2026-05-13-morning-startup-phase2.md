# Morning Startup Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Phase 2 Deep Prep section to the morning-startup skill that dispatches two parallel agents — Slack Drafts and Meeting Prep — immediately after Phase 1 completes.

**Architecture:** Insert a `## Phase 2: Deep Prep` section into `SKILL.md` after Step 5. It instructs Claude to dispatch two Agent tool calls in parallel using Phase 1 context already in memory, wait for both, then print a final summary. Phase 1's "Have a great day" confirmation is replaced with a Phase 1 complete signal.

**Tech Stack:** Markdown skill file (`SKILL.md`), Agent tool, Slack MCP (`mcp__claude_ai_Slack__*`), Atlassian MCP (`mcp__claude_ai_Atlassian__*`)

---

### Task 1: Update the Step 5 completion message

**Files:**
- Modify: `claude/skills/morning-startup/SKILL.md` (Step 5 final confirmation block)

- [ ] **Step 1: Replace the "Have a great day" confirmation**

Find this exact text in SKILL.md:

```
After writing both files, confirm:
> "Your morning briefing is ready. Work note written to
> `Work/YYYY/MM-MonthName/YYYY-MM-DD.md`, personal journal updated.
> Have a great day!"
```

Replace with:

```
After writing both files, confirm:
> "Phase 1 complete — work note and journal updated. Starting deep prep…"
```

- [ ] **Step 2: Verify the change**

Run:
```bash
grep -n "Phase 1 complete" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Expected:
```
XXX:> "Phase 1 complete — work note and journal updated. Starting deep prep…"
```

Also confirm the old message is gone:
```bash
grep -n "Have a great day" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add claude/skills/morning-startup/SKILL.md
git commit -m "feat(morning-startup): replace Phase 1 completion message for Phase 2 handoff"
```

---

### Task 2: Insert the Phase 2 section

**Files:**
- Modify: `claude/skills/morning-startup/SKILL.md` — insert before `## Troubleshooting`

- [ ] **Step 1: Insert the full Phase 2 section**

Find this exact text (the separator immediately before the Troubleshooting section):

```
---

## Troubleshooting
```

Insert the following block immediately before it (so the Phase 2 content sits between the Step 5 section and the `---` before Troubleshooting):

````markdown
---

## Phase 2: Deep Prep

Once Step 5 is complete, run two prep agents **in parallel**. Dispatch both Agent tool
calls simultaneously — do not wait for one before starting the other.

When building each agent's prompt, substitute all `{{CONFIG_TOKEN}}` values with the
actual resolved values from `config.md`. Agents run in fresh contexts without access
to `config.md`.

---

### Phase 2a: Slack Drafts Agent

Dispatch an Agent with description `"Draft Slack reply drafts for today"`.

Build the following prompt, substituting real values for all `{{}}` tokens and inserting
the actual @-mentions list gathered in Step 3b:

```
You are drafting Slack replies for a morning startup routine.

**Your context (all values are real — use them directly):**
- Slack User ID: {{SLACK_USER_ID}}
- Slack Team ID: {{SLACK_TEAM_ID}}
- Today's date: [today YYYY-MM-DD]
- Yesterday's date: [yesterday YYYY-MM-DD]
- Output file: ~/Documents/Personal/Work/inbox/[today]-slack-drafts.md
- Today's work note path: [full path to today's work note, e.g. ~/Documents/Personal/Work/2026/05-May/2026-05-13.md]

**@-mentions from Phase 1 (do not re-search — use these directly):**
[insert each mention entry from the Phase 1 Slack section: channel name, thread link, one-line summary]

**Monitored channels to check for unanswered threads:**
[insert each row from the config channels table: channel name, channel ID]

---

**Pass 1 — Draft replies for @-mentions:**

For each @-mention listed above:
1. Read the full thread using mcp__claude_ai_Slack__slack_read_thread (you need the
   channel ID and thread timestamp — extract these from the slack:// link or URL above).
2. Understand what is being asked or requested.
3. Draft a contextual reply the user can edit and send.
4. If the thread is purely informational (announcement, FYI, no action expected):
   do NOT draft a reply — add it to the "No Reply Needed" list instead.

**Pass 2 — Unanswered threads in monitored channels:**

For each monitored channel listed above:
1. Search for threads where the user posted using mcp__claude_ai_Slack__slack_search_public_and_private:
   Query: `from:{{SLACK_USER_ID}} in:[channel-name] after:[yesterday YYYY-MM-DD]`
2. For each result, read the thread using mcp__claude_ai_Slack__slack_read_channel.
3. Check whether the most recent message in the thread is NOT from {{SLACK_USER_ID}}.
4. If others replied after the user's last message: the user owes a response. Draft a reply.
5. If the user's message is the most recent: skip it.

---

**Output:**

1. Create directory ~/Documents/Personal/Work/inbox/ if it does not exist.

2. Write ~/Documents/Personal/Work/inbox/[today]-slack-drafts.md (overwrite if exists):

# Slack Draft Replies — [today]

## @Mentions Needing Response

### #[channel] — [thread summary]
**Link:** [slack://channel?team=[SLACK_TEAM_ID]&id=[CHANNEL_ID]&message=[MESSAGE_TS]]
**Context:** [1-2 sentence summary of what's being asked]
**Draft:**
> [draft reply text — written in first person as the user]
**Status:** Ready to post | Needs your input

## Threads Awaiting Your Response

### #[channel] — [thread summary]
**Link:** [slack://channel?team=[SLACK_TEAM_ID]&id=[CHANNEL_ID]&message=[MESSAGE_TS]]
**Context:** [1-2 sentence summary]
**Draft:**
> [draft reply text]
**Status:** Ready to post | Needs your input

## No Reply Needed
- #[channel]: [thread summary] — informational only

3. Add a wikilink to the slack-drafts file in today's work note.
   Open [today's work note path] and append this line at the end of the ## Slack section
   (after the last bullet in that section, before the next ##):

[[Work/inbox/[today]-slack-drafts|📝 Slack Drafts →]]

---

**When complete, return ONLY this one-line summary (no other output):**
"Drafted N replies (N @-mentions, N unanswered threads), N informational (no reply needed)"
```

---

### Phase 2b: Meeting Prep Agent

Dispatch an Agent with description `"Prepare meeting notes for today"`.

Build the following prompt, substituting real values for all `{{}}` tokens and inserting
the actual meeting list gathered in Step 3a:

```
You are preparing meeting notes for a morning startup routine.

**Your context (all values are real — use them directly):**
- Today's date: [today YYYY-MM-DD]
- Seven days ago: [YYYY-MM-DD]
- Jira cloud ID: {{JIRA_CLOUD_ID}}
- Jira base URL: {{JIRA_BASE_URL}}
- Today's work note path: [full path, e.g. ~/Documents/Personal/Work/2026/05-May/2026-05-13.md]

**Today's meetings (from Phase 1 calendar — do not re-fetch):**
[insert each meeting entry from the Phase 1 Calendar section:
 time, title, attendees list with names/emails, meeting link if available]

**VIPs — flag any unresolved items explicitly:**
Rick Song, Charles Yeh, Chuck McIntyre, Drew McMahon, Laura Milinez,
Malav Bhavsar, Manoj Dayaram, Christian Henry

---

**Skip the following meetings entirely — do not write prep notes for them:**
- Focus time blocks or "No meetings" blocks
- Events whose title starts with "❇️" or whose description contains "Clockwise"
- Events with only one attendee (solo blocks, personal reminders)

---

**For each real (non-skipped) meeting, do the following:**

**Step A — Attendee context (Slack):**
For each attendee, search Slack using mcp__claude_ai_Slack__slack_search_public_and_private:
- Query: `from:[attendee-first-name] after:[seven-days-ago]`
- Look for: pending questions, recent decisions, anything unresolved
- For VIPs: mark any unresolved thread explicitly with "⚠️ unresolved"
- If an attendee has no Slack activity: note "no recent Slack context"

**Step B — Topic context (Jira):**
Use mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql with cloudId {{JIRA_CLOUD_ID}}:
- JQL: `text ~ "[2-3 keywords from meeting title]" AND statusCategory != Done ORDER BY updated DESC`
- Take the top 3 most relevant results
- If no results: note "no related Jira tickets found"

**Step C — Talking points:**
Generate exactly 3 talking points. Requirements:
- Each must be specific, not generic (no "discuss project status")
- Each must be grounded in what you found: cite the Slack thread, Jira ticket, or context
- Each must be actionable: framed as a question to resolve or decision to make
- If no Slack/Jira context was found: infer from meeting title and attendees, but
  prepend "**Note: no recent context found**" before the talking points for that meeting

---

**Output:**

Open [today's work note path].
If a `## Meeting Prep` section already exists in the file: replace it entirely.
If it does not exist: append it at the end of the file.

Write the following section:

## Meeting Prep

### [HH:MM AM/PM] — [Meeting Title]

**Attendees:** [Name, Name (+N more if >3)]

**Context:**
- [Person or ⚠️ VIP name]: [1-line Slack summary, or "no recent Slack context"]
- [[KEY-123]]({{JIRA_BASE_URL}}KEY-123): [ticket summary] — [status, days since update]

**Talking Points:**
1. [specific, grounded, actionable point]
2. [specific, grounded, actionable point]
3. [specific, grounded, actionable point]

[repeat the ### block for each non-skipped meeting]

---

**When complete, return ONLY this one-line summary (no other output):**
"Prepped N meetings, skipped N (focus/Clockwise/solo blocks)"
```

---

### Phase 2 Summary

After both agents complete, print the following (substituting agent return summaries):

```
## Morning Prep Complete

✅ Slack Drafts: [paste Slack Drafts agent return summary here] → ~/Documents/Personal/Work/inbox/[today]-slack-drafts.md
✅ Meeting Prep: [paste Meeting Prep agent return summary here] → Work Day note updated

Nothing has been sent or posted. Review and act when ready.
```

For any agent that failed or returned an error: replace ✅ with ⚠️ and describe the
error in place of the return summary. If an agent timed out, note "agent timed out —
check partial output at [path]".
````

- [ ] **Step 2: Verify Phase 2 section is present**

Run:
```bash
grep -n "^## Phase 2" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Expected:
```
XXX:## Phase 2: Deep Prep
```

- [ ] **Step 3: Verify the two agent subsections are present**

Run:
```bash
grep -n "^### Phase 2" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Expected:
```
XXX:### Phase 2a: Slack Drafts Agent
XXX:### Phase 2b: Meeting Prep Agent
```

- [ ] **Step 4: Verify Phase 2 Summary section is present**

Run:
```bash
grep -n "Morning Prep Complete" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Expected:
```
XXX:## Morning Prep Complete
```

- [ ] **Step 5: Verify section ordering is correct**

Run:
```bash
grep -n "^## " /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Expected ordering (line numbers will vary):
```
XX:## Before You Start: Load Your Config
XX:## Step 0: Preflight Check
XX:## Step 2: Read Context from Notes
XX:## Step 3: Gather Context (Run in Parallel)
XX:## Step 4: Write Work Daily Note
XX:## Step 5: Write Personal Journal Stub
XX:## Phase 2: Deep Prep
XX:## Troubleshooting
XX:## Morning Startup Skill
```

- [ ] **Step 6: Commit**

```bash
git add claude/skills/morning-startup/SKILL.md
git commit -m "feat(morning-startup): add Phase 2 deep prep with Slack drafts and meeting prep agents"
```

---

### Task 3: Smoke test

**Files:** none — verification only

- [ ] **Step 1: Confirm no stale "Have a great day" text remains**

Run:
```bash
grep -n "Have a great day\|Phase 1 complete\|Phase 2" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Expected:
- "Have a great day" — no matches
- "Phase 1 complete" — one match (Step 5 confirmation)
- "Phase 2" — multiple matches (section header, subsection headers, references)

- [ ] **Step 2: Confirm agent prompts contain required MCP tool references**

Run:
```bash
grep -n "mcp__claude_ai_Slack__\|mcp__claude_ai_Atlassian__" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md | grep -v "^.*Step 3"
```

Expected: matches within the Phase 2 section for:
- `mcp__claude_ai_Slack__slack_read_thread`
- `mcp__claude_ai_Slack__slack_search_public_and_private`
- `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql`

- [ ] **Step 3: Confirm inbox path is consistent**

Run:
```bash
grep -n "Work/inbox" /Users/ianchesal/src/dotfiles/claude/skills/morning-startup/SKILL.md
```

Expected: all references use `~/Documents/Personal/Work/inbox/` — no variations.

- [ ] **Step 4: Final commit if any cleanup was needed**

If no changes: skip. Otherwise:
```bash
git add claude/skills/morning-startup/SKILL.md
git commit -m "fix(morning-startup): phase 2 cleanup"
```
