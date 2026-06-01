---
name: signal-person
description: Use when the user wants a deep read on one person they manage or work with — to prep for a 1:1, a performance conversation, or to refresh a teammate's signal cache. Triggers on phrases like "signal <name>", "what's going on with <name>", "prep me on <name>", "how is <name> doing", "refresh <name>'s signals", or "/signal-person <name>". Gathers Jira, GitHub PR, and Slack signals for the person, synthesizes a manager-level picture, and writes/enriches their signal cache at ~/.claude/signal-cache/{shortname}.json. The morning-startup skill reads and lightly refreshes the same cache during daily 1:1 prep; this skill is the deeper, on-demand analysis and the owner of the cache schema.
---

# Signal Person

A companion to `morning-startup`. It builds a manager-level picture of one person and
persists it to a per-person **signal cache** that morning-startup reuses for fast daily
1:1 prep. Run it ad hoc — before an important 1:1, a quarterly review, or whenever a
person's cache feels stale.

The central question this skill answers is: **"What does this person need from me, and
what should I be paying attention to?"**

---

## Before You Start: Resolve the Person

The person registry lives in the morning-startup config (single source of truth):
`~/.claude/skills/morning-startup/config.md` → the **1:1 People — Signal Registry** table.

Given the user's input (a name or a shortname):
- Match it against the registry to resolve: **shortname**, **display name**,
  **Slack username**, **GitHub handle** (optional), and **work email** if present.
- If the person is **not** in the registry: proceed using whatever identifiers you can
  infer (name → Slack/Jira lookup), but tell the user they aren't registered and offer
  to add a row to the registry so future caching is automatic. Without a shortname you
  cannot key a cache file — ask the user for one before writing.

If `config.md` is missing, tell the user to set up morning-startup first (it owns the
registry), then stop.

---

## Step 1: Gather Signals (Run in Parallel)

Gather all sources simultaneously. The user is a manager — read everything at the
leadership level, not the IC level.

### 1a. Jira
Resolve the person's account ID with `mcp__claude_ai_Atlassian__lookupJiraAccountId`
(by display name), then use `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql` with the
cloud ID from morning-startup config. JQL:
`assignee = "[accountId]" AND statusCategory != Done ORDER BY updated DESC`

For each active issue capture: key, summary, status, priority, days since last update.
Flag **stuck** = no update in 7+ business days, or status is Blocked.

### 1b. GitHub PRs (optional — needs a GitHub handle and the `gh` CLI)
If a handle is known and `gh` is available:
- Open PRs authored by them: `gh search prs --author <handle> --state open`
- Merged in the last 7 days: `gh search prs --author <handle> --merged --created '>=[7d ago]'`
Capture: open PR list (repo, number, title, age, draft?) and `pr_volume_7d` (merged+open count).
If unavailable, skip silently and leave PR fields unchanged from any prior cache.

### 1c. Slack
`mcp__claude_ai_Slack__slack_search_public_and_private` query
`from:[slack-username] after:[7 days ago]`. Look for: blockers raised, decisions made,
unresolved threads, sentiment. Summarize at the manager level — skip routine status chatter.

---

## Step 2: Synthesize

Produce a short manager-level read:
- **What they need from me:** the single most useful thing the user can give this person
  right now — a decision, an unblock, air cover, recognition, a course-correction.
- **Watch:** patterns worth attention — e.g. Jira going stale while PRs keep merging
  (tracking hygiene), a blocker that's been raised twice, a drop in activity.
- **One question:** a specific question to ask in the next 1:1, grounded in the signals.

Never generic. Every line cites a ticket, PR, or thread.

---

## Step 3: Write the Cache

Create `~/.claude/signal-cache/` if it doesn't exist. Write
`~/.claude/signal-cache/{shortname}.json`.

**Merge, don't clobber.** If a cache already exists, preserve durable fields
(`known_context`, and `what_they_need` unless your analysis updates it). Overwrite the
freshly-gathered signal fields. Set `last_updated` to now (ISO 8601) and
`last_updated_by` to `"signal-person"`.

### Canonical cache schema

This skill owns the schema. `morning-startup` reads it and lightly refreshes the signal
fields during daily 1:1 prep (writing `last_updated_by: "morning-startup"`), but
preserves the durable fields below.

```json
{
  "shortname": "jordan",
  "display_name": "Jordan Smith",
  "slack_username": "jordan",
  "github_handle": "jsmith",
  "work_email": "jordan@example.com",

  "last_updated": "2026-06-01T08:30:00-04:00",
  "last_updated_by": "signal-person",

  "jira_active": [
    {
      "key": "INFR-123",
      "summary": "Migrate datastore to new cluster",
      "status": "In Progress",
      "priority": "High",
      "days_since_update": 10,
      "stuck": true
    }
  ],
  "prs_open": [
    { "repo": "persona/infra", "number": 42, "title": "Bump node pool", "age_days": 3, "draft": false }
  ],
  "pr_volume_7d": 9,
  "recent_context": "Merged 9 PRs last week; INFR-123 stale 10 bd despite active PRs.",

  "known_context": "Leads the compute migration. Prefers async written updates.",
  "what_they_need": "A decision on the migration cutover date."
}
```

**Durable fields** (manager-maintained, preserved across refreshes): `known_context`,
`what_they_need`. **Signal fields** (refreshed on every run): `jira_active`, `prs_open`,
`pr_volume_7d`, `recent_context`, `last_updated*`.

---

## Step 4: Report

Print a concise summary to the user:

```
## Signal: [Display Name] ({shortname})

**What they need from you:** [one specific thing]

**Stuck / open:**
- [KEY-123] [summary] — stuck [N] bd
- (or "no stuck tickets")

**Activity:** [N] PRs merged last week · [N] open PRs · [Slack one-liner]

**One question for your next 1:1:** [grounded question]

**Watch:** [optional pattern]

_Cache updated → ~/.claude/signal-cache/{shortname}.json_
```

---

## Notes

- This skill and `morning-startup` share one cache. Running either keeps it current;
  this one goes deeper and is the schema authority.
- Keep `~/.claude/signal-cache/` out of any synced/committed location — it contains
  per-person work signals. It lives under `~/.claude/`, which is runtime state.
- Add new people to the registry in `morning-startup/config.md` so their caches are
  keyed consistently and picked up automatically in daily 1:1 prep.
