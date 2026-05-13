---
name: morning-startup
description: Use when the user wants to start their workday, get a morning briefing, or says things like "start my day", "morning startup", "good morning", "what's on my plate today", "morning briefing", or "let's get the day started". This skill reads context from yesterday's personal and work notes, gathers context from Calendar, Slack, and Jira in parallel, writes a full Work Daily Note, and places a slim briefing stub with executive coaching highlights into today's personal journal. Invoke whenever the user signals they are beginning their workday.
---

# Morning Startup

This skill helps you start your workday by:
1. Checking all data sources are available (preflight check)
2. Reading context from yesterday's and today's notes (personal and work)
3. Gathering today's context from Calendar, Slack, and Jira in parallel
4. Writing a full Work Daily Note with all work context
5. Writing a slim `## Work Day` stub (wikilink + coaching highlights) into today's personal journal

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

## Step 2: Read Context from Notes

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

## Step 3: Gather Context (Run in Parallel)

Gather all three data sources simultaneously. Do NOT wait for one to finish before
starting the others.

### 3a. Google Calendar

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

### 3b. Slack — Unread Messages Triage

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

### 3c. Jira — Assigned Issues

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

## Step 4: Write Work Daily Note

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
verbatim in memory — you will copy them into Step 5.

---

## Step 5: Write Personal Journal Stub

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
> "Phase 1 complete — work note and journal updated. Starting deep prep…"

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

---

## Morning Startup Skill

- Always verify Slack MCP tools are available BEFORE starting context gathering; if unavailable, note this upfront rather than mid-flow
- When user mentions calendar items, treat each meeting as independent unless explicitly linked (e.g., don't assume Monday prep relates to Wednesday meetings)
- After verbally updating priorities or plans, ALWAYS write the changes to today's note immediately—don't wait to be asked
