---
name: morning-feedback
description: Use when Ian wants to process the feedback he left as Notion comments on his Daily Startup briefing pages and turn it into changes to the morning-startup skill — "process my briefing feedback", "read my morning-startup comments", "apply my Daily Startup feedback", "go through my briefing comments". Manual only; the morning briefing itself never reads comments.
---

# Morning Feedback

Ian reads each Daily Startup page in Notion and leaves comments on it for the AI, either
inline on the passage that is wrong or at page level. This skill reads the comments he
hasn't had handled yet and proposes one small edit per comment to the morning-startup
skill. It applies only what he approves, commits, deploys, and replies in Notion so
each page records what its feedback changed.

Design: `docs/superpowers/specs/2026-11-17-morning-feedback-design.md`.

**Files this skill edits:**

| File | Holds | In git? |
|------|-------|---------|
| `home/dot_claude/skills/morning-startup/SKILL.md` | general behaviour rules | yes, **public repo** |
| `home/dot_claude/skills/morning-startup/config.example.md` | structure of config, generic placeholders only | yes, public |
| `~/.claude/skills/morning-startup/config.md` | anything identifying: people, vendors, channels, figures, internal projects | **no** (machine-local) |

Repo paths are relative to `git rev-parse --show-toplevel`. Run from the dotfiles repo
or one of its worktrees; if not inside it, stop and say so.

## Step 1: Preflight

1. Read `~/.claude/skills/morning-startup/config.md` and take
   `NOTION_STARTUP_DATA_SOURCE` (a `collection://<uuid>`). If the file or value is
   missing, stop and say which.
2. Probe Notion with `notion-fetch` on that data source. If the tool is missing or auth
   fails, stop: "❌ Notion isn't reachable — [diagnosis]. Fix it and re-run."
3. `git status --porcelain`. Note any files already dirty: you must never stage them
   later. If `morning-startup/SKILL.md` or `config.example.md` is already dirty, stop
   and ask, because your edits would mix with Ian's.
4. Lookback: 14 days unless Ian gave a number ("last 30 days") or a date.

## Step 2: Find pages

`notion-query-data-sources` in `sql` mode:

```sql
SELECT url, "Day", "date:Entry Date:start" AS d
FROM "<NOTION_STARTUP_DATA_SOURCE>"
WHERE "date:Entry Date:start" >= '<today minus lookback, YYYY-MM-DD>'
ORDER BY "date:Entry Date:start" ASC
```

No pages → report "No Daily Startup pages in the last N days." and stop.

## Step 3: Find unhandled discussions

For each page, `notion-get-comments` with `page_id` = the page URL (unresolved only, the
default). Call them in parallel. A page with no discussions returns only
`{"suggested_edits_status": ...}`, with no `<discussion>` elements. If a response has `shown-count` < `total-count`, fetch each
`<omitted-discussion>` by `discussion_id`; if a discussion has `next-cursor`, page
back until there is none. You need whole threads.

A discussion is **unhandled** when its **newest** comment is not `by-you="true"`. So:
- no Claude reply yet → unhandled
- Claude replied, then Ian answered back ("no, that's not it") → unhandled again; read
  the whole thread, because the newest comment is a correction to the last change
- newest comment is Claude's → handled; skip it

Nothing unhandled on any page → report "No unhandled feedback across N pages." and
stop. Touch nothing else: no git, no chezmoi.

## Step 4: Read the anchors

For each page with unhandled discussions, `notion-fetch` the page with
`include_discussions: true`. Match each `discussion://` URL to the block it is anchored
in and keep a short excerpt (about 200 chars) of that passage. Judge the comment against
that passage. "Wrong" on an incident line means the incident line, not the page.
Page-level discussions have no anchor; say so.

## Step 5: Route and propose

Read `home/dot_claude/skills/morning-startup/SKILL.md` and the live `config.md` once.
For each unhandled discussion, decide one outcome:

- **SKILL.md rule.** A general behaviour change: what to include, how to badge, how to
  verify, tone, layout. Grep SKILL.md for the topic first. If a rule already covers
  it, **tighten that rule** rather than adding a second one. Keep the edit as small as
  the feedback. One comment never justifies restructuring a section.
- **config.md entry.** Anything naming a person, vendor, channel, figure, customer or
  internal project, even when the *rule* is general ("don't badge SEV-3s owned by
  <team lead>"). Split it if needed: a generic rule in SKILL.md that refers to a config
  list, plus the specific names in config.md.
- **New config key or section.** Also add it to `config.example.md` with a generic
  placeholder and example. **Never copy Ian's real value into the example.**
- **No change.** A note to self, a question, or something already fixed by an earlier
  comment in this pass. Give the reason.

Leakage check on every SKILL.md and config.example.md diff: no real names, Slack or
Jira IDs, emails, dollar figures, customer names or internal hostnames. If one is in
there, move it to config.md.

## Step 6: Review with Ian

Show every proposal in one message, oldest page first:

```
### 1. <page date> — "<comment text>"
Anchor: "<excerpt>" (or: page-level)
Thread: <only if it has earlier replies: one line summary>
→ SKILL.md | config.md | config.example.md | no change
<the diff, or the reason>
```

Ask Ian to approve, edit or skip each one ("all", "1,3", "skip 2", "for 4 do X
instead"). **Skipped items get no reply in Notion**, so they come back next pass.

## Step 7: Apply and commit

Apply the approved edits. Then stage **only** the repo files this pass edited, never
files that were dirty at preflight. Commit once:

```
Apply briefing feedback to morning-startup

- <date>: <one-line summary of change> (<file>)
- ...
```

Use the attribution trailer the session specifies. config.md changes are not
committed; they are machine-local by design. No repo files changed → no commit.

## Step 8: Deploy

If the commit touched `home/dot_claude/skills/morning-startup/`, run
`chezmoi --source "$(git rev-parse --show-toplevel)" diff ~/.claude/skills/morning-startup`
and show the result. On Ian's yes, run the same command with `apply` in place of
`diff`. Always pass `--source`: from a worktree, chezmoi otherwise reads main's
source state. Keep it scoped to that path. config.md is unmanaged by chezmoi, so apply
leaves it alone.

## Step 9: Reply in Notion

For each approved or no-change item, `notion-create-comment` with `page_id` and
`discussion_id`, one line:

- `Updated morning-startup SKILL.md: <summary> (commit <short hash>)`
- `Updated config.md (local, <hostname>): <summary>`
- `No change: <reason>`

That reply is what marks the discussion handled.

## Step 10: Resolve on request

Ask once: "Resolve these N discussions in Notion?" Only on an explicit yes, call
`notion-set-discussion-resolved` with `resolved: true` for each discussion you replied
to. Without a yes, leave them open. They are already marked handled by the reply.

## Finish

Summarise: pages scanned, discussions handled, changes made per file, the commit hash,
whether chezmoi applied, and anything skipped (which comes back next pass).
