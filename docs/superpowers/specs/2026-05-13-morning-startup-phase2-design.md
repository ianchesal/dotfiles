# Design: Morning Startup Phase 2 — Deep Prep

**Date:** 2026-05-13
**Skill:** `morning-startup`
**File:** `claude/skills/morning-startup/SKILL.md`

## Problem

The morning-startup skill produces a solid situational briefing (Phase 1) but stops short of
actionable prep work. Two recurring friction points remain after the briefing:
- Slack @-mentions and unanswered threads accumulate without drafted responses
- Meetings arrive without attendee context, relevant Jira items, or talking points

## Goal

After Phase 1 completes, automatically run two prep agents in parallel and deliver a final
summary of what's ready for review — without sending or posting anything.

## Scope

**In scope:**
- Slack draft replies agent (mentions + unanswered threads)
- Meeting prep agent (attendee context, Jira, talking points)

**Out of scope:**
- PR code review agent (dropped — too noisy given EM role)
- Automatically posting or sending anything
- Phase 2 running independently of Phase 1

---

## Architecture

Phase 2 is a new `## Phase 2: Deep Prep` section in `SKILL.md`, placed immediately after
the existing Step 5 (personal journal stub). It runs automatically once Step 5 completes.

Claude dispatches two Agent tool calls **in parallel**, passing Phase 1 context (meeting list
from Step 3a, mentions list from Step 3b) in each agent's prompt — no re-fetching. Both
agents run concurrently. Claude waits for both, then prints the final summary.

**Error handling:** If one agent fails, the other's results are still surfaced. Phase 2 never
blocks on a single agent failure.

---

## Agent 1: Slack Drafts

### Inputs (from Phase 1 context)
- @-mentions list from Step 3b
- Monitored channels list from config
- Slack user ID (`{{SLACK_USER_ID}}`)

### Process

**Pass 1 — @-mentions:**
For each mention thread already found in Phase 1, read the full thread via
`mcp__claude_ai_Slack__slack_read_thread`. Draft a contextual reply. Skip purely
informational threads (announcements, FYIs where no response is expected) — mark those
"no reply needed."

**Pass 2 — Unanswered threads:**
Search monitored channels for threads where the user posted but received replies in the
last 24 hours without a follow-up from the user. Use
`mcp__claude_ai_Slack__slack_search_public_and_private` with `from:{{SLACK_USER_ID}}`
plus date filter. Read each candidate thread and check whether a reply is pending.

### Output

Written to `~/Documents/Personal/Work/inbox/YYYY-MM-DD-slack-drafts.md`.
The inbox directory is created silently if it doesn't exist. File is overwritten if re-run
the same day.

```markdown
# Slack Draft Replies — YYYY-MM-DD

## @Mentions Needing Response

### #channel — [thread summary]
**Link:** [slack:// deeplink]
**Context:** [1-2 sentence thread summary]
**Draft:**
> [draft reply text]
**Status:** Ready to post | Needs your input

## Threads Awaiting Your Response

### #channel — [thread summary]
**Link:** [slack:// deeplink]
**Context:** [1-2 sentence thread summary]
**Draft:**
> [draft reply text]
**Status:** Ready to post | Needs your input

## No Reply Needed
- #channel: [thread summary] — informational only
```

---

## Agent 2: Meeting Prep

### Inputs (from Phase 1 context)
- Today's meeting list with attendees from Step 3a
- VIP names from config (`{{VIP_NAMES}}`)
- Jira cloud ID from config

### Process

**Skip criteria:** Focus time blocks, Clockwise-managed blocks (identified by "❇️" prefix or
Clockwise description links), and events with only one attendee (solo blocks).

For each real meeting:

1. **Attendee context** — search Slack (last 7 days) for DMs and channel threads involving
   each attendee using `mcp__claude_ai_Slack__slack_search_public_and_private`. For VIPs,
   flag any unresolved items explicitly.

2. **Jira context** — search for open tickets whose summary or description relates to the
   meeting title or attendee names using `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql`
   with cloud ID `{{JIRA_CLOUD_ID}}`.

3. **Talking points** — generate exactly 3 specific, context-grounded talking points anchored
   in what was found (Jira tickets, open Slack threads, pending decisions). If no context is
   found, generate reasonable inferences from the meeting title and attendees — note "no
   recent context found."

### Output

Append a `## Meeting Prep` section to today's work daily note (after existing content).
If a `## Meeting Prep` section already exists (re-run), replace it.

```markdown
## Meeting Prep

### HH:MM AM/PM — [Meeting Title]

**Attendees:** [Name, Name (+N)]

**Context:**
- [Person]: [relevant recent Slack activity or "no recent context"]
- [KEY-123](url): [Jira ticket summary] — [status/age]

**Talking Points:**
1. [specific, context-grounded point]
2. [specific, context-grounded point]
3. [specific, context-grounded point]
```

---

## Final Summary

After both agents complete, print:

```
## Morning Prep Complete

✅ Slack Drafts: N threads drafted → ~/Documents/Personal/Work/inbox/YYYY-MM-DD-slack-drafts.md
✅ Meeting Prep: N meetings prepped → Work Day note updated

[⚠️ Agent name: error description — if any agent failed]

Nothing has been sent or posted. Review and act when ready.
```

If both agents fail, still print the summary with ⚠️ entries for each.

---

## Config Changes

No changes to `config.md` required. The inbox path is derived from the existing
`{{WORK_NOTES_PATH}}`:

```
~/Documents/Personal/Work/inbox/YYYY-MM-DD-slack-drafts.md
```

If the user wants to customize the inbox path in the future, a `{{INBOX_PATH}}` config
key can be added — but this is out of scope for this implementation.

---

## Implementation Notes

- Phase 2 section is placed in SKILL.md after Step 5, before the Troubleshooting section
- Phase 1 step numbering (Steps 0–5) is unchanged
- The Agent tool dispatches are triggered by the skill instructions — no code changes needed
- Both agent prompts must be self-contained (include all context they need inline, not by
  reference to "earlier in the skill")
- Meeting Prep agent should process meetings sequentially within the agent (each meeting
  requires its own Slack + Jira lookups) but the agent itself runs in parallel with Slack Drafts
