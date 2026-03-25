---
name: morning-startup
description: Use when the user wants to start their workday, get a morning briefing, or says things like "start my day", "morning startup", "good morning", "what's on my plate today", "morning briefing", or "let's get the day started". This skill orchestrates auth, calendar review, Slack triage, and Jira review, then writes a Daily Plan to today's daily note. Invoke whenever the user signals they are beginning their workday.
---

# Morning Startup

This skill helps you start your workday by:
1. Walking through work authentication
2. Gathering today's context from Calendar, Slack, and Jira in parallel
3. Writing a `## Daily Plan` section into today's daily note

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

## Step 1: Authentication

If `config.md` specifies an auth command, prompt the user to run it. The auth
command is interactive and must be run by the user in their own terminal — Claude
cannot run interactive shell functions.

Tell the user:
> "Please run `{{AUTH_COMMAND}}` in your terminal now. It will walk you through
> your work authentication. Tell me when you're finished and I'll continue."

Wait for the user to confirm before moving on.

If no auth command is configured, skip this step.

---

## Step 1.5: Read Today's Intentions (Read-Only)

Before gathering context, read today's daily note to capture any intentions the
user has already written.

1. Locate today's daily note using `{{DAILY_NOTES_PATH}}` and
   `{{DAILY_NOTES_STRUCTURE}}`.
2. If the note does not exist, record state: **Intentions absent**.
3. If the note exists, extract the bullet list under `## Today's Intentions`.
   Read only until the next `##`-level heading or end of file.
4. Assess the extracted content:
   - Bullets present and non-empty → record state **Intentions present**, capture
     the list.
   - Section missing, empty, or only blank bullets → record state
     **Intentions absent**.

This step is **read-only**. Do not modify the note. Carry the captured intentions forward — they will be incorporated into the `## Daily Plan` output in Step 3.

---

## Step 2: Gather Context (Run in Parallel)

Once auth is confirmed, gather all three data sources simultaneously. Do NOT
wait for one to finish before starting the others.

### 2a. Google Calendar — Today's Events

Use `mcp__claude_ai_Google_Calendar__gcal_list_events` to fetch today's events
in `{{YOUR_TIMEZONE}}`.

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

### Priorities Analysis

[priorities analysis content — see rules below]

---

### Calendar

[calendar content]

### Slack

[slack content]

### Jira

[jira content]

---

```

**Generating `### Priorities Analysis`:**

Use the state captured in Step 1.5 and the context gathered in Step 2.

**Branch A — Intentions present:**

Cross-reference each intention against calendar events, Jira issues, and Slack
activity. Apply these icon rules:

Apply the **first matching rule** in order:

1. ❓ **Too vague** — the intention text is non-specific (e.g., "misc", "catch up",
   "emails"). Use ❓ and skip cross-referencing.
2. ✅ **Well-supported** — at least one source has a strong signal: a scheduled
   calendar event directly related to this intention, a 🔥 Jira issue (High/Highest
   priority) or one updated within the last 3 days, OR relevant Slack
   mentions/activity. Use ✅.
3. ⚠️ **Weakly supported** — at least one source connects to this intention, but
   the signal is weak (e.g., a Jira ticket updated >3 days ago and not 🔥, or a
   calendar item only tangentially related). Use ⚠️.
4. 🚨 **No support** — nothing in calendar, Jira, or Slack connects to this
   intention. Use 🚨.

Coaching tone: be direct, name misalignments plainly, do not soften 🚨 items.
Ground all coaching in today's context only — no references to past days.

Output:

```markdown
### Priorities Analysis

**Your intentions for today:**
- [intention 1]
- [intention 2]

**Alignment check:**
- ✅ **[intention]** — [supporting evidence]. Well-supported.
- ⚠️ **[intention]** — [weak evidence]. [Coaching note on risk].
- 🚨 **[intention]** — Nothing on your calendar, in Jira, or in Slack connects to
  this. If it's real today, block time now.
- ❓ **[intention]** — Too vague to cross-reference. Consider rewriting as a
  specific outcome.

**Unplanned demands on your day:**
- [Slack mentions, 🔥 Jira tickets, or calendar items not covered by any intention]
```

If all calendar events, Jira tickets, and Slack signals are already covered by
the user's intentions, write: "**Unplanned demands on your day:** None — your
intentions cover everything on the radar."

**Branch B — Intentions absent:**

Generate ranked suggestions using calendar-first weighting:
1. Calendar commitments (scheduled = already committed)
2. 🔥 Urgent Jira issues (High/Highest priority)
3. ⏰ Languishing Jira issues (no update in `{{LANGUISHING_THRESHOLD}}` days) —
   distinct from urgent; list separately
4. Slack activity requiring response or decision

Limit to 3–5 items. Within each source, take only the highest-priority item unless two items are
materially different in urgency (e.g., two 🔥 tickets with different deadlines).
Do not pad with low-signal items. If signals are sparse,
close with: "Light day — consider using focus time for [top Jira item] or
strategic work."

Output:

```markdown
### Priorities Analysis

**No intentions written yet.** Based on your calendar, Jira, and Slack:

**Suggested priorities:**
1. [Calendar item] — scheduled, [prep note if applicable]
2. [🔥 Urgent Jira KEY-XXX] — [why urgent, e.g. High priority, assigned to you]
3. [⏰ Languishing Jira KEY-YYY] — [no update in N days, needs attention]
4. [Slack item] — [mention or VIP message requiring response]
```

**Edge cases:**
- Daily note not found → Branch B. Add note: "Daily note not found — no intentions to analyze."
- `## Today's Intentions` missing or only blank bullets → Branch B.
- Vague intention → ❓ icon: `❓ **[intention]** — Too vague to cross-reference. Consider rewriting as a specific outcome.`
- Ambiguous but not fully vague (intention names a domain or project, e.g., "work on auth", but not a specific outcome) → attempt cross-reference against that domain; ⚠️ if a weak match is found, 🚨 if none. Do not assign ❓ unless the intention has no domain at all.
- `## Daily Plan` already exists in file → replace entire section (existing behavior); this overwrites any existing `### Priorities Analysis`.

If the daily note doesn't exist, tell the user — they may need to create it
from their note template first.

After writing, confirm:
> "Your daily plan has been written to [filename]. Have a great day!"

---

## Troubleshooting

- **Auth**: The auth command must be run manually in a terminal — Claude cannot
  run interactive shell functions.
- **Slack mentions returning nothing**: Verify `{{SLACK_USER_ID}}` is correct.
  Use `mentions:USER_ID` syntax, not `to:me`.
- **Jira returns too many results**: Focus on 🔥 Urgent and 🆕 New first;
  summarize languishing items in a collapsed group.
- **Incidents channel is noisy**: Supplement channel read with a keyword search
  for `incident SEV after:{{YESTERDAY_DATE}}` to surface recent incidents.
