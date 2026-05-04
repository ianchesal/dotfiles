# Design: Morning Startup — Work Note Split

**Date:** 2026-05-04
**Status:** Approved

## Problem

The morning-startup skill currently writes all work context (Calendar, Slack, Jira, Executive Coaching) directly into the personal daily journal note. As the briefing has grown, this pollutes the personal journal with work noise. The user wants the two streams kept separate.

## Goal

- Work content (Calendar, Slack, Jira, Executive Coaching) lives in a dedicated work daily note.
- Personal daily journal gets a slim stub: a wikilink to the work note + The One Thing + One Question from coaching.
- Yesterday's work daily note is read alongside yesterday's personal note to give the coaching richer continuity.
- A template for the work daily note type is committed to the Obsidian vault.

---

## File Locations

| Note type | Path |
|-----------|------|
| Personal daily note | `~/Documents/Personal/Daily/YYYY/MM-MonthName/YYYY-MM-DD.md` |
| Work daily note | `~/Documents/Personal/Work/YYYY/MM-MonthName/YYYY-MM-DD.md` |
| Obsidian templates | `~/Documents/Personal/Extras/Templates/` |

**Wikilink strategy:** Both note types share the same filename (`YYYY-MM-DD.md`), so bare wikilinks are ambiguous in Obsidian. Always use full-path wikilinks when linking from personal → work:
`[[Work/2026/05-May/2026-05-04|Work Day - 2026-05-04 →]]`

---

## Skill Steps (Clean Rewrite)

### Step 1: Read Context from Notes

Read all three notes silently before gathering external data.

**Yesterday's personal note** (`Daily/YYYY/MM-MonthName/YYYY-MM-DD.md`):
- Extract: mood, energy signals, what got done, what carried forward, personal context.

**Today's personal note** (`Daily/YYYY/MM-MonthName/YYYY-MM-DD.md`):
- Extract: any intentions already written, todos, notes captured before startup.

**Yesterday's work note** (`Work/YYYY/MM-MonthName/YYYY-MM-DD.md`):
- Extract: work carries-forward, Jira state, unresolved incidents, decisions made.
- If it doesn't exist, skip silently.

Hold all context. Use it in Step 3 to ground coaching in both personal state and work continuity.

### Step 2: Gather Data (Run in Parallel)

Unchanged from the current skill. Gather Calendar, Slack, and Jira simultaneously.

See existing SKILL.md sections 2a, 2b, 2c for full details.

### Step 3: Write Work Daily Note

**Path:** `~/Documents/Personal/Work/YYYY/MM-MonthName/YYYY-MM-DD.md`

**Behavior:** Create if missing. Replace if it already exists.

**Structure:**

```markdown
# Work Day - YYYY-MM-DD

## Calendar

[full calendar content — Today at a glance, Key meetings table, Focus time, Lunch window]

## Week Ahead         ← Monday only

[week coaching table and prepare-now flags]

## Slack

[full slack content — Mentions, VIP Activity, Incidents, Channel Highlights]

## Jira

[full jira table]

## Executive Coaching

**Today's Shape:**
[2–3 sentences on the texture of today]

**The One Thing:**
[Single most important thing to move forward today]

**Watch Out For:**
[1–3 specific, concrete observations with real data references]

**Energy & Wellbeing:**
[Based on personal note context and yesterday's note]

**One Question:**
[A single sharp coaching question specific to today]
```

### Step 4: Write Personal Note Stub

Find `## Random Notes` in today's personal daily note. Insert `## Work Day` **above** it.

If `## Work Day` already exists, replace it.

**Content:**

```markdown
## Work Day

[[Work/YYYY/MM-MonthName/YYYY-MM-DD|Work Day - YYYY-MM-DD →]]

**The One Thing:** [copied verbatim from Step 3 coaching]

**One Question:** [copied verbatim from Step 3 coaching]

---

```

After writing, confirm:
> "Your daily plan has been written. Personal note updated, work note at `Work/YYYY/MM-MonthName/YYYY-MM-DD.md`. Have a great day!"

---

## Config Changes

Add a new section to `config.md`:

```markdown
## Work Daily Notes

- **Path**: `~/Documents/Personal/Work/`
- **Structure**: `YYYY/MM-MonthName/YYYY-MM-DD.md`
- **Title format**: `Work Day - YYYY-MM-DD`
```

---

## Obsidian Template

**File:** `~/Documents/Personal/Extras/Templates/Template, Work Daily Note.md`

Follows the same Templater format as `Template, Daily Note.md`. No prev/next nav links — navigation to work notes happens via wikilinks from the personal journal.

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

---

## What Does NOT Change

- Step 2 (Calendar, Slack, Jira gathering) is unchanged.
- The Executive Coaching format and quality bar are unchanged — full coaching lives in the work note.
- The personal note anchor (`## Random Notes`) is unchanged.
- All config values not related to work daily notes are unchanged.

---

## Out of Scope

- Prev/next navigation links in work daily notes.
- Any changes to the daily-wrap or sentiment-analysis skills.

## Implementation Notes

- The skill must create the work note directory path (`Work/YYYY/MM-MonthName/`) if it doesn't already exist before writing the file. This is not a separate user-facing step — it happens silently as part of Step 3.
