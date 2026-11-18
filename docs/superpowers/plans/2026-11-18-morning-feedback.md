# morning-feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A project-scoped Claude skill that turns Ian's Notion comments on Daily Startup pages into reviewed edits to the morning-startup skill.

**Architecture:** One prose skill, `.claude/skills/morning-feedback/SKILL.md`, driving Notion MCP tools, file edits, git and chezmoi. It has no code and no scripts, so the "test" is a read-only dry run against the live Notion database.

**Tech Stack:** Claude Code skill (Markdown + YAML frontmatter), Notion MCP, git, chezmoi.

**Spec:** `docs/superpowers/specs/2026-11-17-morning-feedback-design.md`

## Global Constraints

- Lives in `.claude/skills/morning-feedback/` (repo root, project-scoped, not chezmoi source state)
- Data source ID comes from `~/.claude/skills/morning-startup/config.md` → `NOTION_STARTUP_DATA_SOURCE`. Never hardcode it (public repo)
- Default lookback is 14 days, and an argument can override it
- Unhandled = an unresolved discussion whose newest comment is not `by-you="true"`
- Identifying details go to `config.md` only, never to `SKILL.md` or the repo
- `notion-set-discussion-resolved` runs only after Ian's explicit yes
- Line length 160; Markdown is not linted

## Review Focus

- A page with zero comments, or no pages in the window → report "no unhandled feedback" and stop, without touching git or chezmoi
- A discussion where Ian replied after Claude's reply → treated as unhandled; the proposal must read the whole thread, not just the first comment
- A comment that applies to config.example.md structure → the example gets a generic placeholder, never Ian's real value
- Dirty working tree before the pass → refuse to commit unrelated changes; stage only the files the pass edited
- Running from a worktree → chezmoi gets `--source "$(git rev-parse --show-toplevel)"`

Each of these is pinned by an explicit instruction in Task 1's SKILL.md, and Task 2's dry run exercises the first two against real data.

---

### Task 1: Write the skill

**Files:**
- Create: `.claude/skills/morning-feedback/SKILL.md`
- Modify: `AGENTS.md` (Claude Configuration → skills dividing line: name `morning-feedback` as the second project-scoped skill)

- [ ] **Step 1:** Frontmatter: `name: morning-feedback`, and a description that triggers on "process my briefing feedback", "read my morning-startup comments", "apply my Daily Startup feedback".
- [ ] **Step 2:** Body sections in spec order: Preflight (config + Notion probe), Find pages (SQL over `"date:Entry Date:start" >= today-N`), Find unhandled discussions, Read anchors (`notion-fetch include_discussions: true`), Route and propose, Review, Apply + commit, Deploy (scoped chezmoi), Reply, Resolve on request, plus the Review Focus guards above.
- [ ] **Step 3:** Commit the spec, plan, skill and AGENTS.md together.

### Task 2: Read-only dry run

- [ ] **Step 1:** Follow the skill through "Find unhandled discussions" only, against the live database. Expected: a list (possibly empty) of pages and discussions with anchor excerpts, and no writes.
- [ ] **Step 2:** If the SQL or the comment parsing misbehaves, fix SKILL.md and amend with a fixup-free follow-up commit.
