# Morning Startup Work Note Split — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the morning-startup skill so work briefing content (Calendar, Slack, Jira, Executive Coaching) is written to a dedicated work daily note, with a slim stub (wikilink + The One Thing + One Question) written into the personal journal.

**Architecture:** Three file changes — config.md and config.example.md gain a Work Daily Notes section, SKILL.md is rewritten with a 4-step structure. One new file is written outside the dotfiles repo: the Obsidian vault template.

**Tech Stack:** Markdown, Templater (Obsidian), shell path expansion (`~`)

**Spec:** `docs/superpowers/specs/2026-05-04-morning-startup-work-note-split-design.md`

---

## File Map

| Action | File |
|--------|------|
| Modify | `claude/skills/morning-startup/config.md` |
| Modify | `claude/skills/morning-startup/config.example.md` |
| Rewrite | `claude/skills/morning-startup/SKILL.md` |
| Create (outside repo) | `~/Documents/Personal/Extras/Templates/Template, Work Daily Note.md` |

---

## Task 1: Add Work Daily Notes section to config files

**Files:**
- Modify: `claude/skills/morning-startup/config.md`
- Modify: `claude/skills/morning-startup/config.example.md`

- [ ] **Step 1: Add Work Daily Notes section to config.md**

Append the following to the end of `claude/skills/morning-startup/config.md`:

```markdown

## Work Daily Notes

- **Path**: `~/Documents/Personal/Work/`
- **Structure**: `YYYY/MM-MonthName/YYYY-MM-DD.md`
- **Title format**: `Work Day - YYYY-MM-DD`
```

- [ ] **Step 2: Add Work Daily Notes section to config.example.md**

Append the following to the end of `claude/skills/morning-startup/config.example.md`:

```markdown

## Work Daily Notes

- **Path**: `{{PATH_TO_WORK_NOTES}}`
  - Example: `~/Documents/Personal/Work/`
- **Structure**: `YYYY/MM-MonthName/YYYY-MM-DD.md`
  - Example: `2026/05-May/2026-05-04.md`
- **Title format**: `Work Day - YYYY-MM-DD`
  - Used in the `# Work Day - YYYY-MM-DD` heading and wikilinks from the personal journal.
```

- [ ] **Step 3: Verify both files**

Read `claude/skills/morning-startup/config.md` and confirm the `## Work Daily Notes` section appears at the bottom with the three keys: `Path`, `Structure`, `Title format`.

Read `claude/skills/morning-startup/config.example.md` and confirm the same section appears with placeholder values.

- [ ] **Step 4: Commit**

```bash
git add claude/skills/morning-startup/config.md claude/skills/morning-startup/config.example.md
git commit -m "feat(morning-startup): add Work Daily Notes config section"
```

---

## Task 2: Create the Obsidian work daily note template

**Files:**
- Create: `~/Documents/Personal/Extras/Templates/Template, Work Daily Note.md`

Note: this file is in the Obsidian vault, not the dotfiles git repo. No git commit is needed for this task.

- [ ] **Step 1: Write the template file**

Write the following content to `~/Documents/Personal/Extras/Templates/Template, Work Daily Note.md`:

```markdown
---
created: <% tp.date.now("YYYY-MM-DD HH:mm:ss") %>
tags:
  - work
  - journal
---

# Work Day - <% tp.file.title %>

## Calendar

## Slack

## Jira

## Executive Coaching
```

- [ ] **Step 2: Verify the file**

Read `~/Documents/Personal/Extras/Templates/Template, Work Daily Note.md` and confirm:
- Frontmatter contains `created`, `tags: [work, journal]`
- Title line uses `tp.file.title`
- Four section headers are present: `## Calendar`, `## Slack`, `## Jira`, `## Executive Coaching`

---

## Task 3: Rewrite SKILL.md

**Files:**
- Rewrite: `claude/skills/morning-startup/SKILL.md`

- [ ] **Step 1: Write the new SKILL.md**

Write the following content to `claude/skills/morning-startup/SKILL.md` (complete replacement):

````markdown
---
name: morning-startup
description: Use when the user wants to start their workday, get a morning briefing, or says things like "start my day", "morning startup", "good morning", "what's on my plate today", "morning briefing", or "let's get the day started". This skill reads context from yesterday's personal and work notes, gathers context from Calendar, Slack, and Jira in parallel, writes a full Work Daily Note, and places a slim briefing stub with executive coaching highlights into today's personal journal. Invoke whenever the user signals they are beginning their workday.
---

# Morning Startup

This skill helps you start your workday by:
1. Reading context from yesterday's and today's notes (personal and work)
2. Gathering today's context from Calendar, Slack, and Jira in parallel
3. Writing a full Work Daily Note with all work context
4. Writing a slim `## Work Day` stub (wikilink + coaching highlights) into today's personal journal

---

## Before You Start: Load Your Config

Look for a `config.md` file in the same directory as this `SKILL.md`. Read it
now — it supplies all personal values referenced throughout this skill.

If `config.md` does not exist, tell the user:
> "I don't see a `config.md` in your morning-startup skill directory. Please copy
> `config.example.md` to `config.md` and fill in your values, then try again."
> Then stop.

Throughout this skill, references like `{{SLACK_USER_ID}}` mean: use the value
from your `config.md`.

---

## Step 1: Read Context from Notes

Before gathering external data, read the following files. Do this silently — no
need to narrate it to the user.

**Yesterday's personal daily note:**
- Compute yesterday's date and build the path using `{{DAILY_NOTES_PATH}}` and
  `{{DAILY_NOTES_STRUCTURE}}`.
- Read the file. If it doesn't exist, skip silently.
- Extract: what got done (Day in Review), what carried forward, any themes, mood,
  energy signals, or personal context mentioned.

**Today's personal daily note:**
- Read today's file if it exists.
- Extract: any intentions already written, todos, personal context, or notes already
  captured before you started.

**Yesterday's work daily note:**
- Compute yesterday's date and build the path using `{{WORK_NOTES_PATH}}` and
  `{{WORK_NOTES_STRUCTURE}}`.
- Read the file. If it doesn't exist, skip silently.
- Extract: work carries-forward, Jira state, unresolved incidents, key decisions made.

Hold all context. Use it in Step 3 to ground the Executive Coaching in both
personal state and work continuity.

---

## Step 2: Gather Context (Run in Parallel)

Gather all three data sources simultaneously. Do NOT wait for one to finish before
starting the others.

### 2a. Google Calendar

**CRITICAL — Always pass explicit date bounds.** The calendar MCP can return
stale or historical data if called without a time range. You MUST always pass
`timeMin`, `timeMax`, and `timeZone` when calling `gcal_list_events`.

**If today is Monday:**
- Fetch the **full week** (Monday through Friday) with:
  - `timeMin`: `YYYY-MM-DDT00:00:00` using Monday's date
  - `timeMax`: `YYYY-MM-DDT23:59:59` using Friday's date
  - `timeZone`: `{{YOUR_TIMEZONE}}`
- You will produce both a today-view AND a `### Week Ahead` section (see template).

**All days:**
- Fetch today's events with:
  - `timeMin`: `YYYY-MM-DDT00:00:00` using today's date
  - `timeMax`: `YYYY-MM-DDT23:59:59` using today's date
  - `timeZone`: `{{YOUR_TIMEZONE}}`

**After fetching, validate the results:** Check that the returned events have
dates within the requested range. If any events predate the last 30 days, the
MCP returned stale/historical data. In that case, retry once with the same
explicit parameters. If the second attempt also returns stale data, write a
warning in the Calendar section, skip calendar analysis entirely, and continue
with Slack and Jira — do not block the rest of the briefing on a broken calendar.

For each event, analyze and note:

- **External/vendor meetings** — attendees from outside your company domain
- **Customer meetings** — known customer names or domains from your config
- **VIP meetings** — events that include people from your `{{VIP_NAMES}}` list
- **Exceptional/uncommon meetings** — things that don't recur regularly; flag
  these so the user isn't surprised
- **Scheduling tool links** — meetings booked via `{{SCHEDULING_TOOL}}` (visible
  in event description/organizer metadata)
- **Focus time blocks** — time blocked for deep work
- **Lunch opportunity** — suggest the best window given the user's timezone
  (`{{YOUR_TIMEZONE}}`) vs company HQ timezone (`{{COMPANY_HQ_TIMEZONE}}`);
  east-coasters at west-coast companies often miss lunch
- When writing the table out, make sure there's a space between the `Key
  meetings` header and the table. Otherwise Obsidian doesn't render it properly
  as a table.

Produce a `### Calendar` section:

```
### Calendar

**Today at a glance:** [X meetings · Y hours of focus time]

**⚠️ Heads up / Unusual today:**
- [Any exceptional or non-recurring meetings]

**Key meetings:**

| Time | Event | Notes |
|------|-------|-------|
| 9:00 AM | Example meeting | VIP attending |

**Focus time:** [X hours — when]

**Lunch window:** [Best suggested time and why]
```

**If today is Monday, also produce a `### Week Ahead` section:**

Scan the full week and flag anything the user needs to prepare for now to avoid
being caught off-guard later. Think about prep time — if there's a big review on
Thursday, flag it Monday so prep can start Tuesday.

```
### Week Ahead

**Week at a glance:** [X total meetings · heaviest day · lightest day · total focus time]

**⚠️ Prepare now — don't get caught flat-footed:**
- [Non-recurring, VIP, external, high-stakes, or unusual meetings this week. For each: why it matters and what to do before it.]

| Day | Key Events | Load |
|-----|-----------|------|
| Mon | [events] | Heavy / Medium / Light |
| Tue | [events] | Heavy / Medium / Light |
| Wed | [events] | Heavy / Medium / Light |
| Thu | [events] | Heavy / Medium / Light |
| Fri | [events] | Heavy / Medium / Light |
```

### 2b. Slack — Unread Messages Triage

Use `mcp__claude_ai_Slack__slack_search_public_and_private` and
`mcp__claude_ai_Slack__slack_read_channel` to check recent messages.

**Priority order:**
1. **Mentions** — search `mentions:{{SLACK_USER_ID}} after:{{YESTERDAY_DATE}}`
2. **VIP DMs** — search for recent messages `from:{{VIP_SLACK_USERNAMES}}`
   using `slack_search_public_and_private`
3. **Incidents** — read the incidents/on-call channel from your config;
   for each incident assess: severity, impact summary, current status
   (ongoing vs resolved), whether action is needed
4. **Monitored channels** — read each channel from your `{{SLACK_CHANNELS}}`
   config table; summarize what's worth reading

For incidents specifically, also search `incident SEV after:{{YESTERDAY_DATE}}`
to catch any recent `inc-*` channels created overnight — the main incidents
channel can be noisy with old bot posts.

For each item requiring action, produce a clickable Obsidian deep link using
the Slack `slack://` URL scheme:
- Channel: `[#channel-name](slack://channel?team={{SLACK_TEAM_ID}}&id=CHANNEL_ID)`
- Message: `[description](slack://channel?team={{SLACK_TEAM_ID}}&id=CHANNEL_ID&message=MESSAGE_TS)`

If you have an `https://slack.com/archives/...` permalink but can't determine
the team ID, use the `https://` URL directly — still clickable in Obsidian.

Produce a `### Slack` section:

```
### Slack

**🔴 Action Required (Mentions):**
- [message description] — [link]

**💬 VIP Activity:**
- [Person]: [summary] — [link]

**🚨 Incidents:**
- [SEV-X] [Incident name]: [impact]. Status: [ongoing/resolved]. [link]
  - _Action needed: Yes/No — [reason]_

**📣 Channel Highlights:**
- [#channel]: [what's worth reading] — [link]
```

Omit any category where there's nothing to report, or note "Nothing new."

### 2c. Jira — Assigned Issues

Use `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql` with cloud ID
`{{JIRA_CLOUD_ID}}`.

Run these queries:
- All open: `assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC`

Flag each issue:
- 🆕 **New** — created in the last 3 days
- ⏰ **Languishing** — no update in `{{LANGUISHING_THRESHOLD}}` days
- 🔥 **Urgent** — priority is High or Highest
- 📋 **Normal** — everything else

Produce a `### Jira` section as a markdown table:

```
### Jira

| Status | Key | Summary | Priority | Last Updated |
|--------|-----|---------|----------|-------------|
| 🔥⏰ | [KEY-123]({{JIRA_BASE_URL}}KEY-123) | Summary | High | 2026-01-01 (30d) |
```

If no open issues, note "No open Jira issues assigned."

---

## Step 3: Write Work Daily Note

Determine today's work note path from your config:
- Base path: `{{WORK_NOTES_PATH}}`
- Structure: `{{WORK_NOTES_STRUCTURE}}`
- Title format: `{{WORK_NOTES_TITLE_FORMAT}}`

Build the full path by expanding `~` and substituting today's date into the
structure. Create any missing directories in the path before writing.

Write (or replace) the file at that path with the following content:

```markdown
# Work Day - YYYY-MM-DD

## Calendar

[calendar section from Step 2a — full content including Today at a glance,
Heads up, Key meetings table, Focus time, Lunch window]

[## Week Ahead — Monday only]
[week ahead section — full content including Week at a glance,
Prepare now flags, and weekly table]

## Slack

[slack section from Step 2b — full content including all categories]

## Jira

[jira table from Step 2c]

## Executive Coaching

**Today's Shape:**
[In 2–3 sentences, describe the texture of today. Is it meeting-heavy with
little focus time? A day with a big deliverable? An unusually light day?
Name what the user is walking into so they can set the right intention.]

**The One Thing:**
[Given everything — calendar, Slack, Jira, yesterday's personal note,
yesterday's work note, and today's intentions — what is the single most
important thing to move forward today? Name it explicitly. If the day risks
filling up with busyness that doesn't move the needle, say so.]

**Watch Out For:**
[1–3 specific, concrete observations about risks or patterns. Reference real
data — actual meeting names, Jira keys, Slack threads, note content.
Examples: "Your 1:1s are back-to-back from 3–5 PM — you'll be drained by
the last one. Prep quick agendas for each now." Or: "INFR-1673 has been open
44 days with no movement. Decide today: do it or defer it explicitly."]

**Energy & Wellbeing:**
[Based on context from yesterday's personal note or today's. Flag anything
worth attending to: disrupted routines, personal stressors, a heavy week
that needs pacing. If yesterday's note shows the user was productive and
energized, note that too — momentum is real.]

**One Question:**
[A single sharp coaching question to carry into the day. Make it specific to
today's context, not generic. E.g.: "The incident debrief is at 1 PM and
you're the organizer — do you have a clear outcome in mind for what you want
to leave the room having decided?"]
```

After writing the work note, hold **The One Thing** and **One Question** values
verbatim in memory — you will copy them into Step 4.

---

## Step 4: Write Personal Journal Stub

Determine today's personal note path from your config:
- Base path: `{{DAILY_NOTES_PATH}}`
- Structure: `{{DAILY_NOTES_STRUCTURE}}`

Read the current personal daily note. Find `{{ANCHOR_SECTION}}`. Insert the
`## Work Day` section **above** that line.

If `## Work Day` already exists in the file, **replace** it rather than
inserting a duplicate.

Compute the wikilink path for the work note. The path component is derived from
`{{WORK_NOTES_STRUCTURE}}` with today's date substituted, without the `.md`
extension. Example for 2026-05-04: `Work/2026/05-May/2026-05-04`.

**Content to insert:**

```markdown
## Work Day

[[Work/YYYY/MM-MonthName/YYYY-MM-DD|Work Day - YYYY-MM-DD →]]

**The One Thing:** [verbatim from Step 3 coaching]

**One Question:** [verbatim from Step 3 coaching]

---

```

If the personal daily note doesn't exist, tell the user — they may need to
create it from their note template first.

After writing both files, confirm:
> "Your morning briefing is ready. Work note written to
> `Work/YYYY/MM-MonthName/YYYY-MM-DD.md`, personal journal updated.
> Have a great day!"

---

## Troubleshooting

- **Calendar returns historical/stale data**: Always pass explicit `timeMin`,
  `timeMax`, and `timeZone` parameters to `gcal_list_events`. If results still
  look wrong (dates from years ago), retry once. If the second attempt fails,
  write a warning in the Calendar section and continue — do not skip Slack and
  Jira.
- **Slack mentions returning nothing**: Verify `{{SLACK_USER_ID}}` is correct.
  Use `mentions:USER_ID` syntax, not `to:me`.
- **Jira returns too many results**: Focus on 🔥 Urgent and 🆕 New first;
  summarize languishing items in a collapsed group.
- **Incidents channel is noisy**: Supplement channel read with a keyword search
  for `incident SEV after:{{YESTERDAY_DATE}}` to surface recent incidents.
- **Notes don't exist**: Skip silently and proceed without that context. Don't
  block on missing notes.
- **Work note directory doesn't exist**: Create it silently before writing the
  file. The path `Work/YYYY/MM-MonthName/` may not exist on the first run.
````

- [ ] **Step 2: Verify SKILL.md structure**

Read `claude/skills/morning-startup/SKILL.md` and confirm all of the following are present:
- Frontmatter with updated `description` mentioning "Work Daily Note"
- `## Step 1` mentions three note reads (yesterday's personal, today's personal, yesterday's work)
- `## Step 2` contains sections 2a, 2b, 2c
- `## Step 3` references `{{WORK_NOTES_PATH}}`, `{{WORK_NOTES_STRUCTURE}}`, `{{WORK_NOTES_TITLE_FORMAT}}`
- `## Step 3` includes the full Executive Coaching block with all five sub-sections
- `## Step 4` references `{{ANCHOR_SECTION}}` and produces the `## Work Day` stub
- `## Troubleshooting` includes the work note directory creation note

- [ ] **Step 3: Verify config placeholder coverage**

Read `claude/skills/morning-startup/config.md` and confirm every `{{placeholder}}` referenced in the new SKILL.md has a corresponding value:

| Placeholder | Config section | Key |
|-------------|---------------|-----|
| `{{WORK_NOTES_PATH}}` | `## Work Daily Notes` | `Path` |
| `{{WORK_NOTES_STRUCTURE}}` | `## Work Daily Notes` | `Structure` |
| `{{WORK_NOTES_TITLE_FORMAT}}` | `## Work Daily Notes` | `Title format` |
| `{{DAILY_NOTES_PATH}}` | `## Daily Notes` | `Path` |
| `{{DAILY_NOTES_STRUCTURE}}` | `## Daily Notes` | `Structure` |
| `{{ANCHOR_SECTION}}` | `## Daily Notes` | `Anchor section` |
| `{{SLACK_USER_ID}}` | `## Identity` | `Slack User ID` |
| `{{SLACK_TEAM_ID}}` | `## Identity` | `Slack Team ID` |
| `{{JIRA_CLOUD_ID}}` | `## Jira` | `Cloud ID` |
| `{{JIRA_BASE_URL}}` | `## Jira` | `Base URL` |
| `{{LANGUISHING_THRESHOLD}}` | `## Jira` | `Languishing threshold` |
| `{{YOUR_TIMEZONE}}` | `## Timezone` | `My timezone` |
| `{{COMPANY_HQ_TIMEZONE}}` | `## Timezone` | `Company HQ timezone` |

- [ ] **Step 4: Commit**

```bash
git add claude/skills/morning-startup/SKILL.md
git commit -m "feat(morning-startup): rewrite skill for work/personal note split

- 4-step structure: read notes, gather data, write work note, write personal stub
- Step 1 now reads yesterday's work daily note alongside personal notes
- Step 3 writes full Calendar/Slack/Jira/Coaching to dedicated work note
- Step 4 writes slim Work Day stub to personal journal with wikilink + coaching highlights"
```
