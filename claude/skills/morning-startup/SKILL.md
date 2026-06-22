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

**Heads up filter — manager-level only.** Only include an item under `⚠️ Heads up`
if it requires you to act or decide **as the head of infrastructure** (RSVP, resolve
a conflict, prepare for something exceptional, make a call only you can make). Do not
include IC-level operational status (tool hiccups, routine standups starting on time,
a meeting ending early). Test: _would you behave differently as the head of infrastructure
today because of this item?_ If no, omit it.

**1:1 detection.** Identify every 1:1 on today's calendar — a title containing "1:1",
a two-person pattern like "X / Y", "X <> Y", "X and Y", or any meeting with exactly two
attendees where one is you. Collect the list of 1:1 people (match each against the
`{{PERSON_SIGNAL_REGISTRY}}` to resolve their shortname). Do **not** write prep into the
Key Meetings table — the dedicated `## 1:1 Prep` section is produced by the Phase 2
meeting & 1:1 prep agent (see below). Just mark each 1:1 in the Notes column with
`1:1 — see 1:1 Prep` and pass the resolved 1:1 people list forward to that agent.

Produce a `### Calendar` section:

```
### Calendar

**Today at a glance:** [X meetings · Y hours of focus time]

**⚠️ Heads up / Unusual today:**
- [Only items requiring your action or decision as head of infrastructure — no IC operational noise]

**Key meetings:**

| Time | Event | Notes |
|------|-------|-------|
| 9:00 AM | Google Cloud sync | External; RSVP needed |
| 12:35 PM | 1:1 Jordan | 1:1 — see 1:1 Prep |

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

   Before surfacing any result: verify that `{{SLACK_USER_ID}}` appears literally in
   the message text, or the message is a direct reply to you in a thread you started.
   Drop false positives silently — do not list them.

2. **VIP DMs** — search for recent messages `from:{{VIP_SLACK_USERNAMES}}`
   using `slack_search_public_and_private`
3. **Incidents** — read the incidents/on-call channel from your config. Also search
   `incident SEV after:{{YESTERDAY_DATE}}` to catch recent `inc-*` channels created
   overnight — the main incidents channel can be noisy with old bot posts.

   **⚠️ Lifecycle re-posts are NOT new incidents.** The incident.io bot re-posts an
   incident's full summary on every status change — "Incident updated", "Incident
   resolved", or a transition like `Reviewing → Closed`. These re-posts embed impact
   times like *"began at 21:14 UTC"* **with no date**, so a re-post that fires today
   looks exactly like a fresh overnight outage even when the incident is days or weeks
   old and already closed. The `incident SEV after:` search surfaces them because the
   *message* timestamp is recent, not the *incident*. Before you badge anything as
   new / active / overnight:
   - Read the message body's **status line**. If it shows `Closed`, `Resolved`,
     `Documenting`, `Reviewing`, or any `→` transition, treat it as a lifecycle
     re-post, not a new event.
   - **Verify the incident's real `reported_at`/`created_at` via the incident.io MCP**
     (`incident_list` query by name, or `incident_show`) rather than trusting the Slack
     post's recency. Only badge incidents whose `reported_at` falls inside the briefing
     window (since yesterday). When in doubt, look it up — never infer the date from the
     undated impact times in the summary text.

   **Incident badge and filter rules.** Assign each active incident one badge, in
   priority order:
   - `[LEAD]` — you are the incident lead or comms lead
   - `[FOLLOW-UP]` — you have an open follow-up Jira ticket linked to this incident
   - `[ADJ]` — the incident involves infrastructure you own: GCP, Kubernetes, Mongo/
     datastores, networking, compute, CI/CD, or any service owned by your team — even
     if another team leads the incident
   - `[WATCH]` — SEV-1 or SEV-2 company-wide with none of the above

   **Show** any incident that earns a badge. SEV-1 and SEV-2 always earn at least
   `[WATCH]`. Show SEV-3 only if it earns `[LEAD]`, `[FOLLOW-UP]`, or `[ADJ]`.
   **Collapse** all other active incidents to a single line: `N other active incidents
   — no infra involvement`. **Omit the incidents block entirely** (not even a header)
   if zero incidents earn a badge.

   Format for shown incidents:
   ```
   [BADGE] INC-XXXX · SEV-N · Short name · Day N · status
     → [your role / open follow-up key / affected infra services]
   ```

4. **Monitored channels** — read each channel from your `{{SLACK_CHANNELS}}`
   config table; summarize what's worth reading.

   **Channel highlight filter — manager-level only.** Surface only items you need to
   act on or be aware of as the head of infrastructure. Skip IC-level operational status
   (engineers handling their own work, transient tool hiccups, PR activity not requiring
   your review or decision). Test: _would you act differently as head of infrastructure
   because of this item?_

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
- [verified mention description] — [link]

**💬 VIP Activity:**
- [Person]: [summary] — [link]

**🚨 Incidents:**
[LEAD] INC-001 · SEV-3 · Storage capacity · Day 14 · documenting
  → lead: you · open follow-ups: INFR-101, INFR-102
[ADJ] INC-002 · SEV-2 · Dashboard 500s · Day 4 · mitigating
  → infra: K8s deploy pipeline affected
2 other active incidents — no infra involvement

**📣 Channel Highlights:**
- [#channel]: [management-level signal only] — [link]
```

Omit any category where there's nothing to report, or note "Nothing new."
Omit the Incidents block entirely if no incident earns a badge.

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

**Today needs from you (as Head of Infrastructure):**
[One synthesis sentence answering "what does today need from me as the head of
infrastructure?" — specific and actionable, naming 2–3 things maximum. Draw from
everything gathered: unresolved RSVP/calendar decisions that must happen before the
day progresses, new high-priority or Blocked Jira interrupts needing routing, any
incident requiring your action (especially `[LEAD]`/`[ADJ]`), any 1:1 person whose
signal warrants a conversation today, and the carry-forward from yesterday's work note.
Example: "Today needs: RSVP the 2 PM Google sync, route INFR-456 to the on-call owner,
and ask Jordan about the migration cutover in your 1:1." If nothing is urgent, say so:
"Quiet day — protect the afternoon focus block and prep for Thursday's review."]

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

After writing the work note, hold **Today needs from you (as Head of Infrastructure)**,
**The One Thing**, and **One Question** values verbatim in memory — you will copy them
into Step 5.

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

**Today needs from you (as Head of Infrastructure):** [verbatim from Step 4 coaching]

**The One Thing:** [verbatim from Step 4 coaching]

**One Question:** [verbatim from Step 4 coaching]

---

```

If the personal daily note doesn't exist, tell the user — they may need to
create it from their note template first.

After writing both files, confirm:
> "Phase 1 complete — work note and journal updated. Starting deep prep…"

---

## Phase 2: Deep Prep

Once Step 5 is complete, run the meeting & 1:1 prep agent.

When building the agent's prompt, substitute all `{{CONFIG_TOKEN}}` values with the
actual resolved values from `config.md`. The agent runs in a fresh context without access
to `config.md`.

Note: this routine does **not** draft Slack replies. Surfacing *what* needs a reply is
handled in Step 3b (the `🔴 Action Required (Mentions)` section of the work note) —
deciding and writing the replies is left to you.

---

### Phase 2: Meeting & 1:1 Prep Agent

Dispatch an Agent with description `"Prepare meeting and 1:1 notes for today"`.

Build the following prompt, substituting real values for all `{{}}` tokens and inserting
the actual meeting list gathered in Step 3a (including the resolved 1:1 people list):

```
You are preparing meeting notes and 1:1 prep for a morning startup routine. The user
is the Head of Infrastructure — frame all prep at the manager/leadership level, not
the IC level.

**Your context (all values are real — use them directly):**
- Today's date: [today YYYY-MM-DD]
- Seven days ago: [YYYY-MM-DD]
- Jira cloud ID: {{JIRA_CLOUD_ID}}
- Jira base URL: {{JIRA_BASE_URL}}
- Today's work note path: [full path, e.g. ~/Documents/Personal/Work/2026/05-May/2026-05-13.md]
- Signal cache directory: ~/.claude/signal-cache/  (one JSON file per person, named {shortname}.json)

**Today's meetings (from Phase 1 calendar — do not re-fetch):**
[insert each meeting entry from the Phase 1 Calendar section:
 time, title, attendees list with names/emails, meeting link if available]

**Today's 1:1s (resolved in Step 3a — prep these specially, see "1:1 PREP" below):**
[insert each 1:1: time, title, person display name, person shortname (or "unregistered"),
 person Slack username, person GitHub handle if known]

**VIPs — flag any unresolved items explicitly:**
[insert {{VIP_NAMES}} from config]

---

**Skip the following meetings entirely — do not write prep notes for them:**
- Focus time blocks or "No meetings" blocks
- Events whose title starts with "❇️" or whose description contains "Clockwise"
- Events with only one attendee (solo blocks, personal reminders)

---

## 1:1 PREP (do this first, for each 1:1 person above)

For each 1:1, build manager-level prep grounded in that person's signal cache.

**Step 1:1-A — Read the signal cache.**
Read `~/.claude/signal-cache/{shortname}.json` if the person is registered.
- If it exists: load `jira_active`, `prs_open`, `pr_volume_7d`, `recent_context`,
  `known_context`, and note `last_updated`.
- If it does not exist (or the person is unregistered): you'll build a fresh one from
  live signals in the next step, and note "no prior cache — first capture" in the prep.

**Step 1:1-B — Gather fresh signals (live).**
- Jira: resolve the person's account ID first with `lookupJiraAccountId` (by display name),
  then `searchJiraIssuesUsingJql` with cloudId {{JIRA_CLOUD_ID}}, JQL:
  `assignee = "[accountId]" AND statusCategory != Done ORDER BY updated DESC`.
  Identify stuck tickets (no update in 7+ business days, or status Blocked).
- Slack: `slack_search_public_and_private` query `from:[slack-username] after:[seven-days-ago]`
  for recent decisions, blockers, or unresolved threads.
- (Optional) PR volume: if a GitHub handle is known and the `gh` CLI is available, count
  merged + open PRs in the last 7 days. Skip silently if unavailable.

**Step 1:1-C — Refresh the cache.**
Write `~/.claude/signal-cache/{shortname}.json` (create the directory if missing),
following the schema in the signal-person skill. Set `last_updated` to now and
`last_updated_by` to `"morning-startup"`. Preserve any `known_context` and richer fields
written by the signal-person skill — only overwrite the lightweight signals you gathered.
Skip the write only for unregistered people (no shortname to key the file on).

**Step 1:1-D — Produce the prep.** For each 1:1, answer the central question:
**"What does this person need from me today?"** Ground every line in the signals — never
generic. Cover:
- **What they need from me:** the single most useful thing you can give them today —
  a decision, an unblock, air cover, recognition, or a course-correction. Be specific.
- **Stuck / open:** the most relevant stuck ticket (key + short summary + days stuck), or
  "no stuck tickets" if clean.
- **One question:** one specific question to ask, derived from the signal data.
- **Watch:** optional — any signal worth noting (PR volume spike/drop, Jira going stale
  while PRs merge, a thread that stalled).

---

**For each real (non-skipped) meeting that is NOT a 1:1, do the following:**

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

Open [today's work note path]. Write TWO sections. For each, if it already exists in
the file replace it entirely; otherwise append it at the end of the file. Write
`## 1:1 Prep` before `## Meeting Prep`.

First, the 1:1 section (omit entirely if there are no 1:1s today):

## 1:1 Prep

### [HH:MM AM/PM] — 1:1 [Person Name]

**What they need from me:** [the single most useful thing you can give them today —
specific, grounded in signals]

**Stuck / open:** [[KEY-123]]({{JIRA_BASE_URL}}KEY-123) — [summary], stuck [N] bd
(or "no stuck tickets"). [If first run: "no prior cache — first capture."]

**One question:** [specific question derived from the signals]

**Watch:** [optional signal worth noting, or omit the line]

[repeat the ### block for each 1:1]

Then the meeting section (omit entirely if every meeting was a 1:1 or skipped):

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

[repeat the ### block for each non-1:1, non-skipped meeting]

---

**When complete, return ONLY this one-line summary (no other output):**
"Prepped N 1:1s (cache refreshed), N meetings, skipped N (focus/Clockwise/solo blocks)"
```

---

### Phase 2 Summary

After the agent completes, print the following (substituting the agent return summary):

```
## Morning Prep Complete

✅ Meeting & 1:1 Prep: [paste Meeting & 1:1 Prep agent return summary here] → Work Day note updated

Anything that needs your reply is flagged under 🔴 Action Required in the work note.
```

If the agent failed or returned an error: replace ✅ with ⚠️ and describe the
error in place of the return summary. If the agent timed out, note "agent timed out —
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
- **An "incident" looks new but might be old**: incident.io re-posts the full summary
  on every status change (incl. auto-close), with undated impact times that read like a
  fresh overnight outage. Check the status line and verify `reported_at` via the
  incident.io MCP before badging it — see the lifecycle re-post guard in Step 3b.3.
- **Notes don't exist**: Skip silently and proceed without that context. Don't
  block on missing notes.
- **Work note directory doesn't exist**: Create it silently before writing the
  file. The path `Work/YYYY/MM-MonthName/` may not exist on the first run.
- **Signal cache empty or missing**: On first run, no `~/.claude/signal-cache/`
  exists. The Phase 2 meeting & 1:1 prep agent creates it and captures fresh signals — 1:1 prep that
  day notes "first capture." Caches fill in and get richer over subsequent runs (and
  via the `signal-person` skill). Unregistered 1:1 people are prepped from live signals
  but not cached (no shortname to key on) — add them to `{{PERSON_SIGNAL_REGISTRY}}`
  in `config.md` to start caching them.

---

## Morning Startup Skill

- Always verify Slack MCP tools are available BEFORE starting context gathering; if unavailable, note this upfront rather than mid-flow
- When user mentions calendar items, treat each meeting as independent unless explicitly linked (e.g., don't assume Monday prep relates to Wednesday meetings)
- After verbally updating priorities or plans, ALWAYS write the changes to today's note immediately—don't wait to be asked
