---
name: morning-startup
description: Use when the user wants to start their workday, get a morning briefing, or says things like "start my day", "morning startup", "good morning", "what's on my plate today", "morning briefing", or "let's get the day started". This skill reads context from yesterday's and today's notes, gathers context from Calendar, Slack, and Jira in parallel, and writes a Daily Plan with executive coaching to today's daily note. Invoke whenever the user signals they are beginning their workday.
---

# Morning Startup

This skill helps you start your workday by:
1. Reading context from yesterday's note and today's existing note
2. Gathering today's context from Calendar, Slack, and Jira in parallel
3. Writing a `## Daily Plan` section into today's daily note, including executive coaching

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

**Yesterday's daily note:**
- Compute yesterday's date and build the path using `{{DAILY_NOTES_PATH}}` and
  `{{DAILY_NOTES_STRUCTURE}}`.
- Read the file. If it doesn't exist, skip silently.
- Extract: what got done (Day in Review), what carried forward, any themes, mood,
  energy signals, or personal context mentioned.

**Today's daily note:**
- Read today's file if it exists.
- Extract: any intentions already written, todos, personal context, or notes already
  captured before you started.

Hold all of this context. Use it in Step 3 to personalize the Executive Coaching
section — reference it explicitly so the coaching feels grounded in reality, not
generic.

---

## Step 2: Gather Context (Run in Parallel)

Gather all three data sources simultaneously. Do NOT wait for one to finish before
starting the others.

### 2a. Google Calendar

**If today is Monday:**
- Fetch the **full week** (Monday through Friday) using
  `mcp__claude_ai_Google_Calendar__gcal_list_events` in `{{YOUR_TIMEZONE}}`.
- You will produce both a today-view AND a `### Week Ahead` section (see template).

**All days:**
- Fetch today's events in `{{YOUR_TIMEZONE}}`.

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

## Step 3: Write the Daily Plan

Determine today's daily note path from your config:
- Base path: `{{DAILY_NOTES_PATH}}`
- Structure: `{{DAILY_NOTES_STRUCTURE}}`

Read the current daily note. Find the line `{{SECTION_HEADING_TO_INSERT_ABOVE}}`.
Insert the full `## Daily Plan` section **above** that line.

Full section to insert:

```markdown
## Daily Plan

### Calendar

[calendar content]

[### Week Ahead]
[week coaching content — Monday only]

### Slack

[slack content]

### Jira

[jira content]

### Executive Coaching

[coaching content — see format below]

---

```

**Executive Coaching section — how to write it:**

This is the highest-value section. Don't summarize — coach. Draw on everything
you've gathered: calendar shape, Slack signals, Jira state, what happened
yesterday, what the user has already written in today's note. Be specific and
grounded. Reference real meeting names, Jira keys, Slack threads, and note
content. Avoid generic platitudes.

Format:

```
### Executive Coaching

**Today's Shape:**
[In 2–3 sentences, describe the texture of today. Is it meeting-heavy with little
focus time? A day with a big deliverable? An unusually light day that's an opportunity?
Name what the user is walking into so they can set the right intention.]

**The One Thing:**
[Given everything — calendar, Slack, Jira, yesterday's carries-forward, and today's
intentions — what is the single most important thing to move forward today? Name it
explicitly. If the day is at risk of filling up with busyness that doesn't move the
needle, say so.]

**Watch Out For:**
[1–3 specific, concrete observations about risks or patterns. Reference real data.
Examples: "Your 1:1s are back-to-back from 3–5 PM — you'll be drained by the last
one. Prep quick agendas for each now." Or: "INFR-1673 has been open 44 days with no
movement. Every day it sits is a small tax on your mental load. Decide today: do it
or defer it explicitly." Or: "Christian Henry's DM about the MongoDB contract is
directly connected to your #1 intention. Answer it before 10 AM."]

**Energy & Wellbeing:**
[Based on context from yesterday's note or today's. Flag anything worth attending to:
disrupted routines, personal stressors, a heavy week that needs pacing. If yesterday's
note shows the user was productive and energized, note that too — momentum is real.]

**One Question:**
[A single sharp coaching question to carry into the day. Make it specific to today's
context, not generic. E.g.: "The incident debrief is at 1 PM and you're the organizer
— do you have a clear outcome in mind for what you want to leave the room having
decided?"]
```

If `## Daily Plan` already exists in the file, **replace** it rather than
inserting a duplicate.

If the daily note doesn't exist, tell the user — they may need to create it
from their note template first.

After writing, confirm:
> "Your daily plan has been written to [filename]. Have a great day!"

---

## Troubleshooting

- **Slack mentions returning nothing**: Verify `{{SLACK_USER_ID}}` is correct.
  Use `mentions:USER_ID` syntax, not `to:me`.
- **Jira returns too many results**: Focus on 🔥 Urgent and 🆕 New first;
  summarize languishing items in a collapsed group.
- **Incidents channel is noisy**: Supplement channel read with a keyword search
  for `incident SEV after:{{YESTERDAY_DATE}}` to surface recent incidents.
- **Notes don't exist**: Skip silently and proceed without that context. Don't
  block on missing notes.
