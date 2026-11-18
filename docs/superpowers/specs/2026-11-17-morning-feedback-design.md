# morning-feedback: turn Notion comments into morning-startup changes

**Date:** 2026-11-17
**Size:** small change (one new project-scoped skill)

## Intent

Ian reads each Daily Startup page in Notion and wants to leave feedback on it as
Notion comments, inline on the passage that's wrong or page-level, written for
the AI rather than for himself. Later, when he chooses, he runs a feedback pass
that reads those comments and turns them into lasting changes to the
`morning-startup` skill. The briefing run itself never reads or acts on comments.

## Goals

- One manual trigger ("process my briefing feedback") picks up every comment not
  yet handled
- Each comment becomes a proposed, reviewable edit. Nothing changes without Ian's approval
- Every handled comment gets a reply in Notion saying what changed, so the page
  records its own feedback loop

## Non-goals

- No automatic behaviour change in the next morning run
- No Claude memories: feedback goes into files Ian can diff
- No changes to `morning-startup`'s own SKILL.md flow (it doesn't read comments)

## Anti-goals

- Names, vendors, numbers or internal context leaking into the public repo
- Resolving Notion discussions Ian didn't explicitly ask to resolve (the Notion
  tool's own contract)
- One comment rewriting large parts of the skill: changes stay as small as the feedback

## Approaches

- **A. Project-scoped skill, `.claude/skills/morning-feedback/` (chosen).** It runs
  from the dotfiles repo, where every resulting change becomes a commit. This matches
  AGENTS.md's dividing line: skills for working *on this repo* live in `.claude/skills/`.
- B. Global skill in `home/dot_claude/skills/`. It would run from anywhere but
  still has to reach into `~/src/dotfiles` to edit and commit, and it would
  deploy to work boxes and gcw for nothing.
- C. A mode inside morning-startup. That SKILL.md is already ~1,150 lines, "good
  morning" could trigger the wrong mode, and every briefing would load
  instructions it never uses.

## Design

1. **Find pages.** Query the Daily Startup data source (ID from
   `~/.claude/skills/morning-startup/config.md`, `NOTION_STARTUP_DATA_SOURCE`)
   for entries in the last 14 days. A different window can be given as an argument.
2. **Find unhandled feedback.** For each page, `notion-get-comments` (unresolved
   only). A discussion is **unhandled** when no comment in it has `by-you="true"`.
   Claude's reply is the "processed" marker, so the pass is idempotent and
   needs no ledger. Ian's follow-up in the same thread after a Claude reply
   ("no, that's not it") makes it unhandled again. Rule: unhandled when its
   newest comment is not by-you.
3. **Read the anchor.** `notion-fetch` with `include_discussions: true` shows
   which passage each inline discussion is attached to. The comment is judged
   against that passage, not on its own.
4. **Propose one change per comment**, routed by content:
   - general behaviour rule → `home/dot_claude/skills/morning-startup/SKILL.md`
     (public repo)
   - anything naming people, vendors, channels, figures or internal projects →
     `~/.claude/skills/morning-startup/config.md` (private, machine-local, not in git)
   - a new config key or section → also update `config.example.md` with a
     generic placeholder
   - a comment that isn't skill feedback (a note to self, a question) → propose
     "no change" and say why
   Before writing a new rule, search SKILL.md for an existing one on the same
   topic and tighten that rule rather than adding a duplicate.
5. **Review.** Show all proposals together: comment text, page date, anchor
   excerpt, target file and diff. Ian approves, edits or skips each one. Skipped
   comments get no reply, so they stay unhandled for next time.
6. **Apply and commit.** Apply the approved edits. Commit the repo changes in one
   commit that lists the comments it addresses. config.md edits are local only.
7. **Deploy.** Show `chezmoi diff ~/.claude/skills/morning-startup` and, on a yes,
   apply scoped to that path. From a worktree, pass
   `--source "$(git rev-parse --show-toplevel)"` per AGENTS.md.
8. **Reply in Notion.** Reply to each handled discussion with what changed: the
   file, a one-line summary and the commit short hash, or "config.md (local)" or
   "no change: <reason>".
9. **Resolve on request.** At the end, ask once: "Resolve these N discussions?"
   Resolve only on a yes.

## Constraints

- Notion MCP must be reachable. If it isn't, stop and say so (same preflight
  wording style as morning-startup)
- config.md is per-machine. A rule written there exists only on the machine the
  pass ran on (in practice, the one that runs morning-startup)

## Left to the builder

- Exact trigger phrasing in the skill description
- Format of the proposal review (one table or per-comment blocks)
- Whether to add a short "Feedback" line to `docs/` or AGENTS.md pointing at the skill
